// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/element_type_matchers.dart';
import '../resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementLocatorTest);
  });
}

@reflectiveTest
class ElementLocatorTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions {
    return AnalysisOptionsImpl()..hint = false;
  }

  test_locate_AssignmentExpression() async {
    await _resolveTestCode(r'''
int x = 0;
void main() {
  x += 1;
}
''');
    var node = findNode.assignment('+=');
    var element = ElementLocator.locate(node);
    expect(element, isMethodElement);
  }

  test_locate_BinaryExpression() async {
    await _resolveTestCode('var x = 3 + 4');
    var node = findNode.binary('+');
    var element = ElementLocator.locate(node);
    expect(element, isMethodElement);
  }

  test_locate_ClassDeclaration() async {
    await _resolveTestCode('class A {}');
    var node = findNode.classDeclaration('class');
    var element = ElementLocator.locate(node);
    expect(element, isClassElement);
  }

  test_locate_CompilationUnit() async {
    await _resolveTestCode('// only comment');

    var unitElement = result.unit.declaredElement;
    expect(unitElement, isNotNull);

    var element = ElementLocator.locate(result.unit);
    expect(element, same(unitElement));
  }

  test_locate_ConstructorDeclaration() async {
    await _resolveTestCode(r'''
class A {
  A.foo();
}
''');
    var node = findNode.constructor('foo();');
    var element = ElementLocator.locate(node);
    expect(element, isConstructorElement);
  }

  test_locate_ExportDirective() async {
    await _resolveTestCode("export 'dart:code';");
    var node = findNode.export('export');
    var element = ElementLocator.locate(node);
    expect(element, isExportElement);
  }

  test_locate_FunctionDeclaration() async {
    await _resolveTestCode('int f() => 3;');
    var node = findNode.functionDeclaration('f');
    var element = ElementLocator.locate(node);
    expect(element, isFunctionElement);
  }

  test_locate_Identifier_annotationClass_namedConstructor() async {
    await _resolveTestCode(r'''
class Class {
  const Class.name();
}
void main(@Class.name() parameter) {}
''');
    var node = findNode.simple('Class.name() parameter');
    var element = ElementLocator.locate(node);
    expect(element, isClassElement);
  }

  test_locate_Identifier_annotationClass_unnamedConstructor() async {
    await _resolveTestCode(r'''
class Class {
  const Class();
}
void main(@Class() parameter) {}
''');
    var node = findNode.simple('Class() parameter');
    var element = ElementLocator.locate(node);
    expect(element, isConstructorElement);
  }

  test_locate_Identifier_className() async {
    await _resolveTestCode('class A {}');
    var node = findNode.simple('A');
    var element = ElementLocator.locate(node);
    expect(element, isClassElement);
  }

  test_locate_Identifier_constructor_named() async {
    await _resolveTestCode(r'''
class A {
  A.bar();
}
''');
    var node = findNode.simple('bar');
    var element = ElementLocator.locate(node);
    expect(element, isConstructorElement);
  }

  test_locate_Identifier_constructor_unnamed() async {
    await _resolveTestCode(r'''
class A {
  A();
}
''');
    var node = findNode.constructor('A();');
    var element = ElementLocator.locate(node);
    expect(element, isConstructorElement);
  }

  test_locate_Identifier_fieldName() async {
    await _resolveTestCode('''
class A {
  var x;
}
''');
    var node = findNode.simple('x;');
    var element = ElementLocator.locate(node);
    expect(element, isFieldElement);
  }

  test_locate_Identifier_libraryDirective() async {
    await _resolveTestCode('library foo.bar;');
    var node = findNode.simple('foo');
    var element = ElementLocator.locate(node);
    expect(element, isLibraryElement);
  }

  test_locate_Identifier_propertyAccess() async {
    await _resolveTestCode(r'''
void main() {
 int x = 'foo'.length;
}
''');
    var node = findNode.simple('length');
    var element = ElementLocator.locate(node);
    expect(element, isPropertyAccessorElement);
  }

  test_locate_ImportDirective() async {
    await _resolveTestCode("import 'dart:core';");
    var node = findNode.import('import');
    var element = ElementLocator.locate(node);
    expect(element, isImportElement);
  }

  test_locate_IndexExpression() async {
    await _resolveTestCode(r'''
void main() {
  var x = [1, 2];
  var y = x[0];
}
''');
    var node = findNode.index('[0]');
    var element = ElementLocator.locate(node);
    expect(element, isMethodElement);
  }

  test_locate_InstanceCreationExpression() async {
    await _resolveTestCode(r'''
class A {}

void main() {
 new A();
}
''');
    var node = findNode.instanceCreation('new A()');
    var element = ElementLocator.locate(node);
    expect(element, isConstructorElement);
  }

  test_locate_InstanceCreationExpression_type_prefixedIdentifier() async {
    newFile('/test/lib/a.dart', content: r'''
class A {}
''');
    await _resolveTestCode(r'''
import 'a.dart' as pref;

void main() {
 new pref.A();
}
''');
    var node = findNode.instanceCreation('A();');
    var element = ElementLocator.locate(node);
    expect(element, isConstructorElement);
  }

  test_locate_InstanceCreationExpression_type_simpleIdentifier() async {
    newFile('/test/lib/a.dart', content: r'''
''');
    await _resolveTestCode(r'''
class A {}

void main() {
 new A();
}
''');
    var node = findNode.instanceCreation('A();');
    var element = ElementLocator.locate(node);
    expect(element, isConstructorElement);
  }

  test_locate_LibraryDirective() async {
    await _resolveTestCode('library foo;');
    var node = findNode.library('library');
    var element = ElementLocator.locate(node);
    expect(element, isLibraryElement);
  }

  test_locate_MethodDeclaration() async {
    await _resolveTestCode(r'''
class A {
  void foo() {}
}
''');
    var node = findNode.methodDeclaration('foo');
    var element = ElementLocator.locate(node);
    expect(element, isMethodElement);
  }

  test_locate_MethodInvocation_method() async {
    await _resolveTestCode(r'''
class A {
  void foo() {}
}

void main() {
 new A().foo();
}
''');
    var node = findNode.methodInvocation('foo();');
    var element = ElementLocator.locate(node);
    expect(element, isMethodElement);
  }

  test_locate_MethodInvocation_topLevel() async {
    await _resolveTestCode(r'''
foo(x) {}

void main() {
 foo(0);
}
''');
    var node = findNode.methodInvocation('foo(0)');
    var element = ElementLocator.locate(node);
    expect(element, isFunctionElement);
  }

  test_locate_PartOfDirective() async {
    var libPath = convertPath('/test/lib/lib.dart');
    var partPath = convertPath('/test/lib/test.dart');

    newFile(libPath, content: r'''
library my.lib;
part 'test.dart';
''');

    driver.addFile(libPath);
    driver.addFile(partPath);

    await _resolveTestCode('part of my.lib;');
    var node = findNode.partOf('part of');
    var element = ElementLocator.locate(node);
    expect(element, isLibraryElement);
  }

  test_locate_PostfixExpression() async {
    await _resolveTestCode('int addOne(int x) => x++;');
    var node = findNode.postfix('x++');
    var element = ElementLocator.locate(node);
    expect(element, isMethodElement);
  }

  test_locate_PrefixedIdentifier() async {
    await _resolveTestCode(r'''
import 'dart:core' as core;
core.int value;
''');
    var node = findNode.prefixed('core.int');
    var element = ElementLocator.locate(node);
    expect(element, isClassElement);
  }

  test_locate_PrefixExpression() async {
    await _resolveTestCode('int addOne(int x) => ++x;');
    var node = findNode.prefix('++x');
    var element = ElementLocator.locate(node);
    expect(element, isMethodElement);
  }

  test_locate_StringLiteral_exportUri() async {
    newFile("/test/lib/foo.dart", content: '');
    await _resolveTestCode("export 'foo.dart';");
    var node = findNode.stringLiteral('foo.dart');
    var element = ElementLocator.locate(node);
    expect(element, isLibraryElement);
  }

  test_locate_StringLiteral_expression() async {
    await _resolveTestCode("var x = 'abc';");
    var node = findNode.stringLiteral('abc');
    var element = ElementLocator.locate(node);
    expect(element, isNull);
  }

  test_locate_StringLiteral_importUri() async {
    newFile("/test/lib/foo.dart", content: '');
    await _resolveTestCode("import 'foo.dart';");
    var node = findNode.stringLiteral('foo.dart');
    var element = ElementLocator.locate(node);
    expect(element, isLibraryElement);
  }

  test_locate_StringLiteral_partUri() async {
    newFile("/test/lib/foo.dart", content: 'part of lib;');
    await _resolveTestCode('''
library lib;

part 'foo.dart';
''');
    var node = findNode.stringLiteral('foo.dart');
    var element = ElementLocator.locate(node);
    expect(element, isCompilationUnitElement);
  }

  test_locate_VariableDeclaration() async {
    await _resolveTestCode('var x = 42;');
    var node = findNode.variableDeclaration('x =');
    var element = ElementLocator.locate(node);
    expect(element, isTopLevelVariableElement);
  }

  Future<void> _resolveTestCode(String code) async {
    addTestFile(code);
    await resolveTestFile();
  }
}
