// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var foo = main;

main() {
  Expect.equals(main, main);
  Expect.identical(main, main);
  Expect.equals(main.hashCode, main.hashCode);

  Expect.equals(main, foo);
  Expect.identical(main, foo);
  Expect.equals(main.hashCode, foo.hashCode);
}
