// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import './const_canonical_type_lib.dart' as oo;

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

typedef F1 = oo.A<FutureOr<dynamic>> Function();
typedef F2 = oo.A<dynamic> Function();
typedef F3 = oo.A<FutureOr<FutureOr<dynamic>?>> Function();
typedef F4 = oo.A Function();

test1() {
  const c = oo.A;
  var v = oo.A;

  expectEqual(c, v);
  expectEqual(v, oo.c);
  expectEqual(oo.c, oo.v);
  expectEqual(oo.v, oo.A);
  expectEqual(oo.A, c);

  const cf1 = F1;
  const cf2 = F2;
  const cf3 = F3;
  const cf4 = F4;
  const oocf1 = oo.F1;
  const oocf2 = oo.F2;
  const oocf3 = oo.F3;
  const oocf4 = oo.F4;
  var vf1 = F1;
  var vf2 = F2;
  var vf3 = F3;
  var vf4 = F4;
  var oovf1 = oo.F1;
  var oovf2 = oo.F2;
  var oovf3 = oo.F3;
  var oovf4 = oo.F4;

  expectEqual(cf1, cf2);
  expectEqual(cf2, cf3);
  expectEqual(cf3, cf4);
  expectEqual(cf4, oocf1);
  expectEqual(oocf1, oocf2);
  expectEqual(oocf2, oocf3);
  expectEqual(oocf3, oocf4);
  expectEqual(oocf4, vf1);
  expectEqual(vf1, vf2);
  expectEqual(vf2, vf3);
  expectEqual(vf3, vf4);
  expectEqual(vf4, oovf1);
  expectEqual(oovf1, oovf2);
  expectEqual(oovf2, oovf3);
  expectEqual(oovf3, oovf4);
  expectEqual(oovf4, F1);
  expectEqual(F1, F2);
  expectEqual(F2, F3);
  expectEqual(F3, F4);
  expectEqual(F4, oo.F1);
  expectEqual(oo.F1, oo.F2);
  expectEqual(oo.F2, oo.F3);
  expectEqual(oo.F3, oo.F4);
  expectEqual(oo.F1, cf1);

  const a1 = oo.A<List<F1>>();
  const a2 = oo.A<List<F2>>();
  const a3 = oo.A<List<F3>>();
  const a4 = oo.A<List<F4>>();

  return const <dynamic>[
    Check(c, c),
    Check(c, oo.A),
    Check(oo.A, oo.A),

    Check(cf1, cf2),
    Check(cf2, cf3),
    Check(cf3, cf4),
    Check(cf4, oocf1),
    Check(oocf1, oocf2),
    Check(oocf2, oocf3),
    Check(oocf3, oocf4),
    Check(oocf4, F1),
    Check(F1, F2),
    Check(F2, F3),
    Check(F3, F4),
    Check(F4, oo.F1),
    Check(oo.F1, oo.F2),
    Check(oo.F2, oo.F3),
    Check(oo.F3, oo.F4),
    Check(oo.F4, cf1),

    Check(a1, a2),
    Check(a2, a3),
    Check(a3, a4),
    Check(a4, oo.a1),
    Check(oo.a1, oo.a2),
    Check(oo.a2, oo.a3),
    Check(oo.a3, oo.a4),
    Check(oo.a4, const oo.A<List<F1>>()),
    Check(const oo.A<List<F1>>(), const oo.A<List<F2>>()),
    Check(const oo.A<List<F2>>(), const oo.A<List<F3>>()),
    Check(const oo.A<List<F3>>(), const oo.A<List<F4>>()),
    Check(const oo.A<List<F4>>(), const oo.A<List<oo.F1>>()),
    Check(const oo.A<List<oo.F1>>(), const oo.A<List<oo.F2>>()),
    Check(const oo.A<List<oo.F2>>(), const oo.A<List<oo.F3>>()),
    Check(const oo.A<List<oo.F3>>(), const oo.A<List<oo.F4>>()),
    Check(const oo.A<List<oo.F4>>(), a1),
  ];
}

main() {
  test1();
}
