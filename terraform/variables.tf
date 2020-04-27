# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#  

variable "compartment_ocid" {
}

variable "tenancy_ocid" {
}

variable "region" {
}


variable "user_ocid" {

}

variable "private_key_path"{

}

variable "fingerprint"{
  
}

data "oci_identity_user" "current_user" {
  #Required
  user_id = var.user_ocid

}

data "oci_identity_tenancy" "tenant_details" {
  #Required
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_regions" "home-region" {
  filter {
    name   = "key"
    values = [data.oci_identity_tenancy.tenant_details.home_region_key]
  }
}

data "oci_identity_regions" "current_region" {
  filter {
    name = "name"
    values = [var.region]
  }
}