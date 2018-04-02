// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class F {
  final int value;
  F(this.value);
  call() => value;
  noSuchMethod(Invocation i) {
    if (i.memberName == #call && i.isMethod) {
      return i.positionalArguments[0];
    }
    return super.noSuchMethod(i);
  }
}

main() {
  F f = new F(42);
  // Tears off f.call, fails with nSM (wrong number of arguments).
  Expect.throwsNoSuchMethodError(() => Function.apply(f, ['a', 'b', 'c', 'd']));

  dynamic d = f;
  var result = d('a', 'b', 'c', 'd'); // calls F.noSuchMethod
  Expect.equals('a', result);

  // Tears off f.call, call succeeds
  Expect.equals(42, Function.apply(f, []));
}
