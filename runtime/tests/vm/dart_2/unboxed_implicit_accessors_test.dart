// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final l = <I>[A(), B(42, 4.2)];
final l2 = <I2>[A2(), B2(42, 4.2)];

main() {
  if (l[0].intValue != 23) throw 'a';
  if (l[0].doubleValue != 2.3) throw 'b';
  if (l[1].intValue != 42) throw 'c';
  if (l[1].doubleValue != 4.2) throw 'd';

  if (l2[0].intValue != null) throw 'a';
  if (l2[0].doubleValue != null) throw 'b';
  if (l2[1].intValue != 42) throw 'c';
  if (l2[1].doubleValue != 4.2) throw 'd';

  if (int.parse('1') == 1) {
    l2[0].intValue = 24;
    l2[0].doubleValue = 2.4;
    l2[1].intValue = 24;
    l2[1].doubleValue = 2.4;
  } else {
    (l2[0] as A2).intValue = null;
    (l2[0] as A2).doubleValue = null;
  }
}

abstract class I {
  int get intValue;
  double get doubleValue;
}

class A implements I {
  int get intValue => 23;
  double get doubleValue => 2.3;
}

class B implements I {
  // Field as well as getter/setter will be unboxed.
  final int intValue;
  // Field as well as getter/setter will be unboxed.
  final double doubleValue;
  B(this.intValue, this.doubleValue);
}

abstract class I2 {
  void set intValue(int v) {}
  void set doubleValue(double v) {}

  int get intValue;
  double get doubleValue;
}

class A2 implements I2 {
  void set intValue(int v) {}
  void set doubleValue(double v) {}

  int get intValue => null;
  double get doubleValue => null;
}

class B2 implements I2 {
  // Field itself will get unboxed, but getter/setter will be boxed.
  int intValue;
  // Field itself will get unboxed, but getter/setter will be boxed.
  double doubleValue;

  B2(this.intValue, this.doubleValue);
}
