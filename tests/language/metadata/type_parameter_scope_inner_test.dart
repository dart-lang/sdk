// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that metadata on a type parameter cannot refer to declarations in an
// inner scope.  See https://github.com/dart-lang/language/issues/1790.

class Annotation {
  const Annotation(dynamic d);
}

class Class<@Annotation(foo) T> {
//                      ^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Undefined name 'foo'.
  static void foo() {}
}

void function<@Annotation(foo) T>(dynamic foo) {
//                        ^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Undefined name 'foo'.
  dynamic foo;
}

extension Extension<@Annotation(foo) T> on Class<T> {
//                              ^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Undefined name 'foo'.
  static void foo() {}

  void extensionMethod<@Annotation(foo) T, @Annotation(bar) U>() {}
  //                                                   ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
  // [cfe] Undefined name 'bar'.
}

class C {
  void method<@Annotation(foo) T, @Annotation(bar) U>(dynamic foo) {
  //                      ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
  // [cfe] Undefined name 'foo'.
    dynamic foo;
  }

  static void bar() {}
}

mixin Mixin<@Annotation(foo) T> {
//                      ^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Undefined name 'foo'.
  static void foo() {}
}

typedef Typedef<@Annotation(foo) T> = void Function<foo>();
//                          ^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Undefined name 'foo'.
