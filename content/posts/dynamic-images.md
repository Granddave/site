---
title: "Dynamic images in Hugo"
date: 2025-11-25T13:18:31+00:00
tags:
  - Hugo
  - HTML
  - CSS
  - Excalidraw
showToc: true
TocOpen: false
---

{{<
    dynamic-image
    light="/img/dynamic-image-hugo-light.svg"
    dark="/img/dynamic-image-hugo-dark.svg"
    alt="Excalidraw'd Hugo logo"
>}}

As you may have noticed, this website can be displayed in either light or dark
mode (toggle with sun/moon top left of page or with `Alt+T`).

An issue is that images and diagrams are perfectly visible in light mode, but
when flipping over to dark mode they either are surrounded by a big white box
or lost all contrast if the background is transparent, or vice versa.

I needed dynamic images; selective images depending on what mode is enabled.

## The `dynamic-image` shortcode

In [Hugo](https://gohugo.io/)—the tool used to create this website—you can
extend the markdown by invoking templates called shortcodes. This is a short
code I managed to hack together with help some LLM[^1].

[^1]: I found similar another blog solving the same problem in another way as well.
https://stenbrinke.nl/blog/adding-support-for-dark-and-light-images-to-hugo-figure-shortcode/

[`layouts/shortcodes/dynamic-image.html`](https://github.com/Granddave/site/blob/108d17157135248445dc8917afd8ddb503ee8317/layouts/shortcodes/dynamic-image.html):

```html
{{ $lightSrc := .Get "light"}}
{{ $darkSrc := .Get "dark"}}
{{ $alt := .Get "alt" }}
{{ $class := .Get "class" }}
{{ $style := .Get "style" }}

<div class="dynamic-image {{ $class }}" style="{{ $style }}">
  <center>
    <img src="{{ $lightSrc }}" alt="{{ $alt }}" class="light-mode-img">
    <img src="{{ $darkSrc }}" alt="{{ $alt }}" class="dark-mode-img">
  </center>
</div>
```

And the accompanying CSS...

[`assets/css/extended/dynamic-image.css`](https://github.com/Granddave/site/blob/108d17157135248445dc8917afd8ddb503ee8317/assets/css/extended/dynamic-image.css):
```css
.dynamic-image img {
  display: none;
}
body:not(.dark) .dynamic-image .light-mode-img {
  display: block;
}
body.dark .dynamic-image .dark-mode-img {
  display: block;
}
```

Effectively what we've done here is to make sure to only display the "dark"
variant when dark-mode is enabled (`body.dark`) and the "light" variant when light-mode is
enabled (`body:not(.dark)`).

Below is an example usage taken from my last post about [reverse
proxies](posts/reverse-proxy/):

```html
{{</*
    dynamic-image
    light="/img/reverse-proxy-without-light.svg"
    dark="/img/reverse-proxy-without-dark.svg"
    alt="Without a reverse proxy"
*/>}}
```
{{<
    dynamic-image
    light="/img/reverse-proxy-without-light.svg"
    dark="/img/reverse-proxy-without-dark.svg"
    alt="Without a reverse proxy"
>}}

Now if you toggle the light/dark mode you should see that the text, arrows and
colors are visible in both modes.

Below is an animation toggling the images back regardless of what the current
mode is and forth to illustrate the effect.

{{<
    imagetoggle
    img1="/img/reverse-proxy-without-light.svg"
    img2="/img/reverse-proxy-without-dark.svg"
>}}

A downside to this approach is that different "web readers" strip CSS making the
images disappear or sometimes even show both variants. Maybe there is some way
to detect in the shortcode..?

---

## Diagram generation

I might as well mention how these diagrams are made.
I use a web application called [Excalidraw](https://excalidraw.com/), which is
a drawing application that stores all data locally and is great for quick
diagrams and illustrations. The projects can be downloaded to `.excalidraw` files
and the full canvas or selected elements can be exported as images (PNG and SVG).

The trick here is to export the same image twice, once in dark mode and once in
light mode.

During export, make sure *Background* is unchecked, and then export the image
as SVG. Export the image once again but now toggle the *Dark mode* option.

{{< figure src="/img/dynamic-images-export.png" >}}

---

{{< hackernews "https://news.ycombinator.com/item?id=46048430" >}}
