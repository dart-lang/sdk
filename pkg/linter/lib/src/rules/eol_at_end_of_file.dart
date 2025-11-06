// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Put a single newline at end of file.';

class EolAtEndOfFile extends LintRule {
  EolAtEndOfFile()
    : super(name: LintNames.eol_at_end_of_file, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.eolAtEndOfFile;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    assert(context.currentUnit?.unit == node);
    var content = context.currentUnit?.content;
    if (content != null &&
        content.isNotEmpty &&
        // TODO(srawlins): Re-implement this check without iterating over
        // various lists of strings.
        (!content.endsWithNewline || content.endsWithMultipleNewlines)) {
      rule.reportAtOffset(content.trimRight().length, 1);
    }
  }
}

extension on String {
  static const newline = ['\n', '\r'];
  static const multipleNewlines = ['\n\n', '\r\r', '\r\n\r\n'];
  bool get endsWithMultipleNewlines => multipleNewlines.any(endsWith);
  bool get endsWithNewline => newline.any(endsWith);
}
