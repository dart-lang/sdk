// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import java.io.IOException;

/**
 * Tests for javascript object construction and initialization.
 */
public class JsConstructorOptTest extends ExprOptTest {

  /**
   * Test javascript object creation and inlining of field in the factory body.
   */
  public void testConstructorOptTest() throws IOException {

    String classAAA = compileSingleUnit(getName(), "AAA");
    // class AAA {
    // int a;
    // int b = 567;
    // AAA(this.a) : this.c = 123 { }
    // int c;
    // int d;
    // }
    {
      // Ensure arguments to constructor are in the same field order definition.
      String params = findMarkerAtOccurrence(classAAA, "p$a$field", "[\\(\\)}]", 1);
      assertEquals("p$a$field, p$b$field, p$c$field, p$d$field", params);

      String init_a = findMarkerAtOccurrence(classAAA, "p$a$field", "[;\\n]", 2);
      assertEquals("this.a$field = p$a$field", init_a);

      String init_b = findMarkerAtOccurrence(classAAA, "p$b$field", "[;\\n]", 2);
      assertEquals("this.b$field = p$b$field", init_b);

      String init_c = findMarkerAtOccurrence(classAAA, "p$c$field", "[;\\n]", 2);
      assertEquals("this.c$field = p$c$field", init_c);

      String init_d = findMarkerAtOccurrence(classAAA, "p$d$field", "[;\\n]", 2);
      assertEquals("this.d$field = p$d$field", init_d);

      String[] bodyLines = getFunctionBody("AAA$$Factory", classAAA);

      assertEquals(8, bodyLines.length);

      String tmp_init_a = bodyLines[0].trim();
      assertEquals("var init$a$field = a;", tmp_init_a);

      String tmp_init_b = bodyLines[1].trim();
      assertEquals("var init$b$field = 567;", tmp_init_b);

      String tmp_init_c = bodyLines[2].trim();
      assertEquals("var init$c$field = 123;", tmp_init_c);

      String tmp_init_d = bodyLines[3].trim();
      assertEquals("var init$d$field = $Dart$Null;", tmp_init_d);

      String newCall = getLine(bodyLines, 4);
      assertEquals("var tmp = new Test_app4a54ba$AAA$Dart(init$a$field, init$b$field, "
          + "init$c$field, init$d$field);", newCall);

      assertTrue(bodyLines[5].indexOf("$lookupRTT()") != -1);

      String ctorCall = getLine(bodyLines, 6);
      assertTrue(ctorCall.indexOf("$Constructor.call") != -1);
    }

    String classBBB = compileSingleUnit(getName(), "BBB");

    // class BBB {
    // int a;
    // int b = 567;
    // int c;
    // BBB(this.a) { }
    // }
    //
    // class CCC extends BBB {
    // int d;
    // CCC(this.d) : super(this.d) { }
    // }
    {
      String[] bodyLines = getFunctionBody("BBB$$Factory", classBBB);

      assertEquals(5, bodyLines.length);

      String line1 = getLine(bodyLines, 0);
      assertEquals("var tmp = new Test_app4a54ba$BBB$Dart;", line1);

      assertTrue(bodyLines[1].indexOf("$lookupRTT()") != -1);

      String initCall = getLine(bodyLines, 2);
      assertTrue(initCall.indexOf("$Initializer.call") != -1);

      String ctorCall = getLine(bodyLines, 3);
      assertTrue(ctorCall.indexOf("$Constructor.call") != -1);

      String returnStmt = getLine(bodyLines, 4);
      assertEquals("return tmp;", returnStmt);
    }

    String classCCC = compileSingleUnit(getName(), "CCC");
    {
      String[] bodyLines = getFunctionBody("CCC$$Factory", classCCC);

      assertEquals(5, bodyLines.length);

      String line1 = getLine(bodyLines, 0);
      assertEquals("var tmp = new Test_app4a54ba$CCC$Dart;", line1);

      assertTrue(bodyLines[1].indexOf("$lookupRTT()") != -1);

      String initCall = getLine(bodyLines, 2);
      assertTrue(initCall.indexOf("$Initializer.call") != -1);

      String ctorCall = getLine(bodyLines, 3);
      assertTrue(ctorCall.indexOf("$Constructor.call") != -1);

      String returnStmt = getLine(bodyLines, 4);
      assertEquals("return tmp;", returnStmt);
    }

    // class DDD {
    // int x;
    // int z;
    // DDD(this.x, [this.z = 123]);
    // }
    {
      String classDDD = compileSingleUnit(getName(), "DDD");
      {
        String[] bodyLines = getFunctionBody("DDD$$Factory", classDDD);
        assertEquals(5, bodyLines.length);
        assertEquals("var tmp = new Test_app4a54ba$DDD$Dart;", getLine(bodyLines, 0));
        assertEquals("tmp.$typeInfo = Test_app4a54ba$DDD$Dart.$lookupRTT();", getLine(bodyLines, 1));
        assertEquals("Test_app4a54ba$DDD$Dart.$Initializer.call(tmp, x, z);", getLine(bodyLines, 2));
        assertEquals("Test_app4a54ba$DDD$Dart.$Constructor.call(tmp, x, z);", getLine(bodyLines, 3));
        assertEquals("return tmp;", getLine(bodyLines, 4));
      }
      {
        String[] bodyLines =
            getFunctionBody("Test_app4a54ba$DDD$Dart.prototype.foo$member", classDDD);
        assertEquals(1, bodyLines.length);
        assertEquals("Test_app4a54ba$DDD$Dart.DDD$$Factory(1, 123);", getLine(bodyLines, 0));
      }
    }
  }

  private static String getLine(String[]lines, int index) {
    return replaceTemps(lines[index].trim());
  }
}
