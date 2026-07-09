#!/usr/bin/env python3
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import argparse
import gn_helpers
import os
import re
import shutil
import sys


def ParseArgs(args):
    args = args[1:]
    parser = argparse.ArgumentParser(
        description='A script to copy a file tree somewhere')

    parser.add_argument('--depfile',
                        '-d',
                        type=str,
                        help='Path to a depfile to write when copying.')
    parser.add_argument(
        '--exclude_patterns',
        '-e',
        type=str,
        help='Patterns to exclude [passed to shutil.copytree]')
    parser.add_argument(
        '--from', '-f', dest="copy_from", type=str, help='Source directory')
    parser.add_argument(
        '--stamp',
        '-s',
        type=str,
        help='The path to a stamp file to output when finished.')
    parser.add_argument('--to', '-t', type=str, help='Destination directory')

    return parser.parse_args(args)


def ValidateArgs(args):
    if not args.copy_from or not os.path.isdir(args.copy_from):
        print("--from argument must refer to a directory")
        return False
    if not args.to:
        print("--to is required")
        return False
    return True


# Returns a list of the files under 'src' that were copied.
def CopyTree(src, dst, ignore=None):
    copied_files = []

    # Recursive helper method to collect errors but keep processing.
    def copy_tree(src, dst, ignore, errors):
        names = os.listdir(src)
        if ignore is not None:
            ignored_names = ignore(src, names)
        else:
            ignored_names = set()

        if not os.path.exists(dst):
            os.makedirs(dst)
        for name in names:
            if name in ignored_names:
                continue
            srcname = os.path.join(src, name)
            dstname = os.path.join(dst, name)
            try:
                if os.path.isdir(srcname):
                    copy_tree(srcname, dstname, ignore, errors)
                else:
                    copied_files.append(srcname)
                    shutil.copy(srcname, dstname)
            except (IOError, os.error) as why:
                errors.append((srcname, dstname, str(why)))
        try:
            shutil.copystat(src, dst)
        except WindowsError:
            # Can't copy file access times on Windows.
            pass
        except OSError as why:
            errors.append((src, dst, str(why)))

    # Format errors from file copies.
    def format_error(error):
        if len(error) == 1:
            return "Error: {msg}".format(msg=str(error[0]))
        return "From: {src}\nTo:   {dst}\n{msg}" \
                .format(src=error[0], dst=error[1], msg=error[2])

    errors = []
    copy_tree(src, dst, ignore, errors)
    if errors:
        failures = "\n\n".join(format_error(error) for error in errors)
        parts = ("Some file copies failed:", "=" * 78, failures)
        msg = '\n'.join(parts)
        raise RuntimeError(msg)

    return copied_files


def WriteDepfile(depfile, stamp, dep_list):
    os.makedirs(os.path.dirname(depfile), exist_ok=True)
    # Paths in the depfile must be relative to the root build output directory,
    # which is the cwd that ninja invokes the script from.
    cwd = os.getcwd()
    relstamp = os.path.relpath(stamp, cwd)
    reldep_list = [os.path.relpath(d, cwd) for d in dep_list]
    # Depfile paths must use an escape sequence for space characters.
    reldep_list = [path.replace(" ", r"\ ") for path in reldep_list]
    with open(depfile, 'w') as f:
        print("{0}: {1}".format(relstamp, " ".join(reldep_list)), file=f)


def Main(argv):
    args = ParseArgs(argv)
    if not ValidateArgs(args):
        return -1

    if args.exclude_patterns == None:
        copied_files = CopyTree(args.copy_from, args.to)
    else:
        patterns = args.exclude_patterns.split(',')
        copied_files = CopyTree(args.copy_from,
                                args.to,
                                ignore=shutil.ignore_patterns(*patterns))

    if args.depfile and args.stamp:
        WriteDepfile(args.depfile, args.stamp, copied_files)

    if args.stamp:
        open(args.stamp, 'w').close()

    return 0


if __name__ == '__main__':
    sys.exit(Main(sys.argv))
