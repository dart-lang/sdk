// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class ScriptRef extends ObjectRef {
  /// The uri from which this script was loaded.
  String? get uri;
}

abstract class Script extends Object implements ScriptRef {
  /// The library which owns this script.
  LibraryRef? get library;

  /// The source code for this script. For certain built-in scripts,
  /// this may be reconstructed without source comments.
  String? get source;

  DateTime? get loadTime;
  int? get firstTokenPos;
  int? get lastTokenPos;
  int? get lineOffset;
  int? get columnOffset;

  int? tokenToLine(int? token);
  int? tokenToCol(int? token);
}
