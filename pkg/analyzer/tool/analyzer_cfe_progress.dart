// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/dart/analysis/context_builder.dart';
import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as path;

/// Count failing Analyzer CFE integration tests.
///
/// We look for classes ending in *Test_UseCFE or *Test_Kernel with test
/// methods that are marked with @failingTest annotations.
///
/// In addition, we count the test exclusions from status related to using Fasta
/// with the Analyzer.
void main() {
  if (!io.FileSystemEntity.isDirectorySync('pkg')) {
    io.stderr
        .writeln('This tool should be run from the top level sdk directory.');
    io.exit(1);
  }

  final List<String> analysisPaths = [
    'pkg/analysis_server',
    'pkg/analyzer_cli',
    'pkg/analyzer_plugin',
    'pkg/analyzer',
  ];

  final ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  ContextLocator locator =
      new ContextLocator(resourceProvider: resourceProvider);
  List<ContextRoot> contextRoots =
      locator.locateRoots(includedPaths: analysisPaths);
  ContextBuilder builder =
      new ContextBuilder(resourceProvider: resourceProvider);

  for (ContextRoot contextRoot in contextRoots) {
    if (!analysisPaths
        .any((analysisPath) => contextRoot.root.path.endsWith(analysisPath))) {
      continue;
    }

    AnalysisSession analysisSession =
        builder.createContext(contextRoot: contextRoot).currentSession;
    print('\nCFE tests for ${path.relative(contextRoot.root.path)}:');

    int totalFailingCount = 0;

    for (String analyzedPath in contextRoot.analyzedFiles()) {
      if (!analyzedPath.endsWith('_test.dart')) {
        continue;
      }

      ParseResult result = analysisSession.getParsedAstSync(analyzedPath);
      CompilationUnit unit = result.unit;

      for (ClassDeclaration member
          in unit.declarations.where((member) => member is ClassDeclaration)) {
        String className = member.name.toString();
        if (!className.endsWith('Test_UseCFE') &&
            !className.endsWith('Test_Kernel')) {
          continue;
        }

        int failingCount = 0;

        for (MethodDeclaration method
            in member.members.where((member) => member is MethodDeclaration)) {
          String methodName = method.name.toString();
          if (!methodName.startsWith('test_')) {
            continue;
          }

          if (method.metadata.any((Annotation annotation) =>
              annotation.name.toString() == 'failingTest')) {
            failingCount++;
          }
        }

        totalFailingCount += failingCount;
      }
    }

    print('  $totalFailingCount failing tests');
  }

  // tests/language_2/language_2_analyzer.status:
  //   [ $compiler == dart2analyzer && $fasta ]
  print('\nCFE tests for tests/language_2:');
  int useCfeLanguage2 = countStatusExclusions(
      'tests/language_2/language_2_analyzer.status',
      r'[ $compiler == dart2analyzer && $fasta ]');
  print('  $useCfeLanguage2 failing tests');

  // Also count the Fasta '-DuseFastaParser=true' tests.
  print('\n--use-fasta-parser exclusions from status files');

  int testExclusions = 0;
  testExclusions += countStatusExclusions(
      'tests/co19_2/co19_2-analyzer.status', r'# Issue 33995');
  testExclusions += countStatusExclusions(
      'tests/language_2/language_2_analyzer.status', r'# Issue 33022');

  int testFailures = 0;
  testFailures += countStringOccurrences(
      'pkg/analyzer/test', 'https://github.com/dart-lang/sdk/issues/33992');
  testFailures += countStringOccurrences('pkg/analysis_server/test',
      'https://github.com/dart-lang/sdk/issues/33992');

  print('  $testExclusions co19 and language2 status file exclusions');
  print('  $testFailures failing analyzer and analysis_server tests');
}

int countStatusExclusions(String filePath, String exclusionText) {
  io.File file = new io.File(filePath);
  List<String> lines = file.readAsLinesSync();
  lines = lines
      .where((line) => line.trim().isNotEmpty && !line.trim().startsWith('#'))
      .toList();

  return lines.where((line) => line.contains(exclusionText)).length;
}

int countStringOccurrences(String dirPath, String stringMatch) {
  int count = 0;

  for (io.FileSystemEntity entity
      in new io.Directory(dirPath).listSync(recursive: true)) {
    if (entity is! io.File) continue;
    if (entity.path.endsWith('_test.dart')) {
      String text = (entity as io.File).readAsStringSync();
      int index = text.indexOf(stringMatch);
      while (index != -1) {
        count++;
        index = text.indexOf(stringMatch, index + 1);
      }
    }
  }

  return count;
}
