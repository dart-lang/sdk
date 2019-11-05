// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class D<X extends void Function()> {
  factory D.foo() => new D._();
  D._() {}
}

main() {
  print(new D.foo());
}