import os
import osproc
import strformat
import strutils
import uri
import ./mkdirp
import ./rmrf

proc bin*(home: string): string =
  home / "bin"

proc env*(managerDir, bin: string): string =
  fmt"""

# {extractFilename(managerDir)}
if echo "$PATH" | grep -q "{managerDir}/"; then
  PATH=$(echo "$PATH" | sed -e "s|{managerDir}/[^:]*:||g");
fi;
export PATH="{bin}:$PATH";

"""

proc execute*(command: string, args: openArray[string] = [], workingDir: string, options = {poUsePath, poParentStreams}): Process =
  if not workingDir.existsDir:
    raise newException(OSError, "Directory does not exists. directory={workingDir}".fmt)
  when defined(windows):
    let curdir = getCurrentDir()
    setCurrentDir(workingDir)
    try:
      startProcess(command, args = args, options = options)
    finally:
      setCurrentDir(curdir)
  else:
    startProcess(command, args = args, options = options, workingDir = workingDir)

proc download*(url: string, workingDir = ""): string =
  var workDir: string = workingDir
  if workDir == "":
    workDir = getCurrentDir()

  var process: Process
  if execCmd("which wget > /dev/null") == 0:
    process = execute(command = "wget", args = @[url], workingDir = workDir)
    defer: process.close
    let err = process.waitForExit
    if err != 0:
      raise newException(OSError, "Failed to execute 'wget'. args = {@[url]}, workingDir = {workDir}".fmt)
  elif execCmd("which curl > /dev/null") == 0:
    let args = ["--progress-bar", "--show-error", "--location", "--remote-header-name", "--remote-name", url]
    process = execute(command = "curl", args = args, workingDir = workDir)
    defer: process.close
    let err = process.waitForExit
    if err != 0:
      raise newException(OSError, "Failed to execute 'curl'. args = {args}, workingDir = {workDir}".fmt)
  else:
    raise newException(OSError, "Not found both wget and curl.")

  url.parseUri.path.splitPath.tail

proc extract*(filename: string, target: string, workingDir = ""): string =
  var workDir: string = workingDir
  if workDir == "":
    workDir = getCurrentDir()

  var cat = "cat"
  if execCmd("which pv > /dev/null") == 0:
    cat = "pv"

  let head = filename.splitPath.head
  let ext = filename.splitFile.ext
  let name = filename.splitFile.name
  let base = head / name

  discard base.rmrf
  base.mkdirp

  case filename.splitFile.ext
    of ".zip":
      let temp= "{name}-temp".fmt
      temp.mkdirp
      let args = split("-o tail -d {temp} | {cat}".fmt, " ")
      let process = execute(command = "unzip", args = args, workingDir = workDir)
      defer: process.close
      let err = process.waitForExit
      if err != 0:
        raise newException(OSError, "Failed to execute 'unzip'. args = {args}, workingDir = {workDir}".fmt)
      moveDir(temp, base)
    of ".gz", ".tgz":
      #let args = split("{filename} | tar -zxf - -C {name} --strip-components=1".fmt, " ")
      #let process = execute(command = cat, args = args, workingDir = workDir)
      #defer: process.close
      #let err = process.waitForExit
      let command = "{cat} {filename} | tar -zxf - -C {name} --strip-components=1".fmt
      let err = execCmd(command)
      if err != 0:
        #raise newException(OSError, "Failed to execute 'tar'. command = {cat}, args = {args}, workingDir = {workDir}".fmt)
        raise newException(OSError, "Failed to execute 'tar'. command = {command}, workingDir = {workDir}".fmt)
    of ".xz", ".txz":
      let args = split("{filename} | tar -Jxf - -C {name} --strip-components=1".fmt, " ")
      let process = execute(command = cat, args = args, workingDir = workDir)
      defer: process.close
      let err = process.waitForExit
      if err != 0:
        raise newException(OSError, "Failed to execute 'tar'. command = {cat}, args = {args}, workingDir = {workDir}".fmt)
    else:
      raise newException(OSError, "Not supported ext. ext={ext}, filename={filename}".fmt)

  target.splitPath.head.mkdirp
  moveDir(base, target)
