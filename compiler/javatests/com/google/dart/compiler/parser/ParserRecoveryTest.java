// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.common.base.Joiner;
import com.google.dart.compiler.ast.DartArrayLiteral;
import com.google.dart.compiler.ast.DartBinaryExpression;
import com.google.dart.compiler.ast.DartBooleanLiteral;
import com.google.dart.compiler.ast.DartBreakStatement;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartContinueStatement;
import com.google.dart.compiler.ast.DartDoWhileStatement;
import com.google.dart.compiler.ast.DartExprStmt;
import com.google.dart.compiler.ast.DartFieldDefinition;
import com.google.dart.compiler.ast.DartForInStatement;
import com.google.dart.compiler.ast.DartForStatement;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartIfStatement;
import com.google.dart.compiler.ast.DartImportDirective;
import com.google.dart.compiler.ast.DartIntegerLiteral;
import com.google.dart.compiler.ast.DartLibraryDirective;
import com.google.dart.compiler.ast.DartMapLiteral;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartReturnStatement;
import com.google.dart.compiler.ast.DartSourceDirective;
import com.google.dart.compiler.ast.DartStatement;
import com.google.dart.compiler.ast.DartSwitchStatement;
import com.google.dart.compiler.ast.DartThrowExpression;
import com.google.dart.compiler.ast.DartTryStatement;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartUnqualifiedInvocation;
import com.google.dart.compiler.ast.DartVariable;
import com.google.dart.compiler.ast.DartVariableStatement;
import com.google.dart.compiler.ast.DartWhileStatement;

import java.math.BigInteger;
import java.util.List;

public class ParserRecoveryTest extends AbstractParserTest {

  @Override
  public void testStringsErrors() {
    // Implemented elsewhere
  }

  public void test_incompleteFunctionExpression() {
    DartParserRunner parserRunner = parseSource(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  var v = (AAA a, BB)",
        "}"));
    DartUnit unit = parserRunner.getDartUnit();
    assertEquals(
        Joiner.on("\n").join(
            "// unit test_incompleteFunctionExpression",
            "",
            "main() {",
            "  var v = (AAA a, BB) {",
            "  };",
            "}",
            ""),
        unit.toString());
  }

  public void test_incompleteFunctionExpression_qualifiedType() {
    DartParserRunner parserRunner = parseSource(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  var v = (pref.AAA a, BB)",
        "}"));
    DartUnit unit = parserRunner.getDartUnit();
    assertEquals(
        Joiner.on("\n").join(
            "// unit test_incompleteFunctionExpression_qualifiedType",
            "",
            "main() {",
            "  var v = (pref.AAA a, BB) {",
            "  };",
            "}",
            ""),
        unit.toString());
  }
  
  public void test_incompleteFunctionExpression_typeArguments() {
    DartParserRunner parserRunner = parseSource(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  var v = (AAA<T1, T2<T3, T4>, T5> a, BB)",
        "}"));
    DartUnit unit = parserRunner.getDartUnit();
    assertEquals(
        Joiner.on("\n").join(
            "// unit test_incompleteFunctionExpression_typeArguments",
            "",
            "main() {",
            "  var v = (AAA<T1, T2<T3, T4>, T5> a, BB) {",
            "  };",
            "}",
            ""),
            unit.toString());
  }

  public void testVarOnMethodDefinition() {
    // This syntax is illegal, and should produce errors, but since it is a common error,
    // we want to make sure it produce a valid AST for editor users
    DartUnit unit = parseUnit("phony_var_on_method.dart",
        Joiner.on("\n").join(
            "var f1() { return 1;}",  // Error, use of var on a method
            "class A { ",
            "  var f2() { return 1;}",  // Error, use of var on a method
            "  f3() { return 2; }",
            "}"),
            ParserErrorCode.VAR_IS_NOT_ALLOWED_ON_A_METHOD_DEFINITION, 1, 1,
            ParserErrorCode.VAR_IS_NOT_ALLOWED_ON_A_METHOD_DEFINITION, 3, 3);
    DartMethodDefinition f1 = (DartMethodDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("f1", ((DartIdentifier)(f1.getName())).getName());
    DartClass A = (DartClass)unit.getTopLevelNodes().get(1);
    DartMethodDefinition f2 = (DartMethodDefinition)(A.getMembers().get(0));
    assertEquals("f2", ((DartIdentifier)(f2.getName())).getName());
    // Make sure that parsing continue
    DartMethodDefinition f3 = (DartMethodDefinition)(A.getMembers().get(1));
    assertEquals("f3", ((DartIdentifier)(f3.getName())).getName());
  }

  public void testFinalOnMethodDefinition() {
    // This syntax is illegal, and should produce errors, but since it is a common error,
    // we want to make sure it produce a valid AST for editor users
    DartUnit unit = parseUnit("phony_final_on_method.dart",
        Joiner.on("\n").join(
            "final f1() {return 1;}",  // Error, use of final on a method
            "class A { ",
            "  final f2() {return 1;}",  // Error, use of final on a method
            "  f3() { return 2; }",
            "  final String f4() { return 1; }",  // Error, use of final on a method
            "}"),
            ParserErrorCode.FINAL_IS_NOT_ALLOWED_ON_A_METHOD_DEFINITION, 1, 1,
            ParserErrorCode.FINAL_IS_NOT_ALLOWED_ON_A_METHOD_DEFINITION, 3, 3,
            ParserErrorCode.FINAL_IS_NOT_ALLOWED_ON_A_METHOD_DEFINITION, 5, 9);
    DartMethodDefinition f1 = (DartMethodDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("f1", ((DartIdentifier)(f1.getName())).getName());
    DartClass A = (DartClass)unit.getTopLevelNodes().get(1);
    DartMethodDefinition f2 = (DartMethodDefinition)(A.getMembers().get(0));
    assertEquals("f2", ((DartIdentifier)(f2.getName())).getName());
    DartMethodDefinition f3 = (DartMethodDefinition)(A.getMembers().get(1));
    assertEquals("f3", ((DartIdentifier)(f3.getName())).getName());
    DartMethodDefinition f4 = (DartMethodDefinition)(A.getMembers().get(2));
    assertEquals("f4", ((DartIdentifier)(f4.getName())).getName());
  }

  public void testRecoverToTopLevel1() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recover_to_toplevel1.dart",
        Joiner.on("\n").join(
            "class A {",
            "  var a;",
            "",  // error - missing right brace
            "class B { ",  // error recover should pick up class B
            "  var b;",
            "}"));
    // Make sure class B is still around
    DartClass A = (DartClass)unit.getTopLevelNodes().get(0);
    assertEquals("A", A.getName().getName());
    DartFieldDefinition A_a = (DartFieldDefinition)A.getMembers().get(0);
    assertEquals("a", A_a.getFields().get(0).getName().getName());
    DartClass B = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("B", B.getName().getName());
    DartFieldDefinition B_b = (DartFieldDefinition)B.getMembers().get(0);
    assertEquals("b", B_b.getFields().get(0).getName().getName());
  }

  public void testRecoverToTopLevel2() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recover_to_toplevel2.dart",
        Joiner.on("\n").join(
            "class A {",
            "  var a;",
            "  var incomplete",  // error - missing semicolon
            "", // error - missing closing brace
            "class B { ",  // error recover should pick up class B
            "  var b;",
            "}"));
    // Make sure class B is still around
    DartClass A = (DartClass)unit.getTopLevelNodes().get(0);
    assertEquals("A", A.getName().getName());
    DartFieldDefinition A_a = (DartFieldDefinition)A.getMembers().get(0);
    assertEquals("a", A_a.getFields().get(0).getName().getName());
    DartClass B = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("B", B.getName().getName());
    DartFieldDefinition B_b = (DartFieldDefinition)B.getMembers().get(0);
    assertEquals("b", B_b.getFields().get(0).getName().getName());
  }

  public void testRecoverToTopLevel3() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recover_to_toplevel3.dart",
        Joiner.on("\n").join(
            "class A {",
            "  var a;",
            "  var incomplete = ",  // error - missing value
            "", // error - missing closing brace
            "class B { ",  // error recover should pick up class B
            "  var b;",
            "}"));
    // Make sure class B is still around
    DartClass A = (DartClass)unit.getTopLevelNodes().get(0);
    assertEquals("A", A.getName().getName());
    DartFieldDefinition A_a = (DartFieldDefinition)A.getMembers().get(0);
    assertEquals("a", A_a.getFields().get(0).getName().getName());
    DartClass B = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("B", B.getName().getName());
    DartFieldDefinition B_b = (DartFieldDefinition)B.getMembers().get(0);
    assertEquals("b", B_b.getFields().get(0).getName().getName());
  }

  public void testRecoverToTopLevel4() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recover_to_toplevel4.dart",
        Joiner.on("\n").join(
            "class A {",
            "  var a;",
            "  incomplete()",  // error - missing body
            "", // error - missing right brace
            "class B { ",  // error recover should pick up class B
            "  var b;",
            "}"));
    // Make sure class B is still around
    DartClass A = (DartClass)unit.getTopLevelNodes().get(0);
    assertEquals("A", A.getName().getName());
    DartFieldDefinition A_a = (DartFieldDefinition)A.getMembers().get(0);
    assertEquals("a", A_a.getFields().get(0).getName().getName());
    DartClass B = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("B", B.getName().getName());
    DartFieldDefinition B_b = (DartFieldDefinition)B.getMembers().get(0);
    assertEquals("b", B_b.getFields().get(0).getName().getName());
  }

  public void testRecoverToTopLevel5() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recover_to_toplevel5.dart",
        Joiner.on("\n").join(
            "class A {",
            "  var a;",
            "  incomplete()",  // error - missing body
            "}",
            "class B { ",  // error recover should pick up class B
            "  var b;",
            "}"));
    // Make sure class B is still around
    DartClass A = (DartClass)unit.getTopLevelNodes().get(0);
    assertEquals("A", A.getName().getName());
    DartFieldDefinition A_a = (DartFieldDefinition)A.getMembers().get(0);
    assertEquals("a", A_a.getFields().get(0).getName().getName());
    DartClass B = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("B", B.getName().getName());
    DartFieldDefinition B_b = (DartFieldDefinition)B.getMembers().get(0);
    assertEquals("b", B_b.getFields().get(0).getName().getName());
  }

  public void testRecoverToTopLevel6() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recover_to_toplevel6.dart",
        Joiner.on("\n").join(
            "class A {",
            "  var a;",
            "  method() { instance.field",  // error - missing semicolon, missing rbrace
            "}",
            "class B { ",  // error recover should pick up class B
            "  var b;",
            "}"));
    // Make sure class B is still around
    DartClass A = (DartClass)unit.getTopLevelNodes().get(0);
    assertEquals("A", A.getName().getName());
    DartFieldDefinition A_a = (DartFieldDefinition)A.getMembers().get(0);
    assertEquals("a", A_a.getFields().get(0).getName().getName());
    DartClass B = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("B", B.getName().getName());
    DartFieldDefinition B_b = (DartFieldDefinition)B.getMembers().get(0);
    assertEquals("b", B_b.getFields().get(0).getName().getName());
  }

  public void testRecoverToTopLevel7() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recover_to_toplevel7.dart",
        Joiner.on("\n").join(
            "class A {",
            "  var a;",
            "  method() { instance.field",  // error - missing semicolon, missing rbrace
            "", // error missing rbrace
            "class B { ",  // error recover should pick up class B
            "  var b;",
            "}"));
    // Make sure class B is still around
    DartClass A = (DartClass)unit.getTopLevelNodes().get(0);
    assertEquals("A", A.getName().getName());
    DartFieldDefinition A_a = (DartFieldDefinition)A.getMembers().get(0);
    assertEquals("a", A_a.getFields().get(0).getName().getName());
    DartClass B = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("B", B.getName().getName());
    DartFieldDefinition B_b = (DartFieldDefinition)B.getMembers().get(0);
    assertEquals("b", B_b.getFields().get(0).getName().getName());
  }

  public void testRecoverToTopLevel8() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recover_to_toplevel8.dart",
        Joiner.on("\n").join(
            "class A {",
            "  var a;",
            "  method() {",
            "    B instance ;",
            "    instance.",  // error - missing semicolon, missing rbrace
            "", // error missing rbrace
            "class B { ",  // error recover should pick up class B
            "  var b;",
            "}"));
    // Make sure class B is still around
    DartClass A = (DartClass)unit.getTopLevelNodes().get(0);
    assertEquals("A", A.getName().getName());
    DartFieldDefinition A_a = (DartFieldDefinition)A.getMembers().get(0);
    assertEquals("a", A_a.getFields().get(0).getName().getName());
    DartClass B = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("B", B.getName().getName());
    DartFieldDefinition B_b = (DartFieldDefinition)B.getMembers().get(0);
    assertEquals("b", B_b.getFields().get(0).getName().getName());
  }

  public void testRecoverToTopLevel9() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recover_to_toplevel9.dart",
        Joiner.on("\n").join(
            "class A ", // missing braces
            "class B { ",  // error recovery should pick up class B
            "  var b;",
            "}"));
    // Make sure class B is still around
    DartClass A = (DartClass)unit.getTopLevelNodes().get(0);
    assertEquals("A", A.getName().getName());
    DartClass B = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("B", B.getName().getName());
    DartFieldDefinition B_b = (DartFieldDefinition)B.getMembers().get(0);
    assertEquals("b", B_b.getFields().get(0).getName().getName());
  }

  public void testRecoverToTopLevel10() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recover_to_toplevel10.dart",
        Joiner.on("\n").join(
            "class A ", // missing opening brace
            "  var a;",
            "}",
            "class B { ",  // error recovery should pick up class B
            "  var b;",
            "}"));
    // Make sure class B is still around
    DartClass A = (DartClass)unit.getTopLevelNodes().get(0);
    assertEquals("A", A.getName().getName());
    // In this case, the parser chooses to promote 'var a' to a top level element
    DartClass B = (DartClass)unit.getTopLevelNodes().get(2);
    assertEquals("B", B.getName().getName());
    DartFieldDefinition B_b = (DartFieldDefinition)B.getMembers().get(0);
    assertEquals("b", B_b.getFields().get(0).getName().getName());
  }

  public void testReservedWordClass() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_reserved_word_class",
        Joiner.on("\n").join(
            "class foo {}",
            "main() {",
            "  int class = 10;",
            "  print(\"class = $class\");",
            "}",
            "class bar {}"));
    DartClass foo = (DartClass)unit.getTopLevelNodes().get(0);
    assertEquals("foo", foo.getName().getName());
    DartMethodDefinition mainMethod = (DartMethodDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("main", ((DartIdentifier)mainMethod.getName()).getName());
    // The recovery on 'int class' closes the main method, assuming int class = 10 is a
    // new toplevel so 'print' ends up as a bogus top level node.
    DartClass bar = (DartClass)unit.getTopLevelNodes().get(3);
    assertEquals("bar", bar.getName().getName());
  }

  public void testBadOperatorRecovery() {
    DartUnit unit = parseUnit("phony_bad_operator_recovery",
        Joiner.on("\n").join(
            "class foo {",
            "  operator / (arg) {}",
            "  operator /= (arg) {}",
            "  operator ][ (arg) {}",
            "  operator === (arg) {}",
            "  operator + (arg) {}",
            "}"),
            ParserErrorCode.OPERATOR_IS_NOT_USER_DEFINABLE, 3, 12,
            ParserErrorCode.OPERATOR_IS_NOT_USER_DEFINABLE, 4, 12,
            ParserErrorCode.OPERATOR_IS_NOT_USER_DEFINABLE, 5, 12);
    DartClass foo =  (DartClass)unit.getTopLevelNodes().get(0);
    assertEquals("foo", foo.getName().getName());
    DartMethodDefinition opDiv = (DartMethodDefinition)foo.getMembers().get(0);
    assertEquals("/", ((DartIdentifier)opDiv.getName()).getName());
    DartMethodDefinition opAssignDiv = (DartMethodDefinition)foo.getMembers().get(1);
    assertEquals("/=", ((DartIdentifier)opAssignDiv.getName()).getName());
    DartMethodDefinition opNonsense = (DartMethodDefinition)foo.getMembers().get(2);
    assertEquals("][", ((DartIdentifier)opNonsense.getName()).getName());
    DartMethodDefinition opEquiv = (DartMethodDefinition)foo.getMembers().get(3);
    assertEquals("===", ((DartIdentifier)opEquiv.getName()).getName());
    DartMethodDefinition opPlus = (DartMethodDefinition)foo.getMembers().get(4);
    assertEquals("+", ((DartIdentifier)opPlus.getName()).getName());
  }

  public void testPropertyAccessInArgumentListRecovery1() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access1.dart",
        Joiner.on("\n").join(
            "var before;",
            "var bad = new B(null, foo.);",
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartFieldDefinition bad = (DartFieldDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getFields().get(0).getName().getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInArgumentListRecovery2() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access2.dart",
        Joiner.on("\n").join(
            "var before;",
            "var bad = new B(null, foo.,);",
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartFieldDefinition bad = (DartFieldDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getFields().get(0).getName().getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInArgumentListRecovery3() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access3.dart",
        Joiner.on("\n").join(
            "var before;",
            "var bad = new B(null,, foo);",
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartFieldDefinition bad = (DartFieldDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getFields().get(0).getName().getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInArgumentListRecovery4() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access4.dart",
        Joiner.on("\n").join(
            "var before;",
            "var bad = new B(null,+, foo);",
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartFieldDefinition bad = (DartFieldDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getFields().get(0).getName().getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInInitializerListRecovery1() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access1.dart",
        Joiner.on("\n").join(
            "class A {",
            "  var before;",
            "  A() : before = foo. ;",
            "  var after;",
            "}"));
    DartClass A = (DartClass)unit.getTopLevelNodes().get(0);
    DartFieldDefinition before = (DartFieldDefinition)A.getMembers().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartMethodDefinition bad = (DartMethodDefinition)A.getMembers().get(1);
    assertEquals("A", ((DartIdentifier)bad.getName()).getName());
    DartFieldDefinition after = (DartFieldDefinition)A.getMembers().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInFormalParameterList1() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_parameter1.dart",
        Joiner.on("\n").join(
                "var before;",
                "typedef void bad(bar.);",
            "var after;"));
        DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
        assertEquals("before", before.getFields().get(0).getName().getName());
        DartFunctionTypeAlias bad = (DartFunctionTypeAlias)unit.getTopLevelNodes().get(1);
        assertEquals("bad", bad.getName().getName());
        DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
        assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInFormalParameterList2() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_parameter2.dart",
        Joiner.on("\n").join(
            "var before;",
            "typedef void bad(bar.,baz);",
        "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartFunctionTypeAlias bad = (DartFunctionTypeAlias)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getName().getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInFormalParameterList3() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_parameter3.dart",
        Joiner.on("\n").join(
            "var before;",
            "typedef void bad(foo, [bar.]);", // incomplete property access
        "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartFunctionTypeAlias bad = (DartFunctionTypeAlias)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getName().getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }


  public void testPropertyAccessInFormalParameterList4() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_parameter4.dart",
        Joiner.on("\n").join(
            "var before;",
            "typedef void bad(int bar.);", // a property access is not valid here
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartFunctionTypeAlias bad = (DartFunctionTypeAlias)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getName().getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInFormalParameterList5() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_parameter5.dart",
        Joiner.on("\n").join(
            "var before;",
            "var bad = (bar.) {};", // incomplete property access
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartFieldDefinition bad = (DartFieldDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getFields().get(0).getName().getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInFormalParameterList6() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_parameter6.dart",
        Joiner.on("\n").join(
            "var before;",
            "void bad(foo.);", // incomplete property access
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartMethodDefinition bad = (DartMethodDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", ((DartIdentifier)bad.getName()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testRecoverInBlock1() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recover_in_block1.dart",
        Joiner.on("\n").join(
            "var before;",
            "bad() { foo( }", // unterminated invocation
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartMethodDefinition bad = (DartMethodDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", ((DartIdentifier)bad.getName()).getName());
    DartUnqualifiedInvocation invocation = (DartUnqualifiedInvocation)
        ((DartExprStmt)bad.getFunction().getBody().getStatements().get(0)).getExpression();
    assertEquals("foo", invocation.getTarget().getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testRecoverInBlock2() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recover_in_block2.dart",
        Joiner.on("\n").join(
            "var before;",
            "bad() { foo }", // unterminated statement
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartMethodDefinition bad = (DartMethodDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", ((DartIdentifier)bad.getName()).getName());
    DartIdentifier ident = (DartIdentifier)
        ((DartExprStmt)bad.getFunction().getBody().getStatements().get(0)).getExpression();
    assertEquals("foo", ident.getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testRecoverInBlock3() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recover_in_block3.dart",
        Joiner.on("\n").join(
            "var before;",
            "bad() { foo. }", // unterminated statement
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartMethodDefinition bad = (DartMethodDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", ((DartIdentifier)bad.getName()).getName());
    DartPropertyAccess prop = (DartPropertyAccess)
    ((DartExprStmt)bad.getFunction().getBody().getStatements().get(0)).getExpression();
assertEquals("foo", ((DartIdentifier)prop.getQualifier()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testRecoverInBlock4() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recover_in_block4.dart",
        Joiner.on("\n").join(
            "var before;",
            "bad() { var foo = }", // unterminated variable decl
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartMethodDefinition bad = (DartMethodDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", ((DartIdentifier)bad.getName()).getName());
    DartVariable foo = ((DartVariableStatement)bad.getFunction().getBody().getStatements().get(0))
        .getVariables().get(0);
    assertEquals("foo", foo.getVariableName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testRecoverInBlock5() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recover_in_block5.dart",
        Joiner.on("\n").join(
            "var before;",
            "bad() { foo(bar. }", // unterminated invocation
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartMethodDefinition bad = (DartMethodDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", ((DartIdentifier)bad.getName()).getName());
    DartUnqualifiedInvocation invocation = (DartUnqualifiedInvocation)
        ((DartExprStmt)bad.getFunction().getBody().getStatements().get(0)).getExpression();
    assertEquals("foo", invocation.getTarget().getName());
    DartPropertyAccess arg0 = (DartPropertyAccess)invocation.getArguments().get(0);
    assertEquals("bar", ((DartIdentifier)arg0.getQualifier()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testRecoverInBlock6() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recover_in_block6.dart",
        Joiner.on("\n").join(
            "var before;",
            "bad() { foo + }", // incomplete expression
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartMethodDefinition bad = (DartMethodDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", ((DartIdentifier)bad.getName()).getName());
    DartBinaryExpression expr = (DartBinaryExpression)
    ((DartExprStmt)bad.getFunction().getBody().getStatements().get(0)).getExpression();
    assertEquals("foo", ((DartIdentifier)expr.getArg1()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
 }

  public void testPropertyAccessInExpressionList1() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_expression_list1.dart",
        Joiner.on("\n").join(
                "method() {",
                "  var before;",
                "  for (var i=0;i < 2;before, foo.,after) {}",
                "  var after;",
                "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    DartVariable before = ((DartVariableStatement) method.getFunction().getBody().getStatements()
        .get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartForStatement forStatement = (DartForStatement) method.getFunction().getBody()
        .getStatements().get(1);
    DartBinaryExpression increment = (DartBinaryExpression) forStatement.getIncrement();
    DartBinaryExpression i1 = (DartBinaryExpression) increment.getArg1();
    DartIdentifier beforeIdent = (DartIdentifier) i1.getArg1();
    assertEquals("before", beforeIdent.getName());
    DartPropertyAccess foo = (DartPropertyAccess) i1.getArg2();
    assertEquals("foo", ((DartIdentifier) foo.getQualifier()).getName());
    DartIdentifier afterIdent = (DartIdentifier) increment.getArg2();
    assertEquals("after", afterIdent.getName());
    DartVariable after = ((DartVariableStatement) method.getFunction().getBody().getStatements()
        .get(2)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testPropertyAccessInExpressionList2() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_expression_list2.dart",
        Joiner.on("\n").join(
            "method() {",
            "  var before;",
            "  for (var i=0;i < 2; foo.) {}",
            "  var after;",
        "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    DartVariable before = ((DartVariableStatement) method.getFunction().getBody().getStatements()
        .get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartForStatement forStatement = (DartForStatement) method.getFunction().getBody()
        .getStatements().get(1);
    DartPropertyAccess foo = (DartPropertyAccess) forStatement.getIncrement();
    assertEquals("foo", ((DartIdentifier) foo.getQualifier()).getName());
    DartVariable after = ((DartVariableStatement) method.getFunction().getBody().getStatements()
        .get(2)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testPropertyAccessInArrayLiteral1() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_array_literal1.dart",
        Joiner.on("\n").join(
            "var before;",
            "var bad = [foo.];",
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartFieldDefinition bad = (DartFieldDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getFields().get(0).getName().getName());
    DartArrayLiteral literal = (DartArrayLiteral)bad.getFields().get(0).getValue();
    DartPropertyAccess foo = (DartPropertyAccess)literal.getExpressions().get(0);
    assertEquals("foo", ((DartIdentifier)foo.getQualifier()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInArrayLiteral2() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_array_literal2.dart",
        Joiner.on("\n").join(
            "var before;",
            "var bad = [foo.,];",
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartFieldDefinition bad = (DartFieldDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getFields().get(0).getName().getName());
    DartArrayLiteral literal = (DartArrayLiteral)bad.getFields().get(0).getValue();
    DartPropertyAccess foo = (DartPropertyAccess)literal.getExpressions().get(0);
    assertEquals("foo", ((DartIdentifier)foo.getQualifier()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInArrayLiteral3() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_array_literal2.dart",
        Joiner.on("\n").join(
            "var before;",
            "var bad = [foo. + ];",
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartFieldDefinition bad = (DartFieldDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getFields().get(0).getName().getName());
    DartArrayLiteral literal = (DartArrayLiteral)bad.getFields().get(0).getValue();
    DartPropertyAccess foo = (DartPropertyAccess)literal.getExpressions().get(0);
    assertEquals("foo", ((DartIdentifier)foo.getQualifier()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInMapLiteral1() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_map_literal1.dart",
        Joiner.on("\n").join(
            "var before;",
            "var bad = {\"key\" : foo.};",
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartFieldDefinition bad = (DartFieldDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getFields().get(0).getName().getName());
    DartMapLiteral literal = (DartMapLiteral)bad.getFields().get(0).getValue();
    DartPropertyAccess foo = (DartPropertyAccess)literal.getEntries().get(0).getValue();
    assertEquals("foo", ((DartIdentifier)foo.getQualifier()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInMapLiteral2() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_map_literal2.dart",
        Joiner.on("\n").join(
            "var before;",
            "var bad = {\"key\" : foo.,};",
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartFieldDefinition bad = (DartFieldDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getFields().get(0).getName().getName());
    DartMapLiteral literal = (DartMapLiteral)bad.getFields().get(0).getValue();
    DartPropertyAccess foo = (DartPropertyAccess)literal.getEntries().get(0).getValue();
    assertEquals("foo", ((DartIdentifier)foo.getQualifier()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInMapLiteral3() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_map_literal3.dart",
        Joiner.on("\n").join(
            "var before;",
            "var bad = {\"key\" : foo. +};",
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartFieldDefinition bad = (DartFieldDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getFields().get(0).getName().getName());
    DartMapLiteral literal = (DartMapLiteral)bad.getFields().get(0).getValue();
    DartPropertyAccess foo = (DartPropertyAccess)literal.getEntries().get(0).getValue();
    assertEquals("foo", ((DartIdentifier)foo.getQualifier()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testRecoveryDirective1() {
    DartUnit unit = parseUnit("phony_recovery_directive1.dart",
        Joiner.on("\n").join(
            "library a;",
            "library b;"),
            ParserErrorCode.DIRECTIVE_OUT_OF_ORDER, 2, 1,
            ParserErrorCode.ONLY_ONE_LIBRARY_DIRECTIVE, 2, 10);
    DartLibraryDirective a = (DartLibraryDirective)unit.getDirectives().get(0);
    assertEquals("a", a.getLibraryName());
    DartLibraryDirective b = (DartLibraryDirective)unit.getDirectives().get(1);
    assertEquals("b", b.getLibraryName());
  }

  public void testRecoveryDirective2() {
    DartUnit unit = parseUnit("phony_recovery_directive2.dart",
        Joiner.on("\n").join(
            "import 'a';",
            "library b;"),
            ParserErrorCode.DIRECTIVE_OUT_OF_ORDER, 2, 1);
    DartImportDirective a = (DartImportDirective)unit.getDirectives().get(0);
    assertEquals("a", a.getLibraryUri().getValue());
    DartLibraryDirective b = (DartLibraryDirective)unit.getDirectives().get(1);
    assertEquals("b", b.getLibraryName());
  }

  public void testRecoveryDirective3() {
    DartUnit unit = parseUnit("phony_recovery_directive3.dart",
        Joiner.on("\n").join(
            "part 'a';",
            "import 'b';"),
            ParserErrorCode.DIRECTIVE_OUT_OF_ORDER, 2, 1);
    DartSourceDirective a = (DartSourceDirective)unit.getDirectives().get(0);
    assertEquals("a", a.getSourceUri().getValue());
    DartImportDirective b = (DartImportDirective)unit.getDirectives().get(1);
    assertEquals("b", b.getLibraryUri().getValue());
  }

  public void testRecoveryDirective4() {
    DartUnit unit = parseUnit("phony_recovery_directive4.dart",
        Joiner.on("\n").join(
            "import 'a'", // missing semicolon
            "import 'b';"),
            ParserErrorCode.EXPECTED_TOKEN, 1, 8);
    DartImportDirective a = (DartImportDirective)unit.getDirectives().get(0);
    assertEquals("a", a.getLibraryUri().getValue());
    DartImportDirective b = (DartImportDirective)unit.getDirectives().get(1);
    assertEquals("b", b.getLibraryUri().getValue());
  }

  public void testRecoveryDirective6() {
    DartUnit unit = parseUnit("phony_recovery_directive6.dart",
        Joiner.on("\n").join(
            "import 'a'", // missing semicolon
            "class b {}"),
            ParserErrorCode.EXPECTED_TOKEN, 1, 8);
    DartImportDirective a = (DartImportDirective)unit.getDirectives().get(0);
    assertEquals("a", a.getLibraryUri().getValue());
    DartClass b = (DartClass)unit.getTopLevelNodes().get(0);
    assertEquals("b", b.getClassName());
  }


  public void testPropertyAccessInTypeArgsRecovery1() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_type_args1.dart",
        Joiner.on("\n").join(
            "var before;",
            "List<foo.> bad;",
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartFieldDefinition bad = (DartFieldDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getFields().get(0).getName().getName());
    DartTypeNode badTypeNode = bad.getTypeNode().getTypeArguments().get(0);
    assertEquals("foo", ((DartIdentifier)((DartPropertyAccess)badTypeNode.getIdentifier()).getQualifier()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInTypeArgsRecovery2() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_type_args2.dart",
        Joiner.on("\n").join(
            "var before;",
            "List<foo. +> bad;",
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
//    DartFieldDefinition bad = (DartFieldDefinition)unit.getTopLevelNodes().get(1);
//    assertEquals("bad", bad.getFields().get(0).getName().getName());
//    DartTypeNode badTypeNode = bad.getTypeNode().getTypeArguments().get(0);
//    assertEquals("foo", ((DartIdentifier)((DartPropertyAccess)badTypeNode.getIdentifier()).getQualifier()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInTypeParametersRecovery1() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_type_param1.dart",
        Joiner.on("\n").join(
            "var before;",
            "class bad<T extends foo.> {}",
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartClass bad = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getClassName());
    DartTypeNode badTypeNode = bad.getTypeParameters().get(0).getBound();
    assertEquals("foo", ((DartIdentifier)((DartPropertyAccess)badTypeNode.getIdentifier()).getQualifier()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInTypeParametersRecovery2() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_type_param2.dart",
        Joiner.on("\n").join(
            "var before;",
            "class bad<T extends foo. +> {}",
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartClass bad = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getClassName());
    DartTypeNode badTypeNode = bad.getTypeParameters().get(0).getBound();
    assertEquals("foo", ((DartIdentifier)((DartPropertyAccess)badTypeNode.getIdentifier()).getQualifier()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testPropertyAccessInTypeParametersRecovery3() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_property_access_type_param3.dart",
        Joiner.on("\n").join(
            "var before;",
            "class bad<foo +> {}",
            "var after;"));
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartClass bad = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("bad", bad.getClassName());
    assertEquals("foo", bad.getTypeParameters().get(0).getName().getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testInvalidIdentifier1() {
    DartUnit unit = parseUnit("phony_invalid_identifier.dart",
        Joiner.on("\n").join(
            "var before;",
            "class void {}",
            "var after;"),
            ParserErrorCode.INVALID_IDENTIFIER, 2, 7);
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());

    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(1);
    assertEquals("after", after.getFields().get(0).getName().getName());
  }

  public void testRecoveryClassRbrace1() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recovery_class_rbrace1.dart",
        Joiner.on("\n").join(
            "var before;",
            "class A {",
            "  int bad =,",  // incomplete field definition
            "}",
            "int after;")); // use 'int' instead of 'var' because it is harder to recover to
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartClass A = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("A", A.getClassName());
    DartFieldDefinition bad = (DartFieldDefinition)A.getMembers().get(0);
    assertEquals("bad", bad.getFields().get(0).getName().getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
    assertEquals("int", ((DartIdentifier)after.getTypeNode().getIdentifier()).getName());
  }

  public void testRecoveryClassRbrace2() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recovery_class_rbrace2.dart",
        Joiner.on("\n").join(
            "var before;",
            "class A {",
            "  int bad( arg a,",  // incomplete method definition
            "}",
            "int after;")); // use 'int' instead of 'var' because it is harder to recover to
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartClass A = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("A", A.getClassName());
    DartMethodDefinition bad = (DartMethodDefinition)A.getMembers().get(0);
    assertEquals("bad", ((DartIdentifier)bad.getName()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
    assertEquals("int", ((DartIdentifier)after.getTypeNode().getIdentifier()).getName());
  }

  public void testRecoveryClassRbrace3() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recovery_class_rbrace3.dart",
        Joiner.on("\n").join(
            "var before;",
            "class A {",
            "  int bad( arg a, ; complete garbage follows",  // incomplete method definition
            "}",
            "int after;")); // use 'int' instead of 'var' because it is harder to recover to
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartClass A = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("A", A.getClassName());
    DartMethodDefinition bad = (DartMethodDefinition)A.getMembers().get(0);
    assertEquals("bad", ((DartIdentifier)bad.getName()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
    assertEquals("int", ((DartIdentifier)after.getTypeNode().getIdentifier()).getName());
  }

  public void testRecoveryClassRbrace4() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recovery_class_rbrace4.dart",
        Joiner.on("\n").join(
            "var before;",
            "class A {",
            "  int bad(arg a) { junk }; ",  // trailing semicolon
            "}",
            "int after;")); // use 'int' instead of 'var' because it is harder to recover to
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartClass A = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("A", A.getClassName());
    DartMethodDefinition bad = (DartMethodDefinition)A.getMembers().get(0);
    assertEquals("bad", ((DartIdentifier)bad.getName()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
    assertEquals("int", ((DartIdentifier)after.getTypeNode().getIdentifier()).getName());
  }

  public void testRecoveryClassRbrace5() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recovery_class_rbrace5.dart",
        Joiner.on("\n").join(
            "var before;",
            "class A {",
            "  var bad = int foo(arg a) { =  junk }; ",  // jibberish value with trailing semicolon
            "}",
            "int after;")); // use 'int' instead of 'var' because it is harder to recover to
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartClass A = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("A", A.getClassName());
    DartFieldDefinition bad = (DartFieldDefinition)A.getMembers().get(0);
    assertEquals("bad", bad.getFields().get(0).getName().getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
    assertEquals("int", ((DartIdentifier)after.getTypeNode().getIdentifier()).getName());
  }

  public void testRecoveryClassRbrace6() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recovery_class_rbrace6.dart",
        Joiner.on("\n").join(
            "var before;",
            "class A {",
            "  bad() ",  // incomplete method
            "}",
            "int after;")); // use 'int' instead of 'var' because it is harder to recover to
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartClass A = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("A", A.getClassName());
    DartMethodDefinition bad = (DartMethodDefinition)A.getMembers().get(0);
    assertEquals("bad", ((DartIdentifier)bad.getName()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
    assertEquals("int", ((DartIdentifier)after.getTypeNode().getIdentifier()).getName());
  }

  public void testRecoveryClassRbrace7() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recovery_class_rbrace7.dart",
        Joiner.on("\n").join(
            "var before;",
            "class A {",
            "  bad() }",  // incomplete method
            "}",
            "int after;")); // use 'int' instead of 'var' because it is harder to recover to
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartClass A = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("A", A.getClassName());
    DartMethodDefinition bad = (DartMethodDefinition)A.getMembers().get(0);
    assertEquals("bad", ((DartIdentifier)bad.getName()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
    assertEquals("int", ((DartIdentifier)after.getTypeNode().getIdentifier()).getName());
  }

  public void testRecoveryClassRbrace8() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recovery_class_rbrace8.dart",
        Joiner.on("\n").join(
            "var before;",
            "class A {",
            "  bad( }",  // incomplete method
            "}",
            "int after;")); // use 'int' instead of 'var' because it is harder to recover to
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartClass A = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("A", A.getClassName());
    DartMethodDefinition bad = (DartMethodDefinition)A.getMembers().get(0);
    assertEquals("bad", ((DartIdentifier)bad.getName()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
    assertEquals("int", ((DartIdentifier)after.getTypeNode().getIdentifier()).getName());
  }

  public void testRecoveryClassRbrace9() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recovery_class_rbrace9.dart",
        Joiner.on("\n").join(
            "var before;",
            "class A {",
            "  bad",  // incomplete declaration
            "}",
            "int after;")); // use 'int' instead of 'var' because it is harder to recover to
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartClass A = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("A", A.getClassName());
    DartMethodDefinition bad = (DartMethodDefinition)A.getMembers().get(0);
    assertNotNull(bad);
   // assertEquals("bad", ((DartIdentifier)bad.getName()).getName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
    assertEquals("int", ((DartIdentifier)after.getTypeNode().getIdentifier()).getName());
  }

  public void testRecoveryClassRbrace10() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recovery_class_rbrace10.dart",
        Joiner.on("\n").join(
            "var before;",
            "class A {",
            "  void",  // incomplete declaration
            "}",
            "int after;")); // use 'int' instead of 'var' because it is harder to recover to
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartClass A = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("A", A.getClassName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
    assertEquals("int", ((DartIdentifier)after.getTypeNode().getIdentifier()).getName());
  }

  public void testRecoveryClassRbrace11() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recovery_class_rbrace11.dart",
        Joiner.on("\n").join(
            "var before;",
            "class A {",
            "  const",  // incomplete declaration
            "}",
            "int after;")); // use 'int' instead of 'var' because it is harder to recover to
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartClass A = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("A", A.getClassName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
    assertEquals("int", ((DartIdentifier)after.getTypeNode().getIdentifier()).getName());
  }

  public void testRecoveryClassRbrace12() {
    DartUnit unit = parseUnitUnspecifiedErrors("phony_recovery_class_rbrace12.dart",
        Joiner.on("\n").join(
            "var before;",
            "class A {",
            "  ;;;;",  // stray semicolons
            "}",
            "int after;")); // use 'int' instead of 'var' because it is harder to recover to
    DartFieldDefinition before = (DartFieldDefinition)unit.getTopLevelNodes().get(0);
    assertEquals("before", before.getFields().get(0).getName().getName());
    DartClass A = (DartClass)unit.getTopLevelNodes().get(1);
    assertEquals("A", A.getClassName());
    DartFieldDefinition after = (DartFieldDefinition)unit.getTopLevelNodes().get(2);
    assertEquals("after", after.getFields().get(0).getName().getName());
    assertEquals("int", ((DartIdentifier)after.getTypeNode().getIdentifier()).getName());
  }

  public void testRecoveryBeforeIf1() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_if1.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad.",
            "  if (false) {}",
            "  int after;", // use 'int' instead of 'var' because it is harder to recover to
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartPropertyAccess bad = (DartPropertyAccess) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", ((DartIdentifier) bad.getQualifier()).getName());
    DartIfStatement ifStatement = (DartIfStatement) statements.get(2);
    assertEquals(false, ((DartBooleanLiteral)ifStatement.getCondition()).getValue());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeIf2() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_if2.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad",
            "  if (false) {}",
            "  int after;", // use 'int' instead of 'var' because it is harder to recover to
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartIdentifier bad = (DartIdentifier) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", bad.getName());
    DartIfStatement ifStatement = (DartIfStatement) statements.get(2);
    assertEquals(false, ((DartBooleanLiteral)ifStatement.getCondition()).getValue());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeSwitch1() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_switch1.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad.",
            "  switch (false) {}",
            "  int after;", // use 'int' instead of 'var' because it is harder to recover to
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartPropertyAccess bad = (DartPropertyAccess) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", ((DartIdentifier) bad.getQualifier()).getName());
    DartSwitchStatement switchStatement = (DartSwitchStatement) statements.get(2);
    assertEquals(false, ((DartBooleanLiteral)switchStatement.getExpression()).getValue());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeSwitch2() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_switch2.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad",
            "  switch (false) {}",
            "  int after;", // use 'int' instead of 'var' because it is harder to recover to
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartIdentifier bad = (DartIdentifier) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", bad.getName());
    DartSwitchStatement switchStatement = (DartSwitchStatement) statements.get(2);
    assertEquals(false, ((DartBooleanLiteral)switchStatement.getExpression()).getValue());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeWhile1() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_while1.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad.",
            "  while (false) {}",
            "  int after;", // use 'int' instead of 'var' because it is harder to recover to
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartPropertyAccess bad = (DartPropertyAccess) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", ((DartIdentifier) bad.getQualifier()).getName());
    DartWhileStatement whileStatement = (DartWhileStatement) statements.get(2);
    assertEquals(false, ((DartBooleanLiteral)whileStatement.getCondition()).getValue());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeWhile2() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_while2.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad",
            "  while (false) {}",
            "  int after;", // use 'int' instead of 'var' because it is harder to recover to
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartIdentifier bad = ((DartIdentifier)((DartExprStmt) statements.get(1)).getExpression());
    assertEquals("bad", bad.getName());
    DartWhileStatement whileStatement = (DartWhileStatement) statements.get(2);
    assertEquals(false, ((DartBooleanLiteral)whileStatement.getCondition()).getValue());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeDo1() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_do1.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad.",
            "  do {} while (false);",
            "  int after;", // use 'int' instead of 'var' because it is harder to recover to
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartPropertyAccess bad = (DartPropertyAccess) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", ((DartIdentifier) bad.getQualifier()).getName());
    DartDoWhileStatement doStatement = (DartDoWhileStatement) statements.get(2);
    assertEquals(false, ((DartBooleanLiteral)doStatement.getCondition()).getValue());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeDo2() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_do2.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad",
            "  do {} while (false);",
            "  int after;", // use 'int' instead of 'var' because it is harder to recover to
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartIdentifier bad = (DartIdentifier) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", bad.getName());
    DartDoWhileStatement doStatement = (DartDoWhileStatement) statements.get(2);
    assertEquals(false, ((DartBooleanLiteral)doStatement.getCondition()).getValue());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeFor1() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_for1.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad.",
            "  for(var i in []) {}",
            "  int after;", // use 'int' instead of 'var' because it is harder to recover to
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartPropertyAccess bad = (DartPropertyAccess) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", ((DartIdentifier) bad.getQualifier()).getName());
    DartForInStatement forInStatement = (DartForInStatement) statements.get(2);
    assertEquals("i", forInStatement.getVariableStatement()
        .getVariables().get(0).getName().getName());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeFor2() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_for2.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad.",
            "  for(var i = 0 ; i < 1 ; i++) {}",
            "  int after;", // use 'int' instead of 'var' because it is harder to recover to
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartPropertyAccess bad = (DartPropertyAccess) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", ((DartIdentifier) bad.getQualifier()).getName());
    DartForStatement forStatement = (DartForStatement) statements.get(2);
    assertEquals("i", ((DartVariableStatement)forStatement.getInit())
        .getVariables().get(0).getName().getName());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeVar1() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_var1.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad.",
            "  var after;",
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartPropertyAccess bad = (DartPropertyAccess) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", ((DartIdentifier) bad.getQualifier()).getName());
    DartVariable after = ((DartVariableStatement) statements.get(2)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeVar2() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_var2.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad",
            "  var after;",
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartIdentifier bad = (DartIdentifier) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", bad.getName());
    DartVariable after = ((DartVariableStatement) statements.get(2)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeFinal1() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_final1.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad.",
            "  final int after;",
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartPropertyAccess bad = (DartPropertyAccess) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", ((DartIdentifier) bad.getQualifier()).getName());
    DartVariable after = ((DartVariableStatement) statements.get(2)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
    assertTrue(((DartVariableStatement)statements.get(2)).getModifiers().isFinal());
  }

  public void testRecoveryBeforeFinal2() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_final2.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad",
            "  final int after;",
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartIdentifier bad = (DartIdentifier) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", bad.getName());
    DartVariable after = ((DartVariableStatement) statements.get(2)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
    assertTrue(((DartVariableStatement)statements.get(2)).getModifiers().isFinal());
  }

  public void testRecoveryBeforeTry1() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_try1.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad.",
            "  try {}",
            "  int after;",
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartPropertyAccess bad = (DartPropertyAccess) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", ((DartIdentifier) bad.getQualifier()).getName());
    DartTryStatement tryStatement = (DartTryStatement) statements.get(2);
    assertEquals(0, tryStatement.getTryBlock().getStatements().size());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeTry2() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_try1.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad",
            "  try {}",
            "  int after;",
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartIdentifier bad = (DartIdentifier) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", bad.getName());
    DartTryStatement tryStatement = (DartTryStatement) statements.get(2);
    assertEquals(0, tryStatement.getTryBlock().getStatements().size());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeContinue1() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_continue1.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad.",
            "  continue;",  // Not really legal here, but the parser doesn't know.
            "  int after;",
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartPropertyAccess bad = (DartPropertyAccess) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", ((DartIdentifier) bad.getQualifier()).getName());
    DartContinueStatement continueStatement = (DartContinueStatement) statements.get(2);
    assertNull(continueStatement.getTargetName());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeContinue2() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_continue2.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad",
            "  continue;",  // Not really legal here, but the parser doesn't know.
            "  int after;",
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartIdentifier bad = (DartIdentifier) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", bad.getName());
    DartContinueStatement continueStatement = (DartContinueStatement) statements.get(2);
    assertNull(continueStatement.getTargetName());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeBreak1() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_break1.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad.",
            "  break;",  // Not really legal here, but the parser doesn't know.
            "  int after;",
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartPropertyAccess bad = (DartPropertyAccess) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", ((DartIdentifier) bad.getQualifier()).getName());
    DartBreakStatement breakStatement = (DartBreakStatement) statements.get(2);
    assertNull(breakStatement.getTargetName());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeBreak2() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_break2.dart",
        Joiner.on("\n").join("method() {",
            "  var before;",
            "  bad",
            "  break;",  // Not really legal here, but the parser doesn't know.
            "  int after;",
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartIdentifier bad = (DartIdentifier) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", bad.getName());
    DartBreakStatement breakStatement = (DartBreakStatement) statements.get(2);
    assertNull(breakStatement.getTargetName());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeReturn1() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_break1.dart",
        Joiner.on("\n").join(
            "int method() {",
            "  var before;",
            "  bad.",
            "  return 1;",
            "  int after;",  // Never reached, but the parser doesn't know.
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartPropertyAccess bad = (DartPropertyAccess) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", ((DartIdentifier) bad.getQualifier()).getName());
    DartReturnStatement returnStatement = (DartReturnStatement) statements.get(2);
    assertEquals(BigInteger.valueOf(1), ((DartIntegerLiteral)returnStatement.getValue()).getValue());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeReturn2() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_break1.dart",
        Joiner.on("\n").join(
            "int method() {",
            "  var before;",
            "  bad",
            "  return 1;",
            "  int after;",  // Never reached, but the parser doesn't know.
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartIdentifier bad = (DartIdentifier) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", bad.getName());
    DartReturnStatement returnStatement = (DartReturnStatement) statements.get(2);
    assertEquals(BigInteger.valueOf(1), ((DartIntegerLiteral)returnStatement.getValue()).getValue());
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeThrow1() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_break1.dart",
        Joiner.on("\n").join(
            "int method() {",
            "  var before;",
            "  bad.",
            "  throw new Exception();",
            "  int after;",  // Never reached, but the parser doesn't know.
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartPropertyAccess bad = (DartPropertyAccess) ((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", ((DartIdentifier) bad.getQualifier()).getName());
    DartThrowExpression throwStatement = (DartThrowExpression) ((DartExprStmt) statements.get(2)).getExpression();
    assertNotNull(throwStatement);
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }

  public void testRecoveryBeforeThrow2() {
    DartUnit unit = parseUnitUnspecifiedErrors(
        "phony_recovery_before_break2.dart",
        Joiner.on("\n").join(
            "int method() {",
            "  var before;",
            "  bad",
            "  throw new Exception();",
            "  int after;",  // Never reached, but the parser doesn't know.
            "}"));
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    List<DartStatement> statements = method.getFunction().getBody().getStatements();
    DartVariable before = ((DartVariableStatement) statements.get(0)).getVariables().get(0);
    assertEquals("before", before.getName().getName());
    DartIdentifier bad = (DartIdentifier)((DartExprStmt) statements.get(1)).getExpression();
    assertEquals("bad", bad.getName());
    DartThrowExpression throwStatement = (DartThrowExpression) ((DartExprStmt) statements.get(2)).getExpression();
    assertNotNull(throwStatement);
    DartVariable after = ((DartVariableStatement) statements.get(3)).getVariables().get(0);
    assertEquals("after", after.getName().getName());
  }
}
