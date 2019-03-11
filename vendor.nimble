# Package

version       = "0.0.1"
author        = "Soichiro Shishido"
description   = "app and version vendor"
license       = "MIT"
srcDir        = "src"
bin           = @["vendor"]


# Dependencies

requires "nim >= 0.19.2"
requires "docopt"

task windows, "build for windows":
  switch("opt", "size")
  switch("define", "ssl")
  switch("define", "mingw")
  setCommand "build"
