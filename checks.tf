check "instance_type_recommendation" {
  assert {
    condition     = var.instance_type == "t3.micro"
    error_message = "para este laboratorio se recomienda utilizar t3.micro para mantener una conf pequeña y economica"
  }

}