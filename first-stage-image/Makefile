IMAGE_DESTINATION?=/dev/sdb
DD_OPTIONS?=bs=102400000 oflag=sync

ORG?=tjfontaine

all: first-stage-efi.img

clean:
	rm -f first-stage-efi.img
	rm -f *-stamp

build-pivot: build-pivot-stamp
	
build-pivot-stamp: pivot-second-stage/Dockerfile pivot-second-stage/pivot-second-stage.sh pivot-second-stage/build.yml
	linuxkit pkg build -org ${ORG} pivot-second-stage
	touch $@

first-stage-efi.img: build-pivot-stamp first-stage.yml
	linuxkit build -format raw-efi first-stage.yml

write-image: first-stage-efi.img
	dd if=./first-stage-efi.img of=${IMAGE_DESTINATION} ${DD_OPTIONS}
	sync
