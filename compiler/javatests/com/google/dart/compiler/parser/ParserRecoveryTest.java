// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.common.base.Joiner;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartFieldDefinition;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartUnit;

public class ParserRecoveryTest extends AbstractParserTest {

  @Override
  public void testStringsErrors() {
    // Implemented elsewhere
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
}
