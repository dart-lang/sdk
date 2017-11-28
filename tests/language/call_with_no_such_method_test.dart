// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class F {
  call() => null;
  noSuchMethod(Invocation i) {
    if (i.memberName == #call && i.isMethod) {
      return i.positionalArguments[0];
    }
    return super.noSuchMethod(i);
  }
}

main() {
  var result = Function.apply(new F(), ['a', 'b', 'c', 'd']);
  Expect.equals('a', result);
}
