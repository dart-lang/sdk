// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/navigation/analysis_options_navigation_computer.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_context.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsNavigationTest);
  });
}

@reflectiveTest
class AnalysisOptionsNavigationTest extends AbstractContextTest {
  late NavigationCollectorImpl collector;

  @override
  void setUp() {
    super.setUp();
    newFile(testPubspecPath, 'name: test\n');
    collector = NavigationCollectorImpl();
  }

  void test_include_doesNotExist() {
    _computeNavigation('''
include: non_existent.yaml
''');
    expect(collector.regions, isEmpty);
  }

  void test_include_doubleQuotes() {
    var otherFile = newFile('$testPackageRootPath/other.yaml', '');
    _computeNavigation('''
include: "other.yaml"
''');
    _assertHasRegion('"other.yaml"');
    _assertHasTarget(otherFile.path, 0, 0);
  }

  void test_include_list() {
    var file1 = newFile('$testPackageRootPath/opt1.yaml', '');
    var file2 = newFile('$testPackageRootPath/opt2.yaml', '');
    _computeNavigation('''
include:
  - opt1.yaml
  - opt2.yaml
''');
    _assertHasRegion('opt1.yaml');
    _assertHasTarget(file1.path, 0, 0);
    _assertHasRegion('opt2.yaml');
    _assertHasTarget(file2.path, 0, 0);
  }

  void test_include_offsetFilter_matching() {
    var otherFile = newFile('$testPackageRootPath/other.yaml', '');
    var code = TestCode.parse('''
include: oth^er.yaml
''');
    _setOptionsContent(code.code);
    computeAnalysisOptionsNavigation(
      resourceProvider,
      collector,
      allDrivers.first.sourceFactory,
      analysisOptionsPath,
      code.position.offset,
      0,
    );
    collector.createRegions();
    _assertHasRegion('other.yaml');
    _assertHasTarget(otherFile.path, 0, 0);
  }

  void test_include_offsetFilter_notMatching() {
    newFile('$testPackageRootPath/other.yaml', '');
    var code = TestCode.parse('''
^# comment
include: other.yaml
''');
    _setOptionsContent(code.code);
    computeAnalysisOptionsNavigation(
      resourceProvider,
      collector,
      allDrivers.first.sourceFactory,
      analysisOptionsPath,
      code.position.offset,
      0,
    );
    collector.createRegions();
    expect(collector.regions, isEmpty);
  }

  void test_include_package_fileDoesNotExist() {
    var lintsPath = '$workspaceRootPath/lints';
    newFile('$lintsPath/lib/recommended.yaml', '');
    var config = PackageConfigFileBuilder();
    config.add(name: 'lints', rootFolder: getFolder(lintsPath));
    writePackageConfig2(workspaceRootPath, config: config);

    _computeNavigation('''
include: package:lints/non_existent.yaml
''');
    expect(collector.regions, isEmpty);
  }

  void test_include_package_unknownPackage() {
    _computeNavigation('''
include: package:unknown/analysis_options.yaml
''');
    expect(collector.regions, isEmpty);
  }

  void test_include_packageFile() {
    var lintsPath = '$workspaceRootPath/lints';
    var recommendedFile = newFile('$lintsPath/lib/recommended.yaml', '');
    var config = PackageConfigFileBuilder();
    config.add(name: 'lints', rootFolder: getFolder(lintsPath));
    writePackageConfig2(workspaceRootPath, config: config);

    _computeNavigation('''
include: package:lints/recommended.yaml
''');
    _assertHasRegion('package:lints/recommended.yaml');
    _assertHasTarget(recommendedFile.path, 0, 0);
  }

  void test_include_quotes() {
    var otherFile = newFile('$testPackageRootPath/other.yaml', '');
    _computeNavigation('''
include: 'other.yaml'
''');
    _assertHasRegion("'other.yaml'");
    _assertHasTarget(otherFile.path, 0, 0);
  }

  void test_include_relativeFile() {
    var otherFile = newFile('$testPackageRootPath/other.yaml', '');
    _computeNavigation('''
include: other.yaml
''');
    _assertHasRegion('other.yaml');
    _assertHasTarget(otherFile.path, 0, 0);
  }

  void test_noInclude() {
    _computeNavigation('''
linter:
  rules:
    - avoid_empty_else
''');
    expect(collector.regions, isEmpty);
  }

  void _assertHasRegion(String search) {
    var optionsFile = getFile(analysisOptionsPath);
    var content = optionsFile.readAsStringSync();
    var offset = content.indexOf(search);
    expect(offset, isNot(-1), reason: 'Cannot find "$search" in content');
    var length = search.length;

    for (var region in collector.regions) {
      if (region.offset == offset && region.length == length) {
        return;
      }
    }
    fail('No region found at ($offset, $length) in ${collector.regions}');
  }

  void _assertHasTarget(String targetFile, int offset, int length) {
    for (var target in collector.targets) {
      var file = collector.files[target.fileIndex];
      if (file == targetFile &&
          target.offset == offset &&
          target.length == length) {
        return;
      }
    }
    fail(
      'No target found for ($targetFile, $offset, $length) in ${collector.targets}',
    );
  }

  void _computeNavigation(String content) {
    _setOptionsContent(content);
    computeAnalysisOptionsNavigation(
      resourceProvider,
      collector,
      allDrivers.first.sourceFactory,
      analysisOptionsPath,
      0,
      content.length,
    );
    collector.createRegions();
  }

  void _setOptionsContent(String content) {
    getFile(analysisOptionsPath).writeAsStringSync(content);
  }
}
