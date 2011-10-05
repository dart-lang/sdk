// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import java.io.IOException;

/**
 * @author johnlenz@google.com (John Lenz)
 */
public class RttTest extends SnippetTestCase {
  private static final String DELIMETERS = "[\\n,;]";
  // private static final String FIELD_DELIMETERS = "[\\n,;.]";

  public void testRuntimeTypes() throws IOException {
    String js = compileSingleUnit(getName());

    {
      String init = findMarkerAtOccurrence(js, "_marker_B1", DELIMETERS, 1);
      assertEquals("var _marker_B1 = $intern(Test_app4a54ba$B$Dart.B$$Factory())", init);

      String expr = findMarkerAtOccurrence(js, "_marker_B1", DELIMETERS, 2);
      assertEquals("a = _marker_B1 instanceof Test_app4a54ba$B$Dart", expr);
    }

    {
      String init = findMarkerAtOccurrence(js, "_marker_B2", DELIMETERS, 1);
      assertEquals("var _marker_B2 = Test_app4a54ba$B$Dart.B$$Factory()", init);
    }

    {
      String init = findMarkerAtOccurrence(js, "_marker_C1", DELIMETERS, 1);
      assertEquals("var _marker_C1 = $intern("
          + "Test_app4a54ba$C$Dart.C$$Factory("
              + "Test_app4a54ba$C$Dart.$lookupRTT())", init);

      String expr = findMarkerAtOccurrence(js, "_marker_C1", DELIMETERS, 2);
      assertEquals("a = _marker_C1 instanceof Test_app4a54ba$C$Dart", expr);
    }

    {
      String init = findMarkerAtOccurrence(js, "_marker_C2", DELIMETERS, 1);
      assertEquals("var _marker_C2 = $intern(Test_app4a54ba$C$Dart.C$$Factory("
          + "Test_app4a54ba$C$Dart.$lookupRTT([String$Dart.$lookupRTT()]))", init);

      String expr = findMarkerAtOccurrence(js, "_marker_C2", DELIMETERS, 2);
      assertEquals("a = Test_app4a54ba$C$Dart.$lookupRTT([String$Dart.$lookupRTT()])"
          + ".implementedBy(_marker_C2)", expr);
    }

    {
      String init = findMarkerAtOccurrence(js, "_marker_C3", DELIMETERS, 1);
      assertEquals("var _marker_C3 = "
          + "Test_app4a54ba$C$Dart.C$$Factory("
              + "Test_app4a54ba$C$Dart.$lookupRTT())", init);
    }

    {
      String init = findMarkerAtOccurrence(js, "_marker_C4", DELIMETERS, 1);
      assertEquals("var _marker_C4 = "
          + "Test_app4a54ba$C$Dart.C$$Factory("
              + "Test_app4a54ba$C$Dart.$lookupRTT([Object.$lookupRTT()]))", init);

      String expr = findMarkerAtOccurrence(js, "_marker_C4", DELIMETERS, 2);
      assertEquals("a = Test_app4a54ba$C$Dart.$lookupRTT([Object.$lookupRTT()])"
          + ".implementedBy(_marker_C4)", expr);
    }

    {
      String init = findMarkerAtOccurrence(js, "_marker_D1", DELIMETERS, 1);
      assertEquals("var _marker_D1 = Test_app4a54ba$D$Dart.D$$Factory([])", init);

      String expr = findMarkerAtOccurrence(js, "_marker_D1", DELIMETERS, 2);
      assertEquals("a = _marker_D1 instanceof Test_app4a54ba$D$Dart", expr);
    }
  }
}
