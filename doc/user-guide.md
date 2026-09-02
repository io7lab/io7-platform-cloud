# io7 Platform — User Guide

This is a follow-along. Do each step, and at the end of it there is a short note on what you
just did and what it taught you. Nothing to study first.

io7 itself is already built, so installing it is two scripts and a few answers. The whole
thing is on video as well, if you would rather watch before you type:
[io7 platform installation](https://www.youtube.com/watch?v=18xfq__oo4E).

Let's put it on a server.

## 1 · Install the platform

Any Linux box with Docker will do. These instructions use AWS EC2 because that is what most
people reach for, but a home server or a VM works the same.

### Prepare the machine

| Item | Recommended |
|---|---|
| OS | Ubuntu 22.04 or 24.04 |
| Instance | t3.small or larger (t3.micro works but leaves little headroom) |
| Storage | 20 GB (the 8 GB default fills up once events start accumulating) |

On a cloud instance — AWS EC2, Google Cloud, Azure, Oracle and the rest — nothing reaches the
machine from outside until you allow it, so open port 22 to SSH in. The creation wizard usually
offers SSH as a tick box. That is all you need to install; the platform's own ports come up in
a moment, once there is something behind them.

On a machine on your own network there is often nothing to do here beyond its local firewall.

### Install

Two scripts, in order. SSH into the machine and run:

```bash
git clone https://github.com/io7lab/io7-platform-cloud.git
bash io7-platform-cloud/setup/setup_docker_nodejs.sh
exit
```

The first script sets the hostname and installs Node.js and Docker. **The `exit` matters** —
it adds you to the `docker` group, which only takes effect on the next login.

Log back in and check that both tools answer:

```bash
docker --version
node --version
```

Now install the platform itself:

```bash
bash io7-platform-cloud/setup/io7-platform-setup.sh
```

It asks four things. Write them down.

| Prompt | Meaning |
|---|---|
| mqtt id / pw | Mosquitto Dynamic Security admin account, used internally by the platform |
| admin id | An email-shaped ID — this is your Management Web login |
| admin pw | At least 8 characters, or the script stops |

> **Run this in a real terminal.** The script uses `docker exec -it` partway through. In a
> non-interactive shell that step fails silently, the install looks successful, and devices
> are rejected later for reasons that are very hard to trace.

### Check it

```bash
docker ps
```

Seven containers should be `Up`: `mqtt`, `nodered`, `redis`, `influxdb`, `io7api`, `io7web`,
`grafana`.

Now open it from your laptop. This is the first time anything reaches the server from outside,
so on a cloud instance the ports have to be allowed first — on AWS that is the instance's
**Security Group**, on other providers a VPC firewall or network rule under a different name.
On your own network, check the machine's firewall if it has one.

| Port | Service | Opened for |
|---|---|---|
| 3000 | Management Web | your browser |
| 2009 | io7 API Server | the Management Web page, behind the scenes |
| 9001 | MQTT over WebSocket | the Management Web page, behind the scenes |
| 1883 | MQTT | devices and applications, from Step 2 onwards |
| 1880 | Node-RED and the dashboard | your browser, once you start building |
| 3003 | Grafana | your browser, if you want the charts |
| 8086 | InfluxDB | your browser, if you want the raw data |

Then browse to `http://<your-host>:3000` and log in with the admin account.

![Management Web home](images/management-web-home.png)

> **If the page loads but the login button does nothing, port 2009 is blocked.** The browser
> loads the page from 3000 but talks to the API server on 2009 and to MQTT on 9001. Each
> blocked port fails in its own quiet way: 3000 → nothing loads, 2009 → login does nothing,
> 9001 → devices never show as online.

Your platform state lives in `~/data` and the compose file is `~/docker-compose.yml`. Those
two are the only things worth backing up; the containers are disposable.


### What you just did

You did not configure a broker, wire up a database, or write a line of code. Two scripts
brought up seven containers and one login screen.

Worth remembering: **the containers are disposable, `~/data` is not.** Everything the platform
knows — your devices, your flows, your history — lives in that one directory. Back it up and
you have backed up the platform.

---

## 2 · Verify with a dummy device

Before wiring anything, prove the whole path works. A dummy device is a terminal program
that behaves exactly like real hardware — same topics, same payloads, same registration.

**Register it.** In Management Web → Device List, add a device with ID `lux1` and a token of
your choosing (`lux1` is fine while learning). Type must be `device`.

**Run it.** On your laptop or on the server — anywhere with Node.js:

```bash
npx github:io7lab/io7dummy-device lux
```

```text
devId: ? lux1
token: ? lux1
broker: ? my.example.com
pubInterval: 5000
```

Answers are saved to `lux.cfg` in the current directory, named after the mode you ran.

A light sensor drawn in ASCII appears and starts publishing every 5 seconds. **Press the up
and down arrow keys** to fake bright and dark — roughly 900 and 200 lux.

**Watch it arrive.** Back in Management Web, `lux1` is now online, and its detail page shows
events streaming in.

![Events arriving](images/management-web-events.png)

If the values on screen change within a second or two of pressing an arrow key, every layer
is working: device → broker → API server → browser.

The platform also kept the last value it saw — the Device Shadow, which the next section
puts in context:

```bash
docker exec -it redis redis-cli GET lux1
```


### What you just did

You registered a device that does not exist and watched it report anyway.

That is not a trick, it is how you will work from here on. **A device is whatever connects
with a registered ID and token and publishes to the right topic.** The dummy is a real device
as far as the platform is concerned — which is why, in Step 5, an ESP32 can take its place
without the platform noticing.

Notice also what you never did: you never told the platform *what* `lux1` is. No schema, no
device type, no driver. You registered a name and it started keeping its data.

---

## 3 · What you just set up

You watched a value travel from a program on your laptop to a web page in your browser. It
passed through six services on the way, and you did not have to know any of them to make it
work. Now that it works, here is what it went through — mostly so that when something breaks,
you know which door to knock on.

![io7 platform architecture](images/architecture.png)

Everything a device does is MQTT publish and subscribe. Everything an application does is
the same. The broker sits in the middle and nobody talks to anybody directly.

| Service | Port | What it does |
|---|---|---|
| Mosquitto | 1883 · 9001 | MQTT broker. 1883 for devices and apps, 9001 for browsers (WebSocket) |
| io7 API Server | 2009 | Device registry and lifecycle. Creates broker credentials when you register a device |
| Management Web | 3000 | Where you register devices, issue app IDs, and watch events arrive |
| Node-RED | 1880 | Where your automation lives, and where the dashboard is served |
| Redis | 6379 | Device Shadow — the last value each device reported |
| InfluxDB | 8086 | Time series history |
| Grafana | 3003 | Charts over that history |

### The contract

A device is anything that follows this topic convention. That is the whole definition — the
platform never asks what language it was written in or what board it runs on.

```text
iot3/<deviceId>/evt/<eventId>/fmt/json     device → platform   (events)
iot3/<deviceId>/cmd/<cmdId>/fmt/json       platform → device   (commands)
```

The payload is always JSON wrapped in a `d` object:

```json
{"d": {"lamp": "on"}}
```

That one rule is why Step 5 and Step 6 can replace the devices from Step 2 without touching
a single node in your flow.

### Two kinds of credentials

| Credential | Held by | Can do |
|---|---|---|
| **Device ID + token** | one device | publish and subscribe on its own `iot3/<deviceId>/…` topics only |
| **App ID + token** | an application (Node-RED, io7app) | subscribe to device events and publish commands |

A device cannot impersonate another device — the broker's access control is generated from
the registry when you register it.

---

---

## Next — the lessons

The platform is running, and you have watched something report to it. That is the setup done;
you will not have to touch it again.

Everything from here is about using it: writing an automation, putting real devices under it,
and moving the pieces around to see what the platform actually buys you.

**[Continue to the lessons →](user-guide-labs.md)**

