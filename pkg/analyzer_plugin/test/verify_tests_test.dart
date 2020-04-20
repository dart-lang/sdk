// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'utils/package_root.dart' as package_root;

void main() {
  var provider = PhysicalResourceProvider.INSTANCE;
  var packageRoot = provider.pathContext.normalize(package_root.packageRoot);
  var analysisServerPath =
      provider.pathContext.join(packageRoot, 'analyzer_plugin');
  var testDirPath = provider.pathContext.join(analysisServerPath, 'test');

  var collection = AnalysisContextCollection(
      includedPaths: <String>[testDirPath], resourceProvider: provider);
  var contexts = collection.contexts;
  if (contexts.length != 1) {
    fail('The test directory contains multiple analysis contexts.');
  }

  buildTestsIn(
      contexts[0].currentSession, testDirPath, provider.getFolder(testDirPath));
}

void buildTestsIn(
    AnalysisSession session, String testDirPath, Folder directory) {
  var testFileNames = <String>[];
  File testAllFile;
  var children = directory.getChildren();
  children.sort((first, second) => first.shortName.compareTo(second.shortName));
  for (var child in children) {
    if (child is Folder) {
      if (child.shortName == 'integration') {
        continue;
      } else if (child.getChildAssumingFile('test_all.dart').exists) {
        testFileNames.add('${child.shortName}/test_all.dart');
      }
      buildTestsIn(session, testDirPath, child);
    } else if (child is File) {
      var name = child.shortName;
      if (name == 'test_all.dart') {
        testAllFile = child;
      } else if (name.endsWith('_test.dart')) {
        testFileNames.add(name);
      }
    }
  }
  var relativePath = path.relative(directory.path, from: testDirPath);
  test(relativePath, () {
    if (testFileNames.isEmpty) {
      return;
    }
    if (testAllFile == null) {
      fail('Missing "test_all.dart" in $relativePath');
    }
    var result = session.getParsedUnit(testAllFile.path);
    if (result.state != ResultState.VALID) {
      fail('Could not parse ${testAllFile.path}');
    }
    var importedFiles = <String>[];
    for (var directive in result.unit.directives) {
      if (directive is ImportDirective) {
        importedFiles.add(directive.uri.stringValue);
      }
    }
    var missingFiles = <String>[];
    for (var testFileName in testFileNames) {
      if (!importedFiles.contains(testFileName)) {
        missingFiles.add(testFileName);
      }
    }
    if (missingFiles.isNotEmpty) {
      fail('Tests missing from "test_all.dart": ${missingFiles.join(', ')}');
    }
  });
}
