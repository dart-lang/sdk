// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Contains a builder object useful for creating source maps programatically.
library source_maps.builder;

// TODO(sigmund): add a builder for multi-section mappings.

import 'dart:collection';
import 'dart:convert';

import 'span.dart';
import 'src/vlq.dart';

/// Builds a source map given a set of mappings.
class SourceMapBuilder {

  final List<Entry> _entries = <Entry>[];

  /// Indices associated with file urls that will be part of the source map. We
  /// use a linked hash-map so that `_urls.keys[_urls[u]] == u`
  final Map<String, int> _urls = new LinkedHashMap<String, int>();

  /// Indices associated with identifiers that will be part of the source map.
  /// We use a linked hash-map so that `_names.keys[_names[n]] == n`
  final Map<String, int> _names = new LinkedHashMap<String, int>();

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
    var buff = new StringBuffer();
    var line = 0;
    var column = 0;
    var srcLine = 0;
    var srcColumn = 0;
    var srcUrlId = 0;
    var srcNameId = 0;
    var first = true;

    // The encoding needs to be sorted by the target offsets.
    _entries.sort();
    for (var entry in _entries) {
      int nextLine = entry.target.line;
      if (nextLine > line) {
        for (int i = line; i < nextLine; ++i) {
          buff.write(';');
        }
        line = nextLine;
        column = 0;
        first = true;
      }

      if (!first) buff.write(',');
      first = false;
      column = _append(buff, column, entry.target.column);

      // Encoding can be just the column offset if there is no source
      // information.
      var source = entry.source;
      if (source == null) continue;
      var newUrlId = _indexOf(_urls, source.sourceUrl);

      srcUrlId = _append(buff, srcUrlId, newUrlId);
      srcLine = _append(buff, srcLine, source.line);
      srcColumn = _append(buff, srcColumn, source.column);

      if (entry.identifierName == null) continue;
      srcNameId = _append(buff, srcNameId,
          _indexOf(_names, entry.identifierName));
    }

    var result = {
      'version': 3,
      'sourceRoot': '',
      'sources': _urls.keys.toList(),
      'names' : _names.keys.toList(),
      'mappings' : buff.toString()
    };
    if (fileUrl != null) {
      result['file'] = fileUrl;
    }
    return result;
  }

  /// Encodes all mappings added to this builder as a json string.
  String toJson(String fileUrl) => JSON.encode(build(fileUrl));

  /// Get the index of [value] in [map], or create one if it doesn't exist.
  int _indexOf(Map<String, int> map, String value) {
    return map.putIfAbsent(value, () {
      int index = map.length;
      map[value] = index;
      return index;
    });
  }

  /// Appends to [buff] a VLQ encoding of [newValue] using the difference
  /// between [oldValue] and [newValue]
  static int _append(StringBuffer buff, int oldValue, int newValue) {
    buff.writeAll(encodeVlq(newValue - oldValue));
    return newValue;
  }
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
