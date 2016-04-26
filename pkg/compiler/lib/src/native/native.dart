// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library native;

import '../compiler.dart' show Compiler;
import '../elements/elements.dart';

export 'behavior.dart';
export 'enqueue.dart';
export 'js.dart';
export 'scanner.dart';
export 'ssa.dart';

bool maybeEnableNative(Compiler compiler, LibraryElement library) {
  String libraryName = library.canonicalUri.toString();
  if (library.entryCompilationUnit.script.name
          .contains('sdk/tests/compiler/dart2js_native') ||
      library.entryCompilationUnit.script.name
          .contains('sdk/tests/compiler/dart2js_extra') ||
      libraryName == 'dart:async' ||
      libraryName == 'dart:html' ||
      libraryName == 'dart:html_common' ||
      libraryName == 'dart:indexed_db' ||
      libraryName == 'dart:js' ||
      libraryName == 'dart:svg' ||
      libraryName == 'dart:_native_typed_data' ||
      libraryName == 'dart:web_audio' ||
      libraryName == 'dart:web_gl' ||
      libraryName == 'dart:web_sql' ||
      compiler.options.allowNativeExtensions) {
    return true;
  }
  return false;
}
