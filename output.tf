output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_a_id" {
  value = ["${aws_subnet.public_subnet_a.id}"]
}

output "public_subnet_c_id" {
  value = ["${aws_subnet.public_subnet_c.id}"]
}

output "private_subnet_a_id"{
  value = ["${aws_subnet.private_web_a.id}"]
}

output "private_subnet_c_id"{
  value = ["${aws_subnet.private_web_c.id}"]
}

output "private_subnet_2a_id"{
  value = ["${aws_subnet.private_db_2a.id}"]
}

output "private_subnet_2c_id"{
  value = ["${aws_subnet.private_db_2c.id}"]
}
