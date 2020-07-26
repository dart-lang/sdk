// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test to ensure that an abstract getter is not mistaken for a field.

class Foo {
//    ^
// [cfe] The non-abstract class 'Foo' is missing implementations for these members:

  // Intentionally abstract:
  get i;
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER
}

class Bar {}

checkIt(f) {
  Expect.throwsNoSuchMethodError(() => f.i = 'hi');
  Expect.throwsNoSuchMethodError(() => print(f.i));
  Expect.throwsNoSuchMethodError(() => print(f.i()));
}

main() {
  checkIt(new Foo());
  checkIt(new Bar());
}
