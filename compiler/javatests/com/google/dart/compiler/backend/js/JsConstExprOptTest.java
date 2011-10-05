// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import java.io.IOException;

/**
 * Tests for binary expression optimizations.
 */
public class JsConstExprOptTest extends ExprOptTest {

  public void testConstantExprOpt() throws IOException {
    String js = compileSingleUnit(getName());

    {
      String marker = findMarkerAtOccurrence(js, "_marker_0", "[\\n;]", 2);
      assertEquals("_marker_0 = 50 * 2", marker);
    }

    {
      String marker = findMarkerAtOccurrence(js, "_marker_1", "[\\n;]", 2);
      assertEquals("_marker_1 = 10 + 5 * 2 + 5", marker);
    }

    {
      String marker = findMarkerAtOccurrence(js, "_marker_2", "[\\n;]", 2);
      assertEquals("_marker_2 = 5 + 5", marker);
    }

    // Cant inline array.
    {
      String marker = findMarkerAtOccurrence(js, "_marker_3", "[\\n;]", 2);
      assertEquals("_marker_3 = 5 + Test_app4a54ba$A$Dart.ARRAY$getter()"
          + "[$inlineArrayIndexCheck(Test_app4a54ba$A$Dart.ARRAY$getter(), 0)]", marker);
    }

    // Cant bind constants that refer to methods
    {
      String marker = findMarkerAtOccurrence(js, "_marker_4", "[\\n;]", 2);
      assertEquals("_marker_4 = Test_app4a54ba$A$Dart.C3$getter()", marker);
    }

    // Cant bind constants that instantiate objects.
    {
      String marker = findMarkerAtOccurrence(js, "_marker_5", "[\\n;]", 2);
      assertEquals("_marker_5 = Test_app4a54ba$A$Dart.C4$getter()", marker);
    }
  }
}
