// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  int? field;
  int? bar(int? x) {}
}

main() {
  Foo foo = new Foo();
  foo.field = 5;
  foo.bar(6);

  test_nullable_function_type_formal_param(f: () => 2);
}

int test_nullable_function_type_formal_param({int f()?: null}) {
  return f?.call() ?? -1;
}
