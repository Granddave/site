---
title: "Backup files quick with Bash's brace expansion"
date: 2023-04-08T17:35:12+02:00
tags: ["Bash", "CLI"]
---

Alright, here's a quick trick that I use at least a few times a week.

## Problem

Let's say we have a file that we want to make a copy of for whatever reason. In
this example we're creating a backup of the SSH server config before modifying
it:

```bash
$ cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
```

This is fine and dandy, but a bit verbose... We're writing the same string two
times and to be frank, it's not fun.

## Solution

Bash has a feature called **brace expansion**.

The snippet below is equivalent with the one up above:

```bash
$ cp /etc/ssh/sshd_config{,.bak}
```

and if we want to overwrite the active file (`sshd_config`) with the backed up
one, we can do the reverse operation *(note the placement of the comma)*:

```bash
$ cp /etc/ssh/sshd_config{.bak,}
```

which would expand to, yes you guessed it:

```bash
$ cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
```

---

## Other use cases

While where at it, here are some other useful expansions.

1. Create header and source files for the `app`, `widget` and `parser` classes
    ```bash
    $ touch src/{app,widget,parser}.{h,cpp}
    ```
2. Download `img-1.jpg` through `img-10.jpg`
    ```bash
    $ wget https://acme.com/images/img-{1..10}.jpg
    ```
3. Move all nine files to another directory
    ```bash
    $ mv file-{a..c}{1..3}.txt some-dir/
    ```

## References

See [bash(1) EXPANSION](https://www.man7.org/linux/man-pages/man1/bash.1.html#EXPANSION).
