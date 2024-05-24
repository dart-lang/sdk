#!/usr/bin/env python3
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Helper script for GN to run `dart compile exe` and produce a depfile.

Run with:
  python3 gn_dart_compile_exe.py             \
    --dart-binary <path to dart binary>      \
    --entry-point <path to dart entry point>       \
    --output <path to resulting executable>  \
    --sdk-hash <SDK hash>                    \
    --packages <path to package config file> \
    --depfile <path to depfile to write>

This is workaround for `dart compile exe` not supporting --depfile option
in the current version of prebuilt SDK. Once we roll in a new version
of checked in SDK we can remove this helper.
"""

import argparse
import os
import sys
import subprocess
from tempfile import TemporaryDirectory


def parse_args(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("--dart-sdk",
                        required=True,
                        help="Path to the prebuilt Dart SDK")
    parser.add_argument("--sdk-hash", required=True, help="SDK hash")
    parser.add_argument("--entry-point",
                        required=True,
                        help="Dart entry point to precompile")
    parser.add_argument("--output",
                        required=True,
                        help="Path to resulting executable   ")
    parser.add_argument("--packages",
                        required=True,
                        help="Path to package config file")
    parser.add_argument("--depfile",
                        required=True,
                        help="Path to depfile to write")
    return parser.parse_args(argv)


# Run a command, swallowing the output unless there is an error.
def run_command(command):
    try:
        subprocess.check_output(command, stderr=subprocess.STDOUT)
        return True
    except subprocess.CalledProcessError as e:
        print("Command failed: " + " ".join(command) + "\n" + "output: " +
              _decode(e.output))
        return False
    except OSError as e:
        print("Command failed: " + " ".join(command) + "\n" + "output: " +
              _decode(e.strerror))
        return False


def _decode(bytes):
    return bytes.decode("utf-8")


def main(argv):
    args = parse_args(argv[1:])

    # Unless the path is absolute, this script is designed to run binaries
    # produced by the current build, which is the current working directory when
    # this script is run.
    prebuilt_sdk = os.path.abspath(args.dart_sdk)

    dart_binary = os.path.join(prebuilt_sdk, "bin", "dart")
    if not os.path.isfile(dart_binary):
        print("Binary not found: " + dart_binary)
        return 1

    dartaotruntime_binary = os.path.join(prebuilt_sdk, "bin", "dartaotruntime")
    if not os.path.isfile(dartaotruntime_binary):
        print("Binary not found: " + dartaotruntime_binary)
        return 1

    gen_kernel_snapshot = os.path.join(prebuilt_sdk, "bin", "snapshots",
                                       "gen_kernel_aot.dart.snapshot")
    if not os.path.isfile(gen_kernel_snapshot):
        print("Binary not found: " + gen_kernel_snapshot)
        return 1

    platform_dill = os.path.join(prebuilt_sdk, "lib", "_internal",
                                 "vm_platform_strong.dill")
    if not os.path.isfile(platform_dill):
        print("Binary not found: " + platform_dill)
        return 1

    # Compile the executable.
    ok = run_command([
        dart_binary,
        "compile",
        "exe",
        "--packages",
        args.packages,
        f"-Dsdk_hash={args.sdk_hash}",
        "-o",
        args.output,
        args.entry_point,
    ])
    if not ok:
        return 1

    # Collect dependencies by using gen_kernel.
    with TemporaryDirectory() as tmpdir:
        output_dill = os.path.join(tmpdir, "output.dill")
        ok = run_command([
            dartaotruntime_binary,
            gen_kernel_snapshot,
            "--platform",
            platform_dill,
            "--packages",
            args.packages,
            "--depfile",
            args.depfile,
            "-o",
            output_dill,
            args.entry_point,
        ])
        if not ok:
            return 1

        # Fix generated depfile to refer to the output file name instead
        # of referring to the temporary dill file we have generated.
        with open(args.depfile, "r") as f:
            content = f.read()
        (target_name, deps) = content.split(": ", 1)
        if target_name != output_dill:
            print(
                "ERROR: Something is wrong with generated depfile: expected {output_dill} as target, but got {target_name}"
            )
            return 1
        with open(args.depfile, "w") as f:
            f.write(args.output)
            f.write(": ")
            f.write(deps)

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
