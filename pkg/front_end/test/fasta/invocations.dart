// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  print("Hello, World!");
  z("Hello, World!");
  z.print("Hello, World!");
  y.z.print("Hello, World!");
  x.y.z.print("Hello, World!");

  1 + print("Hello, World!") + z("Hello, World!") + z.print("Hello, World!")
      + y.z.print("Hello, World!") + x.y.z.print("Hello, World!");
}
