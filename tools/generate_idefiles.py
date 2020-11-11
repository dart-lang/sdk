#!/usr/bin/python
#
# Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Script to generate configuration files for analysis servers of C++ and Dart.

It generates compile_commands.json for C++ clang and intellij and
analysis_options.yaml for the Dart analyzer.
"""

import argparse
import json
import os
import subprocess
import sys

import generate_buildfiles
import utils

HOST_OS = utils.GuessOS()


def GenerateIdeFiles(options):
    GenerateCompileCommands(options)
    GenerateAnalysisOptions(options)


def GenerateCompileCommands(options):
    """Generate compile_commands.json for the C++ analysis servers.

  compile_commands.json is used by the c++ clang and intellij language analysis
  servers used in IDEs such as Visual Studio Code and Emacs.

  Args:
    options: supported options include: verbose, force, dir

  Returns:
    success (0) or failure (non zero)
  """

    fname = os.path.join(options.dir, "compile_commands.json")

    if os.path.isfile(fname) and not options.force:
        print fname + " already exists, use --force to override"
        return

    gn_result = generate_buildfiles.RunGn(options)
    if gn_result != 0:
        return gn_result

    out_folder = utils.GetBuildRoot(HOST_OS,
                                    mode="debug",
                                    arch=options.arch,
                                    target_os=options.os)

    if not os.path.isdir(out_folder):
        return 1

    command_set = json.loads(
        subprocess.check_output(
            ["ninja", "-C", out_folder, "-t", "compdb", "cxx", "cc", "h"]))

    commands = []
    for obj in command_set:
        command = obj["command"]

        # Skip precompiled mode, a lot of code is commented out in precompiled mode
        if "-DDART_PRECOMPILED_RUNTIME" in command:
            continue

        # Remove warnings
        command = command.replace("-Werror", "")

        obj["command"] = command
        commands += [obj]

    with open(fname, "w") as f:
        json.dump(commands, f, indent=4)

    return 0


def GenerateAnalysisOptions(options):
    """Generate analysis_optioms.yaml for the Dart analyzer.

  To prevent dartanalyzer from tripping on the non-Dart files when it is
  started from the root dart-sdk directory.
  https://github.com/dart-lang/sdk/issues/35562

  Args:
    options: supported options include: force, dir
  """
    contents = """analyzer:
  exclude:
    - benchmarks/**
    - benchmarks-internal/**
    - docs/newsletter/20171103/**
    - pkg/**
    - out/**
    - runtime/**
    - samples-dev/swarm/**
    - sdk/lib/**
    - tests/co19/**
    - tests/co19_2/**
    - tests/corelib/**
    - tests/corelib_2/**
    - tests/dart2js/**
    - tests/dart2js_2/**
    - tests/dartdevc/**
    - tests/dartdevc_2/**
    - tests/ffi/**
    - tests/ffi_2/**
    - tests/language/**
    - tests/language_2/**
    - tests/lib/**
    - tests/lib_2/**
    - tests/modular/**
    - tests/standalone/**
    - tests/standalone_2/**
    - third_party/observatory_pub_packages/**
    - third_party/pkg/**
    - third_party/pkg_tested/dart_style/**
    - third_party/tcmalloc/**
    - tools/apps/update_homebrew/**
    - tools/dart2js/**
    - tools/dom/**
    - tools/sdks/dart-sdk/lib/**
    - tools/status_clean.dart
    - xcodebuild/**"""

    fname = os.path.join(options.dir, "analysis_options.yaml")

    if os.path.isfile(fname) and not options.force:
        print fname + " already exists, use --force to override"
        return

    with open(fname, "w") as f:
        f.write(contents)


def main(argv):
    parser = argparse.ArgumentParser(
        description="Python script to generate compile_commands.json and "
        "analysis_options.yaml which are used by the analysis servers for "
        "c++ and Dart.")

    parser.add_argument("-v",
                        "--verbose",
                        help="Verbose output.",
                        action="store_true")

    parser.add_argument("-f",
                        "--force",
                        help="Override files.",
                        action="store_true")

    parser.add_argument("-d",
                        "--dir",
                        help="Target directory.",
                        default=utils.DART_DIR)

    parser.add_argument("-a",
                        "--arch",
                        help="Target architecture for runtime sources.",
                        default="x64")

    parser.add_argument("-s",
                        "--os",
                        help="Target operating system for runtime sources.",
                        default=HOST_OS)

    options = parser.parse_args(argv[1:])

    return GenerateIdeFiles(options)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
