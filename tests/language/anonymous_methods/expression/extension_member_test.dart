// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Anonymous methods in extension members.
// SharedOptions=--enable-experiment=anonymous-methods

import 'package:expect/expect.dart';

extension on int {
  int get g1 => this + '$this'.=> this.length;
  int get g2 => this + '$this'.=> length;

  bool m1() {
    final i = () { return this + '$this'.=> this.length + length; }();
    return i.isEven;
  }

  bool m2() {
    final i = this + '$this'.=> () { return this.length + length; }();
    return i.isEven;
  }

  bool m3() {
    final String? receiver = '$this';
    final i = (receiver?.=> () { return this.length + length; }()) ?? -1;
    return i.isEven;
  }

  bool m4() {
    int i = -1;
    '$this'..=> () { i = this.length + length; }();
    return i.isEven;
  }

  bool m5() {
    final String? receiver = '$this';
    int i = -1;
    receiver?..=> () { i = this.length + length; }();
    return i.isEven;
  }
}

void main() {
  Expect.equals(2, 1.g1);
  Expect.equals(2, 1.g2);
  Expect.equals(false, 1.m1());
  Expect.equals(false, 1.m2());
  Expect.equals(true, 1.m3());
  Expect.equals(true, 1.m4());
  Expect.equals(true, 1.m5());
}
