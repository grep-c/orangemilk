terraform {
  backend "s3" {
    bucket         = "omk-tfstate-113c8"
    key            = "orangemilk/lab/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "omk-tf-locks"
    encrypt        = true
  }
}
