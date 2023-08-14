// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

import 'dart:js_interop';

@JS()
external void topLevel();

@JS()
inline class Inline {
  final JSObject obj;
  external Inline();
  external Inline.named();
  external Inline.literal({JSNumber? a});
  Inline.nonExternal(this.obj);
  // TODO(srujzs): Once we have inline class factories, test these.
  // external factory Inline.fact();
  // external factory Inline.literalFact({JSNumber? a});
  // factory Inline.nonExternalFact() => Inline();

  external static void externalStatic();
  static void nonExternalStatic() {}

  external void externalMethod();
  void nonExternalMethod() {}
}

extension on Inline {
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
//^
// [web] Tear-offs of external top-level member 'topLevel' are disallowed.
  const [topLevel];
//^
// [web] Tear-offs of external top-level member 'topLevel' are disallowed.

  Inline.externalStatic;
  //     ^
  // [web] Tear-offs of external inline class interop member 'externalStatic' are disallowed.
  const [Inline.externalStatic];
//^
// [web] Tear-offs of external inline class interop member 'externalStatic' are disallowed.
  Inline.nonExternalStatic;
  final inline = Inline();
  inline.externalMethod;
  //     ^
  // [web] Tear-offs of external inline class interop member 'externalMethod' are disallowed.
  inline.nonExternalMethod;
  inline.externalExtensionMethod;
  //     ^
  // [web] Tear-offs of external extension interop member 'externalExtensionMethod' are disallowed.
  inline.nonExternalExtensionMethod;

  StaticInterop.externalStatic;
  //            ^
  // [web] Tear-offs of external @staticInterop member 'externalStatic' are disallowed.
  const [StaticInterop.externalStatic];
//^
// [web] Tear-offs of external @staticInterop member 'externalStatic' are disallowed.
  StaticInterop.nonExternalStatic;
  final staticInterop = StaticInterop();
  staticInterop.externalExtensionMethod;
  //            ^
  // [web] Tear-offs of external extension interop member 'externalExtensionMethod' are disallowed.
  staticInterop.nonExternalExtensionMethod;
}

void testConstructors() {
  Inline.new;
//^
// [web] Tear-offs of external inline class interop member 'new' are disallowed.
  Inline.named;
//^
// [web] Tear-offs of external inline class interop member 'named' are disallowed.
  Inline.literal;
//^
// [web] Tear-offs of external inline class interop member 'literal' are disallowed.
  Inline.nonExternal;
  const [Inline.new];
//^
// [web] Tear-offs of external inline class interop member 'new' are disallowed.

  // TODO(srujzs): Once we have factories available, test these.
  // Inline.fact;
  // Inline.literalFact;
  // Inline.nonExternalFact;
  // const [Inline.fact];

  StaticInterop.new;
//^
// [web] Tear-offs of external @staticInterop member 'new' are disallowed.
  StaticInterop.named;
//^
// [web] Tear-offs of external @staticInterop member 'named' are disallowed.
  StaticInterop.nonExternalFact;
  const [StaticInterop.new];
//^
// [web] Tear-offs of external @staticInterop member 'new' are disallowed.

  Anonymous.new;
//^
// [web] Tear-offs of external @staticInterop member 'new' are disallowed.
  Anonymous.named;
//^
// [web] Tear-offs of external @staticInterop member 'named' are disallowed.
  Anonymous.nonExternalFact;
  const [Anonymous.new];
//^
// [web] Tear-offs of external @staticInterop member 'new' are disallowed.
}

void main() {
  testMethods();
  testConstructors();
}
