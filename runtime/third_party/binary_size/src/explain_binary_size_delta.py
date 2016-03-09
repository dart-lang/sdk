#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Describe the size difference of two binaries.

Generates a description of the size difference of two binaries based
on the difference of the size of various symbols.

This tool needs "nm" dumps of each binary with full symbol
information. You can obtain the necessary dumps by running the
run_binary_size_analysis.py script upon each binary, with the
"--nm-out" parameter set to the location in which you want to save the
dumps. Example:

  # obtain symbol data from first binary in /tmp/nm1.dump
  cd $CHECKOUT1_SRC
  ninja -C out/Release binary_size_tool
  tools/binary_size/run_binary_size_analysis \
      --library <path_to_library>
      --destdir /tmp/throwaway
      --nm-out /tmp/nm1.dump

  # obtain symbol data from second binary in /tmp/nm2.dump
  cd $CHECKOUT2_SRC
  ninja -C out/Release binary_size_tool
  tools/binary_size/run_binary_size_analysis \
      --library <path_to_library>
      --destdir /tmp/throwaway
      --nm-out /tmp/nm2.dump

  # cleanup useless files
  rm -r /tmp/throwaway

  # run this tool
  explain_binary_size_delta.py --nm1 /tmp/nm1.dump --nm2 /tmp/nm2.dump
"""

import collections
from collections import Counter
from math import ceil
import operator
import optparse
import os
import sys

import binary_size_utils


def CalculateSharedAddresses(symbols):
  """Checks how many symbols share the same memory space. This returns a
Counter result where result[address] will tell you how many times address was
used by symbols."""
  count = Counter()
  for _, _, _, _, address in symbols:
    count[address] += 1

  return count


def CalculateEffectiveSize(share_count, address, symbol_size):
  """Given a raw symbol_size and an address, this method returns the
  size we should blame on this symbol considering it might share the
  machine code/data with other symbols. Using the raw symbol_size for
  each symbol would in those cases over estimate the true cost of that
  block.

  """
  shared_count = share_count[address]
  if shared_count == 1:
    return symbol_size

  assert shared_count > 1
  return int(ceil(symbol_size / float(shared_count)))

class SymbolDelta(object):
  """Stores old size, new size and some metadata."""
  def __init__(self, shared):
    self.old_size = None
    self.new_size = None
    self.shares_space_with_other_symbols = shared

  def __eq__(self, other):
    return (self.old_size == other.old_size and
            self.new_size == other.new_size and
            self.shares_space_with_other_symbols ==
            other.shares_space_with_other_symbols)

  def __ne__(self, other):
    return not self.__eq__(other)

  def copy_symbol_delta(self):
    symbol_delta = SymbolDelta(self.shares_space_with_other_symbols)
    symbol_delta.old_size = self.old_size
    symbol_delta.new_size = self.new_size
    return symbol_delta

class DeltaInfo(SymbolDelta):
  """Summary of a the change for one symbol between two instances."""
  def __init__(self, file_path, symbol_type, symbol_name, shared):
    SymbolDelta.__init__(self, shared)
    self.file_path = file_path
    self.symbol_type = symbol_type
    self.symbol_name = symbol_name

  def __eq__(self, other):
    return (self.file_path == other.file_path and
            self.symbol_type == other.symbol_type and
            self.symbol_name == other.symbol_name and
            SymbolDelta.__eq__(self, other))

  def __ne__(self, other):
    return not self.__eq__(other)

  def ExtractSymbolDelta(self):
    """Returns a copy of the SymbolDelta for this DeltaInfo."""
    return SymbolDelta.copy_symbol_delta(self)

def Compare(symbols1, symbols2):
  """Executes a comparison of the symbols in symbols1 and symbols2.

  Returns:
      tuple of lists: (added_symbols, removed_symbols, changed_symbols, others)
      where each list contains DeltaInfo objects.
  """
  added = [] # tuples
  removed = [] # tuples
  changed = [] # tuples
  unchanged = [] # tuples

  cache1 = {}
  cache2 = {}
  # Make a map of (file, symbol_type) : (symbol_name, effective_symbol_size)
  share_count1 = CalculateSharedAddresses(symbols1)
  share_count2 = CalculateSharedAddresses(symbols2)
  for cache, symbols, share_count in ((cache1, symbols1, share_count1),
                                      (cache2, symbols2, share_count2)):
    for symbol_name, symbol_type, symbol_size, file_path, address in symbols:
      if 'vtable for ' in symbol_name:
        symbol_type = '@' # hack to categorize these separately
      if file_path:
        file_path = os.path.normpath(file_path)
        if sys.platform.startswith('win'):
          file_path = file_path.replace('\\', '/')
      else:
        file_path = '(No Path)'
      # Take into consideration that multiple symbols might share the same
      # block of code.
      effective_symbol_size = CalculateEffectiveSize(share_count, address,
                                                     symbol_size)
      key = (file_path, symbol_type)
      bucket = cache.setdefault(key, {})
      size_list = bucket.setdefault(symbol_name, [])
      size_list.append((effective_symbol_size,
                        effective_symbol_size != symbol_size))

  # Now diff them. We iterate over the elements in cache1. For each symbol
  # that we find in cache2, we record whether it was deleted, changed, or
  # unchanged. We then remove it from cache2; all the symbols that remain
  # in cache2 at the end of the iteration over cache1 are the 'new' symbols.
  for key, bucket1 in cache1.items():
    bucket2 = cache2.get(key)
    file_path, symbol_type = key;
    if not bucket2:
      # A file was removed. Everything in bucket1 is dead.
      for symbol_name, symbol_size_list in bucket1.items():
        for (symbol_size, shared) in symbol_size_list:
          delta_info = DeltaInfo(file_path, symbol_type, symbol_name, shared)
          delta_info.old_size = symbol_size
          removed.append(delta_info)
    else:
      # File still exists, look for changes within.
      for symbol_name, symbol_size_list in bucket1.items():
        size_list2 = bucket2.get(symbol_name)
        if size_list2 is None:
          # Symbol no longer exists in bucket2.
          for (symbol_size, shared) in symbol_size_list:
            delta_info = DeltaInfo(file_path, symbol_type, symbol_name, shared)
            delta_info.old_size = symbol_size
            removed.append(delta_info)
        else:
          del bucket2[symbol_name] # Symbol is not new, delete from cache2.
          if len(symbol_size_list) == 1 and len(size_list2) == 1:
            symbol_size, shared1 = symbol_size_list[0]
            size2, shared2 = size_list2[0]
            delta_info = DeltaInfo(file_path, symbol_type, symbol_name,
                                   shared1 or shared2)
            delta_info.old_size = symbol_size
            delta_info.new_size = size2
            if symbol_size != size2:
              # Symbol has change size in bucket.
              changed.append(delta_info)
            else:
              # Symbol is unchanged.
              unchanged.append(delta_info)
          else:
            # Complex comparison for when a symbol exists multiple times
            # in the same file (where file can be "unknown file").
            symbol_size_counter = collections.Counter(symbol_size_list)
            delta_counter = collections.Counter(symbol_size_list)
            delta_counter.subtract(size_list2)
            for delta_counter_key in sorted(delta_counter.keys()):
              delta = delta_counter[delta_counter_key]
              unchanged_count = symbol_size_counter[delta_counter_key]
              (symbol_size, shared) = delta_counter_key
              if delta > 0:
                unchanged_count -= delta
              for _ in range(unchanged_count):
                delta_info = DeltaInfo(file_path, symbol_type,
                                       symbol_name, shared)
                delta_info.old_size = symbol_size
                delta_info.new_size = symbol_size
                unchanged.append(delta_info)
              if delta > 0: # Used to be more of these than there is now.
                for _ in range(delta):
                  delta_info = DeltaInfo(file_path, symbol_type,
                                         symbol_name, shared)
                  delta_info.old_size = symbol_size
                  removed.append(delta_info)
              elif delta < 0: # More of this (symbol,size) now.
                for _ in range(-delta):
                  delta_info = DeltaInfo(file_path, symbol_type,
                                         symbol_name, shared)
                  delta_info.new_size = symbol_size
                  added.append(delta_info)

          if len(bucket2) == 0:
            del cache1[key] # Entire bucket is empty, delete from cache2

  # We have now analyzed all symbols that are in cache1 and removed all of
  # the encountered symbols from cache2. What's left in cache2 is the new
  # symbols.
  for key, bucket2 in cache2.iteritems():
    file_path, symbol_type = key;
    for symbol_name, symbol_size_list in bucket2.items():
      for (symbol_size, shared) in symbol_size_list:
        delta_info = DeltaInfo(file_path, symbol_type, symbol_name, shared)
        delta_info.new_size = symbol_size
        added.append(delta_info)
  return (added, removed, changed, unchanged)


def DeltaStr(number):
  """Returns the number as a string with a '+' prefix if it's > 0 and
  a '-' prefix if it's < 0."""
  result = str(number)
  if number > 0:
    result = '+' + result
  return result


def SharedInfoStr(symbol_info):
  """Returns a string (prefixed by space) explaining that numbers are
  adjusted because of shared space between symbols, or an empty string
  if space had not been shared."""

  if symbol_info.shares_space_with_other_symbols:
    return " (adjusted sizes because of memory sharing)"

  return ""

class CrunchStatsData(object):
  """Stores a summary of data of a certain kind."""
  def __init__(self, symbols):
    self.symbols = symbols
    self.sources = set()
    self.before_size = 0
    self.after_size = 0
    self.symbols_by_path = {}


def CrunchStats(added, removed, changed, unchanged, showsources, showsymbols):
  """Outputs to stdout a summary of changes based on the symbol lists."""
  # Split changed into grown and shrunk because that is easier to
  # discuss.
  grown = []
  shrunk = []
  for item in changed:
    if item.old_size < item.new_size:
      grown.append(item)
    else:
      shrunk.append(item)

  new_symbols = CrunchStatsData(added)
  removed_symbols = CrunchStatsData(removed)
  grown_symbols = CrunchStatsData(grown)
  shrunk_symbols = CrunchStatsData(shrunk)
  sections = [new_symbols, removed_symbols, grown_symbols, shrunk_symbols]
  for section in sections:
    for item in section.symbols:
      section.sources.add(item.file_path)
      if item.old_size is not None:
        section.before_size += item.old_size
      if item.new_size is not None:
        section.after_size += item.new_size
      bucket = section.symbols_by_path.setdefault(item.file_path, [])
      bucket.append((item.symbol_name, item.symbol_type,
                     item.ExtractSymbolDelta()))

  total_change = sum(s.after_size - s.before_size for s in sections)
  summary = 'Total change: %s bytes' % DeltaStr(total_change)
  print(summary)
  print('=' * len(summary))
  for section in sections:
    if not section.symbols:
      continue
    if section.before_size == 0:
      description = ('added, totalling %s bytes' % DeltaStr(section.after_size))
    elif section.after_size == 0:
      description = ('removed, totalling %s bytes' %
                     DeltaStr(-section.before_size))
    else:
      if section.after_size > section.before_size:
        type_str = 'grown'
      else:
        type_str = 'shrunk'
      description = ('%s, for a net change of %s bytes '
                     '(%d bytes before, %d bytes after)' %
            (type_str, DeltaStr(section.after_size - section.before_size),
             section.before_size, section.after_size))
    print('  %d %s across %d sources' %
          (len(section.symbols), description, len(section.sources)))

  maybe_unchanged_sources = set()
  unchanged_symbols_size = 0
  for item in unchanged:
    maybe_unchanged_sources.add(item.file_path)
    unchanged_symbols_size += item.old_size # == item.new_size
  print('  %d unchanged, totalling %d bytes' %
        (len(unchanged), unchanged_symbols_size))

  # High level analysis, always output.
  unchanged_sources = maybe_unchanged_sources
  for section in sections:
    unchanged_sources = unchanged_sources - section.sources
  new_sources = (new_symbols.sources -
    maybe_unchanged_sources -
    removed_symbols.sources)
  removed_sources = (removed_symbols.sources -
    maybe_unchanged_sources -
    new_symbols.sources)
  partially_changed_sources = (grown_symbols.sources |
    shrunk_symbols.sources | new_symbols.sources |
    removed_symbols.sources) - removed_sources - new_sources
  allFiles = set()
  for section in sections:
    allFiles = allFiles | section.sources
  allFiles = allFiles | maybe_unchanged_sources
  print 'Source stats:'
  print('  %d sources encountered.' % len(allFiles))
  print('  %d completely new.' % len(new_sources))
  print('  %d removed completely.' % len(removed_sources))
  print('  %d partially changed.' % len(partially_changed_sources))
  print('  %d completely unchanged.' % len(unchanged_sources))
  remainder = (allFiles - new_sources - removed_sources -
    partially_changed_sources - unchanged_sources)
  assert len(remainder) == 0

  if not showsources:
    return  # Per-source analysis, only if requested
  print 'Per-source Analysis:'
  delta_by_path = {}
  for section in sections:
    for path in section.symbols_by_path:
      entry = delta_by_path.get(path)
      if not entry:
        entry = {'plus': 0, 'minus': 0}
        delta_by_path[path] = entry
      for symbol_name, symbol_type, symbol_delta in \
            section.symbols_by_path[path]:
        if symbol_delta.old_size is None:
          delta = symbol_delta.new_size
        elif symbol_delta.new_size is None:
          delta = -symbol_delta.old_size
        else:
          delta = symbol_delta.new_size - symbol_delta.old_size

        if delta > 0:
          entry['plus'] += delta
        else:
          entry['minus'] += (-1 * delta)

  def delta_sort_key(item):
    _path, size_data = item
    growth = size_data['plus'] - size_data['minus']
    return growth

  for path, size_data in sorted(delta_by_path.iteritems(), key=delta_sort_key,
                                reverse=True):
    gain = size_data['plus']
    loss = size_data['minus']
    delta = size_data['plus'] - size_data['minus']
    header = ' %s - Source: %s - (gained %d, lost %d)' % (DeltaStr(delta),
                                                          path, gain, loss)
    divider = '-' * len(header)
    print ''
    print divider
    print header
    print divider
    if showsymbols:
      def ExtractNewSize(tup):
        symbol_delta = tup[2]
        return symbol_delta.new_size
      def ExtractOldSize(tup):
        symbol_delta = tup[2]
        return symbol_delta.old_size
      if path in new_symbols.symbols_by_path:
        print '  New symbols:'
        for symbol_name, symbol_type, symbol_delta in \
            sorted(new_symbols.symbols_by_path[path],
                   key=ExtractNewSize,
                   reverse=True):
          print ('   %8s: %s type=%s, size=%d bytes%s' %
                 (DeltaStr(symbol_delta.new_size), symbol_name, symbol_type,
                  symbol_delta.new_size, SharedInfoStr(symbol_delta)))
      if path in removed_symbols.symbols_by_path:
        print '  Removed symbols:'
        for symbol_name, symbol_type, symbol_delta in \
            sorted(removed_symbols.symbols_by_path[path],
                   key=ExtractOldSize):
          print ('   %8s: %s type=%s, size=%d bytes%s' %
                 (DeltaStr(-symbol_delta.old_size), symbol_name, symbol_type,
                  symbol_delta.old_size,
                  SharedInfoStr(symbol_delta)))
      for (changed_symbols_by_path, type_str) in [
        (grown_symbols.symbols_by_path, "Grown"),
        (shrunk_symbols.symbols_by_path, "Shrunk")]:
        if path in changed_symbols_by_path:
          print '  %s symbols:' % type_str
          def changed_symbol_sortkey(item):
            symbol_name, _symbol_type, symbol_delta = item
            return (symbol_delta.old_size - symbol_delta.new_size, symbol_name)
          for symbol_name, symbol_type, symbol_delta in \
              sorted(changed_symbols_by_path[path], key=changed_symbol_sortkey):
            print ('   %8s: %s type=%s, (was %d bytes, now %d bytes)%s'
                   % (DeltaStr(symbol_delta.new_size - symbol_delta.old_size),
                      symbol_name, symbol_type,
                      symbol_delta.old_size, symbol_delta.new_size,
                      SharedInfoStr(symbol_delta)))


def main():
  usage = """%prog [options]

  Analyzes the symbolic differences between two binary files
  (typically, not necessarily, two different builds of the same
  library) and produces a detailed description of symbols that have
  been added, removed, or whose size has changed.

  Example:
       explain_binary_size_delta.py --nm1 /tmp/nm1.dump --nm2 /tmp/nm2.dump

  Options are available via '--help'.
  """
  parser = optparse.OptionParser(usage=usage)
  parser.add_option('--nm1', metavar='PATH',
                    help='the nm dump of the first library')
  parser.add_option('--nm2', metavar='PATH',
                    help='the nm dump of the second library')
  parser.add_option('--showsources', action='store_true', default=False,
                    help='show per-source statistics')
  parser.add_option('--showsymbols', action='store_true', default=False,
                    help='show all symbol information; implies --showsources')
  parser.add_option('--verbose', action='store_true', default=False,
                    help='output internal debugging stuff')
  opts, _args = parser.parse_args()

  if not opts.nm1:
    parser.error('--nm1 is required')
  if not opts.nm2:
    parser.error('--nm2 is required')
  symbols = []
  for path in [opts.nm1, opts.nm2]:
    with file(path, 'r') as nm_input:
      if opts.verbose:
        print 'parsing ' + path + '...'
      symbols.append(list(binary_size_utils.ParseNm(nm_input)))
  (added, removed, changed, unchanged) = Compare(symbols[0], symbols[1])
  CrunchStats(added, removed, changed, unchanged,
    opts.showsources | opts.showsymbols, opts.showsymbols)

if __name__ == '__main__':
  sys.exit(main())
