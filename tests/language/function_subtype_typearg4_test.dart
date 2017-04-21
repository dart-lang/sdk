// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping of type arguments.

import 'package:expect/expect.dart';

class C<T> {}

class I {}

class J extends I {}

typedef I f1();
typedef J f2();

main() {
  Expect.isTrue(new C<f1>() is C<f2>);
}
