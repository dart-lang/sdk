// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping for null.

import 'package:expect/expect.dart';

typedef int Foo(bool a, [String b]);
typedef int Bar<T>(T a, [String b]);

main() {
  Expect.isFalse(null is Foo, 'null is Foo');
  Expect.isFalse(null is Bar<bool>, 'null is Bar<bool>');
  Expect.isFalse(null is Bar, 'null is Bar');
}
