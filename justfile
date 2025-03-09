[private]
default:
    @just --list

# generate terraform docs
gen:
    terraform-docs markdown modules/hub > modules/hub/README.md
    terraform-docs markdown modules/spoke > modules/spoke/README.md