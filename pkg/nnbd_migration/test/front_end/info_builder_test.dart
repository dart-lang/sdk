// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/front_end/info_builder.dart';
import 'package:nnbd_migration/src/front_end/migration_info.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_abstract.dart';
import 'nnbd_migration_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuildEnclosingMemberDescriptionTest);
    defineReflectiveTests(InfoBuilderTest);
  });
}

@reflectiveTest
class BuildEnclosingMemberDescriptionTest extends AbstractAnalysisTest {
  Future<ResolvedUnitResult> resolveTestFile() async {
    return await session.getResolvedUnit(testFile);
  }

  Future<void> test_classConstructor_named() async {
    addTestFile(r'''
class C {
  C.aaa();
}
''');
    var result = await resolveTestFile();
    ClassDeclaration class_ =
        result.unit.declarations.single as ClassDeclaration;
    var constructor = class_.members.single;
    expect(InfoBuilder.buildEnclosingMemberDescription(constructor),
        equals("the constructor 'C.aaa'"));
  }

  Future<void> test_classConstructor_unnamed() async {
    addTestFile(r'''
class C {
  C();
}
''');
    var result = await resolveTestFile();
    ClassDeclaration class_ =
        result.unit.declarations.single as ClassDeclaration;
    var constructor = class_.members.single;
    expect(InfoBuilder.buildEnclosingMemberDescription(constructor),
        equals("the default constructor of 'C'"));
  }

  Future<void> test_classField() async {
    addTestFile(r'''
class C {
  int i;
}
''');
    var result = await resolveTestFile();
    ClassDeclaration class_ =
        result.unit.declarations.single as ClassDeclaration;
    FieldDeclaration fieldDeclaration =
        class_.members.single as FieldDeclaration;
    var field = fieldDeclaration.fields.variables[0];
    expect(InfoBuilder.buildEnclosingMemberDescription(field),
        equals("the field 'C.i'"));
  }

  Future<void> test_classField_from_type() async {
    addTestFile(r'''
class C {
  int i;
}
''');
    var result = await resolveTestFile();
    ClassDeclaration class_ =
        result.unit.declarations.single as ClassDeclaration;
    FieldDeclaration fieldDeclaration =
        class_.members.single as FieldDeclaration;
    var type = fieldDeclaration.fields.type;
    expect(InfoBuilder.buildEnclosingMemberDescription(type),
        equals("the field 'C.i'"));
  }

  Future<void> test_classGetter() async {
    addTestFile(r'''
class C {
  int get aaa => 7;
}
''');
    var result = await resolveTestFile();
    ClassDeclaration class_ =
        result.unit.declarations.single as ClassDeclaration;
    var getter = class_.members.single;
    expect(InfoBuilder.buildEnclosingMemberDescription(getter),
        equals("the getter 'C.aaa'"));
  }

  Future<void> test_classMethod() async {
    addTestFile(r'''
class C {
  int aaa() => 7;
}
''');
    var result = await resolveTestFile();
    ClassDeclaration class_ =
        result.unit.declarations.single as ClassDeclaration;
    var method = class_.members.single;
    expect(InfoBuilder.buildEnclosingMemberDescription(method),
        equals("the method 'C.aaa'"));
  }

  Future<void> test_classOperator() async {
    addTestFile(r'''
class C {
  bool operator ==(Object other) => false;
}
''');
    var result = await resolveTestFile();
    ClassDeclaration class_ =
        result.unit.declarations.single as ClassDeclaration;
    var operator = class_.members.single;
    expect(InfoBuilder.buildEnclosingMemberDescription(operator),
        equals("the operator 'C.=='"));
  }

  Future<void> test_classSetter() async {
    addTestFile(r'''
class C {
  void set aaa(value) {}
}
''');
    var result = await resolveTestFile();
    ClassDeclaration class_ =
        result.unit.declarations.single as ClassDeclaration;
    var setter = class_.members.single;
    expect(InfoBuilder.buildEnclosingMemberDescription(setter),
        equals("the setter 'C.aaa='"));
  }

  Future<void> test_extensionMethod() async {
    addTestFile(r'''
extension E on List {
  int aaa() => 7;
}
''');
    var result = await resolveTestFile();
    ExtensionDeclaration extension_ =
        result.unit.declarations.single as ExtensionDeclaration;
    var method = extension_.members.single;
    expect(InfoBuilder.buildEnclosingMemberDescription(method),
        equals("the method 'E.aaa'"));
  }

  Future<void> test_extensionMethod_unnamed() async {
    addTestFile(r'''
extension on List {
  int aaa() => 7;
}
''');
    var result = await resolveTestFile();
    ExtensionDeclaration extension_ =
        result.unit.declarations.single as ExtensionDeclaration;
    var method = extension_.members.single;
    expect(InfoBuilder.buildEnclosingMemberDescription(method),
        equals("the method 'aaa' in unnamed extension on List<dynamic>"));
  }

  Future<void> test_mixinMethod() async {
    addTestFile(r'''
mixin C {
  int aaa() => 7;
}
''');
    var result = await resolveTestFile();
    MixinDeclaration mixin_ =
        result.unit.declarations.single as MixinDeclaration;
    var method = mixin_.members.single;
    expect(InfoBuilder.buildEnclosingMemberDescription(method),
        equals("the method 'C.aaa'"));
  }

  Future<void> test_topLevelFunction() async {
    addTestFile(r'''
void aaa(value) {}
''');
    var result = await resolveTestFile();
    var function = result.unit.declarations.single;
    expect(InfoBuilder.buildEnclosingMemberDescription(function),
        equals("the function 'aaa'"));
  }

  Future<void> test_topLevelGetter() async {
    addTestFile(r'''
int get aaa => 7;
''');
    var result = await resolveTestFile();
    var getter = result.unit.declarations.single;
    expect(InfoBuilder.buildEnclosingMemberDescription(getter),
        equals("the getter 'aaa'"));
  }

  Future<void> test_topLevelSetter() async {
    addTestFile(r'''
void set aaa(value) {}
''');
    var result = await resolveTestFile();
    var setter = result.unit.declarations.single;
    expect(InfoBuilder.buildEnclosingMemberDescription(setter),
        equals("the setter 'aaa='"));
  }

  Future<void> test_topLevelVariable() async {
    addTestFile(r'''
int i;
''');
    var result = await resolveTestFile();
    TopLevelVariableDeclaration topLevelVariableDeclaration =
        result.unit.declarations.single as TopLevelVariableDeclaration;
    var variable = topLevelVariableDeclaration.variables.variables[0];
    expect(InfoBuilder.buildEnclosingMemberDescription(variable),
        equals("the variable 'i'"));
  }

  Future<void> test_topLevelVariable_from_type() async {
    addTestFile(r'''
int i;
''');
    var result = await resolveTestFile();
    TopLevelVariableDeclaration topLevelVariableDeclaration =
        result.unit.declarations.single as TopLevelVariableDeclaration;
    var type = topLevelVariableDeclaration.variables.type;
    expect(InfoBuilder.buildEnclosingMemberDescription(type),
        equals("the variable 'i'"));
  }
}

@reflectiveTest
class InfoBuilderTest extends NnbdMigrationTestBase {
  /// Assert various properties of the given [edit].
  bool assertEdit(
      {@required EditDetail edit, int offset, int length, String replacement}) {
    expect(edit, isNotNull);
    if (offset != null) {
      expect(edit.offset, offset);
    }
    if (length != null) {
      expect(edit.length, length);
    }
    if (replacement != null) {
      expect(edit.replacement, replacement);
    }
    return true;
  }

  List<RegionInfo> getNonInformativeRegions(List<RegionInfo> regions) {
    return regions
        .where((region) =>
            region.kind != NullabilityFixKind.typeNotMadeNullable &&
            region.kind != NullabilityFixKind.typeNotMadeNullableDueToHint)
        .toList();
  }

  Future<void> test_addLate() async {
    var content = '''
f() {
  String s;
  if (1 == 2) s = "Hello";
  g(s);
}
g(String /*!*/ s) {}
''';
    var migratedContent = '''
f() {
  late String  s;
  if (1 == 2) s = "Hello";
  g(s);
}
g(String /*!*/ s) {}
''';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = unit.fixRegions;
    expect(regions, hasLength(2));
    var region = regions[0];
    assertRegion(
        region: region,
        offset: 8,
        length: 4,
        explanation: 'Added a late keyword',
        kind: NullabilityFixKind.addLate);
  }

  Future<void> test_addLate_dueToHint() async {
    var content = '/*late*/ int x = 0;';
    var migratedContent = '/*late*/ int  x = 0;';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = unit.fixRegions;
    expect(regions, hasLength(2));
    var textToRemove = '/*late*/ ';
    assertRegionPair(regions, 0,
        offset1: migratedContent.indexOf('/*'),
        length1: 2,
        offset2: migratedContent.indexOf('*/'),
        length2: 2,
        explanation: 'Added a late keyword, due to a hint',
        kind: NullabilityFixKind.addLateDueToHint,
        edits: (List<EditDetail> edits) => assertEdit(
            edit: edits.single,
            offset: content.indexOf(textToRemove),
            length: textToRemove.length,
            replacement: ''));
  }

  Future<void> test_addLate_dueToTestSetup() async {
    addTestCorePackage();
    var content = '''
import 'package:test/test.dart';
void main() {
  int i;
  setUp(() {
    i = 1;
  });
  test('a', () {
    f(i);
  });
  f(int /*?*/ i) {}
}
''';
    var migratedContent = '''
import 'package:test/test.dart';
void main() {
  late int  i;
  setUp(() {
    i = 1;
  });
  test('a', () {
    f(i);
  });
  f(int /*?*/ i) {}
}
''';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = unit.fixRegions;
    expect(regions, hasLength(3));
    var region = regions[0];
    assertRegion(
        region: region,
        offset: 49,
        length: 4,
        explanation: 'Added a late keyword, due to assignment in `setUp`',
        kind: NullabilityFixKind.addLateDueToTestSetup);
  }

  Future<void> test_addLateFinal_dueToHint() async {
    var content = '/*late final*/ int x = 0;';
    var migratedContent = '/*late final*/ int  x = 0;';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = unit.fixRegions;
    expect(regions, hasLength(2));
    var textToRemove = '/*late final*/ ';
    assertRegionPair(regions, 0,
        offset1: migratedContent.indexOf('/*'),
        length1: 2,
        offset2: migratedContent.indexOf('*/'),
        length2: 2,
        explanation: 'Added late and final keywords, due to a hint',
        kind: NullabilityFixKind.addLateFinalDueToHint,
        edits: (List<EditDetail> edits) => assertEdit(
            edit: edits.single,
            offset: content.indexOf(textToRemove),
            length: textToRemove.length,
            replacement: ''));
  }

  Future<void> test_compound_assignment_nullable_result() async {
    var unit = await buildInfoForSingleTestFile('''
abstract class C {
  C/*?*/ operator+(int i);
}
void f(C/*!*/ a, int b) {
  a += b;
}
''', migratedContent: '''
abstract class C {
  C/*?*/ operator+(int  i);
}
void f(C/*!*/ a, int  b) {
  a += b;
}
''');
    var operator = '+=';
    var operatorOffset = unit.content.indexOf(operator);
    var region =
        unit.regions.where((region) => region.offset == operatorOffset).single;
    assertRegion(
        region: region,
        length: operator.length,
        explanation: 'Compound assignment has bad combined type',
        kind: NullabilityFixKind.compoundAssignmentHasBadCombinedType,
        edits: isEmpty);
  }

  Future<void> test_compound_assignment_nullable_source() async {
    var unit = await buildInfoForSingleTestFile('''
void f(int/*?*/ a, int b) {
  a += b;
}
''', migratedContent: '''
void f(int/*?*/ a, int  b) {
  a += b;
}
''');
    var operator = '+=';
    var operatorOffset = unit.content.indexOf(operator);
    var region =
        unit.regions.where((region) => region.offset == operatorOffset).single;
    assertRegion(
        region: region,
        length: operator.length,
        explanation: 'Compound assignment has nullable source',
        kind: NullabilityFixKind.compoundAssignmentHasNullableSource,
        edits: isEmpty);
  }

  Future<void> test_conditionFalseInStrongMode_expression() async {
    var unit = await buildInfoForSingleTestFile(
        'int f(String s) => s == null ? 0 : s.length;',
        migratedContent:
            'int  f(String  s) => s == null /* == false */ ? 0 : s.length;',
        warnOnWeakCode: true);
    var insertedComment = '/* == false */';
    var insertedCommentOffset = unit.content.indexOf(insertedComment);
    var region = unit.regions
        .where((region) => region.offset == insertedCommentOffset)
        .single;
    assertRegion(
        region: region,
        length: insertedComment.length,
        explanation: 'Condition will always be false in strong checking mode',
        kind: NullabilityFixKind.conditionFalseInStrongMode,
        edits: isEmpty);
  }

  Future<void> test_conditionFalseInStrongMode_if() async {
    var unit = await buildInfoForSingleTestFile('''
int f(String s) {
  if (s == null) {
    return 0;
  } else {
    return s.length;
  }
}
''', migratedContent: '''
int  f(String  s) {
  if (s == null /* == false */) {
    return 0;
  } else {
    return s.length;
  }
}
''', warnOnWeakCode: true);
    var insertedComment = '/* == false */';
    var insertedCommentOffset = unit.content.indexOf(insertedComment);
    var region = unit.regions
        .where((region) => region.offset == insertedCommentOffset)
        .single;
    assertRegion(
        region: region,
        length: insertedComment.length,
        explanation: 'Condition will always be false in strong checking mode',
        kind: NullabilityFixKind.conditionFalseInStrongMode,
        edits: isEmpty);
  }

  Future<void> test_conditionTrueInStrongMode_expression() async {
    var unit = await buildInfoForSingleTestFile(
        'int f(String s) => s != null ? s.length : 0;',
        migratedContent:
            'int  f(String  s) => s != null /* == true */ ? s.length : 0;',
        warnOnWeakCode: true);
    var insertedComment = '/* == true */';
    var insertedCommentOffset = unit.content.indexOf(insertedComment);
    var region = unit.regions
        .where((region) => region.offset == insertedCommentOffset)
        .single;
    assertRegion(
        region: region,
        length: insertedComment.length,
        explanation: 'Condition will always be true in strong checking mode',
        kind: NullabilityFixKind.conditionTrueInStrongMode,
        edits: isEmpty);
  }

  Future<void> test_conditionTrueInStrongMode_if() async {
    var unit = await buildInfoForSingleTestFile('''
int f(String s) {
  if (s != null) {
    return s.length;
  } else {
    return 0;
  }
}
''', migratedContent: '''
int  f(String  s) {
  if (s != null /* == true */) {
    return s.length;
  } else {
    return 0;
  }
}
''', warnOnWeakCode: true);
    var insertedComment = '/* == true */';
    var insertedCommentOffset = unit.content.indexOf(insertedComment);
    var region = unit.regions
        .where((region) => region.offset == insertedCommentOffset)
        .single;
    assertRegion(
        region: region,
        length: insertedComment.length,
        explanation: 'Condition will always be true in strong checking mode',
        kind: NullabilityFixKind.conditionTrueInStrongMode,
        edits: isEmpty);
  }

  Future<void> test_discardCondition() async {
    var unit = await buildInfoForSingleTestFile('''
void g(int i) {
  print(i.isEven);
  if (i != null) print('NULL');
}
''', migratedContent: '''
void g(int  i) {
  print(i.isEven);
  /* if (i != null) */ print('NULL');
}
''');
    var regions = unit.fixRegions;
    expect(regions, hasLength(2));
    assertRegion(
        region: regions[0],
        offset: 38,
        length: 3,
        kind: NullabilityFixKind.removeDeadCode);
    assertRegion(
        region: regions[1],
        offset: 56,
        length: 3,
        kind: NullabilityFixKind.removeDeadCode);
  }

  Future<void> test_downcast_nonNullable() async {
    var content = 'int/*!*/ f(num/*!*/ n) => n;';
    var migratedContent = 'int/*!*/ f(num/*!*/ n) => n as int;';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = getNonInformativeRegions(unit.regions);
    expect(regions, hasLength(1));
    var region = regions.single;
    var regionTarget = ' as int';
    assertRegion(
        region: region,
        offset: migratedContent.indexOf(regionTarget),
        length: regionTarget.length,
        kind: NullabilityFixKind.downcastExpression,
        edits: isEmpty,
        traces: isEmpty);
  }

  Future<void> test_downcast_nonNullable_to_nullable() async {
    var content = 'int/*?*/ f(num/*!*/ n) => n;';
    // TODO(paulberry): we should actually cast to `int`, not `int?`, because we
    // know `n` is non-nullable.
    var migratedContent = 'int/*?*/ f(num/*!*/ n) => n as int?;';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = getNonInformativeRegions(unit.regions);
    var regionTarget = ' as int?';
    var offset = migratedContent.indexOf(regionTarget);
    var region = regions.where((region) => region.offset == offset).single;
    // TODO(paulberry): once we are correctly casting to `int`, not `int?`, this
    // should be classified as a downcast.  Currently it's classified as a side
    // cast.
    assertRegion(
        region: region,
        offset: offset,
        length: regionTarget.length,
        kind: NullabilityFixKind.otherCastExpression,
        edits: isEmpty,
        traces: isEmpty);
  }

  Future<void> test_downcast_nullable() async {
    var content = 'int/*?*/ f(num/*?*/ n) => n;';
    var migratedContent = 'int/*?*/ f(num/*?*/ n) => n as int?;';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = getNonInformativeRegions(unit.regions);
    var regionTarget = ' as int?';
    var offset = migratedContent.indexOf(regionTarget);
    var region = regions.where((region) => region.offset == offset).single;
    assertRegion(
        region: region,
        offset: offset,
        length: regionTarget.length,
        kind: NullabilityFixKind.downcastExpression,
        edits: isEmpty,
        traces: isEmpty);
  }

  Future<void> test_downcast_nullable_to_nonNullable() async {
    var content = 'int/*!*/ f(num/*?*/ n) => n;';
    var migratedContent = 'int/*!*/ f(num/*?*/ n) => n as int;';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = getNonInformativeRegions(unit.regions);
    var regionTarget = ' as int';
    var offset = migratedContent.indexOf(regionTarget);
    var region = regions.where((region) => region.offset == offset).single;
    assertRegion(
        region: region,
        offset: offset,
        length: regionTarget.length,
        kind: NullabilityFixKind.downcastExpression,
        edits: isEmpty,
        traces: isNotEmpty);
  }

  Future<void> test_downcast_with_traces() async {
    var content = 'List<int/*!*/>/*!*/ f(List<int/*?*/>/*?*/ x) => x;';
    var migratedContent =
        'List<int/*!*/>/*!*/ f(List<int/*?*/>/*?*/ x) => x as List<int>;';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = unit.regions.where(
        (region) => region.kind == NullabilityFixKind.downcastExpression);
    expect(regions, hasLength(1));
    var region = regions.single;
    var regionTarget = ' as List<int>';
    assertRegion(
        region: region,
        offset: migratedContent.indexOf(regionTarget),
        length: regionTarget.length,
        kind: NullabilityFixKind.downcastExpression,
        edits: isEmpty,
        traces: isNotEmpty);
    var traceDescriptionToOffset = {
      for (var trace in region.traces)
        trace.description: trace.entries[0].target.offset
    };
    expect(traceDescriptionToOffset, {
      'Nullability reason': content.indexOf('List<int/*?*/>/*?*/'),
      'Non-nullability reason': content.indexOf('List<int/*!*/>/*!*/'),
      'Nullability reason for type argument 0': content.indexOf('int/*?*/'),
      'Non-nullability reason for type argument 0': content.indexOf('int/*!*/')
    });
  }

  Future<void> test_dynamicValueIsUsed() async {
    var unit = await buildInfoForSingleTestFile('''
bool f(int i) {
  if (i == null) return true;
  else return false;
}
void g() {
  dynamic i = null;
  f(i);
}
''', migratedContent: '''
bool  f(int? i) {
  if (i == null) return true;
  else return false;
}
void g() {
  dynamic i = null;
  f(i);
}
''');
    var regions = unit.fixRegions;
    expect(regions, hasLength(1));
    var region = regions[0];
    var edits = region.edits;
    assertRegion(
        region: region,
        offset: 11,
        explanation: "Changed type 'int' to be nullable");
    assertEdit(edit: edits[0], offset: 10, replacement: '/*!*/');
    assertEdit(edit: edits[1], offset: 10, replacement: '/*?*/');
  }

  Future<void> test_expressionFunctionReturnTarget() async {
    var unit = await buildInfoForSingleTestFile('''
String g() => 1 == 2 ? "Hello" : null;
''', migratedContent: '''
String? g() => 1 == 2 ? "Hello" : null;
''');
    assertInTargets(targets: unit.targets, offset: 7, length: 1); // "g"
    var regions = unit.regions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 6,
        explanation: "Changed type 'String' to be nullable");
  }

  Future<void> test_function_typed_parameter_made_nullable_due_to_hint() async {
    var content = 'f(void g(int i)/*?*/) {}';
    var migratedContent = 'f(void g(int  i)/*?*/) {}';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = unit.fixRegions;
    expect(regions, hasLength(2));
    var textToRemove = '/*?*/';
    assertRegionPair(regions, 0,
        offset1: migratedContent.indexOf(textToRemove),
        length1: 2,
        offset2: migratedContent.indexOf(textToRemove) + 3,
        length2: 2,
        explanation:
            "Changed type 'void Function(int)' to be nullable, due to a "
            'nullability hint',
        kind: NullabilityFixKind.makeTypeNullableDueToHint,
        traces: isNotNull, edits: (List<EditDetail> edits) {
      expect(edits, hasLength(2));
      var editsByDescription = {for (var edit in edits) edit.description: edit};
      assertEdit(
          edit: editsByDescription['Change to /*!*/ hint'],
          offset: content.indexOf(textToRemove),
          length: textToRemove.length,
          replacement: '/*!*/');
      assertEdit(
          edit: editsByDescription['Remove /*?*/ hint'],
          offset: content.indexOf(textToRemove),
          length: textToRemove.length,
          replacement: '');
      return true;
    });
  }

  Future<void> test_increment_nullable_result() async {
    var unit = await buildInfoForSingleTestFile('''
abstract class C {
  C/*?*/ operator+(int i);
}
void f(C/*!*/ a) {
  a++;
}
''', migratedContent: '''
abstract class C {
  C/*?*/ operator+(int  i);
}
void f(C/*!*/ a) {
  a++;
}
''');
    var operator = '++';
    var operatorOffset = unit.content.indexOf(operator);
    var region =
        unit.regions.where((region) => region.offset == operatorOffset).single;
    assertRegion(
        region: region,
        length: operator.length,
        explanation: 'Compound assignment has bad combined type',
        kind: NullabilityFixKind.compoundAssignmentHasBadCombinedType,
        edits: isEmpty);
  }

  Future<void> test_increment_nullable_source() async {
    var unit = await buildInfoForSingleTestFile('''
void f(int/*?*/ a) {
  a++;
}
''', migratedContent: '''
void f(int/*?*/ a) {
  a++;
}
''');
    var operator = '++';
    var operatorOffset = unit.content.indexOf(operator);
    var region =
        unit.regions.where((region) => region.offset == operatorOffset).single;
    assertRegion(
        region: region,
        length: operator.length,
        explanation: 'Compound assignment has nullable source',
        kind: NullabilityFixKind.compoundAssignmentHasNullableSource,
        edits: isEmpty);
  }

  Future<void> test_insertedRequired_fieldFormal_hint() async {
    var unit = await buildInfoForSingleTestFile('''
class C {
  int level;
  int level2;
  C({this.level}) : this.level2 = level + 1;
}
''', migratedContent: '''
class C {
  int  level;
  int  level2;
  C({required this.level}) : this.level2 = level + 1;
}
''');
    var regions = unit.fixRegions;
    expect(regions, hasLength(1));
    var region = regions[0];
    var edits = region.edits;
    assertRegion(
        region: region,
        offset: 44,
        length: 9,
        explanation: "Add 'required' keyword to parameter 'level' in 'C.'",
        kind: NullabilityFixKind.addRequired);
    assertEdit(
        edit: edits[0], offset: 42, length: 0, replacement: '/*required*/ ');
  }

  Future<void> test_insertedRequired_fieldFormal() async {
    addMetaPackage();
    var unit = await buildInfoForSingleTestFile('''
import 'package:meta/meta.dart';
class C {
  int level;
  int level2;
  C({this.level}) : this.level2 = level + 1;
}
''', migratedContent: '''
import 'package:meta/meta.dart';
class C {
  int  level;
  int  level2;
  C({required this.level}) : this.level2 = level + 1;
}
''');
    var regions = unit.fixRegions;
    expect(regions, hasLength(1));
    var region = regions[0];
    var edits = region.edits;
    assertRegion(
        region: region,
        offset: 77,
        length: 9,
        explanation: "Add 'required' keyword to parameter 'level' in 'C.'",
        kind: NullabilityFixKind.addRequired);
    assertEdit(
        edit: edits[0], offset: 75, length: 0, replacement: '@required ');
  }

  Future<void> test_insertedRequired_parameter_hint() async {
    var unit = await buildInfoForSingleTestFile('''
class C {
  int level = 0;
  bool f({int lvl}) => lvl >= level;
}
''', migratedContent: '''
class C {
  int  level = 0;
  bool  f({required int  lvl}) => lvl >= level;
}
''');
    var regions = unit.fixRegions;
    expect(regions, hasLength(1));
    var region = regions[0];
    var edits = region.edits;
    assertRegion(
        region: region,
        offset: 39,
        length: 9,
        explanation: "Add 'required' keyword to parameter 'lvl' in 'C.f'",
        kind: NullabilityFixKind.addRequired);
    assertEdit(
        edit: edits[0], offset: 37, length: 0, replacement: '/*required*/ ');
  }

  Future<void> test_insertedRequired_parameter_metaPrefixed() async {
    addMetaPackage();
    var unit = await buildInfoForSingleTestFile('''
import 'package:meta/meta.dart' as meta;
class C {
  int level = 0;
  bool f({int lvl}) => lvl >= level;
}
''', migratedContent: '''
import 'package:meta/meta.dart' as meta;
class C {
  int  level = 0;
  bool  f({required int  lvl}) => lvl >= level;
}
''');
    var regions = unit.fixRegions;
    expect(regions, hasLength(1));
    var region = regions[0];
    var edits = region.edits;
    assertEdit(
        edit: edits[0], offset: 78, length: 0, replacement: '@meta.required ');
  }

  Future<void> test_insertedRequired_parameter() async {
    addMetaPackage();
    var unit = await buildInfoForSingleTestFile('''
import 'package:meta/meta.dart';
class C {
  int level = 0;
  bool f({int lvl}) => lvl >= level;
}
''', migratedContent: '''
import 'package:meta/meta.dart';
class C {
  int  level = 0;
  bool  f({required int  lvl}) => lvl >= level;
}
''');
    var regions = unit.fixRegions;
    expect(regions, hasLength(1));
    var region = regions[0];
    var edits = region.edits;
    assertRegion(
        region: region,
        offset: 72,
        length: 9,
        explanation: "Add 'required' keyword to parameter 'lvl' in 'C.f'",
        kind: NullabilityFixKind.addRequired);
    assertEdit(
        edit: edits[0], offset: 70, length: 0, replacement: '@required ');
  }

  Future<void> test_insertParens() async {
    var originalContent = '''
class C {
  C operator+(C c) => null;
}
C/*!*/ _f(C c) => c + c;
''';
    var migratedContent = '''
class C {
  C? operator+(C  c) => null;
}
C/*!*/ _f(C  c) => (c + c)!;
''';
    var unit = await buildInfoForSingleTestFile(originalContent,
        migratedContent: migratedContent);
    var regions = unit.fixRegions;
    expect(regions, hasLength(3));
    assertRegion(
        region: regions[0],
        offset: migratedContent.indexOf('? operator'),
        length: 1,
        explanation: "Changed type 'C' to be nullable");
    assertRegion(
        region: regions[1],
        offset: migratedContent.indexOf('/*!*/'),
        length: 5,
        explanation: "Type 'C' was not made nullable due to a hint",
        kind: NullabilityFixKind.typeNotMadeNullableDueToHint);
    assertRegion(
        region: regions[2],
        offset: migratedContent.indexOf('!;'),
        length: 1,
        explanation: 'Added a non-null assertion to nullable expression',
        kind: NullabilityFixKind.checkExpression);
  }

  Future<void> test_method_name_change() async {
    addPackageFile('collection', 'collection.dart', '');
    var content = '''
import 'package:collection/collection.dart';

int f(List<int> values, int/*?*/ x)
    => values.firstWhere((i) => (i + x).isEven,
        orElse: () => null);
''';
    var migratedContent = '''
import 'package:collection/collection.dart';

int? f(List<int >  values, int/*?*/ x)
    => values.firstWherefirstWhereOrNull((i) => (i + x!).isEven,
        orElse: () => null);
''';
    await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent, removeViaComments: false);
  }

  void test_nullAwareAssignment_remove() async {
    var unit = await buildInfoForSingleTestFile('''
int f(int/*!*/ x, int y) => x ??= y;
''', migratedContent: '''
int  f(int/*!*/ x, int  y) => x ??= y;
''', warnOnWeakCode: false, removeViaComments: false);
    var codeToRemove = ' ??= y';
    var removalOffset = unit.content.indexOf(codeToRemove);
    var region =
        unit.regions.where((region) => region.offset == removalOffset).single;
    assertRegion(
        region: region,
        length: codeToRemove.length,
        explanation:
            'Removed a null-aware assignment, because the target cannot be '
            'null',
        kind: NullabilityFixKind.removeDeadCode,
        edits: isEmpty);
  }

  void test_nullAwareAssignment_unnecessaryInStrongMode() async {
    var unit = await buildInfoForSingleTestFile('''
int f(int/*!*/ x, int y) => x ??= y;
''', migratedContent: '''
int  f(int/*!*/ x, int  y) => x ??= y;
''', warnOnWeakCode: true);
    var operator = '??=';
    var operatorOffset = unit.content.indexOf(operator);
    var region =
        unit.regions.where((region) => region.offset == operatorOffset).single;
    assertRegion(
        region: region,
        length: operator.length,
        explanation:
            'Null-aware assignment will be unnecessary in strong checking mode',
        kind: NullabilityFixKind.nullAwareAssignmentUnnecessaryInStrongMode,
        edits: isEmpty);
  }

  void test_nullAwarenessUnnecessaryInStrongMode() async {
    var unit = await buildInfoForSingleTestFile('''
int f(String s) => s?.length;
''', migratedContent: '''
int  f(String  s) => s?.length;
''', warnOnWeakCode: true);
    var question = '?';
    var questionOffset = unit.content.indexOf(question);
    var region =
        unit.regions.where((region) => region.offset == questionOffset).single;
    assertRegion(
        region: region,
        length: question.length,
        explanation:
            'Null-aware access will be unnecessary in strong checking mode',
        kind: NullabilityFixKind.nullAwarenessUnnecessaryInStrongMode,
        edits: isEmpty);
  }

  Future<void> test_nullCheck_dueToHint() async {
    var content = 'int f(int/*?*/ x) => x/*!*/;';
    var migratedContent = 'int  f(int/*?*/ x) => x/*!*/;';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = unit.fixRegions;
    expect(regions, hasLength(4));
    assertRegionPair(regions, 0,
        kind: NullabilityFixKind.makeTypeNullableDueToHint);
    var hintText = '/*!*/';
    assertRegionPair(regions, 2,
        offset1: migratedContent.indexOf(hintText),
        length1: 2,
        offset2: migratedContent.indexOf(hintText) + 3,
        length2: 2,
        explanation: 'Accepted a null check hint',
        kind: NullabilityFixKind.checkExpressionDueToHint,
        traces: isNotEmpty,
        edits: ((List<EditDetail> edits) => assertEdit(
            edit: edits.single,
            offset: content.indexOf(hintText),
            length: hintText.length,
            replacement: '')));
  }

  Future<void> test_nullCheck_onMemberAccess() async {
    var unit = await buildInfoForSingleTestFile('''
class C {
  int value;
  C([this.value]);
  void f() {
    value.sign;
  }
}
''', migratedContent: '''
class C {
  int? value;
  C([this.value]);
  void f() {
    value!.sign;
  }
}
''');
    var regions = unit.regions;
    expect(regions, hasLength(2));
    // regions[0] is `int?`.
    var region = regions[1];
    var edits = region.edits;
    assertRegion(
        region: regions[1],
        offset: 65,
        explanation: 'Added a non-null assertion to nullable expression',
        kind: NullabilityFixKind.checkExpression);
    assertEdit(edit: edits[0], offset: 64, length: 0, replacement: '/*!*/');
  }

  Future<void> test_parameter_fromOverriddenField_explicit() async {
    var unit = await buildInfoForSingleTestFile('''
class A {
  int m;
}
class B extends A {
  void set m(Object p) {}
}
void f(A a) => a.m = null;
''', migratedContent: '''
class A {
  int? m;
}
class B extends A {
  void set m(Object? p) {}
}
void f(A  a) => a.m = null;
''');
    var regions = unit.fixRegions;
    expect(regions, hasLength(2));
    assertRegion(
        region: regions[0],
        offset: 15,
        explanation: "Changed type 'int' to be nullable");
    assertRegion(
        region: regions[1],
        offset: 61,
        explanation: "Changed type 'Object' to be nullable");

    expect(regions[0].traces, hasLength(1));
    var trace = regions[0].traces.first;
    expect(trace.description, 'Nullability reason');
    var entries = trace.entries;
    expect(entries, hasLength(2));
    assertTraceEntry(unit, entries[0], 'A.m', unit.content.indexOf('int?'),
        contains('A.m (test.dart:2:3)'));
  }

  Future<void> test_removal_handles_offsets_correctly() async {
    var originalContent = '''
void f(num n, int/*?*/ i) {
  if (n is! int) return;
  print((n as int).isEven);
  print(i + 1);
}
''';
    // Note: even though `as int` is removed, it still shows up in the
    // preview, since we show deleted text.
    var migratedContent = '''
void f(num  n, int/*?*/ i) {
  if (n is! int ) return;
  print((n as int).isEven);
  print(i! + 1);
}
''';
    var unit = await buildInfoForSingleTestFile(originalContent,
        migratedContent: migratedContent, removeViaComments: false);
    var regions = unit.fixRegions;
    expect(regions, hasLength(4));
    assertRegionPair(regions, 0,
        kind: NullabilityFixKind.makeTypeNullableDueToHint);
    assertRegion(
        region: regions[2],
        offset: migratedContent.indexOf(' as int'),
        length: ' as int'.length,
        explanation: 'Discarded a downcast that is now unnecessary',
        kind: NullabilityFixKind.removeAs);
    assertRegion(
        region: regions[3],
        offset: migratedContent.indexOf('! + 1'),
        explanation: 'Added a non-null assertion to nullable expression',
        kind: NullabilityFixKind.checkExpression);
  }

  Future<void> test_returnDetailTarget() async {
    var unit = await buildInfoForSingleTestFile('''
String g() {
  return 1 == 2 ? "Hello" : null;
}
''', migratedContent: '''
String? g() {
  return 1 == 2 ? "Hello" : null;
}
''');
    assertInTargets(targets: unit.targets, offset: 7, length: 1); // "g"
    var regions = unit.regions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 6,
        explanation: "Changed type 'String' to be nullable");
  }

  Future<void> test_suspicious_cast() async {
    var content = '''
int f(Object o) {
  if (o is! String) return 0;
  return o;
}
''';
    var migratedContent = '''
int  f(Object  o) {
  if (o is! String ) return 0;
  return o as int;
}
''';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = getNonInformativeRegions(unit.regions);
    expect(regions, hasLength(1));
    var region = regions.single;
    var regionTarget = ' as int';
    assertRegion(
        region: region,
        offset: migratedContent.indexOf(regionTarget),
        length: regionTarget.length,
        kind: NullabilityFixKind.otherCastExpression,
        edits: isEmpty);
  }

  Future<void> test_trace_constructor_named() async {
    var unit = await buildInfoForSingleTestFile('''
class C {
  C.named(int i) {}
}
void f() {
  C.named(null);
}
''', migratedContent: '''
class C {
  C.named(int? i) {}
}
void f() {
  C.named(null);
}
''');
    var region = unit.regions
        .where((info) => info.offset == unit.content.indexOf('? i) {}'))
        .single;
    expect(region.traces, hasLength(1));
    var trace = region.traces.single;
    expect(trace.description, 'Nullability reason');
    var entries = trace.entries;
    assertTraceEntry(unit, entries[0], 'C.named',
        unit.content.indexOf('int? i) {}'), contains('parameter 0 of C.named'));
  }

  Future<void> test_trace_constructor_unnamed() async {
    var unit = await buildInfoForSingleTestFile('''
class C {
  C(int i) {}
}
void f() {
  C(null);
}
''', migratedContent: '''
class C {
  C(int? i) {}
}
void f() {
  C(null);
}
''');
    var region = unit.regions
        .where((info) => info.offset == unit.content.indexOf('? i) {}'))
        .single;
    expect(region.traces, hasLength(1));
    var trace = region.traces.single;
    expect(trace.description, 'Nullability reason');
    var entries = trace.entries;
    assertTraceEntry(
        unit,
        entries[0],
        'C.<unnamed>',
        unit.content.indexOf('int? i) {}'),
        contains('parameter 0 of C.<unnamed>'));
  }

  Future<void> test_trace_deadCode() async {
    var unit = await buildInfoForSingleTestFile('''
void f(int/*!*/ i) {
  if (i == null) return;
}
''', migratedContent: '''
void f(int/*!*/ i) {
  /* if (i == null) return; */
}
''');
    var region = unit.regions
        .where(
            (regionInfo) => regionInfo.offset == unit.content.indexOf('/* if'))
        .single;
    expect(region.traces, hasLength(1));
    var trace = region.traces.single;
    expect(trace.description, 'Non-nullability reason');
    var entries = trace.entries;
    expect(entries, hasLength(2));
    // Entry 0 is the nullability of f's argument
    assertTraceEntry(unit, entries[0], 'f', unit.content.indexOf('int'),
        contains('parameter 0 of f'));
    // Entry 1 is the edge from f's argument to never, due to the `/*!*/` hint.
    assertTraceEntry(unit, entries[1], 'f', unit.content.indexOf('int'),
        'explicitly hinted to be non-nullable');
  }

  Future<void> test_trace_extension_unnamed() async {
    var unit = await buildInfoForSingleTestFile('''
extension on String {
  m(int i) {}
}
void f() {
  "".m(null);
}
''', migratedContent: '''
extension on String  {
  m(int? i) {}
}
void f() {
  "".m(null);
}
''');
    var region = unit.regions
        .where((info) => info.offset == unit.content.indexOf('? i) {}'))
        .single;
    expect(region.traces, hasLength(1));
    var trace = region.traces.single;
    expect(trace.description, 'Nullability reason');
    var entries = trace.entries;
    assertTraceEntry(
        unit,
        entries[0],
        '<unnamed extension>.m',
        unit.content.indexOf('int? i) {}'),
        contains('parameter 0 of <unnamed>.m'));
  }

  Future<void> test_trace_nullableType() async {
    var unit = await buildInfoForSingleTestFile('''
void f(int i) {} // f
void g(int i) { // g
  f(i);
}
void h() {
  g(null);
}
''', migratedContent: '''
void f(int? i) {} // f
void g(int? i) { // g
  f(i);
}
void h() {
  g(null);
}
''');
    var region = unit.regions
        .where((regionInfo) =>
            regionInfo.offset == unit.content.indexOf('? i) {} // f'))
        .single;
    expect(region.traces, hasLength(1));
    var trace = region.traces.single;
    expect(trace.description, 'Nullability reason');
    var entries = trace.entries;
    expect(entries, hasLength(6));
    // Entry 0 is the nullability of f's argument
    assertTraceEntry(unit, entries[0], 'f',
        unit.content.indexOf('int? i) {} // f'), contains('parameter 0 of f'),
        hintActions: {
          HintActionKind.addNullableHint,
          HintActionKind.addNonNullableHint
        });

    // Entry 1 is the edge from g's argument to f's argument, due to g's call to
    // f.
    assertTraceEntry(
        unit, entries[1], 'g', unit.content.indexOf('i);'), 'data flow');
    // Entry 2 is the nullability of g's argument
    assertTraceEntry(unit, entries[2], 'g',
        unit.content.indexOf('int? i) { // g'), contains('parameter 0 of g'),
        hintActions: {
          HintActionKind.addNullableHint,
          HintActionKind.addNonNullableHint
        });
    // Entry 3 is the edge from null to g's argument, due to h's call to g.
    assertTraceEntry(
        unit, entries[3], 'h', unit.content.indexOf('null'), 'data flow');
    // Entry 4 is the nullability of the null literal.
    assertTraceEntry(unit, entries[4], 'h', unit.content.indexOf('null'),
        contains('null literal'));
    // Entry 5 is the edge from always to null.
    // TODO(paulberry): this edge provides no additional useful information and
    // shouldn't be included in the trace.
    assertTraceEntry(unit, entries[5], 'h', unit.content.indexOf('null'),
        'literal expression');
  }

  Future<void> test_trace_nullCheck() async {
    var unit = await buildInfoForSingleTestFile('int f(int/*?*/ i) => i + 1;',
        migratedContent: 'int  f(int/*?*/ i) => i! + 1;');
    var region = unit.regions
        .where((regionInfo) => regionInfo.offset == unit.content.indexOf('! +'))
        .single;
    expect(region.traces, hasLength(1));
    var trace = region.traces.single;
    expect(trace.description, 'Nullability reason');
    var entries = trace.entries;
    expect(entries, hasLength(2));
    // Entry 0 is the nullability of the type of i.
    assertTraceEntry(unit, entries[0], 'f', unit.content.indexOf('int/*?*/'),
        contains('parameter 0 of f'));
    // Entry 1 is the edge from always to the type of i.
    // TODO(paulberry): this edge provides no additional useful information and
    // shouldn't be included in the trace.
    assertTraceEntry(unit, entries[1], 'f', unit.content.indexOf('int/*?*/'),
        'explicitly hinted to be nullable');
  }

  Future<void> test_trace_nullCheck_notNullableReason() async {
    var unit = await buildInfoForSingleTestFile('''
void f(int i) { // f
  assert(i != null);
}
void g(int i) { // g
  f(i); // call f
}
void h(int/*?*/ i) {
  g(i);
}
''', migratedContent: '''
void f(int  i) { // f
  assert(i != null);
}
void g(int  i) { // g
  f(i); // call f
}
void h(int/*?*/ i) {
  g(i!);
}
''');
    var region = unit.regions
        .where((regionInfo) => regionInfo.offset == unit.content.indexOf('!)'))
        .single;
    expect(region.traces, hasLength(2));
    // Trace 0 is the nullability reason; we don't care about that right now.
    // Trace 1 is the non-nullability reason.
    var trace = region.traces[1];
    expect(trace.description, 'Non-nullability reason');
    var entries = trace.entries;
    expect(entries, hasLength(4));
    // Entry 0 is the nullability of g's argument
    assertTraceEntry(unit, entries[0], 'g',
        unit.content.indexOf('int  i) { // g'), contains('parameter 0 of g'));
    // Entry 1 is the edge from g's argument to f's argument, due to g's call to
    // f.
    assertTraceEntry(unit, entries[1], 'g',
        unit.content.indexOf('i); // call f'), 'data flow');
    // Entry 2 is the nullability of f's argument
    assertTraceEntry(unit, entries[2], 'f',
        unit.content.indexOf('int  i) { // f'), contains('parameter 0 of f'));
    // Entry 3 is the edge f's argument to never, due to the assert.
    assertTraceEntry(unit, entries[3], 'f', unit.content.indexOf('assert'),
        'value asserted to be non-null');
  }

  Future<void> test_trace_nullCheckHint() async {
    var unit = await buildInfoForSingleTestFile('int f(int/*?*/ i) => i/*!*/;',
        migratedContent: 'int  f(int/*?*/ i) => i/*!*/;');
    var region = unit.regions
        .where(
            (regionInfo) => regionInfo.offset == unit.content.indexOf('/*!*/'))
        .single;
    expect(region.traces, hasLength(1));
    var trace = region.traces.single;
    expect(trace.description, 'Reason');
    expect(trace.entries, hasLength(1));
    assertTraceEntry(unit, trace.entries.single, 'f',
        unit.content.indexOf('i/*!*/'), 'Null check hint');
  }

  Future<void> test_trace_refers_to_variable_initializer() async {
    var unit = await buildInfoForSingleTestFile('''
void f(int/*?*/ i) {
  var x = <int>[i];
  int y = x[0];
}
''', migratedContent: '''
void f(int/*?*/ i) {
  var x = <int?>[i];
  int? y = x[0];
}
''');
    var region = unit.regions
        .where((regionInfo) => regionInfo.offset == unit.content.indexOf('? y'))
        .single;
    expect(region.traces, hasLength(1));
    var trace = region.traces.single;
    expect(trace.description, 'Nullability reason');
    var entries = trace.entries;
    expect(entries, hasLength(8));
    // Entry 0 is the nullability of y
    assertTraceEntry(unit, entries[0], 'f.y', unit.content.indexOf('int? y'),
        contains('f.y'));
    // Entry 1 is the edge from the list element type of x to y, due to array
    // indexing.
    assertTraceEntry(unit, entries[1], 'f.y', unit.content.indexOf('x[0]'),
        contains('data flow'));
    // Entry 2 is the nullability of the implicit list element type of x
    assertTraceEntry(unit, entries[2], 'f.x', unit.content.indexOf('x ='),
        contains('type argument 0 of f.x'));
    // Entry 3 is the edge from the explicit list element type on the RHS of x
    // to the implicit list element type on the LHS of x
    assertTraceEntry(unit, entries[3], 'f.x', unit.content.indexOf('<int?>[i]'),
        contains('data flow'));
    // Entry 4 is the explicit list element type on the RHS of x
    assertTraceEntry(unit, entries[4], 'f.x', unit.content.indexOf('int?>[i]'),
        contains('list element type'));
    // Entry 5 is the edge from the parameter i to the list literal
    assertTraceEntry(unit, entries[5], 'f.x', unit.content.indexOf('i]'),
        contains('data flow'));
    // Entry 6 is the nullability of the parameter i
    assertTraceEntry(unit, entries[6], 'f', unit.content.indexOf('int/*?*/'),
        contains('parameter 0 of f'));
    // Entry 7 is the edge due to the explicit /*?*/ hint
    assertTraceEntry(unit, entries[7], 'f', unit.content.indexOf('int/*?*/'),
        contains('explicitly hinted to be nullable'));
  }

  Future<void> test_trace_substitutionNode() async {
    var unit = await buildInfoForSingleTestFile('''
class C<T extends Object/*!*/> {}

C<int /*?*/ > c;

Map<int, String> x = {};
String/*!*/ y = x[0];
''', migratedContent: '''
class C<T extends Object/*!*/> {}

C<int /*?*/ >? c;

Map<int , String >  x = {};
String/*!*/ y = x[0]!;
''');
    var region = unit.regions
        .where((regionInfo) => regionInfo.offset == unit.content.indexOf('!;'))
        .single;
    // The "why nullable" node associated with adding the `!` is a substitution
    // node, and we don't currently generate a trace for a substitution node.
    // TODO(paulberry): fix this.
    // We do, however, generate a trace for "why not nullable".
    expect(region.traces, hasLength(1));
    expect(region.traces[0].description, 'Non-nullability reason');
  }

  Future<void> test_type_made_nullable() async {
    var unit = await buildInfoForSingleTestFile('''
String g() => 1 == 2 ? "Hello" : null;
''', migratedContent: '''
String? g() => 1 == 2 ? "Hello" : null;
''');
    assertInTargets(targets: unit.targets, offset: 7, length: 1); // "g"
    var regions = unit.regions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 6,
        explanation: "Changed type 'String' to be nullable");
  }

  Future<void> test_type_made_nullable_due_to_hint() async {
    var content = 'int/*?*/ x = 0;';
    var migratedContent = 'int/*?*/ x = 0;';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = unit.fixRegions;
    expect(regions, hasLength(2));
    var textToRemove = '/*?*/';
    assertRegionPair(regions, 0,
        offset1: migratedContent.indexOf(textToRemove),
        length1: 2,
        offset2: migratedContent.indexOf(textToRemove) + 3,
        length2: 2,
        explanation:
            "Changed type 'int' to be nullable, due to a nullability hint",
        kind: NullabilityFixKind.makeTypeNullableDueToHint,
        traces: isNotNull, edits: (List<EditDetail> edits) {
      expect(edits, hasLength(2));
      var editsByDescription = {for (var edit in edits) edit.description: edit};
      assertEdit(
          edit: editsByDescription['Change to /*!*/ hint'],
          offset: content.indexOf(textToRemove),
          length: textToRemove.length,
          replacement: '/*!*/');
      assertEdit(
          edit: editsByDescription['Remove /*?*/ hint'],
          offset: content.indexOf(textToRemove),
          length: textToRemove.length,
          replacement: '');
      return true;
    });
  }

  Future<void> test_type_not_made_nullable() async {
    var unit = await buildInfoForSingleTestFile('int i = 0;',
        migratedContent: 'int  i = 0;');
    var region = unit.regions
        .where((regionInfo) => regionInfo.offset == unit.content.indexOf('  i'))
        .single;
    expect(region.length, 1);
    expect(region.lineNumber, 1);
    expect(region.explanation, "Type 'int' was not made nullable");
    expect(region.edits.map((edit) => edit.description).toSet(),
        {'Add /*?*/ hint', 'Add /*!*/ hint'});
    var trace = region.traces.first;
    expect(trace.description, 'Non-nullability reason');
    var entries = trace.entries;
    expect(entries, hasLength(1));
    assertTraceEntry(unit, entries[0], 'i', unit.content.indexOf('int'),
        'No reason found to make nullable');
    expect(region.kind, NullabilityFixKind.typeNotMadeNullable);
  }

  Future<void> test_type_not_made_nullable_due_to_hint() async {
    var content = 'int/*!*/ i = 0;';
    var migratedContent = 'int/*!*/ i = 0;';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = unit.regions;
    expect(regions, hasLength(1));
    var textToRemove = '/*!*/';
    assertRegion(
        region: regions[0],
        offset: migratedContent.indexOf(textToRemove),
        length: 5,
        explanation: "Type 'int' was not made nullable due to a hint",
        kind: NullabilityFixKind.typeNotMadeNullableDueToHint,
        traces: isNotNull,
        edits: (List<EditDetail> edits) {
          expect(edits, hasLength(2));
          var editsByDescription = {
            for (var edit in edits) edit.description: edit
          };
          assertEdit(
              edit: editsByDescription['Change to /*?*/ hint'],
              offset: content.indexOf(textToRemove),
              length: textToRemove.length,
              replacement: '/*?*/');
          assertEdit(
              edit: editsByDescription['Remove /*!*/ hint'],
              offset: content.indexOf(textToRemove),
              length: textToRemove.length,
              replacement: '');
          return true;
        });
  }
}
