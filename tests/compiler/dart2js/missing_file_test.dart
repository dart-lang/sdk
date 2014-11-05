// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the compiler can handle imports when package root has not been set.

library dart2js.test.missing_file;

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_source_file_helper.dart';

import 'package:compiler/src/dart2jslib.dart'
       show NullSink;

import 'package:compiler/compiler.dart'
       show DiagnosticHandler, Diagnostic;

import 'dart:async';

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''

import 'foo.dart';

main() {}
''',
};

void runCompiler(Uri main, String expectedMessage) {
  Uri script = currentDirectory.resolveUri(Platform.script);
  Uri libraryRoot = script.resolve('../../../sdk/');

  var provider = new MemorySourceFileProvider(MEMORY_SOURCE_FILES);
  var handler = new FormattingDiagnosticHandler(provider);
  var errors = [];

  void diagnosticHandler(Uri uri, int begin, int end, String message,
                         Diagnostic kind) {
    if (kind == Diagnostic.ERROR) {
      errors.add(message);
    }
    handler(uri, begin, end, message, kind);
  }


  EventSink<String> outputProvider(String name, String extension) {
    if (name != '') throw 'Attempt to output file "$name.$extension"';
    return new NullSink('$name.$extension');
  }

  Compiler compiler = new Compiler(provider,
                                   outputProvider,
                                   diagnosticHandler,
                                   libraryRoot,
                                   null,
                                   [],
                                   {});

  asyncTest(() => compiler.run(main).then((_) {
    Expect.equals(1, errors.length);
    Expect.equals(expectedMessage,
                  errors[0]);
  }));
}

void main() {
  runCompiler(Uri.parse('memory:main.dart'),
              "Can't read 'memory:foo.dart' "
              "(Exception: No such file memory:foo.dart).");
  runCompiler(Uri.parse('memory:foo.dart'),
              "Can't read 'memory:foo.dart' "
              "(Exception: No such file memory:foo.dart).");
  runCompiler(Uri.parse('dart:foo'),
              "Library not found 'dart:foo'.");
}
