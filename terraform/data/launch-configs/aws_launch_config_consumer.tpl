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
  systemctl start consumer
}

function main() {
  install-pip
  install-boto3
  systemd-reload
}

ensure-install-dir

cat > /etc/systemd/system/multi-user.target.wants/consumer.service << __EOF
[Unit]
Description=Consumer Application
After=network-online.target docker.socket firewalld.service
Wants=network-online.target

[Service]
Type=simple
Environment=AWS_DEFAULT_REGION=us-east-1
ExecStart=/usr/bin/python3 /app/consumer.py
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

cat > /app/consumer.py << __EOF

import boto3
import time
import random

sqs = boto3.client('sqs')
dynamodb = boto3.client('dynamodb')

queue_url = '${AWS_SQS_URL}'
while True:
	try:
		response = sqs.receive_message(
		    QueueUrl=queue_url,
		    MaxNumberOfMessages=1,
		    VisibilityTimeout=60,
		    WaitTimeSeconds=0
		)

		message = response['Messages'][0]['Body'].split()
		message_md5 = response['Messages'][0]['MD5OfBody']
		receipt_handle = response['Messages'][0]['ReceiptHandle']

		ip = message[1]
		num = message[2]

		response = dynamodb.get_item (
			TableName='aws-sqs-python-dynamodb', 
			Key={
				'IP':{
					'S':'%s' % ip
				} 
			}
		)

		if not 'Item' in response:
			dynamodb.put_item (
				TableName='aws-sqs-python-dynamodb', 
				Item={
					'IP':{
						'S':'%s' % ip
					},
					'NUMSUM': {
						'N': '0'
					}
				}
			)

		response = dynamodb.get_item (
			TableName='aws-sqs-python-checking-dynamodb', 
			Key={
				'messageID':{
					'S':'%s' % message_md5
				} 
			}
		)

		if not 'Item' in response:
			response = dynamodb.transact_write_items(TransactItems=[
				{
					'Put': 
					{
						'TableName': 'aws-sqs-python-checking-dynamodb',
						'Item': 
							{
								'messageID': {
									'S': '%s' % message_md5
								}
						}
					}
				},
				{
					'Update': 
					{
						'TableName': 'aws-sqs-python-dynamodb',
						'Key': 
						{
							'IP': {
								'S': '%s' % ip
							}
						},
						'UpdateExpression': 'set NUMSUM = NUMSUM + :inc',
						'ExpressionAttributeValues': {
							':inc': {'N': "%s" % num}
			            }
					}
				}
			])

		sqs.delete_message(
		    QueueUrl=queue_url,
		    ReceiptHandle=receipt_handle
		)

	except Exception as e:
		print(e)
		continue

__EOF

main