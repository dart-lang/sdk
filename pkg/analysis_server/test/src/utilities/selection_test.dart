// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/selection.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';
import '../../services/completion/dart/text_expectations.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SelectionTest);
  });
}

@reflectiveTest
class SelectionTest extends AbstractSingleUnitTest {
  Future<void> assertMetadata({
    String prefix = '',
    required String postfix,
  }) async {
    final selection = await _computeSelection('''
$prefix
@a
[!@b
@c!]
@d
$postfix
const a = 1;
const b = 2;
const c = 3;
const d = 4;
''');
    _assertSelection(selection, r'''
nodesInRange
  AnnotationImpl: @b
  AnnotationImpl: @c
''');
  }

  Future<void> test_adjacentStrings_strings() async {
    final selection = await _computeSelection('''
var s = 'a' [!'b' 'c'!] 'd';
''');
    _assertSelection(selection, r'''
nodesInRange
  SimpleStringLiteralImpl: 'b'
  SimpleStringLiteralImpl: 'c'
''');
  }

  Future<void> test_argumentList_arguments() async {
    final selection = await _computeSelection('''
var v = f('0', [!1, 2.0!], '3');
int f(a, b, c, d) => 0;
''');
    _assertSelection(selection, r'''
nodesInRange
  IntegerLiteralImpl: 1
  DoubleLiteralImpl: 2.0
''');
  }

  @FailingTest(reason: 'Augmentation libraries appear to not be supported.')
  Future<void> test_augmentationImportDirective_metadata() async {
    newFile('$testPackageLibPath/a.dart', '''
augmentation library 'test.dart';
''');
    await assertMetadata(postfix: '''
import augment 'a.dart';
''');
  }

  /// B01: between 0 and 1, no touch
  Future<void> test_block_statements_B01_B01() async {
    final selection = await _computeSelection('''
void f() {
  000;
 [! !] 111;
  222;
}
''');
    _assertSelection(selection, r'''
nodesInRange
''');
  }

  /// B01: between 0 and 1, no touch
  /// TE2: touch end of 2
  Future<void> test_block_statements_B01_E2() async {
    final selection = await _computeSelection('''
void f() {
  000;
 [! 111;
  222;!]
  333;
}
''');
    _assertSelection(selection, r'''
nodesInRange
  ExpressionStatementImpl: 111;
  ExpressionStatementImpl: 222;
''');
  }

  /// B01: between 0 and 1, no touch
  /// TB1: touch begin of 1
  Future<void> test_block_statements_B01_TB1() async {
    final selection = await _computeSelection('''
void f() {
  000;
 [! !]111;
  222;
}
''');
    _assertSelection(selection, r'''
nodesInRange
''');
  }

  /// B0: before 0
  Future<void> test_block_statements_B0_B0() async {
    final selection = await _computeSelection('''
void f() {
 [! !] 000;
  111;
}
''');
    _assertSelection(selection, r'''
nodesInRange
''');
  }

  /// B12: between 1 and 2
  /// TE2: touch end of 2
  Future<void> test_block_statements_B12_TE2() async {
    final selection = await _computeSelection('''
void f() {
  000;
  111;
  [! 222;!]
  333;
}
''');
    _assertSelection(selection, r'''
nodesInRange
  ExpressionStatementImpl: 222;
''');
  }

  /// BB0: before begin of 0
  /// TE2: touch end of 2
  Future<void> test_block_statements_BB0_TE2() async {
    final selection = await _computeSelection('''
void f() {
[!  000;
  111;
  222;!]
  333;
}
''');
    _assertSelection(selection, r'''
nodesInRange
  ExpressionStatementImpl: 000;
  ExpressionStatementImpl: 111;
  ExpressionStatementImpl: 222;
''');
  }

  /// I0: inside 0
  /// TE2: touch end of 2
  Future<void> test_block_statements_I0_TE2() async {
    final selection = await _computeSelection('''
void f() {
  0[!00;
  111;
  222;!]
  333;
}
''');
    _assertSelection(selection, r'''
nodesInRange
  ExpressionStatementImpl: 000;
  ExpressionStatementImpl: 111;
  ExpressionStatementImpl: 222;
''');
  }

  /// I1: inside 1
  /// TE2: touch end of 2
  Future<void> test_block_statements_I1_TE2() async {
    final selection = await _computeSelection('''
void f() {
  000;
  1[!11;
  222;!]
  333;
}
''');
    _assertSelection(selection, r'''
nodesInRange
  ExpressionStatementImpl: 111;
  ExpressionStatementImpl: 222;
''');
  }

  /// I2: inside 2
  /// TE2: touch end of 2
  Future<void> test_block_statements_I2_TE2() async {
    final selection = await _computeSelection('''
void f() {
  000;
  111;
  2[!22;!]
  333;
}
''');
    _assertSelection(selection, r'''
nodesInRange
''');
  }

  /// TB0: touch begin of 0
  /// TE2: touch end of 2
  Future<void> test_block_statements_TB0_TE2() async {
    final selection = await _computeSelection('''
void f() {
  [!000;
  111;
  222;!]
  333;
}
''');
    _assertSelection(selection, r'''
nodesInRange
  ExpressionStatementImpl: 000;
  ExpressionStatementImpl: 111;
  ExpressionStatementImpl: 222;
''');
  }

  /// TB1: touch begin of 1
  /// A3: after 3
  Future<void> test_block_statements_TB1_A3() async {
    final selection = await _computeSelection('''
void f() {
  000;
  [!111;
  222;
  333; !]
}
''');
    _assertSelection(selection, r'''
nodesInRange
  ExpressionStatementImpl: 111;
  ExpressionStatementImpl: 222;
  ExpressionStatementImpl: 333;
''');
  }

  /// TB1: touch begin of 1
  /// B23: before 2 and 3
  Future<void> test_block_statements_TB1_B23() async {
    final selection = await _computeSelection('''
void f() {
  000;
  [!111;
  222;
 !] 333;
}
''');
    _assertSelection(selection, r'''
nodesInRange
  ExpressionStatementImpl: 111;
  ExpressionStatementImpl: 222;
''');
  }

  /// TB1: touch begin of 1
  /// TE2: touch end of 2
  Future<void> test_block_statements_TB1_TE2() async {
    final selection = await _computeSelection('''
void f() {
  000;
  [!111;
  222;!]
  333;
}
''');
    _assertSelection(selection, r'''
nodesInRange
  ExpressionStatementImpl: 111;
  ExpressionStatementImpl: 222;
''');
  }

  /// TB1: touch begin of 1
  /// TE2TB3: touch end of 2, touch begin of 3
  Future<void> test_block_statements_TB1_TE2TB3() async {
    final selection = await _computeSelection('''
void f() {
  000;
  [!111;
  222;!]333;
}
''');
    _assertSelection(selection, r'''
nodesInRange
  ExpressionStatementImpl: 111;
  ExpressionStatementImpl: 222;
''');
  }

  /// TB1: touch begin of 1
  /// TE2: touch end 3
  Future<void> test_block_statements_TB1_TE3() async {
    final selection = await _computeSelection('''
void f() {
  000;
  [!111;
  222;
  333;!]
}
''');
    _assertSelection(selection, r'''
nodesInRange
  ExpressionStatementImpl: 111;
  ExpressionStatementImpl: 222;
  ExpressionStatementImpl: 333;
''');
  }

  /// TB2: touch begin of 2
  /// B23: between 2 and 3
  Future<void> test_block_statements_TB2_B23() async {
    final selection = await _computeSelection('''
void f() {
  000;
  111;
  [!222; !]
  333;
}
''');
    _assertSelection(selection, r'''
nodesInRange
  ExpressionStatementImpl: 222;
''');
  }

  /// TB2: touch begin of 2
  /// TE2: touch end of 2
  Future<void> test_block_statements_TB2_TE2() async {
    final selection = await _computeSelection('''
void f() {
  000;
  111;
  [!222;!]
  333;
}
''');
    _assertSelection(selection, r'''
nodesInRange
''');
  }

  /// TE0TB1: touch end of 0, touch begin of 1
  /// TE2: touch end of 2
  Future<void> test_block_statements_TE0TB1_TE2() async {
    final selection = await _computeSelection('''
void f() {
  000;[!111;
  222;!]
  333;
}
''');
    _assertSelection(selection, r'''
nodesInRange
  ExpressionStatementImpl: 111;
  ExpressionStatementImpl: 222;
''');
  }

  /// TE2: touch end of 2
  /// B12: between 1 and 2, no touch
  Future<void> test_block_statements_TE1_B12() async {
    final selection = await _computeSelection('''
void f() {
  000;
  111;[! !]
  222;
}
''');
    _assertSelection(selection, r'''
nodesInRange
''');
  }

  Future<void> test_cascadeExpression_cascadeSections() async {
    final selection = await _computeSelection('''
void f(y) {
  var x = y..a()[!..b..c()!]..d;
}
''');
    _assertSelection(selection, r'''
nodesInRange
  PropertyAccessImpl: ..b
  MethodInvocationImpl: ..c()
''');
  }

  Future<void> test_classTypeAlias_metadata() async {
    await assertMetadata(postfix: '''
class A = C with M;
class C {}
mixin M {}
''');
  }

  Future<void> test_compilationUnit_declarations() async {
    final selection = await _computeSelection('''
typedef F = void Function();
[!var x = 0;
void f() {}!]
class C {}
''');
    _assertSelection(selection, r'''
nodesInRange
  TopLevelVariableDeclarationImpl: var x = 0;
  FunctionDeclarationImpl: void f() {}
''');
  }

  Future<void> test_compilationUnit_directives() async {
    newFile('$testPackageLibPath/a.dart', "part of 'test.dart';");
    final selection = await _computeSelection('''
library l;
[!import '';
export '';!]
part 'a.dart';
''');
    _assertSelection(selection, r'''
nodesInRange
  ImportDirectiveImpl: import '';
  ExportDirectiveImpl: export '';
''');
  }

  Future<void> test_constructorDeclaration_initializers() async {
    final selection = await _computeSelection('''
class C {
  int a, b, c, d;
  C() : a = 0, [!b = 1, c = 2,!] d = 4;
}
''');
    _assertSelection(selection, r'''
nodesInRange
  ConstructorFieldInitializerImpl: b = 1
  ConstructorFieldInitializerImpl: c = 2
''');
  }

  Future<void> test_constructorDeclaration_metadata() async {
    await assertMetadata(prefix: '''
class C {
''', postfix: '''
  C();
}
''');
  }

  Future<void> test_declaredIdentifier_metadata() async {
    await assertMetadata(prefix: '''
void f(List l) {
  for (
''', postfix: '''
var e in l) {}
}
''');
  }

  Future<void> test_defaultFormalParameter_metadata() async {
    await assertMetadata(prefix: '''
void f([
''', postfix: '''
int x = 0]) {}
''');
  }

  Future<void> test_dottedName_components() async {
    final selection = await _computeSelection('''
library a.[!b.c!].d;
''');
    _assertSelection(selection, r'''
nodesInRange
  SimpleIdentifierImpl: b
  SimpleIdentifierImpl: c
''');
  }

  Future<void> test_enumConstantDeclaration_metadata() async {
    await assertMetadata(prefix: '''
enum E {
''', postfix: '''
a }
''');
  }

  Future<void> test_enumDeclaration_constants() async {
    final selection = await _computeSelection('''
enum E { a, [!b, c!], d }
''');
    _assertSelection(selection, r'''
nodesInRange
  EnumConstantDeclarationImpl: b
  EnumConstantDeclarationImpl: c
''');
  }

  Future<void> test_enumDeclaration_members() async {
    final selection = await _computeSelection('''
enum E {
  a;
  final int x = 0;
  [!void m1() {}
  final int y = 1;!]
  void m2() {}
}
''');
    _assertSelection(selection, r'''
nodesInRange
  MethodDeclarationImpl: void m1() {}
  FieldDeclarationImpl: final int y = 1;
''');
  }

  Future<void> test_enumDeclaration_metadata() async {
    await assertMetadata(postfix: '''
enum E { a }
''');
  }

  Future<void> test_exportDirective_combinators() async {
    newFile('$testPackageLibPath/a.dart', '''
int a, b, c, d;
''');
    final selection = await _computeSelection('''
export 'a.dart' show a [!hide b show c!] hide d;
''');
    _assertSelection(selection, r'''
nodesInRange
  HideCombinatorImpl: hide b
  ShowCombinatorImpl: show c
''');
  }

  Future<void> test_exportDirective_configurations() async {
    final selection = await _computeSelection('''
export '' if (a) '' [!if (b) '' if (c) ''!] if (d) '';
''');
    _assertSelection(selection, r'''
nodesInRange
  ConfigurationImpl: if (b) ''
  ConfigurationImpl: if (c) ''
''');
  }

  Future<void> test_exportDirective_metadata() async {
    newFile('$testPackageLibPath/a.dart', '''
int a, b, c, d;
''');
    await assertMetadata(postfix: '''
export 'a.dart';
''');
  }

  Future<void> test_extensionDeclaration_members() async {
    final selection = await _computeSelection('''
extension on int {
  static int x = 0;
  [!void m1() {}
  static int y = 1;!]
  void m2() {}
}
''');
    _assertSelection(selection, r'''
nodesInRange
  MethodDeclarationImpl: void m1() {}
  FieldDeclarationImpl: static int y = 1;
''');
  }

  Future<void> test_extensionDeclaration_metadata() async {
    await assertMetadata(postfix: '''
extension on int {}
''');
  }

  Future<void> test_fieldDeclaration_metadata() async {
    await assertMetadata(prefix: '''
class C {
''', postfix: '''
  int? f;
}
''');
  }

  Future<void> test_fieldFormalParameter_metadata() async {
    await assertMetadata(prefix: '''
class C {
  int x = 0;
  C(
''', postfix: '''
this.x);
}
''');
  }

  Future<void> test_forEachPartsWithPattern_metadata() async {
    await assertMetadata(prefix: '''
void f(List<(int, int)> r) {
  for (
''', postfix: '''
  var (x, y) in r) {}
}
''');
  }

  Future<void> test_formalParameterList_parameters_mixed() async {
    final selection = await _computeSelection('''
void f(a, [!b, {c!], d}) {}
''');
    _assertSelection(selection, r'''
nodesInRange
''');
  }

  Future<void> test_formalParameterList_parameters_named() async {
    final selection = await _computeSelection('''
void f({a, [!b, c!], d}) {}
''');
    _assertSelection(selection, r'''
nodesInRange
  DefaultFormalParameterImpl: b
  DefaultFormalParameterImpl: c
''');
  }

  Future<void> test_formalParameterList_parameters_positional() async {
    final selection = await _computeSelection('''
void f(a, [!b, c!], d) {}
''');
    _assertSelection(selection, r'''
nodesInRange
  SimpleFormalParameterImpl: b
  SimpleFormalParameterImpl: c
''');
  }

  Future<void> test_forPartsWithDeclarations_updaters() async {
    final selection = await _computeSelection('''
void f() {
  for (var x = 0; x < 0; x++, [!x--, ++x!], --x) {}
}
''');
    _assertSelection(selection, r'''
nodesInRange
  PostfixExpressionImpl: x--
  PrefixExpressionImpl: ++x
''');
  }

  Future<void> test_forPartsWithExpression_updaters() async {
    final selection = await _computeSelection('''
void f() {
  var x;
  for (x = 0; x < 0; x++, [!x--, ++x!], --x) {}
}
''');
    _assertSelection(selection, r'''
nodesInRange
  PostfixExpressionImpl: x--
  PrefixExpressionImpl: ++x
''');
  }

  Future<void> test_forPartsWithPattern_updaters() async {
    final selection = await _computeSelection('''
void f() {
  for (var (x, y) = (0, 0); x < 0; x++, [!x--, ++x!], --x) {}
}
''');
    _assertSelection(selection, r'''
nodesInRange
  PostfixExpressionImpl: x--
  PrefixExpressionImpl: ++x
''');
  }

  Future<void> test_functionDeclaration_metadata() async {
    await assertMetadata(postfix: '''
void f() {}
''');
  }

  Future<void> test_functionTypeAlias_metadata() async {
    await assertMetadata(postfix: '''
typedef void F();
''');
  }

  Future<void> test_functionTypedFormalParameter_metadata() async {
    await assertMetadata(prefix: '''
void f(
''', postfix: '''
int g(int)) {}
''');
  }

  Future<void> test_genericTypeAlias_metadata() async {
    await assertMetadata(postfix: '''
typedef F = void Function();
''');
  }

  Future<void> test_hideCombinator_hiddenNames() async {
    newFile('$testPackageLibPath/a.dart', '''
int a, b, c, d;
''');
    final selection = await _computeSelection('''
import 'a.dart' hide a, [!b, c!], d;
''');
    _assertSelection(selection, r'''
nodesInRange
  SimpleIdentifierImpl: b
  SimpleIdentifierImpl: c
''');
  }

  Future<void> test_implementsClause_interfaces() async {
    final selection = await _computeSelection('''
class A implements B, [!C, D!], E {}
class B {}
class C {}
class D {}
class E {}
''');
    _assertSelection(selection, r'''
nodesInRange
  NamedTypeImpl: C
  NamedTypeImpl: D
''');
  }

  Future<void> test_importDirective_combinators() async {
    newFile('$testPackageLibPath/a.dart', '''
int a, b, c, d;
''');
    final selection = await _computeSelection('''
import 'a.dart' show a [!hide b show c!] hide d;
''');
    _assertSelection(selection, r'''
nodesInRange
  HideCombinatorImpl: hide b
  ShowCombinatorImpl: show c
''');
  }

  Future<void> test_importDirective_configurations() async {
    newFile('$testPackageLibPath/a.dart', '''
int a, b, c, d;
''');
    final selection = await _computeSelection('''
import 'a.dart' if (a) '' [!if (b) '' if (c) ''!] if (d) '';
''');
    _assertSelection(selection, r'''
nodesInRange
  ConfigurationImpl: if (b) ''
  ConfigurationImpl: if (c) ''
''');
  }

  Future<void> test_importDirective_metadata() async {
    newFile('$testPackageLibPath/a.dart', '''
int a, b, c, d;
''');
    await assertMetadata(postfix: '''
import 'a.dart';
''');
  }

  Future<void> test_labeledStatement_labels() async {
    final selection = await _computeSelection('''
void f() {
  a: [!b: c:!] d: while (true) {
    if (1 < 2) {
      break a;
    } else if (2 < 3) {
      break b;
    } else if (3 < 4) {
      break c;
    } else if (4 < 5) {
      break d;
    }
  }
}
''');
    _assertSelection(selection, r'''
nodesInRange
  LabelImpl: b:
  LabelImpl: c:
''');
  }

  @FailingTest(reason: 'The parser fails')
  Future<void> test_libraryAugmentationDirective_metadata() async {
    await assertMetadata(postfix: '''
library augment '';
''');
  }

  Future<void> test_libraryDirective_metadata() async {
    await assertMetadata(postfix: '''
library l;
''');
  }

  Future<void> test_libraryIdentifier_components() async {
    final selection = await _computeSelection('''
library a.[!b.c!].d;
''');
    _assertSelection(selection, r'''
nodesInRange
  SimpleIdentifierImpl: b
  SimpleIdentifierImpl: c
''');
  }

  Future<void> test_listLiteral_elements() async {
    final selection = await _computeSelection('''
var l = ['0', [!1, 2.0!], '3'];
''');
    _assertSelection(selection, r'''
nodesInRange
  IntegerLiteralImpl: 1
  DoubleLiteralImpl: 2.0
''');
  }

  Future<void> test_listPattern_elements() async {
    final selection = await _computeSelection('''
void f(x) {
  switch (x) {
    case [1, [!2, 3!], 4]:
      break;
  }
}
''');
    _assertSelection(selection, r'''
nodesInRange
  ConstantPatternImpl: 2
  ConstantPatternImpl: 3
''');
  }

  Future<void> test_mapPattern_entries() async {
    final selection = await _computeSelection('''
void f(x) {
  switch (x) {
    case {'a': 1, [!'b': 2, 'c': 3!], 'd': 4}:
      break;
  }
}
''');
    _assertSelection(selection, r'''
nodesInRange
  MapPatternEntryImpl: 'b': 2
  MapPatternEntryImpl: 'c': 3
''');
  }

  Future<void> test_methodDeclaration_metadata() async {
    await assertMetadata(prefix: '''
class C {
''', postfix: '''
  void m() {}
}
''');
  }

  Future<void> test_mixinDeclaration_members() async {
    final selection = await _computeSelection('''
mixin M {
  int x = 0;
  [!void m1() {}
  int y = 1;!]
  void m2() {}
}
''');
    _assertSelection(selection, r'''
nodesInRange
  MethodDeclarationImpl: void m1() {}
  FieldDeclarationImpl: int y = 1;
''');
  }

  Future<void> test_mixinDeclaration_metadata() async {
    await assertMetadata(postfix: '''
mixin M {}
''');
  }

  Future<void> test_objectPattern_fields() async {
    final selection = await _computeSelection('''
void f(C x) {
  switch (x) {
    case C(a: 1, [!b: 2, c: 3!], d: 4):
      break;
  }
}
class C {
  int a = 1, b = 2, c = 3, d = 4;
}
''');
    _assertSelection(selection, r'''
nodesInRange
  PatternFieldImpl: b: 2
  PatternFieldImpl: c: 3
''');
  }

  Future<void> test_onClause_superclassConstraints() async {
    final selection = await _computeSelection('''
mixin M on A, [!B, C!], D {}
class A {}
class B {}
class C {}
class D {}
''');
    _assertSelection(selection, r'''
nodesInRange
  NamedTypeImpl: B
  NamedTypeImpl: C
''');
  }

  Future<void> test_partDirective_metadata() async {
    newFile('$testPackageLibPath/a.dart', "part of 'test.dart';");
    await assertMetadata(postfix: '''
part 'a.dart';
''');
  }

  Future<void> test_partOfDirective_metadata() async {
    await assertMetadata(postfix: '''
part of '';
''');
  }

  Future<void> test_patternVariableDeclaration_metadata() async {
    await assertMetadata(prefix: '''
void f((int, int) r) {
''', postfix: '''
  var (x, y) = r;
}
''');
  }

  Future<void> test_recordLiteral_fields() async {
    final selection = await _computeSelection('''
var r = ('0', [!1, 2.0!], '3');
''');
    _assertSelection(selection, r'''
nodesInRange
  IntegerLiteralImpl: 1
  DoubleLiteralImpl: 2.0
''');
  }

  Future<void> test_recordPattern_fields() async {
    final selection = await _computeSelection('''
void f((String, int, double, String) x) {
  switch (x) {
    case ('0', [!1, 2.0!], '3'):
      break;
  }
}
''');
    _assertSelection(selection, r'''
nodesInRange
  PatternFieldImpl: 1
  PatternFieldImpl: 2.0
''');
  }

  Future<void> test_recordTypeAnnotation_positionalFields() async {
    final selection = await _computeSelection('''
(int, [!String, int!], String) r = (0, '1', 2, '3');
''');
    _assertSelection(selection, r'''
nodesInRange
  RecordTypeAnnotationPositionalFieldImpl: String
  RecordTypeAnnotationPositionalFieldImpl: int
''');
  }

  Future<void> test_recordTypeAnnotationNamedField_metadata() async {
    await assertMetadata(prefix: '''
void f(({
''', postfix: '''
int x}) r) {}
''');
  }

  Future<void> test_recordTypeAnnotationNamedFields_fields() async {
    final selection = await _computeSelection('''
({int a, [!String b, int c!], String d}) r = (a: 0, b: '1', c: 2, d:'3');
''');
    _assertSelection(selection, r'''
nodesInRange
  RecordTypeAnnotationNamedFieldImpl: String b
  RecordTypeAnnotationNamedFieldImpl: int c
''');
  }

  Future<void> test_recordTypeAnnotationPositionalField_metadata() async {
    await assertMetadata(prefix: '''
void f((int,
''', postfix: '''
int) r) {}
''');
  }

  Future<void> test_setOrMapLiteral_elements() async {
    final selection = await _computeSelection('''
var s = {'0', [!1, 2.0!], '3'};
''');
    _assertSelection(selection, r'''
nodesInRange
  IntegerLiteralImpl: 1
  DoubleLiteralImpl: 2.0
''');
  }

  Future<void> test_showCombinator_shownNames() async {
    newFile('$testPackageLibPath/a.dart', '''
int a, b, c, d;
''');
    final selection = await _computeSelection('''
import 'a.dart' show a, [!b, c!], d;
''');
    _assertSelection(selection, r'''
nodesInRange
  SimpleIdentifierImpl: b
  SimpleIdentifierImpl: c
''');
  }

  Future<void> test_simpleFormalParameter_metadata() async {
    await assertMetadata(prefix: '''
void f(
''', postfix: '''
int x) {}
''');
  }

  Future<void> test_stringInterpolation_elements() async {
    final selection = await _computeSelection(r'''
void f(cd, gh) {
  var s = 'ab${c[!d}e!]f${gh}';
}
''');
    _assertSelection(selection, r'''
nodesInRange
  InterpolationExpressionImpl: ${cd}
  InterpolationStringImpl: ef
''');
  }

  Future<void> test_superFormalParameter_metadata() async {
    await assertMetadata(prefix: '''
class C extends B {
  C({
''', postfix: '''
super.x});
}
class B {
  B({int? x});
}
''');
  }

  Future<void> test_switchCase_labels() async {
    final selection = await _computeSelection('''
void f(int x) {
  switch (x) {
    a: [!b: c!]: d: case 3: continue a;
    case 4: continue b;
    case 5: continue c;
    case 6: continue d;
  }
}
''');
    _assertSelection(selection, r'''
nodesInRange
  LabelImpl: b:
  LabelImpl: c:
''');
  }

  Future<void> test_switchCase_statements() async {
    final selection = await _computeSelection('''
void f(int x) {
  switch (x) {
    case 3:
      var v = 0;
      [!if (v < 0) v++;
      while (v > 0) v--;!]
      print(v);
      break;
  }
}
''');
    _assertSelection(selection, r'''
nodesInRange
  IfStatementImpl: if (v < 0) v++;
  WhileStatementImpl: while (v > 0) v--;
''');
  }

  Future<void> test_switchDefault_labels() async {
    final selection = await _computeSelection('''
void f(int x) {
  switch (x) {
    case 4: continue b;
    case 5: continue c;
    case 6: continue d;
    a: [!b: c!]: d: default: continue a;
  }
}
''');
    _assertSelection(selection, r'''
nodesInRange
  LabelImpl: b:
  LabelImpl: c:
''');
  }

  Future<void> test_switchDefault_statements() async {
    final selection = await _computeSelection('''
void f(int x) {
  switch (x) {
    default:
      var v = 0;
      [!if (v < 0) v++;
      while (v > 0) v--;!]
      print(v);
      break;
  }
}
''');
    _assertSelection(selection, r'''
nodesInRange
  IfStatementImpl: if (v < 0) v++;
  WhileStatementImpl: while (v > 0) v--;
''');
  }

  Future<void> test_switchExpression_members() async {
    final selection = await _computeSelection('''
String f(int x) {
  return switch (x) {
    1 => '1',
    [!2 => '2',
    3 => '3'!],
    4 => '4',
    _ => '5',
  };
}
''');
    _assertSelection(selection, r'''
nodesInRange
  SwitchExpressionCaseImpl: 2 => '2'
  SwitchExpressionCaseImpl: 3 => '3'
''');
  }

  Future<void> test_switchPatternCase_labels() async {
    final selection = await _computeSelection('''
void f((int, int) x) {
  switch (x) {
    a: [!b: c!]: d: case (1, 2): continue a;
    case (3, 4): continue b;
    case (5, 6): continue c;
    case (7, 8): continue d;
  }
}
''');
    _assertSelection(selection, r'''
nodesInRange
  LabelImpl: b:
  LabelImpl: c:
''');
  }

  Future<void> test_switchPatternCase_statements() async {
    final selection = await _computeSelection('''
void f((int, int) r) {
  switch (r) {
    case (1, 2):
      var v = 0;
      [!if (v < 0) v++;
      while (v > 0) v--;!]
      print(v);
      break;
  }
}
''');
    _assertSelection(selection, r'''
nodesInRange
  IfStatementImpl: if (v < 0) v++;
  WhileStatementImpl: while (v > 0) v--;
''');
  }

  Future<void> test_switchStatement_members() async {
    final selection = await _computeSelection('''
void f(int x) {
  switch (x) {
    case 1:
      break;
    [!case 2:
      break;
    case 3:
      break;!]
    case 4:
      break;
  }
}
''');
    _assertSelection(selection, r'''
nodesInRange
  SwitchPatternCaseImpl: case 2:\n      break;
  SwitchPatternCaseImpl: case 3:\n      break;
''');
  }

  Future<void> test_topLevelVariableDeclaration_metadata() async {
    await assertMetadata(postfix: '''
int x = 0;
''');
  }

  Future<void> test_tryStatement_catchClauses() async {
    final selection = await _computeSelection('''
void f() {
  try {
  } on A {
  } [!on B {
  } on C {!]
  } on D {
  }
}
class A {}
class B {}
class C {}
class D {}
''');
    _assertSelection(selection, r'''
nodesInRange
  CatchClauseImpl: on B {\n  }
  CatchClauseImpl: on C {\n  }
''');
  }

  Future<void> test_typeArgumentList_arguments() async {
    final selection = await _computeSelection('''
C<A, [!B, C!], D> c = C();
class A {}
class B {}
class C<Q, R, S, T> {}
class D {}
''');
    _assertSelection(selection, r'''
nodesInRange
  NamedTypeImpl: B
  NamedTypeImpl: C
''');
  }

  Future<void> test_typeParameter_metadata() async {
    await assertMetadata(prefix: '''
class C<
''', postfix: '''
T> {}
''');
  }

  Future<void> test_typeParameterList_typeParameters() async {
    final selection = await _computeSelection('''
class C<A, [!B, D!], E> {}
''');
    _assertSelection(selection, r'''
nodesInRange
  TypeParameterImpl: B
  TypeParameterImpl: D
''');
  }

  Future<void> test_variableDeclarationList_metadata() async {
    await assertMetadata(prefix: '''
void f() {
''', postfix: '''
  int x = 0;
}
''');
  }

  Future<void> test_variableDeclarationList_variables() async {
    final selection = await _computeSelection('''
var a = 1, [!b = 2, c = 3!], d = 4;
''');
    _assertSelection(selection, r'''
nodesInRange
  VariableDeclarationImpl: b = 2
  VariableDeclarationImpl: c = 3
''');
  }

  Future<void> test_withClause_mixinTypes() async {
    final selection = await _computeSelection('''
class C with A, [!B, D!], E {}
mixin A {}
mixin B {}
mixin D {}
mixin E {}
''');
    _assertSelection(selection, r'''
nodesInRange
  NamedTypeImpl: B
  NamedTypeImpl: D
''');
  }

  void _assertSelection(_CodeSelection selection, String expected) {
    final buffer = StringBuffer();
    _writeSelectionToBuffer(buffer, selection);
    _assertTextExpectation(buffer.toString(), expected);
  }

  void _assertTextExpectation(String actual, String expected) {
    if (actual != expected) {
      print('-' * 64);
      print(actual.trimRight());
      print('-' * 64);
      TextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  Future<_CodeSelection> _computeSelection(String annotatedCode) async {
    final testCode = TestCode.parse(annotatedCode);
    expect(testCode.positions, isEmpty);
    final range = testCode.range.sourceRange;

    await resolveTestCode(testCode.code);
    final selection = testUnit.select(
      offset: range.offset,
      length: range.length,
    )!;

    return _CodeSelection(
      testCode: testCode,
      selection: selection,
    );
  }

  void _writeSelectionToBuffer(StringBuffer buffer, _CodeSelection selection) {
    final rawCode = selection.testCode.code;

    buffer.writeln('nodesInRange');
    final nodes = selection.selection.nodesInRange();
    for (final node in nodes) {
      final nodeCode = rawCode.substring(node.offset, node.end);
      final nodeCodeEscaped = escape(nodeCode);
      buffer.writeln('  ${node.runtimeType}: $nodeCodeEscaped');
    }
  }
}

class _CodeSelection {
  final TestCode testCode;
  final Selection selection;

  _CodeSelection({
    required this.testCode,
    required this.selection,
  });
}
