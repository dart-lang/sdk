// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=checked-implicit-downcasts

/// WARNING
///
/// Not all of the expectations in this test match the language specification.
///
/// This is part of a set of tests covering "callable objects". Please consider
/// them all together when making changes:
///
/// ```
/// tests/lib/js/static_interop_test/call_getter_test.dart
/// tests/lib/js/static_interop_test/call_method_test.dart
/// ```
///
/// This test was created with expectations that match the current behavior to
/// make it more clear when something changes and when the results in the web
/// compilers differ.
///
/// If your change causes an expectation to fail you should decide if the
/// new result is desirable and update the expectation accordingly.

import 'dart:js_interop';

import 'package:expect/expect.dart';

import 'call_utils.dart';

@JS('jsFunction')
external JSFunction get jsFunctionAsJSFunction;

@JS('jsObject')
external JSFunction get jsObjectAsJSFunction;

@JS('jsClass')
external JSFunction get jsClassAsJSFunction;

extension on JSFunction {
  @JS('call')
  external String _call(JSAny? self, String s);

  String Function(String) get call => (String s) => _call(globalContext, s);
}

extension type ExtOnJSObject._(JSObject _) {
  @JS('call')
  external String _call(String s);

  String Function(String) get call => (String s) => _call(s);
}

@JS('jsFunction')
external ExtOnJSObject get jsFunctionAsExtOnJSObject;

@JS('jsObject')
external ExtOnJSObject get jsObjectAsExtOnJSObject;

@JS('jsClass')
external ExtOnJSObject get jsClassAsExtOnJSObject;

extension type ExtOnJSObject2._(JSObject _) {
  external JSFunction get call;
}

@JS('jsFunction')
external ExtOnJSObject2 get jsFunctionAsExtOnJSObject2;

@JS('jsObject')
external ExtOnJSObject2 get jsObjectAsExtOnJSObject2;

@JS('jsClass')
external ExtOnJSObject2 get jsClassAsExtOnJSObject2;

extension type ExtOnJSFunction._(JSFunction _) {
  external JSFunction get call;
}

@JS('jsFunction')
external ExtOnJSFunction get jsFunctionAsExtOnJSFunction;

@JS('jsObject')
external ExtOnJSFunction get jsObjectAsExtOnJSFunction;

@JS('jsClass')
external ExtOnJSFunction get jsClassAsExtOnJSFunction;

void main() {
  injectJS();
  testJSFunction();
  testExtOnJSObject();
  testExtOnJSObject2();
  testExtOnJSFunction();
  testAsDynamic();
}

void testJSFunction() {
  var obj = jsFunctionAsJSFunction;
  Expect.equals('C',
      (obj.callAsFunction(globalContext, 'Cello'.toJS) as JSString).toDart);
  Expect.equals('C', obj.call('Cello'));
  Expect.equals('C', (obj.call)('Cello'));

  if (dart2wasm) {
    obj = jsObjectAsJSFunction;
    Expect.throws(() => obj.callAsFunction(globalContext, 'Cello'.toJS));
    Expect.throws(() => obj.call('Cello'));
    Expect.throws(() => (obj.call)('Cello'));
  } else {
    Expect.throwsTypeError(() => jsObjectAsJSFunction);
  }

  if (dart2wasm) {
    obj = jsClassAsJSFunction;
    Expect.throws(() => obj.callAsFunction(globalContext, 'Cello'.toJS));
    Expect.throws(() => obj.call('Cello'));
    Expect.throws(() => (obj.call)('Cello'));
  } else {
    Expect.throwsTypeError(() => jsClassAsJSFunction);
  }
}

void testExtOnJSObject() {
  var obj = jsFunctionAsExtOnJSObject;
  Expect.throws(
      () => obj.call('Cello'), dart2wasm ? null : jsArgIsNotStringCheck);
  Expect.throws(
      () => (obj.call)('Cello'), dart2wasm ? null : jsArgIsNotStringCheck);

  obj = jsObjectAsExtOnJSObject;
  Expect.equals('C', obj.call('Cello'));
  Expect.equals('C', (obj.call)('Cello'));

  obj = jsClassAsExtOnJSObject;
  Expect.equals('C', obj.call('Cello'));
  Expect.equals('C', (obj.call)('Cello'));
}

void testExtOnJSObject2() {
  var obj = jsFunctionAsExtOnJSObject2;
  Expect.throws(() =>
      obj.call.callAsFunction(globalContext, globalContext, 'Cello'.toJS));

  obj = jsObjectAsExtOnJSObject2;
  Expect.equals(
      'C',
      (obj.call.callAsFunction(globalContext, 'Cello'.toJS) as JSString)
          .toDart);

  obj = jsClassAsExtOnJSObject2;
  Expect.equals(
      'C',
      (obj.call.callAsFunction(globalContext, 'Cello'.toJS) as JSString)
          .toDart);
}

void testExtOnJSFunction() {
  var obj = jsFunctionAsExtOnJSFunction;
  Expect.throws(() => obj.call.callAsFunction(globalContext, 'Cello'.toJS));

  if (dart2wasm) {
    obj = jsObjectAsExtOnJSFunction;
    Expect.equals(
        'C',
        (obj.call.callAsFunction(globalContext, 'Cello'.toJS) as JSString)
            .toDart);
  } else {
    Expect.throwsTypeError(() => jsObjectAsExtOnJSFunction);
  }

  if (dart2wasm) {
    obj = jsClassAsExtOnJSFunction;
    Expect.equals(
        'C',
        (obj.call.callAsFunction(globalContext, 'Cello'.toJS) as JSString)
            .toDart);
  } else {
    Expect.throwsTypeError(() => jsClassAsExtOnJSFunction);
  }
}

testAsDynamic() {
  dynamic d = confuse(jsFunctionAsJSFunction);
  if (dart2wasm) {
    Expect.throwsNoSuchMethodError(() => d.call('Fosse'));
  } else {
    Expect.equals('F', d.call('Fosse'));
  }
  if (ddc) {
    Expect.equals('F', (d.call)('Fosse'));
  } else {
    Expect.throwsNoSuchMethodError(() => (d.call)('Fosse'));
  }
  if (dart2wasm) {
    Expect.throwsNoSuchMethodError(() => d('Fosse'));
  } else {
    Expect.equals('F', d('Fosse'));
  }

  d = confuse(jsObjectAsExtOnJSObject);
  Expect.throwsNoSuchMethodError(() => d.call('Fosse'));
  if (ddc) {
    Expect.equals('F', (d.call)('Fosse'));
  } else {
    Expect.throwsNoSuchMethodError(() => (d.call)('Fosse'));
  }
  Expect.throwsNoSuchMethodError(() => d('Fosse'));

  d = confuse(jsClassAsExtOnJSObject);
  Expect.throwsNoSuchMethodError(() => d.call('Fosse'));
  if (ddc) {
    Expect.throws(() => (d.call)('Fosse'), jsThisIsNullCheck);
  } else {
    Expect.throwsNoSuchMethodError(() => (d.call)('Fosse'));
  }
  Expect.throwsNoSuchMethodError(() => d('Fosse'));
}
