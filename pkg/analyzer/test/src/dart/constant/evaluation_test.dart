// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.constant_test;

import 'dart:async';

import 'package:analyzer/context/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/resolver_test_case.dart';
import '../../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantValueComputerTest);
    defineReflectiveTests(ConstantVisitorTest);
    defineReflectiveTests(StrongConstantValueComputerTest);
  });
}

/**
 * Implementation of [ConstantEvaluationValidator] used during unit tests;
 * verifies that any nodes referenced during constant evaluation are present in
 * the dependency graph.
 */
class ConstantEvaluationValidator_ForTest
    implements ConstantEvaluationValidator {
  final InternalAnalysisContext context;
  ConstantValueComputer computer;
  ConstantEvaluationTarget _nodeBeingEvaluated;

  ConstantEvaluationValidator_ForTest(this.context);

  @override
  void beforeComputeValue(ConstantEvaluationTarget constant) {
    _nodeBeingEvaluated = constant;
  }

  @override
  void beforeGetConstantInitializers(ConstructorElement constructor) =>
      _checkPathTo(constructor);

  @override
  void beforeGetEvaluationResult(ConstantEvaluationTarget constant) =>
      _checkPathTo(constant);

  @override
  void beforeGetFieldEvaluationResult(FieldElementImpl field) =>
      _checkPathTo(field);

  @override
  void beforeGetParameterDefault(ParameterElement parameter) =>
      _checkPathTo(parameter);

  void _checkPathTo(ConstantEvaluationTarget target) {
    if (computer.referenceGraph.containsPath(_nodeBeingEvaluated, target)) {
      return; // pass
    }
    // print a nice error message on failure
    StringBuffer out = new StringBuffer();
    out.writeln("missing path in constant dependency graph");
    out.writeln("from $_nodeBeingEvaluated to $target");
    for (var s in context.analysisCache.sources) {
      String text = context.getContents(s).data;
      if (text != "") {
        out.writeln('''
=== ${s.shortName}
$text''');
      }
    }
    fail(out.toString());
  }
}

@reflectiveTest
class ConstantValueComputerTest extends ResolverTestCase {
  test_annotation_constConstructor() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
class A {
  final int i;
  const A(this.i);
}

class C {
  @A(5)
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    Map<String, DartObjectImpl> annotationFields = _assertType(result, 'A');
    _assertIntField(annotationFields, 'i', 5);
  }

  test_annotation_constConstructor_named() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
class A {
  final int i;
  const A.named(this.i);
}

class C {
  @A.named(5)
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    Map<String, DartObjectImpl> annotationFields = _assertType(result, 'A');
    _assertIntField(annotationFields, 'i', 5);
  }

  test_annotation_constConstructor_noArgs() async {
    // Failing to pass arguments to an annotation which is a constant
    // constructor is illegal, but shouldn't crash analysis.
    CompilationUnit compilationUnit = await resolveSource(r'''
class A {
  final int i;
  const A(this.i);
}

class C {
  @A
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  test_annotation_constConstructor_noArgs_named() async {
    // Failing to pass arguments to an annotation which is a constant
    // constructor is illegal, but shouldn't crash analysis.
    CompilationUnit compilationUnit = await resolveSource(r'''
class A {
  final int i;
  const A.named(this.i);
}

class C {
  @A.named
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  test_annotation_nonConstConstructor() async {
    // Calling a non-const constructor from an annotation that is illegal, but
    // shouldn't crash analysis.
    CompilationUnit compilationUnit = await resolveSource(r'''
class A {
  final int i;
  A(this.i);
}

class C {
  @A(5)
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  test_annotation_staticConst() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
class C {
  static const int i = 5;

  @i
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    expect(_assertValidInt(result), 5);
  }

  test_annotation_staticConst_args() async {
    // Applying arguments to an annotation that is a static const is
    // illegal, but shouldn't crash analysis.
    CompilationUnit compilationUnit = await resolveSource(r'''
class C {
  static const int i = 5;

  @i(1)
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  test_annotation_staticConst_otherClass() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
class A {
  static const int i = 5;
}

class C {
  @A.i
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    expect(_assertValidInt(result), 5);
  }

  test_annotation_staticConst_otherClass_args() async {
    // Applying arguments to an annotation that is a static const is
    // illegal, but shouldn't crash analysis.
    CompilationUnit compilationUnit = await resolveSource(r'''
class A {
  static const int i = 5;
}

class C {
  @A.i(1)
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  test_annotation_topLevelVariable() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const int i = 5;
class C {
  @i
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    expect(_assertValidInt(result), 5);
  }

  test_annotation_topLevelVariable_args() async {
    // Applying arguments to an annotation that is a top-level variable is
    // illegal, but shouldn't crash analysis.
    CompilationUnit compilationUnit = await resolveSource(r'''
const int i = 5;
class C {
  @i(1)
  f() {}
}
''');
    _evaluateAnnotation(compilationUnit, "C", "f");
  }

  test_computeValues_cycle() async {
    TestLogger logger = new TestLogger();
    AnalysisEngine.instance.logger = logger;
    try {
      Source source = addSource(r'''
  const int a = c;
  const int b = a;
  const int c = b;''');
      LibraryElement libraryElement = resolve2(source);
      CompilationUnit unit =
          analysisContext.resolveCompilationUnit(source, libraryElement);
      analysisContext.computeErrors(source);
      expect(unit, isNotNull);
      ConstantValueComputer computer = _makeConstantValueComputer();
      computer.add(unit);
      computer.computeValues();
      NodeList<CompilationUnitMember> members = unit.declarations;
      expect(members, hasLength(3));
      _validate(false, (members[0] as TopLevelVariableDeclaration).variables);
      _validate(false, (members[1] as TopLevelVariableDeclaration).variables);
      _validate(false, (members[2] as TopLevelVariableDeclaration).variables);
    } finally {
      AnalysisEngine.instance.logger = Logger.NULL;
    }
  }

  test_computeValues_dependentVariables() async {
    Source source = addSource(r'''
const int b = a;
const int a = 0;''');
    LibraryElement libraryElement = resolve2(source);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(source, libraryElement);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit);
    computer.computeValues();
    NodeList<CompilationUnitMember> members = unit.declarations;
    expect(members, hasLength(2));
    _validate(true, (members[0] as TopLevelVariableDeclaration).variables);
    _validate(true, (members[1] as TopLevelVariableDeclaration).variables);
  }

  test_computeValues_empty() async {
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.computeValues();
  }

  test_computeValues_multipleSources() async {
    Source librarySource = addNamedSource(
        "/lib.dart",
        r'''
library lib;
part 'part.dart';
const int c = b;
const int a = 0;''');
    Source partSource = addNamedSource(
        "/part.dart",
        r'''
part of lib;
const int b = a;
const int d = c;''');
    LibraryElement libraryElement = resolve2(librarySource);
    CompilationUnit libraryUnit =
        analysisContext.resolveCompilationUnit(librarySource, libraryElement);
    expect(libraryUnit, isNotNull);
    CompilationUnit partUnit =
        analysisContext.resolveCompilationUnit(partSource, libraryElement);
    expect(partUnit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(libraryUnit);
    computer.add(partUnit);
    computer.computeValues();
    NodeList<CompilationUnitMember> libraryMembers = libraryUnit.declarations;
    expect(libraryMembers, hasLength(2));
    _validate(
        true, (libraryMembers[0] as TopLevelVariableDeclaration).variables);
    _validate(
        true, (libraryMembers[1] as TopLevelVariableDeclaration).variables);
    NodeList<CompilationUnitMember> partMembers = libraryUnit.declarations;
    expect(partMembers, hasLength(2));
    _validate(true, (partMembers[0] as TopLevelVariableDeclaration).variables);
    _validate(true, (partMembers[1] as TopLevelVariableDeclaration).variables);
  }

  test_computeValues_singleVariable() async {
    Source source = addSource("const int a = 0;");
    LibraryElement libraryElement = resolve2(source);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(source, libraryElement);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit);
    computer.computeValues();
    NodeList<CompilationUnitMember> members = unit.declarations;
    expect(members, hasLength(1));
    _validate(true, (members[0] as TopLevelVariableDeclaration).variables);
  }

  test_computeValues_value_depends_on_enum() async {
    Source source = addSource('''
enum E { id0, id1 }
const E e = E.id0;
''');
    LibraryElement libraryElement = resolve2(source);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(source, libraryElement);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit);
    computer.computeValues();
    TopLevelVariableDeclaration declaration = unit.declarations
        .firstWhere((member) => member is TopLevelVariableDeclaration);
    _validate(true, declaration.variables);
  }

  test_dependencyOnConstructor() async {
    // x depends on "const A()"
    await _assertProperDependencies(r'''
class A {
  const A();
}
const x = const A();''');
  }

  test_dependencyOnConstructorArgument() async {
    // "const A(x)" depends on x
    await _assertProperDependencies(r'''
class A {
  const A(this.next);
  final A next;
}
const A x = const A(null);
const A y = const A(x);''');
  }

  test_dependencyOnConstructorArgument_unresolvedConstructor() async {
    // "const A.a(x)" depends on x even if the constructor A.a can't be found.
    await _assertProperDependencies(
        r'''
class A {
}
const int x = 1;
const A y = const A.a(x);''',
        [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR]);
  }

  test_dependencyOnConstructorInitializer() async {
    // "const A()" depends on x
    await _assertProperDependencies(r'''
const int x = 1;
class A {
  const A() : v = x;
  final int v;
}''');
  }

  test_dependencyOnExplicitSuperConstructor() async {
    // b depends on B() depends on A()
    await _assertProperDependencies(r'''
class A {
  const A(this.x);
  final int x;
}
class B extends A {
  const B() : super(5);
}
const B b = const B();''');
  }

  test_dependencyOnExplicitSuperConstructorParameters() async {
    // b depends on B() depends on i
    await _assertProperDependencies(r'''
class A {
  const A(this.x);
  final int x;
}
class B extends A {
  const B() : super(i);
}
const B b = const B();
const int i = 5;''');
  }

  test_dependencyOnFactoryRedirect() async {
    // a depends on A.foo() depends on A.bar()
    await _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  factory const A.foo() = A.bar;
  const A.bar();
}''');
  }

  test_dependencyOnFactoryRedirectWithTypeParams() async {
    await _assertProperDependencies(r'''
class A {
  const factory A(var a) = B<int>;
}

class B<T> implements A {
  final T x;
  const B(this.x);
}

const A a = const A(10);''');
  }

  test_dependencyOnImplicitSuperConstructor() async {
    // b depends on B() depends on A()
    await _assertProperDependencies(r'''
class A {
  const A() : x = 5;
  final int x;
}
class B extends A {
  const B();
}
const B b = const B();''');
  }

  test_dependencyOnInitializedFinal() async {
    // a depends on A() depends on A.x
    await _assertProperDependencies('''
class A {
  const A();
  final int x = 1;
}
const A a = const A();
''');
  }

  test_dependencyOnInitializedNonStaticConst() async {
    // Even though non-static consts are not allowed by the language, we need
    // to handle them for error recovery purposes.
    // a depends on A() depends on A.x
    await _assertProperDependencies(
        '''
class A {
  const A();
  const int x = 1;
}
const A a = const A();
''',
        [CompileTimeErrorCode.CONST_INSTANCE_FIELD]);
  }

  test_dependencyOnNonFactoryRedirect() async {
    // a depends on A.foo() depends on A.bar()
    await _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  const A.foo() : this.bar();
  const A.bar();
}''');
  }

  test_dependencyOnNonFactoryRedirect_arg() async {
    // a depends on A.foo() depends on b
    await _assertProperDependencies(r'''
const A a = const A.foo();
const int b = 1;
class A {
  const A.foo() : this.bar(b);
  const A.bar(x) : y = x;
  final int y;
}''');
  }

  test_dependencyOnNonFactoryRedirect_defaultValue() async {
    // a depends on A.foo() depends on A.bar() depends on b
    await _assertProperDependencies(r'''
const A a = const A.foo();
const int b = 1;
class A {
  const A.foo() : this.bar();
  const A.bar([x = b]) : y = x;
  final int y;
}''');
  }

  test_dependencyOnNonFactoryRedirect_toMissing() async {
    // a depends on A.foo() which depends on nothing, since A.bar() is
    // missing.
    await _assertProperDependencies(
        r'''
const A a = const A.foo();
class A {
  const A.foo() : this.bar();
}''',
        [CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR]);
  }

  test_dependencyOnNonFactoryRedirect_toNonConst() async {
    // a depends on A.foo() which depends on nothing, since A.bar() is
    // non-const.
    await _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  const A.foo() : this.bar();
  A.bar();
}''');
  }

  test_dependencyOnNonFactoryRedirect_unnamed() async {
    // a depends on A.foo() depends on A()
    await _assertProperDependencies(r'''
const A a = const A.foo();
class A {
  const A.foo() : this();
  const A();
}''');
  }

  test_dependencyOnOptionalParameterDefault() async {
    // a depends on A() depends on B()
    await _assertProperDependencies(r'''
class A {
  const A([x = const B()]) : b = x;
  final B b;
}
class B {
  const B();
}
const A a = const A();''');
  }

  test_dependencyOnVariable() async {
    // x depends on y
    await _assertProperDependencies(r'''
const x = y + 1;
const y = 2;''');
  }

  test_final_initialized_at_declaration() async {
    CompilationUnit compilationUnit = await resolveSource('''
class A {
  final int i = 123;
  const A();
}

const A a = const A();
''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, 'a');
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "i", 123);
  }

  test_fromEnvironment_bool_default_false() async {
    expect(_assertValidBool(await _check_fromEnvironment_bool(null, "false")),
        false);
  }

  test_fromEnvironment_bool_default_overridden() async {
    expect(_assertValidBool(await _check_fromEnvironment_bool("false", "true")),
        false);
  }

  test_fromEnvironment_bool_default_parseError() async {
    expect(
        _assertValidBool(
            await _check_fromEnvironment_bool("parseError", "true")),
        true);
  }

  test_fromEnvironment_bool_default_true() async {
    expect(_assertValidBool(await _check_fromEnvironment_bool(null, "true")),
        true);
  }

  test_fromEnvironment_bool_false() async {
    expect(_assertValidBool(await _check_fromEnvironment_bool("false", null)),
        false);
  }

  test_fromEnvironment_bool_parseError() async {
    expect(
        _assertValidBool(await _check_fromEnvironment_bool("parseError", null)),
        false);
  }

  test_fromEnvironment_bool_true() async {
    expect(_assertValidBool(await _check_fromEnvironment_bool("true", null)),
        true);
  }

  test_fromEnvironment_bool_undeclared() async {
    _assertValidUnknown(await _check_fromEnvironment_bool(null, null));
  }

  test_fromEnvironment_int_default_overridden() async {
    expect(
        _assertValidInt(await _check_fromEnvironment_int("234", "123")), 234);
  }

  test_fromEnvironment_int_default_parseError() async {
    expect(
        _assertValidInt(await _check_fromEnvironment_int("parseError", "123")),
        123);
  }

  test_fromEnvironment_int_default_undeclared() async {
    expect(_assertValidInt(await _check_fromEnvironment_int(null, "123")), 123);
  }

  test_fromEnvironment_int_ok() async {
    expect(_assertValidInt(await _check_fromEnvironment_int("234", null)), 234);
  }

  test_fromEnvironment_int_parseError() async {
    _assertValidNull(await _check_fromEnvironment_int("parseError", null));
  }

  test_fromEnvironment_int_parseError_nullDefault() async {
    _assertValidNull(await _check_fromEnvironment_int("parseError", "null"));
  }

  test_fromEnvironment_int_undeclared() async {
    _assertValidUnknown(await _check_fromEnvironment_int(null, null));
  }

  test_fromEnvironment_int_undeclared_nullDefault() async {
    _assertValidNull(await _check_fromEnvironment_int(null, "null"));
  }

  test_fromEnvironment_string_default_overridden() async {
    expect(
        _assertValidString(await _check_fromEnvironment_string("abc", "'def'")),
        "abc");
  }

  test_fromEnvironment_string_default_undeclared() async {
    expect(
        _assertValidString(await _check_fromEnvironment_string(null, "'def'")),
        "def");
  }

  test_fromEnvironment_string_empty() async {
    expect(
        _assertValidString(await _check_fromEnvironment_string("", null)), "");
  }

  test_fromEnvironment_string_ok() async {
    expect(_assertValidString(await _check_fromEnvironment_string("abc", null)),
        "abc");
  }

  test_fromEnvironment_string_undeclared() async {
    _assertValidUnknown(await _check_fromEnvironment_string(null, null));
  }

  test_fromEnvironment_string_undeclared_nullDefault() async {
    _assertValidNull(await _check_fromEnvironment_string(null, "null"));
  }

  test_getConstructor_redirectingFactory() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
class A {
  factory const A() = B;
}

class B implements A {
  const B();
}

class C {
  @A()
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    expect(result.value.getInvocation().constructor.isFactory, isTrue);
  }

  test_getConstructor_withArgs() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
class A {
  final int i;
  const A(this.i);
}

class C {
  @A(5)
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    ConstructorInvocation invocation = result.value.getInvocation();
    expect(invocation.constructor, isNotNull);
    expect(invocation.positionalArguments, hasLength(1));
    expect(invocation.positionalArguments.single.toIntValue(), 5);
    expect(invocation.namedArguments, isEmpty);
  }

  test_getConstructor_withNamedArgs() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
class A {
  final int i;
  const A({this.i});
}

class C {
  @A(i: 5)
  f() {}
}
''');
    EvaluationResultImpl result =
        _evaluateAnnotation(compilationUnit, "C", "f");
    ConstructorInvocation invocation = result.value.getInvocation();
    expect(invocation.constructor, isNotNull);
    expect(invocation.positionalArguments, isEmpty);
    expect(invocation.namedArguments, isNotEmpty);
    expect(invocation.namedArguments['i'].toIntValue(), 5);
  }

  test_instanceCreationExpression_computedField() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A(4, 5);
class A {
  const A(int i, int j) : k = 2 * i + j;
  final int k;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "k", 13);
  }

  test_instanceCreationExpression_computedField_namedOptionalWithDefault() async {
    await _checkInstanceCreationOptionalParams(false, true, true);
  }

  test_instanceCreationExpression_computedField_namedOptionalWithoutDefault() async {
    await _checkInstanceCreationOptionalParams(false, true, false);
  }

  test_instanceCreationExpression_computedField_unnamedOptionalWithDefault() async {
    await _checkInstanceCreationOptionalParams(false, false, true);
  }

  test_instanceCreationExpression_computedField_unnamedOptionalWithoutDefault() async {
    await _checkInstanceCreationOptionalParams(false, false, false);
  }

  test_instanceCreationExpression_computedField_usesConstConstructor() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A(3);
class A {
  const A(int i) : b = const B(4);
  final int b;
}
class B {
  const B(this.k);
  final int k;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fieldsOfA = _assertType(result, "A");
    expect(fieldsOfA, hasLength(1));
    Map<String, DartObjectImpl> fieldsOfB =
        _assertFieldType(fieldsOfA, "b", "B");
    expect(fieldsOfB, hasLength(1));
    _assertIntField(fieldsOfB, "k", 4);
  }

  test_instanceCreationExpression_computedField_usesStaticConst() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A(3);
class A {
  const A(int i) : k = i + B.bar;
  final int k;
}
class B {
  static const bar = 4;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "k", 7);
  }

  test_instanceCreationExpression_computedField_usesTopLevelConst() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A(3);
const bar = 4;
class A {
  const A(int i) : k = i + bar;
  final int k;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "k", 7);
  }

  test_instanceCreationExpression_explicitSuper() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const B(4, 5);
class A {
  const A(this.x);
  final int x;
}
class B extends A {
  const B(int x, this.y) : super(x * 2);
  final int y;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "B");
    expect(fields, hasLength(2));
    _assertIntField(fields, "y", 5);
    Map<String, DartObjectImpl> superclassFields =
        _assertFieldType(fields, GenericState.SUPERCLASS_FIELD, "A");
    expect(superclassFields, hasLength(1));
    _assertIntField(superclassFields, "x", 8);
  }

  test_instanceCreationExpression_fieldFormalParameter() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A(42);
class A {
  int x;
  const A(this.x)
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "x", 42);
  }

  test_instanceCreationExpression_fieldFormalParameter_namedOptionalWithDefault() async {
    await _checkInstanceCreationOptionalParams(true, true, true);
  }

  test_instanceCreationExpression_fieldFormalParameter_namedOptionalWithoutDefault() async {
    await _checkInstanceCreationOptionalParams(true, true, false);
  }

  test_instanceCreationExpression_fieldFormalParameter_unnamedOptionalWithDefault() async {
    await _checkInstanceCreationOptionalParams(true, false, true);
  }

  test_instanceCreationExpression_fieldFormalParameter_unnamedOptionalWithoutDefault() async {
    await _checkInstanceCreationOptionalParams(true, false, false);
  }

  test_instanceCreationExpression_implicitSuper() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const B(4);
class A {
  const A() : x = 3;
  final int x;
}
class B extends A {
  const B(this.y);
  final int y;
}''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    Map<String, DartObjectImpl> fields = _assertType(result, "B");
    expect(fields, hasLength(2));
    _assertIntField(fields, "y", 4);
    Map<String, DartObjectImpl> superclassFields =
        _assertFieldType(fields, GenericState.SUPERCLASS_FIELD, "A");
    expect(superclassFields, hasLength(1));
    _assertIntField(superclassFields, "x", 3);
  }

  test_instanceCreationExpression_nonFactoryRedirect() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this.a2();
  const A.a2() : x = 5;
  final int x;
}''');
    Map<String, DartObjectImpl> aFields =
        _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
    _assertIntField(aFields, 'x', 5);
  }

  test_instanceCreationExpression_nonFactoryRedirect_arg() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A.a1(1);
class A {
  const A.a1(x) : this.a2(x + 100);
  const A.a2(x) : y = x + 10;
  final int y;
}''');
    Map<String, DartObjectImpl> aFields =
        _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
    _assertIntField(aFields, 'y', 111);
  }

  test_instanceCreationExpression_nonFactoryRedirect_cycle() async {
    // It is an error to have a cycle in non-factory redirects; however, we
    // need to make sure that even if the error occurs, attempting to evaluate
    // the constant will terminate.
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A();
class A {
  const A() : this.b();
  const A.b() : this();
}''');
    _assertValidUnknown(_evaluateTopLevelVariable(compilationUnit, "foo"));
  }

  test_instanceCreationExpression_nonFactoryRedirect_defaultArg() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this.a2();
  const A.a2([x = 100]) : y = x + 10;
  final int y;
}''');
    Map<String, DartObjectImpl> aFields =
        _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
    _assertIntField(aFields, 'y', 110);
  }

  test_instanceCreationExpression_nonFactoryRedirect_toMissing() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this.a2();
}''');
    // We don't care what value foo evaluates to (since there is a compile
    // error), but we shouldn't crash, and we should figure
    // out that it evaluates to an instance of class A.
    _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
  }

  test_instanceCreationExpression_nonFactoryRedirect_toNonConst() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this.a2();
  A.a2();
}''');
    // We don't care what value foo evaluates to (since there is a compile
    // error), but we shouldn't crash, and we should figure
    // out that it evaluates to an instance of class A.
    _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
  }

  test_instanceCreationExpression_nonFactoryRedirect_unnamed() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A.a1();
class A {
  const A.a1() : this();
  const A() : x = 5;
  final int x;
}''');
    Map<String, DartObjectImpl> aFields =
        _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "A");
    _assertIntField(aFields, 'x', 5);
  }

  test_instanceCreationExpression_redirect() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A();
class A {
  const factory A() = B;
}
class B implements A {
  const B();
}''');
    _assertType(_evaluateTopLevelVariable(compilationUnit, "foo"), "B");
  }

  test_instanceCreationExpression_redirect_cycle() async {
    // It is an error to have a cycle in factory redirects; however, we need
    // to make sure that even if the error occurs, attempting to evaluate the
    // constant will terminate.
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A();
class A {
  const factory A() = A.b;
  const factory A.b() = A;
}''');
    _assertValidUnknown(_evaluateTopLevelVariable(compilationUnit, "foo"));
  }

  test_instanceCreationExpression_redirect_external() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A();
class A {
  external const factory A();
}''');
    _assertValidUnknown(_evaluateTopLevelVariable(compilationUnit, "foo"));
  }

  test_instanceCreationExpression_redirect_generic() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A<int>();
class A<T> {
  const A() : this._();
  const A._();
}
''');
    _assertType(_evaluateTopLevelVariable(compilationUnit, 'foo'), 'A<int>');
  }

  test_instanceCreationExpression_redirect_nonConst() async {
    // It is an error for a const factory constructor redirect to a non-const
    // constructor; however, we need to make sure that even if the error
    // attempting to evaluate the constant won't cause a crash.
    CompilationUnit compilationUnit = await resolveSource(r'''
const foo = const A();
class A {
  const factory A() = A.b;
  A.b();
}''');
    _assertValidUnknown(_evaluateTopLevelVariable(compilationUnit, "foo"));
  }

  test_instanceCreationExpression_redirectWithTypeParams() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
class A {
  const factory A(var a) = B<int>;
}

class B<T> implements A {
  final T x;
  const B(this.x);
}

const A a = const A(10);''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "a");
    Map<String, DartObjectImpl> fields = _assertType(result, "B<int>");
    expect(fields, hasLength(1));
    _assertIntField(fields, "x", 10);
  }

  test_instanceCreationExpression_redirectWithTypeSubstitution() async {
    // To evaluate the redirection of A<int>,
    // A's template argument (T=int) must be substituted
    // into B's template argument (B<U> where U=T) to get B<int>.
    CompilationUnit compilationUnit = await resolveSource(r'''
class A<T> {
  const factory A(var a) = B<T>;
}

class B<U> implements A {
  final U x;
  const B(this.x);
}

const A<int> a = const A<int>(10);''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, "a");
    Map<String, DartObjectImpl> fields = _assertType(result, "B<int>");
    expect(fields, hasLength(1));
    _assertIntField(fields, "x", 10);
  }

  test_instanceCreationExpression_symbol() async {
    CompilationUnit compilationUnit =
        await resolveSource("const foo = const Symbol('a');");
    EvaluationResultImpl evaluationResult =
        _evaluateTopLevelVariable(compilationUnit, "foo");
    expect(evaluationResult.value, isNotNull);
    DartObjectImpl value = evaluationResult.value;
    expect(value.type, typeProvider.symbolType);
    expect(value.toSymbolValue(), "a");
  }

  test_instanceCreationExpression_withSupertypeParams_explicit() async {
    await _checkInstanceCreation_withSupertypeParams(true);
  }

  test_instanceCreationExpression_withSupertypeParams_implicit() async {
    await _checkInstanceCreation_withSupertypeParams(false);
  }

  test_instanceCreationExpression_withTypeParams() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
class C<E> {
  const C();
}
const c_int = const C<int>();
const c_num = const C<num>();''');
    EvaluationResultImpl c_int =
        _evaluateTopLevelVariable(compilationUnit, "c_int");
    _assertType(c_int, "C<int>");
    DartObjectImpl c_int_value = c_int.value;
    EvaluationResultImpl c_num =
        _evaluateTopLevelVariable(compilationUnit, "c_num");
    _assertType(c_num, "C<num>");
    DartObjectImpl c_num_value = c_num.value;
    expect(c_int_value == c_num_value, isFalse);
  }

  test_isValidSymbol() async {
    expect(ConstantEvaluationEngine.isValidPublicSymbol(""), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo.bar"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo\$"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo\$bar"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("iff"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("gif"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("if\$"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("\$if"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo="), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo.bar="), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo.+"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("void"), isTrue);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("_foo"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("_foo.bar"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo._bar"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("if"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("if.foo"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo.if"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo=.bar"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo."), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("+.foo"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("void.foo"), isFalse);
    expect(ConstantEvaluationEngine.isValidPublicSymbol("foo.void"), isFalse);
  }

  test_length_of_improperly_typed_string_expression() async {
    // Since type annotations are ignored in unchecked mode, the improper
    // types on s1 and s2 shouldn't prevent us from evaluating i to
    // 'alpha'.length.
    CompilationUnit compilationUnit = await resolveSource('''
const int s1 = 'alpha';
const int s2 = 'beta';
const int i = (true ? s1 : s2).length;
''');
    ConstTopLevelVariableElementImpl element =
        findTopLevelDeclaration(compilationUnit, 'i').element;
    EvaluationResultImpl result = element.evaluationResult;
    expect(_assertValidInt(result), 5);
  }

  test_length_of_improperly_typed_string_identifier() async {
    // Since type annotations are ignored in unchecked mode, the improper type
    // on s shouldn't prevent us from evaluating i to 'alpha'.length.
    CompilationUnit compilationUnit = await resolveSource('''
const int s = 'alpha';
const int i = s.length;
''');
    ConstTopLevelVariableElementImpl element =
        findTopLevelDeclaration(compilationUnit, 'i').element;
    EvaluationResultImpl result = element.evaluationResult;
    expect(_assertValidInt(result), 5);
  }

  test_non_static_const_initialized_at_declaration() async {
    // Even though non-static consts are not allowed by the language, we need
    // to handle them for error recovery purposes.
    CompilationUnit compilationUnit = await resolveSource('''
class A {
  const int i = 123;
  const A();
}

const A a = const A();
''');
    EvaluationResultImpl result =
        _evaluateTopLevelVariable(compilationUnit, 'a');
    Map<String, DartObjectImpl> fields = _assertType(result, "A");
    expect(fields, hasLength(1));
    _assertIntField(fields, "i", 123);
  }

  test_symbolLiteral_void() async {
    CompilationUnit compilationUnit =
        await resolveSource("const voidSymbol = #void;");
    VariableDeclaration voidSymbol =
        findTopLevelDeclaration(compilationUnit, "voidSymbol");
    EvaluationResultImpl voidSymbolResult =
        (voidSymbol.element as VariableElementImpl).evaluationResult;
    DartObjectImpl value = voidSymbolResult.value;
    expect(value.type, typeProvider.symbolType);
    expect(value.toSymbolValue(), "void");
  }

  Map<String, DartObjectImpl> _assertFieldType(
      Map<String, DartObjectImpl> fields,
      String fieldName,
      String expectedType) {
    DartObjectImpl field = fields[fieldName];
    expect(field.type.displayName, expectedType);
    return field.fields;
  }

  void _assertIntField(
      Map<String, DartObjectImpl> fields, String fieldName, int expectedValue) {
    DartObjectImpl field = fields[fieldName];
    expect(field.type.name, "int");
    expect(field.toIntValue(), expectedValue);
  }

  void _assertNullField(Map<String, DartObjectImpl> fields, String fieldName) {
    DartObjectImpl field = fields[fieldName];
    expect(field.isNull, isTrue);
  }

  Future<Null> _assertProperDependencies(String sourceText,
      [List<ErrorCode> expectedErrorCodes = const <ErrorCode>[]]) async {
    Source source = addSource(sourceText);
    LibraryElement element = resolve2(source);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(source, element);
    expect(unit, isNotNull);
    ConstantValueComputer computer = _makeConstantValueComputer();
    computer.add(unit);
    computer.computeValues();
    await computeAnalysisResult(source);
    assertErrors(source, expectedErrorCodes);
  }

  Map<String, DartObjectImpl> _assertType(
      EvaluationResultImpl result, String typeName) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type.displayName, typeName);
    return value.fields;
  }

  bool _assertValidBool(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type, typeProvider.boolType);
    bool boolValue = value.toBoolValue();
    expect(boolValue, isNotNull);
    return boolValue;
  }

  int _assertValidInt(EvaluationResultImpl result) {
    expect(result, isNotNull);
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type, typeProvider.intType);
    return value.toIntValue();
  }

  void _assertValidNull(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type, typeProvider.nullType);
  }

  String _assertValidString(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.type, typeProvider.stringType);
    return value.toStringValue();
  }

  void _assertValidUnknown(EvaluationResultImpl result) {
    expect(result.value, isNotNull);
    DartObjectImpl value = result.value;
    expect(value.isUnknown, isTrue);
  }

  Future<EvaluationResultImpl> _check_fromEnvironment_bool(
      String valueInEnvironment, String defaultExpr) async {
    String envVarName = "x";
    String varName = "foo";
    if (valueInEnvironment != null) {
      if (enableNewAnalysisDriver) {
        driver.declaredVariables.define(envVarName, valueInEnvironment);
      } else {
        analysisContext2.declaredVariables
            .define(envVarName, valueInEnvironment);
      }
    }
    String defaultArg =
        defaultExpr == null ? "" : ", defaultValue: $defaultExpr";
    CompilationUnit compilationUnit = await resolveSource(
        "const $varName = const bool.fromEnvironment('$envVarName'$defaultArg);");
    return _evaluateTopLevelVariable(compilationUnit, varName);
  }

  Future<EvaluationResultImpl> _check_fromEnvironment_int(
      String valueInEnvironment, String defaultExpr) async {
    String envVarName = "x";
    String varName = "foo";
    if (valueInEnvironment != null) {
      if (enableNewAnalysisDriver) {
        driver.declaredVariables.define(envVarName, valueInEnvironment);
      } else {
        analysisContext2.declaredVariables
            .define(envVarName, valueInEnvironment);
      }
    }
    String defaultArg =
        defaultExpr == null ? "" : ", defaultValue: $defaultExpr";
    CompilationUnit compilationUnit = await resolveSource(
        "const $varName = const int.fromEnvironment('$envVarName'$defaultArg);");
    return _evaluateTopLevelVariable(compilationUnit, varName);
  }

  Future<EvaluationResultImpl> _check_fromEnvironment_string(
      String valueInEnvironment, String defaultExpr) async {
    String envVarName = "x";
    String varName = "foo";
    if (valueInEnvironment != null) {
      if (enableNewAnalysisDriver) {
        driver.declaredVariables.define(envVarName, valueInEnvironment);
      } else {
        analysisContext2.declaredVariables
            .define(envVarName, valueInEnvironment);
      }
    }
    String defaultArg =
        defaultExpr == null ? "" : ", defaultValue: $defaultExpr";
    CompilationUnit compilationUnit = await resolveSource(
        "const $varName = const String.fromEnvironment('$envVarName'$defaultArg);");
    return _evaluateTopLevelVariable(compilationUnit, varName);
  }

  Future<Null> _checkInstanceCreation_withSupertypeParams(
      bool isExplicit) async {
    String superCall = isExplicit ? " : super()" : "";
    CompilationUnit compilationUnit = await resolveSource("""
class A<T> {
  const A();
}
class B<T, U> extends A<T> {
  const B()$superCall;
}
class C<T, U> extends A<U> {
  const C()$superCall;
}
const b_int_num = const B<int, num>();
const c_int_num = const C<int, num>();""");
    EvaluationResultImpl b_int_num =
        _evaluateTopLevelVariable(compilationUnit, "b_int_num");
    Map<String, DartObjectImpl> b_int_num_fields =
        _assertType(b_int_num, "B<int, num>");
    _assertFieldType(b_int_num_fields, GenericState.SUPERCLASS_FIELD, "A<int>");
    EvaluationResultImpl c_int_num =
        _evaluateTopLevelVariable(compilationUnit, "c_int_num");
    Map<String, DartObjectImpl> c_int_num_fields =
        _assertType(c_int_num, "C<int, num>");
    _assertFieldType(c_int_num_fields, GenericState.SUPERCLASS_FIELD, "A<num>");
  }

  Future<Null> _checkInstanceCreationOptionalParams(
      bool isFieldFormal, bool isNamed, bool hasDefault) async {
    String fieldName = "j";
    String paramName = isFieldFormal ? fieldName : "i";
    String formalParam =
        "${isFieldFormal ? "this." : "int "}$paramName${hasDefault ? " = 3" : ""}";
    CompilationUnit compilationUnit = await resolveSource("""
const x = const A();
const y = const A(${isNamed ? '$paramName: ' : ''}10);
class A {
  const A(${isNamed ? "{$formalParam}" : "[$formalParam]"})${isFieldFormal ? "" : " : $fieldName = $paramName"};
  final int $fieldName;
}""");
    EvaluationResultImpl x = _evaluateTopLevelVariable(compilationUnit, "x");
    Map<String, DartObjectImpl> fieldsOfX = _assertType(x, "A");
    expect(fieldsOfX, hasLength(1));
    if (hasDefault) {
      _assertIntField(fieldsOfX, fieldName, 3);
    } else {
      _assertNullField(fieldsOfX, fieldName);
    }
    EvaluationResultImpl y = _evaluateTopLevelVariable(compilationUnit, "y");
    Map<String, DartObjectImpl> fieldsOfY = _assertType(y, "A");
    expect(fieldsOfY, hasLength(1));
    _assertIntField(fieldsOfY, fieldName, 10);
  }

  /**
   * Search [compilationUnit] for a class named [className], containing a
   * method [methodName], with exactly one annotation.  Return the constant
   * value of the annotation.
   */
  EvaluationResultImpl _evaluateAnnotation(
      CompilationUnit compilationUnit, String className, String memberName) {
    for (CompilationUnitMember member in compilationUnit.declarations) {
      if (member is ClassDeclaration && member.name.name == className) {
        for (ClassMember classMember in member.members) {
          if (classMember is MethodDeclaration &&
              classMember.name.name == memberName) {
            expect(classMember.metadata, hasLength(1));
            ElementAnnotationImpl elementAnnotation =
                classMember.metadata[0].elementAnnotation;
            return elementAnnotation.evaluationResult;
          }
        }
      }
    }
    fail('Class member not found');
    return null;
  }

  EvaluationResultImpl _evaluateTopLevelVariable(
      CompilationUnit compilationUnit, String name) {
    VariableDeclaration varDecl =
        findTopLevelDeclaration(compilationUnit, name);
    ConstTopLevelVariableElementImpl varElement = varDecl.element;
    return varElement.evaluationResult;
  }

  ConstantValueComputer _makeConstantValueComputer() {
    ConstantEvaluationValidator_ForTest validator =
        new ConstantEvaluationValidator_ForTest(analysisContext2);
    validator.computer = new ConstantValueComputer(
        analysisContext2.typeProvider,
        analysisContext2.declaredVariables,
        validator,
        analysisContext2.typeSystem);
    return validator.computer;
  }

  void _validate(bool shouldBeValid, VariableDeclarationList declarationList) {
    for (VariableDeclaration declaration in declarationList.variables) {
      VariableElementImpl element = declaration.element as VariableElementImpl;
      expect(element, isNotNull);
      EvaluationResultImpl result = element.evaluationResult;
      if (shouldBeValid) {
        expect(result.value, isNotNull);
      } else {
        expect(result.value, isNull);
      }
    }
  }
}

@reflectiveTest
class ConstantVisitorTest extends ResolverTestCase {
  test_visitBinaryExpression_questionQuestion_notNull_notNull() async {
    Expression left = AstTestFactory.string2('a');
    Expression right = AstTestFactory.string2('b');
    Expression expression = AstTestFactory.binaryExpression(
        left, TokenType.QUESTION_QUESTION, right);

    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNotNull);
    expect(result.isNull, isFalse);
    expect(result.toStringValue(), 'a');
    errorListener.assertNoErrors();
  }

  test_visitBinaryExpression_questionQuestion_null_notNull() async {
    Expression left = AstTestFactory.nullLiteral();
    Expression right = AstTestFactory.string2('b');
    Expression expression = AstTestFactory.binaryExpression(
        left, TokenType.QUESTION_QUESTION, right);

    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNotNull);
    expect(result.isNull, isFalse);
    expect(result.toStringValue(), 'b');
    errorListener.assertNoErrors();
  }

  test_visitBinaryExpression_questionQuestion_null_null() async {
    Expression left = AstTestFactory.nullLiteral();
    Expression right = AstTestFactory.nullLiteral();
    Expression expression = AstTestFactory.binaryExpression(
        left, TokenType.QUESTION_QUESTION, right);

    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNotNull);
    expect(result.isNull, isTrue);
    errorListener.assertNoErrors();
  }

  test_visitConditionalExpression_false() async {
    Expression thenExpression = AstTestFactory.integer(1);
    Expression elseExpression = AstTestFactory.integer(0);
    ConditionalExpression expression = AstTestFactory.conditionalExpression(
        AstTestFactory.booleanLiteral(false), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    _assertValue(0, _evaluate(expression, errorReporter));
    errorListener.assertNoErrors();
  }

  test_visitConditionalExpression_nonBooleanCondition() async {
    Expression thenExpression = AstTestFactory.integer(1);
    Expression elseExpression = AstTestFactory.integer(0);
    NullLiteral conditionExpression = AstTestFactory.nullLiteral();
    ConditionalExpression expression = AstTestFactory.conditionalExpression(
        conditionExpression, thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNull);
    errorListener
        .assertErrorsWithCodes([CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL]);
  }

  test_visitConditionalExpression_nonConstantElse() async {
    Expression thenExpression = AstTestFactory.integer(1);
    Expression elseExpression = AstTestFactory.identifier3("x");
    ConditionalExpression expression = AstTestFactory.conditionalExpression(
        AstTestFactory.booleanLiteral(true), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNull);
    errorListener
        .assertErrorsWithCodes([CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  test_visitConditionalExpression_nonConstantThen() async {
    Expression thenExpression = AstTestFactory.identifier3("x");
    Expression elseExpression = AstTestFactory.integer(0);
    ConditionalExpression expression = AstTestFactory.conditionalExpression(
        AstTestFactory.booleanLiteral(true), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNull);
    errorListener
        .assertErrorsWithCodes([CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  test_visitConditionalExpression_true() async {
    Expression thenExpression = AstTestFactory.integer(1);
    Expression elseExpression = AstTestFactory.integer(0);
    ConditionalExpression expression = AstTestFactory.conditionalExpression(
        AstTestFactory.booleanLiteral(true), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    _assertValue(1, _evaluate(expression, errorReporter));
    errorListener.assertNoErrors();
  }

  test_visitSimpleIdentifier_className() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = C;
class C {}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'a', null);
    expect(result.type, typeProvider.typeType);
    expect(result.toTypeValue().name, 'C');
  }

  test_visitSimpleIdentifier_dynamic() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = dynamic;
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'a', null);
    expect(result.type, typeProvider.typeType);
    expect(result.toTypeValue(), typeProvider.dynamicType);
  }

  test_visitSimpleIdentifier_inEnvironment() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const a = b;
const b = 3;''');
    Map<String, DartObjectImpl> environment = new Map<String, DartObjectImpl>();
    DartObjectImpl six =
        new DartObjectImpl(typeProvider.intType, new IntState(6));
    environment["b"] = six;
    _assertValue(6, _evaluateConstant(compilationUnit, "a", environment));
  }

  test_visitSimpleIdentifier_notInEnvironment() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const a = b;
const b = 3;''');
    Map<String, DartObjectImpl> environment = new Map<String, DartObjectImpl>();
    DartObjectImpl six =
        new DartObjectImpl(typeProvider.intType, new IntState(6));
    environment["c"] = six;
    _assertValue(3, _evaluateConstant(compilationUnit, "a", environment));
  }

  test_visitSimpleIdentifier_withoutEnvironment() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const a = b;
const b = 3;''');
    _assertValue(3, _evaluateConstant(compilationUnit, "a", null));
  }

  void _assertValue(int expectedValue, DartObjectImpl result) {
    expect(result, isNotNull);
    expect(result.type.name, "int");
    expect(result.toIntValue(), expectedValue);
  }

  NonExistingSource _dummySource() {
    String path = '/test.dart';
    return new NonExistingSource(path, toUri(path), UriKind.FILE_URI);
  }

  DartObjectImpl _evaluate(Expression expression, ErrorReporter errorReporter) {
    TestTypeProvider typeProvider = new TestTypeProvider();
    return expression.accept(new ConstantVisitor(
        new ConstantEvaluationEngine(typeProvider, new DeclaredVariables(),
            typeSystem: new TypeSystemImpl(typeProvider)),
        errorReporter));
  }

  DartObjectImpl _evaluateConstant(CompilationUnit compilationUnit, String name,
      Map<String, DartObjectImpl> lexicalEnvironment) {
    Source source =
        resolutionMap.elementDeclaredByCompilationUnit(compilationUnit).source;
    Expression expression =
        findTopLevelConstantExpression(compilationUnit, name);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter = new ErrorReporter(errorListener, source);
    DartObjectImpl result = expression.accept(new ConstantVisitor(
        new ConstantEvaluationEngine(typeProvider, new DeclaredVariables(),
            typeSystem: typeSystem),
        errorReporter,
        lexicalEnvironment: lexicalEnvironment));
    errorListener.assertNoErrors();
    return result;
  }
}

@reflectiveTest
class StrongConstantValueComputerTest extends ConstantValueComputerTest {
  void setUp() {
    super.setUp();
    resetWith(options: new AnalysisOptionsImpl()..strongMode = true);
  }
}
