Embedded Kaniko into serverless Jenkins Archetecture based AWS serverless Jenkins environment on AWS Fargate.
https://aws.amazon.com/blogs/devops/building-a-serverless-jenkins-environment-on-aws-fargate/

An example is included in the `example` directory.
## Prerequisites
The following are required to deploy this Terraform module

1. Terraform 0.14+  - Download at https://www.terraform.io/downloads.html
1. Docker 19+ - Download at https://docs.docker.com/get-docker/
1. A VPC with at least two public and two private subnets. Private subnets will require to have NAT gateway to be able to access resources such as secret manager, as well as update for Jenkins. 
1. An SSL certificate to associate with the Application Load Balancer. It's recommended to use an ACM certificate. This is not done by the main Terraform module. However, the example in the `example` directory uses the [public AWS ACM module](https://registry.terraform.io/modules/terraform-aws-modules/acm/aws/latest) to create the ACM certificate and pass it to the Serverless Jenkins module. You may choose to do it this way or explicitly pass the ARN of a certificate that you had previously created or imported into ACM.
1. An admin password for Jenkins must be stored in SSM Parameter store. This parameter must be of type `SecureString` and have the name `jenkins-pwd`. Username is `ecsuser`.
1. Terraform must be bootstrapped. This means that a state S3 bucket and a state locking DynamoDB table must be initialized.

## Deployment
This is packaged as a Terraform module, which means it's not directly deployable. However, there is a deployable example in the `example` directory. To deploy the example:

1. Ensure you have met all the Prerequisites
2. If necessary, execute the bootstrap in the bootstrap directory. This will create a Terraform state bucket & state locking table. This step may be unnecessary if you already have an established Terraform environment.
3. copy `vars.sh.example` to `vars.sh`
4. Edit the variables in `vars.sh` as necessary giving all details specific to your environment (VPC, subnets, state bucket & state locking table, etc.)
5. Run `deploy_example.sh`
