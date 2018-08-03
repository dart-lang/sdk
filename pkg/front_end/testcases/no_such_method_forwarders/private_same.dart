// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that a noSuchMethod forwarder is generated for an inherited
// abstract private member that is declared in the same library as the
// implementor.

abstract class Foo {
  void _foo();
}

class Bar extends Foo {
  dynamic noSuchMethod(Invocation invocation) => null;
}

main() {}
