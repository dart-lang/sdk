#!/usr/bin/env python3
#
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# Copies a binary and signs with using the specified signing identity.

import optparse
import subprocess

parser = optparse.OptionParser()
parser.add_option("--identity", type="string", help="Code signing identity")
parser.add_option("--input", type="string")
parser.add_option("--output", type="string")
options = parser.parse_args()[0]

if not options.identity:
    raise Exception("Missing code signing identity (--identity)")

if not options.input:
    raise Exception("Missing binaries to sign (--input)")

if not options.output:
    raise Exception("Missing binaries to sign (--input)")

# Not cp. Compare tool("copy") in mac_toolchain.gni.
cmd = ["ln", "-f", options.input, options.output]
result = subprocess.run(cmd, capture_output=True, encoding="utf8")
if result.returncode != 0:
    print("failed to run: " + " ".join(cmd))
    print(f"exit code: {result.returncode}")
    print("stdout:")
    print(result.stdout)
    print("stdout:")
    print(result.stderr)
    raise Exception("failed to copy")

codesign_args = [
    "--deep", "--force", "--verify", "--verbose", "--timestamp", "--options",
    "runtime", "--sign", options.identity
]
cmd = ["codesign"] + codesign_args + [options.output]
result = subprocess.run(cmd, capture_output=True, encoding="utf8")
if result.returncode != 0:
    print("failed to run: " + " ".join(cmd))
    print(f"exit code: {result.returncode}")
    print("stdout:")
    print(result.stdout)
    print("stdout:")
    print(result.stderr)
    raise Exception("failed to codesign")
