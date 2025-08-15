// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/element/extensions.dart'; // ignore: implementation_imports

import '../analyzer.dart';
import '../extensions.dart';

const _desc =
    r'Prefer final for variable declarations if they are not reassigned.';

class PreferFinalLocals extends LintRule {
  PreferFinalLocals()
    : super(name: LintNames.prefer_final_locals, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.preferFinalLocals;

  @override
  List<String> get incompatibleRules => const [LintNames.unnecessary_final];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addDeclaredVariablePattern(this, visitor);
    registry.addPatternVariableDeclaration(this, visitor);
    registry.addVariableDeclarationList(this, visitor);
  }
}

class _DeclaredVariableVisitor extends RecursiveAstVisitor<void> {
  final List<BindPatternVariableElement> declaredElements = [];

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    var element = node.declaredFragment?.element;
    if (element != null) {
      declaredElements.add(element);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  bool isPotentiallyMutated(AstNode pattern, FunctionBody function) {
    if (pattern is DeclaredVariablePattern) {
      var element = pattern.declaredFragment?.element;
      if (element == null || function.isPotentiallyMutatedInScope(element)) {
        return true;
      }
    }
    return false;
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    // [DeclaredVariablePattern]s which are declared by a
    // [PatternVariableDeclaration] are reported in
    // [visitPatternVariableDeclaration].
    if (node.thisOrAncestorOfType<PatternVariableDeclaration>() != null) return;
    if (node.isDeclaredFinal) return;

    var function = node.thisOrAncestorOfType<FunctionBody>();
    if (function == null) return;

    var inCaseClause = node.thisOrAncestorOfType<CaseClause>() != null;
    if (inCaseClause) {
      if (!isPotentiallyMutated(node, function)) {
        rule.reportAtNode(node);
      }
    } else {
      var forEachPattern = node.thisOrAncestorOfType<ForEachPartsWithPattern>();
      if (forEachPattern != null) {
        if (forEachPattern.hasPotentiallyMutatedDeclaredVariableInScope(
          function,
        )) {
          return;
        }
      } else {
        if (isPotentiallyMutated(node, function)) return;
      }
    }

    if (!inCaseClause) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    if (node.isDeclaredFinal) return;
    if (node.keyword.isFinal) return;

    var function = node.thisOrAncestorOfType<FunctionBody>();
    if (function == null) return;

    var inCaseClause = node.thisOrAncestorOfType<CaseClause>() != null;

    if (inCaseClause) {
      if (!isPotentiallyMutated(node, function)) {
        rule.reportAtNode(node);
      }
    } else {
      if (!node.hasPotentiallyMutatedDeclaredVariableInScope(function)) {
        if (node.pattern.containsJustWildcards) return;
        rule.reportAtToken(node.keyword);
      }
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.isConst || node.isFinal) return;

    var function = node.thisOrAncestorOfType<FunctionBody>();
    if (function == null) return;

    for (var variable in node.variables) {
      if (variable.equals == null || variable.initializer == null) {
        return;
      }
      var declaredElement = variable.declaredFragment?.element;
      if (declaredElement != null &&
          (declaredElement.isWildcardVariable ||
              function.isPotentiallyMutatedInScope(declaredElement))) {
        return;
      }
    }
    var keyword = node.keyword;
    if (keyword != null) {
      rule.reportAtToken(keyword);
    } else if (node.type != null) {
      rule.reportAtNode(node.type);
    }
  }
}

extension on DartPattern {
  bool get containsJustWildcards {
    var pattern = this;
    return switch (pattern) {
      ListPattern() => pattern.elements.every(
        (e) => e is DartPattern && e.containsJustWildcards,
      ),
      MapPattern() => pattern.elements.every(
        (e) => e is MapPatternEntry && e.value is WildcardPattern,
      ),
      ObjectPattern() => pattern.fields.every(
        (e) => e.pattern.containsJustWildcards,
      ),
      ParenthesizedPattern() => pattern.pattern.containsJustWildcards,
      RecordPattern() => pattern.fields.every(
        (e) => e.pattern.containsJustWildcards,
      ),
      WildcardPattern() => true,
      _ => false,
    };
  }
}

extension on AstNode {
  bool get isDeclaredFinal {
    var self = this;
    if (self is DeclaredVariablePattern) {
      if (self.keyword.isFinal) return true;
      var pattern = self.thisOrAncestorOfType<ForEachPartsWithPattern>();
      if (pattern != null && pattern.keyword.isFinal) return true;
    }
    return false;
  }

  bool hasPotentiallyMutatedDeclaredVariableInScope(FunctionBody function) {
    var declaredVariableVisitor = _DeclaredVariableVisitor();
    accept(declaredVariableVisitor);
    var declaredElements = declaredVariableVisitor.declaredElements;
    for (var element in declaredElements) {
      if (function.isPotentiallyMutatedInScope(element)) {
        return true;
      }
    }
    return false;
  }
}
