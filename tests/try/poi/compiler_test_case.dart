// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helper class for writing compiler tests.
library trydart.compiler_test_case;

import 'dart:async' show
    Future;

export 'dart:async' show
    Future;

import 'package:async_helper/async_helper.dart' show
    asyncTest;

import '../../compiler/dart2js/compiler_helper.dart' show
    MockCompiler,
    compilerFor;

export 'package:expect/expect.dart' show
    Expect;

import 'package:compiler/src/elements/elements.dart' show
    LibraryElement;

export 'package:compiler/src/elements/elements.dart' show
    LibraryElement;

const String CONSTANT_CLASS = 'class Constant { const Constant(); }';

const String SCHEME = 'org.trydart.compiler-test-case';

Uri customUri(String path) => Uri.parse('$SCHEME://$path');

Future runTests(List<CompilerTestCase> tests) {
  asyncTest(() => Future.forEach(tests, runTest));
}

Future runTest(CompilerTestCase test) {
  print('\n{{{\n$test\n\n=== Test Output:\n');
  return test.run().then((_) {
  print('}}}');
  });
}

abstract class CompilerTestCase {
  final String source;

  final Uri scriptUri;

  final MockCompiler compiler;

  CompilerTestCase.init(this.source, this.scriptUri, this.compiler);

  CompilerTestCase.intermediate(String source, Uri scriptUri)
      : this.init(source, scriptUri, compilerFor(source, scriptUri));

  CompilerTestCase(String source, [String path])
      : this.intermediate(source, customUri(path == null ? 'main.dart' : path));

  Future<LibraryElement> loadMainApp() {
    return compiler.libraryLoader.loadLibrary(scriptUri)
        .then((LibraryElement library) {
          if (compiler.mainApp == null) {
            compiler.mainApp = library;
          } else if (compiler.mainApp != library) {
            throw
                "Inconsistent use of compiler"
                " (${compiler.mainApp} != $library).";
          }
          return library;
        });
  }

  Future run();

  /// Returns a future for the mainApp after running the compiler.
  Future<LibraryElement> compile() {
    return loadMainApp().then((LibraryElement library) {
      return compiler.runCompiler(scriptUri).then((_) => library);
    });
  }

  String toString() => source;
}
