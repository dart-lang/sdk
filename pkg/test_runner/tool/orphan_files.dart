// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Looks for ".dart" files in "tests/" that appear to be orphaned. That means
/// they don't end in "_test.dart" so aren't run as tests by the test_runner,
/// but they also don't appear to be referenced by any other tests.
///
/// Usually this means that someone accidentally left off the "_test" and the
/// file is supposed to be a test but is silently getting ignored.
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/context_builder.dart';
import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test_runner/src/path.dart';

Future<void> main(List<String> arguments) async {
  _initAnalysisContext();

  var suites = Directory('tests').listSync();
  suites.sort((a, b) => a.path.compareTo(b.path));

  for (var entry in suites) {
    // Skip the co19 tests since they don't use '_test.dart'.
    if (entry is Directory && !entry.path.contains('co19')) {
      await _checkTestDirectory(entry);
    }
  }
}

AnalysisContext _analysisContext;

Future<void> _checkTestDirectory(Directory directory) async {
  print('-- ${directory.path} --');
  var paths = directory
      .listSync(recursive: true)
      .map((entry) => entry.path)
      .where((path) => path.endsWith('.dart'))
      .toList();
  paths.sort();

  // Collect the set of all files that are known to be referred to by others.
  print('Finding referenced files...');
  var importedPaths = <String>{};
  for (var path in paths) {
    await _parseReferences(importedPaths, path);
  }

  // Find the ".dart" files that don't end in "_test.dart" but also aren't used
  // by another library. Those should probably be tests.
  var hasOrphan = false;
  for (var path in paths) {
    if (!path.endsWith('_test.dart') && !importedPaths.contains(path)) {
      print('Suspected orphan: $path');
      hasOrphan = true;
    }
  }

  if (!hasOrphan) print('No orphans :)');
}

void _initAnalysisContext() {
  var roots = ContextLocator().locateRoots(includedPaths: ['test']);
  if (roots.length != 1) {
    throw StateError('Expected to find exactly one context root, got $roots');
  }

  _analysisContext = ContextBuilder().createContext(contextRoot: roots[0]);
}

Future<void> _parseReferences(
    Set<String> importedPaths, String filePath) async {
  var absolute = Path(filePath).absolute.toNativePath();
  var analysisSession = _analysisContext.currentSession;
  var parseResult = await analysisSession.getParsedUnit2(absolute);
  var unit = (parseResult as ParsedUnitResult).unit;

  void add(String importPath) {
    if (importPath.startsWith('dart:')) return;

    var resolved = Uri.file(filePath).resolve(importPath).path;
    importedPaths.add(resolved);
  }

  for (var directive in unit.directives) {
    if (directive is UriBasedDirective) {
      add(directive.uri.stringValue);
    }
  }
}
