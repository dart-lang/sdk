// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for issue #24839 - http://dartbug.com/24839

const u1 = null;
const int u2 = null;
const List u3 = null;
const u4 = const String.fromEnvironment("XXXXX");
const u5 = const int.fromEnvironment("XXXXX");
const u6 = const bool.fromEnvironment("XXXXX", defaultValue: null);
const n1 = 42;
const n2 = 3.1415;
const int n3 = 37;
const double n4 = 4.6692;
const num n5 = b3 ? 1 : 2.71828;
const n6 = const int.fromEnvironment("XXXXX", defaultValue: 87);
const s1 = "s1";
const String s2 = "s2";
const String s3 = "$s1$s2";
const s4 = const String.fromEnvironment("XXXXX", defaultValue: "s4");
const b1 = true;
const b2 = false;
const b3 = b1 && (b2 || !b1);
const b4 = const bool.fromEnvironment("XXXXX", defaultValue: true);

// Individually
const su1 = "$u1";
const su2 = "$u2";
const su3 = "$u3";
const su4 = "$u4";
const su5 = "$u5";
const su6 = "$u6";
const sn1 = "$n1";
const sn2 = "$n2";
const sn3 = "$n3";
const sn4 = "$n4";
const sn5 = "$n5";
const sn6 = "$n6";
const ss1 = "$s1";
const ss2 = "$s2";
const ss3 = "$s3";
const ss4 = "$s4";
const sb1 = "$b1";
const sb2 = "$b2";
const sb3 = "$b3";
const sb4 = "$b4";

// Constant variables in interpolation.
const interpolation1 =
    "$u1 $u2 $u3 $u4 $u5 $u6 $n1 $n2 $n3 $n4 $n5 $n6 $s1 $s2 $s3 $s4 $b1 $b2 $b3 $b4";
// Constant expressions in interpolation.
// (Single string, the linebreak to fit this into 80 chars is inside an
// interpolation, which is allowed, even for single-line strings).
const interpolation2 =
    "${u1} ${u2} ${u3} ${u4} ${u5} ${u6} ${n1} ${n2} ${n3} ${n4} ${n5} ${n6} ${
     s1} ${s2} ${s3} ${s4} ${b1} ${b2} ${b3} ${b4}";
// Adjacent string literals are combined.
const interpolation3 = "$u1 $u2 $u3 $u4 $u5 "
    '$u6 $n1 $n2 $n3 $n4 '
    """$n5 $n6 $s1 $s2 $s3 """
    '''$s4 $b1 $b2 $b3 $b4''';
// Nested interpolations.
const interpolation4 = "${"$u1 $u2 $u3 $u4 $u5 " '$u6 $n1 $n2 $n3 $n4'} ${
     """$n5 $n6 $s1 $s2 $s3 """ '''$s4 $b1 $b2 $b3 $b4'''}";

main() {
  Expect.equals(u1.toString(), su1);
  Expect.equals(u2.toString(), su2);
  Expect.equals(u3.toString(), su3);
  Expect.equals(u4.toString(), su4);
  Expect.equals(u5.toString(), su5);
  Expect.equals(u6.toString(), su6);
  Expect.equals(n1.toString(), sn1);
  Expect.equals(n2.toString(), sn2);
  Expect.equals(n3.toString(), sn3);
  Expect.equals(n4.toString(), sn4);
  Expect.equals(n5.toString(), sn5);
  Expect.equals(n6.toString(), sn6);
  Expect.equals(s1.toString(), ss1);
  Expect.equals(s2.toString(), ss2);
  Expect.equals(s3.toString(), ss3);
  Expect.equals(s4.toString(), ss4);
  Expect.equals(b1.toString(), sb1);
  Expect.equals(b2.toString(), sb2);
  Expect.equals(b3.toString(), sb3);
  Expect.equals(b4.toString(), sb4);
  var expect = "null null null null null null 42 3.1415 37 4.6692 2.71828 87 "
      "s1 s2 s1s2 s4 true false false true";
  Expect.equals(expect, interpolation1);
  Expect.equals(expect, interpolation2);
  Expect.equals(expect, interpolation3);
  Expect.equals(expect, interpolation4);
}
