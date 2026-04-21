// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checking that `this` of an anonymous method can be accessed.
// SharedOptions=--enable-experiment=anonymous-methods

import 'package:expect/expect.dart';
import '../../static_type_helper.dart';

class A {
  final int x = 'first'.=> this.length + length;
  late final int y = this.x + 'second'.=> this.length + length;
  final int z;
  A(String s) : this.z = s.=> this.length + length;
}

extension E on int {
  int get x => 'first'.=> this.length + length;
  int get y => this + 'second'.=> this.length + length;
  static int get z => 'third'.=> this.length + length;
}

void main() {
  final a = A('Hello!');
  Expect.equals(10, a.x);
  Expect.equals(22, a.y);
  Expect.equals(12, a.z);
  Expect.equals(10, 1.x);
  Expect.equals(13, 1.y);
  Expect.equals(10, E.z);
}
