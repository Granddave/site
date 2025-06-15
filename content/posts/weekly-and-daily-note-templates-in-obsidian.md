---
title: "Weekly and daily note templates in Obsidian"
date: 2025-06-15T22:37:52+02:00
tags: ["Note-taking", "Obsidian", "JavaScript"]
showToc: true
TocOpen: false
---

I use [Obsidian](https://obsidian.md/) extensively for both personal use and
work.

Today I'm sharing a trick using the
[Templater](https://github.com/SilentVoid13/Templater) plugin that makes it
possible to create daily and weekly notes that based on their file names can
auto-generate links in-between them. Super handy!

Install Templater and in the template directory of your vault, we will create
two files, "Daily Template" and "Weekly Template".

## Weekly note template

Here is an example of how a generated week note could look like

![Week note for 2025 week 26](/img/obs-template-week.png)

This template includes a
[command](https://silentvoid13.github.io/Templater/syntax.html#command-syntax)
that includes JavaScript to build up the file that we want based on the name of
the file. It generates links to the previous and next week as properties, and
links to all work days of the week as bullet points.

`Templates/Weekly Template.md`
```js
---
tags:
  - weekly
<%*
// Parse current note date from filename (assumes "YYYY-[W]WW")
let fileTitle = tp.file.title;
let parts = fileTitle.split('-W');
if (parts.length < 2) {
  tR += "Invalid format";
} else {
  let year = parseInt(parts[0]);
  let week = parseInt(parts[1]);
  let startOfWeek = moment().year(year).isoWeek(week).startOf("isoWeek");

  // Next and prev week
  tR += "prev: \"[[" + moment(startOfWeek).subtract(7, "days").format("YYYY-[W]WW") + "]]\"\n";
  tR += "next: \"[[" + moment(startOfWeek).add(7, "days").format("YYYY-[W]WW") + "]]\"\n";

  // Close properties
  tR += "---\n"

  // Generate a link for each day from Monday to Friday
  for (let i = 0; i < 5; i++) {
    let day = moment(startOfWeek).add(i, "days").format("YYYY-MM-DD");
    tR += `- [[${day}]]\n`;
  }
}
%>

## Todo

## Projects

## Notes

```


## Daily note template

The daily note template is very similar. We link to previous and next day as
well as the note of the week. This allows us to go back and forth both in time,
but also in scope if that makes sense. Very powerful. One of the goals here is
limit context switching which we achieve by the direct links.

![Day note for 2025-06-23](/img/obs-template-day.png)

`Templates/Daily Template.md`
```js
---
tags:
  - daily
<%*
// Parse current note date from filename (assumes "YYYY-MM-DD")
let d = moment(tp.file.title, "YYYY-MM-DD");
if (!d.isValid()){
    tR += "Invalid date format";
} else {
    tR += "week: \"[[" + d.format("YYYY-[W]WW") + "]]\"\n";

    let prev, next;
    if (d.isoWeekday() === 1) {
        prev = moment(d).subtract(3, "days"); // Skip weekend
    } else {
        prev = moment(d).subtract(1, "days");
    }
    if (d.isoWeekday() === 5) {
        next = moment(d).add(3, "days"); // Skip weekend
    } else {
        next = moment(d).add(1, "days");
    }
    tR += "prev: \"[[" + prev.format("YYYY-MM-DD") + "]]\"\n";
    tR += "next: \"[[" + next.format("YYYY-MM-DD") + "]]\"\n";
}
%>
---
## Meetings
- 

## Todo
- [ ] 

## Notes
```

## Insert templates automatically via filename

By using the calendar plugin as shown in the images above, clicking a week or
date will open that note, or create it if it doesn't already exist. It will be
named following the specific format. Templater has a feature where it can insert
a template based on the name of the file. This makes it very easy to create a
new note and get to work.

![Templater settings](/img/obs-template-auto.png)

- `\d{4}-\d{2}-\d{2}`
- `\d{4}-W\d{1,2}`

---

Any other ideas on where to use similar templates?
