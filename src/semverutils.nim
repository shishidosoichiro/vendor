import options
import semver

proc parseVersionOrNot(x: string): Option[Version] =
  try:
    return some(v(x))
  except ParseError:
    #echo getCurrentExceptionMsg()
    return none(Version)
  except FieldError:
    #echo getCurrentExceptionMsg()
    return none(Version)

proc cmpSemver*(x, y: string): int =
  let ovx = parseVersionOrNot(x)
  let ovy = parseVersionOrNot(y)
  if ovx.isSome:
    if ovy.isSome:
      let vx = ovx.get
      let vy = ovy.get
      if vx < vy:
        return -1
      elif vx > vy:
        return 1
      else:
        return 0
    else:
      return 1
  else:
    return cmp(x, y)
