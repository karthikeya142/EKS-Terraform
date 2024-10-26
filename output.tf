output "cluster_id" {
  value = aws_eks_cluster.karthik.id
}

output "node_group_id" {
  value = aws_eks_node_group.karthik.id
}

output "vpc_id" {
  value = aws_vpc.kt_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.kt_subnet[*].id
}
