// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for F-Bounded Quantification.

import "package:expect/expect.dart";

class A<T extends B<T>> {}

class B<T> extends A {}

main() {
  Expect.equals("B<B>", new B<B>().runtimeType.toString());
}
