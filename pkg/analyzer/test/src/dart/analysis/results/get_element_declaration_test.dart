// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetElementDeclarationParsedTest);
    defineReflectiveTests(GetElementDeclarationResolvedTest);
  });
}

mixin GetElementDeclarationMixin implements PubPackageResolutionTest {
  Future<FragmentDeclarationResult?> getFragmentDeclaration(Fragment fragment);

  test_class() async {
    await resolveTestCode(r'''
class A {}
''');
    var fragment = findNode.classDeclaration('A').declaredFragment!;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as ClassDeclaration;
    expect(node.name.lexeme, 'A');
  }

  test_class_duplicate() async {
    await resolveTestCode(r'''
class A {} // 1
class A {} // 2
''');
    {
      var fragment = findNode.classDeclaration('A {} // 1').declaredFragment!;
      var result = await getFragmentDeclaration(fragment);
      var node = result!.node as ClassDeclaration;
      expect(node.name.lexeme, 'A');
      expect(node.name.offset, this.result.content.indexOf('A {} // 1'));
    }

    {
      var fragment = findNode.classDeclaration('A {} // 2').declaredFragment!;
      var result = await getFragmentDeclaration(fragment);
      var node = result!.node as ClassDeclaration;
      expect(node.name.lexeme, 'A');
      expect(node.name.offset, this.result.content.indexOf('A {} // 2'));
    }
  }

  test_class_inPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
class A {}
''');
    await resolveTestCode(r'''
part 'a.dart';
''');
    var fragment = findElement2.class_('A').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as ClassDeclaration;
    expect(node.name.lexeme, 'A');
  }

  test_class_missingName() async {
    await resolveTestCode('''
class {}
''');
    var fragment = findNode.classDeclaration('class {}').declaredFragment!;
    var result = await getFragmentDeclaration(fragment);
    // Without a name, the class declaration cannot be found.
    expect(result, null);
  }

  test_classTypeAlias() async {
    await resolveTestCode(r'''
mixin M {}
class A {}
class B = A with M;
''');
    var fragment = findElement2.class_('B').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as ClassTypeAlias;
    expect(node.name.lexeme, 'B');
  }

  test_constructor() async {
    await resolveTestCode(r'''
class A {
  A();
  A.named();
}
''');
    {
      var unnamed = findElement2.constructor('new').firstFragment;
      var result = await getFragmentDeclaration(unnamed);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name, isNull);
    }

    {
      var named = findElement2.constructor('named').firstFragment;
      var result = await getFragmentDeclaration(named);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name!.lexeme, 'named');
    }
  }

  test_constructor_duplicate_named() async {
    await resolveTestCode(r'''
class A {
  A.named(); // 1
  A.named(); // 2
}
''');
    {
      var element = findNode.constructor('A.named(); // 1').declaredFragment!;
      var result = await getFragmentDeclaration(element);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name!.lexeme, 'named');
      expect(node.name!.offset, this.result.content.indexOf('named(); // 1'));
    }

    {
      var element = findNode.constructor('A.named(); // 2').declaredFragment!;
      var result = await getFragmentDeclaration(element);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name!.lexeme, 'named');
      expect(node.name!.offset, this.result.content.indexOf('named(); // 2'));
    }
  }

  test_constructor_duplicate_unnamed() async {
    await resolveTestCode(r'''
class A {
  A(); // 1
  A(); // 2
}
''');
    {
      var element = findNode.constructor('A(); // 1').declaredFragment!;
      var result = await getFragmentDeclaration(element);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name, isNull);
      expect(node.returnType.offset, this.result.content.indexOf('A(); // 1'));
    }

    {
      var element = findNode.constructor('A(); // 2').declaredFragment!;
      var result = await getFragmentDeclaration(element);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name, isNull);
      expect(node.returnType.offset, this.result.content.indexOf('A(); // 2'));
    }
  }

  test_constructor_synthetic() async {
    await resolveTestCode(r'''
class A {}
''');
    var element = findElement2.unnamedConstructor('A').firstFragment;
    expect(element.isSynthetic, isTrue);

    var result = await getFragmentDeclaration(element);
    expect(result, isNull);
  }

  test_enum() async {
    await resolveTestCode(r'''
enum MyEnum {a, b, c}
''');
    var fragment = findElement2.enum_('MyEnum').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as EnumDeclaration;
    expect(node.name.lexeme, 'MyEnum');
  }

  test_enum_constant() async {
    await resolveTestCode(r'''
enum MyEnum {a, b, c}
''');
    var fragment = findElement2.field('a').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as EnumConstantDeclaration;
    expect(node.name.lexeme, 'a');
  }

  test_extension() async {
    await resolveTestCode(r'''
extension E on int {}
''');
    var fragment = findElement2.extension_('E').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as ExtensionDeclaration;
    expect(node.name!.lexeme, 'E');
  }

  test_field() async {
    await resolveTestCode(r'''
class C {
  int foo;
}
''');
    var fragment = findElement2.field('foo').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as VariableDeclaration;
    expect(node.name.lexeme, 'foo');
  }

  test_formalParameter() async {
    await resolveTestCode(r'''
void f(int a) {}
''');
    var fragment = findElement2.parameter('a').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as SimpleFormalParameter;
    expect(node.name!.lexeme, 'a');
  }

  test_formalParameter_missingName_named() async {
    await resolveTestCode(r'''
void f({@a}) {}
''');
    var f = findElement2.topFunction('f').firstFragment;
    var fragment = f.formalParameters.single;
    expect(fragment.name, isNull);
    expect(fragment.element.isNamed, isTrue);

    var result = await getFragmentDeclaration(fragment);
    // Without a name, the parameter declaration cannot be found.
    expect(result, null);
  }

  test_formalParameter_missingName_required() async {
    await resolveTestCode(r'''
void f(@a) {}
''');
    var f = findElement2.topFunction('f').firstFragment;
    var fragment = f.formalParameters.single;
    expect(fragment.name, isNull);
    expect(fragment.element.isPositional, isTrue);

    var result = await getFragmentDeclaration(fragment);
    // Without a name, the parameter declaration cannot be found.
    expect(result, null);
  }

  test_functionDeclaration_local() async {
    await resolveTestCode(r'''
main() {
  void foo() {}
}
''');
    var fragment = findElement2.localFunction('foo').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as FunctionDeclaration;
    expect(node.name.lexeme, 'foo');
  }

  test_functionDeclaration_top() async {
    await resolveTestCode(r'''
void foo() {}
''');
    var fragment = findElement2.topFunction('foo').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as FunctionDeclaration;
    expect(node.name.lexeme, 'foo');
  }

  test_genericFunctionTypeElement() async {
    await resolveTestCode(r'''
typedef F = void Function();
''');
    var typeAlias = findElement2.typeAlias('F');
    var fragment = typeAlias.aliasedElement!.firstFragment;
    var result = await getFragmentDeclaration(fragment);
    expect(result, isNull);
  }

  test_genericTypeAlias() async {
    await resolveTestCode(r'''
typedef A = List<int>;
''');
    var fragment = findElement2.typeAlias('A').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as GenericTypeAlias;
    expect(node.name.lexeme, 'A');
  }

  test_getter_class() async {
    await resolveTestCode(r'''
class A {
  int get x => 0;
}
''');
    var fragment = findElement2.getter('x').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as MethodDeclaration;
    expect(node.name.lexeme, 'x');
    expect(node.isGetter, isTrue);
  }

  test_getter_top() async {
    await resolveTestCode(r'''
int get x => 0;
''');
    var fragment = findElement2.topGet('x').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as FunctionDeclaration;
    expect(node.name.lexeme, 'x');
    expect(node.isGetter, isTrue);
  }

  test_libraryFragment() async {
    await resolveTestCode('');
    var fragment = this.result.libraryFragment;
    var result = await getFragmentDeclaration(fragment);
    expect(result, isNull);
  }

  test_localVariable() async {
    await resolveTestCode(r'''
main() {
  int foo;
}
''');
    var fragment = findElement2.localVar('foo').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as VariableDeclaration;
    expect(node.name.lexeme, 'foo');
  }

  test_method() async {
    await resolveTestCode(r'''
class C {
  void foo() {}
}
''');
    var fragment = findElement2.method('foo').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as MethodDeclaration;
    expect(node.name.lexeme, 'foo');
  }

  test_mixin() async {
    await resolveTestCode(r'''
mixin M {}
''');
    var fragment = findElement2.mixin('M').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as MixinDeclaration;
    expect(node.name.lexeme, 'M');
  }

  test_setter_class() async {
    await resolveTestCode(r'''
class A {
  set x(_) {}
}
''');
    var fragment = findElement2.setter('x').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as MethodDeclaration;
    expect(node.name.lexeme, 'x');
    expect(node.isSetter, isTrue);
  }

  test_setter_top() async {
    await resolveTestCode(r'''
set x(_) {}
''');
    var fragment = findElement2.topSet('x').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as FunctionDeclaration;
    expect(node.name.lexeme, 'x');
    expect(node.isSetter, isTrue);
  }

  test_topLevelVariable() async {
    await resolveTestCode(r'''
int foo;
''');
    var fragment = findElement2.topVar('foo').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as VariableDeclaration;
    expect(node.name.lexeme, 'foo');
  }

  test_topLevelVariable_synthetic() async {
    await resolveTestCode(r'''
int get foo => 0;
''');
    var fragment = findElement2.topVar('foo').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    expect(result, isNull);
  }
}

@reflectiveTest
class GetElementDeclarationParsedTest extends PubPackageResolutionTest
    with GetElementDeclarationMixin {
  @override
  Future<FragmentDeclarationResult?> getFragmentDeclaration(
    Fragment fragment,
  ) async {
    var library = fragment.element.library!;
    var path = library.firstFragment.source.fullName;
    var file = getFile(path);
    var parsedLibrary = await _getParsedLibrary(file);
    return parsedLibrary.getFragmentDeclaration(fragment);
  }

  Future<ParsedLibraryResult> _getParsedLibrary(File file) async {
    var session = contextFor(file).currentSession;
    return session.getParsedLibrary(file.path) as ParsedLibraryResult;
  }
}

@reflectiveTest
class GetElementDeclarationResolvedTest extends PubPackageResolutionTest
    with GetElementDeclarationMixin {
  @override
  Future<FragmentDeclarationResult?> getFragmentDeclaration(
    Fragment fragment,
  ) async {
    var library = fragment.element.library!;
    var path = library.firstFragment.source.fullName;
    var file = getFile(path);
    var resolvedLibrary = await _getResolvedLibrary(file);
    return resolvedLibrary.getFragmentDeclaration(fragment);
  }

  Future<ResolvedLibraryResult> _getResolvedLibrary(File file) async {
    var session = contextFor(file).currentSession;
    return await session.getResolvedLibrary(file.path) as ResolvedLibraryResult;
  }
}
