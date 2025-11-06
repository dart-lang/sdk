// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../src/dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FragmentOffsetTest);
  });
}

@reflectiveTest
class FragmentOffsetTest extends PubPackageResolutionTest {
  void checkOffset<F extends Fragment>(
    AstNode declaration,
    Fragment fragment,
    int expectedOffset,
  ) {
    var offset = checkOffsetInRange<F>(declaration, fragment);
    expect(offset, expectedOffset);
  }

  /// Checks that the offset is in the range of the declaration, but doesn't
  /// check the precise offset.
  ///
  /// Used in the case of error recovery, where the precise offset is
  /// unspecified.
  int checkOffsetInRange<F extends Fragment>(
    AstNode declaration,
    Fragment fragment,
  ) {
    expect(fragment, isA<F>());
    var offset = fragment.offset;
    expect(offset, greaterThanOrEqualTo(declaration.offset));
    expect(offset, lessThanOrEqualTo(declaration.end));
    return offset;
  }

  test_bindPatternVariableFragment() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore: unused_local_variable
  var (int i,) = (0,);
}
''');
    var declaredVariablePattern = findNode.declaredVariablePattern('int i');
    checkOffset<BindPatternVariableFragment>(
      declaredVariablePattern,
      declaredVariablePattern.declaredFragment!,
      declaredVariablePattern.name.offset,
    );
  }

  test_classFragment() async {
    await assertNoErrorsInCode(r'''
class C {}
''');
    var classDeclaration = findNode.classDeclaration('C');
    checkOffset<ClassFragment>(
      classDeclaration,
      classDeclaration.declaredFragment!,
      classDeclaration.name.offset,
    );
  }

  test_classFragment_classTypeAlias() async {
    await assertNoErrorsInCode(r'''
mixin M {}
class C = Object with M;
''');
    var classTypeAlias = findNode.classTypeAlias('C');
    checkOffset<ClassFragment>(
      classTypeAlias,
      classTypeAlias.declaredFragment!,
      classTypeAlias.name.offset,
    );
  }

  test_classFragment_classTypeAlias_missingName() async {
    await assertErrorsInCode(
      r'''
mixin M {}
class = Object with M;
''',
      [error(ParserErrorCode.missingIdentifier, 17, 1)],
    );
    var classTypeAlias = findNode.classTypeAlias('Object with M');
    checkOffsetInRange<ClassFragment>(
      classTypeAlias,
      classTypeAlias.declaredFragment!,
    );
  }

  test_classFragment_missingName() async {
    await assertErrorsInCode(
      r'''
library; // Ensures that the class declaration isn't at offset 0

class {}
''',
      [error(ParserErrorCode.missingIdentifier, 72, 1)],
    );
    var classDeclaration = findNode.classDeclaration('class {}');
    checkOffsetInRange<ClassFragment>(
      classDeclaration,
      classDeclaration.declaredFragment!,
    );
  }

  test_constructorFragment_implicit() async {
    await assertNoErrorsInCode(r'''
class C {}
''');
    var classDeclaration = findNode.classDeclaration('C');
    checkOffset<ConstructorFragment>(
      classDeclaration,
      classDeclaration
          .declaredFragment!
          .element
          .unnamedConstructor!
          .firstFragment,
      classDeclaration.name.offset,
    );
  }

  test_constructorFragment_missingName() async {
    await assertErrorsInCode(
      r'''
class C {
  C.();
}
''',
      [error(ParserErrorCode.missingIdentifier, 14, 1)],
    );
    var constructorDeclaration = findNode.constructor('C.()');
    checkOffsetInRange<ConstructorFragment>(
      constructorDeclaration,
      constructorDeclaration.declaredFragment!,
    );
  }

  test_constructorFragment_named() async {
    await assertNoErrorsInCode(r'''
class C {
  C.foo();
}
''');
    var constructorDeclaration = findNode.constructor('foo');
    checkOffset<ConstructorFragment>(
      constructorDeclaration,
      constructorDeclaration.declaredFragment!,
      constructorDeclaration.name!.offset,
    );
  }

  test_constructorFragment_unnamed() async {
    await assertNoErrorsInCode(r'''
class C {
  C();
}
''');
    var constructorDeclaration = findNode.constructor('C()');
    checkOffset<ConstructorFragment>(
      constructorDeclaration,
      constructorDeclaration.declaredFragment!,
      constructorDeclaration.returnType.offset,
    );
  }

  test_dynamicFragment() async {
    await assertNoErrorsInCode(r'''
dynamic d;
''');
    var namedType =
        findNode.topLevelVariableDeclaration('dynamic d').variables.type
            as NamedType;
    expect(namedType.element!.kind, ElementKind.DYNAMIC);
    // `dynamic` isn't defined in the source code anywhere, so its offset is 0.
    expect(namedType.element!.firstFragment.offset, 0);
  }

  test_enumFragment() async {
    await assertNoErrorsInCode(r'''
enum E { e1 }
''');
    var enumDeclaration = findNode.enumDeclaration('E');
    checkOffset<EnumFragment>(
      enumDeclaration,
      enumDeclaration.declaredFragment!,
      enumDeclaration.name.offset,
    );
  }

  test_enumFragment_missingName() async {
    await assertErrorsInCode(
      r'''
library; // Ensures that the enum declaration isn't at offset 0

enum { e1 }
''',
      [error(ParserErrorCode.missingIdentifier, 70, 1)],
    );
    var enumDeclaration = findNode.enumDeclaration('enum { e1 }');
    checkOffsetInRange<EnumFragment>(
      enumDeclaration,
      enumDeclaration.declaredFragment!,
    );
  }

  test_extensionFragment_named() async {
    await assertNoErrorsInCode(r'''
library; // Ensures that the extension declaration isn't at offset 0

/// Documentation comment
extension E on int {}
''');
    var extensionDeclaration = findNode.extensionDeclaration('on int');
    checkOffset<ExtensionFragment>(
      extensionDeclaration,
      extensionDeclaration.declaredFragment!,
      extensionDeclaration.name!.offset,
    );
  }

  test_extensionFragment_unnamed() async {
    await assertNoErrorsInCode(r'''
extension on int {}
''');
    var extensionDeclaration = findNode.extensionDeclaration('on int');
    checkOffset<ExtensionFragment>(
      extensionDeclaration,
      extensionDeclaration.declaredFragment!,
      extensionDeclaration.extensionKeyword.offset,
    );
  }

  test_extensionTypeFragment() async {
    await assertNoErrorsInCode(r'''
extension type E(int i) {}
''');
    var extensionTypeDeclaration = findNode.extensionTypeDeclaration('E');
    checkOffset<ExtensionTypeFragment>(
      extensionTypeDeclaration,
      extensionTypeDeclaration.declaredFragment!,
      extensionTypeDeclaration.name.offset,
    );
  }

  test_extensionTypeFragment_missingName() async {
    await assertErrorsInCode(
      r'''
library; // Ensures that the extension type declaration isn't at offset 0

extension type(int i) {}
''',
      [error(ParserErrorCode.missingIdentifier, 89, 1)],
    );
    var extensionTypeDeclaration = findNode.extensionTypeDeclaration(
      'extension type(int i)',
    );
    checkOffsetInRange<ExtensionTypeFragment>(
      extensionTypeDeclaration,
      extensionTypeDeclaration.declaredFragment!,
    );
  }

  test_fieldFormalParameterFragment() async {
    await assertNoErrorsInCode(r'''
class C {
  final int i;
  C(this.i);
}
''');
    var parameter = findNode.fieldFormalParameter('this.i');
    checkOffset<FieldFormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
      parameter.name.offset,
    );
  }

  test_fieldFormalParameterFragment_missingName() async {
    await assertErrorsInCode(
      r'''
class C {
  int? x;
  C(this.);
}
''',
      [
        error(
          CompileTimeErrorCode.initializingFormalForNonExistentField,
          24,
          5,
        ),
        error(ParserErrorCode.missingIdentifier, 29, 1),
      ],
    );
    var parameter = findNode.fieldFormalParameter('this.');
    checkOffsetInRange<FieldFormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
    );
  }

  test_fieldFormalParameterFragment_withDefaultValue() async {
    await assertNoErrorsInCode(r'''
class C {
  final int i;
  C({this.i = 0});
}
''');
    var parameter = findNode.fieldFormalParameter('this.i');
    checkOffset<FieldFormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
      parameter.name.offset,
    );
  }

  test_fieldFragment() async {
    await assertNoErrorsInCode(r'''
class C {
  int? x;
}
''');
    var fieldDeclaration = findNode.fieldDeclaration('x').fields.variables[0];
    checkOffset<FieldFragment>(
      fieldDeclaration,
      fieldDeclaration.declaredFragment!,
      fieldDeclaration.name.offset,
    );
  }

  test_fieldFragment_const() async {
    await assertNoErrorsInCode(r'''
class C {
  static const int x = 0;
}
''');
    var fieldDeclaration = findNode.fieldDeclaration('x').fields.variables[0];
    checkOffset<FieldFragment>(
      fieldDeclaration,
      fieldDeclaration.declaredFragment!,
      fieldDeclaration.name.offset,
    );
  }

  test_fieldFragment_enum_constant() async {
    await assertNoErrorsInCode(r'''
enum E { e1 }
''');
    var enumConstantDeclaration = findNode.enumConstantDeclaration('e1');
    checkOffset<FieldFragment>(
      enumConstantDeclaration,
      enumConstantDeclaration.declaredFragment!,
      enumConstantDeclaration.name.offset,
    );
  }

  test_fieldFragment_enum_values() async {
    await assertNoErrorsInCode(r'''
enum E { e1 }
''');
    var enumDeclaration = findNode.enumDeclaration('E');
    checkOffset<FieldFragment>(
      enumDeclaration,
      enumDeclaration.declaredFragment!.element
          .getField('values')!
          .firstFragment,
      enumDeclaration.name.offset,
    );
  }

  test_fieldFragment_extensionTypeRepresentationField() async {
    await assertNoErrorsInCode(r'''
extension type E(int i) {}
''');
    var representationDeclaration = findNode
        .extensionTypeDeclaration('int i')
        .representation;
    checkOffset<FieldFragment>(
      representationDeclaration,
      representationDeclaration.fieldFragment!,
      representationDeclaration.fieldName.offset,
    );
  }

  test_formalParameterFragment() async {
    await assertNoErrorsInCode(r'''
void f(int x) {}
''');
    var parameter = findNode.simpleFormalParameter('x');
    checkOffset<FormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
      parameter.name!.offset,
    );
  }

  test_formalParameterFragment_missingName() async {
    await assertErrorsInCode(
      r'''
void f((int x)) {}
''',
      [error(ParserErrorCode.missingIdentifier, 7, 1)],
    );
    var function = findNode.functionDeclaration('f(');
    var parameter =
        function.functionExpression.parameters!.parameters[0]
            as FunctionTypedFormalParameter;
    expect(parameter.name.isSynthetic, true);
    checkOffsetInRange<FormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
    );
  }

  test_formalParameterFragment_missingName2() async {
    await assertErrorsInCode(
      r'''
void f(void (int x)) {}
''',
      [error(ParserErrorCode.missingIdentifier, 12, 1)],
    );
    var function = findNode.functionDeclaration('f(');
    var parameter =
        function.functionExpression.parameters!.parameters[0]
            as FunctionTypedFormalParameter;
    expect(parameter.name.isSynthetic, true);
    checkOffsetInRange<FormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
    );
  }

  test_formalParameterFragment_ofImplicitSetter_member_implicit() async {
    await assertNoErrorsInCode(r'''
class C {
  int? x;
}
''');
    var fieldDeclaration = findNode.fieldDeclaration('x').fields.variables[0];
    checkOffset<FormalParameterFragment>(
      fieldDeclaration,
      (fieldDeclaration.declaredFragment as FieldFragment)
          .element
          .setter!
          .formalParameters
          .single
          .firstFragment,
      fieldDeclaration.name.offset,
    );
  }

  test_formalParameterFragment_ofImplicitSetter_topLevel_implicit() async {
    await assertNoErrorsInCode(r'''
int? x;
''');
    var topLevelVariableDeclaration = findNode
        .topLevelVariableDeclaration('x')
        .variables
        .variables[0];
    checkOffset<FormalParameterFragment>(
      topLevelVariableDeclaration,
      (topLevelVariableDeclaration.declaredFragment as TopLevelVariableFragment)
          .element
          .setter!
          .formalParameters
          .single
          .firstFragment,
      topLevelVariableDeclaration.name.offset,
    );
  }

  test_formalParameterFragment_withDefaultValue() async {
    await assertNoErrorsInCode(r'''
void f({int x = 0}) {}
''');
    var parameter = findNode.simpleFormalParameter('x');
    checkOffset<FormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
      parameter.name!.offset,
    );
  }

  test_genericFunctionTypeFragment() async {
    await assertNoErrorsInCode(r'''
library; // Ensures that the generic function type isn't at offset 0

void Function(int x)? f;
''');
    var genericFunctionType = findNode.genericFunctionType(
      'void Function(int x)?',
    );
    checkOffset<GenericFunctionTypeFragment>(
      genericFunctionType,
      genericFunctionType.declaredFragment!,
      genericFunctionType.offset,
    );
  }

  test_getterFragment_member() async {
    await assertNoErrorsInCode(r'''
class C {
  int get foo => 0;
}
''');
    var getterDeclaration = findNode.methodDeclaration('foo');
    checkOffset<GetterFragment>(
      getterDeclaration,
      getterDeclaration.declaredFragment!,
      getterDeclaration.name.offset,
    );
  }

  test_getterFragment_member_implicit() async {
    await assertNoErrorsInCode(r'''
class C {
  int? x;
}
''');
    var fieldDeclaration = findNode.fieldDeclaration('x').fields.variables[0];
    checkOffset<GetterFragment>(
      fieldDeclaration,
      (fieldDeclaration.declaredFragment as FieldFragment)
          .element
          .getter!
          .firstFragment,
      fieldDeclaration.name.offset,
    );
  }

  test_getterFragment_topLevel() async {
    await assertNoErrorsInCode(r'''
int get foo => 0;
''');
    var getterDeclaration = findNode.functionDeclaration('foo');
    checkOffset<GetterFragment>(
      getterDeclaration,
      getterDeclaration.declaredFragment!,
      getterDeclaration.name.offset,
    );
  }

  test_getterFragment_topLevel_implicit() async {
    await assertNoErrorsInCode(r'''
int? x;
''');
    var topLevelVariableDeclaration = findNode
        .topLevelVariableDeclaration('x')
        .variables
        .variables[0];
    checkOffset<GetterFragment>(
      topLevelVariableDeclaration,
      (topLevelVariableDeclaration.declaredFragment as TopLevelVariableFragment)
          .element
          .getter!
          .firstFragment,
      topLevelVariableDeclaration.name.offset,
    );
  }

  test_joinPatternVariableFragment() async {
    await assertNoErrorsInCode(r'''
void f() {
  switch ((0,) as dynamic) {
    // ignore: unused_local_variable
    case (var i,) || (:var i,):
      break;
  }
}
''');
    var firstDeclaredVariablePattern = findNode.declaredVariablePattern(
      'var i,) ||',
    );
    checkOffset<JoinPatternVariableFragment>(
      firstDeclaredVariablePattern,
      firstDeclaredVariablePattern.declaredFragment!.join!,
      firstDeclaredVariablePattern.name.offset,
    );
  }

  test_labelFragment() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore: unused_label
  L: while(true) {}
}
''');
    var label = findNode.label('L');
    checkOffset<LabelFragment>(
      label,
      label.declaredFragment!,
      label.label.offset,
    );
  }

  test_libraryFragment_first_named() async {
    await assertNoErrorsInCode(r'''
// Comment to ensure that the library declaration isn't at offset 0
library L;

class C {}
''');
    var unit = findNode.unit;
    checkOffset<LibraryFragment>(
      unit,
      unit.declaredFragment!,
      findNode.library('L').name!.offset,
    );
  }

  test_libraryFragment_first_unnamed_withLibraryDeclaration() async {
    await assertNoErrorsInCode(r'''
// Comment to ensure that the library declaration isn't at offset 0
library;

class C {}
''');
    var unit = findNode.unit;
    checkOffset<LibraryFragment>(unit, unit.declaredFragment!, 0);
  }

  test_libraryFragment_first_unnamed_withoutLibraryDeclaration() async {
    await assertNoErrorsInCode(r'''
// Comment to ensure that the class declaration isn't at offset 0
class C {}
''');
    var unit = findNode.unit;
    checkOffset<LibraryFragment>(unit, unit.declaredFragment!, 0);
  }

  test_libraryFragment_notFirst_named() async {
    newFile('$testPackageLibPath/lib.dart', r'''
library L;

part 'part.dart';
''');
    newFile('$testPackageLibPath/part.dart', r'''
// Comment to ensure that the "part of" declaration isn't at offset 0
part of 'lib.dart';

class C {}
''');
    await resolveFile2(getFile('$testPackageLibPath/part.dart'));
    assertErrorsInResolvedUnit(result, const []);

    var unit = findNode.unit;
    checkOffset<LibraryFragment>(unit, unit.declaredFragment!, 0);
  }

  test_libraryFragment_notFirst_unnamed() async {
    newFile('$testPackageLibPath/lib.dart', r'''
part 'part.dart';
''');
    newFile('$testPackageLibPath/part.dart', r'''
// Comment to ensure that the "part of" declaration isn't at offset 0
part of 'lib.dart';

class C {}
''');
    await resolveFile2(getFile('$testPackageLibPath/part.dart'));
    assertErrorsInResolvedUnit(result, const []);

    var unit = findNode.unit;
    checkOffset<LibraryFragment>(unit, unit.declaredFragment!, 0);
  }

  test_local_variable_fragment() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore: unused_local_variable
  int i = 0;
}
''');
    var localVariable = findNode.variableDeclaration('i = 0');
    checkOffset<LocalVariableFragment>(
      localVariable,
      localVariable.declaredFragment!,
      localVariable.name.offset,
    );
  }

  test_local_variable_fragment_const() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore: unused_local_variable
  const int i = 0;
}
''');
    var localVariable = findNode.variableDeclaration('i = 0');
    checkOffset<LocalVariableFragment>(
      localVariable,
      localVariable.declaredFragment!,
      localVariable.name.offset,
    );
  }

  test_localFunctionFragment_named() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore: unused_element
  void g() {}
}
''');
    var localFunction = findNode
        .functionDeclarationStatement('g()')
        .functionDeclaration;
    checkOffset<LocalFunctionFragment>(
      localFunction,
      localFunction.declaredFragment!,
      localFunction.name.offset,
    );
  }

  test_localFunctionFragment_unnamed() async {
    await assertNoErrorsInCode(r'''
dynamic f() {
  return () {};
}
''');
    var localFunction = findNode.functionExpression('() {}');
    checkOffset<LocalFunctionFragment>(
      localFunction,
      localFunction.declaredFragment!,
      localFunction.parameters!.leftParenthesis.offset,
    );
  }

  test_methodFragment() async {
    await assertNoErrorsInCode(r'''
class C {
  void foo() {}
}
''');
    var methodDeclaration = findNode.methodDeclaration('foo');
    checkOffset<MethodFragment>(
      methodDeclaration,
      methodDeclaration.declaredFragment!,
      methodDeclaration.name.offset,
    );
  }

  test_mixinFragment() async {
    await assertNoErrorsInCode(r'''
mixin M {}
''');
    var mixinDeclaration = findNode.mixinDeclaration('M');
    checkOffset<MixinFragment>(
      mixinDeclaration,
      mixinDeclaration.declaredFragment!,
      mixinDeclaration.name.offset,
    );
  }

  test_mixinFragment_missingName() async {
    await assertErrorsInCode(
      r'''
library; // Ensures that the mixin declaration isn't at offset 0

mixin {}
''',
      [error(ParserErrorCode.missingIdentifier, 72, 1)],
    );
    var mixinDeclaration = findNode.mixinDeclaration('mixin {}');
    checkOffsetInRange<MixinFragment>(
      mixinDeclaration,
      mixinDeclaration.declaredFragment!,
    );
  }

  test_neverFragment() async {
    await assertNoErrorsInCode(r'''
Never n = throw '';
''');
    var namedType =
        findNode.topLevelVariableDeclaration('Never n').variables.type
            as NamedType;
    expect(namedType.element!.kind, ElementKind.NEVER);
    // `Never` isn't defined in the source code anywhere, so its offset is 0.
    expect(namedType.element!.firstFragment.offset, 0);
  }

  test_prefixFragment() async {
    await assertNoErrorsInCode(r'''
// ignore: unused_import
import 'dart:async' as a;
''');
    var importDirective = findNode.import('as a');
    checkOffset<PrefixFragment>(
      importDirective,
      importDirective.libraryImport!.prefix!,
      importDirective.prefix!.offset,
    );
  }

  test_prefixFragment_inMultipleImports() async {
    await assertNoErrorsInCode(r'''
// ignore: unused_import
import 'dart:async' as a; // first
// ignore: unused_import
import 'dart:math' as a; // second
''');
    var firstImportDirective = findNode.import('as a; // first');
    checkOffset<PrefixFragment>(
      firstImportDirective,
      firstImportDirective.libraryImport!.prefix!,
      firstImportDirective.prefix!.offset,
    );
  }

  test_prefixFragment_missingName() async {
    await assertErrorsInCode(
      r'''
// ignore: unused_import
import 'dart:async' as;
''',
      [error(ParserErrorCode.missingIdentifier, 47, 1)],
    );
    var importDirective = findNode.import('as;');
    checkOffsetInRange<PrefixFragment>(
      importDirective,
      importDirective.libraryImport!.prefix!,
    );
  }

  test_setterFragment_member() async {
    await assertNoErrorsInCode(r'''
class C {
  set foo(int value) {}
}
''');
    var setterDeclaration = findNode.methodDeclaration('foo');
    checkOffset<SetterFragment>(
      setterDeclaration,
      setterDeclaration.declaredFragment!,
      setterDeclaration.name.offset,
    );
  }

  test_setterFragment_member_implicit() async {
    await assertNoErrorsInCode(r'''
class C {
  int? x;
}
''');
    var fieldDeclaration = findNode.fieldDeclaration('x').fields.variables[0];
    checkOffset<SetterFragment>(
      fieldDeclaration,
      (fieldDeclaration.declaredFragment as FieldFragment)
          .element
          .setter!
          .firstFragment,
      fieldDeclaration.name.offset,
    );
  }

  test_setterFragment_topLevel() async {
    await assertNoErrorsInCode(r'''
set foo(int value) {}
''');
    var setterDeclaration = findNode.functionDeclaration('foo');
    checkOffset<SetterFragment>(
      setterDeclaration,
      setterDeclaration.declaredFragment!,
      setterDeclaration.name.offset,
    );
  }

  test_setterFragment_topLevel_implicit() async {
    await assertNoErrorsInCode(r'''
int? x;
''');
    var topLevelVariableDeclaration = findNode
        .topLevelVariableDeclaration('x')
        .variables
        .variables[0];
    checkOffset<SetterFragment>(
      topLevelVariableDeclaration,
      (topLevelVariableDeclaration.declaredFragment as TopLevelVariableFragment)
          .element
          .setter!
          .firstFragment,
      topLevelVariableDeclaration.name.offset,
    );
  }

  test_superFormalParameterFragment() async {
    await assertNoErrorsInCode(r'''
class B {
  B(int i);
}

class C extends B {
  C(super.i);
}
''');
    var parameter = findNode.superFormalParameter('super.i');
    checkOffset<SuperFormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
      parameter.name.offset,
    );
  }

  test_superFormalParameterFragment_missingName() async {
    await assertErrorsInCode(
      r'''
class B {
  B([int? i]);
}

class C extends B {
  C(super.);
}
''',
      [error(ParserErrorCode.missingIdentifier, 58, 1)],
    );
    var parameter = findNode.superFormalParameter('super.');
    checkOffsetInRange<SuperFormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
    );
  }

  test_superFormalParameterFragment_withDefaultValue() async {
    await assertNoErrorsInCode(r'''
class B {
  B({int? i});
}

class C extends B {
  C({super.i = 0});
}
''');
    var parameter = findNode.superFormalParameter('super.i');
    checkOffset<SuperFormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
      parameter.name.offset,
    );
  }

  test_topLevelFunctionFragment() async {
    await assertNoErrorsInCode(r'''
void foo() {}
''');
    var topLevelFunctionDeclaration = findNode.functionDeclaration('foo');
    checkOffset<TopLevelFunctionFragment>(
      topLevelFunctionDeclaration,
      topLevelFunctionDeclaration.declaredFragment!,
      topLevelFunctionDeclaration.name.offset,
    );
  }

  test_topLevelVariableFragment() async {
    await assertNoErrorsInCode(r'''
int? x;
''');
    var topLevelVariableDeclaration = findNode
        .topLevelVariableDeclaration('x')
        .variables
        .variables[0];
    checkOffset<TopLevelVariableFragment>(
      topLevelVariableDeclaration,
      topLevelVariableDeclaration.declaredFragment!,
      topLevelVariableDeclaration.name.offset,
    );
  }

  test_topLevelVariableFragment_const() async {
    await assertNoErrorsInCode(r'''
const int x = 0;
''');
    var topLevelVariableDeclaration = findNode
        .topLevelVariableDeclaration('x')
        .variables
        .variables[0];
    checkOffset<TopLevelVariableFragment>(
      topLevelVariableDeclaration,
      topLevelVariableDeclaration.declaredFragment!,
      topLevelVariableDeclaration.name.offset,
    );
  }

  test_typeAliasFragment_functionTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef void F();
''');
    var functionTypeAlias = findNode.functionTypeAlias('F');
    checkOffset<TypeAliasFragment>(
      functionTypeAlias,
      functionTypeAlias.declaredFragment!,
      functionTypeAlias.name.offset,
    );
  }

  test_typeAliasFragment_functionTypeAlias_missingName() async {
    await assertErrorsInCode(
      r'''
library; // Ensures that the function type alias declaration isn't at offset 0

typedef void();
''',
      [
        error(WarningCode.unusedElement, 0, 0),
        error(ParserErrorCode.missingIdentifier, 92, 1),
      ],
    );
    var functionTypeAlias = findNode.functionTypeAlias('void()');
    checkOffsetInRange<TypeAliasFragment>(
      functionTypeAlias,
      functionTypeAlias.declaredFragment!,
    );
  }

  test_typeAliasFragment_genericTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef T = int;
''');
    var genericTypeAlias = findNode.genericTypeAlias('T');
    checkOffset<TypeAliasFragment>(
      genericTypeAlias,
      genericTypeAlias.declaredFragment!,
      genericTypeAlias.name.offset,
    );
  }

  test_typeAliasFragment_genericTypeAlias_missingName() async {
    await assertErrorsInCode(
      r'''
library; // Ensures that the generic type alias declaration isn't at offset 0

typedef = int;
''',
      [
        error(WarningCode.unusedElement, 0, 0),
        error(ParserErrorCode.missingIdentifier, 87, 1),
      ],
    );
    var genericTypeAlias = findNode.genericTypeAlias('= int');
    checkOffsetInRange<TypeAliasFragment>(
      genericTypeAlias,
      genericTypeAlias.declaredFragment!,
    );
  }

  test_typeParameterFragment() async {
    await assertNoErrorsInCode(r'''
class C<T> {}
''');
    var typeParameter = findNode.typeParameter('T');
    checkOffset<TypeParameterFragment>(
      typeParameter,
      typeParameter.declaredFragment!,
      typeParameter.name.offset,
    );
  }
}
