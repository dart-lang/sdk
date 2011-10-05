// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import java.io.IOException;

/**
 * Tests for binary expression optimizations.
 */
public class JsCompoundBinaryExprOptTest extends ExprOptTest {
  private static final String DELIMETERS = "[\\n,;]";
  private static final String FIELD_DELIMETERS = "[\\n,;.]";

  /**
   * Test that compound binary expressions (+=,-=,*=, /=) on NUMBERIMPLEMENTATION generated as
   * operator invocations.
   */
  public void testCompoundBinaryExprOpt() throws IOException {
    // TODO(zundel): The source for this test compiles but does not execute correctly.
    String js = compileSingleUnit(getName());

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_1", DELIMETERS, 2);
      assertEquals("_marker_1 += _marker_0 + 1", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_2", DELIMETERS, 2);
      assertEquals("_marker_2 -= _marker_0 + 1", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_3", DELIMETERS, 2);
      assertEquals("_marker_3 *= _marker_0 + 1", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_4", DELIMETERS, 2);
      assertEquals("_marker_4 /= _marker_0 + 1", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_5", DELIMETERS, 2);
      assertEquals("_marker_5 += _marker_0 + 1", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_6", DELIMETERS, 2);
      assertEquals("_marker_6 -= _marker_0 + 1", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_7", DELIMETERS, 2);
      assertEquals("_marker_7 *= _marker_0 + 1", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_8", DELIMETERS, 2);
      assertEquals("_marker_8 /= _marker_0 + 1", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_8", DELIMETERS, 2);
      assertEquals("_marker_8 /= _marker_0 + 1", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_a_.Ay_01", DELIMETERS, 1);
      assertEquals("_a_.Ay_01$field++", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_a_.Ay_02", DELIMETERS, 1);
      assertEquals("_a_.Ay_02$field--", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "Ay_03", DELIMETERS, 1);
      assertEquals("_a_.Ay_03$field += 2 * tmp * -123", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "Ay_04", DELIMETERS, 1);
      assertEquals("_a_.Ay_04$field -= 2 * tmp * -123", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "Ay_05", DELIMETERS, 1);
      assertEquals("_a_.Ay_05$field *= 2 * tmp * -123", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "Ay_06", DELIMETERS, 1);
      assertEquals("_a_.Ay_06$field /= 2 * tmp * -123", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "AAAx_01", DELIMETERS, 1);
      assertEquals("_a_.aa_$field.aaa_$field.AAAx_01$field += 2 * tmp / -1",
                   findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "AAAx_02", DELIMETERS, 1);
      assertEquals("_a_.aa_$field.aaa_$field.AAAx_02$field -= 2 * tmp / -1",
                   findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "AAAx_03", DELIMETERS, 1);
      assertEquals("_a_.aa_$field.aaa_$field.AAAx_03$field *= 2 * tmp / -1",
                   findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "AAAx_04", DELIMETERS, 1);
      assertEquals("_a_.aa_$field.aaa_$field.AAAx_04$field /= 2 * tmp / -1",
                   findMarkerAtOccurrence);
    }

    {
      String getter = replaceTemps(findMarkerAtOccurrence(js, "AAAz_01", FIELD_DELIMETERS, 1));
      assertEquals("AAAz_01$getter()", getter);
      String setter = replaceTemps(findMarkerAtOccurrence(js, "AAAz_01", FIELD_DELIMETERS, 2));
      assertEquals("AAAz_01$setter(tmp = ADD$operator(tmp", setter);
    }

    {
      String getter = replaceTemps(findMarkerAtOccurrence(js, "AAAz_02", FIELD_DELIMETERS, 1));
      assertEquals("AAAz_02$getter()", getter);
      String setter = replaceTemps(findMarkerAtOccurrence(js, "AAAz_02", FIELD_DELIMETERS, 2));
      assertEquals("AAAz_02$setter(tmp = ADD$operator(tmp", setter);
    }

    {
      String setter = replaceTemps(findMarkerAtOccurrence(js, "AAAz_03", FIELD_DELIMETERS, 1));
      assertEquals("AAAz_03$setter(tmp = ADD$operator(tmp", setter);
      String getter = replaceTemps(findMarkerAtOccurrence(js, "AAAz_03", FIELD_DELIMETERS, 2));
      assertEquals("AAAz_03$getter()", getter);
    }

    {
      String setter = replaceTemps(findMarkerAtOccurrence(js, "AAAz_04", FIELD_DELIMETERS, 1));
      assertEquals("AAAz_04$setter(tmp = ADD$operator(tmp", setter);
      String getter = replaceTemps(findMarkerAtOccurrence(js, "AAAz_04", FIELD_DELIMETERS, 2));
      assertEquals("AAAz_04$getter()", getter);
    }

    {
      String setter = replaceTemps(findMarkerAtOccurrence(js, "AAAx_06", FIELD_DELIMETERS, 1));
      assertEquals("AAAx_06$setter(tmp = MOD$operator(tmp", setter);
      String getter = replaceTemps(findMarkerAtOccurrence(js, "AAAx_06", FIELD_DELIMETERS, 2));
      assertEquals("AAAx_06$getter()", getter);
    }

    {
      String setter = replaceTemps(findMarkerAtOccurrence(js, "AAAx_07", FIELD_DELIMETERS, 1));
      assertEquals("AAAx_07$setter(tmp = TRUNC$operator(tmp", setter);
      String getter = replaceTemps(findMarkerAtOccurrence(js, "AAAx_07", FIELD_DELIMETERS, 2));
      assertEquals("AAAx_07$getter()", getter);
    }

    String classAAA = compileSingleUnit(getName(), "AAA");
    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(classAAA, "AAAw_01", DELIMETERS, 9);
      assertEquals("this.AAAw_01$field++", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(classAAA, "AAAu_01", DELIMETERS, 9);
      assertEquals("this.AAAu_01$field += a * 123", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_9", DELIMETERS, 2);
      assertEquals("_marker_9 |= _marker_0 & 1", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker__10", DELIMETERS, 2);
      assertEquals("_marker__10 &= _marker_0 & 1", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker__11", DELIMETERS, 2);
      assertEquals("_marker__11 ^= _marker_0 & 1", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker__12", "[\\n;]", 2);
      assertEquals("_marker__12 |= BIT_AND$operator(_var_marker, 1)", findMarkerAtOccurrence);
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_var_marker", "[\\n;]", 3);
      assertEquals("_var_marker = BIT_OR$operator(_var_marker, _marker__12 & 1)",
                   findMarkerAtOccurrence);
    }
  }
}
