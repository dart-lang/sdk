// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Contains a builder object useful for creating source maps programatically.
library source_maps.builder;

// TODO(sigmund): add a builder for multi-section mappings.

import 'dart:convert';

import 'parser.dart';
import 'span.dart';

/// Builds a source map given a set of mappings.
class SourceMapBuilder {

  final List<Entry> _entries = <Entry>[];

  /// Adds an entry mapping the [targetOffset] to [source].
  void addFromOffset(Location source,
      SourceFile targetFile, int targetOffset, String identifier) {
    if (targetFile == null) {
      throw new ArgumentError('targetFile cannot be null');
    }
    _entries.add(new Entry(source,
          new FileLocation(targetFile, targetOffset), identifier));
  }

  /// Adds an entry mapping [target] to [source].
  void addSpan(Span source, Span target) {
    var name = source.isIdentifier ? source.text : null;
    _entries.add(new Entry(source.start, target.start, name));
  }

  void addLocation(Location source, Location target, String identifier) {
    _entries.add(new Entry(source, target, identifier));
  }

  /// Encodes all mappings added to this builder as a json map.
  Map build(String fileUrl) {
    return new SingleMapping.fromEntries(this._entries, fileUrl).toJson();
  }

  /// Encodes all mappings added to this builder as a json string.
  String toJson(String fileUrl) => JSON.encode(build(fileUrl));
}

/// An entry in the source map builder.
class Entry implements Comparable {
  /// Span denoting the original location in the input source file
  final Location source;

  /// Span indicating the corresponding location in the target file.
  final Location target;

  /// An identifier name, when this location is the start of an identifier.
  final String identifierName;

  Entry(this.source, this.target, this.identifierName);

  /// Implements [Comparable] to ensure that entries are ordered by their
  /// location in the target file. We sort primarily by the target offset
  /// because source map files are encoded by printing each mapping in order as
  /// they appear in the target file.
  int compareTo(Entry other) {
    int res = target.compareTo(other.target);
    if (res != 0) return res;
    res = source.sourceUrl.compareTo(other.source.sourceUrl);
    if (res != 0) return res;
    return source.compareTo(other.source);
  }
}
