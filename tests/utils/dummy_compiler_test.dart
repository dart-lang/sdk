// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Smoke test of the dart2js compiler API.
library dummy_compiler;

import 'dart:async';
import 'dart:uri';

import '../../sdk/lib/_internal/compiler/compiler.dart';

Future<String> provider(Uri uri) {
  Completer<String> completer = new Completer<String>();
  String source;
  if (uri.scheme == "main") {
    source = "main() {}";
  } else if (uri.scheme == "lib") {
    if (uri.path.endsWith("/core.dart")) {
      source = """library core;
                  class Object {}
                  class Type {}
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
                  class Null {}
                  getRuntimeTypeInfo(o) {}
                  setRuntimeTypeInfo(o, i) {}
                  eqNull(a) {}
                  eqNullB(a) {}""";
    } else if (uri.path.endsWith('_patch.dart')) {
      source = '';
    } else if (uri.path.endsWith('interceptors.dart')) {
      source = """class ObjectInterceptor {}
                  class JSArray {
                    var length;
                    var removeLast;
                    var add;
                  }
                  class JSString {
                    var length;
                    var split;
                    var concat;
                  }
                  class JSFunction {}
                  class JSInt {}
                  class JSDouble {}
                  class JSNumber {}
                  class JSNull {}
                  class JSBool {}
                  var getInterceptor;""";
    } else if (uri.path.endsWith('js_helper.dart')) {
      source = 'library jshelper; class JSInvocationMirror {}';
    } else if (uri.path.endsWith('isolate_helper.dart')) {
      source = 'library isolatehelper; class _WorkerStub {}';
    } else {
      source = "library lib;";
    }
  } else {
   throw "unexpected URI $uri";
  }
  completer.complete(source);
  return completer.future;
}

void handler(Uri uri, int begin, int end, String message, Diagnostic kind) {
  if (uri == null) {
    print('$kind: $message');
  } else {
    print('$uri:$begin:$end: $kind: $message');
  }
}

main() {
  Future<String> result =
      compile(new Uri.fromComponents(scheme: 'main'),
              new Uri.fromComponents(scheme: 'lib', path: '/'),
              new Uri.fromComponents(scheme: 'package', path: '/'),
              provider, handler);
  result.then((String code) {
    if (code == null) {
      throw 'Compilation failed';
    }
  }, onError: (AsyncError e) {
      throw 'Compilation failed';
  });
}
