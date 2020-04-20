// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

get b => 499;
@pragma('dart2js:noInline')
get b_noInline => b;
const b0 = 499 is FutureOr<int>;
final b1 = 499 is FutureOr<int>;
get b2 => 499 is FutureOr<int>;
get b3 => b is FutureOr<int>;
get b4 => b_noInline is FutureOr<int>;

get c => 499;
@pragma('dart2js:noInline')
get c_noInline => c;
const c0 = 499 is FutureOr<FutureOr<int>>;
final c1 = 499 is FutureOr<FutureOr<int>>;
get c2 => 499 is FutureOr<FutureOr<int>>;
get c3 => c is FutureOr<FutureOr<int>>;
get c4 => c_noInline is FutureOr<FutureOr<int>>;

get d => 499.0;
@pragma('dart2js:noInline')
get d_noInline => d;
const d0 = 499.0 is FutureOr<int>;
final d1 = 499.0 is FutureOr<int>;
get d2 => 499.0 is FutureOr<int>;
get d3 => d is FutureOr<int>;
get d4 => d_noInline is FutureOr<int>;

get e => 499;
@pragma('dart2js:noInline')
get e_noInline => e;
const e0 = 499 is FutureOr<double>;
final e1 = 499 is FutureOr<double>;
get e2 => 499 is FutureOr<double>;
get e3 => e is FutureOr<double>;
get e4 => e_noInline is FutureOr<double>;

get f => 499;
@pragma('dart2js:noInline')
get f_noInline => f;
const f0 = 499 is FutureOr<FutureOr<double>>;
final f1 = 499 is FutureOr<FutureOr<double>>;
get f2 => 499 is FutureOr<FutureOr<double>>;
get f3 => f is FutureOr<FutureOr<double>>;
get f4 => f_noInline is FutureOr<FutureOr<double>>;

test(fromConst, fromFinal, fromImplicitConstant, fromInlined, fromRuntime) {
  Expect.equals(fromRuntime, fromConst);
  Expect.equals(fromRuntime, fromFinal);
  Expect.equals(fromRuntime, fromInlined);
  Expect.equals(fromRuntime, fromImplicitConstant);
}

main() {
  test(b0, b1, b2, b3, b4);
  test(c0, c1, c2, c3, c4);
  test(d0, d1, d2, d3, d4);
  test(e0, e1, e2, e3, e4);
  test(f0, f1, f2, f3, f4);
}