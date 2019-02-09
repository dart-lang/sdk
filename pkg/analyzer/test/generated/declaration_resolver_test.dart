// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/declaration_resolver.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/driver_resolution.dart';
import '../util/element_type_matchers.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeclarationResolverMetadataTest);
    defineReflectiveTests(DeclarationResolverTest);
  });
}

CompilationUnit _cloneResolveUnit(CompilationUnit unit) {
  CompilationUnit clonedUnit = AstCloner.clone(unit);
  new DeclarationResolver().resolve(clonedUnit, unit.declaredElement);
  return clonedUnit;
}

@reflectiveTest
class DeclarationResolverMetadataTest extends DriverResolutionTest {
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

  Future<void> setupCode(String code) async {
    this.code = code;

    addTestFile(code + ' const a = null;');
    await resolveTestFile();

    unit = result.unit;
    unit2 = _cloneResolveUnit(unit);
  }

  test_classDeclaration() async {
    await setupCode('@a class C {}');
    checkMetadata('C');
  }

  test_classTypeAlias() async {
    await setupCode('@a class C = D with E; class D {} class E {}');
    checkMetadata('C');
  }

  test_constructorDeclaration_named() async {
    await setupCode('class C { @a C.x(); }');
    checkMetadata('x');
  }

  test_constructorDeclaration_unnamed() async {
    await setupCode('class C { @a C(); }');
    checkMetadata('C()');
  }

  test_declaredIdentifier() async {
    await setupCode('f(x, y) { for (@a var x in y) {} }');
    checkMetadata('var', expectDifferent: true);
  }

  test_enumDeclaration() async {
    await setupCode('@a enum E { v }');
    checkMetadata('E');
  }

  test_enumDeclaration_constant() async {
    await setupCode('enum E { @a v }');
    checkMetadata('v');
  }

  test_exportDirective() async {
    newFile('/test/lib/foo.dart', content: 'class C {}');
    await setupCode('@a export "foo.dart";');
    checkMetadata('export');
  }

  test_exportDirective_resynthesized() async {
    addTestFile(r'''
@a
export "dart:async";

@b
export "dart:math";

const a = null;
const b = null;
''');
    await resolveTestFile();
    unit = result.unit;

    expect(unit.directives[0].metadata.single.name.name, 'a');
    expect(unit.directives[1].metadata.single.name.name, 'b');
    var unitElement = unit.declaredElement as CompilationUnitElementImpl;

    // Damage the unit element - as if "setAnnotations" were not called.
    // The ExportElement(s) still have the metadata, we should use it.
    unitElement.setAnnotations(unit.directives[0].offset, []);
    unitElement.setAnnotations(unit.directives[1].offset, []);
    expect(unitElement.library.exports[0].metadata, hasLength(1));
    expect(unitElement.library.exports[1].metadata, hasLength(1));

    // DeclarationResolver on the clone should succeed.
    CompilationUnit clonedUnit = AstCloner.clone(unit);
    new DeclarationResolver().resolve(clonedUnit, unit.declaredElement);
    expect(unit.directives[0].metadata.single.name.name, 'a');
    expect(unit.directives[1].metadata.single.name.name, 'b');
  }

  test_fieldDeclaration() async {
    await setupCode('class C { @a int x; }');
    checkMetadata('x');
  }

  test_fieldFormalParameter() async {
    await setupCode('class C { var x; C(@a this.x); }');
    checkMetadata('this');
  }

  test_fieldFormalParameter_withDefault() async {
    await setupCode('class C { var x; C([@a this.x = null]); }');
    checkMetadata('this');
  }

  test_functionDeclaration_function() async {
    await setupCode('@a f() {}');
    checkMetadata('f');
  }

  test_functionDeclaration_getter() async {
    await setupCode('@a get f() => null;');
    checkMetadata('f');
  }

  test_functionDeclaration_setter() async {
    await setupCode('@a set f(value) {}');
    checkMetadata('f');
  }

  test_functionTypeAlias() async {
    await setupCode('@a typedef F();');
    checkMetadata('F');
  }

  test_functionTypedFormalParameter() async {
    await setupCode('f(@a g()) {}');
    checkMetadata('g');
  }

  test_functionTypedFormalParameter_withDefault() async {
    await setupCode('f([@a g() = null]) {}');
    checkMetadata('g');
  }

  test_importDirective() async {
    newFile('/test/lib/foo.dart', content: 'class C {}');
    await setupCode('@a import "foo.dart";');
    checkMetadata('import');
  }

  test_importDirective_resynthesized() async {
    addTestFile(r'''
@a
import "dart:async";

@b
import "dart:math";

const a = null;
const b = null;
''');
    await resolveTestFile();
    unit = result.unit;

    expect(unit.directives[0].metadata.single.name.name, 'a');
    expect(unit.directives[1].metadata.single.name.name, 'b');
    var unitElement = unit.declaredElement as CompilationUnitElementImpl;

    // Damage the unit element - as if "setAnnotations" were not called.
    // The ImportElement(s) still have the metadata, we should use it.
    unitElement.setAnnotations(unit.directives[0].offset, []);
    unitElement.setAnnotations(unit.directives[1].offset, []);
    expect(unitElement.library.imports[0].metadata, hasLength(1));
    expect(unitElement.library.imports[1].metadata, hasLength(1));

    // DeclarationResolver on the clone should succeed.
    CompilationUnit clonedUnit = AstCloner.clone(unit);
    new DeclarationResolver().resolve(clonedUnit, unit.declaredElement);
    expect(unit.directives[0].metadata.single.name.name, 'a');
    expect(unit.directives[1].metadata.single.name.name, 'b');
  }

  test_libraryDirective() async {
    await setupCode('@a library L;');
    checkMetadata('L');
  }

  test_libraryDirective_resynthesized() async {
    addTestFile('@a library L; const a = null;');
    await resolveTestFile();
    unit = result.unit;

    expect(unit.directives.single.metadata.single.name.name, 'a');
    var unitElement = unit.declaredElement as CompilationUnitElementImpl;

    // Damage the unit element - as if "setAnnotations" were not called.
    // The LibraryElement still has the metadata, we should use it.
    unitElement.setAnnotations(unit.directives.single.offset, []);
    expect(unitElement.library.metadata, hasLength(1));

    // DeclarationResolver on the clone should succeed.
    CompilationUnit clonedUnit = AstCloner.clone(unit);
    new DeclarationResolver().resolve(clonedUnit, unit.declaredElement);
    expect(clonedUnit.directives.single.metadata.single.name.name, 'a');
  }

  test_localFunctionDeclaration() async {
    await setupCode('f() { @a g() {} }');
    // Note: metadata on local function declarations is ignored by the
    // analyzer.  TODO(paulberry): is this a bug?
    FunctionDeclaration node = EngineTestCase.findNode(
        unit, code, 'g', (AstNode n) => n is FunctionDeclaration);
    NodeList<Annotation> metadata = (node as FunctionDeclarationImpl).metadata;
    if (Parser.useFasta) {
      expect(metadata, hasLength(1));
    } else {
      expect(metadata, isEmpty);
    }
  }

  test_localVariableDeclaration() async {
    await setupCode('f() { @a int x; }');
    checkMetadata('x', expectDifferent: true);
  }

  test_methodDeclaration_getter() async {
    await setupCode('class C { @a get m => null; }');
    checkMetadata('m');
  }

  test_methodDeclaration_method() async {
    await setupCode('class C { @a m() {} }');
    checkMetadata('m');
  }

  test_methodDeclaration_setter() async {
    await setupCode('class C { @a set m(value) {} }');
    checkMetadata('m');
  }

  test_partDirective() async {
    newFile('/test/lib/foo.dart', content: 'part of L;');
    await setupCode('library L; @a part "foo.dart";');
    checkMetadata('part');
  }

  test_partDirective_resynthesized() async {
    newFile('/test/lib/part_a.dart', content: 'part of L;');
    newFile('/test/lib/part_b.dart', content: 'part of L;');

    addTestFile(r'''
library L;

@a
part "part_a.dart";

@b
part "part_b.dart";

const a = null;
const b = null;
''');
    await resolveTestFile();
    unit = result.unit;

    expect(unit.directives[1].metadata.single.name.name, 'a');
    expect(unit.directives[2].metadata.single.name.name, 'b');
    var unitElement = unit.declaredElement as CompilationUnitElementImpl;

    // Damage the unit element - as if "setAnnotations" were not called.
    // The ImportElement(s) still have the metadata, we should use it.
    unitElement.setAnnotations(unit.directives[1].offset, []);
    unitElement.setAnnotations(unit.directives[2].offset, []);
    expect(unitElement.library.parts[0].metadata, hasLength(1));
    expect(unitElement.library.parts[1].metadata, hasLength(1));

    // DeclarationResolver on the clone should succeed.
    CompilationUnit clonedUnit = AstCloner.clone(unit);
    new DeclarationResolver().resolve(clonedUnit, unit.declaredElement);
    expect(unit.directives[1].metadata.single.name.name, 'a');
    expect(unit.directives[2].metadata.single.name.name, 'b');
  }

  test_simpleFormalParameter() async {
    await setupCode('f(@a x) {}) {}');
    checkMetadata('x');
  }

  test_simpleFormalParameter_withDefault() async {
    await setupCode('f([@a x = null]) {}');
    checkMetadata('x');
  }

  test_topLevelVariableDeclaration() async {
    await setupCode('@a int x;');
    checkMetadata('x');
  }

  test_typeParameter_ofClass() async {
    await setupCode('class C<@a T> {}');
    checkMetadata('T');
  }

  test_typeParameter_ofClassTypeAlias() async {
    await setupCode('class C<@a T> = D with E; class D {} class E {}');
    checkMetadata('T');
  }

  test_typeParameter_ofFunction() async {
    await setupCode('f<@a T>() {}');
    checkMetadata('T');
  }

  test_typeParameter_ofTypedef() async {
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
  }
}

@reflectiveTest
class DeclarationResolverTest extends DriverResolutionTest {
  test_closure_inside_catch_block() async {
    addTestFile('''
f() {
  try {
  } catch (e) {
    return () => null;
  }
}
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_closure_inside_labeled_statement() async {
    addTestFile('''
f(b) {
  foo: while (true) {
    if (b) {
      break foo;
    }
    return () => null;
  }
}
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_closure_inside_switch_case() async {
    addTestFile('''
void f(k, m) {
  switch (k) {
    case 0:
      m.forEach((key, value) {});
    break;
  }
}
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_closure_inside_switch_default() async {
    addTestFile('''
void f(k, m) {
  switch (k) {
    default:
      m.forEach((key, value) {});
    break;
  }
}
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_functionDeclaration_getter() async {
    addTestFile(r'''
int get zzz => 42;
''');
    await resolveTestFile();

    var getterElement = findElement.topGet('zzz');
    expect(getterElement.isGetter, isTrue);

    // re-resolve
    var unit2 = _cloneResolveUnit(result.unit);
    var getterName = FindNode(result.content, unit2).simple('zzz =>');
    expect(getterName.staticElement, same(getterElement));
  }

  test_functionDeclaration_setter() async {
    addTestFile(r'''
void set zzz(_) {}
''');
    await resolveTestFile();

    var setterElement = findElement.topSet('zzz');
    expect(setterElement.isSetter, isTrue);

    // re-resolve
    var unit2 = _cloneResolveUnit(result.unit);
    var getterName = FindNode(result.content, unit2).simple('zzz(_)');
    expect(getterName.staticElement, same(setterElement));
  }

  test_genericFunction_asFunctionReturnType() async {
    addTestFile(r'''
Function(int, String) f() => null;
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asGenericFunctionReturnType() async {
    addTestFile(r'''
typedef F<T> = int Function(T t, S s) Function<S>(int);
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asMethodReturnType() async {
    addTestFile(r'''
class C {
  Function(int, String) m() => null;
}
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asParameterReturnType() async {
    addTestFile(r'''
f(Function(int, String) p) => null;
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asTopLevelVariableType() async {
    addTestFile(r'''
int Function(int, String) v;
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asTypeArgument() async {
    addTestFile(r'''
List<Function(int)> v;
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asTypeArgument_lessNodes() async {
    addTestFile(r'''
Map<Function<int>> v;
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asTypeArgument_moreNodes() async {
    addTestFile(r'''
List<Function<int>, Function<String>> v;
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asTypeArgument_noNodes() async {
    addTestFile(r'''
List v;
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_genericFunction_asTypeArgument_ofInitializer() async {
    String code = r'''
var v = <Function(int)>[];
''';
    addTestFile(code);
    await resolveTestFile();

    var newUnit = _cloneResolveUnit(result.unit);
    var initializer = FindNode(result.content, newUnit).listLiteral('>[]');
    expect(initializer.typeArguments.arguments[0].type, isNotNull);
  }

  test_genericFunction_invalid_missingParameterName() async {
    addTestFile(r'''
typedef F = Function({int});
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_invalid_functionDeclaration_getter_inFunction() async {
    addTestFile(r'''
var v = (() {
  main() {
    int get zzz => 42;
  }
});
''');
    await resolveTestFile();

    // re-resolve
    var unit2 = _cloneResolveUnit(result.unit);
    var getterName = FindNode(result.content, unit2).simple('zzz =>');

    // Local getters are not allowed, so a FunctionElement is created.
    expect(getterName.staticElement, isFunctionElement);
  }

  test_invalid_functionDeclaration_setter_inFunction() async {
    addTestFile(r'''
var v = (() {
  main() {
    set zzz(x) {}
  }
});
''');
    await resolveTestFile();

    // re-resolve
    var unit2 = _cloneResolveUnit(result.unit);
    var setterName = FindNode(result.content, unit2).simple('zzz(x)');

    // Local getters are not allowed, so a FunctionElement is created.
    expect(setterName.staticElement, isFunctionElement);
  }

  test_visitExportDirective_notExistingSource() async {
    addTestFile(r'''
export 'foo.dart';
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitExportDirective_unresolvedUri() async {
    addTestFile(r'''
export 'package:foo/bar.dart';
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitFunctionExpression() async {
    addTestFile(r'''
main(List<String> items) {
  items.forEach((item) {});
}
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitGenericTypeAlias_0() async {
    addTestFile(r'''
typedef F<T> = Function<S>(List<S> list, Function<A>(A), T);
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitGenericTypeAlias_1() async {
    addTestFile(r'''
typedef F = Function({int});
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitGenericTypeAlias_2() async {
    addTestFile(r'''
typedef F = int;
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitImportDirective_notExistingSource() async {
    addTestFile(r'''
import 'foo.dart';
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitImportDirective_unresolvedUri() async {
    addTestFile(r'''
import 'package:foo/bar.dart';
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitMethodDeclaration_getter_duplicate() async {
    addTestFile(r'''
class C {
  int get zzz => 1;
  String get zzz => null;
}
''');
    await resolveTestFile();

    var firstElement = findNode.simple('zzz => 1').staticElement;
    var secondElement = findNode.simple('zzz => null').staticElement;
    expect(firstElement, isNot(same(secondElement)));

    // re-resolve
    var unit2 = _cloneResolveUnit(result.unit);
    var findNode2 = FindNode(result.content, unit2);
    var firstName = findNode2.simple('zzz => 1');
    var secondName = findNode2.simple('zzz => null');
    expect(firstName.staticElement, same(firstElement));
    expect(secondName.staticElement, same(secondElement));
  }

  test_visitMethodDeclaration_getterSetter() async {
    addTestFile(r'''
class C {
  int _field = 0;
  int get field => _field;
  void set field(value) {_field = value;}
}
''');
    await resolveTestFile();

    var getterElement = findElement.getter('field');
    var setterElement = findElement.setter('field');

    // re-resolve
    var unit2 = _cloneResolveUnit(result.unit);
    var findNode2 = FindNode(result.content, unit2);
    var getterName = findNode2.simple('field =>');
    var setterName = findNode2.simple('field(value)');
    expect(getterName.staticElement, same(getterElement));
    expect(setterName.staticElement, same(setterElement));
  }

  test_visitMethodDeclaration_method_duplicate() async {
    addTestFile(r'''
class C {
  void zzz(x) {}
  void zzz(y) {}
}
''');
    await resolveTestFile();

    MethodElement firstElement = findNode.simple('zzz(x)').staticElement;
    MethodElement secondElement = findNode.simple('zzz(y)').staticElement;
    expect(firstElement, isNot(same(secondElement)));

    // re-resolve
    var unit2 = _cloneResolveUnit(result.unit);
    var findNode2 = FindNode(result.content, unit2);
    var firstName = findNode2.simple('zzz(x)');
    var secondName = findNode2.simple('zzz(y)');
    expect(firstName.staticElement, same(firstElement));
    expect(secondName.staticElement, same(secondElement));
  }

  test_visitMethodDeclaration_setter_duplicate() async {
    // https://github.com/dart-lang/sdk/issues/25601
    addTestFile(r'''
class C {
  set zzz(x) {}
  set zzz(y) {}
}
''');
    await resolveTestFile();

    PropertyAccessorElement firstElement =
        findNode.simple('zzz(x)').staticElement;
    PropertyAccessorElement secondElement =
        findNode.simple('zzz(y)').staticElement;
    expect(firstElement, isNot(same(secondElement)));

    // re-resolve
    var unit2 = _cloneResolveUnit(result.unit);
    var findNode2 = FindNode(result.content, unit2);
    var firstName = findNode2.simple('zzz(x)');
    var secondName = findNode2.simple('zzz(y)');
    expect(firstName.staticElement, same(firstElement));
    expect(secondName.staticElement, same(secondElement));
  }

  test_visitMethodDeclaration_unaryMinus() async {
    addTestFile(r'''
class C {
  C operator -() => null;
  C operator -(C other) => null;
}
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }

  test_visitPartDirective_notExistingSource() async {
    addTestFile(r'''
part 'foo.bar';
''');
    await resolveTestFile();
    // re-resolve
    _cloneResolveUnit(result.unit);
    // no other validations than built into DeclarationResolver
  }
}
