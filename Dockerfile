FROM davidfrantz/force

LABEL FORCE='3.8.00'
LABEL maintainer="David Frantz, University of Trier, Germany"

USER root
RUN mkdir -p /var/cache/apt/archives/partial
RUN apt-get update && apt-get install -yq s3cmd jq gettext

# copy the wrapper script to the container
COPY resources/force-level2-wrapper.sh /opt/apex-force-wrapper/bin/
COPY resources/*.template /opt/apex-force-wrapper/etc/

ENV PATH=$PATH:/opt/force-wrapper/bin
