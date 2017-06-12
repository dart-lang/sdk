// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 20776. Tests that the needed classes for the
// constant map in the metadata are generated.

library lib;

@MirrorsUsed(targets: 'lib')
import 'dart:mirrors';

class C {
  final x;
  const C(this.x);
}

@C(const {'foo': 'bar'})
class A {}

main() {
  print(reflectClass(A).metadata);
}
