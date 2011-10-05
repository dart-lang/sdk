// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import java.io.IOException;
import java.util.List;

/**
 * Tests for binary expression optimizations.
 */
public class JsBinaryExprOptTest extends ExprOptTest {

  public void testLiteralExpressions() throws IOException {
    String js = compileSingleUnit(getName());
    List<String> lines = findMarkerLines(js);

    assertEquals("0 = 1 + 1", lines.get(0));
    assertEquals("1 = 1 - 1", lines.get(1));
    assertEquals("2 = 1 * 1", lines.get(2));
    assertEquals("3 = 1 / 1", lines.get(3));
    // we can't inline % as dart uses euclidean 'module'. Inlining % has the same semantics
    // if operands are non-negative, but will have different semantics if operands are negative.
    assertEquals("4 = MOD$operator(1, 1)", lines.get(4));

    assertEquals("5 = 1 > 1", lines.get(5));
    assertEquals("6 = 1 < 1", lines.get(6));
    assertEquals("7 = 1 >= 1", lines.get(7));
    assertEquals("8 = 1 <= 1", lines.get(8));

    assertEquals("9 = 1 === 1", lines.get(9));
    assertEquals("10 = 1 !== 1", lines.get(10));

    assertEquals("11 = true === false", lines.get(11));
    assertEquals("12 = true !== false", lines.get(12));

    assertEquals("13 = TRUNC$operator(1, 2)", lines.get(13));

    assertEquals("14 = 1 | 1", lines.get(14));
    assertEquals("15 = 1 & 1", lines.get(15));
    assertEquals("16 = 1 << 1", lines.get(16));
    assertEquals("17 = 1 >> 1", lines.get(17));

    assertEquals("18 = true || false", lines.get(18));
    assertEquals("19 = true && false", lines.get(19));

    // i == 0 => i === 0
    assertEquals("20 = i === 0", lines.get(20));

    // i != 0 => i !== 0
    assertEquals("21 = i !== 0", lines.get(21));

    // str == 'a' => str === 'a'
    assertEquals("22 = str === 'a'", lines.get(22));

    // str != 'a' => str !== 'a'
    assertEquals("23 = str !== 'a'", lines.get(23));

    // a == b => a === b
    assertEquals("24 = a === b", lines.get(24));

    // a != b => a !== b
    assertEquals("25 = a !== b", lines.get(25));

    // b == a => b.Equals(a) - b overrides equals operator.
    assertEquals("26 = EQ$operator(b, a)", lines.get(26));

    // b != a => b.NotEquals(a) - b overrides equals operator.
    assertEquals("27 = NE$operator(b, a)", lines.get(27));

    // a == null => a == null
    assertEquals("28 = a == null", lines.get(28));

    // a != null => a != null
    assertEquals("29 = a != null", lines.get(29));

    // null == a => a == null
    // We flip lhs and rhs due to v8 issue in which the lhs being null is not as fast as being rhs.
    assertEquals("30 = a == null", lines.get(30));

    // null != a => a != null
    // We flip lhs and rhs due to v8 issue in which the lhs being null is not as fast as being rhs.
    assertEquals("31 = a != null", lines.get(31));

    // b == null => b.Equals($Dart$Null)
    assertEquals("32 = EQ$operator(b, $Dart$Null)", lines.get(32));

    // b != null => b.NotEquals($Dart$Null)
    assertEquals("33 = NE$operator(b, $Dart$Null)", lines.get(33));

    // null == b => b == null
    // We flip lhs and rhs due to v8 issue in which the lhs being null is not as fast as being rhs.
    assertEquals("34 = b == null", lines.get(34));

    // null != b => b != null
    // We flip lhs and rhs due to v8 issue in which the lhs being null is not as fast as being rhs.
    assertEquals("35 = b != null", lines.get(35));

    // i === 0 => i === 0
    assertEquals("36 = i === 0", lines.get(36));

    // i !== 0 => i !== 0
    assertEquals("37 = i !== 0", lines.get(37));

    // str === 'a' => str === 'a'
    assertEquals("38 = str === 'a'", lines.get(38));

    // str !== 'a' => str !== 'a'
    assertEquals("39 = str !== 'a'", lines.get(39));

    // a === b => a === b
    assertEquals("40 = a === b", lines.get(40));

    // a !== b => a !== b
    assertEquals("41 = a !== b", lines.get(41));

    // b === a => b === a
    assertEquals("42 = b === a", lines.get(42));

    // b !== a => b !== a
    assertEquals("43 = b !== a", lines.get(43));

    // a === null => a == null
    assertEquals("44 = a == null", lines.get(44));

    // a !== null => a != null
    assertEquals("45 = a != null", lines.get(45));

    // null === a => a == null
    // We flip lhs and rhs due to v8 issue in which the lhs being null is not as fast as being rhs.
    assertEquals("46 = a == null", lines.get(46));

    // null !== a => a != null
    // We flip lhs and rhs due to v8 issue in which the lhs being null is not as fast as being rhs.
    assertEquals("47 = a != null", lines.get(47));

    // b === null => b == null
    assertEquals("48 = b == null", lines.get(48));

    // b !== null => b != null
    assertEquals("49 = b != null", lines.get(49));

    // null === b => b == null
    // We flip lhs and rhs due to v8 issue in which the lhs being null is not as fast as being rhs.
    assertEquals("50 = b == null", lines.get(50));

    // null !== b => b != null
    // We flip lhs and rhs due to v8 issue in which the lhs being null is not as fast as being rhs.
    assertEquals("51 = b != null", lines.get(51));

    // str === null => str === null
    assertEquals("52 = str == null", lines.get(52));

    // str !== null => str != null
    assertEquals("53 = str != null", lines.get(53));

    // null === str => str == null
    // We flip lhs and rhs due to v8 issue in which the lhs being null is not as fast as being rhs.
    assertEquals("54 = str == null", lines.get(54));

    // null !== str => str != null
    // We flip lhs and rhs due to v8 issue in which the lhs being null is not as fast as being rhs.
    assertEquals("55 = str != null", lines.get(55));

    // null == null => null == null
    assertEquals("56 = null == null", lines.get(56));

    // null === null => null === null
    assertEquals("57 = null == null", lines.get(57));

    // false == null => false == null
    assertEquals("58 = false == null", lines.get(58));

    // false === null => false === null
    assertEquals("59 = false == null", lines.get(59));

    // str == null => str == null
    assertEquals("60 = str == null", lines.get(60));

    // str != null => str != null
    assertEquals("61 = str != null", lines.get(61));

    // null == str => str == null
    // We flip lhs and rhs due to v8 issue in which the lhs being null is not as fast as being rhs.
    assertEquals("62 = str == null", lines.get(62));

    // null != strl => str != null
    // We flip lhs and rhs due to v8 issue in which the lhs being null is not as fast as being rhs.
    assertEquals("63 = str != null", lines.get(63));
  }
}
