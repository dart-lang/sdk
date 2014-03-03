// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import '../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart';
import '../../../sdk/lib/_internal/compiler/implementation/tree/tree.dart';
import '../../../sdk/lib/_internal/compiler/implementation/util/util.dart';
import '../../../sdk/lib/_internal/compiler/implementation/source_file.dart';
import 'mock_compiler.dart';
import 'parser_helper.dart';

import '../../../sdk/lib/_internal/compiler/implementation/elements/modelx.dart'
  show ElementX, CompilationUnitElementX, FunctionElementX;

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart';

import '../../../sdk/lib/_internal/compiler/implementation/dart_types.dart';

final MessageKind NOT_ASSIGNABLE = MessageKind.NOT_ASSIGNABLE;
final MessageKind MEMBER_NOT_FOUND = MessageKind.MEMBER_NOT_FOUND;

DartType voidType;
DartType intType;
DartType boolType;
DartType stringType;
DartType doubleType;
DartType objectType;

main() {
  List tests = [testSimpleTypes,
                testReturn,
                testFor,
                testWhile,
                testTry,
                testSwitch,
                testOperators,
                testConstructorInvocationArgumentCount,
                testConstructorInvocationArgumentTypes,
                testMethodInvocationArgumentCount,
                testMethodInvocations,
                testMethodInvocationsInClass,
                testGetterSetterInvocation,
                testControlFlow,
                // testNewExpression,
                testConditionalExpression,
                testIfStatement,
                testThis,
                testSuper,
                testOperatorsAssignability,
                testFieldInitializers,
                testTypeVariableExpressions,
                testTypeVariableLookup1,
                testTypeVariableLookup2,
                testTypeVariableLookup3,
                testFunctionTypeLookup,
                testTypedefLookup,
                testTypeLiteral,
                testInitializers,
                testTypePromotionHints,
                testFunctionCall];
  for (Function test in tests) {
    setup();
    test();
  }
}

testSimpleTypes() {
  Expect.equals(intType, analyzeType("3"));
  Expect.equals(boolType, analyzeType("false"));
  Expect.equals(boolType, analyzeType("true"));
  Expect.equals(stringType, analyzeType("'hestfisk'"));
}

testReturn() {
  analyzeTopLevel("void foo() { return 3; }", MessageKind.RETURN_VALUE_IN_VOID);
  analyzeTopLevel("int bar() { return 'hest'; }",
                  NOT_ASSIGNABLE);
  analyzeTopLevel("void baz() { var x; return x; }");
  analyzeTopLevel(returnWithType("int", "'string'"),
                  NOT_ASSIGNABLE);
  analyzeTopLevel(returnWithType("", "'string'"));
  analyzeTopLevel(returnWithType("Object", "'string'"));
  analyzeTopLevel(returnWithType("String", "'string'"));
  analyzeTopLevel(returnWithType("String", null));
  analyzeTopLevel(returnWithType("int", null));
  analyzeTopLevel(returnWithType("void", ""));
  analyzeTopLevel(returnWithType("void", 1), MessageKind.RETURN_VALUE_IN_VOID);
  analyzeTopLevel(returnWithType("void", null));
  analyzeTopLevel(returnWithType("String", ""), MessageKind.RETURN_NOTHING);
  // analyzeTopLevel("String foo() {};"); // Should probably fail.
}

testFor() {
  analyze("for (var x;true;x = x + 1) {}");
  analyze("for (var x;null;x = x + 1) {}");
  analyze("for (var x;0;x = x + 1) {}", warnings: NOT_ASSIGNABLE);
  analyze("for (var x;'';x = x + 1) {}", warnings: NOT_ASSIGNABLE);

   analyze("for (;true;) {}");
   analyze("for (;null;) {}");
   analyze("for (;0;) {}", warnings: NOT_ASSIGNABLE);
   analyze("for (;'';) {}", warnings: NOT_ASSIGNABLE);

  // Foreach tests
//  TODO(karlklose): for each is not yet implemented.
//  analyze("{ List<String> strings = ['1','2','3']; " +
//          "for (String s in strings) {} }");
//  analyze("{ List<int> ints = [1,2,3]; for (String s in ints) {} }",
//          NOT_ASSIGNABLE);
//  analyze("for (String s in true) {}", MessageKind.METHOD_NOT_FOUND);
}

testWhile() {
  analyze("while (true) {}");
  analyze("while (null) {}");
  analyze("while (0) {}", warnings: NOT_ASSIGNABLE);
  analyze("while ('') {}", warnings: NOT_ASSIGNABLE);

  analyze("do {} while (true);");
  analyze("do {} while (null);");
  analyze("do {} while (0);", warnings: NOT_ASSIGNABLE);
  analyze("do {} while ('');", warnings: NOT_ASSIGNABLE);
  analyze("do { int i = 0.5; } while (true);", warnings: NOT_ASSIGNABLE);
  analyze("do { int i = 0.5; } while (null);", warnings: NOT_ASSIGNABLE);
}

testTry() {
  analyze("try {} finally {}");
  analyze("try {} catch (e) { int i = e;} finally {}");
  analyze("try {} catch (e, s) { int i = e; StackTrace j = s; } finally {}");
  analyze("try {} on String catch (e) {} finally {}");
  analyze("try { int i = ''; } finally {}", warnings: NOT_ASSIGNABLE);
  analyze("try {} finally { int i = ''; }", warnings: NOT_ASSIGNABLE);
  analyze("try {} on String catch (e) { int i = e; } finally {}",
          warnings: NOT_ASSIGNABLE);
  analyze("try {} catch (e, s) { int i = e; int j = s; } finally {}",
          warnings: NOT_ASSIGNABLE);
  analyze("try {} on String catch (e, s) { int i = e; int j = s; } finally {}",
          warnings: [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
}


testSwitch() {
  analyze("switch (0) { case 1: break; case 2: break; }");
  analyze("switch (0) { case 1: int i = ''; break; case 2: break; }",
          warnings: NOT_ASSIGNABLE);
  analyze("switch (0) { case '': break; }",
          warnings: NOT_ASSIGNABLE);
  analyze("switch ('') { case 1: break; case 2: break; }",
          warnings: [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
  analyze("switch (1.5) { case 1: break; case 2: break; }",
          warnings: [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
}

testOperators() {
  // TODO(karlklose): add the DartC tests for operators when we can parse
  // classes with operators.
  for (final op in ['+', '-', '*', '/', '%', '~/', '|', '&']) {
    analyze("{ var i = 1 ${op} 2; }");
    analyze("{ var i = 1; i ${op}= 2; }");
    analyze("{ int i; var j = (i = true) ${op} 2; }",
            warnings: [NOT_ASSIGNABLE, MessageKind.OPERATOR_NOT_FOUND]);
    analyze("{ int i; var j = 1 ${op} (i = true); }",
            warnings: [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
  }
  for (final op in ['-', '~']) {
    analyze("{ var i = ${op}1; }");
    analyze("{ int i; var j = ${op}(i = true); }",
            warnings: [NOT_ASSIGNABLE, MessageKind.OPERATOR_NOT_FOUND]);
  }
  for (final op in ['++', '--']) {
    analyze("{ int i = 1; int j = i${op}; }");
    analyze("{ int i = 1; bool j = i${op}; }", warnings: NOT_ASSIGNABLE);
    analyze("{ bool b = true; bool j = b${op}; }",
            warnings: MessageKind.OPERATOR_NOT_FOUND);
    analyze("{ bool b = true; int j = ${op}b; }",
            warnings: MessageKind.OPERATOR_NOT_FOUND);
  }
  for (final op in ['||', '&&']) {
    analyze("{ bool b = (true ${op} false); }");
    analyze("{ int b = true ${op} false; }", warnings: NOT_ASSIGNABLE);
    analyze("{ bool b = (1 ${op} false); }", warnings: NOT_ASSIGNABLE);
    analyze("{ bool b = (true ${op} 2); }", warnings: NOT_ASSIGNABLE);
  }
  for (final op in ['>', '<', '<=', '>=']) {
    analyze("{ bool b = 1 ${op} 2; }");
    analyze("{ int i = 1 ${op} 2; }", warnings: NOT_ASSIGNABLE);
    analyze("{ int i; bool b = (i = true) ${op} 2; }",
            warnings: [NOT_ASSIGNABLE, MessageKind.OPERATOR_NOT_FOUND]);
    analyze("{ int i; bool b = 1 ${op} (i = true); }",
            warnings: [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
  }
  for (final op in ['==', '!=']) {
    analyze("{ bool b = 1 ${op} 2; }");
    analyze("{ int i = 1 ${op} 2; }", warnings: NOT_ASSIGNABLE);
    analyze("{ int i; bool b = (i = true) ${op} 2; }",
            warnings: NOT_ASSIGNABLE);
    analyze("{ int i; bool b = 1 ${op} (i = true); }",
            warnings: NOT_ASSIGNABLE);
  }
}

void testConstructorInvocationArgumentCount() {
  compiler.parseScript("""
     class C1 { C1(x, y); }
     class C2 { C2(int x, int y); }
  """);
  // calls to untyped constructor C1
  analyze("new C1(1, 2);");
  analyze("new C1();", warnings: MessageKind.MISSING_ARGUMENT);
  analyze("new C1(1);", warnings: MessageKind.MISSING_ARGUMENT);
  analyze("new C1(1, 2, 3);", warnings: MessageKind.ADDITIONAL_ARGUMENT);
  // calls to typed constructor C2
  analyze("new C2(1, 2);");
  analyze("new C2();", warnings: MessageKind.MISSING_ARGUMENT);
  analyze("new C2(1);", warnings: MessageKind.MISSING_ARGUMENT);
  analyze("new C2(1, 2, 3);", warnings: MessageKind.ADDITIONAL_ARGUMENT);
}

void testConstructorInvocationArgumentTypes() {
  compiler.parseScript("""
    class C1 { C1(x); }
    class C2 { C2(int x); }
    class C3 {
      int field;
      C3(this.field);
      C3.named(this.field);
    }
  """);
  analyze("new C1(42);");
  analyze("new C1('string');");
  analyze("new C2(42);");
  analyze("new C2('string');",
          warnings: NOT_ASSIGNABLE);
  analyze("new C3(42);");
  analyze("new C3('string');",
          warnings: NOT_ASSIGNABLE);
  analyze("new C3.named(42);");
  analyze("new C3.named('string');",
          warnings: NOT_ASSIGNABLE);
}

void testMethodInvocationArgumentCount() {
  compiler.parseScript(CLASS_WITH_METHODS);

  check(String text, [expectedWarnings]) {
    analyze("{ ClassWithMethods c; $text }", warnings: expectedWarnings);
  }

  check("c.untypedNoArgumentMethod(1);", MessageKind.ADDITIONAL_ARGUMENT);
  check("c.untypedOneArgumentMethod();", MessageKind.MISSING_ARGUMENT);
  check("c.untypedOneArgumentMethod(1, 1);", MessageKind.ADDITIONAL_ARGUMENT);
  check("c.untypedTwoArgumentMethod();", MessageKind.MISSING_ARGUMENT);
  check("c.untypedTwoArgumentMethod(1, 2, 3);",
        MessageKind.ADDITIONAL_ARGUMENT);
  check("c.intNoArgumentMethod(1);", MessageKind.ADDITIONAL_ARGUMENT);
  check("c.intOneArgumentMethod();", MessageKind.MISSING_ARGUMENT);
  check("c.intOneArgumentMethod(1, 1);", MessageKind.ADDITIONAL_ARGUMENT);
  check("c.intTwoArgumentMethod();", MessageKind.MISSING_ARGUMENT);
  check("c.intTwoArgumentMethod(1, 2, 3);", MessageKind.ADDITIONAL_ARGUMENT);
  // check("c.untypedField();");

  check("c.intOneArgumentOneOptionalMethod();", [MessageKind.MISSING_ARGUMENT]);
  check("c.intOneArgumentOneOptionalMethod(0);");
  check("c.intOneArgumentOneOptionalMethod(0, 1);");
  check("c.intOneArgumentOneOptionalMethod(0, 1, 2);",
        [MessageKind.ADDITIONAL_ARGUMENT]);
  check("c.intOneArgumentOneOptionalMethod(0, 1, c: 2);",
        [MessageKind.NAMED_ARGUMENT_NOT_FOUND]);
  check("c.intOneArgumentOneOptionalMethod(0, b: 1);",
        [MessageKind.NAMED_ARGUMENT_NOT_FOUND]);
  check("c.intOneArgumentOneOptionalMethod(a: 0, b: 1);",
        [MessageKind.NAMED_ARGUMENT_NOT_FOUND,
         MessageKind.NAMED_ARGUMENT_NOT_FOUND,
         MessageKind.MISSING_ARGUMENT]);

  check("c.intTwoOptionalMethod();");
  check("c.intTwoOptionalMethod(0);");
  check("c.intTwoOptionalMethod(0, 1);");
  check("c.intTwoOptionalMethod(0, 1, 2);", [MessageKind.ADDITIONAL_ARGUMENT]);
  check("c.intTwoOptionalMethod(a: 0);",
        [MessageKind.NAMED_ARGUMENT_NOT_FOUND]);
  check("c.intTwoOptionalMethod(0, b: 1);",
        [MessageKind.NAMED_ARGUMENT_NOT_FOUND]);

  check("c.intOneArgumentOneNamedMethod();", [MessageKind.MISSING_ARGUMENT]);
  check("c.intOneArgumentOneNamedMethod(0);");
  check("c.intOneArgumentOneNamedMethod(0, b: 1);");
  check("c.intOneArgumentOneNamedMethod(b: 1);",
        [MessageKind.MISSING_ARGUMENT]);
  check("c.intOneArgumentOneNamedMethod(0, b: 1, c: 2);",
        [MessageKind.NAMED_ARGUMENT_NOT_FOUND]);
  check("c.intOneArgumentOneNamedMethod(0, 1);",
        [MessageKind.ADDITIONAL_ARGUMENT]);
  check("c.intOneArgumentOneNamedMethod(0, 1, c: 2);",
        [MessageKind.ADDITIONAL_ARGUMENT,
         MessageKind.NAMED_ARGUMENT_NOT_FOUND]);
  check("c.intOneArgumentOneNamedMethod(a: 1, b: 1);",
        [MessageKind.NAMED_ARGUMENT_NOT_FOUND,
         MessageKind.MISSING_ARGUMENT]);

  check("c.intTwoNamedMethod();");
  check("c.intTwoNamedMethod(a: 0);");
  check("c.intTwoNamedMethod(b: 1);");
  check("c.intTwoNamedMethod(a: 0, b: 1);");
  check("c.intTwoNamedMethod(b: 1, a: 0);");
  check("c.intTwoNamedMethod(0);", [MessageKind.ADDITIONAL_ARGUMENT]);
  check("c.intTwoNamedMethod(c: 2);", [MessageKind.NAMED_ARGUMENT_NOT_FOUND]);
  check("c.intTwoNamedMethod(a: 0, c: 2);",
        [MessageKind.NAMED_ARGUMENT_NOT_FOUND]);
  check("c.intTwoNamedMethod(a: 0, b: 1, c: 2);",
        [MessageKind.NAMED_ARGUMENT_NOT_FOUND]);
  check("c.intTwoNamedMethod(c: 2, b: 1, a: 0);",
        [MessageKind.NAMED_ARGUMENT_NOT_FOUND]);
  check("c.intTwoNamedMethod(0, b: 1);", [MessageKind.ADDITIONAL_ARGUMENT]);
  check("c.intTwoNamedMethod(0, 1);",
        [MessageKind.ADDITIONAL_ARGUMENT,
         MessageKind.ADDITIONAL_ARGUMENT]);
  check("c.intTwoNamedMethod(0, c: 2);",
        [MessageKind.ADDITIONAL_ARGUMENT,
         MessageKind.NAMED_ARGUMENT_NOT_FOUND]);
}

void testMethodInvocations() {
  compiler.parseScript(CLASS_WITH_METHODS);

  check(String text, [expectedWarnings]){
    analyze("""{
               ClassWithMethods c;
               SubClass d;
               var e;
               int i;
               int j;
               int localMethod(String str) { return 0; }
               $text
               }
               """, warnings: expectedWarnings);
  }

  check("int k = c.untypedNoArgumentMethod();");
  check("ClassWithMethods x = c.untypedNoArgumentMethod();");
  check("ClassWithMethods x = d.untypedNoArgumentMethod();");
  check("int k = d.intMethod();");
  check("int k = c.untypedOneArgumentMethod(c);");
  check("ClassWithMethods x = c.untypedOneArgumentMethod(1);");
  check("int k = c.untypedOneArgumentMethod('string');");
  check("int k = c.untypedOneArgumentMethod(i);");
  check("int k = d.untypedOneArgumentMethod(d);");
  check("ClassWithMethods x = d.untypedOneArgumentMethod(1);");
  check("int k = d.untypedOneArgumentMethod('string');");
  check("int k = d.untypedOneArgumentMethod(i);");

  check("int k = c.untypedTwoArgumentMethod(1, 'string');");
  check("int k = c.untypedTwoArgumentMethod(i, j);");
  check("ClassWithMethods x = c.untypedTwoArgumentMethod(i, c);");
  check("int k = d.untypedTwoArgumentMethod(1, 'string');");
  check("int k = d.untypedTwoArgumentMethod(i, j);");
  check("ClassWithMethods x = d.untypedTwoArgumentMethod(i, d);");

  check("int k = c.intNoArgumentMethod();");
  check("ClassWithMethods x = c.intNoArgumentMethod();",
        NOT_ASSIGNABLE);

  check("int k = c.intOneArgumentMethod(c);", NOT_ASSIGNABLE);
  check("ClassWithMethods x = c.intOneArgumentMethod(1);",
        NOT_ASSIGNABLE);
  check("int k = c.intOneArgumentMethod('string');",
        NOT_ASSIGNABLE);
  check("int k = c.intOneArgumentMethod(i);");

  check("int k = c.intTwoArgumentMethod(1, 'string');",
        NOT_ASSIGNABLE);
  check("int k = c.intTwoArgumentMethod(i, j);");
  check("ClassWithMethods x = c.intTwoArgumentMethod(i, j);",
        NOT_ASSIGNABLE);

  check("c.functionField();");
  check("d.functionField();");
  check("c.functionField(1);");
  check("d.functionField('string');");

  check("c.intField();", MessageKind.NOT_CALLABLE);
  check("d.intField();", MessageKind.NOT_CALLABLE);

  check("c.untypedField();");
  check("d.untypedField();");
  check("c.untypedField(1);");
  check("d.untypedField('string');");


  check("c.intOneArgumentOneOptionalMethod('');",
        NOT_ASSIGNABLE);
  check("c.intOneArgumentOneOptionalMethod('', '');",
        [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  check("c.intTwoOptionalMethod('');", NOT_ASSIGNABLE);
  check("c.intTwoOptionalMethod('', '');",
        [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  check("c.intOneArgumentOneNamedMethod('');",
        NOT_ASSIGNABLE);
  check("c.intOneArgumentOneNamedMethod('', b: '');",
        [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  check("c.intTwoNamedMethod(a: '');", NOT_ASSIGNABLE);
  check("c.intTwoNamedMethod(b: '');", NOT_ASSIGNABLE);
  check("c.intTwoNamedMethod(a: '', b: '');",
        [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
  check("c.intTwoNamedMethod(b: '', a: '');",
        [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  // Invocation of dynamic variable.
  check("e();");
  check("e(1);");
  check("e('string');");

  // Invocation on local method.
  check("localMethod();", MessageKind.MISSING_ARGUMENT);
  check("localMethod(1);", NOT_ASSIGNABLE);
  check("localMethod('string');");
  check("int k = localMethod('string');");
  check("String k = localMethod('string');", NOT_ASSIGNABLE);

  // Invocation on parenthesized expressions.
  check("(e)();");
  check("(e)(1);");
  check("(e)('string');");
  check("(foo)();");
  check("(foo)(1);");
  check("(foo)('string');");

  // Invocations on function expressions.
  check("(foo){}();", MessageKind.MISSING_ARGUMENT);
  check("(foo){}(1);");
  check("(foo){}('string');");
  check("(int foo){}('string');", NOT_ASSIGNABLE);
  check("(String foo){}('string');");
  check("int k = int bar(String foo){ return 0; }('string');");
  check("int k = String bar(String foo){ return foo; }('string');",
        NOT_ASSIGNABLE);

  // Static invocations.
  check("ClassWithMethods.staticMethod();",
        MessageKind.MISSING_ARGUMENT);
  check("ClassWithMethods.staticMethod(1);",
        NOT_ASSIGNABLE);
  check("ClassWithMethods.staticMethod('string');");
  check("int k = ClassWithMethods.staticMethod('string');");
  check("String k = ClassWithMethods.staticMethod('string');",
        NOT_ASSIGNABLE);

  // Invocation on dynamic variable.
  check("e.foo();");
  check("e.foo(1);");
  check("e.foo('string');");

  // Invocation on unresolved variable.
  check("foo();");
  check("foo(1);");
  check("foo('string');");
  check("foo(a: 'string');");
  check("foo(a: localMethod(1));", NOT_ASSIGNABLE);
}

testMethodInvocationsInClass() {
  LibraryElement library = mockLibrary(compiler, CLASS_WITH_METHODS);
  compiler.parseScript(CLASS_WITH_METHODS, library);
  ClassElement ClassWithMethods = library.find("ClassWithMethods");
  ClassWithMethods.ensureResolved(compiler);
  Element c = ClassWithMethods.lookupLocalMember('method');
  assert(c != null);
  ClassElement SubClass = library.find("SubClass");
  SubClass.ensureResolved(compiler);
  Element d = SubClass.lookupLocalMember('method');
  assert(d != null);

  check(Element element, String text, [expectedWarnings]){
    analyzeIn(element,
              """{
                   var e;
                   int i;
                   int j;
                   int localMethod(String str) { return 0; }
                   $text
                 }""",
              expectedWarnings);
  }


  check(c, "int k = untypedNoArgumentMethod();");
  check(c, "ClassWithMethods x = untypedNoArgumentMethod();");
  check(d, "ClassWithMethods x = untypedNoArgumentMethod();");
  check(d, "int k = intMethod();");
  check(c, "int k = untypedOneArgumentMethod(this);");
  check(c, "ClassWithMethods x = untypedOneArgumentMethod(1);");
  check(c, "int k = untypedOneArgumentMethod('string');");
  check(c, "int k = untypedOneArgumentMethod(i);");
  check(d, "int k = untypedOneArgumentMethod(this);");
  check(d, "ClassWithMethods x = untypedOneArgumentMethod(1);");
  check(d, "int k = untypedOneArgumentMethod('string');");
  check(d, "int k = untypedOneArgumentMethod(i);");

  check(c, "int k = untypedTwoArgumentMethod(1, 'string');");
  check(c, "int k = untypedTwoArgumentMethod(i, j);");
  check(c, "ClassWithMethods x = untypedTwoArgumentMethod(i, this);");
  check(d, "int k = untypedTwoArgumentMethod(1, 'string');");
  check(d, "int k = untypedTwoArgumentMethod(i, j);");
  check(d, "ClassWithMethods x = untypedTwoArgumentMethod(i, this);");

  check(c, "int k = intNoArgumentMethod();");
  check(c, "ClassWithMethods x = intNoArgumentMethod();",
        NOT_ASSIGNABLE);

  check(c, "int k = intOneArgumentMethod('');", NOT_ASSIGNABLE);
  check(c, "ClassWithMethods x = intOneArgumentMethod(1);",
        NOT_ASSIGNABLE);
  check(c, "int k = intOneArgumentMethod('string');",
        NOT_ASSIGNABLE);
  check(c, "int k = intOneArgumentMethod(i);");

  check(c, "int k = intTwoArgumentMethod(1, 'string');",
        NOT_ASSIGNABLE);
  check(c, "int k = intTwoArgumentMethod(i, j);");
  check(c, "ClassWithMethods x = intTwoArgumentMethod(i, j);",
        NOT_ASSIGNABLE);

  check(c, "functionField();");
  check(d, "functionField();");
  check(c, "functionField(1);");
  check(d, "functionField('string');");

  check(c, "intField();", MessageKind.NOT_CALLABLE);
  check(d, "intField();", MessageKind.NOT_CALLABLE);

  check(c, "untypedField();");
  check(d, "untypedField();");
  check(c, "untypedField(1);");
  check(d, "untypedField('string');");


  check(c, "intOneArgumentOneOptionalMethod('');",
        NOT_ASSIGNABLE);
  check(c, "intOneArgumentOneOptionalMethod('', '');",
        [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  check(c, "intTwoOptionalMethod('');", NOT_ASSIGNABLE);
  check(c, "intTwoOptionalMethod('', '');",
        [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  check(c, "intOneArgumentOneNamedMethod('');",
        NOT_ASSIGNABLE);
  check(c, "intOneArgumentOneNamedMethod('', b: '');",
        [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  check(c, "intTwoNamedMethod(a: '');", NOT_ASSIGNABLE);
  check(c, "intTwoNamedMethod(b: '');", NOT_ASSIGNABLE);
  check(c, "intTwoNamedMethod(a: '', b: '');",
        [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
  check(c, "intTwoNamedMethod(b: '', a: '');",
        [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  // Invocation of dynamic variable.
  check(c, "e();");
  check(c, "e(1);");
  check(c, "e('string');");

  // Invocation on local method.
  check(c, "localMethod();", MessageKind.MISSING_ARGUMENT);
  check(c, "localMethod(1);", NOT_ASSIGNABLE);
  check(c, "localMethod('string');");
  check(c, "int k = localMethod('string');");
  check(c, "String k = localMethod('string');", NOT_ASSIGNABLE);

  // Invocation on parenthesized expressions.
  check(c, "(e)();");
  check(c, "(e)(1);");
  check(c, "(e)('string');");
  check(c, "(foo)();", MEMBER_NOT_FOUND);
  check(c, "(foo)(1);", MEMBER_NOT_FOUND);
  check(c, "(foo)('string');", MEMBER_NOT_FOUND);

  // Invocations on function expressions.
  check(c, "(foo){}();", MessageKind.MISSING_ARGUMENT);
  check(c, "(foo){}(1);");
  check(c, "(foo){}('string');");
  check(c, "(int foo){}('string');", NOT_ASSIGNABLE);
  check(c, "(String foo){}('string');");
  check(c, "int k = int bar(String foo){ return 0; }('string');");
  check(c, "int k = String bar(String foo){ return foo; }('string');",
        NOT_ASSIGNABLE);

  // Static invocations.
  check(c, "staticMethod();",
        MessageKind.MISSING_ARGUMENT);
  check(c, "staticMethod(1);",
        NOT_ASSIGNABLE);
  check(c, "staticMethod('string');");
  check(c, "int k = staticMethod('string');");
  check(c, "String k = staticMethod('string');",
        NOT_ASSIGNABLE);
  check(d, "staticMethod();", MessageKind.METHOD_NOT_FOUND);
  check(d, "staticMethod(1);", MessageKind.METHOD_NOT_FOUND);
  check(d, "staticMethod('string');", MessageKind.METHOD_NOT_FOUND);
  check(d, "int k = staticMethod('string');", MessageKind.METHOD_NOT_FOUND);
  check(d, "String k = staticMethod('string');", MessageKind.METHOD_NOT_FOUND);

  // Invocation on dynamic variable.
  check(c, "e.foo();");
  check(c, "e.foo(1);");
  check(c, "e.foo('string');");

  // Invocation on unresolved variable.
  check(c, "foo();", MessageKind.METHOD_NOT_FOUND);
  check(c, "foo(1);", MessageKind.METHOD_NOT_FOUND);
  check(c, "foo('string');", MessageKind.METHOD_NOT_FOUND);
  check(c, "foo(a: 'string');", MessageKind.METHOD_NOT_FOUND);
  check(c, "foo(a: localMethod(1));",
      [MessageKind.METHOD_NOT_FOUND, NOT_ASSIGNABLE]);
}

/** Tests analysis of returns (not required by the specification). */
void testControlFlow() {
  analyzeTopLevel("void foo() { if (true) { return; } }");
  analyzeTopLevel("foo() { if (true) { return; } }");
  analyzeTopLevel("int foo() { if (true) { return 1; } }",
                  MessageKind.MAYBE_MISSING_RETURN);
  final bar =
      """void bar() {
        if (true) {
          if (true) { return; } else { return; }
        } else { return; }
      }""";
  analyzeTopLevel(bar);
  analyzeTopLevel("void baz() { return; int i = 1; }",
                  MessageKind.UNREACHABLE_CODE);
  final qux =
      """void qux() {
        if (true) {
          return;
        } else if (true) {
          if (true) {
            return;
          }
          throw 'hest';
        }
        throw 'fisk';
      }""";
  analyzeTopLevel(qux);
  analyzeTopLevel("int hest() {}", MessageKind.MISSING_RETURN);
  final fisk = """int fisk() {
                    if (true) {
                      if (true) { return 1; } else {}
                    } else { return 1; }
                  }""";
  analyzeTopLevel(fisk, MessageKind.MAYBE_MISSING_RETURN);
  analyzeTopLevel("int foo() { while(true) { return 1; } }");
  analyzeTopLevel("int foo() { while(true) { return 1; } return 2; }",
                  MessageKind.UNREACHABLE_CODE);
}


void testFunctionCall() {
  compiler.parseScript(CLASS_WITH_METHODS);

  check(String text, [expectedWarnings]){
    analyze("""{
               ClassWithMethods x;
               int localMethod(String str) { return 0; }
               String2Int string2int;
               Function function;
               SubFunction subFunction;
               $text
               }
               """, warnings: expectedWarnings);
  }

  check("int k = localMethod.call('');");
  check("String k = localMethod.call('');", NOT_ASSIGNABLE);
  check("int k = localMethod.call(0);", NOT_ASSIGNABLE);

  check("int k = ClassWithMethods.staticMethod.call('');");
  check("String k = ClassWithMethods.staticMethod.call('');", NOT_ASSIGNABLE);
  check("int k = ClassWithMethods.staticMethod.call(0);", NOT_ASSIGNABLE);

  check("int k = x.instanceMethod.call('');");
  check("String k = x.instanceMethod.call('');", NOT_ASSIGNABLE);
  check("int k = x.instanceMethod.call(0);", NOT_ASSIGNABLE);

  check("int k = topLevelMethod.call('');");
  check("String k = topLevelMethod.call('');", NOT_ASSIGNABLE);
  check("int k = topLevelMethod.call(0);", NOT_ASSIGNABLE);

  check("((String s) { return 0; }).call('');");
  check("((String s) { return 0; }).call(0);", NOT_ASSIGNABLE);

  check("(int f(String x)) { int i = f.call(''); } (null);");
  check("(int f(String x)) { String s = f.call(''); } (null);", NOT_ASSIGNABLE);
  check("(int f(String x)) { int i = f.call(0); } (null);", NOT_ASSIGNABLE);

  check("int k = string2int.call('');");
  check("String k = string2int.call('');", NOT_ASSIGNABLE);
  check("int k = string2int.call(0);", NOT_ASSIGNABLE);

  check("int k = x.string2int.call('');");
  check("String k = x.string2int.call('');", NOT_ASSIGNABLE);
  check("int k = x.string2int.call(0);", NOT_ASSIGNABLE);

  check("int k = function.call('');");
  check("String k = function.call('');");
  check("int k = function.call(0);");

  check("int k = subFunction.call('');");
  check("String k = subFunction.call('');");
  check("int k = subFunction.call(0);");
}

testNewExpression() {
  compiler.parseScript("class A {}");
  analyze("A a = new A();");
  analyze("int i = new A();", warnings: NOT_ASSIGNABLE);

// TODO(karlklose): constructors are not yet implemented.
//  compiler.parseScript(
//    "class Foo {\n" +
//    "  Foo(int x) {}\n" +
//    "  Foo.foo() {}\n" +
//    "  Foo.bar([int i = null]) {}\n" +
//    "}\n" +
//    "abstract class Bar<T> {\n" +
//    "  factory Bar.make() => new Baz<T>.make();\n" +
//    "}\n" +
//    "class Baz {\n" +
//    "  factory Bar<S>.make(S x) { return null; }\n" +
//    "}");
//
//  analyze("Foo x = new Foo(0);");
//  analyze("Foo x = new Foo();", MessageKind.MISSING_ARGUMENT);
//  analyze("Foo x = new Foo('');", NOT_ASSIGNABLE);
//  analyze("Foo x = new Foo(0, null);", MessageKind.ADDITIONAL_ARGUMENT);
//
//  analyze("Foo x = new Foo.foo();");
//  analyze("Foo x = new Foo.foo(null);", MessageKind.ADDITIONAL_ARGUMENT);
//
//  analyze("Foo x = new Foo.bar();");
//  analyze("Foo x = new Foo.bar(0);");
//  analyze("Foo x = new Foo.bar('');", NOT_ASSIGNABLE);
//  analyze("Foo x = new Foo.bar(0, null);",
//          MessageKind.ADDITIONAL_ARGUMENT);
//
//  analyze("Bar<String> x = new Bar<String>.make('');");
}

testConditionalExpression() {
  analyze("int i = true ? 2 : 1;");
  analyze("int i = true ? 'hest' : 1;");
  analyze("int i = true ? 'hest' : 'fisk';", warnings: NOT_ASSIGNABLE);
  analyze("String s = true ? 'hest' : 'fisk';");

  analyze("true ? 1 : 2;");
  analyze("null ? 1 : 2;");
  analyze("0 ? 1 : 2;", warnings: NOT_ASSIGNABLE);
  analyze("'' ? 1 : 2;", warnings: NOT_ASSIGNABLE);
  analyze("{ int i; true ? i = 2.7 : 2; }",
          warnings: NOT_ASSIGNABLE);
  analyze("{ int i; true ? 2 : i = 2.7; }",
          warnings: NOT_ASSIGNABLE);
  analyze("{ int i; i = true ? 2.7 : 2; }");
}

testIfStatement() {
  analyze("if (true) {}");
  analyze("if (null) {}");
  analyze("if (0) {}",
          warnings: NOT_ASSIGNABLE);
  analyze("if ('') {}",
          warnings: NOT_ASSIGNABLE);
  analyze("{ int i = 27; if (true) { i = 2.7; } else {} }",
          warnings: NOT_ASSIGNABLE);
  analyze("{ int i = 27; if (true) {} else { i = 2.7; } }",
          warnings: NOT_ASSIGNABLE);
}

testThis() {
  String script = """class Foo {
                       void method() {}
                     }""";
  LibraryElement library = mockLibrary(compiler, script);
  compiler.parseScript(script, library);
  ClassElement foo = library.find("Foo");
  foo.ensureResolved(compiler);
  Element method = foo.lookupLocalMember('method');
  analyzeIn(method, "{ int i = this; }", NOT_ASSIGNABLE);
  analyzeIn(method, "{ Object o = this; }");
  analyzeIn(method, "{ Foo f = this; }");
}

testSuper() {
  String script = r'''
    class A {
      String field = "42";
    }

    class B extends A {
      Object field = 42;
      void method() {}
    }
    ''';
  LibraryElement library = mockLibrary(compiler, script);
  compiler.parseScript(script, library);
  ClassElement B = library.find("B");
  B.ensureResolved(compiler);
  Element method = B.lookupLocalMember('method');
  analyzeIn(method, "{ int i = super.field; }", NOT_ASSIGNABLE);
  analyzeIn(method, "{ Object o = super.field; }");
  analyzeIn(method, "{ String s = super.field; }");
}

const String CLASSES_WITH_OPERATORS = '''
class Operators {
  Operators operator +(Operators other) => this;
  Operators operator -(Operators other) => this;
  Operators operator -() => this;
  Operators operator *(Operators other) => this;
  Operators operator /(Operators other) => this;
  Operators operator %(Operators other) => this;
  Operators operator ~/(Operators other) => this;

  Operators operator &(Operators other) => this;
  Operators operator |(Operators other) => this;
  Operators operator ^(Operators other) => this;

  Operators operator ~() => this;

  Operators operator <(Operators other) => true;
  Operators operator >(Operators other) => false;
  Operators operator <=(Operators other) => this;
  Operators operator >=(Operators other) => this;

  Operators operator <<(Operators other) => this;
  Operators operator >>(Operators other) => this;

  bool operator ==(Operators other) => true;

  Operators operator [](Operators key) => this;
  void operator []=(Operators key, Operators value) {}
}

class MismatchA {
  int operator+(MismatchA other) => 0;
  MismatchA operator-(int other) => this;

  MismatchA operator[](int key) => this;
  void operator[]=(int key, MismatchA value) {}
}

class MismatchB {
  MismatchB operator+(MismatchB other) => this;

  MismatchB operator[](int key) => this;
  void operator[]=(String key, MismatchB value) {}
}

class MismatchC {
  MismatchC operator+(MismatchC other) => this;

  MismatchC operator[](int key) => this;
  void operator[]=(int key, String value) {}
}
''';

testOperatorsAssignability() {
  compiler.parseScript(CLASSES_WITH_OPERATORS);

  // Tests against Operators.

  String header = """{
      bool z;
      Operators a;
      Operators b;
      Operators c;
      """;

  check(String text, [expectedWarnings]) {
    analyze('$header $text }', warnings: expectedWarnings);
  }

  // Positive tests on operators.

  check('c = a + b;');
  check('c = a - b;');
  check('c = -a;');
  check('c = a * b;');
  check('c = a / b;');
  check('c = a % b;');
  check('c = a ~/ b;');

  check('c = a & b;');
  check('c = a | b;');
  check('c = a ^ b;');

  check('c = ~a;');

  check('c = a < b;');
  check('c = a > b;');
  check('c = a <= b;');
  check('c = a >= b;');

  check('c = a << b;');
  check('c = a >> b;');

  check('c = a[b];');

  check('a[b] = c;');
  check('a[b] += c;');
  check('a[b] -= c;');
  check('a[b] *= c;');
  check('a[b] /= c;');
  check('a[b] %= c;');
  check('a[b] ~/= c;');
  check('a[b] <<= c;');
  check('a[b] >>= c;');
  check('a[b] &= c;');
  check('a[b] |= c;');
  check('a[b] ^= c;');

  check('a += b;');
  check('a -= b;');
  check('a *= b;');
  check('a /= b;');
  check('a %= b;');
  check('a ~/= b;');

  check('a <<= b;');
  check('a >>= b;');

  check('a &= b;');
  check('a |= b;');
  check('a ^= b;');

  // Negative tests on operators.

  // For the sake of brevity we misuse the terminology in comments:
  //  'e1 is not assignable to e2' should be read as
  //     'the type of e1 is not assignable to the type of e2', and
  //  'e1 is not assignable to operator o on e2' should be read as
  //     'the type of e1 is not assignable to the argument type of operator o
  //      on e2'.

  // `0` is not assignable to operator + on `a`.
  check('c = a + 0;', NOT_ASSIGNABLE);
  // `a + b` is not assignable to `z`.
  check('z = a + b;', NOT_ASSIGNABLE);

  // `-a` is not assignable to `z`.
  check('z = -a;', NOT_ASSIGNABLE);

  // `0` is not assignable to operator [] on `a`.
  check('c = a[0];', NOT_ASSIGNABLE);
  // `a[b]` is not assignable to `z`.
  check('z = a[b];', NOT_ASSIGNABLE);

  // `0` is not assignable to operator [] on `a`.
  // Warning suppressed for `0` is not assignable to operator []= on `a`.
  check('a[0] *= c;', NOT_ASSIGNABLE);
  // `z` is not assignable to operator * on `a[0]`.
  check('a[b] *= z;', NOT_ASSIGNABLE);

  check('b = a++;', NOT_ASSIGNABLE);
  check('b = ++a;', NOT_ASSIGNABLE);
  check('b = a--;', NOT_ASSIGNABLE);
  check('b = --a;', NOT_ASSIGNABLE);

  check('c = a[b]++;', NOT_ASSIGNABLE);
  check('c = ++a[b];', NOT_ASSIGNABLE);
  check('c = a[b]--;', NOT_ASSIGNABLE);
  check('c = --a[b];', NOT_ASSIGNABLE);

  check('z = a == b;');
  check('z = a != b;');

  for (String o in ['&&', '||']) {
    check('z = z $o z;');
    check('z = a $o z;', NOT_ASSIGNABLE);
    check('z = z $o b;', NOT_ASSIGNABLE);
    check('z = a $o b;',
        [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
    check('a = a $o b;',
        [NOT_ASSIGNABLE, NOT_ASSIGNABLE,
         NOT_ASSIGNABLE]);
  }

  check('z = !z;');
  check('z = !a;', NOT_ASSIGNABLE);
  check('a = !z;', NOT_ASSIGNABLE);
  check('a = !a;',
      [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);


  // Tests against MismatchA.

  header = """{
      MismatchA a;
      MismatchA b;
      MismatchA c;
      """;

  // Tests against int operator +(MismatchA other) => 0;

  // `a + b` is not assignable to `c`.
  check('c = a + b;', NOT_ASSIGNABLE);
  // `a + b` is not assignable to `a`.
  check('a += b;', NOT_ASSIGNABLE);
  // `a[0] + b` is not assignable to `a[0]`.
  check('a[0] += b;', NOT_ASSIGNABLE);

  // 1 is not applicable to operator +.
  check('b = a++;', NOT_ASSIGNABLE);
  // 1 is not applicable to operator +.
  // `++a` of type int is not assignable to `b`.
  check('b = ++a;',
      [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  // 1 is not applicable to operator +.
  check('b = a[0]++;', NOT_ASSIGNABLE);
  // 1 is not applicable to operator +.
  // `++a[0]` of type int is not assignable to `b`.
  check('b = ++a[0];',
      [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  // Tests against: MismatchA operator -(int other) => this;

  // `a - b` is not assignable to `c`.
  check('c = a + b;', NOT_ASSIGNABLE);
  // `a - b` is not assignable to `a`.
  check('a += b;', NOT_ASSIGNABLE);
  // `a[0] - b` is not assignable to `a[0]`.
  check('a[0] += b;', NOT_ASSIGNABLE);

  check('b = a--;');
  check('b = --a;');

  check('b = a[0]--;');
  check('b = --a[0];');

  // Tests against MismatchB.

  header = """{
      MismatchB a;
      MismatchB b;
      MismatchB c;
      """;

  // Tests against:
  // MismatchB operator [](int key) => this;
  // void operator []=(String key, MismatchB value) {}

  // `0` is not applicable to operator []= on `a`.
  check('a[0] = b;', NOT_ASSIGNABLE);

  // `0` is not applicable to operator []= on `a`.
  check('a[0] += b;', NOT_ASSIGNABLE);
  // `""` is not applicable to operator [] on `a`.
  check('a[""] += b;', NOT_ASSIGNABLE);
  // `c` is not applicable to operator [] on `a`.
  // `c` is not applicable to operator []= on `a`.
  check('a[c] += b;',
      [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);


  // Tests against MismatchB.

  header = """{
      MismatchC a;
      MismatchC b;
      MismatchC c;
      """;

  // Tests against:
  // MismatchC operator[](int key) => this;
  // void operator[]=(int key, String value) {}

  // `b` is not assignable to `a[0]`.
  check('a[0] += b;', NOT_ASSIGNABLE);
  // `0` is not applicable to operator + on `a[0]`.
  check('a[0] += "";',
      [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
  // `true` is not applicable to operator + on `a[0]`.
  // `true` is not assignable to `a[0]`.
  check('a[0] += true;',
      [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
}

void testFieldInitializers() {
  analyzeTopLevel("""int i = 0;""");
  analyzeTopLevel("""int i = '';""", NOT_ASSIGNABLE);

  analyzeTopLevel("""class Class {
                       int i = 0;
                     }""");
  analyzeTopLevel("""class Class {
                       int i = '';
                     }""", NOT_ASSIGNABLE);
}

void testTypeVariableExpressions() {
  String script = """class Foo<T> {
                       void method() {}
                     }""";
  LibraryElement library = mockLibrary(compiler, script);
  compiler.parseScript(script, library);
  ClassElement foo = library.find("Foo");
  foo.ensureResolved(compiler);
  Element method = foo.lookupLocalMember('method');

  analyzeIn(method, "{ Type type = T; }");
  analyzeIn(method, "{ T type = T; }", NOT_ASSIGNABLE);
  analyzeIn(method, "{ int type = T; }", NOT_ASSIGNABLE);

  analyzeIn(method, "{ String typeName = T.toString(); }");
  analyzeIn(method, "{ T.foo; }", MEMBER_NOT_FOUND);
  analyzeIn(method, "{ T.foo = 0; }", MessageKind.SETTER_NOT_FOUND);
  analyzeIn(method, "{ T.foo(); }", MessageKind.METHOD_NOT_FOUND);
  analyzeIn(method, "{ T + 1; }", MessageKind.OPERATOR_NOT_FOUND);
}

void testTypeVariableLookup1() {
  String script = """
class Foo {
  int field;
  void method(int argument) {}
  int operator +(Foo foo) {}
  int get getter => 21;
}

class Test<S extends Foo, T> {
  S s;
  T t;
  test() {}
}
""";

  LibraryElement library = mockLibrary(compiler, script);
  compiler.parseScript(script, library);
  ClassElement classTest = library.find("Test");
  classTest.ensureResolved(compiler);
  FunctionElement methodTest = classTest.lookupLocalMember("test");

  test(String expression, [message]) {
    analyzeIn(methodTest, "{ $expression; }", message);
  }

  test('s.field');
  test('s.method(1)');
  test('s + s');
  test('s.getter');

  test('t.toString');
  test('t.field', MEMBER_NOT_FOUND);
  test('t.method(1)', MessageKind.METHOD_NOT_FOUND);
  test('t + t', MessageKind.OPERATOR_NOT_FOUND);
  test('t.getter', MEMBER_NOT_FOUND);

  test('s.field = "hest"', NOT_ASSIGNABLE);
  test('s.method("hest")', NOT_ASSIGNABLE);
  test('s + "hest"', NOT_ASSIGNABLE);
  test('String v = s.getter', NOT_ASSIGNABLE);
}

void testTypeVariableLookup2() {
  String script = """
class Foo {
  int field;
  void method(int argument) {}
  int operator +(Foo foo) {}
  int get getter => 21;
}

class Test<S extends T, T extends Foo> {
  S s;
  test() {}
}""";

  LibraryElement library = mockLibrary(compiler, script);
  compiler.parseScript(script, library);
  ClassElement classTest = library.find("Test");
  classTest.ensureResolved(compiler);
  FunctionElement methodTest = classTest.lookupLocalMember("test");

  test(String expression, [message]) {
    analyzeIn(methodTest, "{ $expression; }", message);
  }

  test('s.field');
  test('s.method(1)');
  test('s + s');
  test('s.getter');
}

void testTypeVariableLookup3() {
  String script = """
class Test<S extends T, T extends S> {
  S s;
  test() {}
}""";

  LibraryElement library = mockLibrary(compiler, script);
  compiler.parseScript(script, library);
  ClassElement classTest = library.find("Test");
  classTest.ensureResolved(compiler);
  FunctionElement methodTest = classTest.lookupLocalMember("test");

  test(String expression, [message]) {
    analyzeIn(methodTest, "{ $expression; }", message);
  }

  test('s.toString');
  test('s.field', MEMBER_NOT_FOUND);
  test('s.method(1)', MessageKind.METHOD_NOT_FOUND);
  test('s + s', MessageKind.OPERATOR_NOT_FOUND);
  test('s.getter', MEMBER_NOT_FOUND);
}

void testFunctionTypeLookup() {
  analyze('(int f(int)) => f.toString;');
  analyze('(int f(int)) => f.toString();');
  analyze('(int f(int)) => f.foo;', warnings: MEMBER_NOT_FOUND);
  analyze('(int f(int)) => f.foo();', warnings: MessageKind.METHOD_NOT_FOUND);
}

void testTypedefLookup() {
  compiler.parseScript("typedef int F(int);");
  analyze('(F f) => f.toString;');
  analyze('(F f) => f.toString();');
  analyze('(F f) => f.foo;', warnings: MEMBER_NOT_FOUND);
  analyze('(F f) => f.foo();', warnings: MessageKind.METHOD_NOT_FOUND);
}

void testTypeLiteral() {
  final String source = r"""class Class {
                              static var field = null;
                              static method() {}
                            }""";
  compiler.parseScript(source);

  // Check direct access.
  analyze('Type m() => int;');
  analyze('int m() => int;', warnings: NOT_ASSIGNABLE);

  // Check access in assignment.
  analyze('m(Type val) => val = Class;');
  analyze('m(int val) => val = Class;', warnings: NOT_ASSIGNABLE);

  // Check access as argument.
  analyze('m(Type val) => m(int);');
  analyze('m(int val) => m(int);', warnings: NOT_ASSIGNABLE);

  // Check access as argument in member access.
  analyze('m(Type val) => m(int).foo;');
  analyze('m(int val) => m(int).foo;', warnings: NOT_ASSIGNABLE);

  // Check static property access.
  analyze('m() => Class.field;');
  analyze('m() => (Class).field;', warnings: MEMBER_NOT_FOUND);

  // Check static method access.
  analyze('m() => Class.method();');
  analyze('m() => (Class).method();', warnings: MessageKind.METHOD_NOT_FOUND);
}

void testInitializers() {
  check(String text, [expectedWarnings]) {
    analyzeTopLevel(text, expectedWarnings);
  }

  // Check initializers.
  check(r'''class Class {
              var a;
              Class(this.a);
            }
            ''');
  check(r'''class Class {
              int a;
              Class(this.a);
            }
            ''');
  check(r'''class Class {
              var a;
              Class(int this.a);
            }
            ''');
  check(r'''class Class {
              String a;
              Class(int this.a);
            }
            ''', NOT_ASSIGNABLE);
  check(r'''class Class {
              var a;
              Class(int a) : this.a = a;
            }
            ''');
  check(r'''class Class {
              String a;
              Class(int a) : this.a = a;
            }
            ''', NOT_ASSIGNABLE);

  // Check this-calls.
  check(r'''class Class {
              var a;
              Class(this.a);
              Class.named(int a) : this(a);
            }
            ''');
  check(r'''class Class {
              String a;
              Class(this.a);
              Class.named(int a) : this(a);
            }
            ''', NOT_ASSIGNABLE);
  check(r'''class Class {
              String a;
              Class(var a) : this.a = a;
              Class.named(int a) : this(a);
            }
            ''');
  check(r'''class Class {
              String a;
              Class(String a) : this.a = a;
              Class.named(int a) : this(a);
            }
            ''', NOT_ASSIGNABLE);

  // Check super-calls.
  check(r'''class Super {
              var a;
              Super(this.a);
            }
            class Class extends Super {
              Class.named(int a) : super(a);
            }
            ''');
  check(r'''class Super {
              String a;
              Super(this.a);
            }
            class Class extends Super {
              Class.named(int a) : super(a);
            }
            ''', NOT_ASSIGNABLE);
  check(r'''class Super {
              String a;
              Super(var a) : this.a = a;
            }
            class Class extends Super {
              Class.named(int a) : super(a);
            }
            ''');
  check(r'''class Super {
              String a;
              Super(String a) : this.a = a;
            }
            class Class extends Super {
              Class.named(int a) : super(a);
            }
            ''', NOT_ASSIGNABLE);

  // Check super-calls involving generics.
  check(r'''class Super<T> {
              var a;
              Super(this.a);
            }
            class Class extends Super<String> {
              Class.named(int a) : super(a);
            }
            ''');
  check(r'''class Super<T> {
              T a;
              Super(this.a);
            }
            class Class extends Super<String> {
              Class.named(int a) : super(a);
            }
            ''', NOT_ASSIGNABLE);
  check(r'''class Super<T> {
              T a;
              Super(var a) : this.a = a;
            }
            class Class extends Super<String> {
              Class.named(int a) : super(a);
            }
            ''');
  check(r'''class Super<T> {
              T a;
              Super(T a) : this.a = a;
            }
            class Class extends Super<String> {
              Class.named(int a) : super(a);
            }
            ''', NOT_ASSIGNABLE);

  // Check instance creations.
  check(r'''class Class {
              var a;
              Class(this.a);
            }
            method(int a) => new Class(a);
            ''');
  check(r'''class Class {
              String a;
              Class(this.a);
            }
            method(int a) => new Class(a);
            ''', NOT_ASSIGNABLE);
  check(r'''class Class {
              String a;
              Class(var a) : this.a = a;
            }
            method(int a) => new Class(a);
            ''');
  check(r'''class Class {
              String a;
              Class(String a) : this.a = a;
            }
            method(int a) => new Class(a);
            ''', NOT_ASSIGNABLE);

  // Check instance creations involving generics.
  check(r'''class Class<T> {
              var a;
              Class(this.a);
            }
            method(int a) => new Class<String>(a);
            ''');
  check(r'''class Class<T> {
              T a;
              Class(this.a);
            }
            method(int a) => new Class<String>(a);
            ''', NOT_ASSIGNABLE);
  check(r'''class Class<T> {
              T a;
              Class(var a) : this.a = a;
            }
            method(int a) => new Class<String>(a);
            ''');
  check(r'''class Class<T> {
              T a;
              Class(String a) : this.a = a;
            }
            method(int a) => new Class<String>(a);
            ''', NOT_ASSIGNABLE);
}

void testGetterSetterInvocation() {
  compiler.parseScript(r'''int get variable => 0;
                           void set variable(String s) {}

                           class Class {
                             int get instanceField => 0;
                             void set instanceField(String s) {}

                             static int get staticField => 0;
                             static void set staticField(String s) {}

                             int overriddenField;
                             int get getterField => 0;
                             void set setterField(int v) {}
                           }

                           class GetterClass extends Class {
                             int get overriddenField => super.overriddenField;
                             int get setterField => 0;
                           }

                           class SetterClass extends Class {
                             void set overriddenField(int v) {}
                             void set getterField(int v) {}
                           }

                           Class c;
                           GetterClass gc;
                           SetterClass sc;
                           ''');

  check(String text, [expectedWarnings]) {
    analyze('{ $text }', warnings: expectedWarnings);
  }

  check("variable = '';");
  check("int v = variable;");
  check("variable = 0;", NOT_ASSIGNABLE);
  check("String v = variable;", NOT_ASSIGNABLE);
  // num is not assignable to String (the type of the setter).
  check("variable += 0;", NOT_ASSIGNABLE);
  // String is not assignable to int (the argument type of the operator + on the
  // getter) and num (the result type of the operation) is not assignable to
  // String (the type of the setter).
  check("variable += '';",
      [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  check("c.instanceField = '';");
  check("int v = c.instanceField;");
  check("c.instanceField = 0;", NOT_ASSIGNABLE);
  check("String v = c.instanceField;", NOT_ASSIGNABLE);

  // num is not assignable to String (the type of the setter).
  check("c.instanceField += 0;", NOT_ASSIGNABLE);
  // String is not assignable to int (the argument type of the operator + on the
  // getter) and num (the result type of the operation) is not assignable to
  // String (the type of the setter).
  check("c.instanceField += '';",
      [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  check("Class.staticField = '';");
  check("int v = Class.staticField;");
  check("Class.staticField = 0;", NOT_ASSIGNABLE);
  check("String v = Class.staticField;", NOT_ASSIGNABLE);

  // num is not assignable to String (the type of the setter).
  check("Class.staticField += 0;", NOT_ASSIGNABLE);
  // String is not assignable to int (the argument type of the operator + on the
  // getter) and num (the result type of the operation) is not assignable to
  // String (the type of the setter).
  check("Class.staticField += '';",
        [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  check("int v = c.overriddenField;");
  check("c.overriddenField = 0;");
  check("int v = c.getterField;");
  check("c.getterField = 0;", MessageKind.SETTER_NOT_FOUND);
  check("int v = c.setterField;", MessageKind.GETTER_NOT_FOUND);
  check("c.setterField = 0;");

  check("int v = gc.overriddenField;");
  check("gc.overriddenField = 0;");
  check("int v = gc.setterField;");
  check("gc.setterField = 0;");
  check("int v = gc.getterField;");
  check("gc.getterField = 0;", MessageKind.SETTER_NOT_FOUND);

  check("int v = sc.overriddenField;");
  check("sc.overriddenField = 0;");
  check("int v = sc.getterField;");
  check("sc.getterField = 0;");
  check("int v = sc.setterField;", MessageKind.GETTER_NOT_FOUND);
  check("sc.setterField = 0;");
}

testTypePromotionHints() {
  compiler.parseScript(r'''class A {
                             var a = "a";
                           }
                           class B extends A {
                             var b = "b";
                           }
                           class C {
                             var c = "c";
                           }
                           class D<T> {
                             T d;
                           }
                           class E<T> extends D<T> {
                             T e;
                           }
                           class F<S, U> extends E<S> {
                             S f;
                           }
                           class G<V> extends F<V, V> {
                             V g;
                           }
                           ''');

  check(String text, {warnings, hints, infos}) {
    analyze('{ $text }', warnings: warnings, hints: hints, infos: infos);
  }

  check(r'''
            A a = new B();
            if (a is C) {
              var x = a.c;
            }''',
        warnings: [MessageKind.MEMBER_NOT_FOUND],
        hints: [MessageKind.NOT_MORE_SPECIFIC_SUBTYPE],
        infos: []);

  check(r'''
            A a = new B();
            if (a is C) {
              var x = '${a.c}${a.c}';
            }''',
        warnings: [MessageKind.MEMBER_NOT_FOUND,
                   MessageKind.MEMBER_NOT_FOUND],
        hints: [MessageKind.NOT_MORE_SPECIFIC_SUBTYPE],
        infos: []);

  check(r'''
            A a = new B();
            if (a is C) {
              var x = '${a.d}${a.d}'; // Type promotion wouldn't help.
            }''',
        warnings: [MessageKind.MEMBER_NOT_FOUND,
                   MessageKind.MEMBER_NOT_FOUND],
        hints: [],
        infos: []);

  check('''
           D<int> d = new E();
           if (d is E) { // Suggest E<int>.
             var x = d.e;
           }''',
        warnings: [MessageKind.MEMBER_NOT_FOUND],
        hints: [checkMessage(MessageKind.NOT_MORE_SPECIFIC_SUGGESTION,
                             {'shownTypeSuggestion': 'E<int>'})],
        infos: []);

  check('''
           D<int> d = new F();
           if (d is F) { // Suggest F<int, dynamic>.
             var x = d.f;
           }''',
        warnings: [MessageKind.MEMBER_NOT_FOUND],
        hints: [checkMessage(MessageKind.NOT_MORE_SPECIFIC_SUGGESTION,
                             {'shownTypeSuggestion': 'F<int, dynamic>'})],
        infos: []);

  check('''
           D<int> d = new G();
           if (d is G) { // Suggest G<int>.
             var x = d.f;
           }''',
        warnings: [MessageKind.MEMBER_NOT_FOUND],
        hints: [checkMessage(MessageKind.NOT_MORE_SPECIFIC_SUGGESTION,
                             {'shownTypeSuggestion': 'G<int>'})],
        infos: []);

  check('''
           F<double, int> f = new G();
           if (f is G) { // Cannot suggest a more specific type.
             var x = f.g;
           }''',
        warnings: [MessageKind.MEMBER_NOT_FOUND],
        hints: [MessageKind.NOT_MORE_SPECIFIC],
        infos: []);

  check('''
           D<int> d = new E();
           if (d is E) {
             var x = d.f; // Type promotion wouldn't help.
           }''',
        warnings: [MessageKind.MEMBER_NOT_FOUND],
        hints: [],
        infos: []);

  check('''
           A a = new B();
           if (a is B) {
             a = null;
             var x = a.b;
           }''',
        warnings: [MessageKind.MEMBER_NOT_FOUND],
        hints: [MessageKind.POTENTIAL_MUTATION],
        infos: [MessageKind.POTENTIAL_MUTATION_HERE]);

  check('''
           A a = new B();
           if (a is B) {
             a = null;
             var x = a.c; // Type promotion wouldn't help.
           }''',
        warnings: [MessageKind.MEMBER_NOT_FOUND],
        hints: [],
        infos: []);

  check('''
           A a = new B();
           local() { a = new A(); }
           if (a is B) {
             var x = a.b;
           }''',
        warnings: [MessageKind.MEMBER_NOT_FOUND],
        hints: [MessageKind.POTENTIAL_MUTATION_IN_CLOSURE],
        infos: [MessageKind.POTENTIAL_MUTATION_IN_CLOSURE_HERE]);

  check('''
           A a = new B();
           local() { a = new A(); }
           if (a is B) {
             var x = a.c; // Type promotion wouldn't help.
           }''',
        warnings: [MessageKind.MEMBER_NOT_FOUND],
        hints: [],
        infos: []);

  check('''
           A a = new B();
           if (a is B) {
             var x = () => a;
             var y = a.b;
           }
           a = new A();''',
      warnings: [MessageKind.MEMBER_NOT_FOUND],
      hints: [MessageKind.ACCESSED_IN_CLOSURE],
      infos: [MessageKind.ACCESSED_IN_CLOSURE_HERE,
              MessageKind.POTENTIAL_MUTATION_HERE]);

  check('''
           A a = new B();
           if (a is B) {
             var x = () => a;
             var y = a.c; // Type promotion wouldn't help.
           }
           a = new A();''',
      warnings: [MessageKind.MEMBER_NOT_FOUND],
      hints: [],
      infos: []);
}

const CLASS_WITH_METHODS = '''
typedef int String2Int(String s);

int topLevelMethod(String s) {}

class ClassWithMethods {
  untypedNoArgumentMethod() {}
  untypedOneArgumentMethod(argument) {}
  untypedTwoArgumentMethod(argument1, argument2) {}

  int intNoArgumentMethod() {}
  int intOneArgumentMethod(int argument) {}
  int intTwoArgumentMethod(int argument1, int argument2) {}

  void intOneArgumentOneOptionalMethod(int a, [int b]) {}
  void intTwoOptionalMethod([int a, int b]) {}
  void intOneArgumentOneNamedMethod(int a, {int b}) {}
  void intTwoNamedMethod({int a, int b}) {}

  Function functionField;
  var untypedField;
  int intField;

  static int staticMethod(String str) {}
  int instanceMethod(String str) {}

  void method() {}

  String2Int string2int;
}
class I {
  int intMethod();
}
class SubClass extends ClassWithMethods implements I {
  void method() {}
}
class SubFunction implements Function {}''';

Types types;
MockCompiler compiler;

String returnWithType(String type, expression) {
  return "$type foo() { return $expression; }";
}

Node parseExpression(String text) =>
  parseBodyCode(text, (parser, token) => parser.parseExpression(token));

const String NUM_SOURCE = '''
abstract class num {
  num operator +(num other);
  num operator -(num other);
  num operator *(num other);
  num operator %(num other);
  double operator /(num other);
  int operator ~/(num other);
  num operator -();
  bool operator <(num other);
  bool operator <=(num other);
  bool operator >(num other);
  bool operator >=(num other);
}
''';

const String INT_SOURCE = '''
abstract class int extends num {
  int operator &(int other);
  int operator |(int other);
  int operator ^(int other);
  int operator ~();
  int operator <<(int shiftAmount);
  int operator >>(int shiftAmount);
  int operator -();
}
''';

const String STRING_SOURCE = '''
class String implements Pattern {
  String operator +(String other) => this;
}
''';

void setup() {
  RegExp classNum = new RegExp(r'abstract class num {}');
  Expect.isTrue(DEFAULT_CORELIB.contains(classNum));
  RegExp classInt = new RegExp(r'abstract class int extends num { }');
  Expect.isTrue(DEFAULT_CORELIB.contains(classInt));
  RegExp classString = new RegExp('class String implements Pattern {}');
  Expect.isTrue(DEFAULT_CORELIB.contains(classString));

  String CORE_SOURCE = DEFAULT_CORELIB
      .replaceAll(classNum, NUM_SOURCE)
      .replaceAll(classInt, INT_SOURCE)
      .replaceAll(classString, STRING_SOURCE);

  compiler = new MockCompiler(coreSource: CORE_SOURCE);
  types = compiler.types;
  voidType = compiler.types.voidType;
  intType = compiler.intClass.computeType(compiler);
  doubleType = compiler.doubleClass.computeType(compiler);
  boolType = compiler.boolClass.computeType(compiler);
  stringType = compiler.stringClass.computeType(compiler);
  objectType = compiler.objectClass.computeType(compiler);
}

DartType analyzeType(String text) {
  var node = parseExpression(text);
  TypeCheckerVisitor visitor =
      new TypeCheckerVisitor(compiler, new TreeElementMapping(null), types);
  return visitor.analyze(node);
}

analyzeTopLevel(String text, [expectedWarnings]) {
  if (expectedWarnings == null) expectedWarnings = [];
  if (expectedWarnings is !List) expectedWarnings = [expectedWarnings];

  compiler.diagnosticHandler = createHandler(compiler, text);

  LibraryElement library = mockLibrary(compiler, text);

  Link<Element> topLevelElements = parseUnit(text, compiler, library).reverse();

  Element element = null;
  Node node;
  TreeElements mapping;
  // Resolve all declarations and members.
  for (Link<Element> elements = topLevelElements;
       !elements.isEmpty;
       elements = elements.tail) {
    element = elements.head;
    if (element.isClass()) {
      ClassElement classElement = element;
      classElement.ensureResolved(compiler);
      classElement.forEachLocalMember((Element e) {
        if (!e.isSynthesized) {
          element = e;
          node = element.parseNode(compiler);
          mapping = compiler.resolver.resolve(element);
        }
      });
    } else {
      node = element.parseNode(compiler);
      mapping = compiler.resolver.resolve(element);
    }
  }
  // Type check last class declaration or member.
  TypeCheckerVisitor checker =
      new TypeCheckerVisitor(compiler, mapping, types);
  compiler.clearMessages();
  checker.analyze(node);
  compareWarningKinds(text, expectedWarnings, compiler.warnings);

  compiler.diagnosticHandler = null;
}

/**
 * Analyze the statement [text] and check messages from the type checker.
 * [errors] and [warnings] can be either [:null:], a single [MessageKind] or
 * a list of [MessageKind]s. If [hints] and [infos] are [:null:] the
 * corresponding message kinds are ignored.
 */
analyze(String text, {errors, warnings, List hints, List infos}) {
  if (warnings == null) warnings = [];
  if (warnings is !List) warnings = [warnings];
  if (errors == null) errors = [];
  if (errors is !List) errors = [errors];

  compiler.diagnosticHandler = createHandler(compiler, text);

  Token tokens = scan(text);
  NodeListener listener = new NodeListener(compiler, null);
  Parser parser = new Parser(listener);
  parser.parseStatement(tokens);
  Node node = listener.popNode();
  Element compilationUnit =
    new CompilationUnitElementX(new Script(null, null), compiler.mainApp);
  Element function = new FunctionElementX(
      '', ElementKind.FUNCTION, Modifiers.EMPTY, compilationUnit, false);
  TreeElements elements = compiler.resolveNodeStatement(node, function);
  TypeCheckerVisitor checker = new TypeCheckerVisitor(compiler, elements,
                                                                types);
  compiler.clearMessages();
  checker.analyze(node);
  compareWarningKinds(text, warnings, compiler.warnings);
  compareWarningKinds(text, errors, compiler.errors);
  if (hints != null) compareWarningKinds(text, hints, compiler.hints);
  if (infos != null) compareWarningKinds(text, infos, compiler.infos);
  compiler.diagnosticHandler = null;
}

void generateOutput(String text) {
  for (WarningMessage message in compiler.warnings) {
    var beginToken = message.node.getBeginToken();
    var endToken = message.node.getEndToken();
    int begin = beginToken.charOffset;
    int end = endToken.charOffset + endToken.charCount;
    SourceFile sourceFile = new StringSourceFile('analysis', text);
    print(sourceFile.getLocationMessage(message.message.toString(),
                                        begin, end, true, (str) => str));
  }
}

analyzeIn(Element element, String text, [expectedWarnings]) {
  if (expectedWarnings == null) expectedWarnings = [];
  if (expectedWarnings is !List) expectedWarnings = [expectedWarnings];

  Token tokens = scan(text);
  NodeListener listener = new NodeListener(compiler, null);
  Parser parser = new Parser(listener);
  parser.parseStatement(tokens);
  Node node = listener.popNode();
  TreeElements elements = compiler.resolveNodeStatement(node, element);
  TypeCheckerVisitor checker = new TypeCheckerVisitor(compiler, elements,
                                                                types);
  compiler.clearMessages();
  checker.analyze(node);
  generateOutput(text);
  compareWarningKinds(text, expectedWarnings, compiler.warnings);
}
