REGION?=us-phoenix-1
IMAGE_INSTANCE_ID?=ocid1.instance.oc1.phx.abyhqljrquzzxg4nnljvyyqwvyvvis2c26yu6m2jhvzf6w237ptoumpaq7ha
BUILD_INSTANCE_ID?=ocid1.instance.oc1.phx.abyhqljrdnewipeqvfbvfnovh7av4i3horo3a6ppkzopc2djynym2w3nbupq
COMPARTMENT_ID?=ocid1.compartment.oc1..aaaaaaaaev5ibl3jszvrqnox7o7cvrnnvt2mozslyi3dggcuhehkvztka5ea
BOOT_VOLUME_ID?=ocid1.bootvolume.oc1.phx.abyhqljria46hor6xe27hedu44nub424wnbshx2eqpngk6v45lgg5la3zjhq
WAIT_ARGS?=--wait-interval-seconds 3

ISCSI_IP_PORT?=

.PHONY: attach-local-volume detach-local-volume

attach-local-volume:
	oci --region=${REGION} compute instance action --action=stop --instance-id=${IMAGE_INSTANCE_ID} --wait-for-state=STOPPED ${WAIT_ARGS}
	oci --region=${REGION} compute boot-volume detach --force --boot-volume-attachment-id=${IMAGE_INSTANCE_ID} --wait-for-state=DETACHED ${WAIT_ARGS}
	oci --region=${REGION} compute volume-attachment attach --instance-id=${BUILD_INSTANCE_ID} --volume-id=${BOOT_VOLUME_ID} --type=iscsi --wait-for-state=ATTACHED ${WAIT_ARGS}
	sudo iscsiadm -m node -o new -T iqn.2015-02.oracle.boot:uefi -p ${ISCSI_IP_PORT}
	sudo iscsiadm -m node -o update -T iqn.2015-02.oracle.boot:uefi -n node.startup -v automatic
	sudo iscsiadm -m node -T iqn.2015-02.oracle.boot:uefi -p ${ISCSI_IP_PORT} -l

detach-local-volume:
	sudo iscsiadm -m node -T iqn.2015-02.oracle.boot:uefi -p ${ISCSI_IP_PORT} -u
	sudo iscsiadm -m node -o delete -T iqn.2015-02.oracle.boot:uefi -p ${ISCSI_IP_PORT}
	oci --region=${REGION} compute volume-attachment detach --force --volume-attachment-id=$(shell oci --region=us-phoenix-1 compute volume-attachment list --compartment-id=${COMPARTMENT_ID} --instance-id=${BUILD_INSTANCE_ID} | json data | json -ga -c 'this["lifecycle-state"] === "ATTACHED"' id) --wait-for-state=DETACHED ${WAIT_ARGS}
	oci --region=${REGION} compute boot-volume-attachment attach --instance-id=${IMAGE_INSTANCE_ID} --boot-volume-id=${BOOT_VOLUME_ID} --wait-for-state=ATTACHED ${WAIT_ARGS}
	oci --region=${REGION} compute instance action --action=start --instance-id=${IMAGE_INSTANCE_ID} --wait-for-state=RUNNING ${WAIT_ARGS}
