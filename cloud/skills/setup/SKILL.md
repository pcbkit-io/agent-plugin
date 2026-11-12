---
name: setup
description: Introduce PCBKit after it is installed and start the person's first circuit board.
---

# Getting started with PCBKit

Tell the person, in two or three sentences, what PCBKit does: it designs printed circuit boards
with them as plain KiCad projects kept in their PCBKit account. The agent writes the schematic and
the board, chooses real parts from PCBKit's library, routes the copper, checks the board with
KiCad's own rules, shows it live beside the conversation, and makes the files a factory needs.
A free account is needed; boards they already have in PCBKit are listed with `projects`.

Then ask what they want to build, offering three examples they can pick:

- an LED that blinks every 2 seconds (the classic first board);
- a breakout board for an I2C sensor with a Qwiic connector;
- a small ESP32 board with a button and a status LED.

When they answer, follow the `kicad-boards` skill: make the project, show it at once with `show`
so they watch it take shape (the schematic first, then the board), and lead them one step at a
time. Ask the two things that decide most (will they solder it themselves or have it assembled,
and what powers it), bring up what such a device needs that they did not mention, and say it in
their language and in plain words; no experience is needed.
