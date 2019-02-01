provider "aws" {
  region = "${ var.aws_region}"
  profile = "${ var.aws_profile }"

}



#VPC 

resource "aws_vpc" "skies_vpc" {
  cider_block = " 10.1.0.0.16/16"
}

# Internet Gate way

resource "aws_internet_gateway" "skies_internet_gateway" {
  vpc_id = "${ aws_vpc.skies_vpc.id }"
}
#Public route table

resource "aws_route_table"  " public" {

   vpc_id = "${ aws_vpc.skies_vpc.id }"
   route { 
          cidr_block = "0.0.0.0/0"
          gateway_id = "{ aws_internet_gateway.skies_internet_gateway.id }"
    tags {
          Name = "skiespublic"
    }
   }
}


#Private route table

resource  "aws_defualt_route_table "  "private" {
  default_route_table_id = "${ aws_vpc.skies_vpc.defult_route_table_id }"
  tags {
    Name = "skies_private"
  }
}
#subnets

#public subnet
 resource "aws_subnet" "public" {
   vpc_id ="${ aws_vpc.skies_vpc.id }"
   cidr_block = " 10.1.1.0/24 "
   map_public_ip_on_launch = true 
   availability_zone = "eu-west-1d"
   tags {
     Name ="skies_public"
   }

 }

#Private 1

resource "aws_subnet" " private1" {
  vpc_id = "${ aws_vpc.skies_vpc.id}"
  cidr_block = "10.1.2.0/24"
  map_public_ip_on_launch = false
  availability_zone = "eu-west-1a"
  tags {
    Name ="skies_private1"
  }
# Private 2

resource "aws_subnet" " private2 " {
  vpc_id ="${ aws_vpc.skies_vpc.id }"
  cider_block = " 10.0.1.3.0/24"
  map_public_ip_on_launch = false
  availability_zone = "eu-west-1c"

  tags{
    Name = "skies_private2"
  }
  
}
 

# RDS sub net group < RDS-1 RDS -2 RDS -3 >

resource "aws_subnet" "rds1" {
  vpc_id = "${ aws_vpc.skies_vpc.id }"
  cidr_block = "10.1.4.0/24"
  map_public_ip_on_launch = false
  availability_zone = "eu-west-1a"

  tags {
    Name = "rds1"
    }
}

#RDS -2
resource "aws_subnet" " rds2" {
  vpc_id = "${ aws_vpc.skies_vpc.id }"
  cidr_block = " 10.0.5.0/24"
  map_public_ip_on_launch = false
  availability_zone = "eu-west-1c"

  tags {
    Name = "rds2"
  }
}
#RDS -3

resource "aws_subnet" "rds3" {
  vpc_id = "${ aws_vpc.skies_vpc.id }"
  cider_block = "10.0.1.6.0/24"
  map_public_ip_on_launch = false
  availability_zone = "eu-west-1d"
}



# < Associate subnet with routing tabel  >


#Public
resource "aws_route_table_association" "public_assoc" {
  subnet_id = "${ aws_subnet.public}" 
  route_table_id ="${ aws_route_table.public.id }"

  tags{
    Name = "skies_public_route_table"
  }
}

#Private 

resource "aws_route_table_association" "private1_assoc" {
  subnet_id = "${ aws_subnet.private1.id}" 
  route_table_id ="${ aws_route_table.public.id}"

  tags {
    Name = "skies_private1_merge_public_route_table"
  }
  
}

resource "aws_route_table_association" "private2_assoc" {
  subnet_id = "${ aws_subnet.private2.id }"
  route_table_id = "${ aws_route_table.public.id }"

  tags {
    Name = " Skies_private1_route_table" 

  }
  
}

resource "aws_db_subnet_group" "rds_subnetgroup" {

  name = "rds_subnetgroup"
  subnet_ids = ["${ aws_subnet.rds1.id }" ,"${ aws_subnet.rds2.id }" ,"${ aws_subnet.rds3.id }"]

tags {
  Name = "skies_rds_sng"
}
  
}

# Security Group

resource  "aws_security_group" "public" {
  name = "sg_public"
  description = "used for both private and public instances for load balancer access "
  vpc_id = "${ aws_vpc.skies_vpc.id }"
  #SSH
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "${ var.localip }" ]
  }

# HTTP
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cider_blocks =  [ "0.0.0.0/0 "]
    
    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = [ "0.0.0.0/0" ]
    }

  }

}
  
# Private security Group

resource "aws_security_group" "private" {
  name = "sg_private"
  description = "used for private instances"
  vpc_id = "$ { aws_vpc.skies_vpc.id }"

  # Acess from other security group

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["10.1.0.0/16"] 
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0 /0 "]
  }

}
  
#RDS security Group


resource "aws_security_group" "RDS" {
  name = "sg_rds"
  description = "used for DB instances"
  vpc_id = "${ aws_vpc.skies_vpc.id}"

  #SQL access from public / private security group

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = ["${aws_security_group.public}" ,  "${ aws_security_group.private.id }"]


  }
}

#DB

resource "aws_db_instance" "skies-db" {
    allocated_storage   = 10
    engine              = "mysql"
    engine_version      =  "8.0"
    instance_class      = "${var.db_instance_class_}"
    name                = "${var.dbname}"
    username            = "${var.dbuser}"
    password            = "${var.dbpassword}"
    db_subnet_group_name = "${aws_db_subnet_group.rds_subnetgroup.name}"
    vpc_security_group_ids = "[${aws_security_group.RDS.id}]"


}

#Key Pair 
# so what this is doing is importing the content of the public key file uploading them to amazone and creating a new key based on this information 
#(Note: this will not upload the private key to your instances only the public so if yopu need to connect to one of your private instances from your public instance as a bashing host you will need to use
# ssh -a  to forward the key agent or you will need to copy the private key to your host , ] )

resource "aws_key_pair" "auth" {
  key_name = "${var.key_name}"
  key_path =  "${file(var.public_key_path)}"

}

#S3 Roles, s3_access

resource "aws_iam_instance_profile" "s3_access" {
  name = "s3_access"
  roles = ["${aws_iam_role.s3_access.name}"]
  
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy"
  role = "${aws_iam_role.s3_access.id}"
  policy = <<EOF
  {
    "Version" : "2012-10-17",
    "Statement" : [
     {
       "Effect" : "Allow",
       "Action" : "s3:*",
       "Resource": "*"
     }
    ]
  }
EOF
}

resource "aws_iam_role" "s3_access" {
  name = "s3_access"
  assume_role_policy = <<EOF
  {
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principle" : {
          "Services : "ec2.amazoneaws.com"
        },   
           "Effect" : "Allow",
           "Sid" : ""

              }
    ]
  }

}

#create S3 VPC endpoint 
resource "aws_vpc_endpoint" "private-s3" {
  vpc_id = "${aws_vpc.skies_vpc.id}"
  service_name = "com.amazoneaws.${var.aws_region}.s3"
  route_table_ids = ["${aws_vpc.skies_vpc.main_route_table_id}" , "${aws_route_table.public.id}"]
  policy = <<POLICY
  {
    "Statement" : [
      {
        "Action" : "*",
        "Effect" : "Allow"
        "Resource": "*"
        "Principle" : "*"
      }
    ]
  }
  POLICY
}

#S3 Code Bucket

resource  "aws_s3_bucket" "code" {
  bucket = "$var.domain_name"_code0909
  acl = "private"
   # this allows terraform to distory the bucket even with content 
  force_destory = true
  tags {
    Name = "code bucket"
  }
}

#Compute

#Dev Sever 
  # ansible play
#Load balancer 
# AMI
# Lunch configuration
# Auto scaling group

# Route53 
# primary zone : use deligation set 
#www point to load balancer 
#dev record to point to the dev server public IP address 
#db cname for RDS < allow web server to point to the RDs even if the IP changes 