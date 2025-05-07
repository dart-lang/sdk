// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from tests/language/metadata/type_parameter_scope_inner_test.dart

class Annotation {
  const Annotation(dynamic d);
}

class Class<@Annotation(foo) T> {
  static void foo() {}
}

void function<@Annotation(foo) T>(dynamic foo) {
  dynamic foo;
}

extension Extension<@Annotation(foo) T> on Class<T> {
  static void foo() {}

  void extensionMethod<@Annotation(foo) T, @Annotation(bar) U>() {}
}

class C {
  void method<@Annotation(foo) T, @Annotation(bar) U>(dynamic foo) {
    dynamic foo;
  }

  static void bar() {}
}

mixin Mixin<@Annotation(foo) T> {
  static void foo() {}
}

typedef Typedef<@Annotation(foo) T> = void Function<foo>();
