FROM public.ecr.aws/ubuntu/ubuntu:18.04

COPY . .

RUN apt update && \
    apt install -y git curl unzip ca-certificates

ENV ADDITIONAL_CA_CERTS=/ca-certificates
ADD install-certs.sh /tmp/install-certs.sh
RUN chmod a+x /tmp/install-certs.sh && /tmp/install-certs.sh

RUN git clone --depth 1 https://github.com/tfutils/tfenv.git /tmp/tfenv && \
    chmod -R +rx /tmp/tfenv/bin
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
