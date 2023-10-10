// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/sort_members.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_utilities/package_root.dart';
import 'package:test/test.dart';

void main() {
  group('analysis_server', () {
    buildTestsForAnalysisServer();
  });

  group('analyzer', () {
    buildTestsForAnalyzer();
  });

  group('analyzer_cli', () {
    buildTestsForAnalyzerCli();
  });

  group('analyzer_plugin', () {
    buildTestsForAnalyzerPlugin();
  });

  group('linter', () {
    buildTestsForLinter();
  });

  group('nnbd_migration', () {
    buildTestsForNnbdMigration();
  });
}

void buildTests({
  required String packagePath,
  required List<String> excludedPaths,
}) {
  var provider = PhysicalResourceProvider.INSTANCE;
  var pkgRootPath = provider.pathContext.normalize(packageRoot);

  packagePath = _toPlatformPath(pkgRootPath, packagePath);
  excludedPaths = excludedPaths.map((e) {
    return _toPlatformPath(packagePath, e);
  }).toList();

  var collection = AnalysisContextCollection(
    includedPaths: <String>[packagePath],
    excludedPaths: excludedPaths,
    resourceProvider: provider,
  );
  for (var context in collection.contexts) {
    buildTestsIn(context.currentSession, packagePath, excludedPaths,
        provider.getFolder(packagePath));
  }
}

void buildTestsForAnalysisServer() {
  var excludedPaths = <String>[
    'test/mock_packages',
    // TODO(brianwilkerson) Fix the generator to sort the generated files and
    //  remove these exclusions.
    'lib/protocol/protocol_constants.dart',
    'lib/protocol/protocol_generated.dart',
    'lib/src/edit/nnbd_migration/resources/resources.g.dart',
    'test/integration/support/integration_test_methods.dart',
    'test/integration/support/protocol_matchers.dart',
    // The following are not generated, but can't be sorted because they contain
    // ignore comments in the directives, which sorting deletes.
    'lib/src/services/kythe/schema.dart',
  ];

  buildTests(
    packagePath: 'analysis_server',
    excludedPaths: excludedPaths,
  );
}

void buildTestsForAnalyzer() {
  buildTests(
    packagePath: 'analyzer',
    excludedPaths: [
      'lib/src/context/packages.dart',
      'lib/src/summary/format.dart',
      'test/generated/test_all.dart',
    ],
  );
}

void buildTestsForAnalyzerCli() {
  buildTests(
    packagePath: 'analyzer_cli',
    excludedPaths: [
      'test/data',
    ],
  );
}

void buildTestsForAnalyzerPlugin() {
  // TODO(brianwilkerson) Fix the generator to sort the generated files and
  //  remove these exclusions.
  var excludedPaths = <String>[
    'lib/protocol/protocol_common.dart',
    'lib/protocol/protocol_generated.dart',
    'test/integration/support/integration_test_methods.dart',
    'test/integration/support/protocol_matchers.dart',
  ];

  buildTests(
    packagePath: 'analyzer_plugin',
    excludedPaths: excludedPaths,
  );
}

void buildTestsForLinter() {
  buildTests(packagePath: 'linter', excludedPaths: [
    'test_data',
  ]);
}

void buildTestsForNnbdMigration() {
  buildTests(
      packagePath: 'nnbd_migration',
      excludedPaths: ['lib/src/front_end/resources/resources.g.dart']);
}

void buildTestsIn(AnalysisSession session, String testDirPath,
    List<String> excludedPath, Folder directory) {
  var pathContext = session.resourceProvider.pathContext;
  var children = directory.getChildren();
  children.sort((first, second) => first.shortName.compareTo(second.shortName));
  for (var child in children) {
    if (child is Folder) {
      if (!excludedPath.contains(child.path)) {
        buildTestsIn(session, testDirPath, excludedPath, child);
      }
    } else if (child is File && child.shortName.endsWith('.dart')) {
      var path = child.path;
      if (excludedPath.contains(path)) {
        continue;
      }
      var relativePath = pathContext.relative(path, from: testDirPath);
      test(relativePath, () async {
        var result = session.getParsedUnit(path);
        if (result is! ParsedUnitResult) {
          fail('Could not parse $path');
        }
        var code = result.content;
        var unit = result.unit;
        var errors = result.errors;
        if (errors.isNotEmpty) {
          fail('Errors found when parsing $path');
        }
        var sorter = MemberSorter(code, unit, result.lineInfo);
        var edits = sorter.sort();
        if (edits.isNotEmpty) {
          fail('Unsorted file $path');
        }
      });
    }
  }
}

String _toPlatformPath(String pathPath, String relativePosixPath) {
  var pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
  return pathContext.joinAll([
    pathPath,
    ...relativePosixPath.split('/'),
  ]);
}
