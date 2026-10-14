variable "regiao" {
  description = "Região da AWS onde a API reserva será criada."
  type        = string
  default     = "us-east-1"
}

variable "prefixo" {
  description = "Prefixo dos nomes. Diferente do que será criado ao vivo, para não haver conflito."
  type        = string
  default     = "mural-backup"
}
