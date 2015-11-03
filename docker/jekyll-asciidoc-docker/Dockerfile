FROM centos:7

MAINTAINER Andrew Block “andrew.block@redhat.com”

# Update System and install clients
RUN yum update -y; \
	yum install -y epel-release git tar libyaml-devel autoconf gcc-c++ readline-devel zlib-devel libffi-devel openssl-devel automake libtool bison sqlite-devel; \
	yum install -y nodejs; \
 	yum clean all; \
	curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.29.0/install.sh | bash; \
	bash -c "source /root/.nvm/install.sh"; \
	gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3; \
	curl -sSL https://get.rvm.io | bash -s stable; \
	source /etc/profile.d/rvm.sh;
	
RUN	/bin/bash -l -c "rvm requirements"; 
RUN	/bin/bash -l -c "rvm install 2.2.1";
RUN	/bin/bash -l -c "rvm use 2.2.1";
RUN	/bin/bash -l -c "rvm rubygems latest";
RUN /bin/bash -l -c "gem install bundler";
	
ADD bin/start.sh /root/	

# Expose port
EXPOSE 4000

# Set /root as starting directory
WORKDIR /root

# Helper script
ENTRYPOINT ["/bin/bash"]

# Start Command
CMD ["--login", "/root/start.sh"]
