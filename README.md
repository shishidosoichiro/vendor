# Vendor

DIY Application Version Manager

## Install vendor

### Linux

```
wget https://github.com/shishidosoichiro/vendor/releases/download/0.3.0/vendor-0.3.0-linux-amd64.tar.gz
tar -xvzf vendor-0.3.0-linux-amd64.tar.gz
mv ./vendor-0.3.0-linux-amd64/vendor /usr/local/bin
echo ". <(vendor completion bash)" >> ~/.bashrc
```

### Mac OS

```
curl --progress-bar --show-error --location "https://github.com/shishidosoichiro/vendor/releases/download/0.3.0/vendor-0.3.0-darwin-amd64.tar.gz" --output - > vendor-0.3.0-darwin-amd64.tar.gz
tar -xvzf vendor-0.3.0-darwin-amd64.tar.gz
mv ./vendor-0.3.0-darwin-amd64/vendor ~/bin/vendor
echo ". <(vendor completion bash)" >> ~/.bashrc
```

### Windows

```
curl --progress-bar --show-error --location "https://github.com/shishidosoichiro/vendor/releases/download/0.3.0/vendor-0.3.0-windows-amd64.zip" --output - > vendor-0.3.0-windows-amd64.zip
unzip vendor-0.3.0-windows-amd64.zip
cp -pr ./vendor-0.3.0-windows-amd64/vendor ~/bin
echo ". <(vendor completion bash)" >> ~/.bashrc
```

## Install applications

```
vendor install nim node duktape
```

## Set env

```
eval $(vendor env)
. <(vendor env)
```


## Usage

```
::

    vendor - DIY Application Version Manager

Usage:
  vendor (-h|--help)
  vendor (-v|--version)
  vendor [options] bin [--shell] [<app-and-or-version>...]
  vendor [options] completion <shell>
  vendor [options] env [--shell] [<app-and-or-version>...]
  vendor [options] home [--shell] [<app-and-or-version>...]
  vendor [options] install [<app-and-or-version>...]
  vendor [options] latest [--local] [<app>...]
  vendor [options] ls [-l|--long] [-r|--remote] [<app>...]
  vendor [options] search [<app>]
  vendor [options] uninstall [<app-and-or-version>...]
  vendor [options] versions [<app>...]
  vendor [options] manager exec <app> [--] <cmd> [<args>...]
  vendor [options] manager pull [<app>...]
  vendor [options] manager init <app>
  vendor [options] root crobber
  vendor [options] root exec [--] <cmd> [<args>...]
  vendor [options] root pull
  vendor [options] util bin <home>
  vendor [options] util env <manager-dir> <bin>

Options:
  -a, --home-dir=DIR        Specify vendor home dir
  -d, --debug               Debug mode
  -f, --vendors-list=FILE   Specify vendors list file.
  -h, --help                Output help
  -m, --mark                Add installed mark '*'
  -l, --long                With version
  --shell                   Output with shell path
  -r, --remote              remote
  -u, --update              update
  -v, --version             Output version

Commands:
  bin             Output bin directories of applications with ':' delimited.
  completion      Output completion script. `source <(vendor completion bash)`
  env             Output env scripts each application.
  home            Output home directories of applications.
  install         Install applications
  latest          Output the latest versions of each application
  ls              Output installed versions of each application
  uninstall       Uninstall versions of applications
  versions        Output versions of each applications
  manager exec    Excecute <cmd> on <app> work dirrectory.
  manager pull    Download specified application version managers.
  root crobber    Remove everything
  root exec       Excecute <cmd> on root dirrectory.
  root pull       Update version.txt.
  util bin        Output default bin path.
  util env        Output default env script.

::
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


- through stdout/stderr/stdin using async or threads
- color styled stdout/stderr
