kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: ${efs_system_id}
  directoryPerms: "777"
  uid: "1000"
  gid: "1000"
  gidRangeStart: "1000" # optional
  gidRangeEnd: "1000" # optional
  basePath: "/dynamic_provisioning" # optional