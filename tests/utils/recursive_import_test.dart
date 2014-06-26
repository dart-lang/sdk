// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of "recursive" imports using the dart2js compiler API.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'dart:async';
import 'dummy_compiler_test.dart';
import 'package:compiler/compiler.dart';

const String RECURSIVE_MAIN = """
library fisk;
import 'recurse/fisk.dart';
main() {}
""";


main() {
  int count = 0;
  Future<String> provider(Uri uri) {
    String source;
    if (uri.path.length > 100) {
      // Simulate an OS error.
      throw 'Path length exceeded';
    } else if (uri.scheme == "main") {
      count++;
      source = RECURSIVE_MAIN;
    } else if (uri.scheme == "lib") {
      source = libProvider(uri);
    } else {
     return new Future.error("unexpected URI $uri");
    }
    return new Future.value(source);
  }

  int warningCount = 0;
  int errorCount = 0;
  void handler(Uri uri, int begin, int end, String message, Diagnostic kind) {
    if (uri != null) {
      // print('$uri:$begin:$end: $kind: $message');
      Expect.equals('main', uri.scheme);
      if (kind == Diagnostic.WARNING) {
        warningCount++;
      } else if (kind == Diagnostic.ERROR) {
        errorCount++;
      } else {
        throw kind;
      }
    }
  }

  asyncStart();
  Future<String> result =
      compile(new Uri(scheme: 'main'),
              new Uri(scheme: 'lib', path: '/'),
              new Uri(scheme: 'package', path: '/'),
              provider, handler);
  result.then((String code) {
    Expect.isNull(code);
    Expect.isTrue(10 < count);
    // Two warnings for each time RECURSIVE_MAIN is read, except the
    // first time.
    Expect.equals(2 * (count - 1), warningCount);
    Expect.equals(1, errorCount);
  }, onError: (e) {
      throw 'Compilation failed';
  }).then(asyncSuccess);
}
