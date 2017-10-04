// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.declaration_resolver_test;

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/declaration_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolver_test_case.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeclarationResolverMetadataTest);
    defineReflectiveTests(DeclarationResolverTest);
    defineReflectiveTests(StrongModeDeclarationResolverTest);
  });
}

CompilationUnit _cloneResolveUnit(CompilationUnit unit) {
  CompilationUnit clonedUnit = AstCloner.clone(unit);
  new DeclarationResolver().resolve(clonedUnit, unit.element);
  return clonedUnit;
}

SimpleIdentifier _findSimpleIdentifier(
    AstNode root, String code, String search) {
  return EngineTestCase.findNode(
      root, code, search, (n) => n is SimpleIdentifier);
}

@reflectiveTest
class DeclarationResolverMetadataTest extends ResolverTestCase {
  String code;
  CompilationUnit unit;
  CompilationUnit unit2;

  void checkMetadata(String search, {bool expectDifferent: false}) {
    NodeList<Annotation> metadata = _findMetadata(unit, search);
    NodeList<Annotation> metadata2 = _findMetadata(unit2, search);
    expect(metadata, isNotEmpty);
    for (int i = 0; i < metadata.length; i++) {
      Matcher expectation = same(metadata[i].elementAnnotation);
      if (expectDifferent) {
        expectation = isNot(expectation);
      }
      expect(metadata2[i].elementAnnotation, expectation);
    }
  }

  Future<Null> setupCode(String code) async {
    this.code = code;
    unit = await resolveSource(code + ' const a = null;');
    unit2 = _cloneResolveUnit(unit);
  }

  test_metadata_classDeclaration() async {
    await setupCode('@a class C {}');
    checkMetadata('C');
  }

  test_metadata_classTypeAlias() async {
    await setupCode('@a class C = D with E; class D {} class E {}');
    checkMetadata('C');
  }

  test_metadata_constructorDeclaration_named() async {
    await setupCode('class C { @a C.x(); }');
    checkMetadata('x');
  }

  test_metadata_constructorDeclaration_unnamed() async {
    await setupCode('class C { @a C(); }');
    checkMetadata('C()');
  }

  test_metadata_declaredIdentifier() async {
    await setupCode('f(x, y) { for (@a var x in y) {} }');
    checkMetadata('var', expectDifferent: true);
  }

  test_metadata_enumDeclaration() async {
    await setupCode('@a enum E { v }');
    checkMetadata('E');
  }

  test_metadata_exportDirective() async {
    addNamedSource('/foo.dart', 'class C {}');
    await setupCode('@a export "foo.dart";');
    checkMetadata('export');
  }

  test_metadata_exportDirective_resynthesized() async {
    CompilationUnit unit = await resolveSource(r'''
@a
export "dart:async";

@b
export "dart:math";

const a = null;
const b = null;
''');
    expect(unit.directives[0].metadata.single.name.name, 'a');
    expect(unit.directives[1].metadata.single.name.name, 'b');
    var unitElement = unit.element as CompilationUnitElementImpl;
    // Damage the unit element - as if "setAnnotations" were not called.
    // The ExportElement(s) still have the metadata, we should use it.
    unitElement.setAnnotations(unit.directives[0].offset, []);
    unitElement.setAnnotations(unit.directives[1].offset, []);
    expect(unitElement.library.exports[0].metadata, hasLength(1));
    expect(unitElement.library.exports[1].metadata, hasLength(1));
    // DeclarationResolver on the clone should succeed.
    CompilationUnit clonedUnit = AstCloner.clone(unit);
    new DeclarationResolver().resolve(clonedUnit, unit.element);
    expect(unit.directives[0].metadata.single.name.name, 'a');
    expect(unit.directives[1].metadata.single.name.name, 'b');
  }

  test_metadata_fieldDeclaration() async {
    await setupCode('class C { @a int x; }');
    checkMetadata('x');
  }

  test_metadata_fieldFormalParameter() async {
    await setupCode('class C { var x; C(@a this.x); }');
    checkMetadata('this');
  }

  test_metadata_fieldFormalParameter_withDefault() async {
    await setupCode('class C { var x; C([@a this.x = null]); }');
    checkMetadata('this');
  }

  test_metadata_functionDeclaration_function() async {
    await setupCode('@a f() {}');
    checkMetadata('f');
  }

  test_metadata_functionDeclaration_getter() async {
    await setupCode('@a get f() => null;');
    checkMetadata('f');
  }

  test_metadata_functionDeclaration_setter() async {
    await setupCode('@a set f(value) {}');
    checkMetadata('f');
  }

  test_metadata_functionTypeAlias() async {
    await setupCode('@a typedef F();');
    checkMetadata('F');
  }

  test_metadata_functionTypedFormalParameter() async {
    await setupCode('f(@a g()) {}');
    checkMetadata('g');
  }

  test_metadata_functionTypedFormalParameter_withDefault() async {
    await setupCode('f([@a g() = null]) {}');
    checkMetadata('g');
  }

  test_metadata_importDirective() async {
    addNamedSource('/foo.dart', 'class C {}');
    await setupCode('@a import "foo.dart";');
    checkMetadata('import');
  }

  test_metadata_importDirective_partiallyResolved() async {
    addNamedSource('/foo.dart', 'class C {}');
    this.code = 'const a = null; @a import "foo.dart";';
    Source source = addNamedSource('/test.dart', code);
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    analysisContext.computeResult(source, LIBRARY_ELEMENT1);
    unit = analysisContext.computeResult(target, RESOLVED_UNIT1);
    unit2 = _cloneResolveUnit(unit);
    checkMetadata('import');
  }

  test_metadata_importDirective_resynthesized() async {
    CompilationUnit unit = await resolveSource(r'''
@a
import "dart:async";

@b
import "dart:math";

const a = null;
const b = null;
''');
    expect(unit.directives[0].metadata.single.name.name, 'a');
    expect(unit.directives[1].metadata.single.name.name, 'b');
    var unitElement = unit.element as CompilationUnitElementImpl;
    // Damage the unit element - as if "setAnnotations" were not called.
    // The ImportElement(s) still have the metadata, we should use it.
    unitElement.setAnnotations(unit.directives[0].offset, []);
    unitElement.setAnnotations(unit.directives[1].offset, []);
    expect(unitElement.library.imports[0].metadata, hasLength(1));
    expect(unitElement.library.imports[1].metadata, hasLength(1));
    // DeclarationResolver on the clone should succeed.
    CompilationUnit clonedUnit = AstCloner.clone(unit);
    new DeclarationResolver().resolve(clonedUnit, unit.element);
    expect(unit.directives[0].metadata.single.name.name, 'a');
    expect(unit.directives[1].metadata.single.name.name, 'b');
  }

  test_metadata_libraryDirective() async {
    await setupCode('@a library L;');
    checkMetadata('L');
  }

  test_metadata_libraryDirective_resynthesized() async {
    CompilationUnit unit = await resolveSource('@a library L; const a = null;');
    expect(unit.directives.single.metadata.single.name.name, 'a');
    var unitElement = unit.element as CompilationUnitElementImpl;
    // Damage the unit element - as if "setAnnotations" were not called.
    // The LibraryElement still has the metadata, we should use it.
    unitElement.setAnnotations(unit.directives.single.offset, []);
    expect(unitElement.library.metadata, hasLength(1));
    // DeclarationResolver on the clone should succeed.
    CompilationUnit clonedUnit = AstCloner.clone(unit);
    new DeclarationResolver().resolve(clonedUnit, unit.element);
    expect(clonedUnit.directives.single.metadata.single.name.name, 'a');
  }

  test_metadata_localFunctionDeclaration() async {
    await setupCode('f() { @a g() {} }');
    // Note: metadata on local function declarations is ignored by the
    // analyzer.  TODO(paulberry): is this a bug?
    FunctionDeclaration node = EngineTestCase.findNode(
        unit, code, 'g', (AstNode n) => n is FunctionDeclaration);
    expect((node as FunctionDeclarationImpl).metadata, isEmpty);
  }

  test_metadata_localVariableDeclaration() async {
    await setupCode('f() { @a int x; }');
    checkMetadata('x', expectDifferent: true);
  }

  test_metadata_methodDeclaration_getter() async {
    await setupCode('class C { @a get m => null; }');
    checkMetadata('m');
  }

  test_metadata_methodDeclaration_method() async {
    await setupCode('class C { @a m() {} }');
    checkMetadata('m');
  }

  test_metadata_methodDeclaration_setter() async {
    await setupCode('class C { @a set m(value) {} }');
    checkMetadata('m');
  }

  test_metadata_partDirective() async {
    addNamedSource('/foo.dart', 'part of L;');
    await setupCode('library L; @a part "foo.dart";');
    checkMetadata('part');
  }

  test_metadata_partDirective_resynthesized() async {
    addNamedSource('/part_a.dart', 'part of L;');
    addNamedSource('/part_b.dart', 'part of L;');

    CompilationUnit unit = await resolveSource(r'''
library L;

@a
part "part_a.dart";

@b
part "part_b.dart";

const a = null;
const b = null;
''');
    expect(unit.directives[1].metadata.single.name.name, 'a');
    expect(unit.directives[2].metadata.single.name.name, 'b');
    var unitElement = unit.element as CompilationUnitElementImpl;
    // Damage the unit element - as if "setAnnotations" were not called.
    // The ImportElement(s) still have the metadata, we should use it.
    unitElement.setAnnotations(unit.directives[1].offset, []);
    unitElement.setAnnotations(unit.directives[2].offset, []);
    expect(unitElement.library.parts[0].metadata, hasLength(1));
    expect(unitElement.library.parts[1].metadata, hasLength(1));
    // DeclarationResolver on the clone should succeed.
    CompilationUnit clonedUnit = AstCloner.clone(unit);
    new DeclarationResolver().resolve(clonedUnit, unit.element);
    expect(unit.directives[1].metadata.single.name.name, 'a');
    expect(unit.directives[2].metadata.single.name.name, 'b');
  }

  test_metadata_simpleFormalParameter() async {
    await setupCode('f(@a x) {}) {}');
    checkMetadata('x');
  }

  test_metadata_simpleFormalParameter_withDefault() async {
    await setupCode('f([@a x = null]) {}');
    checkMetadata('x');
  }

  test_metadata_topLevelVariableDeclaration() async {
    await setupCode('@a int x;');
    checkMetadata('x');
  }

  test_metadata_typeParameter_ofClass() async {
    await setupCode('class C<@a T> {}');
    checkMetadata('T');
  }

  test_metadata_typeParameter_ofClassTypeAlias() async {
    await setupCode('class C<@a T> = D with E; class D {} class E {}');
    checkMetadata('T');
  }

  test_metadata_typeParameter_ofFunction() async {
    await setupCode('f<@a T>() {}');
    checkMetadata('T');
  }

  test_metadata_typeParameter_ofTypedef() async {
    await setupCode('typedef F<@a T>();');
    checkMetadata('T');
  }

  NodeList<Annotation> _findMetadata(CompilationUnit unit, String search) {
    AstNode node =
        EngineTestCase.findNode(unit, code, search, (AstNode _) => true);
    while (node != null) {
      if (node is AnnotatedNode && node.metadata.isNotEmpty) {
        return node.metadata;
      }
      if (node is NormalFormalParameter && node.metadata.isNotEmpty) {
        return node.metadata;
      }
      node = node.parent;
    }
    fail('Node not found');
    return null;
  }
}

@reflectiveTest
class DeclarationResolverTest extends ResolverTestCase {
  @override
  void setUp() {
    super.setUp();
  }

  test_closure_inside_catch_block() async {
    String code = '''
f() {
  try {
  } catch (e) {
    return () => null;
  }
}
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_closure_inside_labeled_statement() async {
    String code = '''
f(b) {
  foo: while (true) {
    if (b) {
      break foo;
    }
    return () => null;
  }
}
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_closure_inside_switch_case() async {
    String code = '''
void f(k, m) {
  switch (k) {
    case 0:
      m.forEach((key, value) {});
    break;
  }
}
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_closure_inside_switch_default() async {
    String code = '''
void f(k, m) {
  switch (k) {
    default:
      m.forEach((key, value) {});
    break;
  }
}
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_enumConstant_partiallyResolved() async {
    String code = r'''
enum Fruit {apple, pear}
''';
    Source source = addNamedSource('/test.dart', code);
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    analysisContext.computeResult(source, LIBRARY_ELEMENT1);
    CompilationUnit unit =
        analysisContext.computeResult(target, RESOLVED_UNIT1);
    _cloneResolveUnit(unit);
  }

  test_functionDeclaration_getter() async {
    String code = r'''
int get zzz => 42;
''';
    CompilationUnit unit = await resolveSource(code);
    PropertyAccessorElement getterElement =
        _findSimpleIdentifier(unit, code, 'zzz =>').staticElement;
    expect(getterElement.isGetter, isTrue);
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier getterName = _findSimpleIdentifier(unit2, code, 'zzz =>');
    expect(getterName.staticElement, same(getterElement));
  }

  test_functionDeclaration_setter() async {
    String code = r'''
void set zzz(_) {}
''';
    CompilationUnit unit = await resolveSource(code);
    PropertyAccessorElement setterElement =
        _findSimpleIdentifier(unit, code, 'zzz(_)').staticElement;
    expect(setterElement.isSetter, isTrue);
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier getterName = _findSimpleIdentifier(unit2, code, 'zzz(_)');
    expect(getterName.staticElement, same(setterElement));
  }

  test_genericFunction_asFunctionReturnType() async {
    String code = r'''
Function(int, String) f() => null;
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asGenericFunctionReturnType() async {
    String code = r'''
typedef F<T> = int Function(T t, S s) Function<S>(int);
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asMethodReturnType() async {
    String code = r'''
class C {
  Function(int, String) m() => null;
}
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asParameterReturnType() async {
    String code = r'''
f(Function(int, String) p) => null;
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asTopLevelVariableType() async {
    String code = r'''
int Function(int, String) v;
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asTypeArgument() async {
    String code = r'''
List<Function(int)> v;
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asTypeArgument_lessNodes() async {
    String code = r'''
Map<Function<int>> v;
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asTypeArgument_moreNodes() async {
    String code = r'''
List<Function<int>, Function<String>> v;
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asTypeArgument_noNodes() async {
    String code = r'''
List v;
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asTypeArgument_ofInitializer() async {
    String code = r'''
var v = <Function(int)>[];
''';
    CompilationUnit unit = await resolveSource(code);
    CompilationUnit newUnit = _cloneResolveUnit(unit);
    var v = newUnit.declarations[0] as TopLevelVariableDeclaration;
    var initializer = v.variables.variables[0].initializer as ListLiteral;
    expect(initializer.typeArguments.arguments[0].type, isNotNull);
  }

  test_genericFunction_invalid_missingParameterName() async {
    String code = r'''
typedef F = Function({int});
''';
    CompilationUnit unit = await resolveSource(code);
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_invalid_functionDeclaration_getter_inFunction() async {
    String code = r'''
var v = (() {
  main() {
    int get zzz => 42;
  }
});
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier getterName = _findSimpleIdentifier(unit2, code, 'zzz =>');
    // Local getters are not allowed, so a FunctionElement is created.
    expect(getterName.staticElement, new isInstanceOf<FunctionElement>());
  }

  test_invalid_functionDeclaration_setter_inFunction() async {
    String code = r'''
var v = (() {
  main() {
    set zzz(x) {}
  }
});
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier setterName = _findSimpleIdentifier(unit2, code, 'zzz(x)');
    // Local getters are not allowed, so a FunctionElement is created.
    expect(setterName.staticElement, new isInstanceOf<FunctionElement>());
  }

  test_visitExportDirective_notExistingSource() async {
    String code = r'''
export 'foo.dart';
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitExportDirective_unresolvedUri() async {
    String code = r'''
export 'package:foo/bar.dart';
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitFunctionExpression() async {
    String code = r'''
main(List<String> items) {
  items.forEach((item) {});
}
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitGenericTypeAlias_0() async {
    String code = r'''
typedef F<T> = Function<S>(List<S> list, Function<A>(A), T);
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitGenericTypeAlias_1() async {
    String code = r'''
typedef F = Function({int});
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitGenericTypeAlias_2() async {
    String code = r'''
typedef F = int;
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitImportDirective_notExistingSource() async {
    String code = r'''
import 'foo.dart';
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitImportDirective_unresolvedUri() async {
    String code = r'''
import 'package:foo/bar.dart';
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitMethodDeclaration_getter_duplicate() async {
    String code = r'''
class C {
  int get zzz => 1;
  String get zzz => null;
}
''';
    CompilationUnit unit = await resolveSource(code);
    PropertyAccessorElement firstElement =
        _findSimpleIdentifier(unit, code, 'zzz => 1').staticElement;
    PropertyAccessorElement secondElement =
        _findSimpleIdentifier(unit, code, 'zzz => null').staticElement;
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier firstName = _findSimpleIdentifier(unit2, code, 'zzz => 1');
    SimpleIdentifier secondName =
        _findSimpleIdentifier(unit2, code, 'zzz => null');
    expect(firstName.staticElement, same(firstElement));
    expect(secondName.staticElement, same(secondElement));
  }

  test_visitMethodDeclaration_getterSetter() async {
    String code = r'''
class C {
  int _field = 0;
  int get field => _field;
  void set field(value) {_field = value;}
}
''';
    CompilationUnit unit = await resolveSource(code);
    FieldElement getterElement =
        _findSimpleIdentifier(unit, code, 'field =').staticElement;
    PropertyAccessorElement setterElement =
        _findSimpleIdentifier(unit, code, 'field(').staticElement;
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier getterName = _findSimpleIdentifier(unit2, code, 'field =');
    SimpleIdentifier setterName = _findSimpleIdentifier(unit2, code, 'field(');
    expect(getterName.staticElement, same(getterElement));
    expect(setterName.staticElement, same(setterElement));
  }

  test_visitMethodDeclaration_method_duplicate() async {
    String code = r'''
class C {
  void zzz(x) {}
  void zzz(y) {}
}
''';
    CompilationUnit unit = await resolveSource(code);
    MethodElement firstElement =
        _findSimpleIdentifier(unit, code, 'zzz(x)').staticElement;
    MethodElement secondElement =
        _findSimpleIdentifier(unit, code, 'zzz(y)').staticElement;
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier firstName = _findSimpleIdentifier(unit2, code, 'zzz(x)');
    SimpleIdentifier secondName = _findSimpleIdentifier(unit2, code, 'zzz(y)');
    expect(firstName.staticElement, same(firstElement));
    expect(secondName.staticElement, same(secondElement));
  }

  test_visitMethodDeclaration_setter_duplicate() async {
    // https://github.com/dart-lang/sdk/issues/25601
    String code = r'''
class C {
  set zzz(x) {}
  set zzz(y) {}
}
''';
    CompilationUnit unit = await resolveSource(code);
    PropertyAccessorElement firstElement =
        _findSimpleIdentifier(unit, code, 'zzz(x)').staticElement;
    PropertyAccessorElement secondElement =
        _findSimpleIdentifier(unit, code, 'zzz(y)').staticElement;
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier firstName = _findSimpleIdentifier(unit2, code, 'zzz(x)');
    SimpleIdentifier secondName = _findSimpleIdentifier(unit2, code, 'zzz(y)');
    expect(firstName.staticElement, same(firstElement));
    expect(secondName.staticElement, same(secondElement));
  }

  test_visitMethodDeclaration_unaryMinus() async {
    String code = r'''
class C {
  C operator -() => null;
  C operator -(C other) => null;
}
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitPartDirective_notExistingSource() async {
    String code = r'''
part 'foo.bar';
''';
    CompilationUnit unit = await resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }
}

/**
 * Strong mode DeclarationResolver tests
 */
@reflectiveTest
class StrongModeDeclarationResolverTest extends ResolverTestCase {
  @override
  void setUp() {
    resetWith(options: new AnalysisOptionsImpl()..strongMode = true);
  }

  test_genericFunction_typeParameter() async {
    String code = r'''
/*=T*/ max/*<T>*/(/*=T*/ x, /*=T*/ y) => null;
''';
    CompilationUnit unit = await resolveSource(code);
    FunctionDeclaration node = _findSimpleIdentifier(unit, code, 'max').parent;
    TypeParameter t = node.functionExpression.typeParameters.typeParameters[0];

    FunctionElement element = node.name.staticElement;
    TypeParameterElement tElement = element.typeParameters[0];
    expect(tElement, isNotNull);
    expect(element.typeParameters.toString(), "[T]");
    expect(element.type.toString(), "<T>(T, T) → T");
    expect(t.element, same(tElement));

    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    node = _findSimpleIdentifier(unit2, code, 'max').parent;
    t = node.functionExpression.typeParameters.typeParameters[0];
    expect(t.element, same(tElement));
  }

  test_genericMethod_typeParameter() async {
    String code = r'''
class C {
  /*=T*/ max/*<T>*/(/*=T*/ x, /*=T*/ y) => null;
}
''';
    CompilationUnit unit = await resolveSource(code);
    MethodDeclaration node = _findSimpleIdentifier(unit, code, 'max').parent;
    TypeParameter t = node.typeParameters.typeParameters[0];

    MethodElement element = node.name.staticElement;
    TypeParameterElement tElement = element.typeParameters[0];
    expect(tElement, isNotNull);
    expect(element.typeParameters.toString(), "[T]");
    expect(element.type.toString(), "<T>(T, T) → T");
    expect(t.element, same(tElement));

    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    node = _findSimpleIdentifier(unit2, code, 'max').parent;
    t = node.typeParameters.typeParameters[0];
    expect(t.element, same(tElement));
  }
}
