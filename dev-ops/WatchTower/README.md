# WatchTower — Service Observability Stack

A complete observability stack for Reyla Logistics' three backend services: **order-service**, **tracking-service**, and **notification-service**. This stack gives the team real-time visibility into service health, request rates, error rates, and proactive alerting — so problems are caught before customers notice.

---

## Architecture Diagram

┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   order-service   │     │ tracking-service  │     │notification-service│
│   :3001            │     │   :3002            │     │   :3003            │
│   /health /metrics │     │   /health /metrics │     │   /health /metrics │
└─────────┬──────────┘     └─────────┬──────────┘     └─────────┬──────────┘
│                          │                          │
│   scrape every 15s       │                          │
└──────────────┬───────────┴──────────────┬───────────┘
│                          │
▼                          ▼
┌──────────────────────────────────────┐
│            Prometheus :9090            │
│  - scrapes /metrics from all 3 services│
│  - evaluates alerts.yml every 15s      │
│  - rules: ServiceDown, HighErrorRate,  │
│           ServiceNotScraping           │
└───────────────────┬────────────────────┘
│
▼
┌──────────────────────────────────────┐
│              Grafana :3000              │
│  - Prometheus as data source            │
│  - Auto-provisioned dashboard:          │
│    • HTTP Request Rate (per service)    │
│    • 5xx Error Rate (per service)       │
│    • Service Health Status              │
└──────────────────────────────────────┘

All services run on a shared Docker network (`watchtower-net`) and communicate by service name.

---

## Setup Instructions

### Prerequisites
- Docker & Docker Compose installed

### Start the Stack

```bash
# 1. Copy the environment template
cp .env.example .env

# 2. Start everything
docker compose up --build
```

This starts:
| Service | Port | URL |
|---|---|---|
| order-service | 3001 | http://localhost:3001 |
| tracking-service | 3002 | http://localhost:3002 |
| notification-service | 3003 | http://localhost:3003 |
| Prometheus | 9090 | http://localhost:9090 |
| Grafana | 3000 | http://localhost:3000 |

### Verify Everything Is Working

**1. Check all services respond:**
```bash
curl http://localhost:3001/health
curl http://localhost:3002/health
curl http://localhost:3003/health
```
Each should return `{"status":"ok"}` (or equivalent).

**2. Check Prometheus is scraping all targets:**

Open **http://localhost:9090/targets**

✅ All three services (`order-service`, `tracking-service`, `notification-service`) show as **UP**.

**3. Check Grafana dashboard loads automatically:**

Open **http://localhost:3000** — no login/import required. The **"WatchTower Service Observability"** dashboard is provisioned automatically and loads on first access.

---

## Dashboard Walkthrough

The dashboard (`grafana/dashboards/watchtower.json`) contains three panels:

### 1. HTTP Request Rate
Shows requests-per-second for each service (`order-service`, `tracking-service`, `notification-service`) as separate lines, computed from the `http_requests_total` counter using `rate()`. Useful for spotting traffic spikes or drops.

### 2. 5xx Error Rate
Shows the rate of HTTP 5xx responses per service. In a healthy system this stays at **"No data"** / zero — any non-zero value indicates server errors are occurring.

### 3. Service Health Status
A stat panel showing each service's current `up` value from Prometheus — **1** means the service is up and being scraped successfully, **0** means it's down or unreachable.

All three panels load automatically via Grafana provisioning — no manual dashboard import is needed.

---

## Alerting

Alert rules are defined in [`prometheus/alerts.yml`](./prometheus/alerts.yml) and loaded into Prometheus via `prometheus.yml`. View them at **http://localhost:9090/alerts**.

| Alert | Condition | Severity | Status |
|---|---|---|---|
| `ServiceDown` | `probe_success == 0` for 1m | critical | ✅ Loaded, OK |
| `HighErrorRate` | 5xx rate > 5% over 5m, for 1m | warning | ✅ Loaded, OK |
| `ServiceNotScraping` | `up == 0` for 2m | warning | ✅ Loaded, OK |

All three rules are confirmed loaded and evaluating every 15 seconds (visible on the Prometheus Alerts page).

### How Each Alert Was Tested

**`ServiceNotScraping` / `ServiceDown`** — Stop one service while the rest of the stack keeps running:

```bash
docker compose stop notification-service
```

Wait 1–2 minutes, then check **http://localhost:9090/alerts**:
- `ServiceNotScraping` transitions from **OK → PENDING → FIRING** (after 2 minutes, since `up == 0` for `notification-service`)
- `ServiceDown` transitions similarly if the health probe also fails (after 1 minute)

The Grafana **Service Health Status** panel for `notification-service` drops from `1` to `0` within one scrape interval (15s).

Restart the service to clear the alert:
```bash
docker compose start notification-service
```
Both alerts return to **OK** within one evaluation cycle (15s) once scraping resumes, plus the `for:` duration to fully resolve.

**`HighErrorRate`** — Generate 5xx responses by hitting a non-existent or error-triggering endpoint repeatedly:

```bash
for i in {1..50}; do curl -s -o /dev/null http://localhost:3001/__force_error; done
```

If the error rate over the 5-minute window exceeds 5%, `HighErrorRate` transitions to **PENDING** then **FIRING** after the `for: 1m` duration. Once traffic returns to normal (or stops), the rate falls back under 5% and the alert resolves automatically.

---

## Structured Logging

Docker Compose is configured with the `json-file` log driver for every service, so all logs are written in structured JSON format.

### View live logs from all services at once:

```bash
docker compose logs -f
```

Example output:
order-service_1        | {"level":"info","msg":"Order created","orderId":"a1b2c3","timestamp":"2026-06-11T22:30:45.123Z"}
tracking-service_1     | {"level":"info","msg":"Tracking updated","trackingId":"t9z8y7","status":"in-transit","timestamp":"2026-06-11T22:30:46.001Z"}
notification-service_1 | {"level":"info","msg":"Notification sent","channel":"sms","timestamp":"2026-06-11T22:30:46.500Z"}

### Filter logs to show only errors from a specific service:

```bash
docker compose logs notification-service | grep '"level":"error"'
```

Example output:
notification-service_1 | {"level":"error","msg":"Failed to send notification","channel":"email","error":"SMTP timeout","timestamp":"2026-06-11T22:31:02.778Z"}

---

## File Structure
dev-ops/WatchTower/
├── README.md
├── docker-compose.yml
├── .env.example
├── app/
│   ├── order-service/
│   ├── tracking-service/
│   └── notification-service/
├── prometheus/
│   ├── prometheus.yml
│   └── alerts.yml
└── grafana/
├── provisioning/
│   ├── datasources/
│   │   └── prometheus.yml
│   └── dashboards/
│       └── dashboard.yml
└── dashboards/
└── watchtower.json

screenshots/
├── grafana-dashboard.png
├── prometheus-targets.png
├── prometheus-alerts.png
└── blackbox-exporter.png
---


## Screenshots

### Grafana Dashboard

**URL:** `http://localhost:3000`

The Grafana dashboard provides a real-time view of service health and performance metrics collected from Prometheus. It includes:

* HTTP Request Rate per service
* 5xx Error Rate monitoring
* Service Health Status panel
* Auto-provisioned dashboards and data sources

![Grafana Dashboard]

<img width="1440" height="798" alt="Screenshot 2026-06-12 at 11 57 00 AM" src="https://github.com/user-attachments/assets/646b2123-02f7-4358-8bdb-3f1611f1d03b" />

<img width="1440" height="822" alt="Screenshot 2026-06-12 at 11 57 15 AM" src="https://github.com/user-attachments/assets/958ee8be-a080-4042-b821-f572fff30705" />


**Expected Result**

* All services displayed as healthy (`1`)
* Request rate graphs updating in real time
* Error rate panel showing `0` or `No Data` during normal operation

---

### Prometheus Targets & Alerts

**Targets URL:** `http://localhost:9090/targets`
**Alerts URL:** `http://localhost:9090/alerts`

Prometheus continuously scrapes metrics from all backend services and evaluates alert rules every 15 seconds.

![Prometheus Targets]

<img width="1440" height="798" alt="Screenshot 2026-06-12 at 11 57 55 AM" src="https://github.com/user-attachments/assets/8353bc61-77a8-4e7b-a487-0aefe261e66c" />

![Prometheus Alerts]

<img width="1440" height="795" alt="Screenshot 2026-06-12 at 11 57 29 AM" src="https://github.com/user-attachments/assets/480316a1-bd18-48b5-85d6-655248dc3e74" />


**Expected Result**

| Job                  | Health |
| -------------------- | ------ |
| order-service        | UP     |
| tracking-service     | UP     |
| notification-service | UP     |
| blackbox-probe       | UP     |

Configured alert rules:

* ServiceDown
* HighErrorRate
* ServiceNotScraping

All alerts should remain **Inactive/OK** while services are healthy.

---

### Blackbox Exporter

**URL:** `http://localhost:9115`

Blackbox Exporter performs independent HTTP health checks against all backend services and exposes probe metrics to Prometheus.

Monitored endpoints:

* `http://order-service:3001/health`
* `http://tracking-service:3002/health`
* `http://notification-service:3003/health`

![Blackbox Exporter]
<img width="1440" height="797" alt="Screenshot 2026-06-12 at 11 58 07 AM" src="https://github.com/user-attachments/assets/c1962f0e-f905-49eb-aae1-121c1a613f5a" />

<img width="1440" height="796" alt="Screenshot 2026-06-12 at 11 58 32 AM" src="https://github.com/user-attachments/assets/1b4e6fe9-bb40-420d-ade2-50277589e851" />

**Expected Result**

* `probe_success = 1`
* HTTP status code `200`
* Response time metrics available
* All probe targets reported as `UP`

This validates service availability independently of application-level metrics and provides an additional layer of monitoring.

## Design Decisions

### Why Prometheus + Grafana
The de facto standard observability pair for containerised services — Prometheus's pull-based scraping requires no instrumentation changes beyond exposing `/metrics`, and Grafana's provisioning system lets dashboards and data sources be version-controlled and auto-loaded with zero manual setup.

### Why a Shared Docker Network
All services, Prometheus, and Grafana communicate by service name (`order-service`, `tracking-service`, etc.) over `watchtower-net`. This means Prometheus's scrape targets in `prometheus.yml` are simply `order-service:3001`, `tracking-service:3002`, `notification-service:3003` — no hardcoded IPs, fully portable.

### Why `.env` for Configuration
Ports and service names are environment-variable driven so the same Compose file works across local dev, CI, and other environments without editing YAML — just swap `.env`.

### Alert Design
- **`ServiceDown`** (critical, 1m) catches outright outages fast — this is the alert that should have paged someone *before* the angry customer calls, per the original problem statement.
- **`HighErrorRate`** (warning, 5m window) catches degraded-but-not-down states — e.g. a downstream dependency failing intermittently.
- **`ServiceNotScraping`** (warning, 2m) catches a different failure mode: Prometheus itself losing connectivity to a target, which `ServiceDown` alone wouldn't necessarily indicate.

---

## Pre-Submission Checklist

- ✅ `docker compose up --build` starts all services, Prometheus, and Grafana with no errors
- ✅ `.env.example` committed; real `.env` is gitignored
- ✅ Prometheus `/targets` shows all three services as **UP**
- ✅ Grafana dashboard loads automatically without manual import
- ✅ All three alert rules present in `prometheus/alerts.yml`, each with summary + description
- ✅ README documents how each alert was tested
- ✅ Architecture diagram included
- ✅ Both log commands documented with example output
- ✅ Commit history shows incremental progress
- ✅ Repository set to Public
