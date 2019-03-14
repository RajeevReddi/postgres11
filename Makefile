build:
	@docker build -t "centospg112" . | tee .centospg112

run:
	@docker run --name pg11 -id centospg112 postgres
