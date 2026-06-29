module "frontend" {
  source        = "../../modules/web-server"
  name          = "dev-frontend"
  ami_id        = "ami-0bc7aabcf58d1e02a"
  instance_type = "t2.nano"
}


