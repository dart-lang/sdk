// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import 'constructor12_lib.dart';

main() {
  var a = confuse(new A<int>(1));
  var a2 = confuse(new A(2));
  var b = confuse(new B(3));
  Expect.equals(2, a.foo());
  Expect.equals(3, a2.foo());
  Expect.equals(3, b.foo());
  Expect.equals(1, a.z);
  Expect.equals(2, a2.z);
  Expect.equals(3, b.z);
  Expect.isTrue(a is A<int>);
  Expect.isFalse(a is A<String>);
  Expect.isFalse(a2 is A<int>);
  Expect.isFalse(a2 is A<String>);
  // TODO(nshahan) Move back from constructor12_strong_test.dart after ending
  // support for weak mode.
  // Expect.isFalse(a2 is A<Object>);
  Expect.isTrue(a2 is A<Object?>);
  Expect.equals(2, a.bar());
  Expect.equals(3, a2.bar());
  Expect.equals(3, a.foo());
  Expect.equals(4, a2.foo());
  Expect.equals(0, a.typedList.length);
  Expect.equals(0, a2.typedList.length);
  a.typedList.add(499);
  Expect.equals(1, a.typedList.length);
  Expect.equals(0, a2.typedList.length);
  Expect.isTrue(a.typedList is List<int>);
  Expect.isFalse(a2.typedList is List<int>);
  Expect.isFalse(a.typedList is List<String>);
  Expect.isFalse(a2.typedList is List<String>);
}
