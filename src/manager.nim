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
import ./root
import ./semverutils

type Manager* = ref object of RootObj
  root*: Root
  name*: string
  url*: string
  debug*: bool

proc trim(x: string): string = x.strip
proc trim(s: seq[string]): seq[string] = s.map(trim)
proc notEmpty(x: string): bool = x != ""
proc notEmpty(s: seq[string]): seq[string] = s.filter(notEmpty)

proc command(cmd: string): string =
  when defined(windows): joinPath("bin", cmd & ".cmd")
  else: joinPath("bin", cmd)

method log*(this: Manager, message: string): void {.base.} =
  if this.debug: echo message

method error*(this: Manager, message: string): void {.base.} =
  debugEcho message

method join*(this: Manager, paths: varargs[string]): string {.base.} =
  this.root.join(this.name, paths)

method tempDir*(this: Manager): string {.base.} =
  this.root.join("temp")

method exists*(this: Manager): bool {.base.} =
  this.root.exists(this.name)

method start*(this: Manager, cmd: string, args: openArray[string] = [], options = {poUsePath, poParentStreams}): Process {.base.} =
  this.root.start(this.name, cmd, args, options)

method exec*(this: Manager, cmd: string, args: openArray[string] = []): (string, int) {.base.} =
  this.root.exec(this.name, cmd, args)

method clone*(this: Manager): bool {.base.} =
  var options = {poUsePath, poParentStreams}
  if not this.debug: options = {poUsePath}

  this.log fmt"Cloning version manger of {this.name}..."
  let process = this.root.git(".", "clone", @[this.url, this.name], options)
  defer: process.close
  let ret = process.waitForExit
  if ret != 0: return false
  this.log fmt"Cloning version manger of {this.name} is done."
  return true

method pull*(this: Manager): bool {.base.} =
  var options = {poUsePath, poParentStreams}
  if not this.debug: options = {poUsePath}

  this.log fmt"Updating version manger of {this.name}..."
  let process = this.root.git(this.name, "pull", options = options)
  defer: process.close
  let ret = process.waitForExit
  if ret != 0: return false
  this.log fmt"Updating version manger of {this.name} is done."
  return true

method init*(this: Manager): bool {.base.} =
  if this.exists:
    this.log fmt("Specified application is not found: app={this.name}")
    return false

  var output: string
  var returnCode: int
  let url = "https://github.com/shishidosoichiro/vendor-init.git"
  (output, returnCode) = this.root.execGit(".", "clone", @[url, this.name])
  if not this.debug: echo output
  if returnCode != 0: return false
  (output, returnCode) = this.root.execGit(this.name, "remote", @["remove", "origin"])
  if not this.debug: echo output
  if returnCode != 0: return false
  (output, returnCode) = this.root.execGit(this.name, "remote", @["add", "init", url])
  if not this.debug: echo output
  if returnCode != 0: return false
  this.log fmt"Initializing version manger of {this.name} is done."
  return true

method bin*(this: Manager, version: string): string {.base.} =
  let cmd = command("bin")
  let (output, err) = this.exec(cmd, @[version])
  if err == 0:
    return output
  else:
    this.error output
    return ""

method env*(this: Manager, version: string): string {.base.} =
  let cmd = command("env")
  let (output, err) = this.exec(cmd, @[version])
  if err == 0:
    return output
  else:
    this.error output
    return ""

method home*(this: Manager, version: string): string {.base.} =
  return this.join("versions", version)

method installed*(this: Manager): seq[string] {.base.} =
  var versions: seq[string] = @[]
  let path = this.join("versions")
  for fullpath in "{path}/*".fmt.walkDirs():
    versions.add(fullpath.extractFilename)
  return versions.sorted(cmpSemver)

method versions*(this: Manager): seq[string] {.base.} =
  let cmd = command("versions")
  let (output, err) = this.exec(cmd)
  if err == 0:
    return output.split('\n').trim.notEmpty.sorted(cmpSemver)
  else:
    this.error output
    return @[]

method latest*(this: Manager, local = false): string {.base.} =
  var list: seq[string] = @[]
  if local:
    list = this.installed
  else:
    list = this.versions
  if list.len == 0:
    ""
  else:
    list[list.len - 1]

method install*(this: Manager, version: string): void {.base.} =
  let cmd = command("install")
  let process = this.start(cmd, @[version])
  defer: process.close
  discard process.waitForExit

method uninstall*(this: Manager, version: string): void {.base.} =
  this.home(version).removeDir

method newManager*(root: Root, app: string): Manager {.base.} =
  let manager = Manager(root: root, name: app, url: "", debug: root.debug)
  let records = root.loadVendorRecords
  if records.hasKey(app): manager.url = records[app].url
  return manager
