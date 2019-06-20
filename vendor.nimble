# Package

version       = "0.2.4"
author        = "Soichiro Shishido"
description   = "app and version vendor"
license       = "MIT"
srcDir        = "src"
bin           = @["vendor"]


# Dependencies

requires "nim >= 0.19.2"
requires "docopt >= 0.6.8"
requires "options >= 0.1.0"
requires "regex >= 0.7.4"
requires "semver >= 1.1.0"

task version, "output version":
  echo version
