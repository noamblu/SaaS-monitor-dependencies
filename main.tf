# 1. Install dependencies locally if no layer provided
resource "null_resource" "pip_install" {
  triggers = {
    requirements_diff = filemd5("${path.module}/src/requirements.txt")
  }

  provisioner "local-exec" {
    command = "pip install -r ${path.module}/src/requirements.txt -t ${path.module}/layer/python"
  }
}

# 2. Archive the layer directory
data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/layer"
  output_path = "${path.module}/layer.zip"
  excludes    = ["__pycache__", "*.pyc"]

  depends_on = [null_resource.pip_install]
}

# 3. Create Layer Version
resource "aws_lambda_layer_version" "dependencies" {
  filename            = data.archive_file.layer_zip.output_path
  layer_name          = "saas-monitor-dependencies-layer"
  compatible_runtimes = ["python3.9", "python3.10", "python3.11", "python3.12"] # Broad compatibility
  source_code_hash    = data.archive_file.layer_zip.output_base64sha256
}

resource "aws_schemas_registry" "this" {
  name        = "saas-monitor-registry"
  description = "Schema Registry for SaaS Monitor"
  tags        = var.tags
}
