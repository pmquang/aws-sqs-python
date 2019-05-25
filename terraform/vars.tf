locals {
	tags 	 = {
		OWNER       = "quangpm"
		ENV 		= "dev"
		NAME        = "aws-sqs-python"
	}

	consumer = {
		AMI			  = "ami-0c6b1d09930fac512"
		INSTANCE_TYPE = "t2.micro"
		SSHKEY		  = "quangpm"
	}
	producer = {
		AMI			  = "ami-0c6b1d09930fac512"
		INSTANCE_TYPE = "t2.micro"
		SSHKEY		  = "quangpm"
	}
}
