// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test `dart:js_interop`'s `isA` method returns the right errors.

import 'dart:js_interop';

extension type NonLiteral._(JSObject o) implements JSObject {}

extension type NonLiteralWithMembers._(JSObject o) implements JSObject {
  external NonLiteralWithMembers();

  external bool field;
  external bool get getter;
  external void setter(bool _);
  external void method();
}

extension type ObjectLiteral._(JSObject o) implements JSObject {
  external ObjectLiteral({int a});
}

extension type BothConstructors._(JSObject o) implements JSObject {
  external BothConstructors({int a});
  external BothConstructors.fact(int a);
}

extension type WrapObjectLiteral._(ObjectLiteral o) implements ObjectLiteral {}

extension type CustomJSString(JSString _) implements JSString {}

void test<T extends JSAny?, U extends NonLiteral>(JSAny? any) {
  any.isA<T>();
  //  ^
  // [web] Type argument 'T' provided to 'isA' cannot be a type variable and must be an interop extension type that can be determined at compile-time.
  any.isA<U>();
  //  ^
  // [web] Type argument 'U' provided to 'isA' cannot be a type variable and must be an interop extension type that can be determined at compile-time.

  final tearoff = 0.toJS.isA;
  //                     ^
  // [web] 'isA' can't be torn off.
  tearoff<JSAny>();
  final tearoffWithTypeParam = 0.toJS.isA<JSNumber>;
  //                                  ^
  // [web] 'isA' can't be torn off.
  tearoffWithTypeParam();
  final tearoffWithGenericTypeParam = 0.toJS.isA<T>;
  //                                         ^
  // [web] 'isA' can't be torn off.
  tearoffWithGenericTypeParam();

  any.isA<NonLiteral>();
  any.isA<NonLiteralWithMembers>();
  any.isA<ObjectLiteral>();
  //  ^
  // [web] Type argument 'ObjectLiteral' has an object literal constructor. Because 'isA' uses the type's name or '@JS()' rename, this may result in an incorrect type check.
  any.isA<BothConstructors>();
  //  ^
  // [web] Type argument 'BothConstructors' has an object literal constructor. Because 'isA' uses the type's name or '@JS()' rename, this may result in an incorrect type check.
  any.isA<WrapObjectLiteral>();

  CustomJSString(''.toJS).isA<CustomJSString>();
  //                      ^
  // [web] Type argument 'CustomJSString' wraps primitive JS type 'JSString', which is specially handled using 'typeof'.
}

void main() {}
