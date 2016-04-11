# Owner: Steve Ovens
# Date Created: July 2015
# Primary Function: This is an ssh connection handler to be imported by any script requiring remote access.
# It will do nothing if called directly.
# Dependencies: helper_functions.py

class HandleSSHConnections:
    """This class allows for easier multiple connections. The problem is because /etc/init.d/tomcat restart
    Sometimes does not wait long enough between stop and start functions. As a result, tomcat may stay down
    To remedy this, this class will open multiple connections inserting a 20 second pause between connections
    Hopefully this will allow most instances of tomcat to shutdown gracefully before restarting """
    from helper_functions import ImportHelper
    ImportHelper.import_error_handling("paramiko", globals())
    ImportHelper.import_error_handling("time", globals())

    def open_ssh(self, server, user_name):
        if not self.ssh_is_connected():
            self.ssh = paramiko.SSHClient()
            self.ssh.load_system_host_keys()
            self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            self.ssh.connect(server, username=user_name, timeout=120)
            self.transport = self.ssh.get_transport()
            self.psuedo_tty = self.transport.open_session()
            self.psuedo_tty.get_pty()
            self.read_tty = self.psuedo_tty.makefile()

    def close_ssh(self):
        if self.ssh_is_connected():
            self.read_tty.close()
            self.psuedo_tty.close()
            self.ssh.close()
            time.sleep(2)

    def ssh_is_connected(self):
        transport = self._ssh.get_transport() if self._ssh else None
        return transport and transport.is_active()