// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:compiler/implementation/dart2js.dart'
  as dart2js;

main() {
  Uri currentDirectory = Uri.base;
  Uri script = currentDirectory.resolveUri(Platform.script);
  Uri libraryRoot = script.resolve('../../../sdk/');
  Directory.current = script.resolve("path with spaces").toFilePath();

  return dart2js.main(["--library-root=${libraryRoot.toFilePath()}",
                       "--analyze-only",
                       "file with spaces.dart"]);
}
