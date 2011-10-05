// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import java.io.IOException;

/**
 * Tests for binary expression optimizations.
 */
public class JsUnaryExprOptTest extends ExprOptTest {
  private static final String DELIMETERS = "[;\\(\\) ]";

  /**
   * Test that unary operations on integers are not mangled into operator invocations.
   */
  public void testUnaryDecIncExprOpt() throws IOException {
    String js = compileSingleUnit(getName());

    // Ensure that ++_marker_0 remains ++_marker_0 on simple assignment
    String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_0", DELIMETERS, 2);
    assertEquals("++_marker_0", findMarkerAtOccurrence);

    // Ensure that _marker_1++ remains _marker_1++ when used in a for loop
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_1", DELIMETERS, 3);
    assertEquals("_marker_1++", findMarkerAtOccurrence);

    // Ensure that --_marker_0 remains --_marker_0 on simple assignment
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_0", DELIMETERS, 3);
    assertEquals("--_marker_0", findMarkerAtOccurrence);

    // Ensure that _marker_2-- remains _marker_2-- when used in a for loop
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_2", DELIMETERS, 3);
    assertEquals("_marker_2--", findMarkerAtOccurrence);

    // Ensure that parameter _marker_3 remains as _marker_3++
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_3", DELIMETERS, 2);
    assertEquals("_marker_3++", findMarkerAtOccurrence);

    // Ensure that parameter _marker_3 remains as --_marker_3
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_3", DELIMETERS, 3);
    assertEquals("--_marker_3", findMarkerAtOccurrence);

    // Ensure bit op is inlined (variable).
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_4", DELIMETERS, 2);
    assertEquals("~_marker_4", findMarkerAtOccurrence);

    // Ensure bit op is inlined (parameter).
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_3", DELIMETERS, 4);
    assertEquals("~_marker_3", findMarkerAtOccurrence);

    // Ensure bit op is inlined (field).
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "field_0", DELIMETERS, 1);
    assertEquals("~a.field_0$field", findMarkerAtOccurrence);

    // Ensure bit not op is not inlined if operand is untyped.
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_5", "[\n;]", 2);
    assertEquals("_marker_5 = BIT_NOT$operator(foo)", findMarkerAtOccurrence);

    // Ensure bit not op is not inlined if operand is a field with derived abstract field.
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "field_1", "[\n;]", 1);
    assertEquals("i = (tmp$0 = aa , (tmp$0.field_1$setter(tmp$1 = " +
                 "ADD$operator(tmp$0.field_1$getter(), 1)) , tmp$1))",
                 findMarkerAtOccurrence);

    // Ensure bit not op is not inlined if operand is a field with derived abstract field.
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "field_2", "[\n;]", 1);
    assertEquals("i = (tmp$2 = aaa , (tmp$2.field_2$setter(tmp$3 = " +
                 "ADD$operator(tmp$2.field_2$getter(), 1)) , tmp$3))",
                 findMarkerAtOccurrence);
  }
}
