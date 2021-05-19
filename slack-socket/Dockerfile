FROM python:3.9-slim-buster

RUN apt-get update && \
    apt-get upgrade && \
    apt-get install -y curl ca-certificates

ENV ADDITIONAL_CA_CERTS=/ca-certificates
ADD install-certs.sh /tmp/install-certs.sh
RUN chmod a+x /tmp/install-certs.sh && /tmp/install-certs.sh

COPY . .
RUN pip config set global.cert /etc/ssl/certs/ca-certificates.crt
RUN pip install -r requirements.txt

RUN chmod +x /entrypoint.py

ENTRYPOINT ["python", "/entrypoint.py"]
