// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../util/ascii_utils.dart';

const _desc = r'Name source files using `lowercase_with_underscores`.';

class FileNames extends LintRule {
  FileNames() : super(name: LintNames.file_names, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.file_names;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var element = node.declaredFragment?.element;
    if (element != null) {
      var fileName = element.library.firstFragment.source.shortName;
      if (!isValidDartFileName(fileName)) {
        rule.reportAtOffset(0, 0, arguments: [fileName]);
      }
    }
  }
}
