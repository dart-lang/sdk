// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that type inference uses type arguments provided by
// instantiate to bound in type annotations to infer the type arguments of the
// corresponding constructor invocations.

class A<T extends num> {}

main() {
  A a = new A();
}
