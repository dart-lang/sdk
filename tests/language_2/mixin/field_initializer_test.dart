// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing throw statement

import 'package:expect/expect.dart';

class S {
  var s1 = good_stuff();
  static good_stuff() => "Speyburn";
}

good_stuff() => "Glenfiddich";

class M {
  var m1 = good_stuff();
  static good_stuff() => "Macallen";
}

class A extends S with M {
  static good_stuff() => "Ardberg";
}

main() {
  var a = new A();
  Expect.equals("Macallen", a.m1);
  Expect.equals("Speyburn", a.s1);

  var m = new M();
  Expect.equals("Macallen", m.m1);
}
