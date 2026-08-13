// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin class A {
  dynamic noSuchMethod(Invocation inv) {
    return "A";
  }
}

mixin M on A {
  String m1(int v, [String s = "s1"]);

  String m2(int v, {String s});

  String m3(int v, {required String s});

  String m4(int v, [covariant String s]);
}

class MA = A with M;

main() {
  var m1 = MA().m1;
  print(m1(1, "1"));

  var m2 = MA().m2;
  print(m2(1, s: "1"));

  var m3 = MA().m3;
  print(m3(1, s: "1"));

  var m4 = MA().m4;
  print(m4(1, "1"));
}
