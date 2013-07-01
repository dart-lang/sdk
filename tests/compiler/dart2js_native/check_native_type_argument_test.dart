// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Check that uninstantiated native classes can be used as type arguments in
// checks.

class A native "A" {
}

class C<T> {}

void setup() native """
function A() {}
makeA = function(){return new A};
""";


main() {
  setup();

  Expect.isTrue(new C() is C<A>);
  Expect.isFalse(new C<int>() is C<A>);
}
