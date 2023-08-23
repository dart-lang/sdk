// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
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

import 'test_constants.dart';

void main() {
  group('check reflective test suites', () {
    group('rules', () {
      var testDirPath =
          PhysicalResourceProvider.INSTANCE.pathContext.absolute(ruleTestDir);
      _VerifyTests(testDirPath).build();
    });
  });
}

/// Helper class to test that [testAllFileName] files are properly set up.
/// (Cribbed from `analyzer_utilities`.)
class _VerifyTests {
  final String testDirPath;

  _VerifyTests(this.testDirPath);

  String get testAllFileName => 'all.dart';

  /// Build tests.
  void build() {
    var provider = PhysicalResourceProvider.INSTANCE;
    var collection = AnalysisContextCollection(
        resourceProvider: provider, includedPaths: <String>[testDirPath]);
    var contexts = collection.contexts;
    if (contexts.length != 1) {
      fail('The test directory contains multiple analysis contexts.');
    }

    _buildTestsIn(contexts.first.currentSession, testDirPath,
        provider.getFolder(testDirPath));
  }

  void _buildTestsIn(
      AnalysisSession session, String testDirPath, Folder directory) {
    var testFileNames = <String>[];
    File? testAllFile;
    var children = directory.getChildren();
    children
        .sort((first, second) => first.shortName.compareTo(second.shortName));
    for (var child in children) {
      if (child is Folder) {
        if (child.getChildAssumingFile(testAllFileName).exists) {
          testFileNames.add('${child.shortName}/$testAllFileName');
        }
        _buildTestsIn(session, testDirPath, child);
      } else if (child is File) {
        var name = child.shortName;
        if (name == testAllFileName) {
          testAllFile = child;
        } else if (name.endsWith('_test.dart')) {
          testFileNames.add(name);
        }
      }
    }
    var relativePath = path.relative(directory.path, from: testDirPath);
    test(relativePath, () async {
      if (testFileNames.isEmpty) return;
      if (testAllFile == null) return;

      var result = session.getParsedUnit(testAllFile.path);
      if (result is! ParsedUnitResult) {
        fail('Could not parse ${testAllFile.path}');
      }
      var importedFiles = <String>[];
      for (var directive in result.unit.directives) {
        if (directive is ImportDirective) {
          var uri = directive.uri.stringValue;
          if (uri == null) {
            fail('Invalid URI: $directive');
          }
          importedFiles.add(uri);
        }
      }
      var missingFiles = <String>[];
      for (var testFileName in testFileNames) {
        if (!importedFiles.contains(testFileName)) {
          missingFiles.add(testFileName);
        }
      }
      if (missingFiles.isNotEmpty) {
        fail(
            'Tests missing from "$testDirPath/$testAllFileName": ${missingFiles.join(', ')}');
      }
      var extraImports = <String>[];
      for (var importedFile in importedFiles) {
        if (!testFileNames.contains(importedFile)) {
          extraImports.add(importedFile);
        }
      }
      if (extraImports.isNotEmpty) {
        fail(
            'Extra tests in "$testDirPath/$testAllFileName": ${extraImports.join(', ')}');
      }
    });
  }
}
