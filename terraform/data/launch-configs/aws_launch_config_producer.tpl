#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail



function ensure-install-dir() {
  INSTALL_DIR="/tmp/sqs"
  mkdir -p $${INSTALL_DIR} /app
  cd $${INSTALL_DIR}
}

function install-pip() {
  yum install python3 -y 
  PYTHONBIN=$(which python3)
  curl --connect-timeout 20 --retry 6 --retry-delay 10 https://bootstrap.pypa.io/get-pip.py | $PYTHONBIN -
}

function install-boto3() {
  pip3 install boto3
}

function systemd-reload() {
  systemctl daemon-reload
  systemctl start producer 
}

function main() {
  install-pip
  install-boto3
  systemd-reload
}

ensure-install-dir

cat > /etc/systemd/system/multi-user.target.wants/producer.service << __EOF
[Unit]
Description=Producer Application
After=network-online.target docker.socket firewalld.service
Wants=network-online.target

[Service]
Type=simple
Environment=AWS_DEFAULT_REGION=us-east-1
ExecStart=/usr/bin/python3 /app/producer.py
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s
TimeoutSec=200s

[Install]
WantedBy=multi-user.target
__EOF

localipv4=$( curl http://169.254.169.254/latest/meta-data/local-ipv4 )

cat > /app/producer.py << __EOF

import boto3
import time
import random

# Create SQS client
sqs = boto3.client('sqs')
queue_url = '${AWS_SQS_URL}'
re_send = False

while True:
# Send message to SQS queue
  if not re_send:
    random_int = random.randint(1,1000)
    time_stamp = time.time()
  try:
    response = sqs.send_message(
      QueueUrl=queue_url,
      MessageBody=('%s $localipv4 %d' % (time_stamp, random_int))
    )
  except Exception as e:
    re_send = True
    continue
  time.sleep(3)

__EOF

main