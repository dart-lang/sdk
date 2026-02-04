// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Avoid private typedef functions.';

class AvoidPrivateTypedefFunctions extends AnalysisRule {
  AvoidPrivateTypedefFunctions()
    : super(
        name: LintNames.avoid_private_typedef_functions,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode => diag.avoidPrivateTypedefFunctions;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addFunctionTypeAlias(this, visitor);
    registry.addGenericTypeAlias(this, visitor);
  }
}

class _CountVisitor extends RecursiveAstVisitor<void> {
  final String type;
  int count = 0;
  _CountVisitor(this.type);

  @override
  void visitNamedType(NamedType node) {
    if (node.name.lexeme == type) count++;
    super.visitNamedType(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _countAndReport(node.name);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    if (node.typeParameters != null) return;
    if (node.type is NamedType) return;
    if (node.type is RecordTypeAnnotation) return;

    _countAndReport(node.name);
  }

  void _countAndReport(Token identifier) {
    var name = identifier.lexeme;
    if (!Identifier.isPrivateName(name)) return;

    var visitor = _CountVisitor(name);
    for (var unit in context.allUnits) {
      unit.unit.accept(visitor);
    }
    if (visitor.count <= 1) {
      rule.reportAtToken(identifier);
    }
  }
}
