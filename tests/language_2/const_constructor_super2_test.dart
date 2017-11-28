// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  final a;

  const A(this.a);
}

class B extends A {
  final b;

  const B(a, this.b) : super(a);
}

@NoInline()
foo() => const B(1, 2);

@NoInline()
bar() => const B(2, 2);

void main() {
  Expect.notEquals(foo(), bar());
  Expect.notEquals(foo().a, bar().a);
  Expect.equals(foo().b, bar().b);
}
