# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

locals {
  ssl_server = join(":" , [replace(substr(oci_apigateway_deployment.obp-events-gateway-deployment.endpoint,8, -1 ), "/obpevents" , "" ) , "443"])
}
output "OBP_Event_Subscribe_Callback"{
  value = join("" , [oci_apigateway_deployment.obp-events-gateway-deployment.endpoint , oci_apigateway_deployment.obp-events-gateway-deployment.specification.0.routes.0.path])
}

output "use_to_extract_ssl_certificate" {
  value = local.ssl_server
}