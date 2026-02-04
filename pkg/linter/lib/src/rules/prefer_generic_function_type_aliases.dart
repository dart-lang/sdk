// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
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

const _desc = r'Prefer generic function type aliases.';

class PreferGenericFunctionTypeAliases extends AnalysisRule {
  PreferGenericFunctionTypeAliases()
    : super(
        name: LintNames.prefer_generic_function_type_aliases,
        description: _desc,
      );

  @override
  bool get canUseParsedResult => true;

  @override
  DiagnosticCode get diagnosticCode => diag.preferGenericFunctionTypeAliases;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addFunctionTypeAlias(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    //https://github.com/dart-lang/linter/issues/2777
    if (node.semicolon.isSynthetic) return;

    var returnType = node.returnType;
    var typeParameters = node.typeParameters;
    var parameters = node.parameters;
    var returnTypeSource = returnType == null
        ? ''
        : '${returnType.toSource()} ';
    var typeParameterSource = typeParameters == null
        ? ''
        : typeParameters.toSource();
    var parameterSource = parameters.toSource();
    var replacement =
        '${returnTypeSource}Function$typeParameterSource$parameterSource';
    rule.reportAtToken(node.name, arguments: [replacement]);
  }
}
