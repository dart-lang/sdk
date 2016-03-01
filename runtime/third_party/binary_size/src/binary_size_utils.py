# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Common utilities for tools that deal with binary size information.
"""

import logging
import re


def ParseNm(nm_lines):
  """Parse nm output, returning data for all relevant (to binary size)
  symbols and ignoring the rest.

  Args:
      nm_lines: an iterable over lines of nm output.

  Yields:
      (symbol name, symbol type, symbol size, source file path).

      Path may be None if nm couldn't figure out the source file.
  """

  # Match lines with size, symbol, optional location, optional discriminator
  sym_re = re.compile(r'^([0-9a-f]{8,}) ' # address (8+ hex digits)
                      '([0-9a-f]{8,}) ' # size (8+ hex digits)
                      '(.) ' # symbol type, one character
                      '([^\t]+)' # symbol name, separated from next by tab
                      '(?:\t(.*):[\d\?]+)?.*$') # location
  # Match lines with addr but no size.
  addr_re = re.compile(r'^[0-9a-f]{8,} (.) ([^\t]+)(?:\t.*)?$')
  # Match lines that don't have an address at all -- typically external symbols.
  noaddr_re = re.compile(r'^ {8,} (.) (.*)$')
  # Match lines with no symbol name, only addr and type
  addr_only_re = re.compile(r'^[0-9a-f]{8,} (.)$')

  seen_lines = set()
  for line in nm_lines:
    line = line.rstrip()
    if line in seen_lines:
      # nm outputs identical lines at times. We don't want to treat
      # those as distinct symbols because that would make no sense.
      continue
    seen_lines.add(line)
    match = sym_re.match(line)
    if match:
      address, size, sym_type, sym = match.groups()[0:4]
      size = int(size, 16)
      if sym_type in ('B', 'b'):
        continue  # skip all BSS for now.
      path = match.group(5)
      yield sym, sym_type, size, path, address
      continue
    match = addr_re.match(line)
    if match:
      # sym_type, sym = match.groups()[0:2]
      continue  # No size == we don't care.
    match = noaddr_re.match(line)
    if match:
      sym_type, sym = match.groups()
      if sym_type in ('U', 'w'):
        continue  # external or weak symbol
    match = addr_only_re.match(line)
    if match:
      continue  # Nothing to do.


    # If we reach this part of the loop, there was something in the
    # line that we didn't expect or recognize.
    logging.warning('nm output parser failed to parse: %s', repr(line))
