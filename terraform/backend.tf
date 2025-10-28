terraform {
  backend "s3" {
    bucket = "terraform-state-file-ec2-1995"
    key    = "terraform.tfstate"
    region = "ap-south-1"
    encrypt = false
  }
}
