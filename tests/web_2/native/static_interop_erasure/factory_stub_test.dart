// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that factory methods with bodies are stubbed correctly in static interop
// type erasure.

@JS()
library factory_stub_test;

import 'dart:_interceptors' show JavaScriptObject;

import 'package:js/js.dart';

import '../native_testing.dart' hide JS;
import '../native_testing.dart' as native_testing;
import 'factory_stub_lib.dart';

NativeClass makeNativeClass() native;

@Native('NativeClass')
class NativeClass extends JavaScriptObject {
  factory NativeClass() => makeNativeClass();
}

@JS('NativeClass')
@staticInterop
class StaticNativeClass {
  external factory StaticNativeClass();
  factory StaticNativeClass.redirectingFactory() = StaticNativeClass;
  factory StaticNativeClass.simpleFactory() => StaticNativeClass();
  factory StaticNativeClass.factoryWithParam(
          StaticNativeClass staticNativeClass) =>
      staticNativeClass;
  // This and `StaticNativeClassCopy.nestedFactory` exist to ensure that we
  // cover the case where invocations on factories are visible before their
  // declarations in the AST. This will test whether we correctly create the
  // stub even if we haven't visited the declaration yet. It will also test the
  // case where stubs need to be added before function bodies are visited so
  // that mutually recursive factories can resolve.
  factory StaticNativeClass.nestedFactory({bool callCopyFactory = false}) {
    if (callCopyFactory) StaticNativeClassCopy.nestedFactory();
    return StaticNativeClass();
  }
}

void main() {
  nativeTesting();
  native_testing.JS('', r'''
    (function(){
      function NativeClass() {}
      self.NativeClass = NativeClass;
      self.makeNativeClass = function(){return new NativeClass()};
      self.nativeConstructor(NativeClass);
    })()
  ''');
  applyTestExtensions(['NativeClass']);

  // Make the Native class live.
  NativeClass();
  // Invoke factories and ensure they're typed correctly through assignment.
  StaticNativeClass staticNativeClass = StaticNativeClass.redirectingFactory();
  staticNativeClass = StaticNativeClass.simpleFactory();
  staticNativeClass = StaticNativeClass.factoryWithParam(staticNativeClass);
  staticNativeClass = StaticNativeClass.nestedFactory(callCopyFactory: true);
}
