// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/selection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SelectionTest);
  });
}

@reflectiveTest
class SelectionTest extends AbstractSingleUnitTest {
  @override
  List<String> get experiments => [
        ...super.experiments,
        EnableString.patterns,
      ];

  Future<void> assertMembers(
      {String prefix = '', required String postfix}) async {
    var nodes = await nodesInRange('''
$prefix
  int x = 0;
  [!void m1() {}
  int y = 1;!]
  void m2() {}
$postfix
''');
    expect(nodes, hasLength(2));
    nodes[0] as MethodDeclaration;
    nodes[1] as FieldDeclaration;
  }

  Future<void> assertMetadata(
      {String prefix = '', required String postfix}) async {
    var nodes = await nodesInRange('''
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
    expect(nodes, hasLength(2));
    expect((nodes[0] as Annotation).name.name, 'b');
    expect((nodes[1] as Annotation).name.name, 'c');
  }

  Future<List<AstNode>> nodesInRange(String sourceCode) async {
    var range = await _range(sourceCode);
    var selection =
        testUnit.select(offset: range.offset, length: range.length)!;
    return selection.nodesInRange();
  }

  Future<void> test_adjacentStrings_strings() async {
    var nodes = await nodesInRange('''
var s = 'a' [!'b' 'c'!] 'd';
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as StringLiteral).stringValue, 'b');
    expect((nodes[1] as StringLiteral).stringValue, 'c');
  }

  Future<void> test_argumentList_arguments() async {
    var nodes = await nodesInRange('''
var v = f('0', [!1, 2.0!], '3');
int f(a, b, c, d) => 0;
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as IntegerLiteral).value, 1);
    expect((nodes[1] as DoubleLiteral).value, 2.0);
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

  Future<void> test_block_statements() async {
    var nodes = await nodesInRange('''
void f() {
  var v = 0;
  [!if (v < 0) v++;
  while (v > 0) v--;!]
  print(v);
}
''');
    expect(nodes, hasLength(2));
    nodes[0] as IfStatement;
    nodes[1] as WhileStatement;
  }

  Future<void> test_cascadeExpression_cascadeSections() async {
    var nodes = await nodesInRange('''
void f(y) {
  var x = y..a()[!..b..c()!]..d;
}
''');
    expect(nodes, hasLength(2));
    nodes[0] as PropertyAccess;
    nodes[1] as MethodInvocation;
  }

  Future<void> test_classTypeAlias_metadata() async {
    await assertMetadata(postfix: '''
class A = C with M;
class C {}
mixin M {}
''');
  }

  Future<void> test_compilationUnit_declarations() async {
    var nodes = await nodesInRange('''
typedef F = void Function();
[!var x = 0;
void f() {}!]
class C {}
''');
    expect(nodes, hasLength(2));
    nodes[0] as TopLevelVariableDeclaration;
    nodes[1] as FunctionDeclaration;
  }

  Future<void> test_compilationUnit_directives() async {
    newFile('$testPackageLibPath/a.dart', "part of 'test.dart';");
    var nodes = await nodesInRange('''
library l;
[!import '';
export '';!]
part 'a.dart';
''');
    expect(nodes, hasLength(2));
    nodes[0] as ImportDirective;
    nodes[1] as ExportDirective;
  }

  Future<void> test_constructorDeclaration_initializers() async {
    var nodes = await nodesInRange('''
class C {
  int a, b, c, d;
  C() : a = 0, [!b = 1, c = 2,!] d = 4;
}
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as ConstructorFieldInitializer).fieldName.name, 'b');
    expect((nodes[1] as ConstructorFieldInitializer).fieldName.name, 'c');
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
    var nodes = await nodesInRange('''
library a.[!b.c!].d;
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as SimpleIdentifier).name, 'b');
    expect((nodes[1] as SimpleIdentifier).name, 'c');
  }

  Future<void> test_enumConstantDeclaration_metadata() async {
    await assertMetadata(prefix: '''
enum E {
''', postfix: '''
a }
''');
  }

  Future<void> test_enumDeclaration_constants() async {
    var nodes = await nodesInRange('''
enum E { a, [!b, c!], d }
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as EnumConstantDeclaration).name.lexeme, 'b');
    expect((nodes[1] as EnumConstantDeclaration).name.lexeme, 'c');
  }

  Future<void> test_enumDeclaration_members() async {
    var nodes = await nodesInRange('''
enum E {
  a;
  final int x = 0;
  [!void m1() {}
  final int y = 1;!]
  void m2() {}
}
''');
    expect(nodes, hasLength(2));
    nodes[0] as MethodDeclaration;
    nodes[1] as FieldDeclaration;
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
    var nodes = await nodesInRange('''
export 'a.dart' show a [!hide b show c!] hide d;
''');
    expect(nodes, hasLength(2));
    nodes[0] as HideCombinator;
    nodes[1] as ShowCombinator;
  }

  Future<void> test_exportDirective_configurations() async {
    var nodes = await nodesInRange('''
export '' if (a) '' [!if (b) '' if (c) ''!] if (d) '';
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as Configuration).name.toSource(), 'b');
    expect((nodes[1] as Configuration).name.toSource(), 'c');
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
    var nodes = await nodesInRange('''
extension on int {
  static int x = 0;
  [!void m1() {}
  static int y = 1;!]
  void m2() {}
}
''');
    expect(nodes, hasLength(2));
    nodes[0] as MethodDeclaration;
    nodes[1] as FieldDeclaration;
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
    var nodes = await nodesInRange('''
void f(a, [!b, {c!], d}) {}
''');
    expect(nodes, isEmpty);
  }

  Future<void> test_formalParameterList_parameters_named() async {
    var nodes = await nodesInRange('''
void f({a, [!b, c!], d}) {}
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as FormalParameter).name?.lexeme, 'b');
    expect((nodes[1] as FormalParameter).name?.lexeme, 'c');
  }

  Future<void> test_formalParameterList_parameters_positional() async {
    var nodes = await nodesInRange('''
void f(a, [!b, c!], d) {}
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as FormalParameter).name?.lexeme, 'b');
    expect((nodes[1] as FormalParameter).name?.lexeme, 'c');
  }

  Future<void> test_forPartsWithDeclarations_updaters() async {
    var nodes = await nodesInRange('''
void f() {
  for (var x = 0; x < 0; x++, [!x--, ++x!], --x) {}
}
''');
    expect(nodes, hasLength(2));
    nodes[0] as PostfixExpression;
    nodes[1] as PrefixExpression;
  }

  Future<void> test_forPartsWithExpression_updaters() async {
    var nodes = await nodesInRange('''
void f() {
  var x;
  for (x = 0; x < 0; x++, [!x--, ++x!], --x) {}
}
''');
    expect(nodes, hasLength(2));
    nodes[0] as PostfixExpression;
    nodes[1] as PrefixExpression;
  }

  Future<void> test_forPartsWithPattern_updaters() async {
    var nodes = await nodesInRange('''
void f() {
  for (var (x, y) = (0, 0); x < 0; x++, [!x--, ++x!], --x) {}
}
''');
    expect(nodes, hasLength(2));
    nodes[0] as PostfixExpression;
    nodes[1] as PrefixExpression;
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
    var nodes = await nodesInRange('''
import 'a.dart' hide a, [!b, c!], d;
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as SimpleIdentifier).name, 'b');
    expect((nodes[1] as SimpleIdentifier).name, 'c');
  }

  Future<void> test_implementsClause_interfaces() async {
    var nodes = await nodesInRange('''
class A implements B, [!C, D!], E {}
class B {}
class C {}
class D {}
class E {}
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as NamedType).name2.lexeme, 'C');
    expect((nodes[1] as NamedType).name2.lexeme, 'D');
  }

  Future<void> test_importDirective_combinators() async {
    newFile('$testPackageLibPath/a.dart', '''
int a, b, c, d;
''');
    var nodes = await nodesInRange('''
import 'a.dart' show a [!hide b show c!] hide d;
''');
    expect(nodes, hasLength(2));
    nodes[0] as HideCombinator;
    nodes[1] as ShowCombinator;
  }

  Future<void> test_importDirective_configurations() async {
    newFile('$testPackageLibPath/a.dart', '''
int a, b, c, d;
''');
    var nodes = await nodesInRange('''
import 'a.dart' if (a) '' [!if (b) '' if (c) ''!] if (d) '';
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as Configuration).name.toSource(), 'b');
    expect((nodes[1] as Configuration).name.toSource(), 'c');
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
    var nodes = await nodesInRange('''
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
    expect(nodes, hasLength(2));
    expect((nodes[0] as Label).label.name, 'b');
    expect((nodes[1] as Label).label.name, 'c');
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
    var nodes = await nodesInRange('''
library a.[!b.c!].d;
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as SimpleIdentifier).name, 'b');
    expect((nodes[1] as SimpleIdentifier).name, 'c');
  }

  Future<void> test_listLiteral_elements() async {
    var nodes = await nodesInRange('''
var l = ['0', [!1, 2.0!], '3'];
''');
    expect(nodes, hasLength(2));
    nodes[0] as IntegerLiteral;
    nodes[1] as DoubleLiteral;
  }

  Future<void> test_listPattern_elements() async {
    var nodes = await nodesInRange('''
void f(x) {
  switch (x) {
    case [1, [!2, 3!], 4]:
      break;
  }
}
''');
    expect(nodes, hasLength(2));
    expect(nodes[0].toSource(), '2');
    expect(nodes[1].toSource(), '3');
  }

  Future<void> test_mapPattern_entries() async {
    var nodes = await nodesInRange('''
void f(x) {
  switch (x) {
    case {'a': 1, [!'b': 2, 'c': 3!], 'd': 4}:
      break;
  }
}
''');
    expect(nodes, hasLength(2));
    expect(nodes[0].toSource(), "'b': 2");
    expect(nodes[1].toSource(), "'c': 3");
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
    await assertMembers(prefix: '''
mixin M {
''', postfix: '''
}
''');
  }

  Future<void> test_mixinDeclaration_metadata() async {
    await assertMetadata(postfix: '''
mixin M {}
''');
  }

  Future<void> test_objectPattern_fields() async {
    var nodes = await nodesInRange('''
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
    expect(nodes, hasLength(2));
    expect(nodes[0].toSource(), 'b: 2');
    expect(nodes[1].toSource(), 'c: 3');
  }

  Future<void> test_onClause_superclassConstraints() async {
    var nodes = await nodesInRange('''
mixin M on A, [!B, C!], D {}
class A {}
class B {}
class C {}
class D {}
''');
    expect(nodes, hasLength(2));
    expect(nodes[0].toSource(), 'B');
    expect(nodes[1].toSource(), 'C');
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
    var nodes = await nodesInRange('''
var r = ('0', [!1, 2.0!], '3');
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as IntegerLiteral).value, 1);
    expect((nodes[1] as DoubleLiteral).value, 2.0);
  }

  Future<void> test_recordPattern_fields() async {
    var nodes = await nodesInRange('''
void f((String, int, double, String) x) {
  switch (x) {
    case ('0', [!1, 2.0!], '3'):
      break;
  }
}
''');
    expect(nodes, hasLength(2));
    expect(nodes[0].toSource(), '1');
    expect(nodes[1].toSource(), '2.0');
  }

  Future<void> test_recordTypeAnnotation_positionalFields() async {
    var nodes = await nodesInRange('''
(int, [!String, int!], String) r = (0, '1', 2, '3');
''');
    expect(nodes, hasLength(2));
    expect(nodes[0].toSource(), 'String');
    expect(nodes[1].toSource(), 'int');
  }

  Future<void> test_recordTypeAnnotationNamedField_metadata() async {
    await assertMetadata(prefix: '''
void f(({
''', postfix: '''
int x}) r) {}
''');
  }

  Future<void> test_recordTypeAnnotationNamedFields_fields() async {
    var nodes = await nodesInRange('''
({int a, [!String b, int c!], String d}) r = (a: 0, b: '1', c: 2, d:'3');
''');
    expect(nodes, hasLength(2));
    expect(nodes[0].toSource(), 'String b');
    expect(nodes[1].toSource(), 'int c');
  }

  Future<void> test_recordTypeAnnotationPositionalField_metadata() async {
    await assertMetadata(prefix: '''
void f((int,
''', postfix: '''
int) r) {}
''');
  }

  Future<void> test_setOrMapLiteral_elements() async {
    var nodes = await nodesInRange('''
var s = {'0', [!1, 2.0!], '3'};
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as IntegerLiteral).value, 1);
    expect((nodes[1] as DoubleLiteral).value, 2.0);
  }

  Future<void> test_showCombinator_shownNames() async {
    newFile('$testPackageLibPath/a.dart', '''
int a, b, c, d;
''');
    var nodes = await nodesInRange('''
import 'a.dart' show a, [!b, c!], d;
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as SimpleIdentifier).name, 'b');
    expect((nodes[1] as SimpleIdentifier).name, 'c');
  }

  Future<void> test_simpleFormalParameter_metadata() async {
    await assertMetadata(prefix: '''
void f(
''', postfix: '''
int x) {}
''');
  }

  Future<void> test_stringInterpolation_elements() async {
    var nodes = await nodesInRange(r'''
void f(cd, gh) {
  var s = 'ab${c[!d}e!]f${gh}';
}
''');
    expect(nodes, hasLength(2));
    nodes[0] as InterpolationExpression;
    nodes[1] as InterpolationString;
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
    var nodes = await nodesInRange('''
void f(int x) {
  switch (x) {
    a: [!b: c!]: d: case 3: continue a;
    case 4: continue b;
    case 5: continue c;
    case 6: continue d;
  }
}
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as Label).label.name, 'b');
    expect((nodes[1] as Label).label.name, 'c');
  }

  Future<void> test_switchCase_statements() async {
    var nodes = await nodesInRange('''
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
    expect(nodes, hasLength(2));
    nodes[0] as IfStatement;
    nodes[1] as WhileStatement;
  }

  Future<void> test_switchDefault_labels() async {
    var nodes = await nodesInRange('''
void f(int x) {
  switch (x) {
    case 4: continue b;
    case 5: continue c;
    case 6: continue d;
    a: [!b: c!]: d: default: continue a;
  }
}
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as Label).label.name, 'b');
    expect((nodes[1] as Label).label.name, 'c');
  }

  Future<void> test_switchDefault_statements() async {
    var nodes = await nodesInRange('''
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
    expect(nodes, hasLength(2));
    nodes[0] as IfStatement;
    nodes[1] as WhileStatement;
  }

  Future<void> test_switchExpression_members() async {
    var nodes = await nodesInRange('''
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
    expect(nodes, hasLength(2));
    expect((nodes[0] as SwitchExpressionCase).expression.toSource(), "'2'");
    expect((nodes[1] as SwitchExpressionCase).expression.toSource(), "'3'");
  }

  Future<void> test_switchPatternCase_labels() async {
    var nodes = await nodesInRange('''
void f((int, int) x) {
  switch (x) {
    a: [!b: c!]: d: case (1, 2): continue a;
    case (3, 4): continue b;
    case (5, 6): continue c;
    case (7, 8): continue d;
  }
}
''');
    expect(nodes, hasLength(2));
    expect((nodes[0] as Label).label.name, 'b');
    expect((nodes[1] as Label).label.name, 'c');
  }

  Future<void> test_switchPatternCase_statements() async {
    var nodes = await nodesInRange('''
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
    expect(nodes, hasLength(2));
    nodes[0] as IfStatement;
    nodes[1] as WhileStatement;
  }

  Future<void> test_switchStatement_members() async {
    var nodes = await nodesInRange('''
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
    expect(nodes, hasLength(2));
    expect((nodes[0] as SwitchPatternCase).guardedPattern.toSource(), '2');
    expect((nodes[1] as SwitchPatternCase).guardedPattern.toSource(), '3');
  }

  Future<void> test_topLevelVariableDeclaration_metadata() async {
    await assertMetadata(postfix: '''
int x = 0;
''');
  }

  Future<void> test_tryStatement_catchClauses() async {
    var nodes = await nodesInRange('''
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
    expect(nodes, hasLength(2));
    expect((nodes[0] as CatchClause).exceptionType?.toSource(), 'B');
    expect((nodes[1] as CatchClause).exceptionType?.toSource(), 'C');
  }

  Future<void> test_typeArgumentList_arguments() async {
    var nodes = await nodesInRange('''
C<A, [!B, C!], D> c = C();
class A {}
class B {}
class C<Q, R, S, T> {}
class D {}
''');
    expect(nodes, hasLength(2));
    expect(nodes[0].toSource(), 'B');
    expect(nodes[1].toSource(), 'C');
  }

  Future<void> test_typeParameter_metadata() async {
    await assertMetadata(prefix: '''
class C<
''', postfix: '''
T> {}
''');
  }

  Future<void> test_typeParameterList_typeParameters() async {
    var nodes = await nodesInRange('''
class C<A, [!B, D!], E> {}
''');
    expect(nodes, hasLength(2));
    expect(nodes[0].toSource(), 'B');
    expect(nodes[1].toSource(), 'D');
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
    var nodes = await nodesInRange('''
var a = 1, [!b = 2, c = 3!], d = 4;
''');
    expect(nodes, hasLength(2));
    expect(nodes[0].toSource(), 'b = 2');
    expect(nodes[1].toSource(), 'c = 3');
  }

  Future<void> test_withClause_mixinTypes() async {
    var nodes = await nodesInRange('''
class C with A, [!B, D!], E {}
mixin A {}
mixin B {}
mixin D {}
mixin E {}
''');
    expect(nodes, hasLength(2));
    expect(nodes[0].toSource(), 'B');
    expect(nodes[1].toSource(), 'D');
  }

  Future<SourceRange> _range(String sourceCode) async {
    var parsedTestCode = TestCode.parse(sourceCode);
    await resolveTestCode(parsedTestCode.code);
    SourceRange range;
    if (parsedTestCode.positions.isEmpty) {
      expect(parsedTestCode.ranges, hasLength(1));
      range = parsedTestCode.range.sourceRange;
    } else {
      expect(parsedTestCode.positions, hasLength(1));
      expect(parsedTestCode.ranges, isEmpty);
      range = SourceRange(parsedTestCode.position.offset, 0);
    }
    return range;
  }
}
