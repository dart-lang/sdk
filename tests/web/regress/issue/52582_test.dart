// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=-O1

import 'package:expect/expect.dart';

class A {
  factory A.foo([int x]) = B.foo;
}

class B implements A {
  B.foo([int? x]);
}

void main() {
  final f = A.foo;
  Expect.throws(() => f(), (e) => e is TypeError);
}
