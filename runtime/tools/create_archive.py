#!/usr/bin/env python
# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This python script creates a tar archive and a C++ source file which contains
# the tar archive as an array of bytes.

import os
import sys
from os.path import join, splitext
import time
from optparse import OptionParser
from datetime import date
import tarfile
import tempfile
import gzip


def CreateTarArchive(tar_path, client_root, compress, files):
    mode_string = 'w'
    tar = tarfile.open(tar_path, mode=mode_string)
    for input_file_name in files:
        # Chop off client_root.
        archive_file_name = input_file_name[len(client_root):]
        # Replace back slash with forward slash. So we do not have Windows paths.
        archive_file_name = archive_file_name.replace("\\", "/")
        # Open input file and add it to the archive.
        with open(input_file_name, 'rb') as input_file:
            tarInfo = tarfile.TarInfo(name=archive_file_name)
            input_file.seek(0, 2)
            tarInfo.size = input_file.tell()
            tarInfo.mtime = 0  # For deterministic builds.
            input_file.seek(0)
            tar.addfile(tarInfo, fileobj=input_file)
    tar.close()
    if compress:
        with open(tar_path, "rb") as fin:
            uncompressed = fin.read()
        with open(tar_path, "wb") as fout:
            # mtime=0 for deterministic builds.
            gz = gzip.GzipFile(fileobj=fout, mode="wb", filename="", mtime=0)
            gz.write(uncompressed)
            gz.close()


def MakeArchive(options):
    if not options.client_root:
        sys.stderr.write('--client_root not specified')
        return -1

    files = []
    for dirname, dirnames, filenames in os.walk(options.client_root):
        # strip out all dot files.
        filenames = [f for f in filenames if not f[0] == '.']
        dirnames[:] = [d for d in dirnames if not d[0] == '.']
        for f in filenames:
            src_path = os.path.join(dirname, f)
            if (os.path.isdir(src_path)):
                continue
            files.append(src_path)

    # Ensure consistent file ordering for reproducible builds.
    files.sort()

    # Write out archive.
    CreateTarArchive(options.tar_output, options.client_root, options.compress,
                     files)
    return 0


def WriteCCFile(
        output_file,
        outer_namespace,
        inner_namespace,
        name,
        tar_archive,
):
    with open(output_file, 'w') as out:
        out.write('''
// Copyright (c) %d, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

''' % date.today().year)
        out.write('''

#include <stdint.h>

''')
        out.write('namespace %s {\n' % outer_namespace)
        if inner_namespace != None:
            out.write('namespace %s {\n' % inner_namespace)
        out.write('\n\n')
        # Write the byte contents of the archive as a comma separated list of
        # integers, one integer for each byte.
        out.write('static const uint8_t %s_[] = {\n' % name)
        line = '   '
        lineCounter = 0
        for byte in tar_archive:
            line += r" %d," % (byte if isinstance(byte, int) else ord(byte))
            lineCounter += 1
            if lineCounter == 10:
                out.write(line + '\n')
                line = '   '
                lineCounter = 0
        if lineCounter != 0:
            out.write(line + '\n')
        out.write('};\n')
        out.write('\nunsigned int %s_len = %d;\n' % (name, len(tar_archive)))
        out.write('\nconst uint8_t* %s = %s_;\n\n' % (name, name))
        if inner_namespace != None:
            out.write('}  // namespace %s\n' % inner_namespace)
        out.write('} // namespace %s\n' % outer_namespace)


def MakeCCFile(options):
    if not options.output:
        sys.stderr.write('--output not specified\n')
        return -1
    if not options.name:
        sys.stderr.write('--name not specified\n')
        return -1
    if not options.tar_input:
        sys.stderr.write('--tar_input not specified\n')
        return -1

    # Read it back in.
    with open(options.tar_input, 'rb') as tar_file:
        tar_archive = tar_file.read()

    # Write CC file.
    WriteCCFile(options.output, options.outer_namespace,
                options.inner_namespace, options.name, tar_archive)
    return 0


def Main(args):
    try:
        # Parse input.
        parser = OptionParser()
        parser.add_option(
            "--output", action="store", type="string", help="output file name")
        parser.add_option("--tar_input",\
                          action="store", type="string",
                          help="input tar archive")
        parser.add_option(
            "--tar_output",
            action="store",
            type="string",
            help="tar output file name")
        parser.add_option(
            "--outer_namespace",
            action="store",
            type="string",
            help="outer C++ namespace",
            default="dart")
        parser.add_option(
            "--inner_namespace",
            action="store",
            type="string",
            help="inner C++ namespace",
            default="bin")
        parser.add_option(
            "--name",
            action="store",
            type="string",
            help="name of tar archive symbol")
        parser.add_option("--compress", action="store_true", default=False)
        parser.add_option(
            "--client_root",
            action="store",
            type="string",
            help="root directory client resources")

        (options, args) = parser.parse_args()

        if options.tar_output:
            return MakeArchive(options)
        else:
            return MakeCCFile(options)

    except Exception as inst:
        sys.stderr.write('create_archive.py exception\n')
        sys.stderr.write(str(inst))
        sys.stderr.write('\n')
        return -1


if __name__ == '__main__':
    sys.exit(Main(sys.argv))
