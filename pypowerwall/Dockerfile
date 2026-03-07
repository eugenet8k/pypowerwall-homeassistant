ARG BUILD_FROM=jasonacox/pypowerwall
FROM ${BUILD_FROM}

# Copy the Home Assistant add-on entrypoint
COPY run.sh /ha_run.sh
RUN chmod +x /ha_run.sh

# The entrypoint reads /data/options.json, exports every key as an
# environment variable, then exec's whatever the upstream image had as CMD.
ENTRYPOINT ["/ha_run.sh"]
