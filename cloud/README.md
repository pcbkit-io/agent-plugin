# PCBKit

Design printed circuit boards with your agent. You say what the board should do; the agent writes
the schematic and the board as a plain KiCad project kept in your [PCBKit](https://pcbkit.io)
account, chooses real parts, routes the copper, checks the result with KiCad's own rules, and makes
the files a factory needs. You watch the board take shape live, in 2D and 3D, beside the
conversation, and can open it at pcbkit.io at any time.

Try:

> Design a board with an LED that blinks every 2 seconds, powered from USB-C, and show it to me.

## What is in the plugin

- The skill `kicad-boards`: how to read and change KiCad files as text, and how to take a board
  from an idea to routed and checked. The skill `setup` introduces PCBKit and starts a first board.
- PCBKit's server at `https://pcbkit.io/mcp`, with these tools:

| Tool                              | What it does                                                                       |
| --------------------------------- | ---------------------------------------------------------------------------------- |
| `projects`, `new_project`         | Lists your boards; makes a new one                                                 |
| `show`                            | Shows the board live in the conversation and gives its link                        |
| `bash`, `edit`                    | Work on the project's files in its sandbox on PCBKit's servers                     |
| `find_parts`, `part`, `save_part` | Search PCBKit's library of about 7 million parts with KiCad symbols and footprints |
| `route`                           | Routes the board with PCBKit's autorouter, by the board's own rules                |
| `check`                           | Checks the project, with KiCad's design and electrical rule checks                 |
| `nets`, `look`                    | Read back what the board connects and give the agent a picture, to verify its work |
| `analyze`                         | Voltage drop, impedance, crosstalk, heat and supply impedance of the routed board  |
| `export`, `order`                 | The files for the factory as one zip; the board handed to a factory's order page   |
| `device`, `enclosure`             | Runs the board's program on a model of the board; makes a printable case for it    |

## What you need

A free PCBKit account: the first time, Claude asks you to sign in to PCBKit (with Google, GitHub or
a code sent to your e-mail address). PCBKit is free. Nothing is installed and nothing runs on your
computer: the plugin has no hooks, scripts or local programs.

## Your data

Your boards are kept in your PCBKit account, private until you share them. The server receives the
tool calls the agent makes (which board, the files it writes, the commands it runs in the board's
sandbox, part searches), not your conversation.
[Privacy policy](https://pcbkit.io/privacy) · [Terms](https://pcbkit.io/terms) ·
support@pcbkit.io

To work on a KiCad project in a folder on your own computer instead (Claude Code, Codex), install
the plugin from [pcbkit-io/agent-plugin](https://github.com/pcbkit-io/agent-plugin).
