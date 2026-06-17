// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source_range.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Use `;` instead of `{}` for empty container bodies.';

class EmptyContainerBodies extends AnalysisRule {
  new()
    : super(
        name: LintNames.empty_container_bodies,
        description: _desc,
        state: .stable(since: .new(3, 13, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.emptyContainerBodies;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isFeatureEnabled(Feature.primary_constructors)) return;
    var visitor = _Visitor(this);
    registry.addBlockClassBody(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  new(this.rule);

  @override
  void visitBlockClassBody(BlockClassBody node) {
    var leftBracket = node.leftBracket;
    var rightBracket = node.rightBracket;
    if (leftBracket.next == rightBracket &&
        rightBracket.precedingComments == null) {
      var kind = switch (node.parent) {
        ClassDeclaration() => 'class',
        MixinDeclaration() => 'mixin',
        ExtensionDeclaration() => 'extension',
        ExtensionTypeDeclaration() => 'extension type',
        // This should never happen.
        _ => 'container',
      };
      var offset = leftBracket.offset;
      rule.reportAtSourceRange(
        SourceRange(offset, rightBracket.end - offset),
        arguments: [kind],
      );
    }
  }
}
