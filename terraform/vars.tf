locals {
	tags 	 = {
		Owner       = "quangpm"
		Environment = "dev"
		Name        = "aws-sqs-python"
	}

	consumer = {
		AMI			  = "ami-0756fbca465a59a30"
		INSTANCE_TYPE = "t2.micro"
		SSHKEY		  = "quangpm"
	}
	producer = {
		AMI			  = "ami-0756fbca465a59a30"
		INSTANCE_TYPE = "t2.micro"
		SSHKEY		  = "quangpm"
	}
}
