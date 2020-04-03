// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method({int a = 42, required int b, required final int c}) {}

class Class {
  method(
      {int a = 42,
      required int b,
      required final int c,
      required covariant final int d}) {}
}

// TODO(johnniwinther): Pass the required property to the function types.
typedef Typedef1 = Function({int a, required int b});

typedef Typedef2({int a, required int b});

Function({int a, required int b}) field = ({int a = 42, required int b}) {};

abstract class A {
  // It's ok to omit the default values in abstract members.
  foo({int x});
}

class B extends A {
  // This is an implementation and it should have the default value.
  foo({x}) {}
}

class C extends A {
  foo({x = 42}) {}
}

ok() {
  Function({int a, required int b}) f;
  void g({int a = 42, required int b}) {}
  f = ({int a = 42, required int b}) {};

  Function(int a, [int b]) f2;
  void g2(int a, [int b = 42]) {}
  f2 = (int a, [int b = 42]) {};
}

error() {
  Function({int a, required int b}) f;
  void g({int a, required int b = 42}) {}
  f = ({int a, required int b = 42}) {};

  Function(int a = 42, [int b]) f2;
  void g2(int a = 42, [int b]) {}
  f2 = (int a = 42, [int b]) {};
}

main() {}
