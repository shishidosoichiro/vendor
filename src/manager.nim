import algorithm
import httpclient
import options
import os
#from os import copyDirWithPermissions, copyFileWithPermissions, getFileInfo, pcFile, pcLinkToFile, pcDir, pcLinkToDir, walkDir
import ospaths
import osproc
import sequtils
import streams
import strformat
import strutils
import tables
import uri
import ./mkdirp
import ./semverutils

type Manager* = ref object of RootObj
  homeDir*: string
  appsDir*: string
  vendorsFile*: string
  debug*: bool

type VendorRecord = ref object of RootObj
  name*: string
  url*: string

proc trim(x: string): string = x.strip
proc trim(s: seq[string]): seq[string] = s.map(trim)
proc notEmpty(x: string): bool = x != ""
proc notEmpty(s: seq[string]): seq[string] = s.filter(notEmpty)
proc parseVendorRecord(line: string): VendorRecord =
  let sp = line.split(" ")
  return VendorRecord(name: sp[0], url: sp[1])

method log*(this: Manager, message: string): void {.base.} =
  if this.debug: echo message

method error*(this: Manager, message: string): void {.base.} =
  debugEcho message

method join*(this: Manager, app: string, paths: varargs[string]): string {.base.} =
  var head = this.appsDir.expandTilde.absolutePath
  if app == "..":
    head = head.parentDir
  elif app == ".":
    head = head
  else:
    head = head / app
  @[head].concat(@paths).joinPath

method tempDir*(this: Manager): string {.base.} =
  this.join("temp")

method existsDir*(this: Manager, app: string, paths: varargs[string]): bool {.base.} =
  this.join(app, paths).existsDir

method exists*(this: Manager, app: string = "."): bool {.base.} =
  this.existsDir(app)

method command*(this: Manager, app, cmd: string): string {.base.} =
  when defined(windows): joinPath("bin", cmd & ".cmd")
  else: joinPath("bin", cmd)

method start*(this: Manager, app, cmd: string, args: openArray[string] = [], options = {poUsePath, poParentStreams}): Process {.base.} =
  let workingDir = this.join(app)
  #debugEcho "workingDir: {workingDir}, cmd: {cmd}, args: {args}".fmt
  when defined(windows):
    let curdir = getCurrentDir()
    setCurrentDir(workingDir)
    try:
      startProcess(cmd, args = args, options = options)
    finally:
      setCurrentDir(curdir)
  else:
    startProcess(cmd, args = args, options = options, workingDir = workingDir)

method exec*(this: Manager, app, cmd: string, args: openArray[string] = []): (string, int) {.base.} =
  let process = this.start(app, cmd, args, {poStdErrToStdOut, poUsePath})
  let stream = process.outputStream
  var lines: seq[string] = @[]
  while not stream.atEnd:
    lines.add(string(stream.readLine()))
  let err = process.waitForExit
  return (lines.join("\n"), err)

method git*(this: Manager, app, cmd: string, args: openArray[string] = [], options = {poUsePath, poParentStreams}): Process {.base.} =
  this.start(app, "git", concat(@[cmd], @args), options)

method execGit*(this: Manager, app, cmd: string, args: openArray[string] = []): (string, int) {.base.} =
  this.exec(app, "git", concat(@[cmd], @args))

method loadVendorRecords*(this: Manager): Table[string, VendorRecord] {.base.} =
  result = initTable[string, VendorRecord]()
  let records = this.vendorsFile
    .readFile
    .split("\n")
    .notEmpty
    .map(parseVendorRecord)
  for record in records:
    result[record.name] = record
  return result

method loadVendorRecord*(this: Manager, app: string): VendorRecord {.base.} =
  let records = this.loadVendorRecords
  if not records.hasKey(app): return nil
  return records[app]

method search*(this: Manager, word: string): void {.base.} =
  let records = this.loadVendorRecords
  for app in records.keys:
    if app.contains(word): echo app

method cloneRoot*(this: Manager): bool {.base.} =
  var options = {poUsePath, poParentStreams}
  if not this.debug: options = {poUsePath}

  this.log "Cloning vendor-home..."
  let (head, dirname) = this.homeDir.splitPath
  let url = "https://github.com/shishidosoichiro/vendor-home.git"
  let process = this.git("..", "clone", @[url, dirname], options)
  defer: process.close
  let ret = process.waitForExit
  if ret != 0: return false
  this.log "Cloning vendor-home is done."
  mkdirp(this.appsDir)
  return true

method pullRoot*(this: Manager): bool {.base.} =
  var options = {poUsePath, poParentStreams}
  if not this.debug: options = {poUsePath}

  if not this.existsDir("."):
    return this.cloneRoot()

  this.log "Updating vendor-home..."
  let process = this.git(".", "pull", options = options)
  defer: process.close
  let ret = process.waitForExit
  if ret != 0: return false
  this.log fmt"Updating vendor-home is done."
  return true

method clone*(this: Manager, app: string): bool {.base.} =
  var options = {poUsePath, poParentStreams}
  if not this.debug: options = {poUsePath}

  let record = this.loadVendorRecord(app)
  if record == nil:
    this.log fmt("Specified application is not found: app={app}")
    return false

  this.log fmt("{app} is found. url={record.url}")
  this.log fmt"Cloning version manger of {app}..."
  let process = this.git(".", "clone", @[record.url, app], options)
  defer: process.close
  let ret = process.waitForExit
  if ret != 0: return false
  this.log fmt"Cloning version manger of {app} is done."
  return true

method pull*(this: Manager, app: string): bool {.base.} =
  var options = {poUsePath, poParentStreams}
  if not this.debug: options = {poUsePath}

  if not this.exists(app):
    return this.clone(app)

  this.log fmt"Updating version manger of {app}..."
  let process = this.git(app, "pull", options = options)
  defer: process.close
  let ret = process.waitForExit
  if ret != 0: return false
  this.log fmt"Updating version manger of {app} is done."
  return true

method init*(this: Manager, app: string): bool {.base.} =
  if this.exists(app):
    this.log fmt("Specified application is not found: app={app}")
    return false

  var output: string
  var returnCode: int
  let url = "https://github.com/shishidosoichiro/vendor-init.git"
  (output, returnCode) = this.execGit(".", "clone", @[url, app])
  if not this.debug: echo output
  if returnCode != 0: return false
  (output, returnCode) = this.execGit(app, "remote", @["remove", "origin"])
  if not this.debug: echo output
  if returnCode != 0: return false
  (output, returnCode) = this.execGit(app, "remote", @["add", "init", url])
  if not this.debug: echo output
  if returnCode != 0: return false
  this.log fmt"Initializing version manger of {app} is done."
  return true

method apps*(this: Manager): seq[string] {.base.} =
  let (output, err) = this.exec(".", "ls", ["-1"])
  if err == 0:
    return output.split('\n').trim.notEmpty
  else:
    this.error output
    return @[]

method bin*(this: Manager, app: string, version: string): string {.base.} =
  let cmd = this.command(app, "bin")
  let (output, err) = this.exec(app, cmd, @[version])
  if err == 0:
    return output
  else:
    this.error output
    return ""

method env*(this: Manager, app: string, version: string): string {.base.} =
  let cmd = this.command(app, "env")
  let (output, err) = this.exec(app, cmd, @[version])
  if err == 0:
    return output
  else:
    this.error output
    return ""

method home*(this: Manager, app: string, version: string): string {.base.} =
  return this.join(app, "versions", version)

method installed*(this: Manager, app: string): seq[string] {.base.} =
  var versions: seq[string] = @[]
  let path = this.join(app, "versions")
  for fullpath in "{path}/*".fmt.walkDirs():
    versions.add(fullpath.extractFilename)
  return versions.sorted(cmpSemver)

method versions*(this: Manager, app: string): seq[string] {.base.} =
  let cmd = this.command(app, "versions")
  let (output, err) = this.exec(app, cmd)
  if err == 0:
    return output.split('\n').trim.notEmpty.sorted(cmpSemver)
  else:
    this.error output
    return @[]

method latest*(this: Manager, app: string, local = false): string {.base.} =
  var list: seq[string] = @[]
  if local:
    list = this.installed(app)
  else:
    list = this.versions(app)
  if list.len == 0:
    ""
  else:
    list[list.len - 1]

method install*(this: Manager, app: string, version: string): void {.base.} =
  let cmd = this.command(app, "install")
  let process = this.start(app, cmd, @[version])
  defer: process.close
  discard process.waitForExit

method uninstall*(this: Manager, app: string, version: string): void {.base.} =
  if not this.existsDir(app):
    echo "not installed application: {app}".fmt
    return

  let versionDir = this.join(app, "versions", version)
  if not versionDir.existsDir:
    echo "not installed version: app={app} version={version}".fmt
    return

  echo "removing {app}@{version}...".fmt
  versionDir.removeDir
  echo "removing {app}@{version} is done.".fmt

method crobber*(this: Manager): void {.base.} =
  if not this.appsDir.existsDir:
    echo "applications directory not exists.: {this.appsDir}".fmt
    return

  echo "  appsDir: {this.appsDir}".fmt
  stdout.write "Really crobber? [y/N]: "
  let answer = readLine(stdin).normalize
  if answer != "y": return

  echo "removing {this.appsDir}...".fmt
  this.appsDir.removeDir
  echo "removing {this.appsDir} is done.".fmt
