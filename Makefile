all: make-docs

make-docs:
	naturaldocs \
		--rebuild \
		--documented-only \
		--input cake \
		--output HTML docs \
		--project docs/project