PreBot for Eggdrop
---

These scripts allow you to scrape pre releases from IRC channels and save them to an MySQL database. They are written in TCL for use with eggdrop.

There is a concept of the main bot and leaf bots (optional). The main bot offers all the lookup scripts while the leaf bots can join additional IRC networks and add new pres to the database directly or proxy lookup requests through the main bot.

The leaf bots can actually be updated via the partyline. Additionally, other main bots on the partyline can be used to sync pres, even automatically, during downtime.

The pre saving scripts will attempt to sanitize the input and limit specific genres to a list of approved items.