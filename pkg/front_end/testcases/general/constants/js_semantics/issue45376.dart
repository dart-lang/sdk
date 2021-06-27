// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MyClass {
  final int a;
  final int b;
  const MyClass(i1, i2) : a = (i1 >>> i2), b = (i1 >>> i2);
}

test() {
  const MyClass c1 = MyClass(1.0, 1);
}

main() {}