let doc = """
::

    vendor

Usage:
  vendor (-h|--help)
  vendor (-v|--version)
  vendor [options] bin [<app-and-or-version>...]
  vendor [options] env [<app-and-or-version>...]
  vendor [options] home [<app-and-or-version>...]
  vendor [options] install [<app-and-or-version>...]
  vendor [options] latest [--local] [<app>...]
  vendor [options] ls [-l|--long] [<app>...]
  vendor [options] search <app>
  vendor [options] uninstall [<app-and-or-version>...]
  vendor [options] versions [<app>...]
  vendor [options] manager exec <app> [--] <cmd> [<args>...]
  vendor [options] manager pull [<app>...]
  vendor [options] manager init <app>
  vendor [options] root crobber
  vendor [options] root exec [--] <cmd> [<args>...]
  vendor [options] root pull

Options:
  -a, --home-dir=DIR        Specify vendor home dir
  -d, --debug               Debug mode
  -f, --vendors-list=FILE   Specify vendors list file.
  -h, --help                Output help
  -l, --long                with version
  -u, --update              update
  -v, --version             Output version
  -y, --yes                 Yes

Commands:
  bin             Output bin directories of applications with ':' delimited.
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
  root pull       Update version.txt

::
"""

import docopt
import os
import ospaths
import osproc
import sequtils
import strformat
import strutils
import system
#import tables
#import yaml/presenter
#import yaml/serialization
import ./manager
import ./parse
#import ./pipe

proc atmark(x: string, y: string): string =
  fmt("{x}@{y}")

proc atmark(x: string): (proc(t: string): string) =
  return proc(y: string): string = x.atmark(y)

proc atmark(s: seq[string], x: string): seq[string] =
  s.map(atmark(x))

when isMainModule:
  let args = docopt(doc, version = "Vendor 0.1.1")

  var homeDir = $args["--home-dir"]
  if homeDir == "nil":
    homeDir = getEnv("VENDOR_HOME_DIR", getHomeDir() / ".vendor")

  let appsDir = homeDir / "apps"

  var vendorsFile = $args["--vendors-list"]
  if vendorsFile == "nil":
    vendorsFile = getEnv("VENDOR_LIST", homeDir / "vendors.txt")

  let debug = args["--debug"]
  let update = args["--update"]
  let yes = args["--yes"]
  let long = args["--long"]
  let local = args["--local"]

  let m = Manager(homeDir: homeDir, appsDir: appsDir, vendorsFile: vendorsFile, debug: debug)

  proc apps(defaults: seq[string]): seq[string] =
    if defaults.len == 0: m.apps
    else: defaults

  # bin
  if args["bin"]:
    if (not m.exists or update) and not m.pullRoot: quit(QuitFailure)
    for appver in apps(@(args["<app-and-or-version>"])):
      var (app, version) = parse(appver)
      if (not m.exists(app) or update) and not m.pull(app): continue
      if version == "latest": version = m.latest(app, local = true)
      echo m.bin(app, version)

  # env
  elif args["env"]:
    if (not m.exists or update) and not m.pullRoot: quit(QuitFailure)
    for appver in apps(@(args["<app-and-or-version>"])):
      var (app, version) = parse(appver)
      if (not m.exists(app) or update) and not m.pull(app): continue
      if version == "latest": version = m.latest(app, local = true)
      echo m.env(app, version)

  # home
  elif args["home"]:
    if (not m.exists or update) and not m.pullRoot: quit(QuitFailure)
    for appver in apps(@(args["<app-and-or-version>"])):
      var (app, version) = parse(appver)
      if (not m.exists(app) or update) and not m.pull(app): continue
      if version == "latest": version = m.latest(app, local = true)
      echo m.home(app, version)

  # install
  elif args["install"]:
    if (not m.exists or update) and not m.pullRoot: quit(QuitFailure)
    for appver in apps(@(args["<app-and-or-version>"])):
      var (app, version) = parse(appver)
      if (not m.exists(app) or update) and not m.pull(app): continue
      if version == "latest": version = m.latest(app)
      m.install(app, version)

  # latest
  elif args["latest"]:
    if (not m.exists or update) and not m.pullRoot: quit(QuitFailure)
    for app in apps(@(args["<app>"])):
      if (not m.exists(app) or update) and not m.pull(app): continue
      let latest = m.latest(app, local)
      if latest != "": echo atmark(app, latest)

  # ls
  elif args["ls"]:
    if (not m.exists or update) and not m.pullRoot: quit(QuitFailure)
    let apps = apps(@(args["<app>"]))
    if long:
      for app in apps(@(args["<app>"])):
        if (not m.exists(app) or update) and not m.pull(app): continue
        let output = m.installed(app).atmark(app).join("\n")
        if output != "": echo output
    else:
      if apps.len > 0: echo apps.join("\n")

  # search
  elif args["search"]:
    if (not m.exists or update) and not m.pullRoot: quit(QuitFailure)
    m.search($args["<app>"])

  # uninstall
  elif args["uninstall"]:
    if update and not m.pullRoot: quit(QuitFailure)
    for appver in apps(@(args["<app-and-or-version>"])):
      var (app, version) = parse(appver)
      if (not m.exists(app) or update) and not m.pull(app): continue
      if version == "latest": version = m.latest(app, local = true)
      if version == "": continue
      m.uninstall(app, version)

  # versions
  elif args["versions"]:
    if (not m.exists or update) and not m.pullRoot: quit(QuitFailure)
    for app in apps(@(args["<app>"])):
      if (not m.exists(app) or update) and not m.pull(app): continue
      let output = m.versions(app).atmark(app).join("\n")
      if output != "": echo output

  # manager exec
  elif args["manager"] and args["exec"]:
    if update and not m.pullRoot: quit(QuitFailure)
    let app = $args["<app>"]
    let cmd = $args["<cmd>"]
    let cmdargs = @(args["<args>"])
    let process = m.start(app, cmd, cmdargs)
    defer: process.close
    #await (process > stdout) and (process.errorStream > stderr)
    discard process.waitForExit

  # manager init
  elif args["manager"] and args["init"]:
    let app = $args["<app>"]
    if update and not m.pullRoot: quit(QuitFailure)
    discard m.init(app)

  # manager pull
  elif args["manager"] and args["pull"]:
    if update and not m.pullRoot: quit(QuitFailure)
    for app in apps(@(args["<app>"])):
      if m.pull(app): continue

  # root crobber
  elif args["root"] and args["crobber"]:
    m.crobber

  # root exec
  elif args["root"] and args["exec"]:
    if update and not m.pullRoot: quit(QuitFailure)
    let cmd = $args["<cmd>"]
    let cmdargs = @(args["<args>"])
    let process = m.start(".", cmd, cmdargs)
    defer: process.close
    #await (process > stdout) and (process.errorStream > stderr)
    discard process.waitForExit

  # root pull
  elif args["root"] and args["pull"]:
    if not m.pullRoot: quit(QuitFailure)

  else:
    echo args

  quit(QuitSuccess)
