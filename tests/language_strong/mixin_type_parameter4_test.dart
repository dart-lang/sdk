// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class R<E, F> {}

class M<J> implements R<bool, J> {}

class B1 {}

class B2 {}

class A1<T> extends B1 with M<T> {}

class A2<T> = B2 with M<T>;

main() {
  var a1 = new A1<int>();
  Expect.isTrue(a1 is R<bool, int>);
  var a2 = new A2<int>();
  Expect.isTrue(a2 is R<bool, int>);
}
