// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.common.base.Joiner;
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
     // rethrow is an error outside a catch block
     String rethrow =
       "  m() {\n" +
       "    try {\n" +
       "    }\n" +
       "    catch (var e) {\n" +
       "      throw;\n" +
       "    }\n" +
       "  }\n";
     testClassMemeber(rethrow);

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
          "  factory Array() {\n  }\n" +
          "}\n" +
          "\n");
   }

   public void testClassWithFactoryParameterized() {
     same(
          "// unit testcode\n" +
          "class c<E> {\n" +
          "\n" +
          "  factory Array() {\n  }\n" +
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

   public void testArrayLiteral() {
     same(Joiner.on("\n").join(
         "// unit testcode",
         "var m = [1, 2, 3];",
         ""));
     same(Joiner.on("\n").join(
         "// unit testcode",
         "var m = <int>[1, 2, 3];",
         ""));
   }

   public void testMapLiteral() {
     same(Joiner.on("\n").join(
         "// unit testcode",
         "var m = {\"a\" : 1, \"b\" : 2, \"c\" : 3};",
         ""));
     same(Joiner.on("\n").join(
         "// unit testcode",
         "var m = <int>{\"a\" : 1, \"b\" : 2, \"c\" : 3};",
         ""));
   }

   private void same(String sourceCode) {
     // Some of the syntax we are testing is only valid in a system library
     DartUnit unit = parseUnitAsSystemLibrary("testcode", sourceCode);
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
