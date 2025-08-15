// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Avoid annotating with `dynamic` when not required.';

class AvoidAnnotatingWithDynamic extends LintRule {
  AvoidAnnotatingWithDynamic()
    : super(name: LintNames.avoid_annotating_with_dynamic, description: _desc);

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.avoidAnnotatingWithDynamic;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addFieldFormalParameter(this, visitor);
    registry.addSimpleFormalParameter(this, visitor);
    registry.addSuperFormalParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _checkNode(node, node.type);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _checkNode(node, node.type);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    _checkNode(node, node.type);
  }

  void _checkNode(NormalFormalParameter node, TypeAnnotation? type) {
    if (node.inAugmentation) return;

    if (type is NamedType && type.type is DynamicType) {
      rule.reportAtNode(node);
    }
  }
}

extension on AstNode {
  bool get inAugmentation {
    AstNode? target = this;
    while (target != null) {
      if (target.isAugmentation) return true;
      if (target is Block) return false;
      if (target is Declaration) return false;
      target = target.parent;
    }
    return false;
  }
}
