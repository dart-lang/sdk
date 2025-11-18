// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It's a compile-time error if the shorthand context does not denote a
// declaration and static namespace.

// SharedOptions=--enable-experiment=dot-shorthands

Function getFunction() {
  return .new();
  //     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_ABSTRACT_CLASS
  //      ^
  // [cfe] The class 'Function' is abstract and can't be instantiated.
}

// Even though this is a factory constructor, we still don't allow type
// arguments in the dot shorthand constructor.

abstract class Foo<T> {
  factory Foo.a() = _Foo;
  Foo();
}

class _Foo<T> extends Foo<T> {
  _Foo();
}

Foo<T> bar<T>() => .a<T>();
//                  ^
// [cfe] A dot shorthand constructor invocation can't have type arguments.
//                   ^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR
