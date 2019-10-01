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

  test_parameter_nullableFromInvocation() async {
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
    RegionInfo region = regions[0];
    expect(region.offset, 13);
    expect(region.length, 1);
  }
}
