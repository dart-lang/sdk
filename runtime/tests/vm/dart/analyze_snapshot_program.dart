// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

class MethodChannel {
  final String name;
  const MethodChannel(this.name);

  void dump() {
    print('MethodChannel($name)');
  }
}

final channel1 = MethodChannel("channel1");
final channel2 = MethodChannel("channel2");
const constChannel = MethodChannel("constChannel1");
const constChannel2 = MethodChannel("constChannel2");

class MyBase {
  @pragma('vm:never-inline')
  void foo() => print('foo!');
}

class MyInterface {
  @pragma('vm:never-inline')
  void bar() => print('bar default!');
}

class MySub extends MyBase implements MyInterface {
  @pragma('vm:never-inline')
  void bar() => print('bar override!');
}

final mySub1 = MySub();

main() {
  final mcs = [channel1, channel2, constChannel, constChannel2];
  for (int i = 0; i < mcs.length; ++i) {
    mcs[i].dump();
  }
  print('Class: ${MySub()}');

  mySub1.foo();
  mySub1.bar();

  final l = [
    FieldTestBase(2, 2.2, null, Float32x4.zero(), Float64x2.zero()),
    FieldTestSub<int>(),
    FieldTestSub<double>(),
  ];
  for (final x in l) print(x.foo());
}

class FieldTestBase {
  static int baseS0 = int.parse('1');
  static int baseS1 = int.parse('2');
  int base0;
  double base1;
  Object? base2;
  Float32x4 base3;
  Float64x2 base4;

  FieldTestBase(this.base0, this.base1, this.base2, this.base3, this.base4) {
    baseS0++;
    baseS1++;
  }

  @pragma('vm:never-inline')
  String foo() =>
      'Base.foo: [$baseS0, $baseS1, $base0, $base1, $base2, $base3, $base4]';
}

class FieldTestSub<T> extends FieldTestBase {
  late int subL1 = int.parse('1');
  late final double subL2 = double.parse('1.2');

  FieldTestSub()
    : super(
        1,
        1.2,
        Object(),
        Float32x4(1.1, 1.2, 1.3, 1.4),
        Float64x2(2.1, 2.2),
      );

  @pragma('vm:never-inline')
  String foo() => '${super.foo()} Sub<$T>.foo: [$subL1, $subL2]';
}
