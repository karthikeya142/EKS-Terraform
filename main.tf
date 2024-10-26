

provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "kt_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "karthik-vpc"
  }
}

resource "aws_subnet" "kt_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.kt_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.kt_vpc.cidr_block, 4, count.index)
  availability_zone       = element(["us-east-2a", "us-east-2b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "karthikt-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "kt_igw" {
  vpc_id = aws_vpc.kt_vpc.id

  tags = {
    Name = "karthik-igw"
  }
}

resource "aws_route_table" "kt_route_table" {
  vpc_id = aws_vpc.kt_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kt_igw.id
  }

  tags = {
    Name = "karthik-route-table"
  }
}

resource "aws_route_table_association" "a" {
  count          = 2
  subnet_id      = aws_subnet.kt_subnet[count.index].id
  route_table_id = aws_route_table.kt_route_table.id
}

resource "aws_security_group" "kt_cluster_sg" {
  vpc_id = aws_vpc.kt_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "karthik-cluster-sg"
  }
}

resource "aws_security_group" "kt_node_sg" {
  vpc_id = aws_vpc.kt_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "karthik-node-sg"
  }
}

resource "aws_eks_cluster" "karthik" {
  name     = "karthik-cluster"
  role_arn = aws_iam_role.karthik_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.kt_subnet[*].id
    security_group_ids = [aws_security_group.kt_cluster_sg.id]
  }
}

resource "aws_eks_node_group" "karthik" {
  cluster_name    = aws_eks_cluster.karthik.name
  node_group_name = "karthik-node-group"
  node_role_arn   = aws_iam_role.karthik_node_group_role.arn
  subnet_ids      = aws_subnet.kt_subnet[*].id

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t2.medium"]

  remote_access {
    ec2_ssh_key               = var.ssh_key_name
    source_security_group_ids = [aws_security_group.kt_node_sg.id]
  }
}

resource "aws_iam_role" "karthik_cluster_role" {
  name = "karthik-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "karthik_cluster_role_policy" {
  role       = aws_iam_role.karthik_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "karthik_node_group_role" {
  name = "karthik-node-group-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "karthik_node_group_role_policy" {
  role       = aws_iam_role.karthik_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karthik_node_group_cni_policy" {
  role       = aws_iam_role.karthik_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karthik_node_group_registry_policy" {
  role       = aws_iam_role.karthik_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
