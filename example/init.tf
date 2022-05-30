/*
The deploy_example.sh script in this directory consumes variables in vars.sh and
then initializes Terraform. The values you see below will be over written by the
deploy_example.sh script and therefore do not need to be updated.
*/
terraform {
  required_version = ">= 0.13"
  backend "s3" {
    bucket = "my-state-bucket-willtest"
    key    = "serverless-jenkins.tfstate"
    encrypt = true
  }
}

provider "aws" {
    region = "ap-southeast-2"
    access_key=""
    secret_key=""
}
