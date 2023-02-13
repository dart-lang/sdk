// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that private members of classes from other libraries don't
// cause generation of noSuchMethod forwarders.

library private;

import './private_module.dart' show Fisk;

abstract class Foo {
  dynamic noSuchMethod(Invocation invocation) => 42;
}

class Bar extends Foo implements Fisk {}

class Baz extends Foo implements Fisk {
  _hest() => null;
}

main() {}
