// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
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
import '../utils.dart';

const _desc = r'Name libraries using `lowercase_with_underscores`.';

class LibraryNames extends AnalysisRule {
  LibraryNames() : super(name: LintNames.library_names, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.libraryNames;

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
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitLibraryDirective(LibraryDirective node) {
    var name = node.name;
    if (name != null && !isLowerCaseUnderScoreWithDots(name.toString())) {
      rule.reportAtNode(name, arguments: [name.toString()]);
    }
  }
}
