all: second-stage-squashfs.img

second-stage-squashfs.img: second-stage.yml
	linuxkit build -format kernel+squashfs second-stage.yml
	cp second-stage-squashfs.img /nfs/stable/latest/squashfs.img

clean:
	rm -f second-stage-*
