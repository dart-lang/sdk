#!/usr/bin/env python
#
# Copyright 2012 Google Inc. All Rights Reserved.

import overrides_database
import shutil
import subprocess
import sys


def svn_update(path, rev):
  subprocess.call(['svn', 'up', '-r', str(rev), path])


def update_overridden_files(old_rev, new_rev):
  assert old_rev < new_rev
  for override in overrides_database.OVERRIDDEN_FILES:
    patched = override['modified']
    orig = override['original']
    svn_update(orig, old_rev)
    shutil.copyfile(patched, orig)
    svn_update(orig, new_rev)
    shutil.copyfile(orig, patched)


if __name__ == '__main__':
  update_overridden_files(int(sys.argv[1]), int(sys.argv[2]))
