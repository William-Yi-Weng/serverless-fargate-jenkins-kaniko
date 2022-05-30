data "aws_ecr_authorization_token" "token" {}

locals {
  ecr_endpoint        = split("/", aws_ecr_repository.jenkins_controller.repository_url)[0]
  kaniko_ecr_endpoint = split("/", aws_ecr_repository.jenkins_kaniko.repository_url)[0]
}


resource "aws_ecr_repository" "jenkins_controller" {
  name                 = var.jenkins_ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

}

data "template_file" "jenkins_configuration_def" {

  template = file("${path.module}/docker/files/jenkins.yaml.tpl")

  vars = {
    ecs_cluster_fargate      = aws_ecs_cluster.jenkins_controller.arn
    ecs_cluster_fargate_spot = aws_ecs_cluster.jenkins_agents.arn
    cluster_region           = local.region
    jenkins_cloud_map_name   = "controller.${var.name_prefix}"
    jenkins_controller_port  = var.jenkins_controller_port
    jnlp_port                = var.jenkins_jnlp_port
    agent_security_groups    = aws_security_group.jenkins_controller_security_group.id
    execution_role_arn       = aws_iam_role.ecs_execution_role.arn
    subnets                  = join(",", var.jenkins_controller_subnet_ids)
    kaniko_ecr_endpoint      = aws_ecr_repository.jenkins_kaniko.repository_url
    task_role_arn            = aws_iam_role.jenkins_controller_task_role.arn
  }
}


resource "null_resource" "render_template" {
  triggers = {
    src_hash = file("${path.module}/docker/files/jenkins.yaml.tpl")
  }
  depends_on = [data.template_file.jenkins_configuration_def]

  provisioner "local-exec" {
    command = <<EOF
tee ${path.module}/docker/files/jenkins.yaml <<ENDF
${data.template_file.jenkins_configuration_def.rendered}
EOF
  }
}

resource "null_resource" "build_docker_image" {
  triggers = {
    src_hash = file("${path.module}/docker/files/jenkins.yaml.tpl")
  }
  depends_on = [null_resource.render_template, null_resource.build_kaniko_docker_image]
  provisioner "local-exec" {
    command = <<EOF
docker login -u AWS -p ${data.aws_ecr_authorization_token.token.password} ${local.ecr_endpoint} && \
docker build -t ${aws_ecr_repository.jenkins_controller.repository_url}:latest ${path.module}/docker/ && \
docker push ${aws_ecr_repository.jenkins_controller.repository_url}:latest
EOF
  }
}

resource "aws_ecr_repository" "jenkins_kaniko" {
  name                 = var.jenkins_ecr_repository_kaniko_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

}

data "template_file" "kaniko_script_def" {

  template = file("${path.module}/kaniko/files/scripts/execute.sh.tpl")

  vars = {
    repository_url = local.kaniko_ecr_endpoint
  }
}

resource "null_resource" "render_kaniko_template" {
  triggers = {
    src_hash = file("${path.module}/kaniko/files/scripts/execute.sh.tpl")
  }
  depends_on = [data.template_file.kaniko_script_def]

  provisioner "local-exec" {
    command = <<EOF
tee ${path.module}/kaniko/files/scripts/execute.sh <<ENDF
${data.template_file.kaniko_script_def.rendered}
EOF
  }
}

data "template_file" "kaniko_config_def" {

  template = file("${path.module}/kaniko/files/config.json.tpl")

  vars = {
    repository_url = local.kaniko_ecr_endpoint
  }
}

resource "null_resource" "render_kaniko_config" {
  triggers = {
    src_hash = file("${path.module}/kaniko/files/config.json.tpl")
  }
  depends_on = [data.template_file.kaniko_config_def]

  provisioner "local-exec" {
    command = <<EOF
tee ${path.module}/kaniko/files/config.json <<ENDF
${data.template_file.kaniko_config_def.rendered}
EOF
  }
}

resource "null_resource" "build_kaniko_docker_image" {
  triggers = {
    src_hash = file("${path.module}/kaniko/files/scripts/execute.sh.tpl")
  }
  depends_on = [null_resource.render_kaniko_template, null_resource.render_kaniko_config]
  provisioner "local-exec" {
    command = <<EOF
# Build Jenkins kaniko image
docker login -u AWS -p ${data.aws_ecr_authorization_token.token.password} ${local.kaniko_ecr_endpoint} && \
docker build -t ${aws_ecr_repository.jenkins_kaniko.repository_url}:latest ${path.module}/kaniko/ && \
docker push ${aws_ecr_repository.jenkins_kaniko.repository_url}:latest
EOF
  }
}
