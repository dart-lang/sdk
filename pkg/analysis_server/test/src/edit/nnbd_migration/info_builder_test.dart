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
    InfoBuilder builder = InfoBuilder(info, listener);
    infos = await builder.explainMigration();
  }

  test_asExpression() async {
    addTestFile('''
void f([num a]) {
  int b = a as int;
}
''');
    await buildInfo();
    UnitInfo unit = infos[0];
    expect(unit.content, '''
void f([num? a]) {
  int? b = a as int?;
}
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(3));
    assertRegion(region: regions[0], offset: 11);
    assertRegion(
        region: regions[1],
        offset: 24,
        details: ["This variable is initialized to a nullable value"]);
    assertRegion(
        region: regions[2],
        offset: 38,
        details: ["The value of the expression is nullable"]);
  }

  test_expressionFunctionReturnTarget() async {
    addTestFile('''
String g() => 1 == 2 ? "Hello" : null;
''');
    await buildInfo();
    UnitInfo unit = infos[0];
    expect(unit.content, '''
String? g() => 1 == 2 ? "Hello" : null;
''');
    assertInTargets(targets: unit.targets, offset: 7, length: 1); // "g"
    assertInTargets(targets: unit.targets, offset: 11, length: 2); // "=>"
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 6,
        details: ["This function returns a nullable value"]);
    assertDetail(detail: regions[0].details[0], offset: 11, length: 2);
  }

  test_field_fieldFormalInitializer_optional() async {
    addTestFile('''
class A {
  int _f;
  A([this._f]);
}
''');
    await buildInfo();
    expect(infos, hasLength(1));
    UnitInfo unit = infos[0];
    expect(unit.path, testFile);
    expect(unit.content, '''
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
    addTestFile('''
class A {
  int _f;
  A(this._f);
}
void g() {
  A(null);
}
''');
    await buildInfo();
    expect(infos, hasLength(1));
    UnitInfo unit = infos[0];
    expect(unit.path, testFile);
    expect(unit.content, '''
class A {
  int? _f;
  A(this._f);
}
void g() {
  A(null);
}
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(1));
    // TODO(brianwilkerson) It would be nice if the target for the region could
    //  be the argument rather than the field formal parameter.
    assertRegion(region: regions[0], offset: 15, details: [
      "This field is initialized by a field formal parameter and a nullable "
          "value is passed as an argument"
    ]);
  }

  test_field_initializer() async {
    addTestFile('''
class A {
  int _f = null;
  int _f2 = _f;
}
''');
    await buildInfo();
    expect(infos, hasLength(1));
    UnitInfo unit = infos[0];
    expect(unit.path, testFile);
    expect(unit.content, '''
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
        details: ["This field is initialized to null"]);
    assertRegion(
        region: regions[1],
        offset: 33,
        details: ["This field is initialized to a nullable value"]);
  }

  test_localVariable() async {
    addTestFile('''
void f() {
  int _v1 = null;
  int _v2 = _v1;
}
''');
    await buildInfo();
    expect(infos, hasLength(1));
    UnitInfo unit = infos[0];
    expect(unit.path, testFile);
    expect(unit.content, '''
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
        details: ["This variable is initialized to null"]);
    assertRegion(
        region: regions[1],
        offset: 35,
        details: ["This variable is initialized to a nullable value"]);
  }

  test_parameter_fromInvocation_explicit() async {
    addTestFile('''
void f(String s) {}
void g() {
  f(null);
}
''');
    await buildInfo();
    expect(infos, hasLength(1));
    UnitInfo unit = infos[0];
    expect(unit.path, testFile);
    expect(unit.content, '''
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
    addTestFile('''
void f(String s) {}
void g(p) {
  f(p);
}
''');
    await buildInfo();
    expect(infos, hasLength(1));
    UnitInfo unit = infos[0];
    expect(unit.path, testFile);
    expect(unit.content, '''
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

  test_parameter_fromOverriden() async {
    addTestFile('''
class A {
  void m(p) {}
}
class B extends A {
  void m(Object p) {}
}
''');
    await buildInfo();
    expect(infos, hasLength(1));
    UnitInfo unit = infos[0];
    expect(unit.path, testFile);
    expect(unit.content, '''
class A {
  void m(p) {}
}
class B extends A {
  void m(Object? p) {}
}
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(1));
    // TODO(brianwilkerson) The detail should read something like
    //  "The overridden method accepts a nullable type"
    assertRegion(
        region: regions[0],
        offset: 62,
        details: ["A nullable value is assigned"]);
  }

  @failingTest
  test_parameter_optional_explicitDefault_null() async {
    // Failing because we appear to never get an origin when the upstream node
    // for an edge is 'always'.
    addTestFile('''
void f({String s = null}) {}
''');
    await buildInfo();
    expect(infos, hasLength(1));
    UnitInfo unit = infos[0];
    expect(unit.path, testFile);
    expect(unit.content, '''
void f({String? s = null}) {}
''');
    List<RegionInfo> regions = unit.regions;
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
    addTestFile('''
const sd = null;
void f({String s = sd}) {}
''');
    await buildInfo();
    expect(infos, hasLength(1));
    UnitInfo unit = infos[0];
    expect(unit.path, testFile);
    expect(unit.content, '''
const sd = null;
void f({String? s = sd}) {}
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 31,
        details: ["This parameter has an explicit default value of 'null'"]);
  }

  test_parameter_optional_implicitDefault_named() async {
    addTestFile('''
void f({String s}) {}
''');
    await buildInfo();
    expect(infos, hasLength(1));
    UnitInfo unit = infos[0];
    expect(unit.path, testFile);
    expect(unit.content, '''
void f({String? s}) {}
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 14,
        details: ["This parameter has an implicit default value of 'null'"]);
  }

  test_parameter_optional_implicitDefault_positional() async {
    addTestFile('''
void f([String s]) {}
''');
    await buildInfo();
    expect(infos, hasLength(1));
    UnitInfo unit = infos[0];
    expect(unit.path, testFile);
    expect(unit.content, '''
void f([String? s]) {}
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(1));
    assertRegion(
        region: regions[0],
        offset: 14,
        details: ["This parameter has an implicit default value of 'null'"]);
  }

  test_returnDetailTarget() async {
    addTestFile('''
String g() {
  return 1 == 2 ? "Hello" : null;
}
''');
    await buildInfo();
    UnitInfo unit = infos[0];
    expect(unit.content, '''
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
        details: ["This function returns a nullable value"]);
    assertDetail(detail: regions[0].details[0], offset: 15, length: 6);
  }

  test_returnType_function_expression() async {
    addTestFile('''
int _f = null;
int f() => _f;
''');
    await buildInfo();
    expect(infos, hasLength(1));
    UnitInfo unit = infos[0];
    expect(unit.path, testFile);
    expect(unit.content, '''
int? _f = null;
int? f() => _f;
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(2));
    assertRegion(
        region: regions[0],
        offset: 3,
        details: ["This variable is initialized to null"]);
    assertRegion(
        region: regions[1],
        offset: 19,
        details: ["This function returns a nullable value"]);
  }

  test_returnType_getter_block() async {
    addTestFile('''
class A {
  int _f = null;
  int get f {
    return _f;
  }
}
''');
    await buildInfo();
    expect(infos, hasLength(1));
    UnitInfo unit = infos[0];
    expect(unit.path, testFile);
    expect(unit.content, '''
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
        details: ["This field is initialized to null"]);
    assertRegion(
        region: regions[1],
        offset: 33,
        details: ["This getter returns a nullable value"]);
  }

  test_returnType_getter_expression() async {
    addTestFile('''
class A {
  int _f = null;
  int get f => _f;
}
''');
    await buildInfo();
    expect(infos, hasLength(1));
    UnitInfo unit = infos[0];
    expect(unit.path, testFile);
    expect(unit.content, '''
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
        details: ["This field is initialized to null"]);
    assertRegion(
        region: regions[1],
        offset: 33,
        details: ["This getter returns a nullable value"]);
  }

  test_topLevelVariable() async {
    addTestFile('''
int _f = null;
int _f2 = _f;
''');
    await buildInfo();
    expect(infos, hasLength(1));
    UnitInfo unit = infos[0];
    expect(unit.path, testFile);
    expect(unit.content, '''
int? _f = null;
int? _f2 = _f;
''');
    List<RegionInfo> regions = unit.regions;
    expect(regions, hasLength(2));
    assertRegion(
        region: regions[0],
        offset: 3,
        details: ["This variable is initialized to null"]);
    assertRegion(
        region: regions[1],
        offset: 19,
        details: ["This variable is initialized to a nullable value"]);
  }
}
