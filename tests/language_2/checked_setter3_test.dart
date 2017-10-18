// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A<T> {
  T field;
}

class B<T> {
  T field = 42 as dynamic;
}

main() {
  var a = new A<String>();
  dynamic s = "string";

  // This assignment is OK.
  a.field = s;

  dynamic i = 42;
  Expect.throwsTypeError(() => a.field = i);

  // Throws because the field initializer fails the implicit cast.
  Expect.throwsTypeError(() => new B<String>());

  // Throws because the assigned value fails the implicit cast.
  var b = new B<int>();
  Expect.throwsTypeError(() => b.field = s);
}
