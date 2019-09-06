// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=extension-methods

// Tests extension method resolution failures.

import "package:expect/expect.dart";

main() {
  A a = C();
  B1 b1 = C();
  B2 b2 = C();
  C c = C();

  Expect.equals("EA.v1", a.v1);
  Expect.equals("EB1.v1", b1.v1);
  Expect.equals("EB2.v1", b2.v1);
  Expect.equals("EC.v1", c.v1);

  Expect.equals("EA.v2", a.v2);
  Expect.equals("EB1.v2", b1.v2);
  Expect.equals("EB2.v2", b2.v2);
  c // Cannot determine which of EB1 and EB2's v2 is more specific
    .v2 //# 01: compile-time error
  ;

  Expect.equals("EA.v3", a.v3);
  Expect.equals("EA.v3", b1.v3);
  Expect.equals("EA.v3", b2.v3);
  Expect.equals("EA.v3", c.v3);


  Iterable<num> i_num = <int>[];
  Iterable<int> ii = <int>[];
  List<num> ln = <int>[];
  List<int> li = <int>[];

  i_num // No `i_num` extension declared.
    .i_num //# 02: compile-time error
  ;

  Expect.equals("Iterable<int>.i_num", ii.i_num);
  Expect.equals("List<num>.i_num", ln.i_num);

  li // Both apply, neither is more specific.
    .i_num //# 03: compile-time error
  ;

  c // no most specific because both are equally specific.
    .cs //# 04: compile-time error
  ;
}

// Diamond class hierarchy.
class A {}
class B1 implements A {}
class B2 implements A {}
class C implements B1, B2 {}

extension EA on A {
  String get v1 => "EA.v1";
  String get v2 => "EA.v2";
  String get v3 => "EA.v3";
}

extension EB1 on B1 {
  String get v1 => "EB1.v1";
  String get v2 => "EB1.v2";
}

extension EB2 on B2 {
  String get v1 => "EB2.v1";
  String get v2 => "EB2.v2";
}

extension EC on C {
  String get v1 => "EC.v1";
}

// Iterable<num>, Iterable<int>, List<num> and List<int> also forms diamond
// hierarchy.
extension II on Iterable<int> {
  String get i_num => "Iterable<int>.i_num";
}

extension LN on List<num> {
  String get i_num => "List<num>.i_num";
}

// Two exactly identical `on` types.
extension C1 on C {
  String get cs => "C1.cs";
}

extension C2 on C {
  String get cs => "C2.cs";
}
