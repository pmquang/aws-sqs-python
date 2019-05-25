#### CONSUMER
resource "aws_iam_role" "aws-sqs-python-iam-role-consumer" {
  name               = "aws-sqs-python-iam-role-consumer"
  assume_role_policy = "${file("${path.module}/data/iam-roles/aws_iam_role_instance.json")}"
}

resource "aws_iam_role_policy" "aws-sqs-python-iam-role-policy-consumer" {
  name   = "aws-sqs-python-iam-role-policy-consumer"
  role   = "${aws_iam_role.aws-sqs-python-iam-role-consumer.name}"
  policy = "${file("${path.module}/data/iam-policies/aws_iam_role_consumer_policy.json")}"
}

resource "aws_iam_instance_profile" "aws-sqs-python-iam-instance-profile-consumer" {
  name = "aws-sqs-python-iam-instance-profile-consumer"
  role = "${aws_iam_role.aws-sqs-python-iam-role-consumer.name}"
}

data "template_file" "launch-configuration-consumer" {
  template = "${file("${path.module}/data/launch-configs/aws_launch_config_consumer.tpl")}"

  vars {
    AWS_SQS_URL = "${aws_sqs_queue.aws-sqs-python-standard-queue.id}"
  }  
}


resource "aws_launch_configuration" "aws-sqs-python-consumer-launch-config" {
	name_prefix   				= "aws-sqs-python-consumer-launch-config"
	image_id      				= "${local.consumer["AMI"]}"
	instance_type 				= "${local.consumer["INSTANCE_TYPE"]}"
	key_name 					= "${aws_key_pair.sshkey.id}"
	security_groups 			= ["${aws_security_group.allow_ssh.id}"]
	iam_instance_profile        = "${aws_iam_instance_profile.aws-sqs-python-iam-instance-profile-consumer.id}"
	associate_public_ip_address = false
	enable_monitoring           = false

	user_data                   = "${data.template_file.launch-configuration-consumer.rendered}"

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


#### PRODUCER
resource "aws_iam_role" "aws-sqs-python-iam-role-producer" {
  name               = "aws-sqs-python-iam-role-producer"
  assume_role_policy = "${file("${path.module}/data/iam-roles/aws_iam_role_instance.json")}"
}

resource "aws_iam_role_policy" "aws-sqs-python-iam-role-policy-producer" {
  name   = "aws-sqs-python-iam-role-policy-producer"
  role   = "${aws_iam_role.aws-sqs-python-iam-role-producer.name}"
  policy = "${file("${path.module}/data/iam-policies/aws_iam_role_producer_policy.json")}"
}

resource "aws_iam_instance_profile" "aws-sqs-python-iam-instance-profile-producer" {
  name = "aws-sqs-python-iam-instance-profile-producer"
  role = "${aws_iam_role.aws-sqs-python-iam-role-producer.name}"
}

data "template_file" "launch-configuration-producer" {
  template = "${file("${path.module}/data/launch-configs/aws_launch_config_producer.tpl")}"

  vars {
    AWS_SQS_URL = "${aws_sqs_queue.aws-sqs-python-standard-queue.id}"
  }  
}


resource "aws_launch_configuration" "aws-sqs-python-producer-launch-config" {
	name_prefix   				= "aws-sqs-python-producer-launch-config"
	image_id      				= "${local.producer["AMI"]}"
	instance_type 				= "${local.producer["INSTANCE_TYPE"]}"
	key_name 					= "${aws_key_pair.sshkey.id}"
	security_groups 			= ["${aws_security_group.allow_ssh.id}"]
	iam_instance_profile        = "${aws_iam_instance_profile.aws-sqs-python-iam-instance-profile-producer.id}"
	associate_public_ip_address = false
	enable_monitoring           = false

	user_data                   = "${data.template_file.launch-configuration-producer.rendered}"

	lifecycle {
		create_before_destroy = true
	}
}

module aws-sqs-python-producer-asg {
	source                = "./modules/terraform-aws-autoscaling"
	name 				  = "aws-sqs-python-producer"

  	launch_configuration  = "${aws_launch_configuration.aws-sqs-python-producer-launch-config.name}"
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
	asg_name                  = "aws-sqs-python-producer-asg"
	vpc_zone_identifier       = ["${module.vpc.private_subnets}"]
	health_check_type         = "EC2"
	min_size                  = 0
	max_size                  = 2
	desired_capacity          = 2
	wait_for_capacity_timeout = 0
}



