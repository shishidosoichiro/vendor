# Package

version       = "0.1.1"
author        = "Soichiro Shishido"
description   = "app and version vendor"
license       = "MIT"
srcDir        = "src"
bin           = @["vendor"]


# Dependencies

requires "nim >= 0.19.2"
requires "docopt"
requires "options >= 0.1.0"
requires "semver >= 1.1.0"

task windows, "build for windows":
  switch("opt", "size")
  switch("define", "ssl")
  switch("define", "mingw")
  setCommand "build"
