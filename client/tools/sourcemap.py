# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Utilities to extract source map information

A set of utilities to extract source map information. This python library
consumes source map files v3, but doesn't provide any funcitonality to produce
source maps. This code is an adaptation of the Java implementation originally
written for the closure compiler by John Lenz (johnlenz@google.com)
"""

import bisect
import json
import sys

class SourceMap():
  """ An in memory representation of a source map. """

  def get_source_location(self, line, column):
    """ Fetches the original location for a line and column.

        Args:
          line: line in the output file to query
          column: column in the output file to query

        Returns:
          A tuple of the form:
            file, src_line, src_column, opt_identifier
          When available, opt_identifier contains the name of an identifier
          associated with the given program location.
    """
    pass # implemented by subclasses

def parse(sourcemap_file):
  """ Parse a file containing source map information as a json string and return
      a source map object representing it.
      Args:
        sourcemap_file: path to a file (optionally containing a 'file:' prefix)
                        which can either contain a meta-level source map or an
                        actual source map.
  """
  if sourcemap_file.startswith('file:'):
    sourcemap_file = sourcemap_file[5:]

  with open(sourcemap_file, 'r') as f:
    sourcemap_json = json.load(f)

  return _parseFromJson(sourcemap_json)


def _parseFromJson(sourcemap_json):
  if sourcemap_json['version'] != 3:
    raise SourceMapException("unexpected source map version")

  if not 'file' in sourcemap_json:
    raise SourceMapException("unexpected, no file in source map file")

  if 'sections' in sourcemap_json:
    sections = sourcemap_json['sections']
    # a meta file
    if ('mappings' in sourcemap_json
        or 'sources' in sourcemap_json
        or 'names' in sourcemap_json):
      raise SourceMapException("Invalid map format")
    return _MetaSourceMap(sections)

  return _SourceMapFile(sourcemap_json)

class _MetaSourceMap(SourceMap):
  """ A higher-order source map containing nested source maps. """

  def __init__(self, sections):
    """ creates a source map instance given its json input (already parsed). """
    # parse a regular sourcemap file
    self.offsets = []
    self.maps = []

    for section in sections:
      line = section['offset']['line']
      if section['offset']['column'] != 0:
        # TODO(sigmund): implement if needed
        raise Exception("unimplemented")

      if 'url' in section and 'map' in section:
        raise SourceMapException(
            "Invalid format: section may not contain both 'url' and 'map'")

      self.offsets.append(line)
      if 'url' in section:
        self.maps.append(parse(section['url']))
      elif 'map' in section:
        self.maps.append(_parseFromJson(section['map']))
      else:
        raise SourceMapException(
            "Invalid format: section must contain either 'url' or 'map'")

  def get_source_location(self, line, column):
    """ Fetches the original location from the target location. """
    index = bisect.bisect(self.offsets, line) - 1
    return self.maps[index].get_source_location(
        line - self.offsets[index], column)

class _SourceMapFile(SourceMap):
  def __init__(self, sourcemap):
    """ creates a source map instance given its json input (already parsed). """
    # parse a regular sourcemap file
    self.sourcemap_file = sourcemap['file']
    self.sources = sourcemap['sources']
    self.names = sourcemap['names']
    self.lines = []
    self._build(sourcemap['mappings'])

  def get_source_location(self, line, column):
    """ Fetches the original location from the target location. """

    # Normalize the line and column numbers to 0.
    line -= 1
    column -= 1

    if line < 0 or line >= len(self.lines):
      return None

    entries = self.lines[line]
    # If the line is empty return the previous mapping.
    if not entries or entries == [] or entries[0].gen_column > column:
      return self._previousMapping(line)

    index = bisect.bisect(entries, _Entry(column)) - 1
    return self._originalEntryMapping(entries[index])

  def _previousMapping(self, line):
    while True:
      if line == 0:
        return None
      line -= 1
      if self.lines[line]:
        return self._originalEntryMapping(self.lines[line][-1])

  def _originalEntryMapping(self, entry):
    if entry.src_file_id is None:
      return None

    if entry.name_id:
      identifier = self.names[entry.name_id]
    else:
      identifier = None

    filename = self.sources[entry.src_file_id]
    return filename, entry.src_line, entry.src_column, identifier

  def _build(self, linemap):
    """ builds this source map from the sourcemap json """
    entries = []
    line = 0
    prev_col = 0
    prev_src_id = 0
    prev_src_line = 0
    prev_src_column = 0
    prev_name_id = 0
    content = _StringCharIterator(linemap)
    while content.hasNext():
      # ';' denotes a new line.
      token = content.peek()
      if token == ';':
        content.next()
        # The line is complete, store the result for the line, None if empty.
        result = entries if len(entries) > 0 else None
        self.lines.append(result)
        entries = []
        line += 1
        prev_col = 0
      else:
        # Grab the next entry for the current line.
        values = []
        while (content.hasNext()
               and content.peek() != ',' and content.peek() != ';'):
          values.append(_Base64VLQDecode(content))

        # Decodes the next entry, using the previous encountered values to
        # decode the relative values.
        #
        # The values, if present are in the following order:
        #   0: the starting column in the current line of the generated file
        #   1: the id of the original source file
        #   2: the starting line in the original source
        #   3: the starting column in the original source
        #   4: the id of the original symbol name
        # The values are relative to the previous encountered values.

        total = len(values)
        if not(total == 1 or total == 4 or total == 5):
          raise SourceMapException(
              "Invalid entry in source map file: %s\nline: %d\nvalues: %s\n"
              % (self.sourcemap_file, line, str(values)))
        prev_col += values[0]
        if total == 1:
          entry = _Entry(prev_col)
        else:
          prev_src_id += values[1]
          if prev_src_id >= len(self.sources):
            raise SourceMapException(
                "Invalid source id\nfile: %s\nline: %d\nid: %d\n"
                % (self.sourcemap_file, line, prev_src_id))
          prev_src_line += values[2]
          prev_src_column += values[3]
          if total == 4:
            entry = _Entry(
                prev_col, prev_src_id, prev_src_line, prev_src_column)
          elif total == 5:
            prev_name_id += values[4]
            if prev_name_id >= len(self.names):
              raise SourceMapException(
                  "Invalid name id\nfile: %s\nline: %d\nid: %d\n"
                  % (self.sourcemap_file, line, prev_name_id))
            entry = _Entry(
                prev_col, prev_src_id, prev_src_line, prev_src_column,
                prev_name_id)
        entries.append(entry);
        if content.peek() == ',':
          content.next()

class _StringCharIterator():
  """ An iterator over a string that allows you to peek into the next value. """
  def __init__(self, string):
     self.string = string
     self.length = len(string)
     self.current = 0

  def __iter__(self):
    return self

  def next(self):
    res = self.string[self.current]
    self.current += 1
    return res

  def peek(self):
    return self.string[self.current]

  def hasNext(self):
    return self.current < self.length


# Base64VLQ decoding

VLQ_BASE_SHIFT = 5
VLQ_BASE = 1 << VLQ_BASE_SHIFT
VLQ_BASE_MASK = VLQ_BASE - 1
VLQ_CONTINUATION_BIT = VLQ_BASE
BASE64_MAP = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
BASE64_DECODE_MAP = dict()
for c in range(64):
  BASE64_DECODE_MAP[BASE64_MAP[c]] = c

def _Base64VLQDecode(iterator):
  """
   Decodes the next VLQValue from the provided char iterator.

   Sourcemaps are encoded with variable length numbers as base64 encoded strings
   with the least significant digit coming first.  Each base64 digit encodes a
   5-bit value (0-31) and a continuation bit.  Signed values can be represented
   by using the least significant bit of the value as the
   sign bit.

   This function only contains the decoding logic, since the encoding logic is
   only needed to produce source maps.

   Args:
     iterator: a _StringCharIterator
  """
  result = 0
  stop = False
  shift = 0
  while not stop:
    c = iterator.next()
    if c not in BASE64_DECODE_MAP:
      raise Exception("%s not a valid char" % c)
    digit = BASE64_DECODE_MAP[c]
    stop = digit & VLQ_CONTINUATION_BIT == 0
    digit &= VLQ_BASE_MASK
    result += (digit << shift)
    shift += VLQ_BASE_SHIFT

  # Result uses the least significant bit as a sign bit. We convert it into a
  # two-complement value. For example,
  #   2 (10 binary) becomes 1
  #   3 (11 binary) becomes -1
  #   4 (100 binary) becomes 2
  #   5 (101 binary) becomes -2
  #   6 (110 binary) becomes 3
  #   7 (111 binary) becomes -3
  negate = (result & 1) == 1
  result = result >> 1
  return -result if negate else result


ERROR_DETAILS ="""
         - gen_column = %s
         - src_file_id = %s
         - src_line = %s
         - src_column = %s
         - name_id = %s
"""

class _Entry():
  """ An entry in a source map file. """
  def __init__(self, gen_column,
               src_file_id=None,
               src_line=None,
               src_column=None,
               name_id=None):
    """ Creates an entry. Many arguments are marked as optional, but we expect
        either all being None, or only name_id being none.
    """

    # gen column must be defined:
    if gen_column is None:
      raise SourceMapException(
          "Invalid entry, no gen_column specified:" +
          ERROR_DETAILS % (
              gen_column, src_file_id, src_line, src_column, name_id))

    # if any field other than gen_column is defined, then file_id, line, and
    # column must be defined:
    if ((src_file_id is not None or src_line is not None or
         src_column is not None or name_id is not None) and
        (src_file_id is None or src_line is None or src_column is None)):
      raise SourceMapException(
          "Invalid entry, only name_id is optional:" +
          ERROR_DETAILS % (
              gen_column, src_file_id, src_line, src_column, name_id))

    self.gen_column = gen_column
    self.src_file_id = src_file_id
    self.src_line = src_line
    self.src_column = src_column
    self.name_id = name_id

  # define comparison to perform binary search on lookups
  def __cmp__(self, other):
    return cmp(self.gen_column, other.gen_column)

class SourceMapException(Exception):
  """ An exception encountered while parsing or processing source map files."""
  pass

def main():
  """ This module is intended to be used as a library. Main is provided to
      test the functionality on the command line.
  """
  if len(sys.argv) < 3:
    print ("Usage: %s <mapfile> line [column]" % sys.argv[0])
    return 1

  sourcemap = parse(sys.argv[1])
  line = int(sys.argv[2])
  column = int(sys.argv[3]) if len(sys.argv) > 3 else 1
  original = sourcemap.get_source_location(line, column)
  if not original:
    print "Source location not found"
  else:
    filename, srcline, srccolumn, srcid = original
    print "Source location is: %s, line: %d, column: %d, identifier: %s" % (
        filename, srcline, srccolumn, srcid)

if __name__ == '__main__':
  sys.exit(main())
