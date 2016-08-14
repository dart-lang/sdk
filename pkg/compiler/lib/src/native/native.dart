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

const Iterable<String> _allowedDartSchemePaths = const <String>[
  'async',
  'html',
  'html_common',
  'indexed_db',
  'js',
  'js_util',
  'svg',
  '_native_typed_data',
  'web_audio',
  'web_gl',
  'web_sql'
];

bool maybeEnableNative(Compiler compiler, LibraryElement library) {
  bool allowedTestLibrary() {
    String scriptName = library.entryCompilationUnit.script.name;
    return scriptName.contains('sdk/tests/compiler/dart2js_native') ||
        scriptName.contains('sdk/tests/compiler/dart2js_extra');
  }

  bool allowedDartLibary() {
    Uri uri = library.canonicalUri;
    if (uri.scheme != 'dart') return false;
    return _allowedDartSchemePaths.contains(uri.path);
  }

  return allowedTestLibrary() ||
      allowedDartLibary() ||
      compiler.options.allowNativeExtensions;
}
