# Package

version       = "0.3.4"
author        = "Soichiro Shishido"
description   = "app and version vendor"
license       = "MIT"
srcDir        = "src"
bin           = @["vendor"]


# Dependencies

requires "nim >= 1.0.0"
requires "docopt >= 0.6.8"
requires "options >= 0.1.0"
requires "regex >= 0.12.0"
requires "semver >= 1.1.0"

task version, "output version":
  echo version
