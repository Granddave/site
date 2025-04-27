---
title: "Debug stripped executables with detached symbols in GDB"
date: 2025-04-27T14:11:02+02:00
tags: ["C", "GCC", "GDB", "Debugging", "ELF"]
ShowCodeCopyButtons: true
showToc: true
TocOpen: false
---

Say you have an executable that will be shipped to target machines and you don't want to include any debug symbols, but at the same time if an annoying bug occurs you'd like to debug the executable with symbols. Is it possible to have both ways? As a matter of fact, yes!

[GNU Debugger (GDB)](https://www.sourceware.org/gdb/) has a feature where it can load a separate symbols file to make it easier to debug stripped executables. This would allow you to ship stripped binaries, archive symbols files and when needed load them both into a debug session.

This post got a bit longer than I first expected it was going to be. It was an interesting journey, but I didn't include all the rabbit holes. I left some parts for the reader to dig into [at the end](#further-reading).

## TL;DR

```bash
# Build executable
$ cat > app.c << EOF
#include <stdio.h>
int main() {
    printf("Hello, World!\n");
    return 0;
}
EOF
$ gcc -g -O0 -o app app.c
```
```bash
# Separate debug symbols from the executable
$ objcopy --only-keep-debug app app.debug
$ strip --strip-debug app
$ ls
app  app.c  app.debug
```
```bash
# Debug with GDB
$ gdb --exec=app --symbols=app.debug
```

## Deeper explanation

### Compiling, copying and stripping

Let's use the same code as in the example as above.

```c
#include <stdio.h>
int main() {
    printf("Hello, World!\n");
    return 0;
}
```


First we compile `app.c` without any optimizations (`-O0`) into an executable called `app` which includes debug symbols (`-g`).

```bash
# Compile app
$ gcc -g -O0 -o app app.c
```

Compiling without optimizations is not really necessary in this case, but it makes it easier to follow the code when stepping through instructions.

On Linux the executable is of the [ELF](https://en.wikipedia.org/wiki/Executable_and_Linkable_Format) file format. This file format contains different *sections*, such as `.text` containing executable code, `.data` containing initialized writable data and `.bss` containing uninitialized (zeroed) data, among others. A family of sections we're interested in today are the [debug info sections](https://en.wikipedia.org/wiki/.debug_info). They hold symbols like function names, variable names, filenames and line numbers etc. To list what sections an ELF file contain you can run `readelf --sections $elf_file`.

To separate the debug symbols from the executable we can utilize `objcopy`'s `--only-keep-debug` flag. This copies debug sections from `app` to `app.debug`, which itself also is an ELF file, just like `app`. The naming of this file doesn't seem to be standardized, but the GDB documentation uses the `.debug` suffix, so let's use that. This file can be referred to as either the "*debug file*", "*debug info*" or just "*symbols file*"

```bash
# Copy debug symbols to app.debug
$ objcopy --only-keep-debug app app.debug
```

Next we remove, or *strip* sections from `app` that we neither need, nor want in a deployable target executable. This process makes the executable binary smaller, often a fraction of the size of an executable containing debug symbols, especially for larger programs. We can either strip all sections using `strip $executable`. This removes all sections that are not required for the executable to run. Or specifically just strip the debug symbols, which can be achieved by appending `--strip-debug` flag. Let's strip all unnecesary sections.

```bash
# Strip unnecesary sections from app
$ strip app
```

We now have all the files ready!

```bash
$ ls
app  app.c  app.debug
```

### Debugging with detached symbols

The next step is to use GDB to load the stripped executable and provide the symbols file for easier debugging.

Let's first try to debug our test executable *without* providing any symbols file.

```bash
$ gdb app
...
Reading symbols from app...
(No debugging symbols found in app)
(gdb) info functions  # List available functions
All defined functions:

Non-debugging symbols:
0x0000000000401030  puts@plt
```

Here we started passed our `app` executable to GDB and saw as it initialized that it couldn't find any symbols;

> ```bash
> (No debugging symbols found in app)
> ```

We can also see from `info functions` that no main function was found. Nothing about this is surprising since this is the executable we stripped in a previous step.

Let's now provide the `.debug` file to GDB. I've found three (plus a bonus) separate ways of getting GDB to load symbols from it.

1. `--symbols` flag
2. `symbol-file` command
3. Debug link (Bonus: *build ID* [^1])

[^1]: This is similar to the debug link method. The [documentation](https://sourceware.org/gdb/current/onlinedocs/gdb.html/Separate-Debug-Files.html) mentioned that this was only supported on some OS's, so I didn't dig too deep into it. But it might be a topic for another time.


I'm gonna try to explain how they work here below...

#### 1. Symbols flag

The first two options listed above are explicit instructions to GDB to load the symbols file.

First option uses the `--symbols` flag. This is also the option used in the TL;DR.

Here we specify that `app` is our executable file to be debugged using the `--exec` flag:

```bash
$ gdb --exec=app --symbols=app.debug  # Load both executable and symbols file
...
Reading symbols from app.debug...
(gdb) info functions  # List available functions
All defined functions:

File app.c:
2:      int main();
```

The symbols were loaded!

> ```bash
> Reading symbols from app.debug...
> ...
> File app.c:
> 2:      int main();
> ```

#### 2. Symbol file command

Second option is to use the `symbol-file` command.

Load `app` with GDB and pass `app.debug` to execute the `symbol-file` command:
```bash
# Load executable
$ gdb app
...
Reading symbols from app...
(No debugging symbols found in app)
(gdb) symbol-file app.debug  # Load symbol file
Reading symbols from app.debug...
(gdb) info functions  # List available functions
All defined functions:

File app.c:
2:      int main();
```

Again, symbols were loaded successfully.


#### 3. Debug link: Linking symbols file to executable

The third option is to modify the executable itself by adding a special `.gnu_debuglink` section to the binary. This section holds just the basename of the symbols file, in our case it would be `app.debug` (note, not a full path) as well as a [CRC checksum](https://en.wikipedia.org/wiki/Cyclic_redundancy_check) of the symbols file's full content. This means that this specific symbols file is linked to in this specific executable.

```bash
# Link to app.debug in app
$ objcopy --add-gnu-debuglink=app.debug app
```

When running GDB on an executable that has a `.gnu_debuglink` section, GDB will look for the symbol file in a few different places. First, in the same directory as the executable, secondly in a subdirectory called `.debug` and finally through directories set via the `debug-file-directory`. The `debug-file-directory` property is a colon separated string of paths defaulted at GDB's compile-time and can be overridden in runtime.

Say our executable is located in `/home/david/Dev/detached-symbols`, then GDB will search for the filename specified in `.gnu_debuglink` in

- `/home/david/Dev/detached-symbols`
- `/home/david/Dev/detached-symbols/.debug`
- `/usr/lib/debug` (or whatever `debug-file-directory` is set to [^2])

[^2]: You can see what default value your GDB executable was built with by running `gdb --configuration | grep -e '--with-separate-debug-dir'`

Let's try it out:

```bash
$ objcopy --add-gnu-debuglink=app.debug app
$ gdb app
...
Reading symbols from app...
Reading symbols from /home/david/Dev/detached-symbols/app.debug...
```

Notice that I didn't specify any debug file. GDB used the `.gnu_debuglink` section find the symbol file in the same directory as the executable automatically. Neat!

## Closing words

Now we know a few ways of how we can separate the debug information from our executable and when needed debug with the comfort of symbols.

Below are some further reading and resources that might be of use.

### Further reading

- Marking and finding executable and debug info using the [build ID method](https://sourceware.org/gdb/current/onlinedocs/gdb.html/Separate-Debug-Files.html)
- Using [debuginfod](https://sourceware.org/gdb/current/onlinedocs/gdb.html/Debuginfod.html#Debuginfod) to fetch debug info from remotes on-demand using build IDs

### Resources

- [Stack Overflow: extract debug symbol info from ELF binary](https://stackoverflow.com/questions/45659150/extract-debug-symbol-info-from-elf-binary)
- [GDB documentation for separate debug files](https://sourceware.org/gdb/current/onlinedocs/gdb.html/Separate-Debug-Files.html)
- [GDB documentation for `symbol-file` command](https://sourceware.org/gdb/current/onlinedocs/gdb.html/Files.html)
