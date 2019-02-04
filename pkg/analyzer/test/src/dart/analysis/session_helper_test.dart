// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisSessionHelperTest);
  });
}

@reflectiveTest
class AnalysisSessionHelperTest extends DriverResolutionTest {
  AnalysisSessionHelper helper;

  @override
  void setUp() {
    super.setUp();
    helper = new AnalysisSessionHelper(driver.currentSession);
  }

  test_getClass_defined() async {
    var file = newFile('/test/lib/c.dart', content: r'''
class C {}
int v = 0;
''');
    String uri = file.toUri().toString();

    var element = await helper.getClass(uri, 'C');
    expect(element, isNotNull);
    expect(element.displayName, 'C');
  }

  test_getClass_defined_notClass() async {
    var file = newFile('/test/lib/c.dart', content: r'''
int v = 0;
''');
    String uri = file.toUri().toString();

    var element = await helper.getClass(uri, 'v');
    expect(element, isNull);
  }

  test_getClass_exported() async {
    newFile('/test/lib/a.dart', content: r'''
class A {}
''');
    var bFile = newFile('/test/lib/b.dart', content: r'''
export 'a.dart';
''');
    String bUri = bFile.toUri().toString();

    var element = await helper.getClass(bUri, 'A');
    expect(element, isNotNull);
    expect(element.displayName, 'A');
  }

  test_getClass_imported() async {
    newFile('/test/lib/a.dart', content: r'''
class A {}
''');
    var bFile = newFile('/test/lib/b.dart', content: r'''
import 'a.dart';
''');
    String bUri = bFile.toUri().toString();

    var element = await helper.getClass(bUri, 'A');
    expect(element, isNull);
  }

  test_getElementDeclaration_class() async {
    newFile('/test/lib/test.dart', content: r'''
class A {}
''');
    await resolveTestFile();

    var element = findNode.classDeclaration('A').declaredElement;
    var result = await helper.getElementDeclaration(element);
    ClassDeclaration node = result.node;
    expect(node.name.name, 'A');
  }

  test_getElementDeclaration_class_duplicate() async {
    newFile('/test/lib/test.dart', content: r'''
class A {} // 1
class A {} // 2
''');
    await resolveTestFile();

    {
      var element = findNode.classDeclaration('A {} // 1').declaredElement;
      var result = await helper.getElementDeclaration(element);
      ClassDeclaration node = result.node;
      expect(node.name.name, 'A');
      expect(
        node.name.offset,
        this.result.content.indexOf('A {} // 1'),
      );
    }

    {
      var element = findNode.classDeclaration('A {} // 2').declaredElement;
      var result = await helper.getElementDeclaration(element);
      ClassDeclaration node = result.node;
      expect(node.name.name, 'A');
      expect(
        node.name.offset,
        this.result.content.indexOf('A {} // 2'),
      );
    }
  }

  test_getElementDeclaration_class_inPart() async {
    newFile('/test/lib/a.dart', content: r'''
part of 'test.dart';
class A {}
''');
    newFile('/test/lib/test.dart', content: r'''
part 'a.dart';
''');
    await resolveTestFile();

    var library = this.result.unit.declaredElement.library;
    var element = library.getType('A');
    var result = await helper.getElementDeclaration(element);
    ClassDeclaration node = result.node;
    expect(node.name.name, 'A');
  }

  test_getElementDeclaration_constructor() async {
    newFile('/test/lib/test.dart', content: r'''
class A {
  A();
  A.named();
}
''');
    await resolveTestFile();

    {
      var unnamed = findNode.constructor('A();').declaredElement;
      var result = await helper.getElementDeclaration(unnamed);
      ConstructorDeclaration node = result.node;
      expect(node.name, isNull);
    }

    {
      var named = findNode.constructor('A.named();').declaredElement;
      var result = await helper.getElementDeclaration(named);
      ConstructorDeclaration node = result.node;
      expect(node.name.name, 'named');
    }
  }

  test_getElementDeclaration_constructor_duplicate_named() async {
    newFile('/test/lib/test.dart', content: r'''
class A {
  A.named(); // 1
  A.named(); // 2
}
''');
    await resolveTestFile();

    {
      var element = findNode.constructor('A.named(); // 1').declaredElement;
      var result = await helper.getElementDeclaration(element);
      ConstructorDeclaration node = result.node;
      expect(node.name.name, 'named');
      expect(
        node.name.offset,
        this.result.content.indexOf('named(); // 1'),
      );
    }

    {
      var element = findNode.constructor('A.named(); // 2').declaredElement;
      var result = await helper.getElementDeclaration(element);
      ConstructorDeclaration node = result.node;
      expect(node.name.name, 'named');
      expect(
        node.name.offset,
        this.result.content.indexOf('named(); // 2'),
      );
    }
  }

  test_getElementDeclaration_constructor_duplicate_unnamed() async {
    newFile('/test/lib/test.dart', content: r'''
class A {
  A(); // 1
  A(); // 2
}
''');
    await resolveTestFile();

    {
      var element = findNode.constructor('A(); // 1').declaredElement;
      var result = await helper.getElementDeclaration(element);
      ConstructorDeclaration node = result.node;
      expect(node.name, isNull);
      expect(
        node.returnType.offset,
        this.result.content.indexOf('A(); // 1'),
      );
    }

    {
      var element = findNode.constructor('A(); // 2').declaredElement;
      var result = await helper.getElementDeclaration(element);
      ConstructorDeclaration node = result.node;
      expect(node.name, isNull);
      expect(
        node.returnType.offset,
        this.result.content.indexOf('A(); // 2'),
      );
    }
  }

  test_getElementDeclaration_constructor_synthetic() async {
    newFile('/test/lib/test.dart', content: r'''
class A {}
''');
    await resolveTestFile();

    var element = findElement.class_('A').unnamedConstructor;
    expect(element.isSynthetic, isTrue);

    var result = await helper.getElementDeclaration(element);
    expect(result, isNull);
  }

  test_getElementDeclaration_field() async {
    newFile('/test/lib/test.dart', content: r'''
class C {
  int foo;
}
''');
    await resolveTestFile();

    var element = findElement.field('foo');
    var result = await helper.getElementDeclaration(element);
    VariableDeclaration node = result.node;
    expect(node.name.name, 'foo');
  }

  test_getElementDeclaration_functionDeclaration_local() async {
    newFile('/test/lib/test.dart', content: r'''
main() {
  void foo() {}
}
''');
    await resolveTestFile();

    var element = findElement.localFunction('foo');
    var result = await helper.getElementDeclaration(element);
    FunctionDeclaration node = result.node;
    expect(node.name.name, 'foo');
  }

  test_getElementDeclaration_functionDeclaration_top() async {
    newFile('/test/lib/test.dart', content: r'''
void foo() {}
''');
    await resolveTestFile();

    var element = findElement.topFunction('foo');
    var result = await helper.getElementDeclaration(element);
    FunctionDeclaration node = result.node;
    expect(node.name.name, 'foo');
  }

  test_getElementDeclaration_localVariable() async {
    newFile('/test/lib/test.dart', content: r'''
main() {
  int foo;
}
''');
    await resolveTestFile();

    var element = findElement.localVar('foo');
    var result = await helper.getElementDeclaration(element);
    VariableDeclaration node = result.node;
    expect(node.name.name, 'foo');
  }

  test_getElementDeclaration_method() async {
    newFile('/test/lib/test.dart', content: r'''
class C {
  void foo() {}
}
''');
    await resolveTestFile();

    var element = findElement.method('foo');
    var result = await helper.getElementDeclaration(element);
    MethodDeclaration node = result.node;
    expect(node.name.name, 'foo');
  }

  test_getElementDeclaration_topLevelVariable() async {
    newFile('/test/lib/test.dart', content: r'''
int foo;
''');
    await resolveTestFile();

    var element = findElement.topVar('foo');
    var result = await helper.getElementDeclaration(element);
    VariableDeclaration node = result.node;
    expect(node.name.name, 'foo');
  }

  test_getElementDeclaration_topLevelVariable_synthetic() async {
    newFile('/test/lib/test.dart', content: r'''
int get foo => 0;
''');
    await resolveTestFile();

    var element = findElement.topVar('foo');
    var result = await helper.getElementDeclaration(element);
    expect(result, isNull);
  }

  test_getResolvedUnitByElement() async {
    newFile('/test/lib/test.dart', content: r'''
class A {}
class B {}
''');
    await resolveTestFile();

    var element = findNode.classDeclaration('A').declaredElement;
    var resolvedUnit = await helper.getResolvedUnitByElement(element);
    expect(resolvedUnit.unit.declarations, hasLength(2));
  }

  test_getTopLevelPropertyAccessor_defined_getter() async {
    var file = newFile('/test/lib/test.dart', content: r'''
int get a => 0;
''');
    String uri = file.toUri().toString();

    var element = await helper.getTopLevelPropertyAccessor(uri, 'a');
    expect(element, isNotNull);
    expect(element.kind, ElementKind.GETTER);
    expect(element.displayName, 'a');
  }

  test_getTopLevelPropertyAccessor_defined_setter() async {
    var file = newFile('/test/lib/test.dart', content: r'''
set a(_) {}
''');
    String uri = file.toUri().toString();

    var element = await helper.getTopLevelPropertyAccessor(uri, 'a=');
    expect(element, isNotNull);
    expect(element.kind, ElementKind.SETTER);
    expect(element.displayName, 'a');
  }

  test_getTopLevelPropertyAccessor_defined_variable() async {
    var file = newFile('/test/lib/test.dart', content: r'''
int a;
''');
    String uri = file.toUri().toString();

    var element = await helper.getTopLevelPropertyAccessor(uri, 'a');
    expect(element, isNotNull);
    expect(element.kind, ElementKind.GETTER);
    expect(element.displayName, 'a');
  }

  test_getTopLevelPropertyAccessor_exported() async {
    newFile('/test/lib/a.dart', content: r'''
int a;
''');
    var bFile = newFile('/test/lib/b.dart', content: r'''
export 'a.dart';
''');
    String bUri = bFile.toUri().toString();

    var element = await helper.getTopLevelPropertyAccessor(bUri, 'a');
    expect(element, isNotNull);
    expect(element.kind, ElementKind.GETTER);
    expect(element.displayName, 'a');
  }

  test_getTopLevelPropertyAccessor_imported() async {
    newFile('/test/lib/a.dart', content: r'''
int a;
''');
    var bFile = newFile('/test/lib/b.dart', content: r'''
import 'a.dart';
''');
    String bUri = bFile.toUri().toString();

    var element = await helper.getTopLevelPropertyAccessor(bUri, 'a');
    expect(element, isNull);
  }

  test_getTopLevelPropertyAccessor_notDefined() async {
    var file = newFile('/test/lib/test.dart', content: r'''
int a;
''');
    String uri = file.toUri().toString();

    var element = await helper.getTopLevelPropertyAccessor(uri, 'b');
    expect(element, isNull);
  }

  test_getTopLevelPropertyAccessor_notPropertyAccessor() async {
    var file = newFile('/test/lib/test.dart', content: r'''
int a() {}
''');
    String uri = file.toUri().toString();

    var element = await helper.getTopLevelPropertyAccessor(uri, 'a');
    expect(element, isNull);
  }
}
