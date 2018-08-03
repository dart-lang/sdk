// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that type inference invokes instantiate to bound to provide
// type arguments to constructor invocations in cases when nothing constrains
// the arguments or the invocation.

class A<T extends num> {}

main() {
  new A();
}
