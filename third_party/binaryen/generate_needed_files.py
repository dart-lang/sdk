#!/usr/bin/env python3
# Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import re
import subprocess
import sys


def main(args):
    # Build Wasm WasmIntrinsics.cpp.
    wasm_intrinsics_wat = args[0]
    wasm_intrinsics_cpp_in = args[1]
    wasm_intrinsics_cpp_out = args[2]
    with open(wasm_intrinsics_wat, 'rb') as fd:
        wat = fd.read()
    wat_hex = ','.join([hex(byte) for byte in wat])
    with open(wasm_intrinsics_cpp_in) as fd:
        template = fd.read()
    template = template.replace('@WASM_INTRINSICS_SIZE@', '%s' % len(wat))
    template = template.replace('@WASM_INTRINSICS_EMBED@', wat_hex)
    with open(wasm_intrinsics_cpp_out, 'w') as fd:
        fd.write(template)

    # Build config.h
    cmake_in = args[3]
    config_h_in = args[4]
    config_out = args[5]
    with open(cmake_in) as fd:
        cmake = fd.read()
    with open(config_h_in) as fd:
        template = fd.read()
    match = re.search(
        r'project\(binaryen LANGUAGES C CXX VERSION (?P<version>[0-9]+)\)',
        cmake)
    version = match['version']
    git_args = ['git', 'rev-parse', 'HEAD']
    try:
        output = subprocess.check_output(git_args,
                                         cwd=os.path.dirname(cmake_in),
                                         text=True)
        version = '%s (%s)' % (version, output.strip())
    except:
        pass
    template = template.replace('#cmakedefine', '#define')
    template = template.replace('${PROJECT_VERSION}', version)
    with open(config_out, 'w') as fd:
        fd.write(template)


if __name__ == '__main__':
    main(sys.argv[1:])
