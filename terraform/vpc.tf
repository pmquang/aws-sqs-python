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
		Owner       = "${local.tags["OWNER"]}"
		Environment = "${local.tags["ENV"]}"
		Name        = "${local.tags["NAME"]}"
	}
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = "${module.vpc.vpc_id}"
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}