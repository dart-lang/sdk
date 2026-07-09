// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for issue #48442. We can do eager initialization of static variables
// with initializers containing map literals only when the we know the keys have
// implementations of `get:hashCode` known to be free of side-effects and
// without dependencies on other static variables that may not yet exist.

import 'package:expect/expect.dart';

String witness = 'none';

class Foo {
  const Foo();
  int get hashCode {
    witness = 'hashCode';
    return Object.hash(0, 1);
  }

  bool operator ==(other) => other is Foo;
}

const key = Foo();

// This map creation calls Foo.hashCode. In #48442, `map` was initialized
// eagerly, which crashed in `Object.hash` due to an uninitialized `_hashSeed`
// variable in the runtime.
final map = {key: "value"};

void main() {
  Expect.equals('none', witness);
  print(map);
  Expect.equals('hashCode', witness);
}
