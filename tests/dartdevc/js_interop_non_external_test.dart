// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test non-external factories and static methods of JS interop classes.

@JS()
library js_interop_non_external_test;

import 'package:expect/expect.dart';
import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package
import 'package:js/js.dart';

import 'js_interop_non_external_lib.dart';

@JS()
external dynamic eval(String code);

@JS()
class JSClass {
  external JSClass.cons();
  factory JSClass() {
    field = 'unnamed';
    return JSClass.cons();
  }

  factory JSClass.named() {
    field = 'named';
    return JSClass.cons();
  }

  factory JSClass.redirecting() = JSClass;

  static String field = '';
  static String get getSet {
    return field;
  }

  static set getSet(String val) {
    field = val;
  }

  static String method() => field;

  static T genericMethod<T extends num>(T t) {
    // Do a simple test using T.
    Expect.type<T>(t);
    Expect.notType<T>('');
    return t;
  }
}

@JS('JSClass')
@staticInterop
class StaticInterop {
  external factory StaticInterop();
  factory StaticInterop.named() {
    field = 'named';
    return StaticInterop();
  }

  static String field = '';

  static String method() => field;
}

@JS()
@anonymous
class Anonymous {
  external factory Anonymous();

  factory Anonymous.named() {
    field = 'named';
    return Anonymous();
  }

  static String field = '';

  static String method() => field;
}

void testLocal() {
  // Test field is initialized and modified.
  expect(JSClass.field, '');
  JSClass.field = 'modified';
  expect(JSClass.field, 'modified');

  // Test factories and side-effects to make sure body is executed. Test their
  // tear-offs too.
  JSClass();
  expect(JSClass.field, 'unnamed');
  JSClass.named();
  expect(JSClass.field, 'named');
  JSClass.redirecting();
  expect(JSClass.field, 'unnamed');

  (JSClass.cons)();
  (JSClass.new)();
  expect(JSClass.field, 'unnamed');
  (JSClass.named)();
  expect(JSClass.field, 'named');
  (JSClass.redirecting)();
  expect(JSClass.field, 'unnamed');

  // Test getter and setter.
  expect(JSClass.getSet, JSClass.field);
  JSClass.getSet = 'set';
  expect(JSClass.field, 'set');

  // Test methods and their tear-offs.
  expect(JSClass.method(), JSClass.field);
  expect(JSClass.genericMethod(0), 0);

  expect((JSClass.method)(), JSClass.field);
  expect((JSClass.genericMethod)(0), 0);

  // Briefly check that other interop classes work too.
  expect(StaticInterop.field, '');
  StaticInterop.field = 'modified';
  expect(StaticInterop.field, 'modified');
  StaticInterop.named();
  expect(StaticInterop.field, 'named');
  expect(StaticInterop.method(), StaticInterop.field);

  expect(Anonymous.field, '');
  Anonymous.field = 'modified';
  expect(Anonymous.field, 'modified');
  Anonymous.named();
  expect(Anonymous.field, 'named');
  expect(Anonymous.method(), Anonymous.field);
}

// Run the same tests as `testLocal`, but with a class in a different library,
// and with class type args.
void testNonLocal() {
  expect(OtherJSClass.field, '');
  OtherJSClass.field = 'modified';
  expect(OtherJSClass.field, 'modified');

  OtherJSClass<int>(0);
  expect(OtherJSClass.field, 'unnamed');
  OtherJSClass.named(0);
  expect(OtherJSClass.field, 'named');
  OtherJSClass<double>.redirecting(0.1);
  expect(OtherJSClass.field, 'unnamed');

  (OtherJSClass.cons)(0);
  (OtherJSClass<int>.new)(0);
  expect(OtherJSClass.field, 'unnamed');
  (OtherJSClass.named)(0);
  expect(OtherJSClass.field, 'named');
  (OtherJSClass<double>.redirecting)(0.1);
  expect(OtherJSClass.field, 'unnamed');

  expect(OtherJSClass.getSet, OtherJSClass.field);
  OtherJSClass.getSet = 'set';
  expect(OtherJSClass.field, 'set');

  expect(OtherJSClass.method(), OtherJSClass.field);
  expect(OtherJSClass.genericMethod(0), 0);

  expect((OtherJSClass.method)(), OtherJSClass.field);
  expect((OtherJSClass.genericMethod)(0), 0);
}

void main() {
  eval('''
    function JSClass(arg) {}
  ''');
  testLocal();
  testNonLocal();
}
