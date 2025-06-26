FROM s0ands0/dockerized-charmbracelet_freeze:v0.0.12


RUN apk add --no-cache gawk jq


COPY entrypoint.sh /
COPY freeze-first-fenced-code-block-to-image.sh /


ENTRYPOINT ["bash"]
CMD ["/entrypoint.sh"]


##
#
LABEL org.opencontainers.image.description="GitHub Action to parse and convert first found code block in files to image via Freeze"
LABEL org.opencontainers.image.license="AGPL-3.0"
LABEL org.opencontainers.image.source="https://github.com/gha-utilities/freeze-first-code-blocks"
LABEL org.opencontainers.image.title="Freeze "
LABEL org.opencontainers.image.version="0.0.1"
