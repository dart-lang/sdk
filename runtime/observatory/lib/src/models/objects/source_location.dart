// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class SourceLocation {
  /// The script containing the source location.
  ScriptRef get script;
  /// The first token of the location.
  int get tokenPos;
  /// The last token of the location if this is a range. [optional]
  int get endTokenPos;
}
