// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
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

/// Helper class to test that `test_all.dart` files are properly set up in the
/// `analyzer` package (and related packages) and that no tests are annotated
/// to run solo.
class VerifyTests {
  /// Path to the package's `test` subdirectory.
  final String testDirPath;

  /// Paths to exclude from analysis completely.
  final List<String>? excludedPaths;

  VerifyTests(this.testDirPath, {this.excludedPaths});

  /// Build tests.
  void build({
    bool Function(AnalysisContext)? analysisContextPredicate,
  }) {
    var provider = PhysicalResourceProvider.INSTANCE;
    var collection = AnalysisContextCollection(
        resourceProvider: provider,
        includedPaths: <String>[testDirPath],
        excludedPaths: excludedPaths);
    var singleAnalysisContext = collection.contexts
        .where(analysisContextPredicate ?? (_) => true)
        .toList()
        .singleOrNull;
    if (singleAnalysisContext == null) {
      fail('The test directory contains multiple analysis contexts.');
    }

    _buildTestsIn(singleAnalysisContext.currentSession, testDirPath,
        provider.getFolder(testDirPath));
  }

  /// May be overridden in a derived class to indicate whether the test file or
  /// directory indicated by [resource] is so expensive to run that it shouldn't
  /// be included in `test_all.dart` files.
  ///
  /// Default behavior is not to consider any test files or directories
  /// expensive.
  bool isExpensive(Resource resource) => false;

  /// May be overridden in a derived class to indicate whether it is ok for a
  /// `test_all.dart` file in [folder] to import [uri], even if there is no
  /// corresponding test file inside [folder].
  ///
  /// Default behavior is to allow imports of test framework URIs.
  bool isOkAsAdditionalTestAllImport(Folder folder, String uri) => const [
        'package:test/test.dart',
        'package:test_reflective_loader/test_reflective_loader.dart'
      ].contains(uri);

  /// May be overridden in a derived class to indicate whether it is ok for
  /// a `test_all.dart` file to be missing from [folder].
  ///
  /// Default behavior is not to allow `test_all.dart` to be missing from any
  /// folder.
  bool isOkForTestAllToBeMissing(Folder folder) => false;

  void _buildTestsIn(
      AnalysisSession session, String testDirPath, Folder directory) {
    var testFileNames = <String>[];
    var testFilePaths = <String>[];
    File? testAllFile;
    var children = directory.getChildren();
    children
        .sort((first, second) => first.shortName.compareTo(second.shortName));
    for (var child in children) {
      if (child is Folder) {
        if (child.getChildAssumingFile('test_all.dart').exists &&
            !isExpensive(child)) {
          testFileNames.add('${child.shortName}/test_all.dart');
        }
        _buildTestsIn(session, testDirPath, child);
      } else if (child is File) {
        var name = child.shortName;
        if (name == 'test_all.dart') {
          testAllFile = child;
        } else if (name.endsWith('_test.dart') && !isExpensive(child)) {
          testFileNames.add(name);
          testFilePaths.add(child.path);
        }
      }
    }
    var relativePath = path.relative(directory.path, from: testDirPath);
    test(relativePath, () async {
      if (testFileNames.isEmpty) {
        return;
      }
      if (testAllFile == null) {
        if (!isOkForTestAllToBeMissing(directory)) {
          fail('Missing "test_all.dart" in $relativePath');
        } else {
          // Ok that the `test_all.dart` file is missing; there's nothing else to
          // check.
          return;
        }
      }
      if (isOkForTestAllToBeMissing(directory)) {
        fail('Found "test_all.dart" in $relativePath but did not expect one');
      }
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
        fail('Tests missing from "test_all.dart": ${missingFiles.join(', ')}');
      }

      var extraImports = <String>[];
      for (var importedFile in importedFiles) {
        if (!testFileNames.contains(importedFile) &&
            !isOkAsAdditionalTestAllImport(directory, importedFile)) {
          extraImports.add(importedFile);
        }
      }
      if (extraImports.isNotEmpty) {
        fail('Extra tests in "test_all.dart": ${extraImports.join(', ')}');
      }

      for (var testFilePath in testFilePaths) {
        var result = session.getParsedUnit(testFilePath);
        if (result is! ParsedUnitResult) {
          fail('Could not parse $testFilePath');
        }
        for (var declaration in result.unit.declarations) {
          if (declaration is ClassDeclaration) {
            for (var member in declaration.members) {
              if (member is MethodDeclaration) {
                var name = member.name.lexeme;
                // Handle both 'solo_test_' and 'solo_fail_'.
                if (name.startsWith('solo_')) {
                  fail("Solo test: $name in '$testFilePath'");
                }
                for (var annotation in member.metadata) {
                  if (annotation.name.name == 'soloTest') {
                    fail("Solo test: $name in '$testFilePath'");
                  }
                }
              }
            }
          }
        }
      }
    });
  }
}
