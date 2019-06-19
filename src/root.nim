import algorithm
import httpclient
import options
import os
#from os import copyDirWithPermissions, copyFileWithPermissions, getFileInfo, pcFile, pcLinkToFile, pcDir, pcLinkToDir, walkDir
import osproc
import sequtils
import streams
import strformat
import strutils
import tables
import uri
import ./mkdirp
import ./semverutils

type Root* = ref object of RootObj
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

method log*(this: Root, message: string): void {.base.} =
  if this.debug: echo message

method error*(this: Root, message: string): void {.base.} =
  debugEcho message

method join*(this: Root, app: string, paths: varargs[string]): string {.base.} =
  var head = this.appsDir.expandTilde.absolutePath
  if app == "..":
    head = head.parentDir
  elif app == ".":
    head = head
  else:
    head = head / app
  @[head].concat(@paths).joinPath

method tempDir*(this: Root): string {.base.} =
  this.join("temp")

method existsDir*(this: Root, app: string = ".", paths: varargs[string]): bool {.base.} =
  this.join(app, paths).existsDir

method existsFile*(this: Root, app: string = ".", paths: varargs[string]): bool {.base.} =
  this.join(app, paths).existsFile

method start*(this: Root, app, cmd: string, args: openArray[string] = [], options = {poUsePath, poParentStreams}): Process {.base.} =
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

method exec*(this: Root, app, cmd: string, args: openArray[string] = []): (string, int) {.base.} =
  let process = this.start(app, cmd, args, {poStdErrToStdOut, poUsePath})
  let stream = process.outputStream
  var lines: seq[string] = @[]
  while not stream.atEnd:
    lines.add(string(stream.readLine()))
  let err = process.waitForExit
  return (lines.join("\n"), err)

method git*(this: Root, app, cmd: string, args: openArray[string] = [], options = {poUsePath, poParentStreams}): Process {.base.} =
  this.start(app, "git", concat(@[cmd], @args), options)

method execGit*(this: Root, app, cmd: string, args: openArray[string] = []): (string, int) {.base.} =
  this.exec(app, "git", concat(@[cmd], @args))

method loadVendorRecords*(this: Root): Table[string, VendorRecord] {.base.} =
  result = initTable[string, VendorRecord]()
  let records = this.vendorsFile
    .readFile
    .split("\n")
    .notEmpty
    .map(parseVendorRecord)
  for record in records:
    result[record.name] = record
  return result

method loadVendorRecord*(this: Root, app: string): VendorRecord {.base.} =
  let records = this.loadVendorRecords
  if not records.hasKey(app): return nil
  return records[app]

method search*(this: Root, word: string): void {.base.} =
  let records = this.loadVendorRecords
  for app in records.keys:
    if app.contains(word): echo app

method clone*(this: Root): bool {.base.} =
  var options = {poUsePath, poParentStreams}
  if not this.debug: options = {poUsePath}

  this.log "Cloning vendor-home..."
  let (_, dirname) = this.homeDir.splitPath
  let url = "https://github.com/shishidosoichiro/vendor-home.git"
  let process = this.git("..", "clone", @[url, dirname], options)
  defer: process.close
  let ret = process.waitForExit
  if ret != 0: return false
  this.log "Cloning vendor-home is done."
  mkdirp(this.appsDir)
  return true

method pull*(this: Root): bool {.base.} =
  var options = {poUsePath, poParentStreams}
  if not this.debug: options = {poUsePath}

  if not this.existsDir:
    return this.clone()

  this.log "Updating vendor-home..."
  let process = this.git(".", "pull", options = options)
  defer: process.close
  let ret = process.waitForExit
  if ret != 0: return false
  this.log fmt"Updating vendor-home is done."
  return true

method apps*(this: Root): seq[string] {.base.} =
  let (output, err) = this.exec(".", "ls", ["-1"])
  if err == 0:
    return output.split('\n').trim.notEmpty
  else:
    this.error output
    return @[]

method crobber*(this: Root): void {.base.} =
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
