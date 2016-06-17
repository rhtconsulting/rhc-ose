#!/bin/python

#import http-parser 
import requests
import json
import pkiutils
from OpenSSL import crypto

s = requests.Session()

token = "lTBiDnvYlHhuOl3C9Tj_Mb-FvL0hcMMONIua0E0D5CE"
openshift_api="env1-master1.sbox.etl.practice.redhat.com:8443"
ipaurl="https://idm-1.etl.lab.eng.rdu2.redhat.com/ipa/"
relm="ETL.LAB.ENG.RDU2.REDHAT.COM"
namespace="joe"

def streaming():
    req = requests.Request("GET",'https://{0}/oapi/v1/namespaces/{1}/routes?watch=true'.format(openshift_api, namespace),
                           headers={'Authorization': 'Bearer {0}'.format(token)},
                           params="").prepare()

    resp = s.send(req, stream=True, verify=False)
    print resp.status_code

    for line in resp.iter_lines():
        if line:
            yield line


def read_stream():

    for line in streaming():
        event = {}
        try: 
            event = json.loads(line)

            if event['type'] == 'ADDED':
                print event
                print 
                session = requests.Session()

                #TODO: Create Private Key and CSR 
                key = pkiutils.create_rsa_key(bits=2048, keyfile=None, format='PEM', passphrase=None)
                csr = pkiutils.create_csr(key, "/CN={0}/C=US/O=Test organisation/".format(event['object']['spec']['host']), csrfilename=None, attributes=None) 
                print "    CSR and Key Create Complete" 
                #print csr

                #TODO: Sign Request with Dynamic CA (IPA) 

                resp = session.post('{0}session/login_password'.format(ipaurl),
                    params="", data = {'user':'certadmin','password':'redhat'}, verify=False, 
                    headers={'Content-Type':'application/x-www-form-urlencoded', 'Accept':'applicaton/json'})

                header={'referer': ipaurl, 'Content-Type':'application/json', 'Accept':'application/json'}

                # CREATE HOST
                create_host = session.post('{0}session/json'.format(ipaurl), headers=header,
                    data=json.dumps({'id': 0, 'method': 'host_add', 'params': [[event['object']['spec']['host']], {'force': True}]}), verify=False)

                print "    Host Create Return Code: {0}".format(create_host.status_code)

                # CREATE CERT
                cert_request = session.post('{0}session/json'.format(ipaurl), headers=header, 
                    data=json.dumps({'id': 0, 'method': 'cert_request', 'params': [[csr], {'principal': 'host/{0}@{1}'.format(event['object']['spec']['host'], relm), 
                        'request_type': 'pkcs10', 'add': False}]}), verify=False)

                print "    Certificate Signing Return Code: {0}".format(cert_request.status_code)
                #print "  {0}".format(cert_request.json())
                cert_resp = cert_request.json()

                print "CERTIFICATE:\n-----BEGIN CERTIFICATE-----\n{0}\n-----END CERTIFICATE-----".format(
                    '\n'.join(cert_resp['result']['result']['certificate'][i:i+65] for i in xrange(0, len(cert_resp['result']['result']['certificate']), 65)))
                print 
                print "KEY:\n {0}".format(key.exportKey('PEM'))
  
                #TODO: Update Route
                req = requests.patch('https://{0}/oapi/v1/namespaces/{1}/routes/{2}'.format(openshift_uri, namespace, event['object']['metadata']['name']),
                    headers={'Authorization': 'Bearer {0}'.format(token), 'Content-Type':'application/strategic-merge-patch+json'},
                    data=json.dumps({'spec': {'tls': {'certificate': '-----BEGIN CERTIFICATE-----\n{0}\n-----END CERTIFICATE-----'.format(
                        '\n'.join(cert_resp['result']['result']['certificate'][i:i+65] for i in xrange(0, len(cert_resp['result']['result']['certificate']), 65))),
                        'key': '{0}'.format(key.exportKey('PEM'))}}}),
                    params="", verify=False)

                print "    OpenShift Route Update Return Code: {0}".format(req.status_code)

        except Exception as e: 
            print e
            continue

read_stream()
