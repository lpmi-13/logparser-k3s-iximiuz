# syntax=docker/dockerfile:1
ARG ROOTFS_RELEASE=e2771a49
ARG OPERATOR_REPO=https://github.com/lpmi-13/logparser-lab-operator
ARG OPERATOR_REF=main

FROM golang:1.24 AS operator-builder
ARG OPERATOR_REPO
ARG OPERATOR_REF

WORKDIR /src

RUN git clone --depth 1 --branch "${OPERATOR_REF}" "${OPERATOR_REPO}" .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  go build -trimpath -ldflags="-s -w" -o /out/logparser-lab-operator ./cmd/main.go
RUN cp config/crd/bases/lab.learning.io_logparserlabs.yaml \
  /out/lab.learning.io_logparserlabs.yaml

FROM ghcr.io/iximiuz/labs/rootfs:ubuntu-k3s-server-${ROOTFS_RELEASE}

USER root
ENV HOME=/root

COPY --from=operator-builder /out/logparser-lab-operator /usr/local/bin/logparser-lab-operator
COPY --from=operator-builder /out/lab.learning.io_logparserlabs.yaml /opt/logparser-lab-operator/lab.learning.io_logparserlabs.yaml
COPY image/default-logparserlab.yaml /opt/logparser-lab-operator/default-logparserlab.yaml
COPY image/bootstrap-logparser-lab.sh /opt/iximiuz-labs/bootstrap-logparser-lab.sh
COPY image/logparser-lab-operator.service /etc/systemd/system/logparser-lab-operator.service
COPY image/logparser-lab-seed.service /etc/systemd/system/logparser-lab-seed.service

RUN <<'INNER'
set -eu

chmod 755 /opt/iximiuz-labs/bootstrap-logparser-lab.sh
chmod 755 /usr/local/bin/logparser-lab-operator

mkdir -p /var/log/log-lab
chown -R laborant:laborant /var/log/log-lab

for cmd in awk grep sed sort uniq head wc jq yq rg task just websocat btop kubectl; do
  command -v "${cmd}" >/dev/null 2>&1 || {
    echo "missing expected tool: ${cmd}"
    exit 1
  }
done

test -x /root/.fzf/bin/fzf
test -x /home/laborant/.fzf/bin/fzf
grep -q "FZF_DEFAULT_COMMAND='rg --files'" /home/laborant/.bashrc

ln -sf /etc/systemd/system/logparser-lab-operator.service \
  /etc/systemd/system/multi-user.target.wants/logparser-lab-operator.service
ln -sf /etc/systemd/system/logparser-lab-seed.service \
  /etc/systemd/system/multi-user.target.wants/logparser-lab-seed.service
INNER

USER laborant
ENV HOME=/home/laborant
