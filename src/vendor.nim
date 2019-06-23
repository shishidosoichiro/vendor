let doc = """
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
  -l, --long                with version
  --shell                   Output with shell path
  -r, --remote              remote
  -u, --update              update
  -v, --version             Output version
  -y, --yes                 Yes

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
"""
const versionInfo = "Vendor " & staticExec("cd .. && (nimble version | grep -v Executing)") &
                  "\nRevision " & staticExec("git rev-parse HEAD") &
                  "\nCompiled on " & staticExec("uname -v") &
                  "\nNimVersion " & NimVersion
const completion = staticRead("../completion.bash")

import docopt
import os
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
import ./root
import ./utils

proc atmark(x: string, y: string): string =
  fmt("{x}@{y}")

proc atmark(x: string): (proc(t: string): string) =
  return proc(y: string): string = x.atmark(y)

proc atmark(s: seq[string], x: string): seq[string] =
  s.map(atmark(x))

proc echoError*(message: string): void =
  stderr.writeLine(message)

proc load(root: Root, app: string, update: bool): Manager =
  let manager = root.newManager(app)
  if not manager.existsDir:
    if manager.url == "":
      echoError "{app}: not found in vendors.txt".fmt
      return nil
    if not manager.clone:
      echoError "{app}: failed to clone its manager. url: {manager.url}".fmt
      return nil
  elif update:
    if not manager.pull:
      echoError "{app}: failed to pull its manager. url: {manager.url}".fmt
      return nil
  return manager

proc main(): int =
  let args = docopt(doc, version = versionInfo)

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
  let remote = args["--remote"]
  let shell = args["--shell"]

  let root = Root(homeDir: homeDir, appsDir: appsDir, vendorsFile: vendorsFile, debug: debug)

  proc apps(defaults: seq[string]): seq[string] =
    if defaults.len == 0: root.apps
    else: defaults

  # bin
  if args["bin"] and not args["util"]:
    if (not root.existsDir or update) and not root.pull: return QuitFailure
    for appver in apps(@(args["<app-and-or-version>"])):
      var (app, version) = parse(appver)
      let manager = root.load(app, update)
      if manager == nil:
        result = QuitFailure
        continue
      if version == "latest": version = manager.latest(local = true)
      let output = manager.bin(version, shell)
      if output == "":
        echoError "{app}: \"bin\" failed.".fmt
        result = QuitFailure
        continue
      echo output

  # completion
  elif args["completion"]:
    stdout.write(completion)

  # env
  elif args["env"] and not args["util"]:
    if (not root.existsDir or update) and not root.pull: return QuitFailure
    for appver in apps(@(args["<app-and-or-version>"])):
      var (app, version) = parse(appver)
      let manager = root.load(app, update)
      if manager == nil:
        result = QuitFailure
        continue
      if version == "latest": version = manager.latest(local = true)
      let output = manager.env(version, shell)
      if output == "":
        echoError "{app}: \"env\" failed.".fmt
        result = QuitFailure
        continue
      echo output

  # home
  elif args["home"]:
    if (not root.existsDir or update) and not root.pull: return QuitFailure
    for appver in apps(@(args["<app-and-or-version>"])):
      var (app, version) = parse(appver)
      let manager = root.load(app, update)
      if manager == nil:
        result = QuitFailure
        continue
      if version == "latest": version = manager.latest(local = true)
      let output = manager.home(version, shell)
      if output == "":
        echoError "{app}: \"home\" failed.".fmt
        result = QuitFailure
        continue
      echo output

  # install
  elif args["install"]:
    if (not root.existsDir or update) and not root.pull: return QuitFailure
    for appver in apps(@(args["<app-and-or-version>"])):
      var (app, version) = parse(appver)
      let manager = root.load(app, update)
      if manager == nil:
        result = QuitFailure
        continue
      if version == "latest": version = manager.latest
      manager.install(version)

  # latest
  elif args["latest"]:
    if (not root.existsDir or update) and not root.pull: return QuitFailure
    for app in apps(@(args["<app>"])):
      let manager = root.load(app, update)
      if manager == nil:
        result = QuitFailure
        continue
      let latest = manager.latest(local)
      if latest == "":
        echoError "{app}: lat\"est\" failed.".fmt
        result = QuitFailure
        continue
      echo atmark(app, latest)

  # ls
  elif args["ls"]:
    if (not root.existsDir or update) and not root.pull: return QuitFailure
    let apps = apps(@(args["<app>"]))
    if long:
      for app in apps(@(args["<app>"])):
        let manager = root.load(app, update)
        if manager == nil:
          result = QuitFailure
          continue
        var output = ""
        if remote:
          output = manager.versions.atmark(app).join("\n")
          if output == "":
            echoError "{app}: \"versions\" failed.".fmt
            result = QuitFailure
            continue
        else:
          output = manager.installed.atmark(app).join("\n")
          if output == "":
            echoError "{app}: \"installed\" failed.".fmt
            result = QuitFailure
            continue
        echo output
    else:
      if remote:
        echo root.apps.join("\n")
      else:
        if apps.len > 0: echo apps.join("\n")

  # search
  elif args["search"]:
    if (not root.existsDir or update) and not root.pull: return QuitFailure
    if $args["<app>"] == "[]" or $args["<app>"] == "nil" or $args["<app>"] == "":
      echo root.apps.join("\n")
    else:
      root.search($args["<app>"])

  # uninstall
  elif args["uninstall"]:
    if (not root.existsDir or update) and not root.pull: return QuitFailure
    for appver in apps(@(args["<app-and-or-version>"])):
      var (app, version) = parse(appver)
      let manager = root.newManager(app)
      if (not manager.existsDir):
        echoError "{app}: not installed.".fmt
        result = QuitFailure
        continue
      if not manager.home(version).existsDir:
        echoError "{appver}: not installed.".fmt
        result = QuitFailure
        continue

      echo "removing {appver}...".fmt
      manager.uninstall(version)
      echo "removing {appver} is done.".fmt

  # versions
  elif args["versions"]:
    if (not root.existsDir or update) and not root.pull: return QuitFailure
    for app in apps(@(args["<app>"])):
      let manager = root.load(app, update)
      if manager == nil:
        result = QuitFailure
        continue
      let output = manager.versions.atmark(app).join("\n")
      if output == "":
        echoError "{app}: \"versions\" failed.".fmt
        result = QuitFailure
        continue
      echo output

  # manager exec
  elif args["manager"] and args["exec"]:
    if (not root.existsDir or update) and not root.pull: return QuitFailure
    let app = $args["<app>"]
    let cmd = $args["<cmd>"]
    let cmdargs = @(args["<args>"])
    let manager = root.newManager(app)
    let process = manager.start(cmd, cmdargs)
    defer: process.close
    #await (process > stdout) and (process.errorStream > stderr)
    result = process.waitForExit

  # manager init
  elif args["manager"] and args["init"]:
    if (not root.existsDir or update) and not root.pull: return QuitFailure
    let app = $args["<app>"]
    let manager = root.newManager(app)
    if update and not root.pull: return QuitFailure
    discard manager.init

  # manager pull
  elif args["manager"] and args["pull"]:
    if (not root.existsDir or update) and not root.pull: return QuitFailure
    for app in apps(@(args["<app>"])):
      let manager = root.newManager(app)
      if manager.pull: continue

  # root crobber
  elif args["root"] and args["crobber"]:
    root.crobber

  # root exec
  elif args["root"] and args["exec"]:
    if (not root.existsDir or update) and not root.pull: return QuitFailure
    let cmd = $args["<cmd>"]
    let cmdargs = @(args["<args>"])
    let process = root.start(".", cmd, cmdargs)
    defer: process.close
    #await (process > stdout) and (process.errorStream > stderr)
    result = process.waitForExit

  # root pull
  elif args["root"] and args["pull"]:
    if not root.pull: return QuitFailure

  # util bin
  elif args["util"] and args["bin"]:
    let home = $args["<home>"]
    echo utils.bin(home)

  # util env
  elif args["util"] and args["env"]:
    let managerDir = $args["<manager-dir>"]
    let bin = $args["<bin>"]
    echo utils.env(managerDir, bin)

  else:
    echo args

when isMainModule:
  let returnCode = main()
  quit(returnCode)
