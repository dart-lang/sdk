// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class Location {
  /// The script containing the source location.
  ScriptRef get script;

  /// [optional] The first token of the location.
  int get tokenPos;
}

abstract class SourceLocation implements Location {
  /// The first token of the location.
  int get tokenPos;

  /// [optional] The last token of the location if this is a range.
  int get endTokenPos;
}

abstract class UnresolvedSourceLocation implements Location {
  /// [optional] The uri of the script containing the source location if the
  /// script has yet to be loaded.
  String get scriptUri;

  /// [optional] An approximate line number for the source location. This may
  /// change when the location is resolved.
  int get line;

  /// [optional] An approximate column number for the source location. This may
  /// change when the location is resolved.
  int get column;
}
