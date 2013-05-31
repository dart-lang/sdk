// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import '../../../sdk/lib/_internal/compiler/compiler.dart' as api;
import '../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart';
import '../../../sdk/lib/_internal/compiler/implementation/tree/tree.dart';
import '../../../sdk/lib/_internal/compiler/implementation/util/util.dart';
import '../../../sdk/lib/_internal/compiler/implementation/source_file.dart';
import 'mock_compiler.dart';
import 'parser_helper.dart';

import '../../../sdk/lib/_internal/compiler/implementation/elements/modelx.dart'
    show ElementX, CompilationUnitElementX;

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
    hide SourceString;

import '../../../sdk/lib/_internal/compiler/implementation/dart_types.dart';

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
                testControlFlow,
                // testNewExpression,
                testConditionalExpression,
                testIfStatement,
                testThis,
                testSuper,
                testOperatorsAssignability];
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
  analyzeTopLevel("int bar() { return 'hest'; }", MessageKind.NOT_ASSIGNABLE);
  analyzeTopLevel("void baz() { var x; return x; }");
  analyzeTopLevel(returnWithType("int", "'string'"),
                  MessageKind.NOT_ASSIGNABLE);
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
  analyze("for (var x;0;x = x + 1) {}", MessageKind.NOT_ASSIGNABLE);
  analyze("for (var x;'';x = x + 1) {}", MessageKind.NOT_ASSIGNABLE);

   analyze("for (;true;) {}");
   analyze("for (;null;) {}");
   analyze("for (;0;) {}", MessageKind.NOT_ASSIGNABLE);
   analyze("for (;'';) {}", MessageKind.NOT_ASSIGNABLE);

  // Foreach tests
//  TODO(karlklose): for each is not yet implemented.
//  analyze("{ List<String> strings = ['1','2','3']; " +
//          "for (String s in strings) {} }");
//  analyze("{ List<int> ints = [1,2,3]; for (String s in ints) {} }",
//          MessageKind.NOT_ASSIGNABLE);
//  analyze("for (String s in true) {}", MessageKind.METHOD_NOT_FOUND);
}

testWhile() {
  analyze("while (true) {}");
  analyze("while (null) {}");
  analyze("while (0) {}", MessageKind.NOT_ASSIGNABLE);
  analyze("while ('') {}", MessageKind.NOT_ASSIGNABLE);

  analyze("do {} while (true);");
  analyze("do {} while (null);");
  analyze("do {} while (0);", MessageKind.NOT_ASSIGNABLE);
  analyze("do {} while ('');", MessageKind.NOT_ASSIGNABLE);
  analyze("do { int i = 0.5; } while (true);", MessageKind.NOT_ASSIGNABLE);
  analyze("do { int i = 0.5; } while (null);", MessageKind.NOT_ASSIGNABLE);
}

testTry() {
  analyze("try {} finally {}");
  analyze("try {} catch (e) { int i = e;} finally {}");
  analyze("try {} catch (e, s) { int i = e; StackTrace j = s; } finally {}");
  analyze("try {} on String catch (e) {} finally {}");
  analyze("try { int i = ''; } finally {}", MessageKind.NOT_ASSIGNABLE);
  analyze("try {} finally { int i = ''; }", MessageKind.NOT_ASSIGNABLE);
  analyze("try {} on String catch (e) { int i = e; } finally {}",
      MessageKind.NOT_ASSIGNABLE);
  analyze("try {} catch (e, s) { int i = e; int j = s; } finally {}",
      MessageKind.NOT_ASSIGNABLE);
  analyze("try {} on String catch (e, s) { int i = e; int j = s; } finally {}",
      [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);
}


testSwitch() {
  analyze("switch (0) { case 1: break; case 2: break; }");
  analyze("switch (0) { case 1: int i = ''; break; case 2: break; }",
      MessageKind.NOT_ASSIGNABLE);
  analyze("switch (0) { case '': break; case 2: break; }",
      MessageKind.NOT_ASSIGNABLE);
  analyze("switch ('') { case 1: break; case 2: break; }",
      [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);
}

testOperators() {
  // TODO(karlklose): add the DartC tests for operators when we can parse
  // classes with operators.
  for (final op in ['+', '-', '*', '/', '%', '~/', '|', '&']) {
    analyze("{ var i = 1 ${op} 2; }");
    analyze("{ var i = 1; i ${op}= 2; }");
    analyze("{ int i; var j = (i = true) ${op} 2; }",
            [MessageKind.NOT_ASSIGNABLE, MessageKind.OPERATOR_NOT_FOUND]);
    analyze("{ int i; var j = 1 ${op} (i = true); }",
            [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);
  }
  for (final op in ['-', '~']) {
    analyze("{ var i = ${op}1; }");
    analyze("{ int i; var j = ${op}(i = true); }",
        [MessageKind.NOT_ASSIGNABLE, MessageKind.OPERATOR_NOT_FOUND]);
  }
  for (final op in ['++', '--']) {
    analyze("{ int i = 1; int j = i${op}; }");
    analyze("{ int i = 1; bool j = i${op}; }", MessageKind.NOT_ASSIGNABLE);
    analyze("{ bool b = true; bool j = b${op}; }",
        MessageKind.OPERATOR_NOT_FOUND);
    analyze("{ bool b = true; int j = ${op}b; }",
        MessageKind.OPERATOR_NOT_FOUND);
  }
  for (final op in ['||', '&&']) {
    analyze("{ bool b = (true ${op} false); }");
    analyze("{ int b = true ${op} false; }", MessageKind.NOT_ASSIGNABLE);
    analyze("{ bool b = (1 ${op} false); }", MessageKind.NOT_ASSIGNABLE);
    analyze("{ bool b = (true ${op} 2); }", MessageKind.NOT_ASSIGNABLE);
  }
  for (final op in ['>', '<', '<=', '>=']) {
    analyze("{ bool b = 1 ${op} 2; }");
    analyze("{ int i = 1 ${op} 2; }", MessageKind.NOT_ASSIGNABLE);
    analyze("{ int i; bool b = (i = true) ${op} 2; }",
            [MessageKind.NOT_ASSIGNABLE, MessageKind.OPERATOR_NOT_FOUND]);
    analyze("{ int i; bool b = 1 ${op} (i = true); }",
            [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);
  }
  for (final op in ['==', '!=']) {
    analyze("{ bool b = 1 ${op} 2; }");
    analyze("{ int i = 1 ${op} 2; }", MessageKind.NOT_ASSIGNABLE);
    analyze("{ int i; bool b = (i = true) ${op} 2; }",
        MessageKind.NOT_ASSIGNABLE);
    analyze("{ int i; bool b = 1 ${op} (i = true); }",
        MessageKind.NOT_ASSIGNABLE);
  }
}

void testConstructorInvocationArgumentCount() {
  compiler.parseScript("""
     class C1 { C1(x, y); }
     class C2 { C2(int x, int y); }
  """);
  // calls to untyped constructor C1
  analyze("new C1(1, 2);");
  analyze("new C1();", MessageKind.MISSING_ARGUMENT);
  analyze("new C1(1);", MessageKind.MISSING_ARGUMENT);
  analyze("new C1(1, 2, 3);", MessageKind.ADDITIONAL_ARGUMENT);
  // calls to typed constructor C2
  analyze("new C2(1, 2);");
  analyze("new C2();", MessageKind.MISSING_ARGUMENT);
  analyze("new C2(1);", MessageKind.MISSING_ARGUMENT);
  analyze("new C2(1, 2, 3);", MessageKind.ADDITIONAL_ARGUMENT);
}

void testConstructorInvocationArgumentTypes() {
  compiler.parseScript("""
    class C1 { C1(x); }
    class C2 { C2(int x); }
  """);
  analyze("new C1(42);");
  analyze("new C1('string');");
  analyze("new C2(42);");
  analyze("new C2('string');",
          MessageKind.NOT_ASSIGNABLE);
}

void testMethodInvocationArgumentCount() {
  compiler.parseScript(CLASS_WITH_METHODS);

  check(String text, [expectedWarnings]) {
    analyze("{ ClassWithMethods c; $text }", expectedWarnings);
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
               """, expectedWarnings);
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
        MessageKind.NOT_ASSIGNABLE);

  check("int k = c.intOneArgumentMethod(c);", MessageKind.NOT_ASSIGNABLE);
  check("ClassWithMethods x = c.intOneArgumentMethod(1);",
        MessageKind.NOT_ASSIGNABLE);
  check("int k = c.intOneArgumentMethod('string');",
        MessageKind.NOT_ASSIGNABLE);
  check("int k = c.intOneArgumentMethod(i);");

  check("int k = c.intTwoArgumentMethod(1, 'string');",
        MessageKind.NOT_ASSIGNABLE);
  check("int k = c.intTwoArgumentMethod(i, j);");
  check("ClassWithMethods x = c.intTwoArgumentMethod(i, j);",
        MessageKind.NOT_ASSIGNABLE);

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
        MessageKind.NOT_ASSIGNABLE);
  check("c.intOneArgumentOneOptionalMethod('', '');",
        [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);

  check("c.intTwoOptionalMethod('');", MessageKind.NOT_ASSIGNABLE);
  check("c.intTwoOptionalMethod('', '');",
        [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);

  check("c.intOneArgumentOneNamedMethod('');",
        MessageKind.NOT_ASSIGNABLE);
  check("c.intOneArgumentOneNamedMethod('', b: '');",
        [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);

  check("c.intTwoNamedMethod(a: '');", MessageKind.NOT_ASSIGNABLE);
  check("c.intTwoNamedMethod(b: '');", MessageKind.NOT_ASSIGNABLE);
  check("c.intTwoNamedMethod(a: '', b: '');",
        [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);
  check("c.intTwoNamedMethod(b: '', a: '');",
        [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);

  // Invocation of dynamic variable.
  check("e();");
  check("e(1);");
  check("e('string');");

  // Invocation on local method.
  check("localMethod();", MessageKind.MISSING_ARGUMENT);
  check("localMethod(1);", MessageKind.NOT_ASSIGNABLE);
  check("localMethod('string');");
  check("int k = localMethod('string');");
  check("String k = localMethod('string');", MessageKind.NOT_ASSIGNABLE);

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
  check("(int foo){}('string');", MessageKind.NOT_ASSIGNABLE);
  check("(String foo){}('string');");
  check("int k = int bar(String foo){ return 0; }('string');");
  check("int k = String bar(String foo){ return foo; }('string');",
        MessageKind.NOT_ASSIGNABLE);

  // Static invocations.
  check("ClassWithMethods.staticMethod();",
        MessageKind.MISSING_ARGUMENT);
  check("ClassWithMethods.staticMethod(1);",
        MessageKind.NOT_ASSIGNABLE);
  check("ClassWithMethods.staticMethod('string');");
  check("int k = ClassWithMethods.staticMethod('string');");
  check("String k = ClassWithMethods.staticMethod('string');",
        MessageKind.NOT_ASSIGNABLE);

  // Invocation on dynamic variable.
  check("e.foo();");
  check("e.foo(1);");
  check("e.foo('string');");

  // Invocation on unresolved variable.
  check("foo();");
  check("foo(1);");
  check("foo('string');");
  check("foo(a: 'string');");
  check("foo(a: localMethod(1));", MessageKind.NOT_ASSIGNABLE);

  // TODO(johnniwinther): Add tests of invocations using implicit this.
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

testNewExpression() {
  compiler.parseScript("class A {}");
  analyze("A a = new A();");
  analyze("int i = new A();", MessageKind.NOT_ASSIGNABLE);

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
//  analyze("Foo x = new Foo('');", MessageKind.NOT_ASSIGNABLE);
//  analyze("Foo x = new Foo(0, null);", MessageKind.ADDITIONAL_ARGUMENT);
//
//  analyze("Foo x = new Foo.foo();");
//  analyze("Foo x = new Foo.foo(null);", MessageKind.ADDITIONAL_ARGUMENT);
//
//  analyze("Foo x = new Foo.bar();");
//  analyze("Foo x = new Foo.bar(0);");
//  analyze("Foo x = new Foo.bar('');", MessageKind.NOT_ASSIGNABLE);
//  analyze("Foo x = new Foo.bar(0, null);",
//          MessageKind.ADDITIONAL_ARGUMENT);
//
//  analyze("Bar<String> x = new Bar<String>.make('');");
}

testConditionalExpression() {
  analyze("int i = true ? 2 : 1;");
  analyze("int i = true ? 'hest' : 1;");
  analyze("int i = true ? 'hest' : 'fisk';", MessageKind.NOT_ASSIGNABLE);
  analyze("String s = true ? 'hest' : 'fisk';");

  analyze("true ? 1 : 2;");
  analyze("null ? 1 : 2;");
  analyze("0 ? 1 : 2;", MessageKind.NOT_ASSIGNABLE);
  analyze("'' ? 1 : 2;", MessageKind.NOT_ASSIGNABLE);
  analyze("{ int i; true ? i = 2.7 : 2; }",
          MessageKind.NOT_ASSIGNABLE);
  analyze("{ int i; true ? 2 : i = 2.7; }",
          MessageKind.NOT_ASSIGNABLE);
  analyze("{ int i; i = true ? 2.7 : 2; }");
}

testIfStatement() {
  analyze("if (true) {}");
  analyze("if (null) {}");
  analyze("if (0) {}",
  MessageKind.NOT_ASSIGNABLE);
  analyze("if ('') {}",
          MessageKind.NOT_ASSIGNABLE);
  analyze("{ int i = 27; if (true) { i = 2.7; } else {} }",
          MessageKind.NOT_ASSIGNABLE);
  analyze("{ int i = 27; if (true) {} else { i = 2.7; } }",
          MessageKind.NOT_ASSIGNABLE);
}

testThis() {
  String script = "class Foo {}";
  LibraryElement library = mockLibrary(compiler, script);
  compiler.parseScript(script, library);
  ClassElement foo = library.find(const SourceString("Foo"));
  analyzeIn(foo, "{ int i = this; }", MessageKind.NOT_ASSIGNABLE);
  analyzeIn(foo, "{ Object o = this; }");
  analyzeIn(foo, "{ Foo f = this; }");
}

testSuper() {
  String script = r'''
    class A {
      String field = "42";
    }
    
    class B extends A {
      Object field = 42;
    }
    ''';
  LibraryElement library = mockLibrary(compiler, script);
  compiler.parseScript(script, library);
  ClassElement B = library.find(const SourceString("B"));
  analyzeIn(B, "{ int i = super.field; }", MessageKind.NOT_ASSIGNABLE);
  analyzeIn(B, "{ Object o = super.field; }");
  analyzeIn(B, "{ String s = super.field; }");
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
    analyze('$header $text }', expectedWarnings);
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
  check('c = a + 0;', MessageKind.NOT_ASSIGNABLE);
  // `a + b` is not assignable to `z`.
  check('z = a + b;', MessageKind.NOT_ASSIGNABLE);

  // `-a` is not assignable to `z`.
  check('z = -a;', MessageKind.NOT_ASSIGNABLE);

  // `0` is not assignable to operator [] on `a`.
  check('c = a[0];', MessageKind.NOT_ASSIGNABLE);
  // `a[b]` is not assignable to `z`.
  check('z = a[b];', MessageKind.NOT_ASSIGNABLE);

  // `0` is not assignable to operator [] on `a`.
  // Warning suppressed for `0` is not assignable to operator []= on `a`.
  check('a[0] *= c;', MessageKind.NOT_ASSIGNABLE);
  // `z` is not assignable to operator * on `a[0]`.
  check('a[b] *= z;', MessageKind.NOT_ASSIGNABLE);

  check('b = a++;', MessageKind.NOT_ASSIGNABLE);
  check('b = ++a;', MessageKind.NOT_ASSIGNABLE);
  check('b = a--;', MessageKind.NOT_ASSIGNABLE);
  check('b = --a;', MessageKind.NOT_ASSIGNABLE);

  check('c = a[b]++;', MessageKind.NOT_ASSIGNABLE);
  check('c = ++a[b];', MessageKind.NOT_ASSIGNABLE);
  check('c = a[b]--;', MessageKind.NOT_ASSIGNABLE);
  check('c = --a[b];', MessageKind.NOT_ASSIGNABLE);

  check('z = a == b;');
  check('z = a != b;');

  for (String o in ['&&', '||']) {
    check('z = z $o z;');
    check('z = a $o z;', MessageKind.NOT_ASSIGNABLE);
    check('z = z $o b;', MessageKind.NOT_ASSIGNABLE);
    check('z = a $o b;',
        [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);
    check('a = a $o b;',
        [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE,
         MessageKind.NOT_ASSIGNABLE]);
  }

  check('z = !z;');
  check('z = !a;', MessageKind.NOT_ASSIGNABLE);
  check('a = !z;', MessageKind.NOT_ASSIGNABLE);
  check('a = !a;',
      [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);


  // Tests against MismatchA.

  header = """{
      MismatchA a;
      MismatchA b;
      MismatchA c;
      """;

  // Tests against int operator +(MismatchA other) => 0;

  // `a + b` is not assignable to `c`.
  check('c = a + b;', MessageKind.NOT_ASSIGNABLE);
  // `a + b` is not assignable to `a`.
  check('a += b;', MessageKind.NOT_ASSIGNABLE);
  // `a[0] + b` is not assignable to `a[0]`.
  check('a[0] += b;', MessageKind.NOT_ASSIGNABLE);

  // 1 is not applicable to operator +.
  check('b = a++;', MessageKind.NOT_ASSIGNABLE);
  // 1 is not applicable to operator +.
  // `++a` of type int is not assignable to `b`.
  check('b = ++a;',
      [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);

  // 1 is not applicable to operator +.
  check('b = a[0]++;', MessageKind.NOT_ASSIGNABLE);
  // 1 is not applicable to operator +.
  // `++a[0]` of type int is not assignable to `b`.
  check('b = ++a[0];',
      [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);

  // Tests against: MismatchA operator -(int other) => this;

  // `a - b` is not assignable to `c`.
  check('c = a + b;', MessageKind.NOT_ASSIGNABLE);
  // `a - b` is not assignable to `a`.
  check('a += b;', MessageKind.NOT_ASSIGNABLE);
  // `a[0] - b` is not assignable to `a[0]`.
  check('a[0] += b;', MessageKind.NOT_ASSIGNABLE);

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
  check('a[0] = b;', MessageKind.NOT_ASSIGNABLE);

  // `0` is not applicable to operator []= on `a`.
  check('a[0] += b;', MessageKind.NOT_ASSIGNABLE);
  // `""` is not applicable to operator [] on `a`.
  check('a[""] += b;', MessageKind.NOT_ASSIGNABLE);
  // `c` is not applicable to operator [] on `a`.
  // `c` is not applicable to operator []= on `a`.
  check('a[c] += b;',
      [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);


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
  check('a[0] += b;', MessageKind.NOT_ASSIGNABLE);
  // `0` is not applicable to operator + on `a[0]`.
  check('a[0] += "";',
      [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);
  // `true` is not applicable to operator + on `a[0]`.
  // `true` is not assignable to `a[0]`.
  check('a[0] += true;',
      [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);
}

const CLASS_WITH_METHODS = '''
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
}
class I {
  int intMethod();
}
class SubClass extends ClassWithMethods implements I {}''';

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

void setup() {
  RegExp classNum = new RegExp(r'abstract class num {}');
  Expect.isTrue(DEFAULT_CORELIB.contains(classNum));
  RegExp classInt = new RegExp(r'abstract class int extends num { }');
  Expect.isTrue(DEFAULT_CORELIB.contains(classInt));

  String CORE_SOURCE = DEFAULT_CORELIB
      .replaceAll(classNum, NUM_SOURCE)
      .replaceAll(classInt, INT_SOURCE);

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

  LibraryElement library = mockLibrary(compiler, text);

  Link<Element> topLevelElements = parseUnit(text, compiler, library);

  for (Link<Element> elements = topLevelElements;
       !elements.isEmpty;
       elements = elements.tail) {
    Node node = elements.head.parseNode(compiler);
    TreeElements mapping = compiler.resolver.resolve(elements.head);
    TypeCheckerVisitor checker =
        new TypeCheckerVisitor(compiler, mapping, types);
    compiler.clearWarnings();
    checker.analyze(node);
    compareWarningKinds(text, expectedWarnings, compiler.warnings);
  }
}

api.DiagnosticHandler createHandler(String text) {
  return (uri, int begin, int end, String message, kind) {
    SourceFile sourceFile;
    if (uri == null) {
      sourceFile = new SourceFile('analysis', text);
    } else {
      sourceFile = compiler.sourceFiles[uri.toString()];
    }
    if (sourceFile != null) {
      print(sourceFile.getLocationMessage(message, begin, end, true, (x) => x));
    } else {
      print(message);
    }
  };
}

analyze(String text, [expectedWarnings]) {
  if (expectedWarnings == null) expectedWarnings = [];
  if (expectedWarnings is !List) expectedWarnings = [expectedWarnings];

  compiler.diagnosticHandler = createHandler(text);

  Token tokens = scan(text);
  NodeListener listener = new NodeListener(compiler, null);
  Parser parser = new Parser(listener);
  parser.parseStatement(tokens);
  Node node = listener.popNode();
  Element compilationUnit =
    new CompilationUnitElementX(new Script(null, null), compiler.mainApp);
  Element function = new ElementX(
      buildSourceString(''), ElementKind.FUNCTION, compilationUnit);
  TreeElements elements = compiler.resolveNodeStatement(node, function);
  TypeCheckerVisitor checker = new TypeCheckerVisitor(compiler, elements,
                                                                types);
  compiler.clearWarnings();
  checker.analyze(node);
  compareWarningKinds(text, expectedWarnings, compiler.warnings);
  compiler.diagnosticHandler = null;
}

void generateOutput(String text) {
  for (WarningMessage message in compiler.warnings) {
    var beginToken = message.node.getBeginToken();
    var endToken = message.node.getEndToken();
    int begin = beginToken.charOffset;
    int end = endToken.charOffset + endToken.slowCharCount;
    SourceFile sourceFile = new SourceFile('analysis', text);
    print(sourceFile.getLocationMessage(message.message.toString(),
                                        begin, end, true, (str) => str));
  }
}

analyzeIn(ClassElement classElement, String text, [expectedWarnings]) {
  if (expectedWarnings == null) expectedWarnings = [];
  if (expectedWarnings is !List) expectedWarnings = [expectedWarnings];

  Token tokens = scan(text);
  NodeListener listener = new NodeListener(compiler, null);
  Parser parser = new Parser(listener);
  parser.parseStatement(tokens);
  Node node = listener.popNode();
  classElement.ensureResolved(compiler);
  TreeElements elements = compiler.resolveNodeStatement(node, classElement);
  TypeCheckerVisitor checker = new TypeCheckerVisitor(compiler, elements,
                                                                types);
  compiler.clearWarnings();
  checker.analyze(node);
  generateOutput(text);
  compareWarningKinds(text, expectedWarnings, compiler.warnings);
}
