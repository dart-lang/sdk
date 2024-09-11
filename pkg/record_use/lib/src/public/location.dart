// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Location {
  final String uri;
  final int line;
  final int column;

  const Location({
    required this.uri,
    required this.line,
    required this.column,
  });

  factory Location.fromJson(
      Map<String, dynamic> map, String? uri, List<String>? uris) {
    return Location(
      uri: uri ?? uris![map['uri'] as int],
      line: map['line'] as int,
      column: map['column'] as int,
    );
  }

  Map<String, dynamic> toJson({List<String>? uris}) {
    return {
      if (uris != null) 'uri': uris.indexOf(uri),
      'line': line,
      'column': column,
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
