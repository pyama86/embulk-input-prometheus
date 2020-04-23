# Prometheus input plugin for Embulk

Load from prometheus time series data.

## Configuration

```yaml
in:
  type: prometheus
  url: https://example.com
  query: "(100 * (1 - avg by(instance, consul_dc)(irate(node_cpu_seconds_total{job=~\".*node.exporter\",mode='idle'}[1m]))))"
  since: 86400    # sec
  step: 3600      #sec
  tls:
    cert_path: "/path/to/api.crt"
    key_path: "/path/to/api.key"
    ca_path: "/path/to/api.ca"
```
