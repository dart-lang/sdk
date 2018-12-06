#!/usr/bin/python
#
# Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import subprocess
import json
import utils

### Python script to generate compile_commands.json and make it more useful.

HOST_OS = utils.GuessOS()

if not HOST_OS in ['linux', 'macos']:
  print ("Generate compile_commands has not been ported to %s yet." % (HOST_OS))
  exit

if HOST_OS == 'linux':
  ninja = 'ninja-linux64'
  out_folder = ' out'
if HOST_OS == 'macos':
  ninja = 'ninja-mac'
  out_folder = ' xcodebuild'

subprocess.call("python tools/generate_buildfiles.py", shell=True)

command_set = json.loads(
  subprocess.check_output(
    ninja + " -C " + out_folder + "/DebugX64 -t compdb cxx cc h", shell=True
  )
)

commands = []
for obj in command_set:
  C = obj["command"]

  # Skip precompiled mode, a lot of code is commented out in precompiled mode
  if ("-DDART_PRECOMPILED_RUNTIME" in C):
    continue

  # Remove warnings
  C = C.replace("-Werror", "")

  obj["command"] = C
  commands += [obj]

json.dump(commands, open("compile_commands.json", "w"), indent=4)
