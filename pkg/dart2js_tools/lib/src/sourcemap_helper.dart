// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility functions to make it easier to work with source-map files.
import 'package:source_span/source_span.dart';
import 'package:source_maps/source_maps.dart';
import 'package:source_maps/src/utils.dart';
import 'util.dart' show FileProvider;

/// Search backwards in [sources] for a function declaration that includes the
/// [start] offset.
TargetEntry findEnclosingFunction(FileProvider provider, Uri uri, int start) {
  String sources = provider.sourcesFor(uri);
  if (sources == null) return null;
  SourceFile file = provider.fileFor(uri);
  SingleMapping mapping = provider.mappingFor(uri).sourceMap;
  int index = start;
  while (true) {
    index = sources.lastIndexOf('function', index);
    if (index < 0) return null;
    var line = file.getLine(index);
    var lineEntry = findLine(mapping, line);
    var column = file.getColumn(index);
    TargetEntry result = findColumn(line, column, lineEntry);
    // If the name entry doesn't start exactly at the column corresponding to
    // `index`, we must be in the middle of a string or code that uses the word
    // "function", but that doesn't have a corresponding mapping. In those
    // cases, we keep searching backwards until we find the actual definition of
    // a function.
    if (result?.column == column) return result;
    index--;
  }
}

/// Returns [TargetLineEntry] which includes the location in the target [line]
/// number. In particular, the resulting entry is the last entry whose line
/// number is lower or equal to [line].
///
/// Copied from [SingleMapping._findLine].
TargetLineEntry findLine(SingleMapping sourceMap, int line) {
  int index = binarySearch(sourceMap.lines, (e) => e.line > line);
  return (index <= 0) ? null : sourceMap.lines[index - 1];
}

/// Returns [TargetEntry] which includes the location denoted by
/// [line], [column]. If [lineEntry] corresponds to [line], then this will be
/// the last entry whose column is lower or equal than [column]. If
/// [lineEntry] corresponds to a line prior to [line], then the result will be
/// the very last entry on that line.
///
/// Copied from [SingleMapping._findColumn].
TargetEntry findColumn(int line, int column, TargetLineEntry lineEntry) {
  if (lineEntry == null || lineEntry.entries.length == 0) return null;
  if (lineEntry.line != line) return lineEntry.entries.last;
  var entries = lineEntry.entries;
  int index = binarySearch(entries, (e) => e.column > column);
  return (index <= 0) ? null : entries[index - 1];
}
