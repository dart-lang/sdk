// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';

Future<int> badFunc() async {
  return 3;
}

Future<String> badFunc2() async {
  return 'hello';
}

FutureOr<JSObject> badFunc3() async {
  return JSObject();
}

Future<dynamic> badFunc4() async {
  return 2;
}

void main() {
  badFunc.toJS;
  //      ^
  // [web] Calling 'toJS' on a function returning 'Future<T>' requires 'T' to be a subtype of 'JSAny?' or 'void'.
  badFunc2.toJS;
  //       ^
  // [web] Calling 'toJS' on a function returning 'Future<T>' requires 'T' to be a subtype of 'JSAny?' or 'void'.
  badFunc3.toJS;
  //       ^
  // [web] Function converted via 'toJS' contains invalid types in its function signature: '*FutureOr<JSObject>* Function()'.
  badFunc4.toJS;
  //       ^
  // [web] Calling 'toJS' on a function returning 'Future<T>' requires 'T' to be a subtype of 'JSAny?' or 'void'.
  (() async => 3).toJS;
  //              ^
  // [web] Calling 'toJS' on a function returning 'Future<T>' requires 'T' to be a subtype of 'JSAny?' or 'void'.
  badFunc.toJSCaptureThis;
  //      ^
  // [web] Calling 'toJS' on a function returning 'Future<T>' requires 'T' to be a subtype of 'JSAny?' or 'void'.
  badFunc2.toJSCaptureThis;
  //       ^
  // [web] Calling 'toJS' on a function returning 'Future<T>' requires 'T' to be a subtype of 'JSAny?' or 'void'.
  badFunc3.toJSCaptureThis;
  //       ^
  // [web] Function converted via 'toJSCaptureThis' contains invalid types in its function signature: '*FutureOr<JSObject>* Function()'.
  badFunc4.toJSCaptureThis;
  //       ^
  // [web] Calling 'toJS' on a function returning 'Future<T>' requires 'T' to be a subtype of 'JSAny?' or 'void'.
  (() async => 3).toJSCaptureThis;
  //              ^
  // [web] Calling 'toJS' on a function returning 'Future<T>' requires 'T' to be a subtype of 'JSAny?' or 'void'.
}
