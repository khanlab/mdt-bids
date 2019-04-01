FROM khanlab/mdt:v0.20.3

RUN mkdir -p /opt/mdt-bids
COPY . /opt/mdt-bids


ENTRYPOINT ["/opt/mdt-bids/run.sh"]
