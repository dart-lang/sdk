// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Put a single newline at end of file.';

class EolAtEndOfFile extends MultiAnalysisRule {
  new() : super(name: LintNames.eol_at_end_of_file, description: _desc);

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    diag.eolAtEndOfFileMissing,
    diag.eolAtEndOfFileTooMany,
  ];

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
  final MultiAnalysisRule rule;
  final RuleContext context;

  new(this.rule, this.context);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    assert(context.currentUnit?.unit == node);
    var content = context.currentUnit?.content;
    if (content != null && content.isNotEmpty) {
      if (content.endsWithMultipleNewlines) {
        rule.reportAtOffset(
          content.trimRight().length,
          1,
          diagnosticCode: diag.eolAtEndOfFileTooMany,
        );
      } else if (!content.endsWithNewline) {
        rule.reportAtOffset(
          content.trimRight().length,
          1,
          diagnosticCode: diag.eolAtEndOfFileMissing,
        );
      }
    }
  }
}

extension on String {
  static const newline = ['\n', '\r'];
  static const multipleNewlines = ['\n\n', '\r\r', '\r\n\r\n'];
  bool get endsWithMultipleNewlines => multipleNewlines.any(endsWith);
  bool get endsWithNewline => newline.any(endsWith);
}
