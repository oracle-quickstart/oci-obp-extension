# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

#*************************************
#               VCN
#*************************************

resource "oci_core_vcn" "obp-events-vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id =   var.compartment_ocid
  dns_label      = "obp"
  display_name = "Blockchain Platform Events VCN"
}

#*************************************
#           Subnet
#*************************************

resource "oci_core_subnet" "obp-events-public-subnet" {
  #Required
  cidr_block     = "10.0.0.0/24"
  compartment_id =   var.compartment_ocid
  vcn_id         = oci_core_vcn.obp-events-vcn.id
  display_name   = "OBP Events - Public"

  # Public Subnet
  prohibit_public_ip_on_vnic = false
  dns_label                  = "eventspublic"
  route_table_id = oci_core_route_table.obp-events-public-rt.id
  security_list_ids = [oci_core_security_list.obp-events-public-sl.id]
}

resource "oci_core_subnet" "obp-events-private-subnet" {
  #Required
  cidr_block     = "10.0.1.0/24"
  compartment_id =   var.compartment_ocid
  vcn_id         = oci_core_vcn.obp-events-vcn.id
  display_name   = "OBP Events - Private"

  # Private Subnet
  prohibit_public_ip_on_vnic = true
  dns_label                  = "eventsprivate"
  route_table_id = oci_core_route_table.obp-events-private-rt.id
  security_list_ids = [oci_core_security_list.obp-events-private-sl.id]
}


#*************************************
#         Internet Gateway
#*************************************

resource "oci_core_internet_gateway" "obp-events-gateway" {
  #Required
  compartment_id =   var.compartment_ocid
  vcn_id         = oci_core_vcn.obp-events-vcn.id

  #Optional
  display_name = "Blockchain Platform Events Internet Gateway"
  enabled      = true
}

#*************************************
#         NAT Gateway
#*************************************

resource "oci_core_nat_gateway" "obp-events-nat-gateway" {
  #Required
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.obp-events-vcn.id

  #Optional
  display_name = "Blockchain Platform Events Nat Gateway"
}


#*************************************
#           Route Tables
#*************************************

resource "oci_core_route_table" "obp-events-public-rt" {
  #Required
  compartment_id =   var.compartment_ocid
  vcn_id         = oci_core_vcn.obp-events-vcn.id
  display_name = "OBP Events Public RT"

  // Internet Gateway
  route_rules {
    #Required
    network_entity_id = oci_core_internet_gateway.obp-events-gateway.id

    #Optional
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }

}

resource "oci_core_route_table" "obp-events-private-rt" {
  #Required
  compartment_id =   var.compartment_ocid
  vcn_id         = oci_core_vcn.obp-events-vcn.id
  display_name = "OBP Events Private RT"

  // NAT Gateway
  route_rules {
    #Required
    network_entity_id = oci_core_nat_gateway.obp-events-nat-gateway.id

    #Optional
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }

}

#*************************************
#         Security List
#*************************************

resource "oci_core_security_list" "obp-events-public-sl" {
  #Required
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.obp-events-vcn.id
  display_name = "OBP Events Public SL"
  # Egress - Allow All
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol = "All"
    stateless = false
    destination_type = "CIDR_BLOCK"

  }
  # Ingress - Allow All
  ingress_security_rules {
    #Required
    protocol = "All"
    source = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless = false
  }
}

resource "oci_core_security_list" "obp-events-private-sl" {
  #Required
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.obp-events-vcn.id
  display_name = "OBP Events Private SL"
  # Egress - Allow All
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol = "All"
    stateless = false
    destination_type = "CIDR_BLOCK"
  }
  # Ingress - Allow All
  ingress_security_rules {
    #Required
    protocol = "All"
    source = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless = false
  }
}
