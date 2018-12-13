#!/usr/bin/python
#
# Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import argparse
import generate_buildfiles
import json
import subprocess
import sys
import utils
import os

# Python script to generate compile_commands.json which is used by the clang
# and intellij language analysis servers used in IDEs such as Visual Studio
# Code and Emacs.

HOST_OS = utils.GuessOS()


def GenerateCompileCommands(options):
  gn_result = generate_buildfiles.RunGn(options)
  if (gn_result != 0):
    return gn_result

  out_folder = utils.GetBuildRoot(HOST_OS, mode="debug", arch="x64")

  if (not os.path.isdir(out_folder)):
    return 1

  command_set = json.loads(
      subprocess.check_output(
          ["ninja", "-C", out_folder, "-t", "compdb", "cxx", "cc", "h"]
      )
  )

  commands = []
  for obj in command_set:
    command = obj["command"]

    # Skip precompiled mode, a lot of code is commented out in precompiled mode
    if ("-DDART_PRECOMPILED_RUNTIME" in command):
      continue

    # Remove warnings
    command = command.replace("-Werror", "")

    obj["command"] = command
    commands += [obj]

  json.dump(commands, open("compile_commands.json", "w"), indent=4)

  return 0


def ParseArgs(args):
  args = args[1:]
  parser = argparse.ArgumentParser(
      description="A script to generate compile_commands.json which is used by"
      + "the clang and intellij language analysis servers used in IDEs such as"
      + "Visual Studio Code and Emacs")

  parser.add_argument("-v", "--verbose",
                      help='Verbose output.',
                      default=False,
                      action="store_true")

  return parser.parse_args(args)


def main(argv):
  options = ParseArgs(argv)
  return GenerateCompileCommands(options)


if __name__ == '__main__':
  sys.exit(main(sys.argv))
