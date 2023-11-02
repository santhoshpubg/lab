output "vpc_id" {
    value = aws_vpc.labvpc.id
}
output "subnet_id1" {
    value = aws_subnet.labsubnet1.id
}
output "subnet_id2" {
    value = aws_subnet.labsubnet2.id
}
output "IGW_Name" {
    value = aws_internet_gateway.labig.id
}
output "RT_Name" {
    value = aws_route_table.labrt.id
}
output "Security_Group" {
    value = aws_security_group.labsg.id
}
output "Instances_WEB1" {
    value = aws_instance.web.associate_public_ip_address
}
output "Instances_WEB2" {
    value = aws_instance.web1.associate_public_ip_address
}
output "LB_URL" {
  value = aws_lb.lablb.dns_name
}