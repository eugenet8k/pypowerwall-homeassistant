ARG BUILD_FROM=jasonacox/pypowerwall
FROM ${BUILD_FROM}

# Copy the Home Assistant add-on entrypoint
COPY run.py /ha_run.py

# The entrypoint reads /data/options.json, exports every key as an
# environment variable, then exec's whatever the upstream image had as CMD.
ENTRYPOINT ["python3", "/ha_run.py"]
