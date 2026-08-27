output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_public_dns" {
  value = aws_instance.jenkins.public_dns
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "jenkins_instance_id" {
  value = aws_instance.jenkins.id
}

