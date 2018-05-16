// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the noSuchMethod forwarder is generated in cases when
// the user-defined noSuchMethod is inherited by classes with abstract methods.

class M {
  dynamic noSuchMethod(Invocation invocation) => null;
}

class A extends M {
  void call(String s);
}

main() {}
