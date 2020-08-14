// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test requires non-nullable experiment.
// @dart = 2.10

nonConstant() => int.parse('1') == 1;

class A {
  final literal1 = <int>[];
  final literal2 = [1, 2, 3];
  final constLiteral1 = const <int>[];
  final constLiteral2 = const [1, 2];
  final filledFactory1 = List<int>.filled(2, 0);
  final filledFactory2 = List<int>.filled(2, 0, growable: true);
  final filledFactory3 = List<int>.filled(2, 0, growable: false);
  final filledFactory4 = List<int>.filled(2, 0, growable: nonConstant());
  final filledFactory5 = List<int?>.filled(2, null);
  final filledFactory6 = List<int?>.filled(2, null, growable: true);
  final filledFactory7 = List<int?>.filled(2, null, growable: false);
  final filledFactory8 = List<int?>.filled(2, null, growable: nonConstant());
  final generateFactory1 = List<int>.generate(2, (i) => i);
  final generateFactory2 = List<int>.generate(2, (i) => i, growable: true);
  final generateFactory3 = List<int>.generate(2, (i) => i, growable: false);
  final generateFactory4 =
      List<int>.generate(2, (i) => i, growable: nonConstant());
  final generateFactory5 = List<List<int>>.generate(2, (_) => <int>[]);
}

main() {
  A x = A();
  print(x.literal1);
  print(x.literal2);
  print(x.constLiteral1);
  print(x.constLiteral2);
  print(x.filledFactory1);
  print(x.filledFactory2);
  print(x.filledFactory3);
  print(x.filledFactory4);
  print(x.filledFactory5);
  print(x.filledFactory6);
  print(x.filledFactory7);
  print(x.filledFactory8);
  print(x.generateFactory1);
  print(x.generateFactory2);
  print(x.generateFactory3);
  print(x.generateFactory4);
  print(x.generateFactory5);
}
