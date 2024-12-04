// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Prefer typing uninitialized variables and fields.';

class PreferTypingUninitializedVariables extends LintRule {
  PreferTypingUninitializedVariables()
      : super(
          name: LintNames.prefer_typing_uninitialized_variables,
          description: _desc,
        );

  @override
  List<LintCode> get lintCodes => [
        LinterLintCode.prefer_typing_uninitialized_variables_for_field,
        LinterLintCode.prefer_typing_uninitialized_variables_for_local_variable
      ];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addVariableDeclarationList(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.type != null) return;

    for (var v in node.variables) {
      if (v.initializer == null && !v.isAugmentation) {
        var code = node.parent is FieldDeclaration
            ? LinterLintCode.prefer_typing_uninitialized_variables_for_field
            : LinterLintCode
                .prefer_typing_uninitialized_variables_for_local_variable;
        rule.reportLint(v, errorCode: code);
      }
    }
  }
}
