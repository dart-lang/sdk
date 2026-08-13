// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../src/dart/resolution/context_collection_resolution.dart';
import '../../src/dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FragmentOffsetTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore: unused_local_variable
  var (int i,) = (0,);
}
''');
    var declaredVariablePattern = result.findNode.declaredVariablePattern(
      'int i',
    );
    checkOffset<BindPatternVariableFragment>(
      declaredVariablePattern,
      declaredVariablePattern.declaredFragment!,
      declaredVariablePattern.name.offset,
    );
  }

  test_classFragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}
''');
    var classDeclaration = result.findNode.classDeclaration('C');
    checkOffset<ClassFragment>(
      classDeclaration,
      classDeclaration.declaredFragment!,
      classDeclaration.namePart.typeName.offset,
    );
  }

  test_classFragment_classTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {}
class C = Object with M;
''');
    var classTypeAlias = result.findNode.classTypeAlias('C');
    checkOffset<ClassFragment>(
      classTypeAlias,
      classTypeAlias.declaredFragment!,
      classTypeAlias.name.offset,
    );
  }

  test_classFragment_classTypeAlias_missingName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {}
class = Object with M;
//    ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var classTypeAlias = result.findNode.classTypeAlias('Object with M');
    checkOffsetInRange<ClassFragment>(
      classTypeAlias,
      classTypeAlias.declaredFragment!,
    );
  }

  test_classFragment_missingName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
library; // Ensures that the class declaration isn't at offset 0

class {}
//    ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var classDeclaration = result.findNode.classDeclaration('class {}');
    checkOffsetInRange<ClassFragment>(
      classDeclaration,
      classDeclaration.declaredFragment!,
    );
  }

  test_constructorFragment_implicit() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}
''');
    var classDeclaration = result.findNode.classDeclaration('C');
    checkOffset<ConstructorFragment>(
      classDeclaration,
      classDeclaration
          .declaredFragment!
          .element
          .unnamedConstructor!
          .firstFragment,
      classDeclaration.namePart.typeName.offset,
    );
  }

  test_constructorFragment_missingName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  C.();
//  ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
    var constructorDeclaration = result.findNode.constructor('C.()');
    checkOffsetInRange<ConstructorFragment>(
      constructorDeclaration,
      constructorDeclaration.declaredFragment!,
    );
  }

  test_constructorFragment_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  C.foo();
}
''');
    var constructorDeclaration = result.findNode.constructor('foo');
    checkOffset<ConstructorFragment>(
      constructorDeclaration,
      constructorDeclaration.declaredFragment!,
      constructorDeclaration.name!.offset,
    );
  }

  test_constructorFragment_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  C();
}
''');
    var constructorDeclaration = result.findNode.constructor('C()');
    checkOffset<ConstructorFragment>(
      constructorDeclaration,
      constructorDeclaration.declaredFragment!,
      constructorDeclaration.typeName!.offset,
    );
  }

  test_dynamicFragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
dynamic d;
''');
    var namedType =
        result.findNode.topLevelVariableDeclaration('dynamic d').variables.type
            as NamedType;
    expect(namedType.element!.kind, ElementKind.DYNAMIC);
    // `dynamic` isn't defined in the source code anywhere, so its offset is 0.
    expect(namedType.element!.firstFragment.offset, 0);
  }

  test_enumFragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { e1 }
''');
    var enumDeclaration = result.findNode.enumDeclaration('E');
    checkOffset<EnumFragment>(
      enumDeclaration,
      enumDeclaration.declaredFragment!,
      enumDeclaration.namePart.typeName.offset,
    );
  }

  test_enumFragment_missingName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
library; // Ensures that the enum declaration isn't at offset 0

enum { e1 }
//   ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var enumDeclaration = result.findNode.enumDeclaration('enum { e1 }');
    checkOffsetInRange<EnumFragment>(
      enumDeclaration,
      enumDeclaration.declaredFragment!,
    );
  }

  test_extensionFragment_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
library; // Ensures that the extension declaration isn't at offset 0

/// Documentation comment
extension E on int {}
''');
    var extensionDeclaration = result.findNode.extensionDeclaration('on int');
    checkOffset<ExtensionFragment>(
      extensionDeclaration,
      extensionDeclaration.declaredFragment!,
      extensionDeclaration.name!.offset,
    );
  }

  test_extensionFragment_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension on int {}
''');
    var extensionDeclaration = result.findNode.extensionDeclaration('on int');
    checkOffset<ExtensionFragment>(
      extensionDeclaration,
      extensionDeclaration.declaredFragment!,
      extensionDeclaration.extensionKeyword.offset,
    );
  }

  test_extensionTypeFragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type E(int i) {}
''');
    var extensionTypeDeclaration = result.findNode.extensionTypeDeclaration(
      'E',
    );
    checkOffset<ExtensionTypeFragment>(
      extensionTypeDeclaration,
      extensionTypeDeclaration.declaredFragment!,
      extensionTypeDeclaration.namePart.typeName.offset,
    );
  }

  test_extensionTypeFragment_missingName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
library; // Ensures that the extension type declaration isn't at offset 0

extension type(int i) {}
//            ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var extensionTypeDeclaration = result.findNode.extensionTypeDeclaration(
      'extension type(int i)',
    );
    checkOffsetInRange<ExtensionTypeFragment>(
      extensionTypeDeclaration,
      extensionTypeDeclaration.declaredFragment!,
    );
  }

  test_fieldFormalParameterFragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final int i;
  C(this.i);
}
''');
    var parameter = result.findNode.fieldFormalParameter('this.i');
    checkOffset<FieldFormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
      parameter.name.offset,
    );
  }

  test_fieldFormalParameterFragment_missingName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int? x;
  C(this.);
//  ^^^^^
// [diag.initializingFormalForNonExistentField] '' isn't a field in the enclosing class.
//       ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
    var parameter = result.findNode.fieldFormalParameter('this.');
    checkOffsetInRange<FieldFormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
    );
  }

  test_fieldFormalParameterFragment_withDefaultValue() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final int i;
  C({this.i = 0});
}
''');
    var parameter = result.findNode.fieldFormalParameter('this.i');
    checkOffset<FieldFormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
      parameter.name.offset,
    );
  }

  test_fieldFragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int? x;
}
''');
    var fieldDeclaration = result.findNode
        .fieldDeclaration('x')
        .fields
        .variables[0];
    checkOffset<FieldFragment>(
      fieldDeclaration,
      fieldDeclaration.declaredFragment!,
      fieldDeclaration.name.offset,
    );
  }

  test_fieldFragment_const() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static const int x = 0;
}
''');
    var fieldDeclaration = result.findNode
        .fieldDeclaration('x')
        .fields
        .variables[0];
    checkOffset<FieldFragment>(
      fieldDeclaration,
      fieldDeclaration.declaredFragment!,
      fieldDeclaration.name.offset,
    );
  }

  test_fieldFragment_enum_constant() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { e1 }
''');
    var enumConstantDeclaration = result.findNode.enumConstantDeclaration('e1');
    checkOffset<FieldFragment>(
      enumConstantDeclaration,
      enumConstantDeclaration.declaredFragment!,
      enumConstantDeclaration.name.offset,
    );
  }

  test_fieldFragment_enum_values() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { e1 }
''');
    var enumDeclaration = result.findNode.enumDeclaration('E');
    checkOffset<FieldFragment>(
      enumDeclaration,
      enumDeclaration.declaredFragment!.element
          .getField('values')!
          .firstFragment,
      enumDeclaration.namePart.typeName.offset,
    );
  }

  test_formalParameterFragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {}
''');
    var parameter = result.findNode.regularFormalParameter('x');
    checkOffset<FormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
      parameter.name!.offset,
    );
  }

  test_formalParameterFragment_missingName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int x)) {}
//     ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var function = result.findNode.functionDeclaration('f(');
    var parameter =
        function.functionExpression.parameters!.parameters[0]
            as RegularFormalParameter;
    expect(parameter.name!.isSynthetic, true);
    checkOffsetInRange<FormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
    );
  }

  test_formalParameterFragment_missingName2() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(void (int x)) {}
//          ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var function = result.findNode.functionDeclaration('f(');
    var parameter =
        function.functionExpression.parameters!.parameters[0]
            as RegularFormalParameter;
    expect(parameter.name!.isSynthetic, true);
    checkOffsetInRange<FormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
    );
  }

  test_formalParameterFragment_ofImplicitSetter_member_implicit() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int? x;
}
''');
    var fieldDeclaration = result.findNode
        .fieldDeclaration('x')
        .fields
        .variables[0];
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
    var result = await resolveTestCodeWithDiagnostics(r'''
int? x;
''');
    var topLevelVariableDeclaration = result.findNode
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f({int x = 0}) {}
''');
    var parameter = result.findNode.regularFormalParameter('x');
    checkOffset<FormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
      parameter.name!.offset,
    );
  }

  test_genericFunctionTypeFragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
library; // Ensures that the generic function type isn't at offset 0

void Function(int x)? f;
''');
    var genericFunctionType = result.findNode.genericFunctionType(
      'void Function(int x)?',
    );
    checkOffset<GenericFunctionTypeFragment>(
      genericFunctionType,
      genericFunctionType.declaredFragment!,
      genericFunctionType.offset,
    );
  }

  test_getterFragment_member() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int get foo => 0;
}
''');
    var getterDeclaration = result.findNode.methodDeclaration('foo');
    checkOffset<GetterFragment>(
      getterDeclaration,
      getterDeclaration.declaredFragment!,
      getterDeclaration.name.offset,
    );
  }

  test_getterFragment_member_implicit() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int? x;
}
''');
    var fieldDeclaration = result.findNode
        .fieldDeclaration('x')
        .fields
        .variables[0];
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
    var result = await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;
''');
    var getterDeclaration = result.findNode.functionDeclaration('foo');
    checkOffset<GetterFragment>(
      getterDeclaration,
      getterDeclaration.declaredFragment!,
      getterDeclaration.name.offset,
    );
  }

  test_getterFragment_topLevel_implicit() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int? x;
''');
    var topLevelVariableDeclaration = result.findNode
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  switch ((0,) as dynamic) {
    // ignore: unused_local_variable
    case (var i,) || (:var i,):
      break;
  }
}
''');
    var firstDeclaredVariablePattern = result.findNode.declaredVariablePattern(
      'var i,) ||',
    );
    checkOffset<JoinPatternVariableFragment>(
      firstDeclaredVariablePattern,
      firstDeclaredVariablePattern.declaredFragment!.join!,
      firstDeclaredVariablePattern.name.offset,
    );
  }

  test_labelFragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore: unused_label
  L: while(true) {}
}
''');
    var label = result.findNode.label('L');
    checkOffset<LabelFragment>(
      label,
      label.declaredFragment!,
      label.name.offset,
    );
  }

  test_libraryFragment_first_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// Comment to ensure that the library declaration isn't at offset 0
library L;

class C {}
''');
    var unit = result.findNode.unit;
    checkOffset<LibraryFragment>(
      unit,
      unit.declaredFragment!,
      result.findNode.library('L').name!.offset,
    );
  }

  test_libraryFragment_first_unnamed_withLibraryDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// Comment to ensure that the library declaration isn't at offset 0
library;

class C {}
''');
    var unit = result.findNode.unit;
    checkOffset<LibraryFragment>(unit, unit.declaredFragment!, 0);
  }

  test_libraryFragment_first_unnamed_withoutLibraryDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// Comment to ensure that the class declaration isn't at offset 0
class C {}
''');
    var unit = result.findNode.unit;
    checkOffset<LibraryFragment>(unit, unit.declaredFragment!, 0);
  }

  test_libraryFragment_notFirst_named() async {
    var library = getFile('$testPackageLibPath/lib.dart');
    var part = getFile('$testPackageLibPath/part.dart');
    var results = await resolveFilesWithDiagnostics({
      library: r'''
library L;

part 'part.dart';
''',
      part: r'''
// Comment to ensure that the "part of" declaration isn't at offset 0
part of 'lib.dart';

class C {}
''',
    });
    var result = results[part]!;

    var unit = result.findNode.unit;
    checkOffset<LibraryFragment>(unit, unit.declaredFragment!, 0);
  }

  test_libraryFragment_notFirst_unnamed() async {
    var library = getFile('$testPackageLibPath/lib.dart');
    var part = getFile('$testPackageLibPath/part.dart');
    var results = await resolveFilesWithDiagnostics({
      library: r'''
part 'part.dart';
''',
      part: r'''
// Comment to ensure that the "part of" declaration isn't at offset 0
part of 'lib.dart';

class C {}
''',
    });
    var result = results[part]!;

    var unit = result.findNode.unit;
    checkOffset<LibraryFragment>(unit, unit.declaredFragment!, 0);
  }

  test_local_variable_fragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore: unused_local_variable
  int i = 0;
}
''');
    var localVariable = result.findNode.variableDeclaration('i = 0');
    checkOffset<LocalVariableFragment>(
      localVariable,
      localVariable.declaredFragment!,
      localVariable.name.offset,
    );
  }

  test_local_variable_fragment_const() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore: unused_local_variable
  const int i = 0;
}
''');
    var localVariable = result.findNode.variableDeclaration('i = 0');
    checkOffset<LocalVariableFragment>(
      localVariable,
      localVariable.declaredFragment!,
      localVariable.name.offset,
    );
  }

  test_localFunctionFragment_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore: unused_element
  void g() {}
}
''');
    var localFunction = result.findNode
        .functionDeclarationStatement('g()')
        .functionDeclaration;
    checkOffset<LocalFunctionFragment>(
      localFunction,
      localFunction.declaredFragment!,
      localFunction.name.offset,
    );
  }

  test_localFunctionFragment_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
dynamic f() {
  return () {};
}
''');
    var localFunction = result.findNode.functionExpression('() {}');
    checkOffset<LocalFunctionFragment>(
      localFunction,
      localFunction.declaredFragment!,
      localFunction.parameters!.leftParenthesis.offset,
    );
  }

  test_methodFragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
}
''');
    var methodDeclaration = result.findNode.methodDeclaration('foo');
    checkOffset<MethodFragment>(
      methodDeclaration,
      methodDeclaration.declaredFragment!,
      methodDeclaration.name.offset,
    );
  }

  test_mixinFragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {}
''');
    var mixinDeclaration = result.findNode.mixinDeclaration('M');
    checkOffset<MixinFragment>(
      mixinDeclaration,
      mixinDeclaration.declaredFragment!,
      mixinDeclaration.name.offset,
    );
  }

  test_mixinFragment_missingName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
library; // Ensures that the mixin declaration isn't at offset 0

mixin {}
//    ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var mixinDeclaration = result.findNode.mixinDeclaration('mixin {}');
    checkOffsetInRange<MixinFragment>(
      mixinDeclaration,
      mixinDeclaration.declaredFragment!,
    );
  }

  test_neverFragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
Never n = throw '';
''');
    var namedType =
        result.findNode.topLevelVariableDeclaration('Never n').variables.type
            as NamedType;
    expect(namedType.element!.kind, ElementKind.NEVER);
    // `Never` isn't defined in the source code anywhere, so its offset is 0.
    expect(namedType.element!.firstFragment.offset, 0);
  }

  test_prefixFragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// ignore: unused_import
import 'dart:async' as a;
''');
    var importDirective = result.findNode.import('as a');
    checkOffset<PrefixFragment>(
      importDirective,
      importDirective.libraryImport!.prefix!,
      importDirective.prefix!.offset,
    );
  }

  test_prefixFragment_inMultipleImports() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// ignore: unused_import
import 'dart:async' as a; // first
// ignore: unused_import
import 'dart:math' as a; // second
''');
    var firstImportDirective = result.findNode.import('as a; // first');
    checkOffset<PrefixFragment>(
      firstImportDirective,
      firstImportDirective.libraryImport!.prefix!,
      firstImportDirective.prefix!.offset,
    );
  }

  test_prefixFragment_missingName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// ignore: unused_import
import 'dart:async' as;
//                    ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var importDirective = result.findNode.import('as;');
    checkOffsetInRange<PrefixFragment>(
      importDirective,
      importDirective.libraryImport!.prefix!,
    );
  }

  test_setterFragment_member() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  set foo(int value) {}
}
''');
    var setterDeclaration = result.findNode.methodDeclaration('foo');
    checkOffset<SetterFragment>(
      setterDeclaration,
      setterDeclaration.declaredFragment!,
      setterDeclaration.name.offset,
    );
  }

  test_setterFragment_member_implicit() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int? x;
}
''');
    var fieldDeclaration = result.findNode
        .fieldDeclaration('x')
        .fields
        .variables[0];
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
    var result = await resolveTestCodeWithDiagnostics(r'''
set foo(int value) {}
''');
    var setterDeclaration = result.findNode.functionDeclaration('foo');
    checkOffset<SetterFragment>(
      setterDeclaration,
      setterDeclaration.declaredFragment!,
      setterDeclaration.name.offset,
    );
  }

  test_setterFragment_topLevel_implicit() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int? x;
''');
    var topLevelVariableDeclaration = result.findNode
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class B {
  B(int i);
}

class C extends B {
  C(super.i);
}
''');
    var parameter = result.findNode.superFormalParameter('super.i');
    checkOffset<SuperFormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
      parameter.name.offset,
    );
  }

  test_superFormalParameterFragment_missingName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class B {
  B([int? i]);
}

class C extends B {
  C(super.);
//        ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
    var parameter = result.findNode.superFormalParameter('super.');
    checkOffsetInRange<SuperFormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
    );
  }

  test_superFormalParameterFragment_withDefaultValue() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class B {
  B({int? i});
}

class C extends B {
  C({super.i = 0});
}
''');
    var parameter = result.findNode.superFormalParameter('super.i');
    checkOffset<SuperFormalParameterFragment>(
      parameter,
      parameter.declaredFragment!,
      parameter.name.offset,
    );
  }

  test_topLevelFunctionFragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo() {}
''');
    var topLevelFunctionDeclaration = result.findNode.functionDeclaration(
      'foo',
    );
    checkOffset<TopLevelFunctionFragment>(
      topLevelFunctionDeclaration,
      topLevelFunctionDeclaration.declaredFragment!,
      topLevelFunctionDeclaration.name.offset,
    );
  }

  test_topLevelVariableFragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int? x;
''');
    var topLevelVariableDeclaration = result.findNode
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
    var result = await resolveTestCodeWithDiagnostics(r'''
const int x = 0;
''');
    var topLevelVariableDeclaration = result.findNode
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
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef void F();
''');
    var functionTypeAlias = result.findNode.functionTypeAlias('F');
    checkOffset<TypeAliasFragment>(
      functionTypeAlias,
      functionTypeAlias.declaredFragment!,
      functionTypeAlias.name.offset,
    );
  }

  test_typeAliasFragment_functionTypeAlias_missingName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
library; // Ensures that the function type alias declaration isn't at offset 0
// [diag.unusedElement][column 1][length 0] The declaration '<unnamed>' isn't referenced.

typedef void();
//          ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var functionTypeAlias = result.findNode.functionTypeAlias('void()');
    checkOffsetInRange<TypeAliasFragment>(
      functionTypeAlias,
      functionTypeAlias.declaredFragment!,
    );
  }

  test_typeAliasFragment_genericTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef T = int;
''');
    var genericTypeAlias = result.findNode.genericTypeAlias('T');
    checkOffset<TypeAliasFragment>(
      genericTypeAlias,
      genericTypeAlias.declaredFragment!,
      genericTypeAlias.name.offset,
    );
  }

  test_typeAliasFragment_genericTypeAlias_missingName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
library; // Ensures that the generic type alias declaration isn't at offset 0
// [diag.unusedElement][column 1][length 0] The declaration '<unnamed>' isn't referenced.

typedef = int;
//      ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var genericTypeAlias = result.findNode.genericTypeAlias('= int');
    checkOffsetInRange<TypeAliasFragment>(
      genericTypeAlias,
      genericTypeAlias.declaredFragment!,
    );
  }

  test_typeParameterFragment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {}
''');
    var typeParameter = result.findNode.typeParameter('T');
    checkOffset<TypeParameterFragment>(
      typeParameter,
      typeParameter.declaredFragment!,
      typeParameter.name.offset,
    );
  }
}
