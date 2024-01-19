// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:analyzer_utilities/package_root.dart';
import 'package:test/test.dart';

void main() {
  group('analysis_server', () {
    buildTests(packagePath: 'analysis_server');
  });

  group('analyzer', () {
    buildTests(
      packagePath: 'analyzer',
      analysisContextPredicate: (analysisContext) {
        final root = analysisContext.contextRoot.root;
        if (root.endsWithNames(['macro', 'single'])) {
          return false;
        }
        return true;
      },
    );
  });

  group('analyzer_cli', () {
    buildTests(packagePath: 'analyzer_cli');
  });

  group('analyzer_plugin', () {
    buildTests(packagePath: 'analyzer_plugin');
  });
}

void buildTests({
  required String packagePath,
  bool Function(AnalysisContext)? analysisContextPredicate,
}) {
  var provider = PhysicalResourceProvider.INSTANCE;
  var pkgRootPath = provider.pathContext.normalize(packageRoot);

  var testsPath = _toPlatformPath(pkgRootPath, '$packagePath/test');

  var collection = AnalysisContextCollection(
    includedPaths: <String>[testsPath],
    resourceProvider: provider,
  );

  final singleAnalysisContext = collection.contexts
      .where(analysisContextPredicate ?? (_) => true)
      .toList()
      .singleOrNull;
  if (singleAnalysisContext == null) {
    fail('The directory $testsPath contains multiple analysis contexts.');
  }

  test('no @soloTest', () async {
    var failures = <String>[];
    await buildTestsIn(singleAnalysisContext.currentSession, testsPath,
        provider.getFolder(testsPath), failures);

    if (failures.isNotEmpty) {
      fail('@soloTest annotation found in:\n${failures.join('\n')}');
    }
  });
}

Future<void> buildTestsIn(AnalysisSession session, String testDirPath,
    Folder directory, List<String> failures) async {
  var pathContext = session.resourceProvider.pathContext;
  var children = directory.getChildren();
  children.sort((first, second) => first.shortName.compareTo(second.shortName));
  for (var child in children) {
    if (child is Folder) {
      await buildTestsIn(session, testDirPath, child, failures);
    } else if (child is File && child.shortName.endsWith('_test.dart')) {
      var path = child.path;
      var relativePath = pathContext.relative(path, from: testDirPath);

      var result = session.getParsedUnit(path);
      if (result is! ParsedUnitResult) {
        fail('Could not parse $path');
      }
      var unit = result.unit;
      var errors = result.errors;
      if (errors.isNotEmpty) {
        fail('Errors found when parsing $path');
      }
      var tracker = SoloTestTracker();
      unit.accept(tracker);
      if (tracker.found) {
        failures.add(relativePath);
      }
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

/// A [RecursiveAstVisitor] that tracks whether any node is annotated with
/// an annotation named 'soloTest'.
class SoloTestTracker extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitAnnotation(Annotation node) {
    if (node.name.name == 'soloTest') {
      found = true;
    }
    super.visitAnnotation(node);
  }
}
