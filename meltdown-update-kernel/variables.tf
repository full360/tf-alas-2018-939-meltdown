variable filter { default = "Name=tag:MeltdownUpdateKernel,Values=true" }
variable "enable_add_key" { default = false }
variable "enable_remove_key" { default = false }
variable "enable_patch_meltdown" { default = false }
variable "enable_patch_kernel_tag" { default = false }
