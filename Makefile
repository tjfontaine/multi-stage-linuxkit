all: first-stage second-stage

first-stage:
	$(MAKE) -C first-stage-image

second-stage:
	$(MAKE) -C second-stage-image

clean:
	$(MAKE) -C first-stage-image clean
	$(MAKE) -C second-stage-image clean
