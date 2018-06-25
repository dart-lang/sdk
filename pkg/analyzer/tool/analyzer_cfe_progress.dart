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

// TODO(devoncarew): Convert the commented out code below to a --verbose option,
// emitting failing tests in a markdown ready format?

/// Count failing Analyzer CFE integration tests.
///
/// We look for classes ending in *Test_UseCFE or *Test_Kernel with test
/// methods that are marked with @failingTest annotations.
///
/// In addition, we count the test exclusions from pkg/pkg.status related to
/// using Fasta with the Analyzer.
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

        //if (failingCount > 0) {
        //  print('  ${member.name}, $failingCount failing tests');
        //}
      }
    }

    print('  $totalFailingCount failing tests');
  }

  // Also count the Fasta '-DuseFastaParser=true' tests.
  print('\nuseFastaParser=true failures from pkg/pkg.status');

  io.File file = new io.File('pkg/pkg.status');
  List<String> lines = file.readAsLinesSync();
  lines = lines
      .where((line) => line.trim().isNotEmpty && !line.trim().startsWith('#'))
      .toList();

  int index = lines
      .indexOf(r'[ $builder_tag == analyzer_use_fasta && $runtime == vm ]');
  if (index == -1) {
    print('error parsing ${file.path}');
  }

  lines = lines.sublist(index + 1);
  lines = lines.sublist(0, lines.indexWhere((line) => line.startsWith('[')));

  print('  ${lines.length} failing tests');
}
