// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of "recursive" imports using the dart2js compiler API.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'dart:async';
import '../../sdk/lib/_internal/compiler/compiler.dart';

const CORE_LIB = """
library core;
class Object {
  const Object();
  operator==(other) {}
}
class bool {}
class num {}
class int {}
class double{}
class String{}
class Function{}
class List {}
class Map {}
class BoundClosure {}
class Closure {}
class Dynamic_ {}
class Type {}
class Null {}
class StackTrace {}
class LinkedHashMap {}
getRuntimeTypeInfo(o) {}
setRuntimeTypeInfo(o, i) {}
eqNull(a) {}
eqNullB(a) {}
class JSInvocationMirror {}  // Should be in helper.
class _Proxy { const _Proxy(); }
const proxy = const _Proxy();
""";

const INTERCEPTORS_LIB = """
library interceptors;
class JSIndexable {
  get length {}
}
class JSMutableIndexable {}
class JSArray {
  JSArray() {}
  factory JSArray.typed(a) => a;
  removeLast() => null;
  add(x) { }
}
class JSMutableArray extends JSArray {}
class JSExtendableArray extends JSMutableArray {}
class JSFixedArray extends JSMutableArray {}
class JSString {
  split(x) => null;
  concat(x) => null;
  toString() => null;
  operator+(other) => null;
}
class JSNull {
}
class JSBool {
}
""";

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
      if (uri.path.endsWith("/core.dart")) {
        source = CORE_LIB;
      } else if (uri.path.endsWith('_patch.dart')) {
        source = '';
      } else if (uri.path.endsWith('isolate_helper.dart')) {
        source = 'class _WorkerStub {}';
      } else if (uri.path.endsWith('interceptors.dart')) {
        source = INTERCEPTORS_LIB;
      } else {
        source = "library lib${uri.path.replaceAll('/', '.')};";
      }
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
