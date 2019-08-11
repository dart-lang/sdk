// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// The test checks that type arguments of the target of redirection factory
// constructors are preserved.

import 'package:expect/expect.dart';

class A {
  const factory A() = B<String>;
  const A.empty();
}

class B<T> extends A {
  const B() : super.empty();

  toString() => '${T}';
}

void main() {
  Expect.equals("${const A()}", "String");
}
