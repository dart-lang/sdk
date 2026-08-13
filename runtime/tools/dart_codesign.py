#!/usr/bin/env python3
#
# Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# Sign given binaries with using the specified signing identity and
# using entitlements from runtime/tools/entitlement/${binary_name}.plist
# if any.
#

import optparse
import os
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))


def SignBinary(identity, binary):
    codesign_args = [
        "--deep", "--force", "--verify", "--verbose", "--timestamp",
        "--options", "runtime", "--sign", identity
    ]

    name = os.path.basename(binary)

    # Check if we have a matching entitlements file and apply it.
    # It would be simpler if we could specify it from outside but
    # GN does not give us tools for doing that: executable target can't
    # push arbitrary configuration down to the link tool where
    # we would like to perform code signing.
    entitlements_file = os.path.join(SCRIPT_DIR, "entitlements",
                                     name + ".plist")
    if os.path.exists(entitlements_file):
        codesign_args += ["--entitlements", entitlements_file]
    cmd = ["codesign"] + codesign_args + [binary]
    result = subprocess.run(cmd, capture_output=True, encoding="utf8")
    if result.returncode != 0:
        print("failed to run: " + " ".join(cmd))
        print(f"exit code: {result.returncode}")
        print("stdout:")
        print(result.stdout)
        print("stdout:")
        print(result.stderr)
        raise Exception("failed to codesign")


parser = optparse.OptionParser()
parser.add_option("--identity", type="string", help="Code signing identity")
parser.add_option("--binary",
                  type="string",
                  action="append",
                  help="Binary to sign")
options = parser.parse_args()[0]

if not options.identity:
    raise Exception("Missing code signing identity (--identity)")

if not options.binary:
    raise Exception("Missing binaries to sign (--binary)")

for binary in options.binary:
    SignBinary(options.identity, binary)
