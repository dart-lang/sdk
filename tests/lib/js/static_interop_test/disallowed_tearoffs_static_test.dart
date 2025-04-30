// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

@JS()
external void topLevel();

@JS()
extension type ExtensionType.nonExternal(JSObject _) {
  external ExtensionType();
  external ExtensionType.named();
  external ExtensionType.literal({JSNumber? a});
  external factory ExtensionType.fact();
  external factory ExtensionType.literalFact({JSNumber? a});
  factory ExtensionType.nonExternalFact() => ExtensionType();

  external static void externalStatic();
  static void nonExternalStatic() {}

  external void externalMethod();
  void nonExternalMethod() {}
}

extension on ExtensionType {
  external void externalExtensionMethod();
  void nonExternalExtensionMethod() {}
}

@JS()
@staticInterop
class StaticInterop {
  external factory StaticInterop();
  external factory StaticInterop.named();
  factory StaticInterop.nonExternalFact() => StaticInterop();

  external static void externalStatic();
  static void nonExternalStatic() {}
}

extension on StaticInterop {
  external void externalExtensionMethod();
  void nonExternalExtensionMethod() {}
}

@JS()
@staticInterop
@anonymous
class Anonymous {
  external factory Anonymous({String? a});
  external factory Anonymous.named({String? a});
  factory Anonymous.nonExternalFact() => Anonymous.named(a: '');
}

void testMethods() {
  topLevel;
  // [error column 3]
  // [web] Tear-offs of external top-level member 'topLevel' are disallowed.
  const [topLevel];
  // [error column 3]
  // [web] Tear-offs of external top-level member 'topLevel' are disallowed.

  ExtensionType.externalStatic;
  //            ^
  // [web] Tear-offs of external extension type interop member 'externalStatic' are disallowed.
  const [ExtensionType.externalStatic];
  // [error column 3]
  // [web] Tear-offs of external extension type interop member 'externalStatic' are disallowed.
  ExtensionType.nonExternalStatic;
  final extensionType = ExtensionType();
  extensionType.externalMethod;
  //            ^
  // [web] Tear-offs of external extension type interop member 'externalMethod' are disallowed.
  extensionType.nonExternalMethod;
  extensionType.externalExtensionMethod;
  //            ^
  // [web] Tear-offs of external extension interop member 'externalExtensionMethod' are disallowed.
  extensionType.nonExternalExtensionMethod;

  StaticInterop.externalStatic;
  //            ^
  // [web] Tear-offs of external @staticInterop member 'externalStatic' are disallowed.
  const [StaticInterop.externalStatic];
  // [error column 3]
  // [web] Tear-offs of external @staticInterop member 'externalStatic' are disallowed.
  StaticInterop.nonExternalStatic;
  final staticInterop = StaticInterop();
  staticInterop.externalExtensionMethod;
  //            ^
  // [web] Tear-offs of external extension interop member 'externalExtensionMethod' are disallowed.
  staticInterop.nonExternalExtensionMethod;
}

void testConstructors() {
  ExtensionType.new;
  // [error column 3]
  // [web] Tear-offs of external extension type interop member 'new' are disallowed.
  ExtensionType.named;
  // [error column 3]
  // [web] Tear-offs of external extension type interop member 'named' are disallowed.
  ExtensionType.literal;
  // [error column 3]
  // [web] Tear-offs of external extension type interop member 'literal' are disallowed.
  ExtensionType.nonExternal;
  const [ExtensionType.new];
  // [error column 3]
  // [web] Tear-offs of external extension type interop member 'new' are disallowed.

  ExtensionType.fact;
  // [error column 3]
  // [web] Tear-offs of external extension type interop member 'fact' are disallowed.
  ExtensionType.literalFact;
  // [error column 3]
  // [web] Tear-offs of external extension type interop member 'literalFact' are disallowed.
  ExtensionType.nonExternalFact;
  const [ExtensionType.fact];
  // [error column 3]
  // [web] Tear-offs of external extension type interop member 'fact' are disallowed.

  StaticInterop.new;
  // [error column 3]
  // [web] Tear-offs of external @staticInterop member 'new' are disallowed.
  StaticInterop.named;
  // [error column 3]
  // [web] Tear-offs of external @staticInterop member 'named' are disallowed.
  StaticInterop.nonExternalFact;
  const [StaticInterop.new];
  // [error column 3]
  // [web] Tear-offs of external @staticInterop member 'new' are disallowed.

  Anonymous.new;
  // [error column 3]
  // [web] Tear-offs of external @staticInterop member 'new' are disallowed.
  Anonymous.named;
  // [error column 3]
  // [web] Tear-offs of external @staticInterop member 'named' are disallowed.
  Anonymous.nonExternalFact;
  const [Anonymous.new];
  // [error column 3]
  // [web] Tear-offs of external @staticInterop member 'new' are disallowed.
}

void main() {
  testMethods();
  testConstructors();
}
