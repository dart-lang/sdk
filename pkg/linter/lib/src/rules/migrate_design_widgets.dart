// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
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

const _desc =
    r'Design widgets should be imported from Material or Cupertino packages.';

class MigrateDesignWidgets extends AnalysisRule {
  new() : super(name: LintNames.migrate_design_widgets, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.migrateDesignWidgets;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  new(this.rule);

  @override
  void visitImportDirective(ImportDirective node) {
    var uriString = node.uri.stringValue;
    if (uriString == 'package:flutter/material.dart' ||
        uriString == 'package:flutter/cupertino.dart') {
      rule.reportAtNode(node.uri, arguments: [uriString!]);
    }
  }
}
