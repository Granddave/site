---
title: "Format JSON in Vim with jq"
date: 2023-04-13T21:15:07+02:00
tags: ["Neovim", "Vim", "jq"]
---

[jq](https://stedolan.github.io/jq/) is a very powerful command-line tool
designed to manipulate JSON data. One of its great features is that it
automatically formats JSON output for better readability:

{{< highlight bash >}}
$ echo '{"is_jq_awesome": true}' | jq
{
  "is_jq_awesome": true
}
{{< /highlight >}}

## But in Vim?

Can we utilize this inside of Vim? Of course!

In Vim, there's a feature called *filter commands* that enables us to use
external applications to modify our buffers. Filter commands take a *range*,
which is a set of contiguous lines, and a *command* that processes these lines.
This feature is exactly what we need for our purpose.

### Whole buffer

```console
:%!jq
```

Here we pass the whole buffer range (`%`) to `jq`:

{{< asciinema 577418 >}}

### Selected range

It even works with visual selection!

```console
:'<,'>!jq
```

Here we pass instead pass the range of the visual selection (`'<,'>`) to `jq`:

{{< asciinema 577416 >}}

### Minified JSON

You can also pass `--compact-output` to get a minified JSON structure back:

```console
:%!jq --compact-output
```

{{< asciinema 577417 >}}

## Mappings

Let's add some mappings. I use the abbreviations `fj` for *"format JSON"* and
`fcj` for *"format compact JSON"*, but feel free to choose any abbreviations
that works best for you.

### Vim

```vim
" Whole buffer
nnoremap <silent> <Leader>fj <Cmd>%!jq<CR>
nnoremap <silent> <Leader>fcj <Cmd>%!jq --compact-output<CR>

" Visual selection
vnoremap <silent> <Leader>fj :'<,'>!jq<CR>
vnoremap <silent> <Leader>fcj :'<,'>!jq --compact-output<CR>
```

### Neovim using Lua

```lua
local opts = { noremap = true, silent = true }

-- Whole buffer
vim.keymap.set("n", "<Leader>fj", "<Cmd>%!jq<CR>", opts)
vim.keymap.set("n", "<Leader>fcj", "<Cmd>%!jq --compact-output<CR>", opts)

-- Visual selection
vim.keymap.set("v", "<Leader>fj", ":'<,'>!jq<CR>", opts)
vim.keymap.set("v", "<Leader>fcj", ":'<,'>!jq --compact-output<CR>", opts)
```

## Resources

- Vim help docs: `:h range`, `:h filter`
- [jq](https://stedolan.github.io/jq/)

---

{{< hackernews "https://news.ycombinator.com/item?id=35560775" >}}
