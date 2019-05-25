resource "aws_key_pair" "sshkey" {
	key_name   = "${local.consumer["SSHKEY"]}"
	public_key = "${file("${path.root}/data/credentials/ssh-key.pub")}"
}

resource "aws_sqs_queue" "aws-sqs-python-standard-queue" {
	name                        = "aws-sqs-python-standard-queue"
	content_based_deduplication = false
	delay_seconds               = 0
	fifo_queue                  = false
	max_message_size            = 262144
	message_retention_seconds   = 1209600
	receive_wait_time_seconds   = 20
	visibility_timeout_seconds  = 30
}

resource "aws_dynamodb_table" "aws-sqs-python-dynamodb" {
	name           = "aws-sqs-python-dynamodb"
	read_capacity  = 20
	write_capacity = 20
	hash_key       = "IP"

	attribute = [{
		name = "IP"
		type = "S"
	}]

	tags = {
		Owner       = "${local.tags["OWNER"]}"
		Environment = "${local.tags["ENV"]}"
		Name        = "${local.tags["NAME"]}"
	}
}

resource "aws_dynamodb_table" "aws-sqs-python-checking-dynamodb" {
	name           = "aws-sqs-python-checking-dynamodb"
	read_capacity  = 20
	write_capacity = 20
	hash_key       = "messageID"

	attribute = [{
		name = "messageID"
		type = "S"
	}]

	tags = {
		Owner       = "${local.tags["OWNER"]}"
		Environment = "${local.tags["ENV"]}"
		Name        = "${local.tags["NAME"]}"
	}
}
