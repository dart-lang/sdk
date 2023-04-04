// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

// Test that you can use top-level and interop class members without a library
// declaration, using `dart:js_interop`'s `@JS`.

import 'dart:js_interop';

@JS()
external JSNumber topLevelField;

@JS()
external JSNumber get topLevelGetter;

@JS()
external set topLevelSetter(JSNumber _);

@JS()
external void topLevelMethod();

@JS()
inline class InlineClass {
  final JSObject obj;
  external InlineClass();

  external JSNumber field;
  external JSNumber get getter;
  external set setter(JSNumber _);
  external JSVoid method();

  external static JSNumber staticField;
  external static JSNumber get staticGetter;
  external static set staticSetter(JSNumber _);
  external static JSVoid staticMethod();

  @JS()
  external JSNumber annotatedField;
  @JS()
  external JSNumber get annotatedGetter;
  @JS()
  external set annotatedSetter(JSNumber _);
  @JS()
  external JSVoid annotatedMethod();

  @JS()
  external static JSNumber annotatedStaticField;
  @JS()
  external static JSNumber get annotatedStaticGetter;
  @JS()
  external static set annotatedStaticSetter(JSNumber _);
  @JS()
  external static JSVoid annotatedStaticMethod();
}

extension InlineClassExtension on InlineClass {
  external JSNumber extensionField;
  external JSNumber get extensionGetter;
  external set extensionSetter(JSNumber _);
  external JSVoid extensionMethod();

  @JS()
  external JSNumber annotatedExtensionField;
  @JS()
  external JSNumber get annotatedExtensionGetter;
  @JS()
  external set annotatedExtensionSetter(JSNumber _);
  @JS()
  external JSVoid annotatedExtensionMethod();
}

void main() {}
