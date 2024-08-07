// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Define a JS class in a different library to test that name resolution works
// for non-external factories and static methods. Also uses class type
// parameters to make sure we generate a generic class.

@JS()
library js_interop_non_external_lib;

import 'package:expect/expect.dart';
import 'package:js/js.dart';

@JS('JSClass')
class OtherJSClass<T extends num> {
  external OtherJSClass.cons(T t);
  factory OtherJSClass(T t) {
    // Do a simple test using T.
    Expect.type<T>(t);
    Expect.notType<T>('');
    field = 'unnamed';
    return OtherJSClass.cons(t);
  }

  factory OtherJSClass.named(T t) {
    // Do a simple test using T.
    Expect.type<T>(t);
    Expect.notType<T>('');
    field = 'named';
    return OtherJSClass.cons(t);
  }

  factory OtherJSClass.redirecting(T t) = OtherJSClass;

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
