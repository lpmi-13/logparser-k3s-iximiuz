# Log Parser Lab on iximiuz Labs

This playground packages a single-node k3s environment for running the operator defined in https://github.com/lpmi-13/logparser-lab-operator.

The operator seeds a `LogParserLab` resource in the `log-lab` namespace, generates one active log file at a time on the VM filesystem, and exposes the notification UI on port `8888`.

## Build

The Dockerfile expects a release-pinned iximiuz rootfs tag:

```sh
docker build \
  --build-arg ROOTFS_RELEASE=<release> \
  --build-arg OPERATOR_REF=main \
  -t ghcr.io/lpmi-13/k3s-logparser-iximiuz:v1 .
```

You can leave out the build args to use the defaults from the Dockerfile.

After publishing the image, update the OCI drive reference in `manifest.yaml` if you want to use a different registry, repository, or tag.
