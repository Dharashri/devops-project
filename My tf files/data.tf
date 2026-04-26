data "aws_ami" "e2e" {
   # most_recent = true
   #owners = ["649844050992"]
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20260218"]
    }

}