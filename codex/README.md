# PCBKit for coding agents

Design, change and route KiCad boards with your coding agent. The agent edits your KiCad files as
code; [PCBKit](https://pcbkit.io) shows the board live in your browser while it works, routes it,
finds real parts, and checks every write.

## Install

**Claude Code**

```
claude plugin marketplace add pcbkit-io/agent-plugin
claude plugin install pcbkit@pcbkit
```

**Codex** (CLI, or Codex in the ChatGPT desktop app)

```
codex plugin marketplace add pcbkit-io/agent-plugin
```

then install PCBKit from `/plugins`.

Then open a folder (empty, or with a KiCad project) and ask:

> Design a USB-C powered ESP32 board with a temperature sensor, and show it to me.

## What the agent gets

| Tool                              | What it does                                                                                     |
| --------------------------------- | ------------------------------------------------------------------------------------------------ |
| `show`                            | Opens the board live in your browser, in 2D and 3D; it follows every change of the files         |
| `route`                           | Routes the board with PCBKit's autorouter, by the board's own rules                              |
| `find_parts`, `part`, `save_part` | Searches PCBKit's library of about 7 million parts with KiCad symbols and footprints             |
| `schematic`                       | Draws the schematic from the agent's description of the parts and nets, as a person draws one    |
| `check`                           | Checks the KiCad files, with KiCad's own design rule check where KiCad is installed              |
| `nets`, `look`                    | Reads back what the board connects and gives the agent a picture, to verify its own work         |
| `analyze`                         | Computes what the routed board means physically: voltage drop, impedance, heat, supply impedance |
| `export`                          | The files for the factory, one zip by KiCad's own exporter (KiCad 9 or later must be installed)  |
| `order`                           | Puts the board on PCBWay's, OSH Park's, AISLER's or NextPCB's order page; JLCPCB's quote page    |
| `view`                            | Tells the agent what you selected on the board, so "this" means what you point at                |

and a skill that teaches it to read and change KiCad files as text and to take a board from an idea
to routed and checked.

## Any agent, any repository

The plugin is the short way in for Claude Code and Codex. Behind it is PCBKit's CLI, and the CLI
alone gives the same tools to every other place an agent works on a folder.

**A repository that carries PCBKit.** Ask your agent to set the repository up for PCBKit, or run
`pcbkit init` in it, and commit what it writes: PCBKit's launcher (`.pcbkit/pcbkit.sh`), the MCP
server's entry (`.mcp.json`) and the hooks (`.claude/settings.json`). An agent that works in a
clone then has PCBKit with nothing installed: Claude Code in the cloud (let the session's
environment reach `pcbkit.io` and `github.com`), a teammate's computer, a scheduled run.

**Another agent** (Cursor, Gemini CLI, any MCP client): give it an MCP server whose command is
`sh .pcbkit/pcbkit.sh mcp` in such a repository, or `pcbkit mcp` with the CLI installed. The server
tells the agent where the skill is on the computer.

**The CLI by itself** is the launcher under the name `pcbkit`:

```
curl -fsSL https://raw.githubusercontent.com/pcbkit-io/agent-plugin/main/pcbkit.sh -o ~/.local/bin/pcbkit
chmod +x ~/.local/bin/pcbkit
```

`pcbkit open` shows a folder's board in the browser; `pcbkit route`, `check`, `analyze`, `export`
and the rest are the tools as commands (`pcbkit help`).

**No folder at all** (Claude in chat, Cowork, ChatGPT): add PCBKit from the app's own directory, or
its server `https://pcbkit.io/mcp` as a connector. The board is then a project kept in your PCBKit
account.

## Your files stay on your computer

The plugin runs PCBKit's CLI on your computer. It watches the project's folder and sends what
changes to the page in your browser through PCBKit's relay, sealed end to end with a key that is
only in the link (after `#`) and never reaches PCBKit's servers. Nothing is stored. The router runs
on your computer. The parts search asks pcbkit.io.

The first time, the page asks you to sign in to PCBKit.

## Requirements

macOS or Linux (x64 or arm64). The plugin fetches PCBKit's CLI once, from this repository's
[releases](https://github.com/pcbkit-io/agent-plugin/releases), into `~/.pcbkit/bin`, and checks
it against the checksum in `pcbkit.sh`.

## This repository

`claude/` is the plugin for Claude Code, `codex/` the same plugin for Codex: both work on a folder
on your computer. `cloud/` is the plugin as Claude's directory lists it (Claude in chat, Cowork and
Claude Code): the same skill with PCBKit's own server at `https://pcbkit.io/mcp`, where the board is
a project kept in your PCBKit account and nothing runs on your computer; it is texts only, and the
branch `directory` is its latest version. Both are named `pcbkit`: in Claude Code the plugin for a
folder, once installed, takes the listed one's place. `pcbkit.sh` is the launcher by itself. All
are generated from PCBKit's source; issues are welcome here.
