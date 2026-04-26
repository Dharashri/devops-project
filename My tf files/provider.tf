provider "aws" {
    region = "us-east-1"
    assume_role {
        role_arn     = "arn:aws:iam::649844050992:role/tfrole"
        session_name = "tfss"
        external_id  = "Dhara"
    }
}