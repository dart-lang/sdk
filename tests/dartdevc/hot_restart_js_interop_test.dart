// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that JS interop works with hot restart.

// Requirements=nnbd

@JS()
library hot_restart_js_interop_test;

import 'dart:js' show context;
import 'dart:js_util';
import 'dart:_foreign_helper' as helper show JS;
import 'dart:_runtime' as dart;

import 'package:expect/expect.dart';
import 'package:js/js.dart';

@JS()
external void eval(String code);

@JS('window.MyClass')
class MyClass {
  external MyClass();
}

abstract class Wrapper<T> {
  T? rawObject;

  Wrapper() {
    final T defaultObject = createDefault();
    rawObject = defaultObject;
  }

  T createDefault();
}

class WrappedClass extends Wrapper<MyClass> {
  @override
  MyClass createDefault() => MyClass();
}

void main() {
  // See: https://github.com/flutter/flutter/issues/66361
  eval("self.MyClass = function MyClass() {}");
  var c = WrappedClass();
  dart.hotRestart();
  eval("self.MyClass = function MyClass() {}");
  c = WrappedClass();
}
