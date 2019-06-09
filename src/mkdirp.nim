import os
import sequtils
import strutils

proc notEmpty(x: string): bool = x != ""

proc mkdirp*(dir: string): void =
  var parent = ""
  for seg in dir.split(DirSep).filter(notEmpty):
    parent = parent / seg
    discard existsOrCreateDir(parent)
