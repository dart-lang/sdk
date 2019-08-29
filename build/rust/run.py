#!/usr/bin/env python

# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Runs rust tools, overriding the PATH variable so they can locate each other.

import os
import subprocess
import sys
import time

def run(cmd):
    bindir = os.path.dirname(cmd[0]);
    env = os.environ
    if 'PATH' in env:
      env['PATH'] += os.pathsep + bindir
    else:
      env['PATH'] = bindir
    out = ''
    err = ''
    proc = subprocess.Popen(
        cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    while proc.returncode is None:
        time.sleep(1)
        stdout, stderr = proc.communicate()
        out += stdout
        err += stderr
        proc.poll()
    if proc.returncode == 0:
      return 0
    print(out)
    print(err)
    return proc.returncode

if __name__ == '__main__':
    sys.exit(run(sys.argv[1:]))
