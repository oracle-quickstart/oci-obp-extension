# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#  

#*************************************
#           AUTH Token
#*************************************

resource "oci_identity_auth_token" "obk-events-auth-token" {
    provider = oci.home
    #Required
    description = "OBP Events Auth Token"
    user_id = data.oci_identity_user.current_user.id
}

#*************************************
#           KMS
#*************************************

resource "oci_kms_vault" "obp-events-vault" {
  #Required
  compartment_id = var.compartment_ocid
  display_name = "Blockchain Platform Events Vault"
  vault_type = "VIRTUAL"
}

resource "oci_kms_key" "obp-events-key" {
  #Required
  compartment_id = var.compartment_ocid
  display_name = "OBP Events Key"
  key_shape {
    #Required
    algorithm = "AES"
    length = "24"
  }
  management_endpoint = oci_kms_vault.obp-events-vault.management_endpoint
}

resource "oci_kms_encrypted_data" "auth-token-encrypt-data" {
  #Required
  crypto_endpoint = oci_kms_vault.obp-events-vault.crypto_endpoint
  key_id = oci_kms_key.obp-events-key.id
  plaintext = base64encode(oci_identity_auth_token.obk-events-auth-token.token)
}

resource "oci_kms_encrypted_data" "username-encrypt-data" {
  #Required
  crypto_endpoint = oci_kms_vault.obp-events-vault.crypto_endpoint
  key_id = oci_kms_key.obp-events-key.id
  plaintext = base64encode(data.oci_identity_user.current_user.name)
}

#*************************************
#           Stream Pool
#*************************************
// Stream Pool
resource "oci_streaming_stream_pool" "obp-events-stream-pool" {
  #Required
  compartment_id = var.compartment_ocid
  name = "Blockchain Platform Events Stream Pool"
  kafka_settings {
    #Optional
    auto_create_topics_enable = true
    log_retention_hours = 24
    num_partitions = 1
  }
}

#*************************************
#           API Gateway
#*************************************
// Gateway
resource oci_apigateway_gateway obp-events-gateway {
  #Required
  compartment_id = var.compartment_ocid
  display_name = "Blockchain Platform Events Gateway"
  endpoint_type = "PUBLIC"
  subnet_id = oci_core_subnet.obp-events-public-subnet.id
}

// gateway Deployment
resource "oci_apigateway_deployment" "obp-events-gateway-deployment" {
  #Required
  compartment_id = var.compartment_ocid
  display_name = "Blockchain Platform Events Gateway Deployment"
  gateway_id = oci_apigateway_gateway.obp-events-gateway.id
  path_prefix = "/obpevents"
  specification {
    routes {
      backend {
        type = "ORACLE_FUNCTIONS_BACKEND"
        function_id = oci_functions_function.obp-events-function.id
      }
      path = "/callback"
      methods = ["POST"]
    }
  }
}

#*************************************
#           Functions
#*************************************
// App
resource "oci_functions_application" "obp-events-application" {
  #Required
  compartment_id = var.compartment_ocid
  display_name = "obpeventsapp"
  subnet_ids = [oci_core_subnet.obp-events-private-subnet.id]
}

// Function
resource oci_functions_function obp-events-function {
  #Required
  application_id = oci_functions_application.obp-events-application.id
  display_name = "obpeventsfunc"
  image = "${lower(data.oci_identity_regions.current_region.regions.0.key)}.ocir.io/${data.oci_identity_tenancy.tenant_details.name}/obpeventsfunc:0.0.1"
  memory_in_mbs = "1024"
  config = {
    "BOOT_STRAP_SERVERS" = oci_streaming_stream_pool.obp-events-stream-pool.kafka_settings[0].bootstrap_servers
    "TENANT_NAME" = data.oci_identity_tenancy.tenant_details.name
    "USER_NAME" = oci_kms_encrypted_data.username-encrypt-data.ciphertext
    "AUTH_TOKEN" = oci_kms_encrypted_data.auth-token-encrypt-data.ciphertext
    "STREAM_OCID" = oci_streaming_stream_pool.obp-events-stream-pool.id
    "KMS_ENDPOINT" = oci_kms_vault.obp-events-vault.crypto_endpoint
    "KMS_KEY_ID" = oci_kms_key.obp-events-key.id
  }

}