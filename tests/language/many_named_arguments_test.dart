// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Fisk {
  method(
      {a: 'a',
      b: 'b',
      c: 'c',
      d: 'd',
      e: 'e',
      f: 'f',
      g: 'g',
      h: 'h',
      i: 'i',
      j: 'j',
      k: 'k',
      l: 'l',
      m: 'm',
      n: 'n',
      o: 'o',
      p: 'p',
      q: 'q',
      r: 'r',
      s: 's',
      t: 't',
      u: 'u',
      v: 'v',
      w: 'w',
      x: 'x',
      y: 'y',
      z: 'z'}) {
    return 'a: $a, '
        'b: $b, '
        'c: $c, '
        'd: $d, '
        'e: $e, '
        'f: $f, '
        'g: $g, '
        'h: $h, '
        'i: $i, '
        'j: $j, '
        'k: $k, '
        'l: $l, '
        'm: $m, '
        'n: $n, '
        'o: $o, '
        'p: $p, '
        'q: $q, '
        'r: $r, '
        's: $s, '
        't: $t, '
        'u: $u, '
        'v: $v, '
        'w: $w, '
        'x: $x, '
        'y: $y, '
        'z: $z';
  }
}

main() {
  var method = new Fisk().method;
  var namedArguments = new Map();
  namedArguments[const Symbol('a')] = 'a';
  Expect.stringEquals(
      EXPECTED_RESULT, Function.apply(method, [], namedArguments));
  Expect.stringEquals(
      EXPECTED_RESULT,
      new Fisk().method(
          a: 'a',
          b: 'b',
          c: 'c',
          d: 'd',
          e: 'e',
          f: 'f',
          g: 'g',
          h: 'h',
          i: 'i',
          j: 'j',
          k: 'k',
          l: 'l',
          m: 'm',
          n: 'n',
          o: 'o',
          p: 'p',
          q: 'q',
          r: 'r',
          s: 's',
          t: 't',
          u: 'u',
          v: 'v',
          w: 'w',
          x: 'x',
          y: 'y',
          z: 'z'));
}

const String EXPECTED_RESULT = 'a: a, '
    'b: b, '
    'c: c, '
    'd: d, '
    'e: e, '
    'f: f, '
    'g: g, '
    'h: h, '
    'i: i, '
    'j: j, '
    'k: k, '
    'l: l, '
    'm: m, '
    'n: n, '
    'o: o, '
    'p: p, '
    'q: q, '
    'r: r, '
    's: s, '
    't: t, '
    'u: u, '
    'v: v, '
    'w: w, '
    'x: x, '
    'y: y, '
    'z: z';
