# Vendor

DIY Application Version Manager

## Install

```
wget <url>/vendor-0.0.1-darwin.tar.gz
tar -xvzf vendor-0.0.1-darwin.tar.gz
mv ./vendor-0.0.1-darwin/vendor /usr/local/bin
```

## Install

```
vendor install nim node duktape
```

## Set env

```
eval $(vendor env)
```


## Usage

```

    vendor

Usage:
  vendor (-h|--help)
  vendor (-v|--version)
  vendor [options] bin [<app-and-or-version>...]
  vendor [options] env [<app-and-or-version>...]
  vendor [options] home [<app-and-or-version>...]
  vendor [options] install [<app-and-or-version>...]
  vendor [options] latest [-l|--local] [<app>...]
  vendor [options] ls [-l|--long] [<app>...]
  vendor [options] search <app>
  vendor [options] uninstall [<app-and-or-version>...]
  vendor [options] versions [<app>...]
  vendor [options] manager exec <app> [--] <cmd> [<args>...]
  vendor [options] manager pull [<app>...]
  vendor [options] manager init <app>
  vendor [options] root crobber
  vendor [options] root pull
  vendor [options] util download <url>

Options:
  -a, --apps-dir=DIR        Specify apps home dir
  -d, --debug               Debug mode
  -f, --vendors-list=FILE   Specify vendors list file.
  -h, --help                Output help
  -l, --long                with version
  -r, --remote              from remote.
  -u, --update              update
  -v, --version             Output version
  -y, --yes                 Yes

Commands:
  bin             Output bin directories of applications with ':' delimited.
  env             Output env scripts each application.
  home            Output home directories of applications.
  install         Install applications
  ls              Output installed versions of each application
  uninstall       Uninstall versions of applications
  versions        Output versions of each applications
  manager exec    Excecute <cmd> on <app> work dirrectory.
  manager pull    Download specified application version managers.
  root crobber    Remove
  root pull       Update version.txt
  util download   download url and output downloaded filename.
```


## todo

- vendor-init
  - ./bin/download stdout with wget curl
  - ./bin/download remove querystring from filename
- pull vendor.txt from another url.
- add manager to vendor.txt
- `vendor pull <app>@<url>`
- verify downloaded executable file with its hash.
- keep latest version
- mark installed versions when list versions.


- through stdout/stderr/stdin using async or threads
- color styled stdout/stderr
