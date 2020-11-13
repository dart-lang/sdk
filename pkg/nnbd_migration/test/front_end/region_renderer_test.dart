// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/src/front_end/migration_info.dart';
import 'package:nnbd_migration/src/front_end/path_mapper.dart';
import 'package:nnbd_migration/src/front_end/region_renderer.dart';
import 'package:nnbd_migration/src/front_end/web/edit_details.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'nnbd_migration_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RegionRendererTest);
    defineReflectiveTests(RegionRendererTestDriveD);
  });
}

@reflectiveTest
class RegionRendererTest extends RegionRendererTestBase {
  /// Returns the basename of [testFile], used in traces.
  String get _testFileBasename =>
      resourceProvider.pathContext.basename(testFile);

  Future<void> test_informationalRegion_containsTrace() async {
    await buildInfoForSingleTestFile('f(int a) => a.isEven;',
        migratedContent: 'f(int  a) => a.isEven;');
    var response = renderRegion(5);
    expect(response.traces, hasLength(1));
    var trace = response.traces[0];
    expect(trace.description, equals('Non-nullability reason'));
  }

  Future<void> test_informationalRegion_containsTraceEntryDescriptions() async {
    await buildInfoForSingleTestFile('f(int a) => a.isEven;',
        migratedContent: 'f(int  a) => a.isEven;');
    var response = renderRegion(5);
    expect(response.traces, hasLength(1));
    var trace = response.traces[0];
    expect(trace.entries, hasLength(2));
    expect(trace.entries[0].description,
        equals('parameter 0 of f ($_testFileBasename:1:3)'));
    expect(trace.entries[1].description, equals('data flow'));
  }

  Future<void> test_informationalRegion_containsTraceLinks() async {
    await buildInfoForSingleTestFile('f(int a) => a.isEven;',
        migratedContent: 'f(int  a) => a.isEven;');
    var response = renderRegion(5);
    expect(response.traces, hasLength(1));
    var trace = response.traces[0];
    var entry = trace.entries[0];
    expect(entry.link, isNotNull);
    var testFileUriPath = resourceProvider.pathContext.toUri(testFile).path;
    expect(entry.link.href,
        equals('$testFileUriPath?offset=2&line=1&authToken=AUTH_TOKEN'));
    expect(entry.link.path,
        equals(resourceProvider.pathContext.toUri(_testFileBasename).path));
  }

  Future<void> test_modifiedOutput_containsExplanation() async {
    await buildInfoForSingleTestFile('int a = null;',
        migratedContent: 'int? a = null;');
    var response = renderRegion(3);
    expect(response.explanation, equals("Changed type 'int' to be nullable"));
  }

  Future<void> test_modifiedOutput_containsPath() async {
    await buildInfoForSingleTestFile('int a = null;',
        migratedContent: 'int? a = null;');
    var response = renderRegion(3);
    expect(response.displayPath, equals(testFile));
    expect(response.uriPath, equals(pathMapper.map(testFile)));
    expect(response.line, equals(1));
  }

  Future<void> test_modifiedOutput_containsTraceForNullabilityReason() async {
    await buildInfoForSingleTestFile('int a = null;',
        migratedContent: 'int? a = null;');
    var response = renderRegion(3);
    expect(response.traces, hasLength(1));
    var trace = response.traces[0];
    expect(trace.description, equals('Nullability reason'));
    expect(trace.entries, hasLength(4));
    expect(trace.entries[0].description, equals('a ($_testFileBasename:1:1)'));
    expect(trace.entries[1].description, equals('data flow'));
    expect(trace.entries[2].description,
        equals('null literal ($_testFileBasename:1:9)'));
    expect(trace.entries[3].description, equals('literal expression'));
  }

  Future<void> test_unmodifiedOutput_containsExplanation() async {
    await buildInfoForSingleTestFile('f(int a) => a.isEven;',
        migratedContent: 'f(int  a) => a.isEven;');
    var response = renderRegion(5);
    expect(response.explanation, equals("Type 'int' was not made nullable"));
  }

  Future<void> test_unmodifiedOutput_containsPath() async {
    await buildInfoForSingleTestFile('f(int a) => a.isEven;',
        migratedContent: 'f(int  a) => a.isEven;');
    var response = renderRegion(5);
    expect(response.displayPath, equals(testFile));
    expect(response.uriPath, equals(pathMapper.map(testFile)));
    expect(response.line, equals(1));
  }
}

class RegionRendererTestBase extends NnbdMigrationTestBase {
  PathMapper pathMapper;

  /// Render the region at [offset], using a [MigrationInfo] which knows only
  /// about the library at `infos.single`.
  EditDetails renderRegion(int offset) {
    var migrationInfo =
        MigrationInfo(infos, {}, resourceProvider.pathContext, projectPath);
    var unitInfo = infos.single;
    var region = unitInfo.regionAt(offset);
    pathMapper = PathMapper(resourceProvider);
    return RegionRenderer(
            region, unitInfo, migrationInfo, pathMapper, 'AUTH_TOKEN')
        .render();
  }
}

@reflectiveTest
class RegionRendererTestDriveD extends RegionRendererTestBase {
  @override
  String get homePath => _switchToDriveD(super.homePath);

  @override
  void setUp() {
    super.setUp();
  }

  Future<void>
      test_informationalRegion_containsTraceLinks_separateDrive() async {
    // See https://github.com/dart-lang/sdk/issues/43178. Linking from a file on
    // one drive to a file on another drive can cause problems.
    await buildInfoForSingleTestFile(r'''
f(List<int> a) {
  if (1 == 2) List.from(a);
}
g() {
  f(null);
}
''', migratedContent: r'''
f(List<int >? a) {
  if (1 == 2) List.from(a!);
}
g() {
  f(null);
}
''');
    var response = renderRegion(44); // The inserted null-check.
    expect(response.displayPath,
        equals(_switchToDriveD(convertPath('/home/tests/bin/test.dart'))));
    expect(response.traces, hasLength(2));
    var trace = response.traces[1];
    expect(trace.description, equals('Non-nullability reason'));
    expect(trace.entries, hasLength(1));
    var entry = trace.entries[0];
    expect(entry.link, isNotNull);
    var sdkCoreLib = convertPath('/sdk/lib/core/core.dart');
    var sdkCoreLibUriPath = resourceProvider.pathContext.toUri(sdkCoreLib).path;
    var coreLibText = resourceProvider.getFile(sdkCoreLib).readAsStringSync();
    var expectedOffset =
        'List.from'.allMatches(coreLibText).single.start + 'List.'.length;
    var expectedLine =
        '\n'.allMatches(coreLibText.substring(0, expectedOffset)).length + 1;
    expect(
        entry.link.href,
        equals('$sdkCoreLibUriPath?'
            'offset=$expectedOffset&'
            'line=$expectedLine&'
            'authToken=AUTH_TOKEN'));
    // On Windows, the path will simply be the absolute path to the core
    // library, because there is no relative route from C:\ to D:\. On Posix,
    // the path is relative.
    var expectedLinkPath = resourceProvider.pathContext.style == p.Style.windows
        ? sdkCoreLibUriPath
        : '../../..$sdkCoreLibUriPath';
    expect(entry.link.path, equals(expectedLinkPath));
  }

  /// On Windows, replace the C:\ relative root in [path] with the D:\ relative
  /// root.
  ///
  /// On Posix, nothing is be replaced.
  String _switchToDriveD(String path) {
    assert(resourceProvider.pathContext.isAbsolute(path));
    return resourceProvider
        .convertPath(path)
        .replaceFirst(RegExp('^C:\\\\'), 'D:\\');
  }
}
