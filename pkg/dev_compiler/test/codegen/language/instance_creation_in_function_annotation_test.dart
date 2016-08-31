// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that instance creation expressions inside function
// annotations are properly handled.  See dartbug.com/23354

import 'dart:mirrors';
import 'package:expect/expect.dart';

class C {
  final String s;
  const C(this.s);
}

class D {
  final C c;
  const D(this.c);
}

@D(const C('foo'))
f() {}

main() {
  ClosureMirror closureMirror = reflect(f);
  List<InstanceMirror> metadata = closureMirror.function.metadata;
  Expect.equals(1, metadata.length);
  Expect.equals(metadata[0].reflectee.c.s, 'foo');
}
