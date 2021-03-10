job "prometheus" {
  datacenters = ["VOID"]
  namespace = "monitoring"
  type = "service"

  group "app" {
    count = 1

    volume "prometheus" {
      type = "host"
      read_only = false
      source = "prometheus"
    }

    network {
      mode = "bridge"
      port "http" {
        to = 9090
        static = 9090
      }
    }

    service {
      name = "prometheus"
      port = "http"
      tags = ["traefik.enable=true", "traefik.http.routers.prometheus.tls=true"]

      check {
        type = "http"
        address_mode = "host"
        path = "/-/healthy"
        timeout = "30s"
        interval = "15s"
      }
    }

    task "prometheus" {
      driver = "docker"

      volume_mount {
        volume = "prometheus"
        destination = "/prometheus"
        read_only = false
      }

      config {
        image = "prom/prometheus:v2.22.0"
        ports = ["http"]
        args = [
          "--config.file=/local/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles"
        ]
      }

      template {
        data = file("./prometheus.yml")
        destination = "local/prometheus.yml"
        perms = 644
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      artifact {
        source = "https://raw.githubusercontent.com/void-linux/void-infrastructure/master/services/configs/prometheus/alerts/prometheus.yml"
        destination = "local/alerts/"
      }
      artifact {
        source = "https://raw.githubusercontent.com/void-linux/void-infrastructure/master/services/configs/prometheus/alerts/node_exporter.yml"
        destination = "local/alerts/"
      }
    }
  }
}
