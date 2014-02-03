// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=
// VMOptions=--print-object-histogram

// Smoke test of the dart2js compiler API.
library dummy_compiler;

import 'dart:async';
import "package:async_helper/async_helper.dart";

import '../../sdk/lib/_internal/compiler/compiler.dart';

Future<String> provider(Uri uri) {
  String source;
  if (uri.scheme == "main") {
    source = "main() {}";
  } else if (uri.scheme == "lib") {
    if (uri.path.endsWith("/core.dart")) {
      source = """
library core;
class Object {
  Object();
  operator==(other) {}
  get hashCode => throw 'Object.hashCode not implemented.';
}
class Type {}
class bool {}
class num {}
class int {}
class double{}
class String{}
class Function{}
class List<E> {}
class Map {}
class Closure {}
class BoundClosure {}
class Dynamic_ {}
class Null {}
class StackTrace {}
class LinkedHashMap {}
identical(a, b) => true;
getRuntimeTypeInfo(o) {}
setRuntimeTypeInfo(o, i) {}
eqNull(a) {}
eqNullB(a) {}
const proxy = 0;""";
    } else if (uri.path.endsWith('_patch.dart')) {
      source = '';
    } else if (uri.path.endsWith('interceptors.dart')) {
      source = """
class Interceptor {
  operator==(other) {}
  get hashCode => throw 'Interceptor.hashCode not implemented.';
}
abstract class JSIndexable {
  get length;
}
abstract class JSMutableIndexable {}
abstract class JSArray<E> implements JSIndexable {
  JSArray() {}
  factory JSArray.typed(a) => a;
  var removeLast;
  var add;
}
abstract class JSMutableArray extends JSArray {}
abstract class JSFixedArray extends JSMutableArray {}
abstract class JSExtendableArray extends JSMutableArray {}
class JSString implements JSIndexable {
  var split;
  var concat;
  operator+(other) {}
  var toString;
  get length => 0;
}
class JSFunction {}
class JSInt {}
class JSPositiveInt {}
class JSUInt31 {}
class JSUInt32 {}
class JSDouble {}
class JSNumber {}
class JSNull {}
class JSBool {}
getInterceptor(o){}
getDispatchProperty(o) {}
setDispatchProperty(o, v) {}
var mapTypeToInterceptor;""";
    } else if (uri.path.endsWith('js_helper.dart')) {
      source = 'library jshelper; class JSInvocationMirror {} '
               'class ConstantMap {} class TypeImpl {} '
               'createRuntimeType(String name) => null;';
    } else if (uri.path.endsWith('isolate_helper.dart')) {
      source = 'library isolatehelper; class _WorkerStub {}';
    } else {
      source = "library lib${uri.path.replaceAll('/', '.')};";
    }
  } else {
   throw "unexpected URI $uri";
  }
  return new Future.value(source);
}

void handler(Uri uri, int begin, int end, String message, Diagnostic kind) {
  if (uri == null) {
    print('$kind: $message');
  } else {
    print('$uri:$begin:$end: $kind: $message');
  }
}

main() {
  asyncStart();
  Future<String> result =
      compile(new Uri(scheme: 'main'),
              new Uri(scheme: 'lib', path: '/'),
              new Uri(scheme: 'package', path: '/'),
              provider, handler);
  result.then((String code) {
    if (code == null) {
      throw 'Compilation failed';
    }
  }, onError: (e) {
      throw 'Compilation failed';
  }).then(asyncSuccess);
}
