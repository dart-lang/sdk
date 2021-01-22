// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

class Check {
  final _ignored;

  const Check(x, y)
      : assert(identical(x, y)),
      _ignored = identical(x, y) ? 42 : 1 ~/ 0;
}

void expectEqual(x, y) {
  if (x != y) {
    throw "Arguments were supposed to be identical.";
  }
}

class A<X> {
  const A();
}

typedef F1 = A<FutureOr<dynamic>> Function();
typedef F2 = A<dynamic> Function();
typedef F3 = A<FutureOr<FutureOr<dynamic>?>> Function();
typedef F4 = A Function();

test1() {
  const c = A;
  var v = A;

  expectEqual(c, c);
  expectEqual(c, A);
  expectEqual(A, A);
  expectEqual(v, v);
  expectEqual(v, A);

  const cf1 = F1;
  const cf2 = F2;
  const cf3 = F3;
  const cf4 = F4;
  var vf1 = F1;
  var vf2 = F2;
  var vf3 = F3;
  var vf4 = F4;

  expectEqual(cf1, cf2);
  expectEqual(cf2, cf3);
  expectEqual(cf3, cf4);
  expectEqual(cf4, vf1);
  expectEqual(vf1, vf2);
  expectEqual(vf2, vf3);
  expectEqual(vf3, vf4);

  const a1 = A<List<F1>>();
  const a2 = A<List<F2>>();
  const a3 = A<List<F3>>();
  const a4 = A<List<F4>>();

  return const <dynamic>[
    Check(c, c),
    Check(c, A),
    Check(A, A),

    Check(cf1, cf2),
    Check(cf2, cf3),
    Check(cf3, cf4),

    Check(a1, a2),
    Check(a2, a3),
    Check(a3, a4),
    Check(a4, const A<List<F1>>()),
    Check(const A<List<F1>>(), const A<List<F2>>()),
    Check(const A<List<F2>>(), const A<List<F3>>()),
    Check(const A<List<F3>>(), const A<List<F4>>()),
    Check(const A<List<F4>>(), a1),
  ];
}

main() {
  test1();
}
