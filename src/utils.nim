import os
import strformat

proc bin*(home: string): string =
  home / "bin"

proc env*(managerDir, bin: string): string =
  fmt"""

# {extractFilename(managerDir)}
if echo "$PATH" | grep -q "{managerDir}"; then
  PATH=$(echo "$PATH" | sed -e "s|{managerDir}[^:]*:||g");
fi;
export PATH="{bin}:$PATH";

"""
