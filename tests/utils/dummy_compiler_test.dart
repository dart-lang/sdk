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

String libProvider(Uri uri) {
  if (uri.path.endsWith("/core.dart")) {
    return """
library core;
class Object {
  Object();
  // Note: JSNull below must reimplement all members.
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
class LinkedHashMap {
  factory LinkedHashMap._empty() => null;
  factory LinkedHashMap._literal(elements) => null;
}
identical(a, b) => true;
getRuntimeTypeInfo(o) {}
setRuntimeTypeInfo(o, i) {}
eqNull(a) {}
eqNullB(a) {}
const proxy = 0;""";
  } else if (uri.path.endsWith('_patch.dart')) {
    return """
import 'dart:_js_helper';
import 'dart:_interceptors';
import 'dart:_isolate_helper';""";
  } else if (uri.path.endsWith('interceptors.dart')) {
    return """
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
class JSNull {
  bool operator ==(other) => identical(null, other);
  int get hashCode => 0;
}
class JSBool {}
getInterceptor(o){}
getDispatchProperty(o) {}
setDispatchProperty(o, v) {}
var mapTypeToInterceptor;""";
  } else if (uri.path.endsWith('js_helper.dart')) {
    return """
library jshelper; class JSInvocationMirror {}
class ConstantMap {} class TypeImpl {}
createRuntimeType(String name) => null;
class Closure {}
class BoundClosure extends Closure {}
""";
  } else if (uri.path.endsWith('isolate_helper.dart')) {
    return 'library isolatehelper; class _WorkerStub {}';
  } else {
    return "library lib${uri.path.replaceAll('/', '.')};";
  }
}

Future<String> provider(Uri uri) {
  String source;
  if (uri.scheme == "main") {
    source = "main() {}";
  } else if (uri.scheme == "lib") {
    source = libProvider(uri);
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
