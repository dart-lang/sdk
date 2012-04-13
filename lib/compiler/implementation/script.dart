// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Script {
  // TODO(kasperl): Once MockFile in frog/tests/leg/src/parser_helper.dart
  // implements SourceFile, we should be able to type the [file] field as
  // such.
  final file;
  final Uri uri;
  Script(this.uri, this.file);

  String get text() => (file === null) ? null : file.text;
  String get name() => (file === null) ? null : file.filename;
}
