// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc =
    'Avoid library directives unless they have documentation comments or '
    'annotations.';

class UnnecessaryLibraryDirective extends LintRule {
  UnnecessaryLibraryDirective()
    : super(name: LintNames.unnecessary_library_directive, description: _desc);

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.unnecessaryLibraryDirective;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addLibraryDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitLibraryDirective(LibraryDirective node) {
    var parent = node.parent! as CompilationUnit;
    if (parent.directives.any((element) => element is PartDirective)) {
      // Parts may still use library names. No be safe, we don't lint those
      // libraries – even though using library names itself is discouraged.
      return;
    }

    if (node.sortedCommentAndAnnotations.isEmpty) {
      rule.reportAtNode(node);
    }
  }
}
