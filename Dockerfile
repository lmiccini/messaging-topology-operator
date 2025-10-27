# Build the manager binary
FROM --platform=$BUILDPLATFORM registry.access.redhat.com/ubi9/go-toolset:1.21 as builder

WORKDIR /workspace

USER root
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY main.go main.go
COPY api/ api/
COPY controllers/ controllers/
COPY internal/ internal/
COPY rabbitmqclient/ rabbitmqclient/

# Build
ARG TARGETOS
ARG TARGETARCH
ENV GOOS=$TARGETOS
ENV GOARCH=$TARGETARCH

ARG FIPS_MODE=off
ENV GOFIPS140=$FIPS_MODE

RUN CGO_ENABLED=1 GO111MODULE=on go build -a -tags timetzdata -o manager main.go

# ---
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
WORKDIR /
COPY --from=builder /workspace/manager .
RUN echo "messaging-topology-operator:x:1001:" > /etc/group && \
    echo "messaging-topology-operator:x:1001:1001::/home/messaging-topology-operator:/usr/sbin/nologin" > /etc/passwd

USER 1001:1001

ENTRYPOINT ["/manager"]
