// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import java.io.IOException;

/**
 * Tests for closure optimizations.
 */
public class JsClosureExprOptTest extends ExprOptTest {
  public void testClosureOpt() throws IOException {
    String js = compileSingleUnit(getName(), "A");

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_fn_0", ";", 1);
      assertTrue(findMarkerAtOccurrence.contains("$bind0_2"));
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_fn_1", ";", 1);
      assertTrue(findMarkerAtOccurrence.contains("$bind0_3"));
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_fn_2", ";", 1);
      assertTrue(findMarkerAtOccurrence.contains("$bind0_4"));
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_fn_3", ";", 1);
      assertTrue(findMarkerAtOccurrence.contains("$bind0_5"));
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_fn_4", ";", 1);
      assertTrue(findMarkerAtOccurrence.contains("$bind("));
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_fn_5", ";", 1);
      assertTrue(findMarkerAtOccurrence.contains("$bind1_2"));
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_fn_6", ";", 1);
      assertTrue(findMarkerAtOccurrence.contains("$bind2_2"));
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_fn_7", ";", 1);
      assertTrue(findMarkerAtOccurrence.contains("$bind3_2"));
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_fn_8", ";", 1);
      assertTrue(findMarkerAtOccurrence.contains("$bind("));
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_fn_9", ";", 1);
      assertTrue(findMarkerAtOccurrence.contains("$bind1_3"));
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_fn_A", ";", 1);
      assertTrue(findMarkerAtOccurrence.contains("$bind2_4"));
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_fn_B", ";", 1);
      assertTrue(findMarkerAtOccurrence.contains("$bind3_5"));
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_fn_C", ";", 1);
      assertTrue(findMarkerAtOccurrence.contains("$bind("));
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_fn_D", ";", 1);
      assertTrue(findMarkerAtOccurrence.contains("$bind("));
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_fn_E", ";", 1);
      assertTrue(findMarkerAtOccurrence.contains("$bind1_3"));
      assertTrue(findMarkerAtOccurrence.contains("this"));
    }

    {
      String findMarkerAtOccurrence = findMarkerAtOccurrence(js, "_fn_F", ";", 1);
      assertTrue(findMarkerAtOccurrence.contains("$bind2_3"));
    }
  }
}
