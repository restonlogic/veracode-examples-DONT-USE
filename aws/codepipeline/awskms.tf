resource "aws_kms_key" "s3key" {}

resource "aws_kms_alias" "s3key-a" {
  name          = "alias/myKmsKey"
  target_key_id = aws_kms_key.s3key.key_id
}