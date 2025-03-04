[private]
default:
    @just --list

# generate terraform docs
gen:
    terraform-docs markdown module > module/README.md