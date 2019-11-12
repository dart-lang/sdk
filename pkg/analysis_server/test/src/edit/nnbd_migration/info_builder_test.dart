// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/non_nullable_fix.dart';
import 'package:analysis_server/src/edit/nnbd_migration/info_builder.dart';
import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_information.dart';
import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_listener.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InfoBuilderTest);
  });
}

@reflectiveTest
class InfoBuilderTest extends AbstractAnalysisTest {
  /// The information produced by the InfoBuilder, or `null` if [buildInfo] has
  /// not yet completed.
  List<UnitInfo> infos;

  /// Assert various properties of the given [detail].
  void assertDetail({@required RegionDetail detail, int offset, int length}) {
    if (offset != null) {
      expect(detail.target.offset, offset);
    }
    if (length != null) {
      expect(detail.target.length, length);
    }
  }

  /// Assert that some target in [targets] has various properties.
  void assertInTargets(
      {@required Iterable<NavigationTarget> targets, int offset, int length}) {
    String failureReasons = [
      if (offset != null) 'offset: $offset',
      if (length != null) 'length: $length',
    ].join(' and ');
    expect(targets.any((t) {
      return (offset == null || offset == t.offset) &&
          (length == null || length == t.length);
    }), isTrue, reason: 'Expected one of $targets to contain $failureReasons');
  }

  /// Assert various properties of the given [region]. If an [offset] is
  /// provided but no [length] is provided, a default length of `1` will be
  /// used.
  void assertRegion(
      {@required RegionInfo region,
      int offset,
      int length,
      List<String> details}) {
    if (offset != null) {
      expect(region.offset, offset);
      expect(region.length, length ?? 1);
    }
    if (details != null) {
      expect(region.details.map((detail) => detail.description),
          unorderedEquals(details));
    }
  }

  /// Use the InfoBuilder to build information. The information will be stored
  /// in [infos].
  Future<void> buildInfo() async {
    // Compute the analysis results.
    server.setAnalysisRoots(
        '0', [resourceProvider.pathContext.dirname(testFile)], [], {});
    ResolvedUnitResult result = await server
        .getAnalysisDriver(testFile)
        .currentSession
        .getResolvedUnit(testFile);
    // Run the migration engine.
    DartFixListener listener = DartFixListener(server);
    InstrumentationListener instrumentationListener = InstrumentationListener();
    NullabilityMigration migration = new NullabilityMigration(
        new NullabilityMigrationAdapter(listener),
        permissive: false,
        instrumentation: instrumentationListener);
    migration.prepareInput(result);
    migration.processInput(result);
    migration.finish();
    // Build the migration info.
    InstrumentationInformation info = instrumentationListener.data;
    InfoBuilder builder =
        InfoBuilder(info, listener, explainNonNullableTypes: true);
    infos = (await builder.explainMigration()).toList();
  }

  /// Uses the InfoBuilder to build information for a single test file.
  ///
  /// Asserts that [originalContent] is migrated to [migratedContent]. Returns
  /// the singular UnitInfo which was built.
  Future<UnitInfo> buildInfoForSingleTestFile(String originalContent,
      {@required String migratedContent}) async {
    addTestFile(originalContent);
    await buildInfo();
    // Ignore info for dart:core
    var filteredInfos = [
      for (var info in infos) if (info.path.indexOf('core.dart') == -1) info
    ];
    expect(filteredInfos, hasLength(1));
    UnitInfo unit = filteredInfos[0];
    expect(unit.path, testFile);
    expect(unit.content, migratedContent);
    return unit;
  }

  test_asExpression() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
void f([num a]) {
  int b = a as int;
}
''', migratedContent: '''
void f([num? a]) {
  int? b = a as int?;
}
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(3));
    // regions[0] is `num? a`.
    assertRegion(
        region: regions[1],
        offset: 24,
        details: ["This variable is initialized to a nullable value"]);
    assertRegion(
        region: regions[2],
        offset: 38,
        details: ["The value of the expression is nullable"]);
  }

  test_asExpression_insideReturn() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
int f([num a]) {
  return a as int;
}
''', migratedContent: '''
int? f([num? a]) {
  return a as int?;
}
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(3));
    // regions[0] is `inf? f`.
    // regions[1] is `num? a`.
    assertRegion(
        region: regions[2],
        offset: 36,
        details: ["The value of the expression is nullable"]);
  }

  test_expressionFunctionReturnTarget() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
String g() => 1 == 2 ? "Hello" : null;
''', migratedContent: '''
String? g() => 1 == 2 ? "Hello" : null;
''');
    assertInTargets(targets: unit.targets, offset: 7, length: 1); // "g"
    assertInTargets(targets: unit.targets, offset: 11, length: 2); // "=>"
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 6,
        details: ["This function returns a nullable value on line 1"]);
    assertDetail(detail: regions[0].details[0], offset: 11, length: 2);
  }

  test_field_fieldFormalInitializer_optional() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
class A {
  int _f;
  A([this._f]);
}
''', migratedContent: '''
class A {
  int? _f;
  A([this._f]);
}
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(1));
    assertRegion(region: regions[0], offset: 15, details: [
      "This field is initialized by an optional field formal parameter that "
          "has an implicit default value of 'null'"
    ]);
  }

  test_field_fieldFormalInitializer_required() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
class A {
  int _f;
  A(this._f);
}
void g() {
  A(null);
}
''', migratedContent: '''
class A {
  int? _f;
  A(this._f);
}
void g() {
  A(null);
}
''');
    List<RegionInfo> regions = unit.fixRegions;
    expect(regions, hasLength(1));
    // TODO(brianwilkerson) It would be nice if the target for the region could
    //  be the argument rather than the field formal parameter.
    assertRegion(region: regions[0], offset: 15, details: [
      "This field is initialized by a field formal parameter and a nullable "
          "value is passed as an argument"
    ]);
  }

  test_field_initializer() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
class A {
  int _f = null;
  int _f2 = _f;
}
''', migratedContent: '''
class A {
  int? _f = null;
  int? _f2 = _f;
}
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(2));
    assertRegion(
        region: regions[0],
        offset: 15,
        details: ["This field is initialized to an explicit 'null'"]);
    assertRegion(
        region: regions[1],
        offset: 33,
        details: ["This field is initialized to a nullable value"]);
  }

  test_listAndSetLiteralTypeArgument() async {
    // TODO(srawlins): Simplify this test with `var x` once #38341 is fixed.
    UnitInfo unit = await buildInfoForSingleTestFile('''
void f() {
  String s = null;
  List<String> x = <String>["hello", s];
  Set<String> y = <String>{"hello", s};
}
''', migratedContent: '''
void f() {
  String? s = null;
  List<String?> x = <String?>["hello", s];
  Set<String?> y = <String?>{"hello", s};
}
''');
    List<RegionInfo> regions = unit.fixRegions;
    expect(regions, hasLength(5));
    // regions[0] is the `String? s` fix.
    // regions[1] is the `List<String?> x` fix.
    assertRegion(
        region: regions[2],
        offset: 58,
        details: ["This list is initialized with a nullable value on line 3"]);
    assertDetail(detail: regions[2].details[0], offset: 67, length: 1);
    // regions[3] is the `Set<String?> y` fix.
    assertRegion(
        region: regions[4],
        offset: 100,
        details: ["This set is initialized with a nullable value on line 4"]);
    assertDetail(detail: regions[4].details[0], offset: 107, length: 1);
  }

  test_listLiteralTypeArgument_collectionIf() async {
    // TODO(srawlins): Simplify this test with `var x` once #38341 is fixed.
    UnitInfo unit = await buildInfoForSingleTestFile('''
void f() {
  String s = null;
  List<String> x = <String>[
    "hello",
    if (1 == 2) s
  ];
}
''', migratedContent: '''
void f() {
  String? s = null;
  List<String?> x = <String?>[
    "hello",
    if (1 == 2) s
  ];
}
''');
    List<RegionInfo> regions = unit.fixRegions;
    expect(regions, hasLength(3));
    // regions[0] is the `String? s` fix.
    // regions[1] is the `List<String?> x` fix.
    assertRegion(
        region: regions[2],
        offset: 58,
        details: ["This list is initialized with a nullable value on line 5"]);
    assertDetail(detail: regions[2].details[0], offset: 88, length: 1);
  }

  test_localVariable() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
void f() {
  int _v1 = null;
  int _v2 = _v1;
}
''', migratedContent: '''
void f() {
  int? _v1 = null;
  int? _v2 = _v1;
}
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(2));
    assertRegion(
        region: regions[0],
        offset: 16,
        details: ["This variable is initialized to an explicit 'null'"]);
    assertRegion(
        region: regions[1],
        offset: 35,
        details: ["This variable is initialized to a nullable value"]);
  }

  test_mapLiteralTypeArgument() async {
    // TODO(srawlins): Simplify this test with `var x` once #38341 is fixed.
    UnitInfo unit = await buildInfoForSingleTestFile('''
void f() {
  String s = null;
  Map<String, bool> x = <String, bool>{"hello": false, s: true};
  Map<bool, String> y = <bool, String>{false: "hello", true: s};
}
''', migratedContent: '''
void f() {
  String? s = null;
  Map<String?, bool> x = <String?, bool>{"hello": false, s: true};
  Map<bool, String?> y = <bool, String?>{false: "hello", true: s};
}
''');
    List<RegionInfo> regions = unit.fixRegions;
    expect(regions, hasLength(5));
    // regions[0] is the `String? s` fix.
    // regions[1] is the `Map<String?, bool> x` fix.
    assertRegion(
        region: regions[2],
        offset: 63,
        details: ["This map is initialized with a nullable value on line 3"]);
    assertDetail(detail: regions[2].details[0], offset: 85, length: 1);
    // regions[3] is the `Map<bool, String?> y` fix.
    assertRegion(
        region: regions[4],
        offset: 136,
        details: ["This map is initialized with a nullable value on line 4"]);
    assertDetail(detail: regions[4].details[0], offset: 156, length: 1);
  }

  test_nonNullableType_assert() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
void f(String s) {
  assert(s != null);
}
''', migratedContent: '''
void f(String s) {
  assert(s != null);
}
''');
    List<RegionInfo> regions = unit.nonNullableTypeRegions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 7,
        length: 6,
        details: ["This value is asserted to be non-null"]);
  }

  test_nonNullableType_exclamationComment() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
void f(String /*!*/ s) {}
''', migratedContent: '''
void f(String /*!*/ s) {}
''');
    List<RegionInfo> regions = unit.nonNullableTypeRegions;
    expect(regions, hasLength(1));
    assertRegion(region: regions[0], offset: 7, length: 6, details: [
      'This type is annotated with a non-nullability comment ("/*!*/")'
    ]);
  }

  test_nonNullableType_unconditionalFieldAccess() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
void f(String s) {
  print(s.length);
}
''', migratedContent: '''
void f(String s) {
  print(s.length);
}
''');
    List<RegionInfo> regions = unit.nonNullableTypeRegions;
    expect(regions, hasLength(1));
    assertRegion(region: regions[0], offset: 7, length: 6, details: [
      "This value is unconditionally used in a non-nullable context"
    ]);
  }

  test_parameter_fromInvocation_explicit() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
void f(String s) {}
void g() {
  f(null);
}
''', migratedContent: '''
void f(String? s) {}
void g() {
  f(null);
}
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 13,
        details: ["An explicit 'null' is passed as an argument"]);
  }

  @failingTest
  test_parameter_fromInvocation_implicit() async {
    // Failing because the upstream edge ("always -(hard)-> type(13)")
    // associated with the reason (a _NullabilityNodeSimple) had a `null` origin
    // when the listener's `graphEdge` method was called.
    UnitInfo unit = await buildInfoForSingleTestFile('''
void f(String s) {}
void g(p) {
  f(p);
}
''', migratedContent: '''
void f(String? s) {}
void g(p) {
  f(p);
}
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 13,
        details: ["A nullable value is explicitly passed as an argument"]);
  }

  test_parameter_fromOverriden_explicit() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
class A {
  void m(int p) {}
}
class B extends A {
  void m(Object p) {}
}
void f(A a) {
  a.m(null);
}
''', migratedContent: '''
class A {
  void m(int? p) {}
}
class B extends A {
  void m(Object? p) {}
}
void f(A a) {
  a.m(null);
}
''');
    List<RegionInfo> regions = unit.fixRegions;
    expect(regions, hasLength(2));
    assertRegion(
        region: regions[0],
        offset: 22,
        details: ["An explicit 'null' is passed as an argument"]);
    assertRegion(region: regions[1], offset: 67, details: [
      "The corresponding parameter in the overridden method is nullable"
    ]);
  }

  test_parameter_fromOverriden_implicit() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
class A {
  void m(p) {}
}
class B extends A {
  void m(Object p) {}
}
''', migratedContent: '''
class A {
  void m(p) {}
}
class B extends A {
  void m(Object? p) {}
}
''');
    List<RegionInfo> regions = unit.fixRegions;
    expect(regions, hasLength(1));
    // TODO(brianwilkerson) The detail should read something like
    //  "The overridden method accepts a nullable type"
    assertRegion(
        region: regions[0],
        offset: 62,
        details: ["A nullable value is assigned"]);
  }

  test_parameter_named_omittedInCall() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
void f() { g(); }

void g({int i}) {}
''', migratedContent: '''
void f() { g(); }

void g({int? i}) {}
''');
    List<RegionInfo> regions = unit.fixRegions;
    expect(regions, hasLength(1));
    assertRegion(region: regions[0], offset: 30, details: [
      "This named parameter was omitted in a call to this function",
      "This parameter has an implicit default value of 'null'",
    ]);
    assertDetail(detail: regions[0].details[0], offset: 11, length: 3);
  }

  @failingTest
  test_parameter_optional_explicitDefault_null() async {
    // Failing because we appear to never get an origin when the upstream node
    // for an edge is 'always'.
    UnitInfo unit = await buildInfoForSingleTestFile('''
void f({String s = null}) {}
''', migratedContent: '''
void f({String? s = null}) {}
''');
    List<RegionInfo> regions = unit.fixRegions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 14,
        details: ["This parameter has an explicit default value of 'null'"]);
  }

  @failingTest
  test_parameter_optional_explicitDefault_nullable() async {
    // Failing because we appear to never get an origin when the upstream node
    // for an edge is 'always'.
    UnitInfo unit = await buildInfoForSingleTestFile('''
const sd = null;
void f({String s = sd}) {}
''', migratedContent: '''
const sd = null;
void f({String? s = sd}) {}
''');
    List<RegionInfo> regions = unit.fixRegions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 31,
        details: ["This parameter has an explicit default value of 'null'"]);
  }

  test_parameter_optional_implicitDefault_named() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
void f({String s}) {}
''', migratedContent: '''
void f({String? s}) {}
''');
    List<RegionInfo> regions = unit.fixRegions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 14,
        details: ["This parameter has an implicit default value of 'null'"]);
  }

  test_parameter_optional_implicitDefault_positional() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
void f([String s]) {}
''', migratedContent: '''
void f([String? s]) {}
''');
    List<RegionInfo> regions = unit.fixRegions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 14,
        details: ["This parameter has an implicit default value of 'null'"]);
  }

  @failingTest
  test_return_fromOverriden() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
abstract class A {
  String m();
}
class B implements A {
  String m() => 1 == 2 ? "Hello" : null;
}
''', migratedContent: '''
abstract class A {
  String? m();
}
class B implements A {
  String? m() => 1 == 2 ? "Hello" : null;
}
''');
    List<RegionInfo> regions = unit.fixRegions;
    expect(regions, hasLength(2));
    assertRegion(
        region: regions[0],
        offset: 27,
        details: ["An overridding method has a nullable return value"]);
  }

  test_return_multipleReturns() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
String g() {
  int x = 1;
  if (x == 2) return x == 3 ? "Hello" : null;
  return "Hello";
}
''', migratedContent: '''
String? g() {
  int x = 1;
  if (x == 2) return x == 3 ? "Hello" : null;
  return "Hello";
}
''');
    List<RegionInfo> regions = unit.fixRegions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 6,
        details: ["This function returns a nullable value on line 3"]);
    assertInTargets(targets: unit.targets, offset: 40, length: 6); // "return"
  }

  test_returnDetailTarget() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
String g() {
  return 1 == 2 ? "Hello" : null;
}
''', migratedContent: '''
String? g() {
  return 1 == 2 ? "Hello" : null;
}
''');
    assertInTargets(targets: unit.targets, offset: 7, length: 1); // "g"
    assertInTargets(targets: unit.targets, offset: 15, length: 6); // "return"
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 6,
        details: ["This function returns a nullable value on line 2"]);
    assertDetail(detail: regions[0].details[0], offset: 15, length: 6);
  }

  test_returnType_function_expression() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
int _f = null;
int f() => _f;
''', migratedContent: '''
int? _f = null;
int? f() => _f;
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(2));
    assertRegion(
        region: regions[0],
        offset: 3,
        details: ["This variable is initialized to an explicit 'null'"]);
    assertRegion(
        region: regions[1],
        offset: 19,
        details: ["This function returns a nullable value on line 2"]);
  }

  test_returnType_getter_block() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
class A {
  int _f = null;
  int get f {
    return _f;
  }
}
''', migratedContent: '''
class A {
  int? _f = null;
  int? get f {
    return _f;
  }
}
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(2));
    assertRegion(
        region: regions[0],
        offset: 15,
        details: ["This field is initialized to an explicit 'null'"]);
    assertRegion(
        region: regions[1],
        offset: 33,
        details: ["This getter returns a nullable value on line 4"]);
  }

  test_returnType_getter_expression() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
class A {
  int _f = null;
  int get f => _f;
}
''', migratedContent: '''
class A {
  int? _f = null;
  int? get f => _f;
}
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(2));
    assertRegion(
        region: regions[0],
        offset: 15,
        details: ["This field is initialized to an explicit 'null'"]);
    assertRegion(
        region: regions[1],
        offset: 33,
        details: ["This getter returns a nullable value on line 3"]);
  }

  test_setLiteralTypeArgument_nestedList() async {
    // TODO(srawlins): Simplify this test with `var x` once #38341 is fixed.
    UnitInfo unit = await buildInfoForSingleTestFile('''
void f() {
  String s = null;
  Set<List<String>> x = <List<String>>{
    ["hello"],
    if (1 == 2) [s]
  };
}
''', migratedContent: '''
void f() {
  String? s = null;
  Set<List<String?>> x = <List<String?>>{
    ["hello"],
    if (1 == 2) [s]
  };
}
''');
    List<RegionInfo> regions = unit.fixRegions;
    expect(regions, hasLength(3));
    // regions[0] is the `String? s` fix.
    // regions[1] is the `Set<List<String?>> x` fix.
    assertRegion(
        region: regions[2],
        offset: 68,
        details: ["This set is initialized with a nullable value on line 5"]);
    // TODO(srawlins): Actually, this is marking the `[s]`, but I think only
    //  `s` should be marked. Minor bug for now.
    assertDetail(detail: regions[2].details[0], offset: 101, length: 3);
  }

  test_topLevelVariable() async {
    UnitInfo unit = await buildInfoForSingleTestFile('''
int _f = null;
int _f2 = _f;
''', migratedContent: '''
int? _f = null;
int? _f2 = _f;
''');
    List<RegionInfo> regions = unit.fixRegions;
    expect(regions, hasLength(2));
    assertRegion(
        region: regions[0],
        offset: 3,
        details: ["This variable is initialized to an explicit 'null'"]);
    assertRegion(
        region: regions[1],
        offset: 19,
        details: ["This variable is initialized to a nullable value"]);
  }
}
