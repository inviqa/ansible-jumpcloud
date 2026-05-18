# syntax=docker/dockerfile:1.2

FROM quay.io/inviqa_images/ansible:2.20-python3.13-trixie

STOPSIGNAL SIGTERM

COPY tests/requirements.txt /tmp/ansible-jumpcloud-requirements.txt
COPY tests/requirements.yml /tmp/ansible-jumpcloud-requirements.yml

USER root

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    --mount=type=cache,target=/root/.cache \
    set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        curl \
        docker-cli \
    ; \
    python3 -m pip install \
        --root-user-action=ignore \
        -r /tmp/ansible-jumpcloud-requirements.txt; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

USER ansible

RUN ansible-galaxy collection install \
        -r /tmp/ansible-jumpcloud-requirements.yml \
        -p /home/ansible/.ansible/collections

CMD ["sleep", "infinity"]
