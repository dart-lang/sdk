// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_utilities/package_root.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

Future<void> main() async {
  final tests = <AnnotatedTest>[];

  // Note: Unauthenticated GitHub API calls are limited to 60 per hour
  // so this script cannot be run often and will fail if there are over
  // 60 unique issues listed.

  await findFailingTestAnnotations(tests, packagePath: 'analysis_server');
  await findFailingTestAnnotations(tests, packagePath: 'analyzer');
  await findFailingTestAnnotations(tests, packagePath: 'analyzer_cli');
  await findFailingTestAnnotations(tests, packagePath: 'analyzer_plugin');

  final issueUris = tests.map((test) => test.issueUri).toSet();
  print('Found ${tests.length} with ${issueUris.length} unique issues.');
  print('Fetching test statuses from GitHub...');

  final closedIssues = <Uri>{};
  for (final issueUri in issueUris) {
    final response = await http.get(issueUri);
    if (response.statusCode != 200) {
      throw 'Failed to call GitHub API: ${response.statusCode} - ${response.reasonPhrase}\n${response.body}';
    }
    final issueData = jsonDecode(response.body) as Map<String, Object?>;
    if (issueData['state'] != 'open') {
      closedIssues.add(issueUri);
    }
  }

  print('Found ${closedIssues.length} closed issues:');
  for (final tests
      in tests.where((test) => closedIssues.contains(test.issueUri))) {
    final relativePath =
        pathContext.relative(tests.file.path, from: packageRoot);
    print('$relativePath ${tests.testName} ${_formatUri(tests.issueUri)}');
  }
}

final pathContext = provider.pathContext;

final provider = PhysicalResourceProvider.INSTANCE;

Future<void> findFailingTestAnnotations(List<AnnotatedTest> tests,
    {required String packagePath}) async {
  final pkgRootPath = pathContext.normalize(packageRoot);
  final testsPath = pathContext.join(pkgRootPath, packagePath, 'test');

  final collection = AnalysisContextCollection(
    includedPaths: <String>[testsPath],
    resourceProvider: provider,
  );
  final contexts = collection.contexts;
  if (contexts.length != 1) {
    fail('The directory $testsPath contains multiple analysis contexts.');
  }

  final session = contexts[0].currentSession;
  final directory = provider.getFolder(testsPath);

  print('Searching for FailedTest/SkippedTest annotations in $packagePath...');
  await _findFailingTestAnnotationsIn(session, testsPath, directory, tests);
}

Future<void> _findFailingTestAnnotationsIn(AnalysisSession session,
    String testDirPath, Folder directory, List<AnnotatedTest> tests) async {
  final children = directory.getChildren();
  children.sort((first, second) => first.shortName.compareTo(second.shortName));
  for (final child in children) {
    if (child is Folder) {
      await _findFailingTestAnnotationsIn(session, testDirPath, child, tests);
    } else if (child is File && child.shortName.endsWith('_test.dart')) {
      final path = child.path;

      final result = session.getParsedUnit(path);
      if (result is! ParsedUnitResult) {
        fail('Could not parse $path');
      }
      final unit = result.unit;
      final errors = result.errors;
      if (errors.isNotEmpty) {
        fail('Errors found when parsing $path');
      }
      final tracker = FailingTestAnnotationTracker(child);
      unit.accept(tracker);
      tests.addAll(tracker.annotatedTests);
    }
  }
}

String _formatUri(Uri uri) =>
    uri.path.replaceAll('/repos/', '').replaceAll('/issues/', '#');

class AnnotatedTest {
  final File file;
  final String testName;
  final Uri issueUri;

  AnnotatedTest(this.file, this.testName, this.issueUri);
}

/// A [RecursiveAstVisitor] that tracks nodes annotated with [FailingTest] or
/// [SkippedTest].
class FailingTestAnnotationTracker extends RecursiveAstVisitor<void> {
  final annotatedTests = <AnnotatedTest>[];
  final File file;

  FailingTestAnnotationTracker(this.file);

  @override
  void visitAnnotation(Annotation node) {
    if (node.name.name == 'FailingTest' || node.name.name == 'SkippedTest') {
      final issue = node.arguments?.arguments
          .whereType<NamedExpression>()
          .where((arg) => arg.name.label.name == 'issue')
          .firstOrNull;
      final issueUrl = (issue?.expression as SimpleStringLiteral?)?.value;
      if (issueUrl != null && issueUrl.startsWith("https://github.com/")) {
        final issueUri = Uri.parse(issueUrl);
        final apiUri = issueUri.replace(
            host: 'api.github.com',
            pathSegments: ['repos', ...issueUri.pathSegments]);
        final method = node.parent as MethodDeclaration;
        annotatedTests.add(AnnotatedTest(file, method.name.lexeme, apiUri));
      }
    }
    super.visitAnnotation(node);
  }
}
