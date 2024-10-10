// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = "Don't use `final` for local variables.";

class UnnecessaryFinal extends LintRule {
  UnnecessaryFinal()
      : super(
          name: LintNames.unnecessary_final,
          description: _desc,
        );

  @override
  List<String> get incompatibleRules =>
      const [LintNames.prefer_final_locals, LintNames.prefer_final_parameters];

  @override
  List<LintCode> get lintCodes => [
        LinterLintCode.unnecessary_final_with_type,
        LinterLintCode.unnecessary_final_without_type
      ];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry
      ..addFormalParameterList(this, visitor)
      ..addForStatement(this, visitor)
      ..addDeclaredVariablePattern(this, visitor)
      ..addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  LintCode getErrorCode(Object? type) => type == null
      ? LinterLintCode.unnecessary_final_without_type
      : LinterLintCode.unnecessary_final_with_type;

  (Token?, AstNode?) getParameterDetails(FormalParameter node) {
    var parameter = node is DefaultFormalParameter ? node.parameter : node;
    return switch (parameter) {
      FieldFormalParameter() => (parameter.keyword, parameter.type),
      SimpleFormalParameter() => (parameter.keyword, parameter.type),
      SuperFormalParameter() => (parameter.keyword, parameter.type),
      _ => (null, null),
    };
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    var keyword = node.keyword;
    keyword ??=
        node.thisOrAncestorOfType<PatternVariableDeclaration>()?.keyword;
    if (keyword?.type != Keyword.FINAL) return;

    var errorCode = getErrorCode(node.matchedValueType);
    rule.reportLintForToken(keyword, errorCode: errorCode);
  }

  @override
  void visitFormalParameterList(FormalParameterList parameterList) {
    for (var node in parameterList.parameters) {
      if (node.isFinal) {
        var (keyword, type) = getParameterDetails(node);
        if (keyword == null) continue;

        var errorCode = getErrorCode(type);
        rule.reportLintForToken(keyword, errorCode: errorCode);
      }
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    var forLoopParts = node.forLoopParts;
    // If the following `if` test fails, then either the statement is not a
    // for-each loop, or it is something like `for(a in b) { ... }`.  In the
    // second case, notice `a` is not actually declared from within the
    // loop. `a` is a variable declared outside the loop.
    if (forLoopParts is ForEachPartsWithDeclaration) {
      var loopVariable = forLoopParts.loopVariable;
      if (loopVariable.isFinal) {
        var errorCode = getErrorCode(loopVariable.type);
        rule.reportLintForToken(loopVariable.keyword, errorCode: errorCode);
      }
    } else if (forLoopParts is ForEachPartsWithPattern) {
      var keyword = forLoopParts.keyword;
      if (keyword.isFinal) {
        rule.reportLintForToken(keyword,
            errorCode: LinterLintCode.unnecessary_final_without_type);
      }
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    if (node.variables.isFinal) {
      var errorCode = getErrorCode(node.variables.type);
      rule.reportLintForToken(node.variables.keyword, errorCode: errorCode);
    }
  }
}
