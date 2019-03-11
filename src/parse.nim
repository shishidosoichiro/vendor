import strutils

proc parse*(appver: string): (string, string) =
  let a = appver.split('@')
  if a.len == 1:
    result = (a[0], "latest")
  else:
    result = (a[0], a[1])
