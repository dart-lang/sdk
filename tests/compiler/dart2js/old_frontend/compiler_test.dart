// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";

import "package:async_helper/async_helper.dart";
import 'package:compiler/compiler.dart';
import "package:compiler/src/elements/elements.dart";
import "package:compiler/src/old_to_new_api.dart";
import "package:expect/expect.dart";

import "mock_compiler.dart";

Future testErrorHandling() {
  // Test that compiler.currentElement is set correctly when
  // reporting errors/warnings.
  MockCompiler compiler = new MockCompiler.internal();
  return compiler.init().then((_) {
    compiler.parseScript('NoSuchPrefix.NoSuchType foo() {}');
    LibraryElement mainApp = compiler.mainApp;
    FunctionElement foo = mainApp.find('foo');
    compiler.diagnosticHandler = new LegacyCompilerDiagnostics(
        (Uri uri, int begin, int end, String message, Diagnostic kind) {
      if (kind == Diagnostic.WARNING) {
        Expect.equals(foo, compiler.currentElement);
      }
    });
    foo.computeType(compiler.resolution);
    Expect.equals(1, compiler.diagnosticCollector.warnings.length);
  });
}

main() {
  asyncTest(() => testErrorHandling());
}
