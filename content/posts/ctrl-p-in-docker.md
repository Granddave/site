---
title: "Ctrl+P in Docker container"
date: 2024-07-21T20:43:02+02:00
tags: ["Docker", "CLI", "Bash"]
ShowCodeCopyButtons: true
---

I strive to be efficient on the command line, and some of my favourite keyboard
shortcuts in Bash are the ones that allows me to navigate and execute previous
commands easily. Some of which are back and forward through the command history
with `Ctrl+P` and `Ctrl+N` combined with `Ctrl+J` for executing the command.

## The problem

This is all well and good until you jump in to a Docker container and suddenly
`Ctrl+P` isn't working as expected anymore.

Let's start a container and see what's happening:

```bash
~ docker run --rm -it ubuntu:noble
root@63be03f1200d:/# echo 1st
1st
root@63be03f1200d:/# echo 2nd
2nd
root@63be03f1200d:/# echo 3rd
3rd
root@5af42e908375:/#
# Here I just pressed Ctrl+P, but we're still an empty line after the last
# command was executed
root@5af42e908375:/# echo 2nd
# Now I pressed again, but instead of getting `echo 3rd`,
# we jumped up to `echo 2nd`
```

## Solution

After some frustration I started digging into why just `Ctrl+P` is acting
weird, and it turns out that `Ctrl+P` is part of the [key-sequence used for
detaching](https://docs.docker.com/engine/reference/commandline/cli/#default-key-sequence-to-detach-from-containers)
the terminal from an interactive container session. The default sequence is `Ctrl+P Ctrl+Q`, but it can easily be changed via the `--detach-keys` flag per Docker command, or via the Docker configuration file.

Let's fix it globally by modifying `~/.docker/config.json`

```json
{
    "detachKeys": "ctrl-q,ctrl-q"
}
```
