#!/bin/bash
# Starts a Prometheus exporter for Graphite 
[[ "$GRAPHITE_TO_PROMETHEUS" != "true" ]] && exit 0
export CONFIG_omero_metrics_graphite=localhost:9091
/bin/graphite_exporter &