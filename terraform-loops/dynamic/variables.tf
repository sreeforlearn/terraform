variable "ingress_rules" {
  type = list(object({
    port = number
    description = string 
  }))
  
  default = [
   {
     port = 80, description = "HTTP"
   },
   {
     port = 443, description = "HTTPS"
   },
   {
     port = 22, description = "SSH"
   }
  ]
}
