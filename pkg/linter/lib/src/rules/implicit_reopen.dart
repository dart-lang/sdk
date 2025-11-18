// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r"Don't implicitly reopen classes.";

class ImplicitReopen extends AnalysisRule {
  ImplicitReopen()
    : super(
        name: LintNames.implicit_reopen,
        description: _desc,
        state: const RuleState.experimental(),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.implicitReopen;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addClassTypeAlias(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  void checkElement({
    required InterfaceElement? element,
    required Token nameToken,
    required String type,
  }) {
    if (element is! ClassElement) return;
    if (element.metadata.hasReopen) return;
    if (element.isSealed) return;
    if (element.isMixinClass) return;

    var library = element.library;
    var supertype = element.supertype?.element;
    if (supertype is! ClassElement) return;
    if (supertype.library != library) return;

    if (element.isBase) {
      if (supertype.isFinal) {
        reportLint(
          nameToken: nameToken,
          target: element,
          other: supertype,
          reason: 'final',
          type: type,
        );
        return;
      } else if (supertype.isInterface) {
        reportLint(
          nameToken: nameToken,
          target: element,
          other: supertype,
          reason: 'interface',
          type: type,
        );
        return;
      }
    } else if (element.hasNoModifiers) {
      if (supertype.isInterface) {
        reportLint(
          nameToken: nameToken,
          target: element,
          other: supertype,
          reason: 'interface',
          type: type,
        );
        return;
      }
    }
  }

  void reportLint({
    required Token nameToken,
    required String type,
    required InterfaceElement target,
    required InterfaceElement other,
    required String reason,
  }) {
    var targetName = target.name;
    var otherName = other.name;
    if (targetName != null && otherName != null) {
      rule.reportAtToken(
        nameToken,
        arguments: [type, targetName, otherName, reason],
      );
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    checkElement(
      element: node.declaredFragment?.element,
      nameToken: node.namePart.typeName,
      type: 'class',
    );
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    checkElement(
      element: node.declaredFragment?.element,
      nameToken: node.name,
      type: 'class',
    );
  }
}

extension on ClassElement {
  bool get hasNoModifiers => !isInterface && !isBase && !isSealed && !isFinal;
}
