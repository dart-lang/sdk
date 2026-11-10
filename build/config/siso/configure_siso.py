#!/usr/bin/env python3
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""This script is used to configure siso."""

import argparse
import os
import sys

THIS_DIR = os.path.abspath(os.path.dirname(__file__))

SISO_PROJECT_CFG = "SISO_PROJECT"
SISO_ENV = os.path.join(THIS_DIR, ".sisoenv")


def ReadConfig():
    entries = {}
    if not os.path.isfile(SISO_ENV):
        print("The .sisoenv file has not been generated yet")
        return entries
    with open(SISO_ENV, "r") as f:
        for line in f:
            parts = line.strip().split("=")
            if len(parts) > 1:
                entries[parts[0].strip()] = parts[1].strip()
        return entries


def main():
    parser = argparse.ArgumentParser(description="configure siso")
    parser.add_argument(
        "--rbe_instance",
        help="RBE instance to use for Siso. "
        "Ignored if --reapi_address is set for non-RBE address.",
    )
    parser.add_argument("--reapi_instance",
                        default="",
                        help="REAPI instance to use for Siso.")
    parser.add_argument(
        "--reapi_address",
        help="REAPI address to use for Siso. "
        "If set for non-RBE address, rbe_instance is ignored.",
    )
    parser.add_argument(
        "--credential-helper",
        help="The credential helper to use for authenticating. "
        "May be a binary on the PATH or an absolute path.",
    )
    parser.add_argument(
        "--get-siso-project",
        help="Print the currently configured siso project to stdout",
        action="store_true",
    )
    args = parser.parse_args()

    if args.get_siso_project:
        config = ReadConfig()
        if SISO_PROJECT_CFG not in config:
            return 1
        print(config[SISO_PROJECT_CFG])
        return 0

    project = None
    reapi_instance = args.reapi_instance
    reapi_address = args.reapi_address
    if (not reapi_address or
            reapi_address.endswith("remotebuildexecution.googleapis.com:443")
       ) and args.rbe_instance:
        elems = args.rbe_instance.split("/")
        if len(elems) == 4 and elems[0] == "projects":
            project = elems[1]
            reapi_instance = elems[-1]

    with open(SISO_ENV, "w") as f:
        if project:
            f.write("%s=%s\n" % (SISO_PROJECT_CFG, project))
        f.write("SISO_REAPI_INSTANCE=%s\n" % reapi_instance)
        if reapi_address:
            f.write("SISO_REAPI_ADDRESS=%s\n" % reapi_address)
        if args.credential_helper:
            f.write("SISO_CREDENTIAL_HELPER=%s\n" % args.credential_helper)

    return 0


if __name__ == "__main__":
    sys.exit(main())
