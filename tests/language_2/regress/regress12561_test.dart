// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C {
  noSuchMethod(int x, int y) => x + y; /*@compile-error=unspecified*/
}

main() {
  Expect.throws(() => new C().foo, (e) => e is Error); /*@compile-error=unspecified*/
}
