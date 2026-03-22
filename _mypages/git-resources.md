---
layout: page
title: Git resources
---

`git log` the way I like it.
```shell
git log --date=format:'%Y-%m-%d %H:%M:%S' --pretty=format:"%h - %cd - %cn %s"
```

Fetch/update/checkout `main` with remote-tracking/local branch.
```shell
git fetch origin main:main; git checkout main
```
