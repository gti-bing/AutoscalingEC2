# Create autoscaling infrastructure using Terraform

This is a project for building a microbiome search engine that allow researcher to gather studies and generate visualization using Amazon services.

The terraform code build an VPC that housing different modules that needed to serve the search engine website. The following three modules are created for the backend processing and allocated in the private subnet.

## Data Engineering Module
This is the key module that takes FASTQ file and feed into the Qiime2 pipeline to generate the merged sequencing results and visualization. This module is part of the autoscaling group which allows the system to spin up/down EC2 depends on the server load. Details can be found in the autoscaling.tf file.

## Data Collection API
This module takes the input request from the search engine website and query/download the sequencing data from NCBI SRA public database.

## Post Processor API
This module is in charge of generating merged sequencing results using Qiime2 and return the visualization data for front end user.

## Website Application
The front end is hosted in the public subnet and CI/CD deployment pipeline will be created using AWS CodePipeline. Detail implementation can be found in codebuild.tf, codedeploy.tf and codepipeline.tf.

### Prerequisite
Before you run this Terraform project, you have to complete the following setup on your Amazon account.

* Create Parameters
  
  Under your AWS Systems Manager --> Parameter Store, please create the following parameters.

  | Name | AMI Value
  | --- | --- |
  | webserver-custom | ami-05df5e71da6167ac5
  | qiime2-server | ami-09cfe9d7d8c7ed99f
  | postprocessorapi | ami-0413813467ad9f98a
  | datacollectionapi | ami-00616fba1c6cd360c

* Create AWS S3 bucket
  
    This is the location to store SRA sequencing data and user uploaded sequencing data. The following is the folder structure. They should be mounted to all modules. You can refer to main.tf to see how it is being mounted.

 * qiime2storage
   * merged_results
     * private
     * public
   * single_results
     * private
     * public
   * studies
     * private
     * public
   * tmp

    Also, you need to create the access key under IAM in order to access the S3 bucket. Then save the key to location ${HOME}/.s3fs-creds on each of the modules.

* Configure CodePipeline Github Connect

    Follow this [User Guide](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-github.html) to create a connection to GitHub.

  
* Create Amazon RDS Postgres SQL database
  
    Detail instructions please refer to Github link (TBD)


* Install Terraform
  
    Please following this [Get Started with Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) to install Terraform on your local environment.

### Create the infrastructure in AWS

Step 1: Initialization
```
terraform init
```

Step 2: Planning
```
terraform plan
```

Step 3: Create
```
terraform apply
```

Step 4: Delete (**Only** do this will undo the entire infrastructure)
```
terraform destroy
```

## Post launch 
Once all the modules are created. You have to get the IP address for each of the three modules in the private subnet and update the API end points in the website application. Below are the pre-configured IP address, and you need to replace them with the new private IP address.

Data Collection API - 44.232.220.91
Post Processor API - 44.236.252.211

If you want to connect to the website server, you have to use either EC2 connect or ssh. The ssh key can be found in the root directory of the this Terraform project.

To connect to each of the modules in the private subnet, you have to upload the ssh key to the website application EC2, then use it as a bridge.

## Contact
If you have any questions or concerns, please feel free to email us yueb81@gmail.com.
