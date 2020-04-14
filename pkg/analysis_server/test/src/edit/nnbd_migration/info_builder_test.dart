// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/info_builder.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../analysis_abstract.dart';
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
    var includedRoot = resourceProvider.pathContext.dirname(testFile);
    server.setAnalysisRoots('0', [includedRoot], [], {});
    return await server
        .getAnalysisDriver(testFile)
        .currentSession
        .getResolvedUnit(testFile);
  }

  Future<void> test_classConstructor_named() async {
    addTestFile(r'''
class C {
  C.aaa();
}
''');
    var result = await resolveTestFile();
    ClassDeclaration class_ = result.unit.declarations.single;
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
    ClassDeclaration class_ = result.unit.declarations.single;
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
    ClassDeclaration class_ = result.unit.declarations.single;
    FieldDeclaration fieldDeclaration = class_.members.single;
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
    ClassDeclaration class_ = result.unit.declarations.single;
    FieldDeclaration fieldDeclaration = class_.members.single;
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
    ClassDeclaration class_ = result.unit.declarations.single;
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
    ClassDeclaration class_ = result.unit.declarations.single;
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
    ClassDeclaration class_ = result.unit.declarations.single;
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
    ClassDeclaration class_ = result.unit.declarations.single;
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
    ExtensionDeclaration extension_ = result.unit.declarations.single;
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
    ExtensionDeclaration extension_ = result.unit.declarations.single;
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
    MixinDeclaration mixin_ = result.unit.declarations.single;
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
        result.unit.declarations.single;
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
        result.unit.declarations.single;
    var type = topLevelVariableDeclaration.variables.type;
    expect(InfoBuilder.buildEnclosingMemberDescription(type),
        equals("the variable 'i'"));
  }
}

@reflectiveTest
class InfoBuilderTest extends NnbdMigrationTestBase {
  /// Assert various properties of the given [edit].
  void assertEdit(
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
  }

  void assertTraceEntry(UnitInfo unit, TraceEntryInfo entryInfo,
      String function, int offset, Object descriptionMatcher) {
    assert(offset >= 0);
    var lineInfo = LineInfo.fromContent(unit.content);
    var expectedLocation = lineInfo.getLocation(offset);
    expect(entryInfo.target.filePath, unit.path);
    expect(entryInfo.target.line, expectedLocation.lineNumber);
    expect(entryInfo.target.offset, expectedLocation.columnNumber);
    expect(entryInfo.function, function);
    expect(entryInfo.description, descriptionMatcher);
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
    var migratedContent = 'int /*!*/ f(num /*!*/ n) => n as int;';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = unit.regions
        .where(
            (region) => region.kind != NullabilityFixKind.typeNotMadeNullable)
        .toList();
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
    var migratedContent = 'int?/*?*/ f(num /*!*/ n) => n as int?;';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = unit.regions
        .where(
            (region) => region.kind != NullabilityFixKind.typeNotMadeNullable)
        .toList();
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
    var migratedContent = 'int?/*?*/ f(num?/*?*/ n) => n as int?;';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = unit.regions
        .where(
            (region) => region.kind != NullabilityFixKind.typeNotMadeNullable)
        .toList();
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
    var migratedContent = 'int /*!*/ f(num?/*?*/ n) => n as int;';
    var unit = await buildInfoForSingleTestFile(content,
        migratedContent: migratedContent);
    var regions = unit.regions
        .where(
            (region) => region.kind != NullabilityFixKind.typeNotMadeNullable)
        .toList();
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

  Future<void> test_insertedRequired_fieldFormal() async {
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
        edit: edits[0], offset: 42, length: 0, replacement: '@required ');
  }

  Future<void> test_insertedRequired_parameter() async {
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
        edit: edits[0], offset: 37, length: 0, replacement: '@required ');
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
C /*!*/ _f(C  c) => (c + c)!;
''';
    var unit = await buildInfoForSingleTestFile(originalContent,
        migratedContent: migratedContent);
    var regions = unit.fixRegions;
    expect(regions, hasLength(2));
    assertRegion(
        region: regions[0],
        offset: migratedContent.indexOf('? operator'),
        length: 1,
        explanation: "Changed type 'C' to be nullable");
    assertRegion(
        region: regions[1],
        offset: migratedContent.indexOf('!;'),
        length: 1,
        explanation: 'Added a non-null assertion to nullable expression',
        kind: NullabilityFixKind.checkExpression);
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
    // Entry 0 is the nullability of the type of A.m.
    // TODO(srawlins): "A" is probably incorrect here. Should be "A.m".
    assertTraceEntry(unit, entries[0], 'A', unit.content.indexOf('int?'),
        contains('explicit type'));
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
void f(num  n, int?/*?*/ i) {
  if (n is! int ) return;
  print((n as int).isEven);
  print(i! + 1);
}
''';
    var unit = await buildInfoForSingleTestFile(originalContent,
        migratedContent: migratedContent, removeViaComments: false);
    var regions = unit.fixRegions;
    expect(regions, hasLength(3));
    // regions[0] is the addition of `?` to the type of `i`.
    assertRegion(
        region: regions[1],
        offset: migratedContent.indexOf(' as int'),
        length: ' as int'.length,
        explanation: 'Discarded a downcast that is now unnecessary',
        kind: NullabilityFixKind.removeAs);
    assertRegion(
        region: regions[2],
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
    var regions = unit.regions
        .where(
            (region) => region.kind != NullabilityFixKind.typeNotMadeNullable)
        .toList();
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

  Future<void> test_trace_deadCode() async {
    var unit = await buildInfoForSingleTestFile('''
void f(int/*!*/ i) {
  if (i == null) return;
}
''', migratedContent: '''
void f(int /*!*/ i) {
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
    expect(entries, hasLength(3));
    // Entry 0 is the nullability of f's argument
    assertTraceEntry(unit, entries[0], 'f', unit.content.indexOf('int'),
        contains('parameter 0 of f'));
    // Entry 1 is the edge from f's argument to never, due to the `/*!*/` hint.
    assertTraceEntry(unit, entries[1], 'f', unit.content.indexOf('int'),
        'explicitly hinted to be non-nullable');
    // Entry 2 is the "never" node.
    // TODO(paulberry): this node provides no additional useful information and
    // shouldn't be included in the trace.
    expect(entries[2].description, 'never');
    expect(entries[2].function, null);
    expect(entries[2].target, null);
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
        unit.content.indexOf('int? i) {} // f'), contains('parameter 0 of f'));
    // Entry 1 is the edge from g's argument to f's argument, due to g's call to
    // f.
    assertTraceEntry(
        unit, entries[1], 'g', unit.content.indexOf('i);'), 'data flow');
    // Entry 2 is the nullability of g's argument
    assertTraceEntry(unit, entries[2], 'g',
        unit.content.indexOf('int? i) { // g'), contains('parameter 0 of g'));
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
        migratedContent: 'int  f(int?/*?*/ i) => i! + 1;');
    var region = unit.regions
        .where((regionInfo) => regionInfo.offset == unit.content.indexOf('! +'))
        .single;
    expect(region.traces, hasLength(1));
    var trace = region.traces.single;
    expect(trace.description, 'Nullability reason');
    var entries = trace.entries;
    expect(entries, hasLength(2));
    // Entry 0 is the nullability of the type of i.
    // TODO(paulberry): -1 is a bug.
    assertTraceEntry(unit, entries[0], 'f', unit.content.indexOf('int?') - 1,
        contains('parameter 0 of f'));
    // Entry 1 is the edge from always to the type of i.
    // TODO(paulberry): this edge provides no additional useful information and
    // shouldn't be included in the trace.
    assertTraceEntry(unit, entries[1], 'f', unit.content.indexOf('int?') - 1,
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
void h(int?/*?*/ i) {
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
    expect(entries, hasLength(5));
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
    // Entry 4 is the "never" node.
    // TODO(paulberry): this node provides no additional useful information and
    // shouldn't be included in the trace.
    expect(entries[4].description, 'never');
    expect(entries[4].function, null);
    expect(entries[4].target, null);
  }

  Future<void> test_trace_nullCheckHint() async {
    var unit = await buildInfoForSingleTestFile('int f(int/*?*/ i) => i/*!*/;',
        migratedContent: 'int  f(int?/*?*/ i) => i!/*!*/;');
    var region = unit.regions
        .where(
            (regionInfo) => regionInfo.offset == unit.content.indexOf('!/*!*/'))
        .single;
    expect(region.traces, hasLength(1));
    var trace = region.traces.single;
    expect(trace.description, 'Reason');
    expect(trace.entries, hasLength(1));
    // TODO(paulberry): -2 is a bug.
    assertTraceEntry(unit, trace.entries.single, 'f',
        unit.content.indexOf('i!/*!*/') - 2, 'Null check hint');
  }

  Future<void> test_trace_substitutionNode() async {
    var unit = await buildInfoForSingleTestFile('''
class C<T extends Object/*!*/> {}

C<int /*?*/ > c;

Map<int, String> x = {};
String/*!*/ y = x[0];
''', migratedContent: '''
class C<T extends Object /*!*/> {}

C<int? /*?*/ >? c;

Map<int , String >  x = {};
String /*!*/ y = x[0]!;
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
    expect(region.traces, isEmpty);
    expect(region.kind, NullabilityFixKind.typeNotMadeNullable);
  }
}
