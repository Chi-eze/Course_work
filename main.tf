provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

##----IAM----Role

#S3 Roles, s3_access

resource "aws_iam_instance_profile" "s3_access_profile" {
  name = "s3_access"
  role = "${aws_iam_role.s3_access_role.name}"
  }

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy"
  role = "${aws_iam_role.s3_access_role.id}"
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

resource "aws_iam_role" "s3_access_role" {
  name = "s3_access_role"
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
EOF
}


#-------------VPC------------

resource "aws_vpc" "skies_vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags{
    Name = "Sky_VPC"

  }
}

#--------- Internet Gate way---------

resource "aws_internet_gateway" "skies_internet_gateway" {
  vpc_id = "${aws_vpc.skies_vpc.id}"
}
tags {
  Name = "Sky_igw"
}
#-----------Public route table-----------------------

resource "aws_route_table" "skies_public_rt" {
   vpc_id = "${aws_vpc.skies_vpc.id}"
   route { 
          cidr_block = "0.0.0.0/0"
          gateway_id = "${aws_internet_gateway.skies_internet_gateway.id}"
   }
    tags {
          Name = "sky_Public"
    }
}

#------------------Private Route table-------------------
resource  "aws_defualt_route_table"  "skies_private_rt" {
  default_route_table_id = "${aws_vpc.skies_vpc.defult_route_table_id}"
  tags {
    Name = "Sky_Private"
  }
}
#Subnets

#----------public subnet------------
 resource "aws_subnet" "skies_public1_subnet" {
   vpc_id ="${aws_vpc.skies_vpc.id}"
   cidr_block = "${var.cidrs["public1"]}"
   map_public_ip_on_launch = true 
   availability_zone = "eu-west-1a"
   tags {
     Name ="Sky_public1"
   }

 }

resource "aws_subnet"  "skies_public2_subnet"{
  cidr_block = "${var.cidrs["public2"]}"
  map_public_ip_on_launch = true
  availability_zone = "eu-west-1b"
  tags {
    Name = "sky_public2"
  }
}


#---------------Private 1----------------------

resource "aws_subnet" " skies_private1_subnet" {
  vpc_id = "${aws_vpc.skies_vpc.id}"
  cidr_block = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = false
  availability_zone = "eu-west-1c"
  tags {
    Name ="Sky_private1"
  }
}
# -------------------Private 2---------------------

resource "aws_subnet" "skies_private2_subnet" {
  vpc_id ="${aws_vpc.skies_vpc.id}"
  cider_block = "${var.cidrs["private2"]}"
  map_public_ip_on_launch = false
  availability_zone = "eu-west-1a"
  tags{
    Name = "sky_private2"
  }
  
}
 

#RDS sub net group  RDS-1 RDS -2 RDS -3 
#--------------RDS-1---------------------

resource "aws_subnet" "skies_rds1_subnet" {
  vpc_id = "${aws_vpc.skies_vpc.id}"
  cidr_block = "${var.cidrs[rds1]}"
  map_public_ip_on_launch = false
  availability_zone = "eu-west-1a"

  tags {
    Name = "Sky_rds1_Subnet"
    }
}

#-----------------------RDS -2--------------------
resource "aws_subnet" "skies_rds2_subnet" {
  vpc_id = "${aws_vpc.skies_vpc.id}"
  cidr_block = "${var.cidrs["rds2"]}"
  map_public_ip_on_launch = false
  availability_zone = "eu-west-1b"

  tags {
    Name = "Sky_rds2_subnet"
  }
}
#-------------------RDS -3-----------------------

resource "aws_subnet" "skies_rds3_subnet" {
  vpc_id = "${aws_vpc.skies_vpc.id}"
  cider_block = "10.0.1.6.0/24"
  map_public_ip_on_launch = false
  availability_zone = "eu-west-1d"
  tags {
    Name = "Sky_rds2_subnet"
  }
}

#------------RDS Subnet Group -------

resource "aws_db_subnet_group" "skies_rds_subnetgroup" {
  name = "skies_rds_subnetgroup"
  subnet_ids = ["${aws_subnet.skies_rds1_subnet.id}","${aws_subnet.skies_rds2_subnet.id}","${aws_subnet.skies_rds3_subnet.id}"]
tags {

  Name = "Sky_rds_sng"
}
  
}

# < Associate subnet with routing tabel >


#-------------Public1 association-------------
resource "aws_route_table_association" "skies_public1_assoc" {
  subnet_id = "${aws_subnet.skies_public1_subnet.id}" 
  route_table_id = "${aws_route_table.skies_public_rt.id}"
  tags{

    Name = "sky_pub1_sub_prt_assoc"
  }
}

#----------------Public2- association------------------
resource "aws_route_table_association" "skies_public2_assoc" {
  subnet_id = "${aws_subnet.skies_public2_subnet.id}"
  route_table_id = "${aws_route_table.skies_public_rt.id}"
  
}



#Private association

#----------------------private1-------------------

resource "aws_route_table_association" "skies_private1_assoc" {
  subnet_id = "${aws_subnet.skies_private1_subnet.id}" 
  route_table_id = "${aws_defualt_route_table.skies_private_rt.id}"

  tags {
    Name = "sky_pri1_sub_pvrt_assoc"
  }
  
}

resource "aws_route_table_association" "skies_private2_assoc" {
  subnet_id = "${aws_subnet.skies_private2_subnet.id}"
  route_table_id = "${aws_defualt_route_table.skies_private_rt.id}"

  tags {
    Name = "sky_pri2_sub_pvrt_assoc" 

  }
  
}

# Security Group

#-----------------skies-dev--------------------

resource "aws_security_group" "skies_dev_sg" {
  name = "skies_dev_sg"
  description = "used to access the dev instance"
  vpc_id = "${aws_vpc.skies_vpc.id}"
 #SSH
 ingress {
   from_port = 22
   to_port = 22
   protocol = "tcp"
   cidr_blocks = ["${var.localip}"]
 } 
#HTTP
ingress {
  from_port = 80
  to_port = 80
  protocol =  "tcp"
  cidr_blocks = ["${var.localip}"]
}

egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
}


resource  "aws_security_group" "skies_public_sg" {
  name = "sg_public"
  description = "used for the ELB for public access"
  vpc_id = "${aws_vpc.skies_vpc.id}"
# HTTP
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cider_blocks = ["0.0.0.0/0"]
  }
    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
   }

}
  
# Private security Group

resource "aws_security_group" "skies_private_sg" {
  name = "sg_private"
  description = "used for private instances"
  vpc_id = "${aws_vpc.skies_vpc.id}"

  # Access from VPC
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.vpc_cidr}"] 
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0 /0"]
  }

}
  
#RDS security Group

resource "aws_security_group" "skies_rds_sg" {
  name = "skies_sg_rds"
  description = "used for RDS instances"
  vpc_id = "${aws_vpc.skies_vpc.id}"

  #SQL access from public/private security group

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = ["${aws_security_group.skies_dev_sg.id}","${aws_security_group.skies_public_sg.id}","${aws_security_group.skies_private_sg}"]
  }
}

#----------------create S3 VPC endpoint---------------------
resource "aws_vpc_endpoint" "skies_private-s3_endpoint" {
  vpc_id = "${aws_vpc.skies_vpc.id}"
  service_name = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = ["${aws_vpc.skies_vpc.main_route_table_id}","${aws_route_table.skies_public_rt.id}"]
  policy = <<POLICY
  {
    "Statement" : [
      {
        "Action": "*",
        "Effect": "Allow"
        "Resource": "*"
        "Principle": "*"
      }
    ]
  }
  POLICY
}

#--------------------S3 Code Bucket-----------------

resource "ramdom_id" "skies_code_bucket" {
  byte_length = 2 
  }

resource  "aws_s3_bucket" "code" {
  bucket = "${var.domain_name}-${ramdom_id.skies_code_bucket.dec}"
  acl = "private"
   # this allows terraform to distory the bucket even with content 
  force_destory = true
  tags {
    Name = "Sky_Code bucket"
  }
}


#--------------------RDS------------------------------

resource "aws_db_instance" "skies_db" {
    allocated_storage   = 10
    engine              = "mysql"
    engine_version      =  "8.0"
    instance_class      = "${var.db_instance_class}"
    name                = "${var.dbname}"
    username            = "${var.dbuser}"
    password            = "${var.dbpassword}"
    db_subnet_group_name = "${aws_db_subnet_group.skies_rds_subnetgroup.name}"
    vpc_security_group_ids = ["${aws_security_group.skies_rds_sg.id}"]
    skip_final_snapshot = true

}



#Load balancer 
resource "aws_elb" "skies_elb" {
  name = "${var.domain_name}-elb"
  subnets = ["${aws_subnet.skies_public1_subnet.ids}","${aws_subnet.skies_public2_subnet.ids}"]
  security_groups = ["${aws_security_group.skies_public_sg.id}"]
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "https"
  }
  
  health_check {
    healthy_threshold = "${var.elb_healthy_threshold}"
    unhealthy_threshold = "${var.elb_unhealthy_threshold}"
    timeout = "${var.elb_timeout}"
    target = "HTTP:80"
    internal = "${var.elb_interval}"
  }
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  tags{
    name = "Sky_${var.domain_name}-elb"

  }
}


##Key Pair 

#<<--------------Key_Pair---------->>

# so what this is doing is importing the content of the public key file uploading them to amazone and creating a new key based on this information 
#(Note: this will not upload the private key to your instances only the public so if yopu need to connect to one of your private instances from your public instance as a bashing host you will need to use
# ssh -a  to forward the key agent or you will need to copy the private key to your host , ] )

resource "aws_key_pair" "skies_auth" {
  key_name = "${var.key_name}"
  public_key =  "${file(var.public_key_path)}"
}


#Compute

#--------------------Dev Sever -------------------------

resource "aws_instance"  "skies_dev" {
  instance_type = "${var.dev_instance_type}"
  ami = "${var.dev_ami}"
  tags {
    Name = "Sky_dev"
  }
  key_name = "${aws_key_pair.skies_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.skies_dev_sg.id}"]
  iam_instance_profile  = "${aws_iam_instance_profile.s3_access.id}"
  subnet_id = "${aws_subnet.skies_public1_subnet.id}"

  provisioner "local-exec"{
  command = <<EOD
  cat <<EOF > aws_hosts
  [dev]
  ${aws_instance.skies_dev.public_ip}
  [dev:vars]
  s3code=${aws_s3_bucket.code.bucket}
  domain=${var.domain_name}
  EOF
  EOD
}
provisioner  "local-exec" {
  command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.skies_dev.id} --profile podosky && ansible-playbook -i aws_hosts apache.yml"
}
 
}

#Ramdom

#--------------Ramdom-ami---------------------

resource "ramdom_id" "gold_ami" {
  byte_length = 3

  }

  ### AMI
  #--------------Gold ami---------------------
resource "aws_ami_from_instance" "skies_gold" {
  name               = "skies_ami-${random_id.gold_ami.b64}"
  source_instance_id = "${aws_instance.skies_dev.id}"
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


#--------------Lunch configuration----------------

resource  "aws_lunch_configuration"  "skies_lc" {
  name_prefix = "skies_lc-"
  image_id = "${aws_aim_from_instance.skies_gold.id}"
  instance_type = "${var.lc_instance_type}"
  security_groups = ["${aws_security_group.skies_private_sg.id}"]
  iam_instance_profile = "${aws_aim_instance_profile.s3_access_profile.id}"
  key_name =  "${aws_key_pair.skies_auth.id}"
  user_data = "${file("userdata")}"
  lifecycle = {
    create_before_destory = true
  }
}

# ------------------Auto scaling group------------------------

resource "aws_autoscaling_group" "skies_asg" {
  availability_zones = ["${var.aws_region}a", "${var.aws_region}c"]
  name = "asg-${aws_lunch_configuration.lc.id}"
  max_size = "${var.asg_max}"
  min_size = "${var.asg_min}"
  health_check_grace_period = "{var.asg_grace}"
  health_check_type = "${var.asg_hct}"
  desired_capacity = "${var.asg_cap}"
  force_delete = true
  load_balancers = ["${aws_elb.skies_elb.id}"]
  vpc_zone_identifier = ["${aws_subnet.skies_private1_subnet.id}" ,"${aws_subnet.skies_private2_subnet.id}"]
  lunch_configuration = "${aws_lunch_configuration.skies_lc.name}"
  tags{
    key = "Name"
    value = "Sky_asg-instance"
    propagate_at_launch = true
  }
  lifescycle {
    create_before_destory = true
  }
  
}



# ----------------Route53 --------------------

# primary zone : use deligation set 
resource " aws_route53_zone" "primary" {
  name = "${var.domain_name}.co.uk"
  delegation_set_id = "{var.delegation_set}"
}
#-------------------www point to load balancer-------------------
resource "aws_route53_record" "www" {
  zone_id ="${aws_route53_zone.primary.zone_id}"
  name = "www.${var.domain_name}.co.uk"
  type = "A"
  alias {
    name =  "${aws_elb.skies_elb.dns_name}"
    zone_id = "${aws_elb.skies_elb.zone_id}"
    evaluate_target_health = false

  }
  
}

#------------------dev route53-record to point to the dev server public IP address -------------------

resource "aws_route53_record" "dev" { 
  zone_id = "${aws_route53_zone.primary.zone.id}"
  name= "dev.${var.domain_name}.co.uk"
  type = "A"
  ttl = "300"
  records = ["${aws_instance.skies_dev.public.ip}"]
}

#-------------------Private zone----------------------------

resource "aws_route53_zone" "secondary" {
  name = "${var.domain_name}.co.uk"
  vpc_id = "${aws_vpc.skies_vpc.id}"
}

#---------------------------DB---------------
resource "aws_route53" "db" {
  zone_id = "${aws_route53_zone.secondary.zone_id}"
  name = "db.${var.domain_name}.co.uk"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_db_instance.db.address}"]
  }

















  















# ansible playbook