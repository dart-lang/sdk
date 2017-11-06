// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'package:compiler/src/elements/resolution_types.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/modelx.dart'
    show ClassElementX, CompilationUnitElementX, ElementX;
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/resolution/tree_elements.dart'
    show TreeElements, TreeElementMapping;
import 'package:compiler/src/parser/element_listener.dart';
import 'package:compiler/src/tree/tree.dart';
import 'package:compiler/src/typechecker.dart';
import 'package:compiler/src/script.dart';
import 'package:compiler/src/util/util.dart';

import 'mock_compiler.dart';
import 'parser_helper.dart';

final MessageKind NOT_ASSIGNABLE = MessageKind.NOT_ASSIGNABLE;
final MessageKind UNDEFINED_GETTER = MessageKind.UNDEFINED_GETTER;

main() {
  List tests = [
    testSimpleTypes,
    testReturn,
    testFor,
    testSyncForIn,
    testAsyncForIn,
    testWhile,
    testTry,
    testSwitch,
    testEnumSwitch,
    testOperators,
    testConstructorInvocationArgumentCount,
    testConstructorInvocationArgumentTypes,
    testMethodInvocationArgumentCount,
    testMethodInvocations,
    testMethodInvocationsInClass,
    testGetterSetterInvocation,
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
    testFunctionCall,
    testCascade,
    testAwait,
    testAsyncReturn
  ];
  asyncTest(() => Future.forEach(tests, (test) => setup(test)));
}

testSimpleTypes(MockCompiler compiler) {
  checkType(ResolutionInterfaceType type, String code) {
    Expect.equals(type, analyzeType(compiler, code));
  }

  checkType(compiler.resolution.commonElements.intType, "3");
  checkType(compiler.resolution.commonElements.boolType, "false");
  checkType(compiler.resolution.commonElements.boolType, "true");
  checkType(compiler.resolution.commonElements.stringType, "'hestfisk'");
}

Future testReturn(MockCompiler compiler) {
  Future check(String code, [expectedWarnings]) {
    return analyzeTopLevel(code, expectedWarnings);
  }

  return Future.wait([
    check("void foo() { return 3; }", MessageKind.RETURN_VALUE_IN_VOID),
    check("int bar() { return 'hest'; }", NOT_ASSIGNABLE),
    check("void baz() { var x; return x; }"),
    check(returnWithType("int", "'string'"), NOT_ASSIGNABLE),
    check(returnWithType("", "'string'")),
    check(returnWithType("Object", "'string'")),
    check(returnWithType("String", "'string'")),
    check(returnWithType("String", null)),
    check(returnWithType("int", null)),
    check(returnWithType("void", "")),
    check(returnWithType("void", 1), MessageKind.RETURN_VALUE_IN_VOID),
    check(returnWithType("void", null)),
    check(returnWithType("String", ""), MessageKind.RETURN_NOTHING),
    check(arrowReturnWithType("void", "4")),
    check("void set foo(x) => 5;"),
    // check("String foo() {};"), // Should probably fail.
  ]);
}

testFor(MockCompiler compiler) {
  check(String code, {warnings}) {
    analyze(compiler, code, warnings: warnings);
  }

  check("for (var x;true;x = x + 1) {}");
  check("for (var x;null;x = x + 1) {}");
  check("for (var x;0;x = x + 1) {}", warnings: NOT_ASSIGNABLE);
  check("for (var x;'';x = x + 1) {}", warnings: NOT_ASSIGNABLE);

  check("for (;true;) {}");
  check("for (;null;) {}");
  check("for (;0;) {}", warnings: NOT_ASSIGNABLE);
  check("for (;'';) {}", warnings: NOT_ASSIGNABLE);

  // Foreach tests
//  TODO(karlklose): for each is not yet implemented.
//  check("{ List<String> strings = ['1','2','3']; " +
//        "for (String s in strings) {} }");
//  check("{ List<int> ints = [1,2,3]; for (String s in ints) {} }",
//        NOT_ASSIGNABLE);
//  check("for (String s in true) {}", MessageKind.UNDEFINED_METHOD);
}

testSyncForIn(MockCompiler compiler) {
  String script = """
class HasUntypedIterator {
  get iterator => null;
}

class HasIntIterator {
  Iterator<int> get iterator => null;
}

class HasNoIterator {
}

class HasCustomIntIterator {
  CustomIntIterator get iterator => null;
}

class CustomIntIterator {
  int current;
}

class HasCustomNoCurrentIterator {
  CustomNoCurrentIterator get iterator => null;
}

class CustomNoCurrentIterator {
}

var topLevelDyn;
String topLevelString;
int topLevelInt;

class Class {
  void forIn() {}

  var instanceDyn;
  String instanceString;
  int instanceInt;

  static var staticDyn;
  static String staticString;
  static int staticInt;
}
""";
  compiler.parseScript(script);
  LibraryElement mainApp = compiler.mainApp;
  ClassElement foo = mainApp.find("Class");
  foo.ensureResolved(compiler.resolution);
  FunctionElement method = foo.lookupLocalMember('forIn');

  analyzeIn(compiler, method, """{ 
      for (var e in <String>[]) {} 
  }""");
  analyzeIn(compiler, method, """{ 
      for (String e in <String>[]) {} 
  }""");
  analyzeIn(
      compiler,
      method,
      """{ 
      for (int e in <String>[]) {} 
  }""",
      hints: MessageKind.FORIN_NOT_ASSIGNABLE);
  analyzeIn(compiler, method, """{ 
      for (int e in []) {} 
  }""");

  analyzeIn(compiler, method, """{ 
      for (var e in new HasUntypedIterator()) {} 
  }""");
  analyzeIn(compiler, method, """{ 
      for (String e in new HasUntypedIterator()) {} 
  }""");
  analyzeIn(compiler, method, """{ 
      for (int e in new HasUntypedIterator()) {} 
  }""");

  analyzeIn(compiler, method, """{ 
      for (var e in new HasIntIterator()) {} 
  }""");
  analyzeIn(
      compiler,
      method,
      """{ 
      for (String e in new HasIntIterator()) {} 
  }""",
      hints: MessageKind.FORIN_NOT_ASSIGNABLE);
  analyzeIn(compiler, method, """{ 
      for (int e in new HasIntIterator()) {} 
  }""");

  analyzeIn(
      compiler,
      method,
      """{ 
      for (var e in new HasNoIterator()) {} 
  }""",
      warnings: MessageKind.UNDEFINED_GETTER);
  analyzeIn(
      compiler,
      method,
      """{ 
      for (String e in new HasNoIterator()) {} 
  }""",
      warnings: MessageKind.UNDEFINED_GETTER);
  analyzeIn(
      compiler,
      method,
      """{ 
      for (int e in new HasNoIterator()) {} 
  }""",
      warnings: MessageKind.UNDEFINED_GETTER);

  analyzeIn(compiler, method, """{ 
      for (var e in new HasCustomIntIterator()) {} 
  }""");
  analyzeIn(
      compiler,
      method,
      """{ 
      for (String e in new HasCustomIntIterator()) {} 
  }""",
      hints: MessageKind.FORIN_NOT_ASSIGNABLE);
  analyzeIn(compiler, method, """{ 
      for (int e in new HasCustomIntIterator()) {} 
  }""");

  analyzeIn(
      compiler,
      method,
      """{ 
      for (var e in new HasCustomNoCurrentIterator()) {} 
  }""",
      hints: MessageKind.UNDEFINED_GETTER);
  analyzeIn(
      compiler,
      method,
      """{ 
      for (String e in new HasCustomNoCurrentIterator()) {} 
  }""",
      hints: MessageKind.UNDEFINED_GETTER);
  analyzeIn(
      compiler,
      method,
      """{ 
      for (int e in new HasCustomNoCurrentIterator()) {} 
  }""",
      hints: MessageKind.UNDEFINED_GETTER);

  analyzeIn(compiler, method, """{ 
      var localDyn; 
      for (localDyn in <String>[]) {} 
  }""");
  analyzeIn(compiler, method, """{ 
      String localString; 
      for (localString in <String>[]) {} 
  }""");
  analyzeIn(
      compiler,
      method,
      """{ 
      int localInt; 
      for (localInt in <String>[]) {} 
  }""",
      hints: MessageKind.FORIN_NOT_ASSIGNABLE);

  analyzeIn(compiler, method, """{ 
      for (topLevelDyn in <String>[]) {} 
  }""");
  analyzeIn(compiler, method, """{ 
      for (topLevelString in <String>[]) {} 
  }""");
  analyzeIn(
      compiler,
      method,
      """{ 
      for (topLevelInt in <String>[]) {} 
  }""",
      hints: MessageKind.FORIN_NOT_ASSIGNABLE);

  analyzeIn(compiler, method, """{ 
      for (instanceDyn in <String>[]) {} 
  }""");
  analyzeIn(compiler, method, """{ 
      for (instanceString in <String>[]) {} 
  }""");
  analyzeIn(
      compiler,
      method,
      """{ 
      for (instanceInt in <String>[]) {} 
  }""",
      hints: MessageKind.FORIN_NOT_ASSIGNABLE);

  analyzeIn(compiler, method, """{ 
      for (staticDyn in <String>[]) {} 
  }""");
  analyzeIn(compiler, method, """{ 
      for (staticString in <String>[]) {} 
  }""");
  analyzeIn(
      compiler,
      method,
      """{ 
      for (staticInt in <String>[]) {} 
  }""",
      hints: MessageKind.FORIN_NOT_ASSIGNABLE);
}

testAsyncForIn(MockCompiler compiler) {
  String script = """
abstract class CustomStream<T> implements Stream<T> {}
abstract class StringStream implements Stream<String> {}

var topLevelDyn;
String topLevelString;
int topLevelInt;

class Class {
  void forIn() async {}

  var instanceDyn;
  String instanceString;
  int instanceInt;

  static var staticDyn;
  static String staticString;
  static int staticInt;
}
""";
  compiler.parseScript(script);
  LibraryElement mainApp = compiler.mainApp;
  ClassElement foo = mainApp.find("Class");
  foo.ensureResolved(compiler.resolution);
  FunctionElement method = foo.lookupLocalMember('forIn');

  analyzeIn(compiler, method, """{
      var stream;
      await for (var e in stream) {} 
  }""");
  analyzeIn(compiler, method, """{ 
      var stream;
      await for (String e in stream) {} 
  }""");
  analyzeIn(compiler, method, """{ 
      var stream;
      await for (int e in stream) {} 
  }""");

  analyzeIn(
      compiler,
      method,
      """{ 
      await for (var e in []) {} 
  }""",
      hints: MessageKind.NOT_ASSIGNABLE);

  analyzeIn(compiler, method, """{ 
      Stream<String> stream;
      await for (var e in stream) {} 
  }""");
  analyzeIn(compiler, method, """{ 
      Stream<String> stream;
      await for (String e in stream) {} 
  }""");
  analyzeIn(
      compiler,
      method,
      """{ 
      Stream<String> stream;
      await for (int e in stream) {} 
  }""",
      hints: MessageKind.FORIN_NOT_ASSIGNABLE);

  analyzeIn(compiler, method, """{ 
      CustomStream<String> stream;
      await for (var e in stream) {} 
  }""");
  analyzeIn(compiler, method, """{ 
      CustomStream<String> stream;
      await for (String e in stream) {} 
  }""");
  analyzeIn(
      compiler,
      method,
      """{ 
      CustomStream<String> stream;
      await for (int e in stream) {} 
  }""",
      hints: MessageKind.FORIN_NOT_ASSIGNABLE);

  analyzeIn(compiler, method, """{ 
      StringStream stream;
      await for (var e in stream) {} 
  }""");
  analyzeIn(compiler, method, """{ 
      StringStream stream;
      await for (String e in stream) {} 
  }""");
  analyzeIn(
      compiler,
      method,
      """{ 
      StringStream stream;
      await for (int e in stream) {} 
  }""",
      hints: MessageKind.FORIN_NOT_ASSIGNABLE);

  analyzeIn(compiler, method, """{ 
      Stream<String> stream;
      var localDyn; 
      await for (localDyn in stream) {} 
  }""");
  analyzeIn(compiler, method, """{ 
      Stream<String> stream;
      String localString; 
      await for (localString in stream) {} 
  }""");
  analyzeIn(
      compiler,
      method,
      """{ 
      Stream<String> stream;
      int localInt; 
      await for (localInt in stream) {} 
  }""",
      hints: MessageKind.FORIN_NOT_ASSIGNABLE);

  analyzeIn(compiler, method, """{ 
      Stream<String> stream;
      await for (topLevelDyn in stream) {} 
  }""");
  analyzeIn(compiler, method, """{ 
      Stream<String> stream;
      await for (topLevelString in stream) {} 
  }""");
  analyzeIn(
      compiler,
      method,
      """{ 
      Stream<String> stream;
      await for (topLevelInt in stream) {} 
  }""",
      hints: MessageKind.FORIN_NOT_ASSIGNABLE);

  analyzeIn(compiler, method, """{ 
      Stream<String> stream;
      await for (instanceDyn in stream) {} 
  }""");
  analyzeIn(compiler, method, """{ 
      Stream<String> stream;
      await for (instanceString in stream) {} 
  }""");
  analyzeIn(
      compiler,
      method,
      """{ 
      Stream<String> stream;
      await for (instanceInt in stream) {} 
  }""",
      hints: MessageKind.FORIN_NOT_ASSIGNABLE);

  analyzeIn(compiler, method, """{ 
      Stream<String> stream;
      await for (staticDyn in stream) {} 
  }""");
  analyzeIn(compiler, method, """{ 
      Stream<String> stream;
      await for (staticString in stream) {} 
  }""");
  analyzeIn(
      compiler,
      method,
      """{ 
      Stream<String> stream;
      await for (staticInt in stream) {} 
  }""",
      hints: MessageKind.FORIN_NOT_ASSIGNABLE);
}

testWhile(MockCompiler compiler) {
  check(String code, {warnings}) {
    analyze(compiler, code, warnings: warnings);
  }

  check("while (true) {}");
  check("while (null) {}");
  check("while (0) {}", warnings: NOT_ASSIGNABLE);
  check("while ('') {}", warnings: NOT_ASSIGNABLE);

  check("do {} while (true);");
  check("do {} while (null);");
  check("do {} while (0);", warnings: NOT_ASSIGNABLE);
  check("do {} while ('');", warnings: NOT_ASSIGNABLE);
  check("do { int i = 0.5; } while (true);", warnings: NOT_ASSIGNABLE);
  check("do { int i = 0.5; } while (null);", warnings: NOT_ASSIGNABLE);
}

testTry(MockCompiler compiler) {
  check(String code, {warnings}) {
    analyze(compiler, code, warnings: warnings);
  }

  check("try {} finally {}");
  check("try {} catch (e) { int i = e;} finally {}");
  check("try {} catch (e, s) { int i = e; StackTrace j = s; } finally {}");
  check("try {} on String catch (e) {} finally {}");
  check("try { int i = ''; } finally {}", warnings: NOT_ASSIGNABLE);
  check("try {} finally { int i = ''; }", warnings: NOT_ASSIGNABLE);
  check("try {} on String catch (e) { int i = e; } finally {}",
      warnings: NOT_ASSIGNABLE);
  check("try {} catch (e, s) { int i = e; int j = s; } finally {}",
      warnings: NOT_ASSIGNABLE);
  check("try {} on String catch (e, s) { int i = e; int j = s; } finally {}",
      warnings: [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
}

testSwitch(MockCompiler compiler) {
  check(String code, {warnings}) {
    analyze(compiler, code, warnings: warnings);
  }

  check("switch (0) { case 1: break; case 2: break; }");
  check("switch (0) { case 1: int i = ''; break; case 2: break; }",
      warnings: NOT_ASSIGNABLE);
  check("switch (0) { case '': break; }", warnings: NOT_ASSIGNABLE);
  check("switch ('') { case 1: break; case 2: break; }",
      warnings: [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
  check("switch (1.5) { case 1: break; case 2: break; }",
      warnings: [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
}

testEnumSwitch(MockCompiler compiler) {
  String DECLARATIONS = """
enum Enum { A, B, C }
""";

  check(String code, {warnings}) {
    MockCompiler compiler = new MockCompiler.internal();
    return compiler.init(DECLARATIONS).then((_) {
      analyze(compiler, code, warnings: warnings, flushDeferred: true);
    });
  }

  check("""
switch (Enum.A) {
default: break;
}""");

  check("""
switch (Enum.A) {
case Enum.A: break;
default: break;
}""");

  check("""
switch (Enum.A) {
case Enum.A: break;
case Enum.B: break;
default: break;
}""");

  check("""
switch (Enum.A) {
case Enum.A: break;
case Enum.B: break;
case Enum.C: break;
default: break;
}""");

  check("""
switch (Enum.A) {
case Enum.A: break;
case Enum.B: break;
case Enum.C: break;
}""");

  check("""
switch (Enum.A) {
case Enum.B: break;
case Enum.C: break;
}""", warnings: MessageKind.MISSING_ENUM_CASES);

  check("""
switch (Enum.A) {
case Enum.A: break;
case Enum.C: break;
}""", warnings: MessageKind.MISSING_ENUM_CASES);

  check("""
switch (Enum.A) {
case Enum.A: break;
case Enum.B: break;
}""", warnings: MessageKind.MISSING_ENUM_CASES);

  check("""
switch (Enum.A) {
case Enum.A: break;
}""", warnings: MessageKind.MISSING_ENUM_CASES);

  check("""
switch (Enum.A) {
case Enum.B: break;
}""", warnings: MessageKind.MISSING_ENUM_CASES);

  check("""
switch (Enum.A) {
case Enum.C: break;
}""", warnings: MessageKind.MISSING_ENUM_CASES);

  check("""
switch (Enum.A) {
}""", warnings: MessageKind.MISSING_ENUM_CASES);
}

testOperators(MockCompiler compiler) {
  check(String code, {warnings}) {
    analyze(compiler, code, warnings: warnings);
  }

  // TODO(karlklose): add the DartC tests for operators when we can parse
  // classes with operators.
  for (final op in ['+', '-', '*', '/', '%', '~/', '|', '&']) {
    check("{ var i = 1 ${op} 2; }");
    check("{ var i = 1; i ${op}= 2; }");
    check("{ int i; var j = (i = true) ${op} 2; }",
        warnings: [NOT_ASSIGNABLE, MessageKind.UNDEFINED_OPERATOR]);
    check("{ int i; var j = 1 ${op} (i = true); }",
        warnings: [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
  }
  for (final op in ['-', '~']) {
    check("{ var i = ${op}1; }");
    check("{ int i; var j = ${op}(i = true); }",
        warnings: [NOT_ASSIGNABLE, MessageKind.UNDEFINED_OPERATOR]);
  }
  for (final op in ['++', '--']) {
    check("{ int i = 1; int j = i${op}; }");
    check("{ int i = 1; bool j = i${op}; }", warnings: NOT_ASSIGNABLE);
    check("{ bool b = true; bool j = b${op}; }",
        warnings: MessageKind.UNDEFINED_OPERATOR);
    check("{ bool b = true; int j = ${op}b; }",
        warnings: MessageKind.UNDEFINED_OPERATOR);
  }
  for (final op in ['||', '&&']) {
    check("{ bool b = (true ${op} false); }");
    check("{ int b = true ${op} false; }", warnings: NOT_ASSIGNABLE);
    check("{ bool b = (1 ${op} false); }", warnings: NOT_ASSIGNABLE);
    check("{ bool b = (true ${op} 2); }", warnings: NOT_ASSIGNABLE);
  }
  for (final op in ['>', '<', '<=', '>=']) {
    check("{ bool b = 1 ${op} 2; }");
    check("{ int i = 1 ${op} 2; }", warnings: NOT_ASSIGNABLE);
    check("{ int i; bool b = (i = true) ${op} 2; }",
        warnings: [NOT_ASSIGNABLE, MessageKind.UNDEFINED_OPERATOR]);
    check("{ int i; bool b = 1 ${op} (i = true); }",
        warnings: [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
  }
  for (final op in ['==', '!=']) {
    check("{ bool b = 1 ${op} 2; }");
    check("{ int i = 1 ${op} 2; }", warnings: NOT_ASSIGNABLE);
    check("{ int i; bool b = (i = true) ${op} 2; }", warnings: NOT_ASSIGNABLE);
    check("{ int i; bool b = 1 ${op} (i = true); }", warnings: NOT_ASSIGNABLE);
  }
}

void testConstructorInvocationArgumentCount(MockCompiler compiler) {
  compiler.parseScript("""
     class C1 { C1(x, y); }
     class C2 { C2(int x, int y); }
  """);

  check(String code, {warnings}) {
    analyze(compiler, code, warnings: warnings);
  }

  // calls to untyped constructor C1
  check("new C1(1, 2);");
  check("new C1();", warnings: MessageKind.MISSING_ARGUMENT);
  check("new C1(1);", warnings: MessageKind.MISSING_ARGUMENT);
  check("new C1(1, 2, 3);", warnings: MessageKind.ADDITIONAL_ARGUMENT);
  // calls to typed constructor C2
  check("new C2(1, 2);");
  check("new C2();", warnings: MessageKind.MISSING_ARGUMENT);
  check("new C2(1);", warnings: MessageKind.MISSING_ARGUMENT);
  check("new C2(1, 2, 3);", warnings: MessageKind.ADDITIONAL_ARGUMENT);
}

void testConstructorInvocationArgumentTypes(MockCompiler compiler) {
  compiler.parseScript("""
    class C1 { C1(x); }
    class C2 { C2(int x); }
    class C3 {
      int field;
      C3(this.field);
      C3.named(this.field);
    }
  """);

  check(String code, {warnings}) {
    analyze(compiler, code, warnings: warnings);
  }

  check("new C1(42);");
  check("new C1('string');");
  check("new C2(42);");
  check("new C2('string');", warnings: NOT_ASSIGNABLE);
  check("new C3(42);");
  check("new C3('string');", warnings: NOT_ASSIGNABLE);
  check("new C3.named(42);");
  check("new C3.named('string');", warnings: NOT_ASSIGNABLE);
}

void testMethodInvocationArgumentCount(MockCompiler compiler) {
  compiler.parseScript(CLASS_WITH_METHODS);

  check(String text, [expectedWarnings]) {
    analyze(compiler, "{ ClassWithMethods c; $text }",
        warnings: expectedWarnings);
  }

  check("c.untypedNoArgumentMethod(1);", MessageKind.ADDITIONAL_ARGUMENT);
  check("c.untypedOneArgumentMethod();", MessageKind.MISSING_ARGUMENT);
  check("c.untypedOneArgumentMethod(1, 1);", MessageKind.ADDITIONAL_ARGUMENT);
  check("c.untypedTwoArgumentMethod();", MessageKind.MISSING_ARGUMENT);
  check(
      "c.untypedTwoArgumentMethod(1, 2, 3);", MessageKind.ADDITIONAL_ARGUMENT);
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
  check("c.intOneArgumentOneOptionalMethod(a: 0, b: 1);", [
    MessageKind.NAMED_ARGUMENT_NOT_FOUND,
    MessageKind.NAMED_ARGUMENT_NOT_FOUND,
    MessageKind.MISSING_ARGUMENT
  ]);

  check("c.intTwoOptionalMethod();");
  check("c.intTwoOptionalMethod(0);");
  check("c.intTwoOptionalMethod(0, 1);");
  check("c.intTwoOptionalMethod(0, 1, 2);", [MessageKind.ADDITIONAL_ARGUMENT]);
  check(
      "c.intTwoOptionalMethod(a: 0);", [MessageKind.NAMED_ARGUMENT_NOT_FOUND]);
  check("c.intTwoOptionalMethod(0, b: 1);",
      [MessageKind.NAMED_ARGUMENT_NOT_FOUND]);

  check("c.intOneArgumentOneNamedMethod();", [MessageKind.MISSING_ARGUMENT]);
  check("c.intOneArgumentOneNamedMethod(0);");
  check("c.intOneArgumentOneNamedMethod(0, b: 1);");
  check(
      "c.intOneArgumentOneNamedMethod(b: 1);", [MessageKind.MISSING_ARGUMENT]);
  check("c.intOneArgumentOneNamedMethod(0, b: 1, c: 2);",
      [MessageKind.NAMED_ARGUMENT_NOT_FOUND]);
  check("c.intOneArgumentOneNamedMethod(0, 1);",
      [MessageKind.ADDITIONAL_ARGUMENT]);
  check("c.intOneArgumentOneNamedMethod(0, 1, c: 2);",
      [MessageKind.ADDITIONAL_ARGUMENT, MessageKind.NAMED_ARGUMENT_NOT_FOUND]);
  check("c.intOneArgumentOneNamedMethod(a: 1, b: 1);",
      [MessageKind.NAMED_ARGUMENT_NOT_FOUND, MessageKind.MISSING_ARGUMENT]);

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
      [MessageKind.ADDITIONAL_ARGUMENT, MessageKind.ADDITIONAL_ARGUMENT]);
  check("c.intTwoNamedMethod(0, c: 2);",
      [MessageKind.ADDITIONAL_ARGUMENT, MessageKind.NAMED_ARGUMENT_NOT_FOUND]);
}

void testMethodInvocations(MockCompiler compiler) {
  compiler.parseScript(CLASS_WITH_METHODS);

  check(String text, [expectedWarnings]) {
    analyze(
        compiler,
        """{
               ClassWithMethods c;
               SubClass d;
               var e;
               int i;
               int j;
               int localMethod(String str) { return 0; }
               $text
               }
               """,
        warnings: expectedWarnings);
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
  check("ClassWithMethods x = c.intNoArgumentMethod();", NOT_ASSIGNABLE);

  check("int k = c.intOneArgumentMethod(c);", NOT_ASSIGNABLE);
  check("ClassWithMethods x = c.intOneArgumentMethod(1);", NOT_ASSIGNABLE);
  check("int k = c.intOneArgumentMethod('string');", NOT_ASSIGNABLE);
  check("int k = c.intOneArgumentMethod(i);");

  check("int k = c.intTwoArgumentMethod(1, 'string');", NOT_ASSIGNABLE);
  check("int k = c.intTwoArgumentMethod(i, j);");
  check("ClassWithMethods x = c.intTwoArgumentMethod(i, j);", NOT_ASSIGNABLE);

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

  check("c.intOneArgumentOneOptionalMethod('');", NOT_ASSIGNABLE);
  check("c.intOneArgumentOneOptionalMethod('', '');",
      [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  check("c.intTwoOptionalMethod('');", NOT_ASSIGNABLE);
  check("c.intTwoOptionalMethod('', '');", [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  check("c.intOneArgumentOneNamedMethod('');", NOT_ASSIGNABLE);
  check("c.intOneArgumentOneNamedMethod('', b: '');",
      [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  check("c.intTwoNamedMethod(a: '');", NOT_ASSIGNABLE);
  check("c.intTwoNamedMethod(b: '');", NOT_ASSIGNABLE);
  check("c.intTwoNamedMethod(a: '', b: '');", [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
  check("c.intTwoNamedMethod(b: '', a: '');", [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

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
  check("ClassWithMethods.staticMethod();", MessageKind.MISSING_ARGUMENT);
  check("ClassWithMethods.staticMethod(1);", NOT_ASSIGNABLE);
  check("ClassWithMethods.staticMethod('string');");
  check("int k = ClassWithMethods.staticMethod('string');");
  check("String k = ClassWithMethods.staticMethod('string');", NOT_ASSIGNABLE);

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

Future testMethodInvocationsInClass(MockCompiler compiler) {
  MockCompiler compiler = new MockCompiler.internal();
  return compiler.init(CLASS_WITH_METHODS).then((_) {
    LibraryElement library = compiler.mainApp;
    compiler.parseScript(CLASS_WITH_METHODS, library);
    ClassElement ClassWithMethods = library.find("ClassWithMethods");
    ClassWithMethods.ensureResolved(compiler.resolution);
    Element c = ClassWithMethods.lookupLocalMember('method');
    assert(c != null);
    ClassElement SubClass = library.find("SubClass");
    SubClass.ensureResolved(compiler.resolution);
    Element d = SubClass.lookupLocalMember('method');
    assert(d != null);

    check(Element element, String text, [expectedWarnings]) {
      analyzeIn(
          compiler,
          element,
          """{
                     var e;
                     int i;
                     int j;
                     int localMethod(String str) { return 0; }
                     $text
                   }""",
          warnings: expectedWarnings);
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
    check(c, "ClassWithMethods x = intNoArgumentMethod();", NOT_ASSIGNABLE);

    check(c, "int k = intOneArgumentMethod('');", NOT_ASSIGNABLE);
    check(c, "ClassWithMethods x = intOneArgumentMethod(1);", NOT_ASSIGNABLE);
    check(c, "int k = intOneArgumentMethod('string');", NOT_ASSIGNABLE);
    check(c, "int k = intOneArgumentMethod(i);");

    check(c, "int k = intTwoArgumentMethod(1, 'string');", NOT_ASSIGNABLE);
    check(c, "int k = intTwoArgumentMethod(i, j);");
    check(
        c, "ClassWithMethods x = intTwoArgumentMethod(i, j);", NOT_ASSIGNABLE);

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

    check(c, "intOneArgumentOneOptionalMethod('');", NOT_ASSIGNABLE);
    check(c, "intOneArgumentOneOptionalMethod('', '');",
        [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

    check(c, "intTwoOptionalMethod('');", NOT_ASSIGNABLE);
    check(c, "intTwoOptionalMethod('', '');", [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

    check(c, "intOneArgumentOneNamedMethod('');", NOT_ASSIGNABLE);
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
    check(c, "(foo)();", UNDEFINED_GETTER);
    check(c, "(foo)(1);", UNDEFINED_GETTER);
    check(c, "(foo)('string');", UNDEFINED_GETTER);

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
    check(c, "staticMethod();", MessageKind.MISSING_ARGUMENT);
    check(c, "staticMethod(1);", NOT_ASSIGNABLE);
    check(c, "staticMethod('string');");
    check(c, "int k = staticMethod('string');");
    check(c, "String k = staticMethod('string');", NOT_ASSIGNABLE);
    check(d, "staticMethod();", MessageKind.UNDEFINED_METHOD);
    check(d, "staticMethod(1);", MessageKind.UNDEFINED_METHOD);
    check(d, "staticMethod('string');", MessageKind.UNDEFINED_METHOD);
    check(d, "int k = staticMethod('string');", MessageKind.UNDEFINED_METHOD);
    check(
        d, "String k = staticMethod('string');", MessageKind.UNDEFINED_METHOD);

    // Invocation on dynamic variable.
    check(c, "e.foo();");
    check(c, "e.foo(1);");
    check(c, "e.foo('string');");

    // Invocation on unresolved variable.
    check(c, "foo();", MessageKind.UNDEFINED_METHOD);
    check(c, "foo(1);", MessageKind.UNDEFINED_METHOD);
    check(c, "foo('string');", MessageKind.UNDEFINED_METHOD);
    check(c, "foo(a: 'string');", MessageKind.UNDEFINED_METHOD);
    check(c, "foo(a: localMethod(1));",
        [MessageKind.UNDEFINED_METHOD, NOT_ASSIGNABLE]);
  });
}

void testFunctionCall(MockCompiler compiler) {
  compiler.parseScript(CLASS_WITH_METHODS);

  check(String text, [expectedWarnings]) {
    analyze(
        compiler,
        """{
               ClassWithMethods x;
               int localMethod(String str) { return 0; }
               String2Int string2int;
               Function function;
               SubFunction subFunction;
               $text
               }
               """,
        warnings: expectedWarnings);
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

testNewExpression(MockCompiler compiler) {
  compiler.parseScript("class A {}");
  analyze(compiler, "A a = new A();");
  analyze(compiler, "int i = new A();", warnings: NOT_ASSIGNABLE);

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

testConditionalExpression(MockCompiler compiler) {
  check(String code, {warnings}) {
    analyze(compiler, code, warnings: warnings);
  }

  check("int i = true ? 2 : 1;");
  check("int i = true ? 'hest' : 1;");
  check("int i = true ? 'hest' : 'fisk';", warnings: NOT_ASSIGNABLE);
  check("String s = true ? 'hest' : 'fisk';");

  check("true ? 1 : 2;");
  check("null ? 1 : 2;");
  check("0 ? 1 : 2;", warnings: NOT_ASSIGNABLE);
  check("'' ? 1 : 2;", warnings: NOT_ASSIGNABLE);
  check("{ int i; true ? i = 2.7 : 2; }", warnings: NOT_ASSIGNABLE);
  check("{ int i; true ? 2 : i = 2.7; }", warnings: NOT_ASSIGNABLE);
  check("{ int i; i = true ? 2.7 : 2; }");

  compiler.parseScript("""
    bool cond() => true;
    void f1() {}
    void f2() {}""");
  check("{ cond() ? f1() : f2(); }");
}

testIfStatement(MockCompiler compiler) {
  check(String code, {warnings}) {
    analyze(compiler, code, warnings: warnings);
  }

  check("if (true) {}");
  check("if (null) {}");
  check("if (0) {}", warnings: NOT_ASSIGNABLE);
  check("if ('') {}", warnings: NOT_ASSIGNABLE);
  check("{ int i = 27; if (true) { i = 2.7; } else {} }",
      warnings: NOT_ASSIGNABLE);
  check("{ int i = 27; if (true) {} else { i = 2.7; } }",
      warnings: NOT_ASSIGNABLE);
}

testThis(MockCompiler compiler) {
  String script = """class Foo {
                       void method() {}
                     }""";
  compiler.parseScript(script);
  LibraryElement mainApp = compiler.mainApp;
  ClassElement foo = mainApp.find("Foo");
  foo.ensureResolved(compiler.resolution);
  Element method = foo.lookupLocalMember('method');
  analyzeIn(compiler, method, "{ int i = this; }", warnings: NOT_ASSIGNABLE);
  analyzeIn(compiler, method, "{ Object o = this; }");
  analyzeIn(compiler, method, "{ Foo f = this; }");
}

testSuper(MockCompiler compiler) {
  String script = r'''
    class A {
      String field = "42";
    }

    class B extends A {
      Object field = 42;
      void method() {}
    }
    ''';
  compiler.parseScript(script);
  LibraryElement mainApp = compiler.mainApp;
  ClassElement B = mainApp.find("B");
  B.ensureResolved(compiler.resolution);
  Element method = B.lookupLocalMember('method');
  analyzeIn(compiler, method, "{ int i = super.field; }",
      warnings: NOT_ASSIGNABLE);
  analyzeIn(compiler, method, "{ Object o = super.field; }");
  analyzeIn(compiler, method, "{ String s = super.field; }");
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

testOperatorsAssignability(MockCompiler compiler) {
  compiler.parseScript(CLASSES_WITH_OPERATORS);

  // Tests against Operators.

  String header = """{
      bool z;
      Operators a;
      Operators b;
      Operators c;
      """;

  check(String text, [expectedWarnings]) {
    analyze(compiler, '$header $text }', warnings: expectedWarnings);
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
    check('z = a $o b;', [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
    check('a = a $o b;', [NOT_ASSIGNABLE, NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
  }

  check('z = !z;');
  check('z = !a;', NOT_ASSIGNABLE);
  check('a = !z;', NOT_ASSIGNABLE);
  check('a = !a;', [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

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
  check('b = ++a;', [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  // 1 is not applicable to operator +.
  check('b = a[0]++;', NOT_ASSIGNABLE);
  // 1 is not applicable to operator +.
  // `++a[0]` of type int is not assignable to `b`.
  check('b = ++a[0];', [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

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
  check('a[c] += b;', [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

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
  check('a[0] += "";', [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
  // `true` is not applicable to operator + on `a[0]`.
  // `true` is not assignable to `a[0]`.
  check('a[0] += true;', [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);
}

Future testFieldInitializers(MockCompiler compiler) {
  Future check(String code, [expectedWarnings]) {
    return analyzeTopLevel(code, expectedWarnings);
  }

  return Future.wait([
    check("""int i = 0;"""),
    check("""int i = '';""", NOT_ASSIGNABLE),
    check("""class Class {
               int i = 0;
             }"""),
    check("""class Class {
               int i = '';
             }""", NOT_ASSIGNABLE),
  ]);
}

void testTypeVariableExpressions(MockCompiler compiler) {
  String script = """class Foo<T> {
                       void method() {}
                     }""";
  compiler.parseScript(script);
  LibraryElement mainApp = compiler.mainApp;
  ClassElement foo = mainApp.find("Foo");
  foo.ensureResolved(compiler.resolution);
  Element method = foo.lookupLocalMember('method');

  analyzeIn(compiler, method, "{ Type type = T; }");
  analyzeIn(compiler, method, "{ T type = T; }", warnings: NOT_ASSIGNABLE);
  analyzeIn(compiler, method, "{ int type = T; }", warnings: NOT_ASSIGNABLE);

  analyzeIn(compiler, method, "{ String typeName = T.toString(); }");
  analyzeIn(compiler, method, "{ T.foo; }", warnings: UNDEFINED_GETTER);
  analyzeIn(compiler, method, "{ T.foo = 0; }",
      warnings: MessageKind.UNDEFINED_SETTER);
  analyzeIn(compiler, method, "{ T.foo(); }",
      warnings: MessageKind.UNDEFINED_METHOD);
  analyzeIn(compiler, method, "{ T + 1; }",
      warnings: MessageKind.UNDEFINED_OPERATOR);
}

void testTypeVariableLookup1(MockCompiler compiler) {
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

  compiler.parseScript(script);
  LibraryElement mainApp = compiler.mainApp;
  ClassElement classTest = mainApp.find("Test");
  classTest.ensureResolved(compiler.resolution);
  FunctionElement methodTest = classTest.lookupLocalMember("test");

  test(String expression, [message]) {
    analyzeIn(compiler, methodTest, "{ $expression; }", warnings: message);
  }

  test('s.field');
  test('s.method(1)');
  test('s + s');
  test('s.getter');

  test('t.toString');
  test('t.field', UNDEFINED_GETTER);
  test('t.method(1)', MessageKind.UNDEFINED_METHOD);
  test('t + t', MessageKind.UNDEFINED_OPERATOR);
  test('t.getter', UNDEFINED_GETTER);

  test('s.field = "hest"', NOT_ASSIGNABLE);
  test('s.method("hest")', NOT_ASSIGNABLE);
  test('s + "hest"', NOT_ASSIGNABLE);
  test('String v = s.getter', NOT_ASSIGNABLE);
}

void testTypeVariableLookup2(MockCompiler compiler) {
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

  compiler.parseScript(script);
  LibraryElement mainApp = compiler.mainApp;
  ClassElement classTest = mainApp.find("Test");
  classTest.ensureResolved(compiler.resolution);
  FunctionElement methodTest = classTest.lookupLocalMember("test");

  test(String expression, [message]) {
    analyzeIn(compiler, methodTest, "{ $expression; }", warnings: message);
  }

  test('s.field');
  test('s.method(1)');
  test('s + s');
  test('s.getter');
}

void testTypeVariableLookup3(MockCompiler compiler) {
  String script = """
class Test<S extends T, T extends S> {
  S s;
  test() {}
}""";

  compiler.parseScript(script);
  LibraryElement mainApp = compiler.mainApp;
  ClassElement classTest = mainApp.find("Test");
  classTest.ensureResolved(compiler.resolution);
  FunctionElement methodTest = classTest.lookupLocalMember("test");

  test(String expression, [message]) {
    analyzeIn(compiler, methodTest, "{ $expression; }", warnings: message);
  }

  test('s.toString');
  test('s.field', UNDEFINED_GETTER);
  test('s.method(1)', MessageKind.UNDEFINED_METHOD);
  test('s + s', MessageKind.UNDEFINED_OPERATOR);
  test('s.getter', UNDEFINED_GETTER);
}

void testFunctionTypeLookup(MockCompiler compiler) {
  check(String code, {warnings}) {
    analyze(compiler, code, warnings: warnings);
  }

  check('(int f(int)) => f.toString;');
  check('(int f(int)) => f.toString();');
  check('(int f(int)) => f.foo;', warnings: UNDEFINED_GETTER);
  check('(int f(int)) => f.foo();', warnings: MessageKind.UNDEFINED_METHOD);
}

void testTypedefLookup(MockCompiler compiler) {
  check(String code, {warnings}) {
    analyze(compiler, code, warnings: warnings);
  }

  compiler.parseScript("typedef int F(int);");
  check('(F f) => f.toString;');
  check('(F f) => f.toString();');
  check('(F f) => f.foo;', warnings: UNDEFINED_GETTER);
  check('(F f) => f.foo();', warnings: MessageKind.UNDEFINED_METHOD);
}

void testTypeLiteral(MockCompiler compiler) {
  check(String code, {warnings}) {
    analyze(compiler, code, warnings: warnings);
  }

  final String source = r"""class Class {
                              static var field = null;
                              static method() {}
                            }""";
  compiler.parseScript(source);

  // Check direct access.
  check('Type m() => int;');
  check('int m() => int;', warnings: NOT_ASSIGNABLE);

  // Check access in assignment.
  check('m(Type val) => val = Class;');
  check('m(int val) => val = Class;', warnings: NOT_ASSIGNABLE);
  check('m(Type val) => val = dynamic;');
  check('m(int val) => val = dynamic;', warnings: NOT_ASSIGNABLE);

  // Check access as argument.
  check('m(Type val) => m(int);');
  check('m(int val) => m(int);', warnings: NOT_ASSIGNABLE);

  // Check access as argument in member access.
  check('m(Type val) => m(int).foo;');
  check('m(int val) => m(int).foo;', warnings: NOT_ASSIGNABLE);

  // Check static property access.
  check('m() => Class.field;');
  check('m() => (Class).field;', warnings: UNDEFINED_GETTER);

  // Check static method access.
  check('m() => Class.method();');
  check('m() => (Class).method();', warnings: MessageKind.UNDEFINED_METHOD);

  // Check access in invocation.
  check('m() => Class();', warnings: MessageKind.NOT_CALLABLE);
  check('m() => dynamic();', warnings: MessageKind.NOT_CALLABLE);
}

Future testInitializers(MockCompiler compiler) {
  Future check(String text, [expectedWarnings]) {
    return analyzeTopLevel(text, expectedWarnings);
  }

  return Future.wait([
    // Check initializers.
    check(r'''class Class {
                var a;
                Class(this.a);
              }
              '''),
    check(r'''class Class {
                int a;
                Class(this.a);
              }
              '''),
    check(r'''class Class {
                var a;
                Class(int this.a);
              }
              '''),
    check(r'''class Class {
                String a;
                Class(int this.a);
              }
              ''', NOT_ASSIGNABLE),
    check(r'''class Class {
                var a;
                Class(int a) : this.a = a;
              }
              '''),
    check(r'''class Class {
                String a;
                Class(int a) : this.a = a;
              }
              ''', NOT_ASSIGNABLE),

    // Check this-calls.
    check(r'''class Class {
                var a;
                Class(this.a);
                Class.named(int a) : this(a);
              }
              '''),
    check(r'''class Class {
                String a;
                Class(this.a);
                Class.named(int a) : this(a);
              }
              ''', NOT_ASSIGNABLE),
    check(r'''class Class {
                String a;
                Class(var a) : this.a = a;
                Class.named(int a) : this(a);
              }
              '''),
    check(r'''class Class {
                String a;
                Class(String a) : this.a = a;
                Class.named(int a) : this(a);
              }
              ''', NOT_ASSIGNABLE),

    // Check super-calls.
    check(r'''class Super {
                var a;
                Super(this.a);
              }
              class Class extends Super {
                Class.named(int a) : super(a);
              }
              '''),
    check(r'''class Super {
                String a;
                Super(this.a);
              }
              class Class extends Super {
                Class.named(int a) : super(a);
              }
              ''', NOT_ASSIGNABLE),
    check(r'''class Super {
                String a;
                Super(var a) : this.a = a;
              }
              class Class extends Super {
                Class.named(int a) : super(a);
              }
              '''),
    check(r'''class Super {
                String a;
                Super(String a) : this.a = a;
              }
              class Class extends Super {
                Class.named(int a) : super(a);
              }
              ''', NOT_ASSIGNABLE),

    // Check super-calls involving generics.
    check(r'''class Super<T> {
                var a;
                Super(this.a);
              }
              class Class extends Super<String> {
                Class.named(int a) : super(a);
              }
              '''),
    check(r'''class Super<T> {
                T a;
                Super(this.a);
              }
              class Class extends Super<String> {
                Class.named(int a) : super(a);
              }
              ''', NOT_ASSIGNABLE),
    check(r'''class Super<T> {
                T a;
                Super(var a) : this.a = a;
              }
              class Class extends Super<String> {
                Class.named(int a) : super(a);
              }
              '''),
    check(r'''class Super<T> {
                T a;
                Super(T a) : this.a = a;
              }
              class Class extends Super<String> {
                Class.named(int a) : super(a);
              }
              ''', NOT_ASSIGNABLE),

    // Check instance creations.
    check(r'''class Class {
                var a;
                Class(this.a);
              }
              method(int a) => new Class(a);
              '''),
    check(r'''class Class {
                String a;
                Class(this.a);
              }
              method(int a) => new Class(a);
              ''', NOT_ASSIGNABLE),
    check(r'''class Class {
                String a;
                Class(var a) : this.a = a;
              }
              method(int a) => new Class(a);
              '''),
    check(r'''class Class {
                String a;
                Class(String a) : this.a = a;
              }
              method(int a) => new Class(a);
              ''', NOT_ASSIGNABLE),

    // Check instance creations involving generics.
    check(r'''class Class<T> {
                var a;
                Class(this.a);
              }
              method(int a) => new Class<String>(a);
              '''),
    check(r'''class Class<T> {
                T a;
                Class(this.a);
              }
              method(int a) => new Class<String>(a);
              ''', NOT_ASSIGNABLE),
    check(r'''class Class<T> {
                T a;
                Class(var a) : this.a = a;
              }
              method(int a) => new Class<String>(a);
              '''),
    check(r'''class Class<T> {
                T a;
                Class(String a) : this.a = a;
              }
              method(int a) => new Class<String>(a);
              ''', NOT_ASSIGNABLE),
  ]);
}

void testGetterSetterInvocation(MockCompiler compiler) {
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
    analyze(compiler, '{ $text }', warnings: expectedWarnings);
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
  check("variable += '';", [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  check("c.instanceField = '';");
  check("int v = c.instanceField;");
  check("c.instanceField = 0;", NOT_ASSIGNABLE);
  check("String v = c.instanceField;", NOT_ASSIGNABLE);

  // num is not assignable to String (the type of the setter).
  check("c.instanceField += 0;", NOT_ASSIGNABLE);
  // String is not assignable to int (the argument type of the operator + on the
  // getter) and num (the result type of the operation) is not assignable to
  // String (the type of the setter).
  check("c.instanceField += '';", [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  check("Class.staticField = '';");
  check("int v = Class.staticField;");
  check("Class.staticField = 0;", NOT_ASSIGNABLE);
  check("String v = Class.staticField;", NOT_ASSIGNABLE);

  // num is not assignable to String (the type of the setter).
  check("Class.staticField += 0;", NOT_ASSIGNABLE);
  // String is not assignable to int (the argument type of the operator + on the
  // getter) and num (the result type of the operation) is not assignable to
  // String (the type of the setter).
  check("Class.staticField += '';", [NOT_ASSIGNABLE, NOT_ASSIGNABLE]);

  check("int v = c.overriddenField;");
  check("c.overriddenField = 0;");
  check("int v = c.getterField;");
  check("c.getterField = 0;", MessageKind.UNDEFINED_SETTER);
  check("int v = c.setterField;",
      MessageKind.UNDEFINED_INSTANCE_GETTER_BUT_SETTER);
  check("c.setterField = 0;");

  check("int v = gc.overriddenField;");
  check("gc.overriddenField = 0;");
  check("int v = gc.setterField;");
  check("gc.setterField = 0;");
  check("int v = gc.getterField;");
  check("gc.getterField = 0;", MessageKind.UNDEFINED_SETTER);

  check("int v = sc.overriddenField;");
  check("sc.overriddenField = 0;");
  check("int v = sc.getterField;");
  check("sc.getterField = 0;");
  check("int v = sc.setterField;",
      MessageKind.UNDEFINED_INSTANCE_GETTER_BUT_SETTER);
  check("sc.setterField = 0;");
}

testTypePromotionHints(MockCompiler compiler) {
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
    analyze(compiler, '{ $text }',
        warnings: warnings, hints: hints, infos: infos);
  }

  check(r'''
            A a = new B();
            if (a is C) {
              var x = a.c;
            }''',
      warnings: [MessageKind.UNDEFINED_GETTER],
      hints: [MessageKind.NOT_MORE_SPECIFIC_SUBTYPE],
      infos: []);

  check(r'''
            A a = new B();
            if (a is C) {
              var x = '${a.c}${a.c}';
            }''',
      warnings: [MessageKind.UNDEFINED_GETTER, MessageKind.UNDEFINED_GETTER],
      hints: [MessageKind.NOT_MORE_SPECIFIC_SUBTYPE],
      infos: []);

  check(r'''
            A a = new B();
            if (a is C) {
              var x = '${a.d}${a.d}'; // Type promotion wouldn't help.
            }''',
      warnings: [MessageKind.UNDEFINED_GETTER, MessageKind.UNDEFINED_GETTER],
      hints: [],
      infos: []);

  check('''
           D<int> d = new E();
           if (d is E) { // Suggest E<int>.
             var x = d.e;
           }''', warnings: [
    MessageKind.UNDEFINED_GETTER
  ], hints: [
    checkMessage(MessageKind.NOT_MORE_SPECIFIC_SUGGESTION,
        {'shownTypeSuggestion': 'E<int>'})
  ], infos: []);

  check('''
           D<int> d = new F();
           if (d is F) { // Suggest F<int, dynamic>.
             var x = d.f;
           }''', warnings: [
    MessageKind.UNDEFINED_GETTER
  ], hints: [
    checkMessage(MessageKind.NOT_MORE_SPECIFIC_SUGGESTION,
        {'shownTypeSuggestion': 'F<int, dynamic>'})
  ], infos: []);

  check('''
           D<int> d = new G();
           if (d is G) { // Suggest G<int>.
             var x = d.f;
           }''', warnings: [
    MessageKind.UNDEFINED_GETTER
  ], hints: [
    checkMessage(MessageKind.NOT_MORE_SPECIFIC_SUGGESTION,
        {'shownTypeSuggestion': 'G<int>'})
  ], infos: []);

  check('''
           F<double, int> f = new G();
           if (f is G) { // Cannot suggest a more specific type.
             var x = f.g;
           }''',
      warnings: [MessageKind.UNDEFINED_GETTER],
      hints: [MessageKind.NOT_MORE_SPECIFIC],
      infos: []);

  check('''
           D<int> d = new E();
           if (d is E) {
             var x = d.f; // Type promotion wouldn't help.
           }''',
      warnings: [MessageKind.UNDEFINED_GETTER], hints: [], infos: []);

  check('''
           A a = new B();
           if (a is B) {
             a = null;
             var x = a.b;
           }''',
      warnings: [MessageKind.UNDEFINED_GETTER],
      hints: [MessageKind.POTENTIAL_MUTATION],
      infos: [MessageKind.POTENTIAL_MUTATION_HERE]);

  check('''
           A a = new B();
           if (a is B) {
             a = null;
             var x = a.c; // Type promotion wouldn't help.
           }''',
      warnings: [MessageKind.UNDEFINED_GETTER], hints: [], infos: []);

  check('''
           A a = new B();
           local() { a = new A(); }
           if (a is B) {
             var x = a.b;
           }''',
      warnings: [MessageKind.UNDEFINED_GETTER],
      hints: [MessageKind.POTENTIAL_MUTATION_IN_CLOSURE],
      infos: [MessageKind.POTENTIAL_MUTATION_IN_CLOSURE_HERE]);

  check('''
           A a = new B();
           local() { a = new A(); }
           if (a is B) {
             var x = a.c; // Type promotion wouldn't help.
           }''',
      warnings: [MessageKind.UNDEFINED_GETTER], hints: [], infos: []);

  check('''
           A a = new B();
           if (a is B) {
             var x = () => a;
             var y = a.b;
           }
           a = new A();''', warnings: [
    MessageKind.UNDEFINED_GETTER
  ], hints: [
    MessageKind.ACCESSED_IN_CLOSURE
  ], infos: [
    MessageKind.ACCESSED_IN_CLOSURE_HERE,
    MessageKind.POTENTIAL_MUTATION_HERE
  ]);

  check('''
           A a = new B();
           if (a is B) {
             var x = () => a;
             var y = a.c; // Type promotion wouldn't help.
           }
           a = new A();''',
      warnings: [MessageKind.UNDEFINED_GETTER], hints: [], infos: []);
}

void testCascade(MockCompiler compiler) {
  compiler.parseScript(r'''typedef A AFunc();
                           typedef Function FuncFunc();
                           class A {
                             A a;
                             B b;
                             C c;
                             AFunc afunc() => null;
                             FuncFunc funcfunc() => null;
                             C operator [](_) => null;
                             void operator []=(_, C c) {}
                           }
                           class B {
                             B b;
                             C c;
                           }
                           class C {
                             C c;
                             AFunc afunc() => null;
                           }
                           ''');

  check(String text, {warnings, hints, infos}) {
    analyze(compiler, '{ $text }',
        warnings: warnings, hints: hints, infos: infos);
  }

  check('A a = new A()..a;');

  check('A a = new A()..b;');

  check('A a = new A()..a..b;');

  check('A a = new A()..b..c..a;');

  check('B b = new A()..a;', warnings: NOT_ASSIGNABLE);

  check('B b = new A()..b;', warnings: NOT_ASSIGNABLE);

  check('B b = new A().b;');

  check('new A().b..b;');

  check('new A().b..a;', warnings: UNDEFINED_GETTER);

  check('B b = new A().b..c;');

  check('C c = new A().b..c;', warnings: NOT_ASSIGNABLE);

  check('A a = new A()..a = new A();');

  check('A a = new A()..b = new B();');

  check('B b = new A()..b = new B();', warnings: NOT_ASSIGNABLE);

  check('A a = new A()..b = new A();', warnings: NOT_ASSIGNABLE);

  check('AFunc a = new C().afunc();');

  check('AFunc a = new C()..afunc();', warnings: NOT_ASSIGNABLE);

  check('C c = new C()..afunc();');

  check('A a = new C().afunc()();');

  check('A a = new C()..afunc()();', warnings: NOT_ASSIGNABLE);

  check('AFunc a = new C()..afunc()();', warnings: NOT_ASSIGNABLE);

  check('FuncFunc f = new A().funcfunc();');

  check('A a = new A().funcfunc();', warnings: NOT_ASSIGNABLE);

  check('FuncFunc f = new A()..funcfunc();', warnings: NOT_ASSIGNABLE);

  check('A a = new A()..funcfunc();');

  check('FuncFunc f = new A()..funcfunc()();', warnings: NOT_ASSIGNABLE);

  check('A a = new A()..funcfunc()();');

  check('FuncFunc f = new A()..funcfunc()()();', warnings: NOT_ASSIGNABLE);

  check('A a = new A()..funcfunc()()();');

  check('''A a;
           a = new A()..a = a = new A()..c.afunc();''');

  check('''A a = new A()..b = new B()..c.afunc();''');

  check('''A a = new A()..b = new A()..c.afunc();''', warnings: NOT_ASSIGNABLE);

  check('''A a = new A()..b = new A()..c.afunc()();''',
      warnings: NOT_ASSIGNABLE);

  check('''A a = new A()..b = new A()..c.afunc()().b;''',
      warnings: NOT_ASSIGNABLE);

  check('A a = new A().afunc()()[0].afunc();', warnings: NOT_ASSIGNABLE);

  check('C c = new A().afunc()()[0].afunc();', warnings: NOT_ASSIGNABLE);

  check('AFunc a = new A().afunc()()[0].afunc();');

  check('A a = new A()..afunc()()[0].afunc();');

  check('C c = new A()..afunc()()[0].afunc();', warnings: NOT_ASSIGNABLE);

  check('AFunc a = new A()..afunc()()[0].afunc();', warnings: NOT_ASSIGNABLE);

  check('A a = new A().afunc()()[0]..afunc();', warnings: NOT_ASSIGNABLE);

  check('C c = new A().afunc()()[0]..afunc();');

  check('AFunc a = new A().afunc()()[0]..afunc();', warnings: NOT_ASSIGNABLE);

  check('A a = new A()..afunc()()[0]..afunc();');

  check('C c = new A()..afunc()()[0]..afunc();', warnings: NOT_ASSIGNABLE);

  check('AFunc a = new A()..afunc()()[0]..afunc();', warnings: NOT_ASSIGNABLE);

  check('new A()[0] = new A();', warnings: NOT_ASSIGNABLE);

  check('new A()[0] = new C();');

  check('new A().a[0] = new A();', warnings: NOT_ASSIGNABLE);

  check('new A().a[0] = new C();');

  check('new A()..a[0] = new A();', warnings: NOT_ASSIGNABLE);

  check('new A()..a[0] = new C();');

  check('new A()..afunc()()[0] = new A();', warnings: NOT_ASSIGNABLE);

  check('new A()..afunc()()[0] = new C();');
}

testAwait(MockCompiler compiler) {
  String script = """class Foo {
                       void method() async {}
                       Future<int> asyncInt() => new Future<int>.value(0);
                       Foo self() => this;
                     }""";
  compiler.parseScript(script);
  LibraryElement mainApp = compiler.mainApp;
  ClassElement foo = mainApp.find("Foo");
  foo.ensureResolved(compiler.resolution);
  FunctionElement method = foo.lookupLocalMember('method');
  analyzeIn(compiler, method, "{ await 0; }");
  analyzeIn(compiler, method, "{ int i = await 0; }");
  analyzeIn(compiler, method, "{ String s = await 0; }",
      warnings: NOT_ASSIGNABLE);
  analyzeIn(compiler, method, "{ await asyncInt(); }");
  analyzeIn(compiler, method, "{ int i = await asyncInt(); }");
  analyzeIn(compiler, method, "{ String s = await asyncInt(); }",
      warnings: NOT_ASSIGNABLE);
  analyzeIn(compiler, method, "{ Foo f = self(); }");
  analyzeIn(compiler, method, "{ Foo f = await self(); }");
  analyzeIn(compiler, method, "{ Foo f = await self().asyncInt(); }",
      warnings: NOT_ASSIGNABLE);
  analyzeIn(compiler, method, "{ int i = await self().asyncInt(); }");
  analyzeIn(compiler, method, "{ String s = await self().asyncInt(); }",
      warnings: NOT_ASSIGNABLE);
}

testAsyncReturn(MockCompiler compiler) {
  Future check(String code, [expectedWarnings]) {
    return analyzeTopLevel(code, expectedWarnings);
  }

  return Future.wait([
    check("Future<int> foo() async { return; }"),
    check("Future<int> foo() async { return null; }"),
    check("Future<int> foo() async { return 0; }"),
    check("Future<int> foo() async { return ''; }", NOT_ASSIGNABLE),
    check("Future<int> foo() async { return new Future.value(); }"),
    check("Future<int> foo() async { return new Future<int>.value(); }"),
    check("Future<int> foo() async { return new Future<String>.value(); }",
        NOT_ASSIGNABLE),
    check("""
          Future<int> foo() async { return new Future<Future<int>>.value(); }
          """),
    check("void foo() async { return; }"),
    check("void foo() async { return 0; }", MessageKind.RETURN_VALUE_IN_VOID),
    check("void foo() async { return new Future.value(); }",
        MessageKind.RETURN_VALUE_IN_VOID),
    check("int foo() async { return; }"),
    check("int foo() async { return 0; }", NOT_ASSIGNABLE),
    check(
        "int foo() async { return new Future<int>.value(); }", NOT_ASSIGNABLE),
    check("Future<int> foo() async => null;"),
    check("Future<int> foo() async => 0;"),
    check("Future<int> foo() async => '';", NOT_ASSIGNABLE),
    check("Future<int> foo() async => new Future.value();"),
    check("Future<int> foo() async => new Future<int>.value();"),
    check("Future<int> foo() async => new Future<String>.value();",
        NOT_ASSIGNABLE),
    check("""
    Future<int> foo() async => new Future<Future<int>>.value();
    """),
    check("void foo() async { return 0; }", MessageKind.RETURN_VALUE_IN_VOID),
    check("void foo() async { return new Future.value(); }",
        MessageKind.RETURN_VALUE_IN_VOID),
    check("int foo() async => 0;", NOT_ASSIGNABLE),
    check("int foo() async => new Future<int>.value();", NOT_ASSIGNABLE),
    check("Iterable<int> foo() sync* { return; }"),
    check("Stream<int> foo() async* { return; }"),
  ]);
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

String returnWithType(String type, expression) {
  return "$type foo() { return $expression; }";
}

String arrowReturnWithType(String type, expression) {
  return "$type foo() => $expression;";
}

Node parseExpression(String text) =>
    parseBodyCode(text, (parser, token) => parser.parseExpression(token));

const Map<String, String> ALT_SOURCE = const <String, String>{
  'num': r'''
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
      ''',
  'int': r'''
      abstract class int extends num {
        int operator &(int other);
        int operator |(int other);
        int operator ^(int other);
        int operator ~();
        int operator <<(int shiftAmount);
        int operator >>(int shiftAmount);
        int operator -();
      }
      ''',
  'String': r'''
      class String implements Pattern {
        String operator +(String other) => this;
      }
      ''',
};

Future setup(test(MockCompiler compiler)) {
  MockCompiler compiler =
      new MockCompiler.internal(coreSource: ALT_SOURCE, enableAsyncAwait: true);
  return compiler.init("import 'dart:async';").then((_) => test(compiler));
}

ResolutionDartType analyzeType(MockCompiler compiler, String text) {
  var node = parseExpression(text);
  TypeCheckerVisitor visitor = new TypeCheckerVisitor(
      compiler, new TreeElementMapping(null), compiler.resolution.types);
  return visitor.analyze(node);
}

analyzeTopLevel(String text, [expectedWarnings]) {
  if (expectedWarnings == null) expectedWarnings = [];
  if (expectedWarnings is! List) expectedWarnings = [expectedWarnings];

  MockCompiler compiler = new MockCompiler.internal(enableAsyncAwait: true);
  compiler.diagnosticHandler = createHandler(compiler, text);

  return compiler.init("import 'dart:async';").then((_) {
    LibraryElement library = compiler.mainApp;

    Link<Element> topLevelElements =
        parseUnit(text, compiler, library).reverse();

    ElementX element = null;
    Node node;
    TreeElements mapping;
    // Resolve all declarations and members.
    for (Link<Element> elements = topLevelElements;
        !elements.isEmpty;
        elements = elements.tail) {
      element = elements.head;
      if (element.isClass) {
        ClassElementX classElement = element;
        classElement.ensureResolved(compiler.resolution);
        classElement.forEachLocalMember((Element e) {
          if (!e.isSynthesized) {
            element = e;
            node = element.parseNode(compiler.parsingContext);
            compiler.resolver.resolve(element);
            mapping = element.treeElements;
          }
        });
      } else {
        node = element.parseNode(compiler.parsingContext);
        compiler.resolver.resolve(element);
        mapping = element.treeElements;
      }
    }
    // Type check last class declaration or member.
    TypeCheckerVisitor checker =
        new TypeCheckerVisitor(compiler, mapping, compiler.resolution.types);
    DiagnosticCollector collector = compiler.diagnosticCollector;
    collector.clear();
    checker.analyze(node, mustHaveType: false);
    compareWarningKinds(text, expectedWarnings, collector.warnings);

    compiler.diagnosticHandler = null;
  });
}

/**
 * Analyze the statement [text] and check messages from the type checker.
 * [errors] and [warnings] can be either [:null:], a single [MessageKind] or
 * a list of [MessageKind]s. If [hints] and [infos] are [:null:] the
 * corresponding message kinds are ignored.
 */
analyze(MockCompiler compiler, String text,
    {errors, warnings, List hints, List infos, bool flushDeferred: false}) {
  if (warnings == null) warnings = [];
  if (warnings is! List) warnings = [warnings];
  if (errors == null) errors = [];
  if (errors is! List) errors = [errors];

  compiler.diagnosticHandler = createHandler(compiler, text);

  Token tokens = scan(text);
  NodeListener listener =
      new NodeListener(const ScannerOptions(), compiler.reporter, null);
  Parser parser = new Parser(listener);
  parser.parseStatementOpt(parser.syntheticPreviousToken(tokens));
  Node node = listener.popNode();
  Element compilationUnit = new CompilationUnitElementX(
      new Script(null, null, null), compiler.mainApp);
  Element function = new MockElement(compilationUnit);
  TreeElements elements = compiler.resolveNodeStatement(node, function);
  compiler.enqueuer.resolution.emptyDeferredQueueForTesting();
  TypeCheckerVisitor checker =
      new TypeCheckerVisitor(compiler, elements, compiler.resolution.types);
  DiagnosticCollector collector = compiler.diagnosticCollector;
  collector.clear();
  checker.analyze(node, mustHaveType: false);
  if (flushDeferred) {
    compiler.enqueuer.resolution.emptyDeferredQueueForTesting();
  }
  compareWarningKinds(text, warnings, collector.warnings);
  compareWarningKinds(text, errors, collector.errors);
  if (hints != null) compareWarningKinds(text, hints, collector.hints);
  if (infos != null) compareWarningKinds(text, infos, collector.infos);
  compiler.diagnosticHandler = null;
}

void generateOutput(MockCompiler compiler, String text) {
  for (CollectedMessage message in compiler.diagnosticCollector.warnings) {
    int begin = message.begin;
    int end = message.end;
    SourceFile sourceFile = new StringSourceFile.fromName('analysis', text);
    print(
        sourceFile.getLocationMessage(message.message.toString(), begin, end));
  }
}

analyzeIn(MockCompiler compiler, FunctionElement element, String text,
    {warnings, hints}) {
  if (warnings == null) warnings = [];
  if (warnings is! List) warnings = [warnings];
  if (hints == null) hints = [];
  if (hints is! List) hints = [hints];

  compiler.resolver.resolve(element);
  Token tokens = scan(text);
  NodeListener listener =
      new NodeListener(const ScannerOptions(), compiler.reporter, null);
  Parser parser = new Parser(listener)
    ..asyncState = element.asyncMarker.asyncParserState;
  parser.parseStatementOpt(tokens);
  Node node = listener.popNode();
  TreeElements elements = compiler.resolveNodeStatement(node, element);
  TypeCheckerVisitor checker =
      new TypeCheckerVisitor(compiler, elements, compiler.resolution.types);
  DiagnosticCollector collector = compiler.diagnosticCollector;
  collector.clear();
  checker.analyze(node, mustHaveType: false);
  generateOutput(compiler, text);
  compareWarningKinds(text, warnings, collector.warnings);
  compareWarningKinds(text, hints, collector.hints);
}
