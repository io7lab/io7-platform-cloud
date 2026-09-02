# io7 Platform — 3 · Logging and security

*Guide: [Install and verify](1-install-and-verify.md) · [Build an automation](2-build-an-automation.md) · **Logging and security***

By now you have a platform, some devices, and an automation you built in
[Part 2](2-build-an-automation.md).

Two things are still missing, and both are the kind you notice only when it is too late.
Your data disappears the moment nobody is looking, and everything you have built so far
travels the network in plain text.

Same shape as before: do the step, then read what it taught you.

| | What you do | Needs |
|---|---|---|
| Step [9](#9--keep-the-data) | Turn on logging and see yesterday's readings | nothing |
| Step [10](#10--chart-it-in-grafana) | Build a chart, then put it in your dashboard | nothing |
| Step [11](#11--get-told-when-something-happens) | Have it message you when a value goes wrong | a Telegram bot |
| Step [12](#12--lock-it-down) | Put TLS on the whole platform, devices included | a domain name |

---

## 9 · Keep the data

Everything you have built so far only knows *now*. Refresh the dashboard and yesterday is
gone. The platform can keep the history for you — it just does not do it uninvited.

**Turn it on.** Management Web → **Settings**:

- **Monitored Devices** — which devices to record. Add `lux1` and `lamp1`.
- **Monitored Fieldsets** — which keys inside their events to record. Add `lux`.

That is the whole setup. From now on the API server writes every matching event into
InfluxDB, into the bucket `bucket01`, under the measurement `alldevices`, tagged with the
device it came from:

```text
alldevices,device=lux1 lux=214 <timestamp>
```

Only numbers are kept. Time-series storage is for values you can average and plot, so
`{"d":{"lamp":"on"}}` is not written — `lamp` is a word, not a measurement.

**Watch it fill up.** Leave the lux dummy running for a few minutes, pressing the arrow keys
now and then, then open InfluxDB at `http://<your-host>:8086` and use Data Explorer: bucket
`bucket01` → measurement `alldevices` → field `lux` → Submit. Your arrow presses are on the
screen as a line.

The Management Web home page has a Grafana panel built in, so the same data shows up there
without you doing anything.

### What you just did

You ticked two boxes and the platform started remembering.

Worth noticing what it did *not* ask for: no schema, no table, no migration. Time-series
storage takes a measurement name, a tag and a number, and that is the whole contract. This
is also why only numbers made it in.

And you chose what to keep. A device sends everything it knows; you decide what is worth
storing. Left unbounded, an IoT system will happily fill a disk with values nobody will
ever read.

---

## 10 · Chart it in Grafana

Grafana came with the platform, on port 3003. It has never seen your data, though — it
needs to be pointed at InfluxDB once.

**Connect the data source.** Log in at `http://<your-host>:3003` with the admin account,
then **Connections → Add new connection → InfluxDB**:

| Field | Value |
|---|---|
| Name | `io7db` |
| Query language | **Flux** |
| URL | `http://influxdb:8086` |
| Organization | `io7org` |
| Token | your InfluxDB API token |
| Default Bucket | `bucket01` |

**Save & test** should come back green.

> **Query language is the one that catches people.** It defaults to InfluxQL, which does not
> work with InfluxDB 2.x. If the test fails, check that dropdown before you start doubting
> the token.

The URL is `influxdb`, not your hostname, for the same reason Node-RED's io7-hub used
`mqtt` — these are containers on one Docker network, talking by service name.

**Build a panel.** New dashboard → Add visualisation → pick `io7db`. The query builder is
enough: `bucket01` → `_measurement = alldevices` → `device = lux1` → `_field = lux`. Set the
time range to the last hour and your readings are drawn.

**Put it where you already look.** A Grafana panel has a **Share → Snapshot / public link**
option. Take that URL, drop a `ui-template` widget into the Node-RED dashboard you built in
Step 4, and paste an `<iframe>` pointing at it. Now live control and history sit on one page.

### What you just did

You gave the same data a second reader.

Notice that nothing about the devices, the flow or the topics changed to make this happen.
The events went to the broker, the API server wrote them down, and Grafana read them back
later. Each part only knows the one next to it — which is why you could add a whole
visualisation layer without touching anything you had already built.

That is the practical shape of it: **Node-RED is for what is happening now, InfluxDB and
Grafana are for what happened.** Live state comes from the broker and the Device Shadow;
history comes from the database.

---

## 11 · Get told when something happens

A dashboard is only useful while someone is looking at it. For anything that matters, the
system should reach out instead.

**Make a bot.** In Telegram, talk to `@BotFather`, `/newbot`, and keep the token it gives
you. Send your new bot a message, then open this in a browser to find the chat it belongs to:

```text
https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates
```

The `chat.id` in the JSON is the second thing you need.

**Tell Grafana where to send things.** **Alerting → Contact points → Add contact point**,
name it `telegram`, integration **Telegram**, and paste the token and chat ID. There is a
test button — use it, and check your phone.

**Write the rule.** **Alerting → Alert rules → New alert rule**. Query the same lux data,
set the condition (`IS ABOVE 800`, say), give it an evaluation interval, and select the
`telegram` contact point. Then push the dummy sensor into bright with the arrow keys and
wait for the evaluation to come round.

### What you just did

You closed the loop that started in Step 4.

Look at what the system can now do on its own: it reads a sensor, decides, acts on a device,
records what happened, and tells a person when something is worth their attention. Nobody
has to be watching for any of it.

The last piece is the one people forget. **An alert that fires too often gets muted, and a
muted alert is the same as no alert.** Threshold and evaluation interval are not settings to
get technically right; they are a judgement about what genuinely deserves to interrupt
someone.

---

## 12 · Lock it down

Everything so far has been in the clear. Your device tokens, your commands, your admin
login — all of it crosses the network as plain text on port 1883, and anyone on the path can
read it or replay it.

This step fixes that for the whole platform at once. **You need a domain name pointing at
the server** — a free dynamic DNS name from noip.com or afraid.org is fine. Certificates are
issued to names, never to IP addresses.

**Get a certificate.** Open port 80 (Let's Encrypt has to reach your server to verify the
name), then:

```bash
bash io7-platform-cloud/setup/get_letsencrypt_cert.sh my.example.com
```

It runs certbot in a throwaway container and leaves you three files in your home directory:
`ca.pem`, `cert.crt` and `cert.key`.

**Switch the platform over.** Open port **8883**, then:

```bash
bash io7-platform-cloud/setup/io7-platform-secure.sh \
     -ca ca.pem -cert cert.crt -fqdn my.example.com
```

The `-fqdn` must be exactly the name on the certificate. The script rewrites the compose
file, Mosquitto's config and Node-RED's settings, then restarts everything — a minute or two
of downtime, and your devices will drop off while it happens. It keeps `.nossl` backups of
every file it touches, and `io7-platform-nonsecure.sh` puts it all back.

Check with `docker ps` that seven containers are up and that `mqtt` now shows **8883**. Your
web addresses are `https://` from here on.

**Two things the script cannot do for itself**, because they are data inside services rather
than config files:

- **The Grafana data source** still points at `http://influxdb:8086`. Edit it to `https://`
  and tick **Skip TLS Verify** — the certificate is for `my.example.com`, not for the
  internal name `influxdb`, so the name check would fail. Traffic stays encrypted.
- **The io7-hub in Node-RED** still says port 1883. Tick **Use TLS** and change it to 8883.

**Bring a device across.** Copy `ca.pem` onto the ESP32 with Thonny — from the server,
`scp ubuntu@my.example.com:/home/ubuntu/ca.pem .` fetches it first. Make sure `device.cfg`
uses the FQDN as its broker, then reset the board. IO7FuPython finds `ca.pem` on its own and
connects over MQTTS. A finished example is in
[`11.iot-lamp-secure`](https://github.com/io7lab-lab/11.iot-lamp-secure).

**Close port 1883.** Nothing uses it now, and leaving it open means a device could still be
talked into using it.

### What you just did

You encrypted a running system without rewriting any of it.

The devices did not change — one file copied onto the board, one address checked. The flows
did not change. The dashboard did not change. That is what a certificate buys you: identity
and encryption underneath everything, without anything above having to care.

Two ideas are worth taking away. **A certificate is issued to a name**, which is why the
whole step began with a domain and why the internal `influxdb` connection needed the name
check skipped. And **security is a switch you throw for the whole platform, not per device** —
the moment the broker stopped accepting 1883, every device had to come across, and the ones
that could not would have gone silent instead of quietly staying insecure.

Renewal is the part that catches people. Let's Encrypt certificates last 90 days. Copy the
new `iothub.crt` and `iothub.key` into `~/data/certs/` and restart, or write it into cron
now while you are thinking about it.

---

---

## What you learned

Twelve steps, one small system, and a set of ideas that carry over to any IoT work whether or
not you keep using io7.

**A device is a contract, not a thing.** `iot3/<deviceId>/evt/...` to report,
`iot3/<deviceId>/cmd/...` to be commanded, `{"d": {...}}` inside. Anything that honours that is
a device — a Node.js dummy, a MicroPython board, a C++ sketch. That is why you swapped the
hardware twice and changed the language once without rewriting the application.

**Automation is three moves.** Something reports, the application decides, something is
commanded. Every flow you built was a variation on it, and nothing in the middle needed to
know what was on either end.

**Keep the decision out of the device.** You never reflashed a board to change a policy. The
lamp did not know about the switch; the switch did not know about the light sensor. Changing
what the system *does* meant editing a flow, not a firmware.

**Report reality, not intention.** The devices published the state of their own pins, not the
command they received. That single habit is why the dashboard stayed correct no matter who
pressed what.

**The field names are the real agreement.** The topics are fixed by the framework; the words
inside the payload are not. `button: "pushed"` and `switch: "on"` cost you a line of code in
Step 6, and that is the cheap version of a problem that gets expensive between teams.

**Decide where to decide.** Cloud gives you reach, history and one place to change policy;
local gives you a rule that survives an outage. Step 7 let you have both, and the choice is
per rule, not per system.

**Both halves are replaceable.** The device layer swapped three ways, and in Step 8 the
application layer swapped too. What stayed fixed the whole time was the broker and the topic
convention. Everything else was yours to choose.

---

**Store what you will actually read.** Ticking two boxes started the history, and only numbers
went in. Left unbounded an IoT system will fill a disk with values nobody ever looks at, so
deciding what to keep is part of the design, not an afterthought.

**Now and then are different questions.** The broker and the Device Shadow answer what is
happening; InfluxDB and Grafana answer what happened. You added a whole visualisation layer in
Step 10 without touching a device, a flow or a topic.

**An alert nobody trusts is not an alert.** Fire too often and it gets muted, and a muted alert
is the same as none. The threshold is a judgement about what deserves to interrupt someone.

**Security is a switch for the platform, not for each device.** The moment the broker stopped
accepting 1883 every device had to come across. And a certificate is issued to a name, which
is why the whole step began with a domain.

---

## Where to go next

You have the whole platform: devices, automation, a dashboard, history, alerts and TLS.

A few directions people take from here.

**The optional steps**, if you skipped them — [Step 7](2-build-an-automation.md#7--move-the-rule-to-an-edge-server)
puts a rule on a Raspberry Pi so it keeps working when the internet does not, and
[Step 8](2-build-an-automation.md#8--rebuild-it-in-python-with-io7app) rebuilds the same
automation in Python with io7app.

**Your own devices.** The pattern from Steps 5 and 6 holds for anything: publish
`{"d": {...}}` to `iot3/<deviceId>/evt/status/fmt/json`, subscribe to the command topic, and
the platform treats it like everything else you have built.

**Operational habits.** Back up `~/data` — it is the whole platform. Watch the disk, because
time-series data grows quietly. Set an InfluxDB retention policy before it becomes urgent.
And rotate device tokens the way you would any other credential.

---

## Running Node-RED somewhere else

Everything above used the Node-RED that came with the platform. You can just as well point
your own at it — one you already run, or one on a machine closer to your devices.

Install Node-RED the usual way, then add the io7 nodes from **Manage palette → Install** by
searching `node-red-contrib-io7`. Two settings differ from the guide:

| Setting | Bundled Node-RED | Your own |
|---|---|---|
| io7-hub **Host** | `mqtt` | your platform's hostname |
| Port 1883 | already reachable inside Docker | must be open to that machine |

`mqtt` is a Docker service name. It resolves only inside the platform's own network, so a
Node-RED anywhere else has to be given the real address.

For the curious: that is also how the bundled one gets the nodes. `io7-platform-setup.sh`
finishes by running `npm i` in `~/data/nodered`, where the shipped `package.json` lists
`node-red-contrib-io7` as a dependency — and since that directory is mounted into the
container, the nodes are in the palette the moment it starts.

---

---

## Reference

### Ports

| Port | Service |
|---|---|
| 1883 | MQTT |
| 9001 | MQTT over WebSocket (browsers) |
| 1880 | Node-RED and the dashboard |
| 2009 | io7 API Server |
| 3000 | Management Web |
| 3003 | Grafana |
| 8086 | InfluxDB |
| 6379 | Redis (internal) |

### Dummy device modes

```bash
npx github:io7lab/io7dummy-device <mode>
```

`lamp` · `switch` · `button` · `lux` · `rotary` · `thermo` · `thermostat` · `valve` ·
`twoButtons`

Settings are saved as `<mode>.cfg` in the working directory.

### Repositories

| Repo | Contents |
|---|---|
| [io7-platform-cloud](https://github.com/io7lab/io7-platform-cloud) | The cloud platform and its install scripts |
| [io7-platform-edge](https://github.com/io7lab/io7-platform-edge) | The edge server |
| [IO7FuPython](https://github.com/io7lab/IO7FuPython) | MicroPython device framework |
| [IO7F32](https://github.com/io7lab/IO7F32) | Arduino C++ device framework (ESP32) |
| [io7app](https://github.com/io7lab/io7app) | Python application framework |
| [io7dummy-device](https://github.com/io7lab/io7dummy-device) | Simulated devices |
| [node-red-contrib-io7](https://github.com/io7lab/node-red-contrib-io7) | The io7 in / io7 out nodes |

Lab flows and device code for each step are under
[github.com/io7lab-lab](https://github.com/io7lab-lab).

### Troubleshooting

| Symptom | Look at |
|---|---|
| Management Web loads, login does nothing | Port 2009 blocked |
| Device is running but shows offline | Port 9001 blocked |
| io7 node shows `disconnected` | App ID / token wrong, or Host is not `mqtt` |
| Device refuses to connect | Device ID or token differs from the registry; port 1883 closed |
| Dashboard switch flickers | Pass-through is still enabled on the widget |
| Two apps keep dropping | They share one App ID — issue a second one |
| A subscribe returns nothing, no error | Typo in the topic. Brokers accept any subscription, valid or not |

### Diagrams

The two diagrams in this guide are editable. Open the `.excalidraw` files in
[excalidraw.com](https://excalidraw.com) and re-export the SVG next to them.

```text
diagrams/learning-path.excalidraw   diagrams/learning-path.svg
diagrams/edge-topology.excalidraw   diagrams/edge-topology.svg
```
