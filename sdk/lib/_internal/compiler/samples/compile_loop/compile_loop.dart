// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This sample demonstrates how to run the compiler in a loop reading
// all sources from memory, instead of using dart:io.
library sample.compile_loop;

import 'dart:async';

import '../../compiler.dart' as compiler;

// If this file is missing, generate it using ../jsonify/jsonify.dart.
import 'sdk.dart';

Future<String> compile(source) {
  Future<String> inputProvider(Uri uri) {
    if (uri.scheme == 'sdk') {
      var value = SDK_SOURCES['$uri'];
      if (value == null) {
        // TODO(ahe): Use new Future.error.
        throw new Exception('Error: Cannot read: $uri');
      }
      return new Future.value(value);
    } else if ('$uri' == 'memory:/main.dart') {
      return new Future.value(source);
    }
    // TODO(ahe): Use new Future.error.
    throw new Exception('Error: Cannot read: $uri');
  }
  void handler(Uri uri, int begin, int end,
               String message, compiler.Diagnostic kind) {
    // TODO(ahe): Remove dart:io import from
    // ../../implementation/source_file_provider.dart and use
    // FormattingDiagnosticHandler instead.
    print({ 'uri': '$uri',
            'begin': begin,
            'end': end,
            'message': message,
            'kind': kind.name });
    if (kind == compiler.Diagnostic.ERROR) {
      throw new Exception('Unexpected error occurred.');
    }
  }
  return compiler.compile(
      Uri.parse('memory:/main.dart'),
      Uri.parse('sdk:/sdk/'),
      null,
      inputProvider,
      handler,
      []);
}

int iterations = 10;

main() {
  compile(EXAMPLE_HELLO_HTML).then((jsResult) {
    if (jsResult == null) throw 'Compilation failed';
    if (--iterations > 0) main();
  });
}

const String EXAMPLE_HELLO_HTML = r'''
// Go ahead and modify this example.

import "dart:html";

var greeting = "Hello, World!";

// Displays a greeting.
void main() {
  // This example uses HTML to display the greeting and it will appear
  // in a nested HTML frame (an iframe).
  document.body.append(new HeadingElement.h1()..appendText(greeting));
}
''';
