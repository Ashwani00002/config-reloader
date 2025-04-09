FROM jenkins/inbound-agent:3301.v4363ddcca_4e7-1

USER root

# Update package lists and install wget
RUN apt-get update && apt-get install -y wget

# Install jq
RUN apt-get install -y jq

USER jenkins

# docker build -t jenkins-wget-jq-utility:v1.0 .
# docker tag jenkins-wget-jq-utility:v1.0 ashwani00002/jenkins-wget-jq-utility:v1.0
# docker push ashwani00002/jenkins-wget-jq-utility:v1.0