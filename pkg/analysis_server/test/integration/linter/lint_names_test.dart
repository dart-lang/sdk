// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_utilities/package_root.dart';
import 'package:linter/src/rules.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  /// Ensure server lint name representations correspond w/ actual lint rules.
  /// See, e.g., https://dart-review.googlesource.com/c/sdk/+/95743.
  group('lint_names', () {
    var pkgRootPath = path.normalize(packageRoot);
    var fixFilePath = path.join(pkgRootPath, 'analysis_server', 'lib', 'src',
        'services', 'linter', 'lint_names.dart');
    var contextCollection = AnalysisContextCollection(
      includedPaths: [fixFilePath],
    );
    var parseResult = contextCollection
        .contextFor(fixFilePath)
        .currentSession
        .getParsedUnit(fixFilePath) as ParsedUnitResult;

    if (parseResult.errors.isNotEmpty) {
      throw Exception(parseResult.errors);
    }

    var lintNamesClass = parseResult.unit.declarations
        .firstWhere((m) => m is ClassDeclaration && m.name.name == 'LintNames');

    var collector = _FixCollector();
    lintNamesClass.accept(collector);
    for (var name in collector.lintNames) {
      test(name, () {
        expect(registeredLintNames, contains(name));
      });
    }
  });
}

List<LintRule>? _registeredLints;

Iterable<String> get registeredLintNames => registeredLints.map((r) => r.name);

List<LintRule> get registeredLints {
  var registeredLints = _registeredLints;
  if (registeredLints == null) {
    if (Registry.ruleRegistry.isEmpty) {
      registerLintRules();
    }
    registeredLints = Registry.ruleRegistry.toList();
    _registeredLints = registeredLints;
  }
  return registeredLints;
}

class _FixCollector extends GeneralizingAstVisitor<void> {
  final List<String> lintNames = <String>[];

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    for (var v in node.fields.variables) {
      lintNames.add(v.name.name);
    }
  }
}
