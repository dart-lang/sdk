// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of "recursive" imports using the dart2js compiler API.

import '../../sdk/lib/_internal/compiler/compiler.dart';
import 'dart:uri';

const CORE_LIB = """
library core;
class Object{}
class bool {}
class num {}
class int {}
class double{}
class String{}
class Function{}
class List {}
class Map {}
class Closure {}
class Dynamic_ {}
class Type {}
class Null {}
getRuntimeTypeInfo(o) {}
setRuntimeTypeInfo(o, i) {}
eqNull(a) {}
eqNullB(a) {}
class JSInvocationMirror {}  // Should be in helper.
""";

const String RECURSIVE_MAIN = """
library fisk;
import 'recurse/fisk.dart';
main() {}
""";


main() {
  int count = 0;
  Future<String> provider(Uri uri) {
    Completer<String> completer = new Completer<String>();
    String source;
    if (uri.path.length > 100) {
      // Simulate an OS error.
      throw 'Path length exceeded';
    } else if (uri.scheme == "main") {
      count++;
      source = RECURSIVE_MAIN;
    } else if (uri.scheme == "lib") {
      if (uri.path.endsWith("/core.dart")) {
        source = CORE_LIB;
      } else if (uri.path.endsWith('_patch.dart')) {
        source = '';
      } else {
        source = "library lib${uri.path.replaceAll('/', '.')};";
      }
    } else {
     throw "unexpected URI $uri";
    }
    completer.complete(source);
    return completer.future;
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

  String code = compile(new Uri.fromComponents(scheme: 'main'),
                        new Uri.fromComponents(scheme: 'lib', path: '/'),
                        new Uri.fromComponents(scheme: 'package', path: '/'),
                        provider, handler).value;
  Expect.isNull(code);
  Expect.isTrue(10 < count);
  // Two warnings for each time RECURSIVE_MAIN is read, except the
  // first time.
  Expect.equals(2 * (count - 1), warningCount);
  Expect.equals(1, errorCount);
}
