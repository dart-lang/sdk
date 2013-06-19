// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'compiler_helper.dart';

const String TEST1 = r"""
main() {
  var a = [42, null];
  return a[0] + 42;
}
""";

const String TEST2 = r"""
main() {
  var a = new List();
  a.add(42);
  a.add(null);
  return a[0] + 42;
}
""";

const String TEST3 = r"""
main() {
  var a = new List(42);
  a[0] = 42;
  return a[0] + 42;
}
""";


main() {
  String generated = compileAll(TEST1);
  // Check that we only do a null check on the receiver for
  // [: a[0] + 42 :]. We can do a null check because we inferred that
  // the list is of type int or null.
  Expect.isFalse(generated.contains('if (typeof t1'));
  Expect.isTrue(generated.contains('if (t1 == null)'));

  generated = compileAll(TEST2);
  Expect.isFalse(generated.contains('if (typeof t1'));
  Expect.isTrue(generated.contains('if (t1 == null)'));

  generated = compileAll(TEST3);
  Expect.isFalse(generated.contains('if (typeof t1'));
  Expect.isTrue(generated.contains('if (t1 == null)'));
}
