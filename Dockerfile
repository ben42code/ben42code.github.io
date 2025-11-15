#################################################
# Dockerfile to build a GitHub Pages Jekyll site
#   - Ubuntu 22.04
#   - Ruby 3.3.4
#   - Jekyll 3.10.0
#   - GitHub Pages 232
#
# DISCLAIMER: Mostly inspired by: https://gist.github.com/BillRaymond/db761d6b53dc4a237b095819d33c7332
# From: https://github.com/BillRaymond
#
# Source of truth for github pages dependencies versions:
# https://pages.github.com/versions/
# https://pages.github.com/versions.json
#
# 2025-11-15
# {
#     "jekyll": "3.10.0",
#     "jekyll-sass-converter": "1.5.2",
#     "kramdown": "2.4.0",
#     "kramdown-parser-gfm": "1.1.0",
#     "jekyll-commonmark-ghpages": "0.5.1",
#     "liquid": "4.0.4",
#     "rouge": "3.30.0",
#     "github-pages-health-check": "1.18.2",
#     "jekyll-redirect-from": "0.16.0",
#     "jekyll-sitemap": "1.4.0",
#     "jekyll-feed": "0.17.0",
#     "jekyll-gist": "1.5.0",
#     "jekyll-paginate": "1.1.0",
#     "jekyll-coffeescript": "1.2.2",
#     "jekyll-seo-tag": "2.8.0",
#     "jekyll-github-metadata": "2.16.1",
#     "jekyll-avatar": "0.8.0",
#     "jekyll-remote-theme": "0.4.3",
#     "jekyll-include-cache": "0.2.1",
#     "jemoji": "0.13.0",
#     "jekyll-mentions": "1.6.0",
#     "jekyll-relative-links": "0.6.1",
#     "jekyll-optional-front-matter": "0.3.2",
#     "jekyll-readme-index": "0.3.0",
#     "jekyll-default-layout": "0.1.5",
#     "jekyll-titles-from-headings": "0.5.3",
#     "minima": "2.5.1",
#     "jekyll-swiss": "1.0.0",
#     "jekyll-theme-primer": "0.6.0",
#     "jekyll-theme-architect": "0.2.0",
#     "jekyll-theme-cayman": "0.2.0",
#     "jekyll-theme-dinky": "0.2.0",
#     "jekyll-theme-hacker": "0.2.0",
#     "jekyll-theme-leap-day": "0.2.0",
#     "jekyll-theme-merlot": "0.2.0",
#     "jekyll-theme-midnight": "0.2.0",
#     "jekyll-theme-minimal": "0.2.0",
#     "jekyll-theme-modernist": "0.2.0",
#     "jekyll-theme-slate": "0.2.0",
#     "jekyll-theme-tactile": "0.2.0",
#     "jekyll-theme-time-machine": "0.2.0",
#     "ruby": "3.3.4",
#     "github-pages": "232",
#     "html-pipeline": "2.14.3",
#     "sass": "3.7.4",
#     "safe_yaml": "1.0.5",
#     "nokogiri": "1.16.7"
# }
#################################################

FROM ubuntu:24.04

#################################################
# "Get the latest APT packages"
# "apt-get update"
#################################################
RUN apt-get update

#################################################
# "Install Ubuntu prerequisites for Ruby and GitHub Pages (Jekyll)"
# Copy-pasted from: https://gist.github.com/BillRaymond/db761d6b53dc4a237b095819d33c7332
# "Partially based on https://gist.github.com/jhonnymoreira/777555ea809fd2f7c2ddf71540090526"
#################################################
RUN apt-get -y install git \
    curl \
    autoconf \
    bison \
    build-essential \
    libssl-dev \
    libyaml-dev \
    libreadline6-dev \
    zlib1g-dev \
    libncurses5-dev \
    libffi-dev \
    libgdbm6 \
    libgdbm-dev \
    libdb-dev \
    apt-utils

#################################################
# "GitHub Pages/Jekyll is based on Ruby. Set the version and path"
# "As of this writing, use Ruby 3.3.4
#################################################
ENV RBENV_ROOT /usr/local/src/rbenv
ENV RUBY_VERSION 3.3.4
ENV PATH ${RBENV_ROOT}/bin:${RBENV_ROOT}/shims:$PATH

# "#################################################"
# "Install rbenv to manage Ruby versions"
#################################################
RUN git clone https://github.com/rbenv/rbenv.git ${RBENV_ROOT} \
  && git clone https://github.com/rbenv/ruby-build.git \
    ${RBENV_ROOT}/plugins/ruby-build \
  && ${RBENV_ROOT}/plugins/ruby-build/install.sh \
  && echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh

#################################################
# "Install ruby and set the global version"
#################################################
RUN rbenv install ${RUBY_VERSION} \
  && rbenv global ${RUBY_VERSION}

#################################################
# "Install the version of Jekyll that GitHub Pages supports"
# "Based on:  "
# "Note: If you always want the latest 3.10.x version,"
# "       use this line instead:"
# "       RUN gem install jekyll -v '~>3.10'"
#################################################

RUN gem install jekyll -v '3.10.0'
RUN gem install github-pages -v '232'
RUN gem install webrick
