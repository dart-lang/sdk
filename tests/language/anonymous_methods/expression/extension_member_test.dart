// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Anonymous methods in extension members.
// SharedOptions=--enable-experiment=anonymous-methods

import 'package:expect/expect.dart';
import '../../static_type_helper.dart';

extension on int {
  int get g1 => this + '$this'.=> this.length;
  int get g2 => this + '$this'.=> length;

  bool m1() {
    final i = () { return this + '$this'.=> length + length; }();
    return i.isEven;
  }

  bool m2() {
    final i = this + '$this'.=> () { return length + length; }();
    return i.isEven;
  }
}

void main() {
  Expect.equals(2, 1.g1);
  Expect.equals(2, 1.g2);
  Expect.equals(false, 1.m1());
  Expect.equals(false, 1.m2());
}
