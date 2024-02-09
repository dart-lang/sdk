// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility functions to make it easier to work with source-map files.
library;

import 'package:source_maps/source_maps.dart';
// ignore: implementation_imports
import 'package:source_maps/src/utils.dart';
import 'package:source_span/source_span.dart';

import 'util.dart' show FileProvider;

/// Search backwards in [sources] for a function declaration that includes the
/// [start] offset.
TargetEntry? findEnclosingFunction(FileProvider provider, Uri uri, int start) {
  String sources = provider.sourcesFor(uri);
  SourceFile file = provider.fileFor(uri);
  SingleMapping mapping = provider.mappingFor(uri)!.sourceMap;
  var index = start;
  while (true) {
    index = nextDeclarationCandidate(sources, index);
    if (index < 0) return null;
    var line = file.getLine(index);
    var lineEntry = findLine(mapping, line);
    var column = file.getColumn(index);
    TargetEntry? result = findColumn(line, column, lineEntry);
    // If the name entry doesn't start exactly at the column corresponding to
    // `index`, we must be in the middle of a string or code that uses the word
    // "function", but that doesn't have a corresponding mapping. In those
    // cases, we keep searching backwards until we find the actual definition of
    // a function.
    if (result?.column == column) return result;
    index--;
  }
}

/// Returns the index of a candidate location of a enclosing function
/// declaration. We try to find the beginning of a `function` keyword or the
/// `(` of an ES6 method definition, but the search contains some false
/// positives. To rule out false positives, [findEnclosingFunction]
/// validates that the returned location contains a source-map entry, searching
/// for another candidate if not.
int nextDeclarationCandidate(String sources, int start) {
  var indexForFunctionKeyword = sources.lastIndexOf('function', start);
  // We attempt to identify potential method definitions by looking for any '('
  // that precedes a '{'. This method will fail if 1) Dart2JS starts emitting
  // functions with initializers or 2) sourcemap boundaries appear at '(' for
  // non-method-definition constructs.
  var indexForMethodDefinition = sources.lastIndexOf('{', start);
  if (indexForFunctionKeyword > indexForMethodDefinition ||
      indexForFunctionKeyword < 0) {
    return indexForFunctionKeyword;
  }
  indexForMethodDefinition = sources.lastIndexOf('(', indexForMethodDefinition);
  return indexForFunctionKeyword > indexForMethodDefinition
      ? indexForFunctionKeyword
      : indexForMethodDefinition;
}

/// Returns [TargetLineEntry] which includes the location in the target [line]
/// number. In particular, the resulting entry is the last entry whose line
/// number is lower or equal to [line].
///
/// Copied from [SingleMapping._findLine].
TargetLineEntry? findLine(SingleMapping sourceMap, int line) {
  int index =
      binarySearch<TargetLineEntry>(sourceMap.lines, (e) => e.line > line);
  return (index <= 0) ? null : sourceMap.lines[index - 1];
}

/// Returns [TargetEntry] which includes the location denoted by
/// [line], [column]. If [lineEntry] corresponds to [line], then this will be
/// the last entry whose column is lower or equal than [column]. If
/// [lineEntry] corresponds to a line prior to [line], then the result will be
/// the very last entry on that line.
///
/// Copied from [SingleMapping._findColumn].
TargetEntry? findColumn(int line, int column, TargetLineEntry? lineEntry) {
  if (lineEntry == null || lineEntry.entries.isEmpty) return null;
  if (lineEntry.line != line) return lineEntry.entries.last;
  var entries = lineEntry.entries;
  int index = binarySearch<TargetEntry>(entries, (e) => e.column > column);
  return (index <= 0) ? null : entries[index - 1];
}
