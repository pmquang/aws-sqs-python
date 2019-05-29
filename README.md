# aws-sqs-python

This repo for the demo which create the SQS Infras

## Terraform Template 
This template is to create:
* VPC Network
* IAM role for consumer and producer 
* AutoScaling Group for consumer and producer 
* Standard Amazon SQS
* DynamoDB

## Scripts

All script is bundled in IaC of terraform but I will show you here for easily take a look:

* consumer.py

```
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
```

* producer.py

```
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
    re_send = 
  except Exception as e:
    re_send = True
    continue
  time.sleep(3)

```

Producer will send a message to SQS every 3 seconds, support resend in case of having problem due to network or something.

The AWS QSQ apply visibility_timeout_seconds to make sure we just process the message once. 

Consumer will use 2 tables of DynamoDB: aws-sqs-python-dynamodb and aws-sqs-python-checking-dynamodb and apply transaction write.

The reason is to make sure we can eliminate the duplicated message.

* Systemd Service 

```
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
```

## Guide 

* Use terraform 0.11.13 ( I will move to 0.12 soon )
* Need a way to authen to AWS from your terminal with admin permission ( for just easy testing ). 
* My way is export variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
* Default region is us-east-1
* Change public key to ssh server at data/credentails/ssh-key.pub if needed.

> terraform init
> 
> terraform apply -auto-approve

The anything else is already in the code. Please check. 

