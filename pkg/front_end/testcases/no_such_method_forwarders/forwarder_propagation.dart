// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks that the noSuchMethod forwarders inserted into a class aren't
// re-inserted in its children.

import './forwarder_propagation_lib.dart';

abstract class A {
  void set foo(int value);
  int get bar;
  void baz(int x, {String y, double z});
}

class B implements A {
  noSuchMethod(_) {}
}

class C extends B {}

class E implements D {}

class F extends E {}

main() {}
