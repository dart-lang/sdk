#!/usr/bin/env python
#
# Copyright 2012 Google Inc. All Rights Reserved.

import subprocess
import sys

def FetchSVNRevision():
  try:
    proc = subprocess.Popen(['svn', 'info'],
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            cwd='src/dart',
                            shell=(sys.platform=='win32'))
  except OSError:
    # command is apparently either not installed or not executable.
    return None
  if not proc:
    return None

  for line in proc.stdout:
    line = line.strip()
    if not line:
      continue
    key, val = line.split(': ', 1)
    if key == 'Revision':
      return val

  return None


def main():
  revision = FetchSVNRevision()
  path = 'src/chrome/VERSION'
  text = file(path).readlines()
  text[2] = 'BUILD=d%s\n' % revision
  file(path, 'w').writelines(text)

if __name__ == '__main__':
  main()
