// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'issue_34498_lib.dart' as lib;

class A {
  lib.MyClass get lib => null; // (1)

  foo foo() {}

  Missing bar() {}
}

class B extends A {}

final A a = null;

class C<T> {
  T<String> foo() {}
}

main() {}
