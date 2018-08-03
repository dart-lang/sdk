// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class B<T> {}

class A<T> {
  var field;
  A(this.field);
  asTypeVariable() => field as T;
  asBOfT() => field as B<T>;
}

main() {
  Expect.equals(42, new A<int>(42).asTypeVariable());
  Expect.throwsCastError(() => new A<String>(42).asTypeVariable());

  var b = new B<int>();
  Expect.equals(b, new A<int>(b).asBOfT());
  Expect.throwsCastError(() => new A<String>(b).asBOfT());
}
