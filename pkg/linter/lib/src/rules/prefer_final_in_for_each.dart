// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc =
    r'Prefer final in for-each loop variable if reference is not reassigned.';

class PreferFinalInForEach extends LintRule {
  PreferFinalInForEach()
      : super(
          name: LintNames.prefer_final_in_for_each,
          description: _desc,
        );

  @override
  List<LintCode> get lintCodes => [
        LinterLintCode.prefer_final_in_for_each_pattern,
        LinterLintCode.prefer_final_in_for_each_variable
      ];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addForEachPartsWithDeclaration(this, visitor);
    registry.addForEachPartsWithPattern(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    var loopVariable = node.loopVariable;
    if (loopVariable.isFinal) return;

    var function = node.thisOrAncestorOfType<FunctionBody>();
    var loopVariableElement = loopVariable.declaredElement2;
    if (function != null &&
        loopVariableElement != null &&
        !function.isPotentiallyMutatedInScope2(loopVariableElement)) {
      var name = loopVariable.name;
      rule.reportLintForToken(name,
          errorCode: LinterLintCode.prefer_final_in_for_each_variable,
          arguments: [name.lexeme]);
    }
  }

  @override
  void visitForEachPartsWithPattern(ForEachPartsWithPattern node) {
    if (node.keyword.isFinal) return;

    var function = node.thisOrAncestorOfType<FunctionBody>();
    if (function == null) return;

    var pattern = node.pattern;
    if (pattern is RecordPattern) {
      if (!function.potentiallyMutatesAnyField(pattern.fields)) {
        rule.reportLint(pattern,
            errorCode: LinterLintCode.prefer_final_in_for_each_pattern);
      }
    } else if (pattern is ObjectPattern) {
      if (!function.potentiallyMutatesAnyField(pattern.fields)) {
        rule.reportLint(pattern,
            errorCode: LinterLintCode.prefer_final_in_for_each_pattern);
      }
    } else if (pattern is ListPattern) {
      if (!pattern.elements.any((e) => function.potentiallyMutates(e))) {
        rule.reportLint(pattern,
            errorCode: LinterLintCode.prefer_final_in_for_each_pattern);
      }
    } else if (pattern is MapPattern) {
      if (!pattern.elements.any((e) =>
          e is! MapPatternEntry || function.potentiallyMutates(e.value))) {
        rule.reportLint(pattern,
            errorCode: LinterLintCode.prefer_final_in_for_each_pattern);
      }
    }
  }
}

extension on FunctionBody {
  bool potentiallyMutates(Object pattern) {
    if (pattern is! DeclaredVariablePattern) return true;
    var element = pattern.declaredElement2;
    if (element == null) return true;
    return isPotentiallyMutatedInScope2(element.baseElement);
  }

  bool potentiallyMutatesAnyField(List<PatternField> fields) =>
      fields.any((f) => potentiallyMutates(f.pattern));
}
