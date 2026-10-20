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

  Future<FragmentDeclarationResult?> getFragmentDeclaration2(Fragment fragment);

  test_class() async {
    var unitResult = await resolveTestCode(r'''
class A {}
''');
    var fragment = unitResult.findNode.classDeclaration('A').declaredFragment!;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as ClassDeclaration;
    expect(node.namePart.typeName.lexeme, 'A');
  }

  test_class_duplicate() async {
    var unitResult = await resolveTestCode(r'''
class A {} // 1
class A {} // 2
''');
    {
      var fragment = unitResult.findNode
          .classDeclaration('A {} // 1')
          .declaredFragment!;
      var result = await getFragmentDeclaration(fragment);
      var node = result!.node as ClassDeclaration;
      expect(node.namePart.typeName.lexeme, 'A');
      expect(
        node.namePart.typeName.offset,
        unitResult.content.indexOf('A {} // 1'),
      );
    }

    {
      var fragment = unitResult.findNode
          .classDeclaration('A {} // 2')
          .declaredFragment!;
      var result = await getFragmentDeclaration(fragment);
      var node = result!.node as ClassDeclaration;
      expect(node.namePart.typeName.lexeme, 'A');
      expect(
        node.namePart.typeName.offset,
        unitResult.content.indexOf('A {} // 2'),
      );
    }
  }

  test_class_inPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
class A {}
''');
    var unitResult = await resolveTestCode(r'''
part 'a.dart';
''');
    var fragment = unitResult.findElement.class_('A').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as ClassDeclaration;
    expect(node.namePart.typeName.lexeme, 'A');
  }

  test_class_missingName() async {
    var unitResult = await resolveTestCode('''
class {}
''');
    var fragment = unitResult.findNode
        .classDeclaration('class {}')
        .declaredFragment!;
    var result = await getFragmentDeclaration(fragment);
    // Without a name, the class declaration cannot be found.
    expect(result, null);
  }

  test_classTypeAlias() async {
    var unitResult = await resolveTestCode(r'''
mixin M {}
class A {}
class B = A with M;
''');
    var fragment = unitResult.findElement.class_('B').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as ClassTypeAlias;
    expect(node.name.lexeme, 'B');
  }

  test_classTypeAlias_v2() async {
    var unitResult = await resolveTestCode(r'''
mixin M {}
class A {}
class B = A with M;
''');
    var fragment = unitResult.findElement.class_('B').firstFragment;
    var result = await getFragmentDeclaration2(fragment);
    assertParsedNodeText(result!.node, r'''
ClassTypeAlias2
  classKeyword: class
  name: B
  equals: =
  superclass: NamedType
    name: A
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: M
  body: SemicolonInstanceDeclarationBody
    semicolon: ;
V1: ClassTypeAlias
  typedefKeyword: class
  name: B
  equals: =
  superclass: NamedType
    name: A
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: M
  semicolon: ;
''');
  }

  test_constructor() async {
    var unitResult = await resolveTestCode(r'''
class A {
  A();
  A.named();
}
''');
    {
      var unnamed = unitResult.findElement.constructor('new').firstFragment;
      var result = await getFragmentDeclaration(unnamed);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name, isNull);
    }

    {
      var named = unitResult.findElement.constructor('named').firstFragment;
      var result = await getFragmentDeclaration(named);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name!.lexeme, 'named');
    }
  }

  test_constructor_duplicate_named() async {
    var unitResult = await resolveTestCode(r'''
class A {
  A.named(); // 1
  A.named(); // 2
}
''');
    {
      var element = unitResult.findNode
          .constructor('A.named(); // 1')
          .declaredFragment!;
      var result = await getFragmentDeclaration(element);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name!.lexeme, 'named');
      expect(node.name!.offset, unitResult.content.indexOf('named(); // 1'));
    }

    {
      var element = unitResult.findNode
          .constructor('A.named(); // 2')
          .declaredFragment!;
      var result = await getFragmentDeclaration(element);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name!.lexeme, 'named');
      expect(node.name!.offset, unitResult.content.indexOf('named(); // 2'));
    }
  }

  test_constructor_duplicate_unnamed() async {
    var unitResult = await resolveTestCode(r'''
class A {
  A(); // 1
  A(); // 2
}
''');
    {
      var element = unitResult.findNode
          .constructor('A(); // 1')
          .declaredFragment!;
      var result = await getFragmentDeclaration(element);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name, isNull);
      expect(node.typeName2!.offset, unitResult.content.indexOf('A(); // 1'));
    }

    {
      var element = unitResult.findNode
          .constructor('A(); // 2')
          .declaredFragment!;
      var result = await getFragmentDeclaration(element);
      var node = result!.node as ConstructorDeclaration;
      expect(node.name, isNull);
      expect(node.typeName2!.offset, unitResult.content.indexOf('A(); // 2'));
    }
  }

  test_constructor_synthetic() async {
    var unitResult = await resolveTestCode(r'''
class A {}
''');
    var element = unitResult.findElement.unnamedConstructor('A');
    expect(element.isOriginImplicitDefault, isTrue);

    var fragment = element.firstFragment;
    var result = await getFragmentDeclaration(fragment);
    expect(result, isNull);
  }

  test_constructor_v2() async {
    var unitResult = await resolveTestCode(r'''
class A {
  A.named(int a);
}
''');
    var fragment = unitResult.findElement.constructor('named').firstFragment;
    var result = await getFragmentDeclaration2(fragment);
    assertParsedNodeText(result!.node, r'''
ConstructorDeclaration2
  typeName: A
  period: .
  name: named
  formalParameters: FormalParameterList
    leftParenthesis: (
    requiredPositionalFormalParameters
      RegularFormalParameter
        type: NamedType
          name: int
        name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
V1: ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  period: .
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: int
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_enum() async {
    var unitResult = await resolveTestCode(r'''
enum MyEnum {a, b, c}
''');
    var fragment = unitResult.findElement.enum_('MyEnum').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as EnumDeclaration;
    expect(node.namePart.typeName.lexeme, 'MyEnum');
  }

  test_enum_constant() async {
    var unitResult = await resolveTestCode(r'''
enum MyEnum {a, b, c}
''');
    var fragment = unitResult.findElement.field('a').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as EnumConstantDeclaration;
    expect(node.name.lexeme, 'a');
  }

  test_enum_v2() async {
    var unitResult = await resolveTestCode(r'''
enum E {
  v;
  void foo() {}
}
''');
    var fragment = unitResult.findElement.enum_('E').firstFragment;
    var result = await getFragmentDeclaration2(fragment);
    assertParsedNodeText(result!.node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    membersSeparator: ;
    members
      MethodDeclaration2
        returnType: NamedType
          name: void
        name: foo
        formalParameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
V1: EnumDeclaration
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    semicolon: ;
    members
      MethodDeclaration
        returnType: NamedType
          name: void
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
''');
  }

  test_extension() async {
    var unitResult = await resolveTestCode(r'''
extension E on int {}
''');
    var fragment = unitResult.findElement.extension_('E').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as ExtensionDeclaration;
    expect(node.name!.lexeme, 'E');
  }

  test_extension_v2() async {
    var unitResult = await resolveTestCode(r'''
extension E on int {
  void foo() {}
}
''');
    var fragment = unitResult.findElement.extension_('E').firstFragment;
    var result = await getFragmentDeclaration2(fragment);
    assertParsedNodeText(result!.node, r'''
ExtensionDeclaration2
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockInstanceDeclarationBody
    leftBracket: {
    members
      MethodDeclaration2
        returnType: NamedType
          name: void
        name: foo
        formalParameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
V1: ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        returnType: NamedType
          name: void
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
''');
  }

  test_field() async {
    var unitResult = await resolveTestCode(r'''
class C {
  int foo;
}
''');
    var fragment = unitResult.findElement.field('foo').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as VariableDeclaration;
    expect(node.name.lexeme, 'foo');
  }

  test_formalParameter() async {
    var unitResult = await resolveTestCode(r'''
void f(int a) {}
''');
    var fragment = unitResult.findElement.parameter('a').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as RegularFormalParameter;
    expect(node.name!.lexeme, 'a');
  }

  test_formalParameter_missingName_named() async {
    var unitResult = await resolveTestCode(r'''
void f({@a}) {}
''');
    var f = unitResult.findElement.topFunction('f').firstFragment;
    var fragment = f.formalParameters.single;
    expect(fragment.name, isNull);
    expect(fragment.element.isNamed, isTrue);

    var result = await getFragmentDeclaration(fragment);
    // Without a name, the parameter declaration cannot be found.
    expect(result, null);
  }

  test_formalParameter_missingName_required() async {
    var unitResult = await resolveTestCode(r'''
void f(@a) {}
''');
    var f = unitResult.findElement.topFunction('f').firstFragment;
    var fragment = f.formalParameters.single;
    expect(fragment.name, isNull);
    expect(fragment.element.isPositional, isTrue);

    var result = await getFragmentDeclaration(fragment);
    // Without a name, the parameter declaration cannot be found.
    expect(result, null);
  }

  test_functionDeclaration_local() async {
    var unitResult = await resolveTestCode(r'''
main() {
  void foo() {}
}
''');
    var fragment = unitResult.findElement.localFunction('foo').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as FunctionDeclaration;
    expect(node.name.lexeme, 'foo');
  }

  test_functionDeclaration_top() async {
    var unitResult = await resolveTestCode(r'''
void foo() {}
''');
    var fragment = unitResult.findElement.topFunction('foo').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as FunctionDeclaration;
    expect(node.name.lexeme, 'foo');
  }

  test_genericFunctionTypeFragment() async {
    var unitResult = await resolveTestCode(r'''
void f(void Function() x) {}
''');
    var fragment =
        unitResult.findNode.singleGenericFunctionType.declaredFragment!;
    var result = await getFragmentDeclaration(fragment);
    expect(result, isNull);
  }

  test_genericTypeAlias() async {
    var unitResult = await resolveTestCode(r'''
typedef A = List<int>;
''');
    var fragment = unitResult.findElement.typeAlias('A').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as GenericTypeAlias;
    expect(node.name.lexeme, 'A');
  }

  test_genericTypeAlias_v2() async {
    var unitResult = await resolveTestCode(r'''
typedef A = List<int>;
''');
    var fragment = unitResult.findElement.typeAlias('A').firstFragment;
    var result = await getFragmentDeclaration2(fragment);
    assertParsedNodeText(result!.node, r'''
GenericTypeAlias2
  typedefKeyword: typedef
  name: A
  equals: =
  type: NamedType
    name: List
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
  semicolon: ;
V1: GenericTypeAlias
  typedefKeyword: typedef
  name: A
  equals: =
  type: NamedType
    name: List
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
  semicolon: ;
''');
  }

  test_getter_class() async {
    var unitResult = await resolveTestCode(r'''
class A {
  int get x => 0;
}
''');
    var fragment = unitResult.findElement.getter('x').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as MethodDeclaration;
    expect(node.name.lexeme, 'x');
    expect(node.isGetter, isTrue);
  }

  test_getter_class_v2() async {
    var unitResult = await resolveTestCode(r'''
class A {
  int get x => 0;
}
''');
    var fragment = unitResult.findElement.getter('x').firstFragment;
    var result = await getFragmentDeclaration2(fragment);
    assertParsedNodeText(result!.node, r'''
GetterDeclaration
  returnType: NamedType
    name: int
  getKeyword: get
  name: x
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression2: IntegerLiteral
      literal: 0
    semicolon: ;
V1: MethodDeclaration
  returnType: NamedType
    name: int
  propertyKeyword: get
  name: x
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: IntegerLiteral
      literal: 0
    semicolon: ;
''');
  }

  test_getter_top() async {
    var unitResult = await resolveTestCode(r'''
int get x => 0;
''');
    var fragment = unitResult.findElement.topGet('x').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as FunctionDeclaration;
    expect(node.name.lexeme, 'x');
    expect(node.isGetter, isTrue);
  }

  test_getter_top_v2() async {
    var unitResult = await resolveTestCode(r'''
int get x => 0;
''');
    var fragment = unitResult.findElement.topGet('x').firstFragment;
    var result = await getFragmentDeclaration2(fragment);
    assertParsedNodeText(result!.node, r'''
TopLevelGetterDeclaration
  returnType: NamedType
    name: int
  getKeyword: get
  name: x
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression2: IntegerLiteral
      literal: 0
    semicolon: ;
V1: FunctionDeclaration
  returnType: NamedType
    name: int
  propertyKeyword: get
  name: x
  functionExpression: FunctionExpression
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: IntegerLiteral
        literal: 0
      semicolon: ;
''');
  }

  test_libraryFragment() async {
    var unitResult = await resolveTestCode('');
    var fragment = unitResult.libraryFragment;
    var result = await getFragmentDeclaration(fragment);
    expect(result, isNull);
  }

  test_localVariable() async {
    var unitResult = await resolveTestCode(r'''
main() {
  int foo;
}
''');
    var fragment = unitResult.findElement.localVar('foo').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as VariableDeclaration;
    expect(node.name.lexeme, 'foo');
  }

  test_method() async {
    var unitResult = await resolveTestCode(r'''
class C {
  void foo() {}
}
''');
    var fragment = unitResult.findElement.method('foo').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as MethodDeclaration;
    expect(node.name.lexeme, 'foo');
  }

  test_method_v2() async {
    var unitResult = await resolveTestCode(r'''
class C {
  void foo() {}
}
''');
    var fragment = unitResult.findElement.method('foo').firstFragment;
    var result = await getFragmentDeclaration2(fragment);
    assertParsedNodeText(result!.node, r'''
MethodDeclaration2
  returnType: NamedType
    name: void
  name: foo
  formalParameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
V1: MethodDeclaration
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_mixin() async {
    var unitResult = await resolveTestCode(r'''
mixin M {}
''');
    var fragment = unitResult.findElement.mixin('M').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as MixinDeclaration;
    expect(node.name.lexeme, 'M');
  }

  test_mixin_v2() async {
    var unitResult = await resolveTestCode(r'''
mixin M on Object {
  void foo() {}
}
''');
    var fragment = unitResult.findElement.mixin('M').firstFragment;
    var result = await getFragmentDeclaration2(fragment);
    assertParsedNodeText(result!.node, r'''
MixinDeclaration2
  mixinKeyword: mixin
  name: M
  onClause: MixinOnClause
    onKeyword: on
    superclassConstraints
      NamedType
        name: Object
  body: BlockInstanceDeclarationBody
    leftBracket: {
    members
      MethodDeclaration2
        returnType: NamedType
          name: void
        name: foo
        formalParameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
V1: MixinDeclaration
  mixinKeyword: mixin
  name: M
  onClause: MixinOnClause
    onKeyword: on
    superclassConstraints
      NamedType
        name: Object
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        returnType: NamedType
          name: void
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
''');
  }

  test_operator() async {
    var unitResult = await resolveTestCode(r'''
class C {
  C operator +(C other) => this;
}
''');
    var fragment = unitResult.findElement.method('+').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as MethodDeclaration;
    expect(node.name.lexeme, '+');
    expect(node.isOperator, isTrue);
  }

  test_operator_v2() async {
    var unitResult = await resolveTestCode(r'''
class C {
  C operator +(C other) => this;
}
''');
    var fragment = unitResult.findElement.method('+').firstFragment;
    var result = await getFragmentDeclaration2(fragment);
    assertParsedNodeText(result!.node, r'''
OperatorDeclaration
  returnType: NamedType
    name: C
  operatorKeyword: operator
  operator: +
  formalParameters: FormalParameterList
    leftParenthesis: (
    requiredPositionalFormalParameters
      RegularFormalParameter
        type: NamedType
          name: C
        name: other
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression2: ThisExpression
      thisKeyword: this
    semicolon: ;
V1: MethodDeclaration
  returnType: NamedType
    name: C
  operatorKeyword: operator
  name: +
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: C
      name: other
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: ThisExpression
      thisKeyword: this
    semicolon: ;
''');
  }

  test_setter_class() async {
    var unitResult = await resolveTestCode(r'''
class A {
  set x(_) {}
}
''');
    var fragment = unitResult.findElement.setter('x').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as MethodDeclaration;
    expect(node.name.lexeme, 'x');
    expect(node.isSetter, isTrue);
  }

  test_setter_class_v2() async {
    var unitResult = await resolveTestCode(r'''
class A {
  set x(_) {}
}
''');
    var fragment = unitResult.findElement.setter('x').firstFragment;
    var result = await getFragmentDeclaration2(fragment);
    assertParsedNodeText(result!.node, r'''
SetterDeclaration
  setKeyword: set
  name: x
  formalParameters: FormalParameterList
    leftParenthesis: (
    requiredPositionalFormalParameters
      RegularFormalParameter
        name: _
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
V1: MethodDeclaration
  propertyKeyword: set
  name: x
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      name: _
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_setter_top() async {
    var unitResult = await resolveTestCode(r'''
set x(_) {}
''');
    var fragment = unitResult.findElement.topSet('x').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as FunctionDeclaration;
    expect(node.name.lexeme, 'x');
    expect(node.isSetter, isTrue);
  }

  test_topLevelVariable() async {
    var unitResult = await resolveTestCode(r'''
int foo;
''');
    var fragment = unitResult.findElement.topVar('foo').firstFragment;
    var result = await getFragmentDeclaration(fragment);
    var node = result!.node as VariableDeclaration;
    expect(node.name.lexeme, 'foo');
  }

  test_topLevelVariable_synthetic() async {
    var unitResult = await resolveTestCode(r'''
int get foo => 0;
''');
    var fragment = unitResult.findElement.topVar('foo').firstFragment;
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

  @override
  Future<FragmentDeclarationResult?> getFragmentDeclaration2(
    Fragment fragment,
  ) async {
    var library = fragment.element.library!;
    var path = library.firstFragment.source.fullName;
    var file = getFile(path);
    var parsedLibrary = await _getParsedLibrary(file);
    return parsedLibrary.getFragmentDeclaration2(fragment);
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

  @override
  Future<FragmentDeclarationResult?> getFragmentDeclaration2(
    Fragment fragment,
  ) async {
    var library = fragment.element.library!;
    var path = library.firstFragment.source.fullName;
    var file = getFile(path);
    var resolvedLibrary = await _getResolvedLibrary(file);
    return resolvedLibrary.getFragmentDeclaration2(fragment);
  }

  Future<ResolvedLibraryResult> _getResolvedLibrary(File file) async {
    var session = contextFor(file).currentSession;
    return await session.getResolvedLibrary(file.path) as ResolvedLibraryResult;
  }
}
