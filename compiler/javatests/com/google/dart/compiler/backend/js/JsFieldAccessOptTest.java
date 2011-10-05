// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import java.io.IOException;

/**
 * Tests for binary expression optimizations.
 */
public class JsFieldAccessOptTest extends ExprOptTest {
  private static final String DELIMETERS = "[;\\(\\)= ]";

  private final DollarMangler mangler = new DollarMangler();

  /**
   * Test that unary inc and dec operations on integers are not mangled into operator invocations.
   */
  public void testFieldAccessExprOpt() throws IOException {
    String js = compileSingleUnit(getName());

    // Ensure that _marker_0.x remains _marker_0.x for loads
    String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_0", DELIMETERS, 2);
    assertEquals("_marker_0.x$field", findMarkerAtOccurrence);

    // Ensure that _marker_0.x remains _marker_0.x for stores
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_0", DELIMETERS, 3);
    assertEquals("_marker_0.x$field", findMarkerAtOccurrence);

    // Ensure that _marker_1.x becomes _marker_1.x$setter(1) for stores
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_1", DELIMETERS, 2);
    assertEquals("_marker_1." + mangler.createSetterSyntax("x", null), findMarkerAtOccurrence);

    // Ensure that _marker_1.x becomes _marker_1.x$getter() for loads
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_1", DELIMETERS, 3);
    assertEquals("_marker_1." + mangler.createGetterSyntax("x", null), findMarkerAtOccurrence);

    // var _marker_2 = b.x$field;
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_2", "[;\\n]", 1);
    String[] parts = findMarkerAtOccurrence.split("[=]");
    assertTrue(parts.length == 2);
    assertEquals("b.x$field", parts[1].trim());

    // var _marker_3 = b.x_Getter_WithSideEffect$getter();
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_3", "[;\\n]", 1);
    parts = findMarkerAtOccurrence.split("[=]");
    assertTrue(parts.length == 2);
    assertEquals("b.x_Getter_WithSideEffect$getter()", parts[1].trim());

    // var _marker_4 = b.x_Getter_WithSideEffect$getter();
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_4", "[;\\n]", 1);
    parts = findMarkerAtOccurrence.split("[=]");
    assertTrue(parts.length == 2);
    assertEquals("b.x_Getter_WithSomeExpression$getter()", parts[1].trim());

    // var _marker_5 = b.A_Getter$getter();
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_5", "[;\\n]", 1);
    parts = findMarkerAtOccurrence.split("[=]");
    assertTrue(parts.length == 2);
    assertEquals("b.A_Getter$getter()", parts[1].trim());

    // var _marker_6 = b.X_Getter$getter();
    findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_marker_6", "[;\\n]", 1);
    parts = findMarkerAtOccurrence.split("[=]");
    assertTrue(parts.length == 2);
    assertEquals("b.X_Getter$getter()", parts[1].trim());
  }
}
