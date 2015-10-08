#!/bin/bash
set -e
GERRIT_ADMIN_UID={{ ci_user }}
GERRIT_ADMIN_EMAIL={{ ci_user }}@{{ domain_name }}
SSH_KEY_PATH={{ ci_key }}
CHECKOUT_DIR=./git

JENKINS_NAME=jenkins
GERRIT_NAME={{ gerrit_name }}
GERRIT_SSH_HOST={{ gerrit_ssh_host }}
GERRIT_WEBURL={{ gerrit_weburl }}
JENKINS_WEBURL={{ jenkins_weburl }}
NEXUS_REPO={{ nexus_repo }}

#create ssh key.
docker exec {{ jenkins_container }} [ -d /var/jenkins_home/.ssh ] || docker exec {{ jenkins_container }} mkdir -p /var/jenkins_home/.ssh
docker exec {{ jenkins_container }} [ -f /var/jenkins_home/.ssh/id_rsa ] || docker exec {{ jenkins_container }} ssh-keygen -q -N '' -t rsa  -f /var/jenkins_home/.ssh/id_rsa

#gather server rsa key
##TODO: This is not an elegant way.
[ -f ~/.ssh/known_hosts ] && mv -f ~/.ssh/known_hosts ~/.ssh/known_hosts.bak
ssh-keyscan -p 29418 -t rsa ${GERRIT_SSH_HOST} > ~/.ssh/known_hosts

#create jenkins account in gerrit.
account=$(ssh -i "${SSH_KEY_PATH}" -p 29418 ${GERRIT_ADMIN_UID}@${GERRIT_SSH_HOST} 'gerrit ls-members "Non-Interactive Users"' |awk '{print $2}')
findit=false
for i in $account;
do
	if [ x"$i" = x"jenkins" ]; then
		echo "Find the existing jenkins user in gerrit, will not create it."
		findit=true
	fi
done
if [ x"$findit" = x"false" ]; then
    docker exec ${JENKINS_NAME} cat /var/jenkins_home/.ssh/id_rsa.pub | ssh -i "${SSH_KEY_PATH}" -p 29418 ${GERRIT_ADMIN_UID}@${GERRIT_SSH_HOST} gerrit create-account --group "'Non-Interactive Users'" --full-name "'Jenkins Server'" --ssh-key - jenkins

    #checkout project.config from All-Project.git
    [ -d ${CHECKOUT_DIR} ] && mv ${CHECKOUT_DIR} ${CHECKOUT_DIR}.$$
    mkdir ${CHECKOUT_DIR}

    git init ${CHECKOUT_DIR}
    cd ${CHECKOUT_DIR}

    #start ssh agent and add ssh key
    eval $(ssh-agent)
    ssh-add "${SSH_KEY_PATH}"

    #git config
    git config user.name  ${GERRIT_ADMIN_UID}
    git config user.email ${GERRIT_ADMIN_EMAIL}
    git remote add origin ssh://${GERRIT_ADMIN_UID}@${GERRIT_SSH_HOST}:29418/All-Projects 
    #checkout project.config
    git fetch -q origin refs/meta/config:refs/remotes/origin/meta/config
    git checkout meta/config

    #add label.Verified
    git config -f project.config label.Verified.function MaxWithBlock
    git config -f project.config --add label.Verified.defaultValue  0
    git config -f project.config --add label.Verified.value "-1 Fails"
    git config -f project.config --add label.Verified.value "0 No score"
    git config -f project.config --add label.Verified.value "+1 Verified"
    ##commit and push back
    git commit -a -m "Added label - Verified"

    #Change global access right
    ##Remove anonymous access right.
    git config -f project.config --unset access.refs/*.read "group Anonymous Users"
    ##add Jenkins access and verify right
    git config -f project.config --add access.refs/heads/*.read "group Non-Interactive Users"
    git config -f project.config --add access.refs/tags/*.read "group Non-Interactive Users"
    git config -f project.config --add access.refs/heads/*.label-Code-Review "-1..+1 group Non-Interactive Users"
    git config -f project.config --add access.refs/heads/*.label-Verified "-1..+1 group Non-Interactive Users"
    ##add project owners' right to add verify flag
    git config -f project.config --add access.refs/heads/*.label-Verified "-1..+1 group Project Owners"
    ##commit and push back
    git commit -a -m "Change access right." -m "Add access right for Jenkins. Remove anonymous access right"
    git push origin meta/config:meta/config

    #stop ssh agent
    kill ${SSH_AGENT_PID}

    cd -
    rm -rf ${CHECKOUT_DIR}
    [ -d ${CHECKOUT_DIR}.$$ ] && mv ${CHECKOUT_DIR}.$$  ${CHECKOUT_DIR}
fi

#Setup gerrit-trigger plugin and restart jenkins
docker exec ${JENKINS_NAME} \
jenkins-setup.sh \
${GERRIT_NAME} \
${GERRIT_WEBURL} \
${JENKINS_WEBURL} \
${NEXUS_REPO}

docker restart ${JENKINS_NAME}

