---
layout: post
title: "JSONC: The Little Format That Could (Maybe?)"
date: 2025-11-05 21:45:00 +0530
categories: web-development
tags: [json, jsonc, data-formats, configuration, programming]
author: Gnanesh Balusa
permalink: /:categories/:year/:month/:day/:title.html
description: "Ever wondered why you can't add comments to your JSON files? JSONC fixes that. But is it enough? Let's dig into what JSONC actually does, why it exists, and whether you should care"
---
That's exactly the problem JSONC was born to solve.

JSON has become the go-to format for everything from [API responses](https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Objects/JSON){:target="_blank"} to game save files to configuration. It's everywhere. But a lot of developers feel like it's missing some pretty basic features. JSONC is one of several attempts to fix that.
## What Even Is JSONC?

Let's start with the basics. [JSON (JavaScript Object Notation)](https://www.json.org/){:target="_blank"} is a human-readable text format for storing structured data. It uses name-value pairs, arrays, and scalar values. The syntax comes from JavaScript, but these days pretty much every programming language can work with it. That's the whole point. It's supposed to be universal.But here's where things get annoying. JSON has some rules that feel... unnecessarily strict: No comments (you can't use `//` or `/* */` to explain anything), no trailing commas (that comma after the last item in a list will break your entire file), keys must be double-quoted always with no exceptions, and multiline strings don't work (if you want text that wraps across lines, you're out of luck).

So if you write something like this:

{% highlight json %}
{
// One of "dark", "light", or "auto"
theme: "light",

description: "This is a description
wrapped over multiple lines for ease
of reading",

// I like LOADS of spaces!
tab-width: 8,
}
{% endhighlight %}

JSON will reject it completely. Instead, you're stuck with this:

{% highlight json %}
{
"theme": "light",
"description": "This is a description wrapped over multiple lines for ease of reading",
"tab-width": 8
}
{% endhighlight %}

Not terrible, but definitely less readable. And good luck remembering what that tab-width setting was for six months from now.

## Enter JSONC

JSONC stands for "JSON with Comments." And yeah, that's pretty much what it does. It takes regular JSON and adds support for comments. That's the main thing.

Here's what you can do with JSONC:

{% highlight jsonc %}
{
// One of "dark", "light", or "auto"
"theme": "light",

/*
This is a block comment.
You can write as much as you want here.
Multiple lines? No problem.
*/
"tab-width": 8
}
{% endhighlight %}

JSONC supports two types of comments: inline comments with `//` that run until the end of the line, and block comments with `/* */` that can span multiple lines. What it doesn't support is the `#` style comments you'd use in bash scripts. Those won't work here.

## But Wait, There Are Alternatives
Before you get too excited about JSONC, you should know there are other options out there trying to improve JSON.

### YAML

[YAML](https://yaml.org/){:target="_blank"} is probably the most popular alternative. It makes significant changes to JSON's syntax. Instead of curly braces, it uses indentation. It has custom data types and handles multiline strings naturally. You'll see YAML used in [Docker Compose](https://docs.docker.com/compose/){:target="_blank"}, [GitHub Actions](https://docs.github.com/en/actions){:target="_blank"} workflows, and Ruby on Rails. YAML is powerful, but it's also a bigger departure from JSON. Sometimes that's exactly what you need. Other times, it's overkill.

### JSON5

[JSON5](https://json5.org/){:target="_blank"} aims to be valid JavaScript while fixing pretty much everything people complain about in JSON. It allows trailing commas, unquoted keys, multiline strings, and comments. It's used in Chromium, Next.js, and macOS programming. JSON5 is more ambitious than JSONC. It tries to fix everything. JSONC, on the other hand, stays focused on one thing: comments.

## Why Comments Actually Matter (A Lot)
Okay, so comments might not sound revolutionary. But think about it. When was the last time you opened a config file and immediately understood every setting? Here's where comments really shine:

### Configuration Files

This is the big one. Config files benefit massively from comments. You can add examples right in the file, explain why you chose certain settings, document what each option does, and leave notes for your future self (or your teammates). Instead of maintaining a separate README that people might not find, the documentation lives right there in the config file itself.

### Data Annotation

When you're storing data that different parts of your code interact with, comments let you explain what that data represents and how it all connects. It's like leaving breadcrumbs for anyone who comes after you.

### Temporary Debugging

You can comment out sections of a file for testing, though honestly this is less common with data files. It can get confusing fast if you're passing data between systems.

## The Other Side of the Argument
Now, Douglas Crockford, the guy who originally created JSON, has opinions about comments. He deliberately removed them from JSON. Here's what he said: "I removed comments from JSON because I saw people were using them to hold parsing directives, a practice which would have destroyed interoperability." Fair point. Comments can be misused. If people start stuffing parsing instructions into comments, it breaks the whole idea of JSON being a neutral data format. So there's a legitimate argument for leaving them out. But for config files that aren't being passed between systems? Comments are incredibly useful.

## The Downsides (Because Nothing's Perfect)

JSONC sounds pretty good so far, right? But it's not without problems.

### It's Not That Popular

This is the biggest issue. Most tools expect plain JSON, and they'll fail if you feed them a JSONC file. JSONC is technically a superset of JSON (so all valid JSON is also valid JSONC), but it doesn't work the other way around. If your tooling doesn't support JSONC, you're stuck. And most tooling doesn't.

### It Doesn't Fix Other Annoyances

JSONC only adds comments. It doesn't fix trailing commas. It doesn't allow unquoted keys. If we're going to create a new format anyway, why not fix everything? Trailing commas make code easier to maintain. You can add or remove items without worrying about comma placement. Git diffs look cleaner. But JSONC doesn't support them.

### Converting JSONC to JSON Is Awkward
There's a tool called [JSMin](https://www.crockford.com/jsmin.html){:target="_blank"} (by Douglas Crockford) that can strip comments from JSONC and convert it to plain JSON. But it's not as simple as you'd think. Because JSONC uses `//` and `/* */` for comments (the same syntax as code), a converter needs to be a full JSON parser. It has to understand context to avoid accidentally removing something important. If JSONC had chosen a simpler comment syntax, like `#` in the first column, conversion would be trivial. You could do it with a single line of bash:

{% highlight bash %}
<input.jsonc grep -v '^#' >output.json
{% endhighlight %}

But with the current syntax, you need specialized tools.

## How to Actually Use JSONC Today

So where will you encounter JSONC in the wild? Usually in configuration files. The [fastfetch](https://github.com/fastfetch-cli/fastfetch){:target="_blank"} program, for example, uses JSONC for its config. You can annotate your settings with notes, explanations, whatever you need.

If you're building something that needs to support JSONC, you've got two main approaches:

### Option 1: Convert It

Use a tool like JSMin to strip comments and convert JSONC to plain JSON. Then handle it like you would any other JSON file. This works, but it adds an extra step to your workflow.

### Option 2: Use a Library

Grab a library that natively supports JSONC. For C, check out [yyjson](https://github.com/ibireme/yyjson){:target="_blank"} which handles JSONC comments plus trailing commas and other nice features. For JavaScript, Microsoft's [node-jsonc-parser](https://github.com/microsoft/node-jsonc-parser){:target="_blank"} does the job and also supports trailing commas. Pick whichever fits better into your stack.

## So Should You Use JSONC?
Here's the truth: JSONC solves a specific problem really well. If you're working with config files and wish you could add documentation inline, JSONC is perfect for that. But it's not a universal JSON replacement. It doesn't fix all of JSON's quirks. And most importantly, it's not widely supported. You'll need to handle conversion or use specialized libraries if you want to integrate with standard JSON tooling.

If you're building something new and you control the entire stack, JSONC is worth considering. For config files especially, the ability to add comments is legitimately valuable. But if you're working in an ecosystem that expects standard JSON? Stick with JSON. It's been working great for years, and there's no shame in that.

## The Big Takeaway

JSONC isn't trying to replace JSON for everything. It's trying to make config files and annotated data more maintainable. For that specific use case, it succeeds. Would it be better if it also fixed trailing commas and unquoted keys? Probably. Would it be better if conversion to JSON was simpler? Definitely. But for what it is, JSON with comments, it does the job. And sometimes, that's exactly what you need.


For more insights on web development, programming, and tech, check out Gnanesh Balusa's blog.

Published on November 5, 2025 at 9:45 PM IST