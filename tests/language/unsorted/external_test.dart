// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Bar {
  Bar(val);
}

class Foo {
//    ^
// [cfe] The non-abstract class 'Foo' is missing implementations for these members:
  var x = -1;
  f() {}

  Foo() : x = 0;
//^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD

  external var x01;
  external int x02;

  external f11() { }
  //             ^
  // [analyzer] SYNTACTIC_ERROR.EXTERNAL_METHOD_WITH_BODY
  // [cfe] An external or native method can't have a body.
  external f12() => 1;
  //             ^^
  // [analyzer] SYNTACTIC_ERROR.EXTERNAL_METHOD_WITH_BODY
  // [cfe] An external or native method can't have a body.
  //                ^
  // [cfe] An external or native method can't have a body.
  static external f14();
  //     ^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.MODIFIER_OUT_OF_ORDER
  // [cfe] The modifier 'external' should be before the modifier 'static'.
  int external f16();
  //  ^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
  //  ^
  // [cfe] Field 'external' should be initialized because its type 'int' doesn't allow null.
  //           ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER

  external Foo.n21(val) : x = 1;
  //                    ^
  // [analyzer] SYNTACTIC_ERROR.EXTERNAL_CONSTRUCTOR_WITH_INITIALIZER
  // [cfe] An external constructor can't have any initializers.
  external Foo.n22(val) { x = 1; }
  //                    ^
  // [analyzer] SYNTACTIC_ERROR.EXTERNAL_METHOD_WITH_BODY
  // [cfe] An external or native method can't have a body.
  external factory Foo.n23(val) => new Foo();
  //                            ^^
  // [analyzer] SYNTACTIC_ERROR.EXTERNAL_FACTORY_WITH_BODY
  // [cfe] External factories can't have a body.
  //                               ^
  // [cfe] An external or native method can't have a body.
  external Foo.n24(this.x);
  //                    ^
  // [cfe] An external constructor can't initialize fields.
  external factory Foo.n25(val) = Bar;
  //                            ^
  // [analyzer] SYNTACTIC_ERROR.EXTERNAL_FACTORY_REDIRECTION
  // [cfe] A redirecting factory can't be external.
  //                              ^^^
  // [analyzer] COMPILE_TIME_ERROR.REDIRECT_TO_INVALID_RETURN_TYPE
  // [cfe] The constructor function type 'Bar Function(dynamic)' isn't a subtype of 'Foo Function(dynamic)'.
}

external int t06(int i) { return 1; }
// [error line 71, column 1, length 8]
// [analyzer] SYNTACTIC_ERROR.EXTERNAL_METHOD_WITH_BODY
// [cfe] An external or native method can't have a body.
//                      ^
// [cfe] An external or native method can't have a body.
external int t07(int i) => i + 1;
// [error line 77, column 1, length 8]
// [analyzer] SYNTACTIC_ERROR.EXTERNAL_METHOD_WITH_BODY
// [cfe] An external or native method can't have a body.
//                         ^
// [cfe] An external or native method can't have a body.

main() {
  // Ensure Foo class is compiled.
  var foo = new Foo();

  new Foo().f11();
  new Foo().f12();
  Foo.f14();
  new Foo().f16();

  new Foo.n21(1);
  new Foo.n22(1);
  new Foo.n23(1);
  new Foo.n24(1);
  new Foo.n25(1);

  t06(1);
  t07(1);
}
