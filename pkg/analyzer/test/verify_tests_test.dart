// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'utils/package_root.dart' as package_root;

main() {
  PhysicalResourceProvider provider = PhysicalResourceProvider.INSTANCE;
  String packageRoot = provider.pathContext.normalize(package_root.packageRoot);
  String analyzerPath = provider.pathContext.join(packageRoot, 'analyzer');
  String testDirPath = provider.pathContext.join(analyzerPath, 'test');

  AnalysisContextCollection collection = AnalysisContextCollection(
      includedPaths: <String>[testDirPath], resourceProvider: provider);
  List<AnalysisContext> contexts = collection.contexts;
  if (contexts.length != 1) {
    fail('The test directory contains multiple analysis contexts.');
  }

  buildTestsIn(
      contexts[0].currentSession, testDirPath, provider.getFolder(testDirPath));
}

void buildTestsIn(
    AnalysisSession session, String testDirPath, Folder directory) {
  List<String> testFileNames = [];
  File testAllFile;
  List<Resource> children = directory.getChildren();
  children.sort((first, second) => first.shortName.compareTo(second.shortName));
  for (Resource child in children) {
    if (child is Folder) {
      if (child.getChildAssumingFile('test_all.dart').exists) {
        testFileNames.add('${child.shortName}/test_all.dart');
      }
      buildTestsIn(session, testDirPath, child);
    } else if (child is File) {
      String name = child.shortName;
      if (name == 'test_all.dart') {
        testAllFile = child;
      } else if (name.endsWith('_integration_test.dart')) {
        // ignored
      } else if (name.endsWith('_test.dart')) {
        testFileNames.add(name);
      }
    }
  }
  String relativePath = path.relative(directory.path, from: testDirPath);
  test(relativePath, () {
    if (testFileNames.isEmpty) {
      return;
    }
    if (testAllFile == null) {
      if (relativePath != 'id_tests') {
        fail('Missing "test_all.dart" in $relativePath');
      } else {
        // The tests in the id_tests folder don't have a test_all.dart file
        // because they don't use the package:test framework.
        return;
      }
    }
    ParsedUnitResult result = session.getParsedUnit(testAllFile.path);
    if (result.state != ResultState.VALID) {
      fail('Could not parse ${testAllFile.path}');
    }
    List<String> importedFiles = [];
    for (var directive in result.unit.directives) {
      if (directive is ImportDirective) {
        importedFiles.add(directive.uri.stringValue);
      }
    }
    List<String> missingFiles = [];
    for (String testFileName in testFileNames) {
      if (!importedFiles.contains(testFileName)) {
        missingFiles.add(testFileName);
      }
    }
    if (missingFiles.isNotEmpty) {
      fail('Tests missing from "test_all.dart": ${missingFiles.join(', ')}');
    }
  });
}
