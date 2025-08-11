// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Location {
  final String uri;
  final int? line;
  final int? column;

  const Location({required this.uri, this.line, this.column});

  static const _uriKey = 'uri';
  static const _lineKey = 'line';
  static const _columnKey = 'column';

  factory Location.fromJson(Map<String, Object?> map) {
    return Location(
      uri: map[_uriKey] as String,
      line: map[_lineKey] as int?,
      column: map[_columnKey] as int?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      _uriKey: uri,
      if (line != null) _lineKey: line,
      if (line != null) _columnKey: column,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Location &&
        other.uri == uri &&
        other.line == line &&
        other.column == column;
  }

  @override
  int get hashCode => Object.hash(uri, line, column);
}
