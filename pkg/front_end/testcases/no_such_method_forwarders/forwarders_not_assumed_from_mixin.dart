// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the noSuchMethod forwarder is not assumed to be mixed
// in and is generated for classes that mix in a user-defined noSuchMethod and
// have an abstract method.

abstract class I {
  void foo();
}

class A implements I {
  dynamic noSuchMethod(Invocation i) => null;
}

class B extends Object with A {}

main() {}
