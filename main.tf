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
  bucket = "${var.domain_name}_code1115
  acl = "private"
   # this allows terraform to distory the bucket even with content 
  force_destory = true
  tags {
    Name = "code bucket"
  }
}

#Compute
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

#Dev Sever 

resource "aws_instance"  "dev" {
  instance_type = "${var.dev_instance_type}"
  ami = "${var.dev_ami}"
  tags {
    name = "dev"
  }
  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids ["${aws_security_group.public.id}"]
  iam_instance_profile ="${aws_iam_instance_profile.s3_access.id}"
  subnet_id = "${aws_subnet.public.id}"
}

provisioner "local-exec"{
  command = "cat <<EOF > aws_hosts"
  [dev]
  ${aws_instance.dev.public_ip}
  [dev:vars]
  s3code=${aws_s3_bucket.code.bucket}
  EOF
}

provisioner  "local-exec" {
  command = "sleep 6m && ansible-playbook -i aws_hosts apache.yml"
}
 
  

#Load balancer 
resource "aws_elb" "prod" {
  name = "${var.domain_name}-prod-elb"
  subnets = ["${aws_subnet.private1.ids}", "${aws_subnet.private2.id}"]
  security_groups = ["${aws_security_group.public.id}"]
  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 443
    lb_protocol = "https"
  }
  
  health_check {
    healthy_threshold = "${var.elb_healthy_threshold}"
    unhealthy_threshold ="${var.elb_unhealthy_threshold}"
    timeout = "${var.elb_timeout}"
    terget = "HTTP:80/"
    internal = "${var.elb_interval}"
  }
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  tags{
    name = "${var.domain_name}-prod-elb"

  }
}


# AMI

resource "ramdom_id" "ami" {
  byte_length = 8

  }
resource "aws_ami_from_instance" "wp_golden" {
  name               = "wp_ami-${random_id.golden_ami.b64}"
  source_instance_id = "${aws_instance.wp_dev.id}"

  provisioner "local-exec" {
    command = <<EOT
cat <<EOF > userdata
#!/bin/bash
/usr/bin/aws s3 sync s3://${aws_s3_bucket.code.bucket} /var/www/html/
/bin/touch /var/spool/cron/root
sudo /bin/echo '*/5 * * * * aws s3 sync s3://${aws_s3_bucket.code.bucket} /var/www/html/' >> /var/spool/cron/root
EOF
EOT
  }
}

#Lunch configuration

resource  "aws_lunch_configuration"  "lc" {
  name_prefix = "lc"
  image_id = "${aws_aim_from_instance.golden.id}"
  instance_type = "${var.lc_instance_type}"
  security_groups = ["${aws_security_group.private.id}"]
  iam_instance_profile = "${aws_aim_instance_profile.s3_access.id}"
  key_name = "${file("userdata")}"
  lifecycle = {
    create_before_destory = true

  }
}


# Auto scaling group

resource "aws_autoscaling_group" "asg" {
  availability_zones = ["${var.aws_region}a", "${var.aws_region}c"]
  name = "asg-${aws_lunch_configuration.lc.id}"
  max_size = "${var.asg_max}"
  min_size = "${var.asg_min}"
  health_check_grace_period = "{var.asg_grace}"
  health_check_type = "${var.asg_cap}"
  force_delete =true
  load_balancers = ["aws_elb.prod.id"]
  vpc_zone_identifier = ["${aws_subnet.private.id}" ,"${aws_subnet.private2.id}" ]
  lunch_configuration = "${aws_lunch_configuration.lc.name}"
  tags{
    key = "Name"
    value = "asg-instance"
    propagate_at_launch = true
  }
  lifescycle{
    create_before_destory = true
  }
  
}


# Route53 

# primary zone : use deligation set 
resource " aws_route53" "primary" {
  name = "var.domain_name".co.uk
  delegation_set_id = ""{var.delegation_set}
  
}

#www point to load balancer 

resource "aws_route53_record" "www" {
  zone_id ="$aws_route53_zone.primary.zone_id"
  name = "www".${var.domain_name}.co.uk
  type = "A"
  alias {
    name =  "${aws_elb.prod.dns_name}"
    zone_id = "${aws_elb.prod.zone_id}"
    evaluate_target_health = false

  }
  
}

#dev record to point to the dev server public IP address 

resource "aws_route53_record" "dev" { 
  zone_id = "${aws_route53_zone.primary.zone.id}"
  name= "dev.${var.domain_name}.com"
  type = "A"
  ttl = "300"
  records = ["$aws_instance.dev.public.ip"]
}


#db cname for RDS < allow web server to point to the RDs even if the IP changes 

resource "aws_route53" "db" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name = "db.${var.domain_name}.co.uk"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_db_instance.db.address}"]
  
}

# ansible playbook