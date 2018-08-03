// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class B {
  m(int v) => v + 42;
}

abstract class C extends B {
  m(Object v);
}

class D extends C {
  m(Object v) => 'hi $v!';
}

/// Regression test for https://github.com/dart-lang/sdk/issues/30927, DDC used
/// to use the incorrect signature for D.m.
main() {
  dynamic d = new D();
  // Make sure we dispatch using the type signature for D.m, not B.m
  Expect.equals(d.m('world'), 'hi world!');
}
