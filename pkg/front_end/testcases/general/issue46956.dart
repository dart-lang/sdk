// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

class A<X> {}

Future<X?> foo<X extends Object?>(A<X> x) => throw 42;

bar(String? y) {}

test(A<String> a) async {
  final x = await () async {
    return foo(a);
  }();
  bar(x); // Ok.
}

test2(A<String> a) async {
  return /*@typeArgs=String*/ foo(a);
}

test3(A<String> a) {
  return /*@typeArgs=String*/ foo(a);
}

main() {}
