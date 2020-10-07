# Mokay

Perfectly brew coffee in Moka pots using Elixir and Nerves.

## How to use

The app needs these following env variables. I recommend using
[direnv](https://direnv.net/).

```
MIX_TARGET
NERVES_NETWORK_SSID
NERVES_NETWORK_PSK
TWILIO_SID
TWILIO_AUTH_TOKEN
TWILIO_FROM
TWILIO_TO
```

Once those are all set, you can build the app running:

```
mix deps.get && mix compile
```

To build the firmware image, run:

```
mix firmware
```

And to burn it to an SD, run:

```
mix firmware.burn
```
