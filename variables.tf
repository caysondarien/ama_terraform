variable "resource_group_location" {
  default     = "eastus"
  description = "Location of the resource group"
}

variable "dc-password" {
  type    = string
  default = "4nGY-p1zzA!"
}

variable "safemode_password" {
  type        = string
  description = "The password for the Safe mode Administrator account"
  default     = "P@ssword123"
  sensitive   = true
}

variable "domain_name" {
  type        = string
  description = "The Domain Name e.g. ama.local"
  default     = "ama.local"
  sensitive   = false
}

variable "crypto_provider" {
  type        = string
  description = "CryptoProvider e.g. ECDSA_P256#Microsoft Software Key Storage Provider"
  default     = "ECDSA_P256#Microsoft Software Key Storage Provider"
  sensitive   = false
}

variable "private_ip_addr" {
  type        = string
  default     = "10.23.0.100"
  description = "Private IP Address for DC01"
}