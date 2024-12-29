
# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "custom-ecs-cluster"

  tags = {
    Name = "ecs-cluster"
  }
}
