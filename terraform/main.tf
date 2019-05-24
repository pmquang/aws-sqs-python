module vpc {
	source                = "./modules/terraform-aws-vpc"
	
	name = "aws-sqs-python"

	cidr = "10.10.0.0/16"

	azs                 = ["us-east-1a", "us-east-1b", "us-east-1c"]
	private_subnets     = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
	public_subnets 		= ["10.10.11.0/24"]

	enable_nat_gateway = true
	single_nat_gateway = true

	tags = {
		Owner       = "$local.tags["OWNER"]"
		Environment = "$local.tags["ENV"]"
		Name        = "$local.tags["NAME"]"
	}
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = "${module.vpc.vpc_id}"
}

resource "aws_key_pair" "quangpm" {
  key_name   = "quangpm"
  public_key = ${file("${path.root}/data/credentials/ssh-key.pub")}"
}

resource "aws_sqs_queue" "aws-sqs-python-standard-queue" {
	name                        = "aws-sqs-python-standard-queue"
	content_based_deduplication = false
	delay_seconds               = 0
	fifo_queue                  = false
	#redrive_policy              = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.aws-sqs-python-standard-queue.arn}\",\"maxReceiveCount\":4}"
	max_message_size            = 262144
	message_retention_seconds   = 1209600
	receive_wait_time_seconds   = 0
	visibility_timeout_seconds  = 1800
}

resource "aws_launch_configuration" "aws-sqs-python-consumer-launch-config" {
	name_prefix   				= "aws-sqs-python-consumer-launch-config"
	image_id      				= "${local.consumer["AMI"]}"
	instance_type 				= "${local.consumer["INSTANCE_TYPE"]}"
	key_name 					= "${local.consumer["SSHKEY"]}"
	security_groups 			= ["${data.aws_security_group.default.id}"]
	iam_instance_profile        = "${aws_iam_instance_profile.misfit-waf-misfit-com.id}"
	associate_public_ip_address = false
	enable_monitoring           = false

	user_data                   = "${data.template_file.misfit-waf-misfit-com-instance-launch-configuration.rendered}"

	lifecycle {
		create_before_destroy = true
	}
}

module aws-sqs-python-consumer-asg {
	source                = "./modules/terraform-aws-autoscaling"
	name 				  = "aws-sqs-python-consumer"

  	launch_configuration  = "${aws_launch_configuration.aws-sqs-python-consumer-launch-config.name}"
 	create_lc = false

	recreate_asg_when_lc_changes = true

	root_block_device = [
		{
		  volume_size = "50"
		  volume_type = "gp2"
		  delete_on_termination = true
		},
	]

	# Auto scaling group
	asg_name                  = "aws-sqs-python-consumer-asg"
	vpc_zone_identifier       = ["${module.vpc.private_subnets}"]
	health_check_type         = "EC2"
	min_size                  = 0
	max_size                  = 1
	desired_capacity          = 1
	wait_for_capacity_timeout = 0
}
