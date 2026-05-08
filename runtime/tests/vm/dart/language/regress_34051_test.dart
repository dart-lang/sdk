// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  // This is a regression test for http://dartbug.com/34051.

  // Warm-up the subtype cache with a "(int) -> int" closure.
  Expect.isTrue(fooClosure(partialInst(gen)));

  // Test that the generic "(T) -> T" closure raises a type error.
  Expect.throwsTypeError(() => fooClosure(gen));
}

FI partialInst(FI arg) => arg;

T gen<T>(T a) => a;

final dynamic fooClosure = foo;
bool foo(FI arg) => arg is FI;

typedef FI = int Function(int);
