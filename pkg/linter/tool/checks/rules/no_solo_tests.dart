// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r"Don't commit soloed tests.";

class NoSoloTests extends LintRule {
  static const LintCode code = LintCode('no_solo_tests', _desc,
      correctionMessage:
          "Try removing the 'soloTest' annotation or 'solo_' prefix.",
      hasPublishedDocs: true);

  NoSoloTests()
      : super(
          name: 'no_solo_tests',
          description: _desc,
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (context.definingUnit.unit.inTestDir) {
      var visitor = _Visitor(this);
      registry.addMethodDeclaration(this, visitor);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // TODO(pq): we *could* ensure we're in a reflective test too.
    // Handle both 'solo_test_' and 'solo_fail_'.
    if (node.name.lexeme.startsWith('solo_')) {
      rule.reportLintForToken(node.name);
      return;
    }

    for (var annotation in node.metadata) {
      if (annotation.isSoloTest) {
        rule.reportLint(annotation);
      }
    }
  }
}

extension on Annotation {
  bool get isSoloTest {
    var element = element2;
    return element is GetterElement &&
        element.name == 'soloTest' &&
        element.library2?.name == 'test_reflective_loader';
  }
}
