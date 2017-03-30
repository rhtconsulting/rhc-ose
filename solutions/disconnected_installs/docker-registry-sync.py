#!/usr/bin/python
import urllib
import json
from pkg_resources import parse_version
import argparse
import os

parser = argparse.ArgumentParser(description='Syncs images from a public docker registry to a private registry. Use '
                                             'this to populate private registries in a closed off environment. Must be '
                                             'run from a linux host capable of running docker commands which has '
                                             'access both to the internet and the private registry.',
                                             epilog='%s \nSample usage: --from=<public-registry-hostname> '
                                             '--to=<registry-to-sync-to> --file=<image-file>',
                                             formatter_class=argparse.RawTextHelpFormatter)

parser.add_argument('--from', action='store', dest='remote_registry', help='The location of the remote repository')
parser.add_argument('--local', action='store', dest='local_registry', help='The location of the local repository')
parser.add_argument('--file', action='store', dest='json_file', help='A JSON formatted file with the following format:'
                                                                     '{"<tag_type>": {"<namespace>": ["image1", image2"'
                                                                     'image3]}}')
parser.add_argument('--output', action='store_true', dest='output', help='If this flag is present, commands will be'
                                                                         'dumped to stdout instead of run')

options = parser.parse_args()

release_version = '3.4'

retrieve_v_tags_from_redhat_list = []
retrieve_non_v_tags_from_redhat_list = []

latest_tag_list = []

def generate_url_list(dictionary_key, list_to_populate):
    for namespace in config_file_dict[dictionary_key]:
        for image in config_file_dict[dictionary_key][namespace]:
            docker_json_link = "https://registry.access.redhat.com/v2/%s/%s/tags/list" % (namespace, image)
            list_to_populate.append(docker_json_link)

def get_latest_tag_from_api(url_list, tag_list, version_type = None):
    for url in url_list:
        redhat_registry = urllib.urlopen(url)
        # The object is returned as a string so it needs to be converted to a json object
        image_tag_dictionary = json.loads(redhat_registry.read())
        # Get the latest version for a given release
        latest_tag = ''
        image_name = image_tag_dictionary['name']
        for tag in image_tag_dictionary['tags']:
            # check to see if there is a 'v' in the version tag:
            if tag.startswith('v'):
                # This tracks the position of the splice. It assumes that you are trying to get the latest
                # release based on a two digit release (i.e. 3.4 or 3.7)
                splice_position = 4
            else:
                splice_position = 3
            if release_version in tag[:splice_position]:
                # There may be a better way of getting the highest tag for a release
                # but the list may potentially have a higher release version than what you are looking for
                if parse_version(tag) > parse_version(latest_tag):
                    if version_type is not None:
                        if "v" in tag:
                            pass
                        else:
                            latest_tag = tag
                    else:
                        latest_tag = tag
        # We want to remove everything after the hyphen because we don't care about release versions
        latest_tag_minus_hyphon = latest_tag.split('-')[0]
        tag_list.append("%s:%s" % (image_name, latest_tag_minus_hyphon))


config_file = options.json_file
with open(config_file) as json_data:
    config_file_dict = json.load(json_data)

generate_url_list('image_with_v_in_tag', retrieve_v_tags_from_redhat_list)
generate_url_list('images_without_v_in_tag', retrieve_non_v_tags_from_redhat_list)

get_latest_tag_from_api(retrieve_v_tags_from_redhat_list, latest_tag_list)
get_latest_tag_from_api(retrieve_non_v_tags_from_redhat_list, latest_tag_list, 'v')

for namespace_and_image in latest_tag_list:
    if options.output:
        print("docker pull %s/%s" % (options.remote_registry, namespace_and_image))
        print("docker tag %s/%s %s/%s" % (options.remote_registry, namespace_and_image, options.local_registry,
                                          namespace_and_image))
        print("docker push %s/%s" % (options.local_registry, namespace_and_image))
        print("")
    else:
        print("Pulling %s/%s" % (options.remote_registry, namespace_and_image))
        os.popen("docker pull %s/%s" % (options.remote_registry, namespace_and_image)).read()
        print("Tagging for this registry: %s" % options.local_registry)
        os.popen("docker tag %s/%s %s/%s" % (options.remote_registry, namespace_and_image, options.local_registry,
                                             namespace_and_image)).read()
        print("Pushing into the local registry...")
        os.popen("docker push %s/%s" % (options.local_registry, namespace_and_image)).read()