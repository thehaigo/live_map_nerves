# GpsLogger

This application is a GPS logger that communicates with a [live_map](https://github.com/thehaigo/live_map) application created based on [it](https://github.com/yannvery/gps_tracker).

## Setup

- config/target.exs  
  change "your ap ssid" and "your ap password"
- lib/gps_logger/application.ex  
  change "your live_map setting page's token" and "local_ip_address"

## Getting Started

To start your Nerves app:

- export MIX_TARGET=rpi0
- Install dependencies with `mix deps.get`
- Create firmware with `mix firmware`
- Burn to an SD card with `mix firmware.burn`

## Using Hardware

- Raspberry Pi Zero W
- GPS Module (https://akizukidenshi.com/catalog/g/gK-09991/)

## Can't receive GPS signal?

- lib/gps_logger/data_fetcher.ex  
  change "ttyAMA0" to "ttyS0"  
  maybe bluetooth module using UART0

```elixir
Circuits.UART.open(uart, "ttyAMA0", speed: 9600, active: true)
```
