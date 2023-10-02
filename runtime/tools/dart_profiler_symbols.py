#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# On Fuchsia, in lieu of the ELF dynamic symbol table consumed through dladdr,
# the Dart VM profiler consumes symbols produced by this tool, which have the
# format
#
# struct {
#    uint32_t num_entries;
#    struct {
#      uint32_t offset;
#      uint32_t size;
#      uint32_t string_table_offset;
#    } entries[num_entries];
#    const char* string_table;
# }
#
# Entries are sorted by offset. String table entries are NUL-terminated.
#
# See also //third_party/dart/runtime/vm/native_symbol_fuchsia.cc

import optparse
import os
import re
import utils
import subprocess
import struct


class Symbol:

    def __init__(self, offset, size, name):
        self.offset = offset
        self.size = size
        self.name = name


parser = optparse.OptionParser()
parser.add_option("--nm", type="string", help="Path to `nm` tool")
parser.add_option("--binary", type="string")
parser.add_option("--output", type="string")
options = parser.parse_args()[0]
nm = options.nm
if not nm:
    raise Exception('--nm not specified')
binary = options.binary
if not binary:
    raise Exception('--binary not specified')
output = options.output
if not output:
    raise Exception('--output not specified')

p = subprocess.Popen(
    [nm, "--demangle", "--numeric-sort", "--print-size", binary],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT)
nm_output, _ = p.communicate()
nm_lines = nm_output.decode('utf-8').split('\n')
regex = re.compile("([0-9A-Za-z]+) ([0-9A-Za-z]+) (t|T|w|W) (.*)")
symbols = []
for line in nm_lines:
    m = regex.match(line)
    if not m:
        continue
    offset = int(m.group(1), 16)
    if offset > 0x100000000:
        # Mac adds an extra 4GB for some reason
        offset -= 0x100000000
    size = int(m.group(2), 16)
    name = m.group(4).split("(")[0]
    if name == "__mh_execute_header":
        # Skip very out-of-range thing.
        continue
    symbols.append(Symbol(offset, size, name.encode('utf-8')))

if len(symbols) == 0:
    raise Exception(binary + " has no symbols")

stream = open(output, "wb")
stream.write(struct.pack("I", len(symbols)))
nameOffset = 0
for symbol in symbols:
    stream.write(struct.pack("I", symbol.offset))
    stream.write(struct.pack("I", symbol.size))
    stream.write(struct.pack("I", nameOffset))
    nameOffset += len(symbol.name)
    nameOffset += 1
for symbol in symbols:
    stream.write(symbol.name)
    stream.write(b"\0")
stream.close()
