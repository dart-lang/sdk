// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that metadata can be located everywhere the grammar specifies that
// it can occur, with a few variants especially for parameter locations.

@m
library metadata.location.test;

@m
import 'dart:async';

@m
export 'dart:async';

@m
part 'metadata_location_part.dart';

@m
const m = 0;

@m
void f1(@m p1, @m int p2, [@m p3, @m int? p4]) {}

@m
void f2({@m p1, @m int? p2}) {}

@m
void f3(@m p1(), @m int p2()) {}

@m
class C {
  @m
  var x, y, z, w;

  @m
  covariant var u, v;

  @m
  C(@m this.x, @m int this.y,
      {@m this.z, @m int? this.w, @m this.u()?, @m int this.v()?});

  @m
  void f1(@m p1, @m int p2, [@m p3, @m int? p4]) {}

  @m
  void f2({@m p1, @m int? p2}) {}

  @m
  void f3(@m covariant p1, @m covariant int p2,
      [@m covariant p3, @m covariant int? p4]) {}

  @m
  void f4({@m covariant p1, @m covariant int? p2}) {}

  @m
  static void f1s(@m p1, @m int p2, [@m p3, @m int? p4]) {}

  @m
  static void f2s({@m p1, @m int? p2}) {}

  @m
  int get prop => 0;

  @m
  set prop(@m int _) {}

  @m
  static int get staticProp => 0;

  @m
  static set staticProp(@m int _) {}

  @m
  bool operator ==(@m other) => true;
}

@m
mixin M {
  @m
  var x, y, z, w, u, v;

  @m
  void f1(@m p1, @m int p2, [@m p3, @m int p4 = 0]) {}

  @m
  void f2({@m p1, @m int p2 = 0}) {}

  @m
  void f3(@m covariant p1, @m covariant int p2,
      [@m covariant p3, @m covariant int p4 = 0]) {}

  @m
  void f4({@m covariant p1, @m covariant int p2 = 0}) {}

  @m
  static void f1s(@m p1, @m int p2, [@m p3, @m int? p4]) {}

  @m
  static void f2s({@m p1, @m int? p2}) {}

  @m
  int get prop => 0;

  @m
  set prop(@m int _) {}

  @m
  static int get staticProp => 0;

  @m
  static set staticProp(@m int _) {}

  @m
  bool operator ==(@m other) => true;
}

@m
extension Extension on int {
  @m
  void f1(@m p1, @m int p2, [@m p3, @m int p4 = 0]) {}

  @m
  void f2({@m p1, @m int p2 = 0}) {}

  @m
  static void f1s(@m p1, @m int p2, [@m p3, @m int? p4]) {}

  @m
  static void f2s({@m p1, @m int? p2}) {}

  @m
  int get prop => 0;

  @m
  set prop(@m int _) {}

  @m
  static int get staticProp => 0;

  @m
  static set staticProp(@m int _) {}
}

@m
enum E {
  @m
  one,
  @m
  two,
}

void f<@m X>() {}

class D<@m X> {}

@m
typedef void F1<@m X>();

@m
typedef F2<@m X>= void Function();

@m
void main() {
  @m
  var x;

  @m
  void f() {}

  for (@m
  int i = 0;
      i < 1;
      i++) {}
  for (@m int i in []) {}
}
