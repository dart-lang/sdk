// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Annotate redeclared members.';

class AnnotateRedeclares extends AnalysisRule {
  AnnotateRedeclares()
    : super(
        name: LintNames.annotate_redeclares,
        description: _desc,
        state: const RuleState.experimental(),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.annotateRedeclares;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addExtensionTypeDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    if (node.body case BlockClassBody body) {
      body.members.whereType<MethodDeclaration>().forEach(_check);
    }
  }

  void _check(MethodDeclaration node) {
    if (node.isStatic) return;
    var parent = node.parent?.parent;
    // Shouldn't happen.
    if (parent is! ExtensionTypeDeclaration) return;

    var element = node.declaredFragment?.element;
    if (element == null || element.metadata.hasRedeclare) return;

    var parentElement = parent.declaredFragment?.element;
    var extensionType = parentElement?.firstFragment.element;
    if (extensionType == null) return;

    if (_redeclaresMember(element, extensionType)) {
      rule.reportAtToken(node.name, arguments: [element.displayName]);
    }
  }

  /// Returns whether the [member] redeclares a member from a superinterface.
  bool _redeclaresMember(
    ExecutableElement member,
    InterfaceElement extensionType,
  ) {
    var memberName = member.name;
    if (memberName == null) return false;
    var name = Name.forLibrary(member.library, memberName);
    return extensionType.getInheritedMember(name) != null;
  }
}
