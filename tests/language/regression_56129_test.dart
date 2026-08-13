// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

mixin Foo {
  String foo({String? a = 'default'}) => 'Foo.$a';
}

class A extends Object with Foo {
  String foo({String? a}) => 'a.foo(a: $a)';
}

class B extends Object with Foo {
  String foo({String? a}) => super.foo(a: a);
}

void main() {
  final a = A();
  final b = B();
  Expect.equals('a.foo(a: null)', a.foo(a: null));
  Expect.equals('Foo.', b.foo(a: ''));
  Expect.equals('Foo.null', b.foo());
}
