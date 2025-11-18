---
layout: post
title: "Fix Google Analytics on my Github pages"
date: 2025-11-18 00:00:00 +0000
author: Ben42Code
excerpt: How did I unblock Google Analytics for my Github pages with `jekyll/minima` theme.
---
Adding Google Analytics to a [Jekyll](https://jekyllrb.com/) site with [`jekyll/minima`](https://github.com/jekyll/minima) theme is supposed to be straight forward. Just a single line in your [_config.yml](https://jekyllrb.com/docs/configuration/) file.

Here is the [official documentation for `jekyll/minima` v2.5.1](https://github.com/jekyll/minima/blob/v2.5.1/README.md#enabling-google-analytics):

> To enable Google Analytics, add the following lines to your Jekyll site with your [Google Analytics](https://developers.google.com/analytics?hl=en) ["Measurement Id"](https://support.google.com/analytics/answer/12270356?hl=en) (I'll skip the setup part to get a ["Measurement Id"](https://support.google.com/analytics/answer/12270356?hl=en)).
>
> ```yaml
> google_analytics: UA-NNNNNNNN-N
> ```
>
> Google Analytics will only appear in production, i.e., `JEKYLL_ENV=production`

Did it with this [pull request](https://github.com/ben42code/ben42code.github.io/pull/11)...except that it didn't work😓. Google Analytics was telling me that:
- "*No data received from your website*"
- or "*Data collection isn't active for your website. If you installed tags more than 48 hours ago, make sure they are setup correctly.*"

Then, I started to look for what I was missing.

First of all, I was relying on [Github pages out of the box supported theme](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/adding-a-theme-to-your-github-pages-site-using-jekyll#supported-themes). I chose the [`jekyll/minima`](https://github.com/jekyll/minima) theme.
As of today, the exact version of `jekyll/minima` used by `Github pages` is [`v2.5.1`](https://github.com/jekyll/minima/tree/v2.5.1). This information regarding Github pages dependencies versions is available on <https://pages.github.com/versions.json>:
```json
{
    "jekyll": "3.10.0",
	...
    "minima": "2.5.1",
	...
    "ruby": "3.3.4",
    "github-pages": "232",
	...
}
```
`jekyll/minima` theme manages Google Analytics with [`_includes/google-analytics.html`](https://github.com/jekyll/minima/blob/v2.5.1/_includes/google-analytics.html).
And let's just say that [`_includes/google-analytics.html`](https://github.com/jekyll/minima/blob/v2.5.1/_includes/google-analytics.html) content doesn't look like the code snippet recommended by Google Analytics at all.

Code snippet recommended by Google Analytics:
```html
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-XXXXXXXXXX');
</script>
```

Code from [`_includes/google-analytics.html`](https://github.com/jekyll/minima/blob/v2.5.1/_includes/google-analytics.html):
```html
<script>
if(!(window.doNotTrack === "1" || navigator.doNotTrack === "1" || navigator.doNotTrack === "yes" || navigator.msDoNotTrack === "1")) {
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

    ga('create', '{% raw %}{{ site.google_analytics }}{% endraw %}', 'auto');
    ga('send', 'pageview');
}
</script>
```
Long story short, [`jekyll/minima@v2.5.1`](https://github.com/jekyll/minima/tree/v2.5.1) support for Google analytics is outdated/broken. And lucky me, this has already been fixed by [Tiamo Idzenga](https://github.com/iTiamo) a year ago!🎉❤️. More details here:
- [Github issue #816](https://github.com/jekyll/minima/issues/816)
- [Pull request `v2.5-stable`](https://github.com/jekyll/minima/pull/824)
- [Pull request `master`](https://github.com/jekyll/minima/pull/825)

And the fix has been ported in the `v2.5-stable` branch of `jekyll/minima` (I didn't want to switch to `v3.x` yet).
- Commit: [`v2.5-stable@593a05a`](https://github.com/jekyll/minima/commit/593a05a2a6426b2f2438e334abf8c8edc80d4624)

So now the question is how can I target this fixed version of `jekyll/minima`?
Quite straight forward, it's already documented by Github pages: <https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/adding-a-theme-to-your-github-pages-site-using-jekyll>. I just need to switch my theme selection to a remote theme with [`jekyll-remote-theme`](https://github.com/benbalter/jekyll-remote-theme) Jekyll plugin.

To fix my issue, I will therefore switch my theme from the out of the box `jekyll/minima` theme to a remote theme targetting explicitly `jekyll/minima@593a05a`.

- [pull request](https://github.com/ben42code/ben42code.github.io/pull/12).
- Changes introduced on [`_config.yml`](https://github.com/ben42code/ben42code.github.io/commit/bad9f84dd7a72adc86a8b1b9e64347ebeb7ffb51?diff=unified):
> ```diff
> -theme: minima
> +# Targeting minima theme version in '2.5-stable' branch including the google-analytics.html fix/update.
> +remote_theme: jekyll/minima@593a05a2a6426b2f2438e334abf8c8edc80d4624
> ```
> ```diff
> +plugins:
> +  - jekyll-remote-theme
> ```

*Et voilà*! Data is finally flowing to my Google Analytics, and my Data Stream is now telling me that `✅Data collection is active in the past 48 hours.`🥳