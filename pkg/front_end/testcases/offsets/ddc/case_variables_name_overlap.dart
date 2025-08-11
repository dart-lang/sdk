// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void method(o) {
  switch (o) {
    case X1(
        :var s,
        :var i,
        :var d,
      ):
      print("hello X1($s, $i, $d)");
    case X2(
        :var s2,
        :var i,
        :var d,
      ):
      print("hello X2($s2, $i, $d)");
  }
}

class X1 {
  String? s;
  int? i;
  double? d;
}

class X2 {
  String? s2;
  int? i;
  double? d;
}
