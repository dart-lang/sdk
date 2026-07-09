// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that only one noSuchMethod forwarder is generated in case of
// multiple abstract methods with the same signature being declared in the
// implemented interfaces.

abstract class I1 {
  void foo();
}

abstract class I2 {
  void foo();
}

class M implements I1, I2 {
  dynamic noSuchMethod(Invocation i) => null;
}

main() {}
