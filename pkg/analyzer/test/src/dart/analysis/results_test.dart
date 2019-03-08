// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetElementDeclarationParsedTest);
    defineReflectiveTests(GetElementDeclarationResolvedTest);
  });
}

mixin GetElementDeclarationMixin implements DriverResolutionTest {
  Future<ElementDeclarationResult> getElementDeclaration(Element element);

  test_class() async {
    addTestFile(r'''
class A {}
''');
    await resolveTestFile();

    var element = findNode.classDeclaration('A').declaredElement;
    var result = await getElementDeclaration(element);
    ClassDeclaration node = result.node;
    expect(node.name.name, 'A');
  }

  test_class_duplicate() async {
    addTestFile(r'''
class A {} // 1
class A {} // 2
''');
    await resolveTestFile();

    {
      var element = findNode.classDeclaration('A {} // 1').declaredElement;
      var result = await getElementDeclaration(element);
      ClassDeclaration node = result.node;
      expect(node.name.name, 'A');
      expect(
        node.name.offset,
        this.result.content.indexOf('A {} // 1'),
      );
    }

    {
      var element = findNode.classDeclaration('A {} // 2').declaredElement;
      var result = await getElementDeclaration(element);
      ClassDeclaration node = result.node;
      expect(node.name.name, 'A');
      expect(
        node.name.offset,
        this.result.content.indexOf('A {} // 2'),
      );
    }
  }

  test_class_inPart() async {
    newFile('/test/lib/a.dart', content: r'''
part of 'test.dart';
class A {}
''');
    addTestFile(r'''
part 'a.dart';
''');
    await resolveTestFile();

    var library = this.result.unit.declaredElement.library;
    var element = library.getType('A');
    var result = await getElementDeclaration(element);
    ClassDeclaration node = result.node;
    expect(node.name.name, 'A');
  }

  test_class_missingName() async {
    addTestFile('''
class {}
''');
    await resolveTestFile();

    var element = findNode.classDeclaration('class {}').declaredElement;
    var result = await getElementDeclaration(element);
    ClassDeclaration node = result.node;
    expect(node.name.name, '');
    expect(node.name.offset, 6);
  }

  test_classTypeAlias() async {
    addTestFile(r'''
mixin M {}
class A {}
class B = A with M;
''');
    await resolveTestFile();

    var element = findElement.class_('B');
    var result = await getElementDeclaration(element);
    ClassTypeAlias node = result.node;
    expect(node.name.name, 'B');
  }

  test_constructor() async {
    addTestFile(r'''
class A {
  A();
  A.named();
}
''');
    await resolveTestFile();

    {
      var unnamed = findNode.constructor('A();').declaredElement;
      var result = await getElementDeclaration(unnamed);
      ConstructorDeclaration node = result.node;
      expect(node.name, isNull);
    }

    {
      var named = findNode.constructor('A.named();').declaredElement;
      var result = await getElementDeclaration(named);
      ConstructorDeclaration node = result.node;
      expect(node.name.name, 'named');
    }
  }

  test_constructor_duplicate_named() async {
    addTestFile(r'''
class A {
  A.named(); // 1
  A.named(); // 2
}
''');
    await resolveTestFile();

    {
      var element = findNode.constructor('A.named(); // 1').declaredElement;
      var result = await getElementDeclaration(element);
      ConstructorDeclaration node = result.node;
      expect(node.name.name, 'named');
      expect(
        node.name.offset,
        this.result.content.indexOf('named(); // 1'),
      );
    }

    {
      var element = findNode.constructor('A.named(); // 2').declaredElement;
      var result = await getElementDeclaration(element);
      ConstructorDeclaration node = result.node;
      expect(node.name.name, 'named');
      expect(
        node.name.offset,
        this.result.content.indexOf('named(); // 2'),
      );
    }
  }

  test_constructor_duplicate_unnamed() async {
    addTestFile(r'''
class A {
  A(); // 1
  A(); // 2
}
''');
    await resolveTestFile();

    {
      var element = findNode.constructor('A(); // 1').declaredElement;
      var result = await getElementDeclaration(element);
      ConstructorDeclaration node = result.node;
      expect(node.name, isNull);
      expect(
        node.returnType.offset,
        this.result.content.indexOf('A(); // 1'),
      );
    }

    {
      var element = findNode.constructor('A(); // 2').declaredElement;
      var result = await getElementDeclaration(element);
      ConstructorDeclaration node = result.node;
      expect(node.name, isNull);
      expect(
        node.returnType.offset,
        this.result.content.indexOf('A(); // 2'),
      );
    }
  }

  test_constructor_synthetic() async {
    addTestFile(r'''
class A {}
''');
    await resolveTestFile();

    var element = findElement.class_('A').unnamedConstructor;
    expect(element.isSynthetic, isTrue);

    var result = await getElementDeclaration(element);
    expect(result, isNull);
  }

  test_enum() async {
    addTestFile(r'''
enum MyEnum {a, b, c}
''');
    await resolveTestFile();

    var element = findElement.enum_('MyEnum');
    var result = await getElementDeclaration(element);
    EnumDeclaration node = result.node;
    expect(node.name.name, 'MyEnum');
  }

  test_enum_constant() async {
    addTestFile(r'''
enum MyEnum {a, b, c}
''');
    await resolveTestFile();

    var element = findElement.field('a');
    var result = await getElementDeclaration(element);
    EnumConstantDeclaration node = result.node;
    expect(node.name.name, 'a');
  }

  test_field() async {
    addTestFile(r'''
class C {
  int foo;
}
''');
    await resolveTestFile();

    var element = findElement.field('foo');

    var result = await getElementDeclaration(element);
    VariableDeclaration node = result.node;
    expect(node.name.name, 'foo');
  }

  test_functionDeclaration_local() async {
    addTestFile(r'''
main() {
  void foo() {}
}
''');
    await resolveTestFile();

    var element = findElement.localFunction('foo');

    var result = await getElementDeclaration(element);
    FunctionDeclaration node = result.node;
    expect(node.name.name, 'foo');
  }

  test_functionDeclaration_top() async {
    addTestFile(r'''
void foo() {}
''');
    await resolveTestFile();

    var element = findElement.topFunction('foo');

    var result = await getElementDeclaration(element);
    FunctionDeclaration node = result.node;
    expect(node.name.name, 'foo');
  }

  test_getter_class() async {
    addTestFile(r'''
class A {
  int get x => 0;
}
''');
    await resolveTestFile();

    var element = findElement.getter('x');
    var result = await getElementDeclaration(element);
    MethodDeclaration node = result.node;
    expect(node.name.name, 'x');
    expect(node.isGetter, isTrue);
  }

  test_getter_top() async {
    addTestFile(r'''
int get x => 0;
''');
    await resolveTestFile();

    var element = findElement.topGet('x');
    var result = await getElementDeclaration(element);
    FunctionDeclaration node = result.node;
    expect(node.name.name, 'x');
    expect(node.isGetter, isTrue);
  }

  test_localVariable() async {
    addTestFile(r'''
main() {
  int foo;
}
''');
    await resolveTestFile();

    var element = findElement.localVar('foo');

    var result = await getElementDeclaration(element);
    VariableDeclaration node = result.node;
    expect(node.name.name, 'foo');
  }

  test_method() async {
    addTestFile(r'''
class C {
  void foo() {}
}
''');
    await resolveTestFile();

    var element = findElement.method('foo');

    var result = await getElementDeclaration(element);
    MethodDeclaration node = result.node;
    expect(node.name.name, 'foo');
  }

  test_mixin() async {
    addTestFile(r'''
mixin M {}
''');
    await resolveTestFile();

    var element = findElement.mixin('M');
    var result = await getElementDeclaration(element);
    MixinDeclaration node = result.node;
    expect(node.name.name, 'M');
  }

  test_parameter() async {
    addTestFile(r'''
void f(int a) {}
''');
    await resolveTestFile();

    var element = findElement.parameter('a');

    var result = await getElementDeclaration(element);
    SimpleFormalParameter node = result.node;
    expect(node.identifier.name, 'a');
  }

  test_parameter_missingName_named() async {
    addTestFile(r'''
void f({@a}) {}
''');
    await resolveTestFile();

    var f = findElement.topFunction('f');
    var element = f.parameters.single;
    expect(element.name, '');
    expect(element.isNamed, isTrue);

    var result = await getElementDeclaration(element);
    DefaultFormalParameter node = result.node;
    expect(node.identifier.name, '');
  }

  test_parameter_missingName_required() async {
    addTestFile(r'''
void f(@a) {}
''');
    await resolveTestFile();

    var f = findElement.topFunction('f');
    var element = f.parameters.single;
    expect(element.name, '');
    expect(element.isPositional, isTrue);

    var result = await getElementDeclaration(element);
    SimpleFormalParameter node = result.node;
    expect(node.identifier.name, '');
  }

  test_setter_class() async {
    addTestFile(r'''
class A {
  set x(_) {}
}
''');
    await resolveTestFile();

    var element = findElement.setter('x');
    var result = await getElementDeclaration(element);
    MethodDeclaration node = result.node;
    expect(node.name.name, 'x');
    expect(node.isSetter, isTrue);
  }

  test_setter_top() async {
    addTestFile(r'''
set x(_) {}
''');
    await resolveTestFile();

    var element = findElement.topSet('x');
    var result = await getElementDeclaration(element);
    FunctionDeclaration node = result.node;
    expect(node.name.name, 'x');
    expect(node.isSetter, isTrue);
  }

  test_topLevelVariable() async {
    addTestFile(r'''
int foo;
''');
    await resolveTestFile();

    var element = findElement.topVar('foo');

    var result = await getElementDeclaration(element);
    VariableDeclaration node = result.node;
    expect(node.name.name, 'foo');
  }

  test_topLevelVariable_synthetic() async {
    addTestFile(r'''
int get foo => 0;
''');
    await resolveTestFile();

    var element = findElement.topVar('foo');

    var result = await getElementDeclaration(element);
    expect(result, isNull);
  }
}

@reflectiveTest
class GetElementDeclarationParsedTest extends DriverResolutionTest
    with GetElementDeclarationMixin {
  @override
  Future<ElementDeclarationResult> getElementDeclaration(
      Element element) async {
    var libraryPath = element.library.source.fullName;
    var library = _getParsedLibrary(libraryPath);
    return library.getElementDeclaration(element);
  }

  ParsedLibraryResultImpl _getParsedLibrary(String path) {
    return driver.getParsedLibrary(path);
  }
}

@reflectiveTest
class GetElementDeclarationResolvedTest extends DriverResolutionTest
    with GetElementDeclarationMixin {
  @override
  Future<ElementDeclarationResult> getElementDeclaration(
      Element element) async {
    var libraryPath = element.library.source.fullName;
    var library = await _getResolvedLibrary(libraryPath);
    return library.getElementDeclaration(element);
  }

  Future<ResolvedLibraryResult> _getResolvedLibrary(String path) {
    return driver.getResolvedLibrary(path);
  }
}
