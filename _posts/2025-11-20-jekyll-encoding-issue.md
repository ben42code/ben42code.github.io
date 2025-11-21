---
layout: post
title: "Jekyll - Invalid US-ASCII character '\\xE2'"
date: 2025-11-20 00:00:00 +0000
author: Ben42Code
excerpt: UTF8 encoding issues when switching to `minima@main` branch.
---

# Context

I've been using the [`2.5-stable`](https://github.com/jekyll/minima/tree/2.5-stable) branch of the `jekyll/minima` theme without issues. However, I recently wanted to customize the `<head/>` section of my site. The [`master`](https://github.com/jekyll/minima/tree/master) branch provides [`_includes/custom-head.html`](https://github.com/jekyll/minima/blob/8d0aa75ec81ceac98c90fd4539ddab500d936d00/README.md#extending-the-head-) for this purpose, but this feature isn't available in the stable branch.

# Path to failure

I had two options:
1. Submit a pull request to backport the custom head feature to the [`2.5-stable`](https://github.com/jekyll/minima/tree/2.5-stable) branch
2. Upgrade from [`2.5-stable`](https://github.com/jekyll/minima/tree/2.5-stable) to [`master`](https://github.com/jekyll/minima/tree/master)

I chose the second approach and updated my `_config.yml` to use the master branch (since I was already using a [remote theme](https://github.com/benbalter/jekyll-remote-theme), it was cheap and easy):

```diff
-remote_theme: jekyll/minima@2.5-stable
+remote_theme: jekyll/minima@master
```

Unfortunately, this broke my local build😭:

```sh
      Generating... 
      Remote Theme: Using theme jekyll/minima
       Jekyll Feed: Generating feed for posts
  Conversion error: Jekyll::Converters::Scss encountered an error while converting 'assets/css/style.scss':
                    Invalid US-ASCII character "\xE2" on line 255
/usr/local/src/rbenv/versions/3.3.4/lib/ruby/gems/3.3.0/gems/jekyll-sass-converter-1.5.2/lib/jekyll/converters/scss.rb:123:in `rescue in convert': Invalid US-ASCII character "\xE2" on line 255 (Jekyll::Converters::Scss::SyntaxError)

        raise SyntaxError, "#{e} on line #{e.sass_line}"
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

# Investigation / RCA

ℹ️ This issue only affected my local Jekyll build running in an Ubuntu-based Docker container (following [*🎉 Develop GitHub Pages locally in a Ubuntu Docker Container (latest)*](https://www.youtube.com/watch?v=zijOXpZzdvs) by [Bill Raymond](https://www.youtube.com/@bill-raymond)🏆). GitHub Pages handled the `master` branch upgrade without any problems, which gave me hope for a solution.

After investigating what changed in the [`master`](https://github.com/jekyll/minima/tree/master) branch, I traced the build failure to a specific pull request:
- <https://github.com/jekyll/minima/pull/855>
- <https://github.com/jekyll/minima/commit/478d99d18540948394c3d359f83b27abbcc325c8>

The culprit was in [`_sass/minima/_layout.scss`](https://github.com/jekyll/minima/commit/478d99d18540948394c3d359f83b27abbcc325c8#diff-6d0b27793edc9766e7881d79beb11489d548fc41c12286de34531203949950e3), specifically these lines containing the `•` character:

```scss
  .force-inline {
    display: inline;
    &::before {
      content: "•";
      padding-inline: 5px;
    }
```

The [`•` character](https://en.wikipedia.org/wiki/Bullet_(typography)) is a bullet symbol with [Unicode value `U+2022`](https://www.compart.com/fr/unicode/U+2022). Its UTF-8 encoding is the byte sequence `0xE2 0x80 0xA2`. This directly correlates with the build error message: *"Invalid US-ASCII character "\xE2"*. Jekyll was attempting to parse the file as `US-ASCII` instead of UTF-8.

Research into this issue revealed that the problem stems from an incorrectly configured local environment, causing Jekyll/Ruby to default to `US-ASCII` encoding. Relevant resources:
- <https://www.janmeppe.com/blog/invalid-US-ASCII-character/>
- <https://github.com/mmistakes/minimal-mistakes/issues/1809>

While adding `@charset "UTF-8";` at the top of the SCSS file can force the correct encoding ([see this StackOverflow post](https://stackoverflow.com/questions/27600932/how-can-i-change-charset-in-sass-scss)), this approach doesn't scale well across multiple files.

# Resolution
The solution was to configure the Docker container's locale settings. Following guidance from [this AskUbuntu post](https://askubuntu.com/questions/76013/how-do-i-add-locale-to-ubuntu-server), I added the English language pack to my Dockerfile:

```docker
RUN apt-get -y install language-pack-en
```

This ensures Ruby/Jekyll correctly detects UTF-8 encoding. After rebuilding the container, the build succeeded🎉✅:

```shell
      Remote Theme: Using theme jekyll/minima
       Jekyll Feed: Generating feed for posts
                    done in 1.801 seconds.
 Auto-regeneration: enabled for '/workspaces/xxx'
LiveReload address: http://127.0.0.1:35729
    Server address: http://127.0.0.1:4000
  Server running... press ctrl-c to stop.
```
