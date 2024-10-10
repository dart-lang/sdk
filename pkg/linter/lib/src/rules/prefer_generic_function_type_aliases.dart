// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Prefer generic function type aliases.';

class PreferGenericFunctionTypeAliases extends LintRule {
  PreferGenericFunctionTypeAliases()
      : super(
          name: LintNames.prefer_generic_function_type_aliases,
          description: _desc,
        );

  @override
  bool get canUseParsedResult => true;

  @override
  LintCode get lintCode => LinterLintCode.prefer_generic_function_type_aliases;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFunctionTypeAlias(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    //https://github.com/dart-lang/linter/issues/2777
    if (node.semicolon.isSynthetic) return;

    var returnType = node.returnType;
    var typeParameters = node.typeParameters;
    var parameters = node.parameters;
    var returnTypeSource =
        returnType == null ? '' : '${returnType.toSource()} ';
    var typeParameterSource =
        typeParameters == null ? '' : typeParameters.toSource();
    var parameterSource = parameters.toSource();
    var replacement =
        '${returnTypeSource}Function$typeParameterSource$parameterSource';
    rule.reportLintForToken(node.name, arguments: [replacement]);
  }
}
