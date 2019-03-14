build:
	@docker build -t "centospg112" . | tee .centospg112

run:
	@docker run --rm -it $(shell grep "Successfully built" .centospg112 | cut -d ' ' -f 3) /bin/bash
