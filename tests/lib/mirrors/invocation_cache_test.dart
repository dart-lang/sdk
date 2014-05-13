// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@MirrorsUsed(targets: const ["A"])
import 'dart:mirrors';

import 'package:expect/expect.dart';

class A {
  toString() => "A";
}

main() {
  // The invocation cache must not find the 'toString' from JavaScript's
  // Object.prototype.
  var toString = reflect(new A()).getField(#toString).reflectee;
  Expect.equals("A", Function.apply(toString, [], {}));
}
