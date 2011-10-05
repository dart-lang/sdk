// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.ast.DartToSourceVisitor;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.util.DefaultTextOutput;

/**
 * Tests, for each of the parser test examples, that {@link DartToSourceVisitor} produces
 * something parseable. It's an imperfect test, as it doesn't account for semantic changes,
 * but it catches a lot of common problems.
 */
public class ParserRoundTripTest extends CompilerTestCase {

  public void testClasses() {
    roundTrip("ClassesInterfaces.dart");
  }

  public void testMethodSignatures() {
    roundTrip("MethodSignatures.dart");
  }

  public void testFunctionTypes() {
    roundTrip("FunctionTypes.dart");
  }

  public void testFormalParameters() {
    roundTrip("FormalParameters.dart");
  }

  public void testSuperCalls() {
    roundTrip("SuperCalls.dart");
  }

  public void testGenericTypes() {
    roundTrip("GenericTypes.dart");
  }

  public void testShifting() {
    roundTrip("Shifting.dart");
  }

  public void testFunctionInterfaces() {
    roundTrip("FunctionInterfaces.dart");
  }

  public void testStringBuffer() {
    roundTrip("StringBuffer.dart");
  }

  public void testListObjectLiterals() {
    roundTrip("ListObjectLiterals.dart");
  }

  public void testCatchFinally() {
    roundTrip("CatchFinally.dart");
  }

  public void testStrings() {
    roundTrip("Strings.dart");
  }

  /**
   * Ensures that a unit can be parsed, re-serialized, and re-parsed without error.
   */
  private void roundTrip(String path) {
    DartUnit unit = parseUnit(path);

    DefaultTextOutput out = new DefaultTextOutput(false);
    new DartToSourceVisitor(out, false).accept(unit);
    String src = out.toString();
    parseUnit(path, src);
  }
}
