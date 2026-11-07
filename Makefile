# Thin wrappers around scripts/. Examples:
#   make setup            install LaTeX (if missing) + needed packages
#   make new T=thesis N=my-thesis
#   make build D=docs/my-thesis
#   make watch D=docs/my-thesis
#   make release D=docs/my-thesis V=1.0
#   make diff D=docs/my-thesis OLD=my-thesis/v1.0 [NEW=my-thesis/v1.1]
#   make check            make install-tex [PROFILE=basic|full]
#   make templates        build every template (smoke test)

S := bash scripts

.PHONY: help setup new build watch clean release diff check install-tex templates

help:
	@sed -n '1,10p' Makefile | sed 's/^# \{0,1\}//'

setup:    ; $(S)/setup.sh
new:      ; $(S)/new-doc.sh $(T) $(N)
build:    ; $(S)/build.sh $(D)
watch:    ; $(S)/build.sh $(D) --watch
clean:    ; $(S)/build.sh $(D) --clean
release:  ; $(S)/release.sh $(D) $(V)
diff:     ; $(S)/diff.sh $(D) $(OLD) $(NEW)
check:    ; $(S)/check-tex.sh
install-tex: ; $(S)/install-tex.sh --profile $(or $(PROFILE),basic)
templates:
	@for t in templates/*/; do $(S)/build.sh $$t || exit 1; done
