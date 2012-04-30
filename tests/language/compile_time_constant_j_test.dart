// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final field;
  const A() : field = 499;
}

final x = (((1 + 2)));
final y = (((((x)))));
final z = (((const A())));

main() {
  Expect.equals(3, x);
  Expect.equals(3, y);
  Expect.equals(499, z.field);
}
