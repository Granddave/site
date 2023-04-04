---
title: "Closing a Stale SSH Connection"
date: 2023-04-04T19:03:48+02:00
tags: ["SSH", "CLI"]
ShowCodeCopyButtons: true
---

Suppose you're connected to a remote host with SSH and after a while the SSH
session goes stale. The terminal is unresponsive and no keypress seem to take
effect. There might be something with the network, the remote host is
restarting or maybe your machine has been in hibernation, there could be
multiple reasons for a stale session.

The first solution that might come to mind is to just close the terminal
emulator and create another one, but **there is a better way**.

## SSH Escape Sequences

Before I show the trick we take a quick detour and explore a kind of hidden
feature that is implemented in many of the available SSH clients.

Built in to the SSH client are multiple hidden commands that can be triggered
with a so called *escape sequence*. These commands can be access by a
combination of the tilde prefix (`~`) followed by the command.

For example `~?` print the help message containing all of the supported escape
sequences:

```bash
david@remote-host:~$ ~?
Supported escape sequences:
 ~.   - terminate session
 ~B   - send a BREAK to the remote system
 ~R   - request rekey
 ~#   - list forwarded connections
 ~?   - this message
 ~~   - send the escape character by typing it twice
(Note that escapes are only recognized immediately after newline.)
```

Pay extra attention to the last line;

> *(Note that escapes are only recognized immediately after **newline**.)*

This means that for the escape sequence to take effect a preceding newline is
required.

Also, a small note for people using a keyboard with a **nordic layout**; To
type the tilde character, press `AltGr+^ <Space>`. I know that this tripped me
up when I first learned about escape sequences.

### The "Terminate Session" Escape Sequence

So, back to the initial problem.

As the help message stated above we can close the session with `~.`. And
remember, press enter a couple of times before initiating the sequence:

```bash
david@remote-host:~$ ~.
david@remote-host:~$ Shared connection to remote-host.davidisaksson.dev closed.
david@local:~$ echo $?
255
```

From here we can try to initiate the connection again, or just reuse the terminal.
