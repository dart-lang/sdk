// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/doc_comment.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'A code block is missing a specified language.';

class MissingCodeBlockLanguageInDocComment extends LintRule {
  MissingCodeBlockLanguageInDocComment()
    : super(
        name: LintNames.missing_code_block_language_in_doc_comment,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.missingCodeBlockLanguageInDocComment;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addComment(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitComment(Comment node) {
    for (var codeBlock in node.codeBlocks) {
      if (codeBlock.infoString != null) continue;
      if (codeBlock.type != CodeBlockType.fenced) continue;

      var openingCodeBlockFence = codeBlock.lines.first;
      rule.reportAtOffset(
        openingCodeBlockFence.offset,
        openingCodeBlockFence.length,
      );
    }
  }
}
