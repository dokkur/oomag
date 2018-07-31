#!/bin/bash
set -e  # Exit with non-zero if anything fails

#PROJECT_BRANCH="master" defined in travis-ci
#PROJECT_NAME defined in travis-ci and usually looks like repo name
#REMOTE_USER defined in travis-ci and is just user name
#REMOTE_HOST defined in travis-ci and is an IP address or hostname
#RVM_PATH defined in travis-ci and looks like /home/user/.rvm/bin/rvm
#SSH_KEY_BASEPATH defined in travis-ci and looks like /home/user/.ssh

# Do not build a new version if it is a pull-request or commit not to BUILD_BRANCH
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
    echo "We do not manage PRs, skipping deploy;"
    exit 0
fi

if [ "$TRAVIS_BRANCH" != "$PROJECT_BRANCH" ]; then
  echo "Not needed branch but $TRAVIS_BRANCH, skipping deploy;"
  exit 0
fi

echo "Prepare the key..."
# Encryption key is a key stored in travis itself
OUT_KEY="id_rsa"
echo "Trying to decrypt encoded key..."
openssl aes-256-cbc -k "$ENCRYPTION_KEY" -in deploy/id_rsa.enc -out $OUT_KEY -d -md sha256
chmod 600 $OUT_KEY
echo "Add decoded key to the ssh agent keystore"
eval `ssh-agent -s`
ssh-add $OUT_KEY

echo "Run needed script on the target node"
# REMOTE_USER and REMOTE_HOST are defined in Travis itself
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "cd /var/www/$PROJECT_NAME && GIT_SSH_COMMAND=\"ssh -i ${SSH_KEY_BASEPATH}/id_rsa_$PROJECT_NAME\" git pull origin $PROJECT_BRANCH"
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "/var/www/$PROJECT_NAME/deploy/update.sh $PROJECT_NAME $PROJECT_BRANCH $RVM_PATH ${SSH_KEY_BASEPATH}"
echo "All done."
