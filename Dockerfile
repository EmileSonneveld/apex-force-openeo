# build image with
# docker build -t quay.io/bcdev/force-eoap:0.0.4 .
# Push to registery that is available in openEO backend:
# skopeo copy --multi-arch=all --format=oci docker-daemon:quay.io/bcdev/force-eoap:0.0.4 docker://registry.stag.warsaw.openeo.dataspace.copernicus.eu/rand/force-eoap:0.0.4

FROM davidfrantz/force

LABEL FORCE='3.8.00'
LABEL maintainer="David Frantz, University of Trier, Germany"

USER root
RUN mkdir -p /var/cache/apt/archives/partial
RUN apt-get update && apt-get install -yq jq gettext python3 curl

# Install s5cmd from GitHub releases
RUN curl -L -o s5cmd.tar.gz https://github.com/peak/s5cmd/releases/download/v2.2.2/s5cmd_2.2.2_Linux-64bit.tar.gz && \
    tar -xzf s5cmd.tar.gz && \
    mv s5cmd /usr/local/bin/ && \
    chmod +x /usr/local/bin/s5cmd && \
    rm s5cmd.tar.gz LICENSE README.md CHANGELOG.md 2>/dev/null || true

# copy the wrapper script to the container
COPY resources/force-level2-wrapper.sh /opt/apex-force-wrapper/bin/
COPY resources/*.template /opt/apex-force-wrapper/etc/

ENV PATH=$PATH:/opt/force-wrapper/bin
