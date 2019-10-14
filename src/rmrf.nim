import osproc
import strformat

proc rmrf*(pattern: string): int =
  execCmd("rm -rf {pattern}".fmt)
