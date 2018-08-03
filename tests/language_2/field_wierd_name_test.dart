// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing setting/getting of instance fields.

import "package:expect/expect.dart";

// dart2js used to have a bug where a local called '_' in the constructor
// shadowed the parameter named after a field. This lead to the field being
// initialized to 'this' (a cycle) rather than the correct initializer value.
//
// This test is in the language tests rather than dart2js specific tests since
// the dart2js specific tests are not run in all configurations that could
// tickle this issue.

int ii = 0;

class Thing {
  var _;
  var $_;
  // Extra fields to make use of local in constructor beneficial and to exhaust
  // single-character names.
  var a = ++ii, b = ++ii, c = ++ii, d = ++ii, e = ++ii;
  var f = ++ii, g = ++ii, h = ++ii, i = ++ii, j = ++ii;
  var k = ++ii, l = ++ii, m = ++ii, n = ++ii, o = ++ii;
  var p = ++ii, q = ++ii, r = ++ii, s = ++ii, t = ++ii;
  var u = ++ii, v = ++ii, w = ++ii, x = ++ii, y = ++ii;
  var z = ++ii;
  var A = ++ii, B = ++ii, C = ++ii, D = ++ii, E = ++ii;
  var F = ++ii, G = ++ii, H = ++ii, I = ++ii, J = ++ii;
  var K = ++ii, L = ++ii, M = ++ii, N = ++ii, O = ++ii;
  var P = ++ii, Q = ++ii, R = ++ii, S = ++ii, T = ++ii;
  var U = ++ii, V = ++ii, W = ++ii, X = ++ii, Y = ++ii;
  var Z = ++ii;
  var $ = ++ii;

  var f30 = ++ii, f31 = ++ii, f32 = ++ii, f33 = ++ii, f34 = ++ii;
  var f35 = ++ii, f36 = ++ii, f37 = ++ii, f38 = ++ii, f39 = ++ii;
  var f40 = ++ii, f41 = ++ii, f42 = ++ii, f43 = ++ii, f44 = ++ii;
  var f45 = ++ii, f46 = ++ii, f47 = ++ii, f48 = ++ii, f49 = ++ii;
  var f50 = ++ii, f51 = ++ii, f52 = ++ii, f53 = ++ii, f54 = ++ii;
  var f55 = ++ii, f56 = ++ii, f57 = ++ii, f58 = ++ii, f59 = ++ii;

  @NoInline()
  Thing(this._, this.$_);
  toString() {
    if (depth > 0) return 'recursion!';
    try {
      ++depth;
      var sum = a +
          b +
          c +
          d +
          e +
          f +
          g +
          h +
          i +
          j +
          k +
          l +
          m +
          n +
          o +
          p +
          q +
          r +
          s +
          t +
          u +
          v +
          w +
          x +
          y +
          z +
          A +
          B +
          C +
          D +
          E +
          F +
          G +
          H +
          I +
          J +
          K +
          L +
          M +
          N +
          O +
          P +
          Q +
          R +
          S +
          T +
          U +
          V +
          W +
          X +
          Y +
          Z +
          $ +
          f30 +
          f31 +
          f32 +
          f33 +
          f34 +
          f35 +
          f36 +
          f37 +
          f38 +
          f39 +
          f40 +
          f41 +
          f42 +
          f43 +
          f44 +
          f45 +
          f46 +
          f47 +
          f48 +
          f49 +
          f50 +
          f51 +
          f52 +
          f53 +
          f54 +
          f55 +
          f56 +
          f57 +
          f58 +
          f59;
      return 'Thing(${_}, ${$_}, ${sum})';
    } finally {
      --depth;
    }
  }

  static int depth = 0;
}

main() {
  var t1 = new Thing(1, 2);
  var t2 = new Thing(3, 4);
  var t3 = [];

  Expect.equals(
      '[Thing(1, 2, 3486), Thing(3, 4, 10375), []]', '${[t1, t2, t3]}');
}
