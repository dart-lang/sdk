// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(37452): Avoid using unspecified 'toString' behaviour in language test.

import 'package:expect/expect.dart';

void foo(F f<F>(F f)) {}

B bar<B>(B g<F>(F f)) => null;

Function baz<B>() {
  B foo<F>(F f) => null;
  return foo;
}

class C<T> {
  void foo(F f<F>(T t, F f)) => null;
  B bar<B>(B g<F>(T t, F f)) => null;
  Function baz<B>() {
    B foo<F>(T t, F f) => null;
    return foo;
  }
}

main() {
  expectOne(
    foo.runtimeType.toString(),
    ["(<F>(F) => F) => void", "(<T1>(T1) => T1) => void"],
  );
  expectOne(
    bar.runtimeType.toString(),
    ["<B>(<F>(F) => B) => B", "<T1>(<T2>(T2) => T1) => T1"],
  );
  expectOne(
    baz<int>().runtimeType.toString(),
    ["<F>(F) => int", "<T1>(T1) => int"],
  );

  var c = new C<bool>();
  expectOne(
    c.foo.runtimeType.toString(),
    ["(<F>(bool, F) => F) => void", "(<T1>(bool, T1) => T1) => void"],
  );
  expectOne(
    c.bar.runtimeType.toString(),
    ["<B>(<F>(bool, F) => B) => B", "<T1>(<T2>(bool, T2) => T1) => T1"],
  );
  expectOne(
    c.baz<int>().runtimeType.toString(),
    ["<F>(bool, F) => int", "<T1>(bool, T1) => int"],
  );
}

expectOne(String name, Iterable<String> names) {
  Expect.isTrue(names.contains(name), '"$name" should be one of: ${names}');
}
