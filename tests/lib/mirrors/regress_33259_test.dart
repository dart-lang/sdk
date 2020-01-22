// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/33259.

import 'dart:mirrors';
import 'package:expect/expect.dart';

void main() {
  final foo = reflectClass(Thing).declarations[#foo] as VariableMirror;
  Expect.isTrue(foo.metadata[0].reflectee is Sub);
}

class Thing {
  @Sub()
  String foo = "initialized";
}

class Base<T> {
  const Base();
}

class Sub extends Base<String> {
  const Sub();
}
