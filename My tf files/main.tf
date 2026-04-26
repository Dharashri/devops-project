resource "aws_instance" "e2e-ec2" {
    for_each = toset(["master","agent"])
    ami = data.aws_ami.e2e.id
    instance_type = local.instance_type
    key_name = local.key
    security_groups = [aws_security_group.e2e-sg.id]
    tags = {
        name = "devops-${each.key}"
    }
}

resource "aws_security_group" "e2e-sg" {
    name = "ubuntu-sg"
    description = "Allow ports 22, 8080, 80, 443 from Anywhere"

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }
    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }
    ingress {
        description = "HTTPS"
        from_port = 443
        to_port = 443
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }
    ingress {
        description = "App"
        from_port = 8080
        to_port = 8080
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }
    egress {
        description = "Allow all"
        from_port = 0
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"] 
        protocol = "-1"     #All protocols
    }
}