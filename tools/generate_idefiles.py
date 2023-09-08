#!/usr/bin/env python3
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
import re
import subprocess
import sys

import generate_buildfiles
import utils

HOST_OS = utils.GuessOS()


def GenerateIdeFiles(options):
    GenerateCompileCommands(options)


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
        print(fname + " already exists, use --force to override")
        return

    gn_result = generate_buildfiles.RunGn(options)
    if gn_result != 0:
        return gn_result

    out_folder = utils.GetBuildRoot(HOST_OS,
                                    mode="debug",
                                    arch=options.arch,
                                    target_os=options.os,
                                    sanitizer=options.sanitizer)

    if not os.path.isdir(out_folder):
        return 1

    command_set = json.loads(
        subprocess.check_output([
            "buildtools/ninja/ninja", "-C", out_folder, "-t", "compdb", "-x",
            "cxx", "cc", "h"
        ]))

    commands = []
    for obj in command_set:
        command = obj["command"]

        # Skip precompiled mode, a lot of code is commented out in precompiled mode
        if "-DDART_PRECOMPILED_RUNTIME" in command:
            continue

        # Remove warnings
        command = command.replace("-Werror", "")

        # Remove ninja prepend on Windows.
        # This is not fully correct, as now it fails to find a sysroot for
        # Windows. However, clangd completely fails with the `-t` flag.
        command = re.sub(r"([^\s]*)ninja -t msvc -e environment.x64 --", "",
                         command)

        # Add sysroot from out\DebugX64\environment.x64 on Windows.
        # TODO(dacoharkes): Fetch the paths from that file.
        windowsSysroots = [
            'C:\\src\\depot_tools\\win_toolchain\\vs_files\\1023ce2e82\\Windows Kits\\10\\Include\\10.0.20348.0\\um',
            'C:\\src\\depot_tools\\win_toolchain\\vs_files\\1023ce2e82\\Windows Kits\\10\\Include\\10.0.20348.0\\shared',
            'C:\\src\\depot_tools\\win_toolchain\\vs_files\\1023ce2e82\\Windows Kits\\10\\Include\\10.0.20348.0\\winrt',
            'C:\\src\\depot_tools\\win_toolchain\\vs_files\\1023ce2e82\\Windows Kits\\10\\Include\\10.0.20348.0\\ucrt',
            'C:\\src\\depot_tools\\win_toolchain\\vs_files\\1023ce2e82\\VC\\Tools\\MSVC\\14.29.30133\\include',
            'C:\\src\\depot_tools\\win_toolchain\\vs_files\\1023ce2e82\\VC\\Tools\\MSVC\\14.29.30133\\atlmfc\\include',
        ]
        for windowsSysroot in windowsSysroots:
            command = command.replace(
                "-DDART_TARGET_OS_WINDOWS",
                "-DDART_TARGET_OS_WINDOWS \"-I%s\"" % windowsSysroot)

        # Prevent packing errors from causing fatal_too_many_errors on Windows.
        command = command.replace("-DDART_TARGET_OS_WINDOWS",
                                  "-DDART_TARGET_OS_WINDOWS -ferror-limit=0")

        obj["command"] = command
        commands += [obj]

    with open(fname, "w") as f:
        json.dump(commands, f, indent=4)

    return 0


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

    parser.add_argument('--sanitizer',
                        type=str,
                        help='Build variants (comma-separated).',
                        metavar='[none,asan,lsan,msan,tsan,ubsan]',
                        default='none')

    options = parser.parse_args(argv[1:])

    return GenerateIdeFiles(options)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
