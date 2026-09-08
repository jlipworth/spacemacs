# These load-order tests intentionally do not initialize Spacemacs or install
# packages.  Package directories are explicit, read-only test dependencies.
EMACS ?= emacs
ORG_DIR ?=
OX_GFM_DIR ?=

.PHONY: test
test:
	@test -n "$(OX_GFM_DIR)" || (echo 'Set OX_GFM_DIR to an installed ox-gfm directory'; exit 1)
	$(EMACS) -Q --batch $(if $(ORG_DIR),-L "$(ORG_DIR)") \
		-L "$(OX_GFM_DIR)" -l ox-gfm-utest.el \
		-f ert-run-tests-batch-and-exit
