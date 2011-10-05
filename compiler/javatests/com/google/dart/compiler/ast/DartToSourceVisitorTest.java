// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.CompilerTestCase;

/**
 * @author johnlenz@google.com (John Lenz)
 */
public class DartToSourceVisitorTest extends CompilerTestCase {
   public void testDartStatements() {
     testStmt("return");
     testStmt("x");
     testStmt("x.y");
     testStmt("x + 1.0");
     testStmt("x.y()");
     testStmt("throw");
     testStmt("throw e");
     testStmt("Array<String> strings");
   }

   public void testStringBackslashEscaping() {
     testStmt("String foo = \" \\\\ \"");
   }

   public void testDartMembers() {
     testClassMemeber(
       "  m() {\n" +
       "  }\n");
     testClassMemeber(
       "  operator negate() {\n" +
       "  }\n");
     // get is mangled
     // testClassMemeber(
     //  "  get f() {\n" +
     //  "  }\n");
   }

   public void testClassWithFactory() {
     same(
          "// unit testcode\n" +
          "class c {\n" +
          "\n" +
          "  factory Array<E>() {\n  }\n" +
          "}\n" +
          "\n");
   }

   public void testNativeClass() {
     same(
          "// unit testcode\n" +
          "class c native \"C\" {\n" +
          "}\n" +
          "\n");
   }

   private void same(String sourceCode) {
     DartUnit unit = parseUnit("testcode", sourceCode);
     String result = unit.toSource();
     assertEquals(sourceCode, result);
   }

   private void testClassMemeber(String stmt) {
     String boilerplated =
       "// unit testcode\n" +
       "class c {\n" +
       "\n" +
       ""+stmt+"" +
       "}\n" +
       "\n";
     same(boilerplated);
   }

   private void testStmt(String stmt) {
     String boilerplated =
       "  m() {\n" +
       "    "+stmt+";\n" +
       "  }\n";
     testClassMemeber(boilerplated);
   }
}
