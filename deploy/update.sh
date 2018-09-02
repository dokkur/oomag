#!/bin/bash

export PROJECT_NAME=$1
export PROJECT_BRANCH=$2
export RVM_PATH=$3
export SSH_BASEPATH=$4
# sourcing looks like `source /home/deployer/.rvm/bin/rvm`
source $RVM_PATH
cd /var/www/$PROJECT_NAME
export $(cat .env | xargs)
export KEY_NAME=id_rsa_$PROJECT_NAME
export KEY_PATH=${SSH_BASEPATH}/$KEY_NAME
GIT_SSH_COMMAND="ssh -i $KEY_PATH" git pull origin $PROJECT_BRANCH
dotenv bundle install --without development test
dotenv bundle exec rails db:migrate
dotenv bundle exec rake assets:precompile
sudo /opt/nginx/sbin/nginx -s reload
