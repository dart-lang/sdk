// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../rules/prefer_single_quotes.dart';

const _desc =
    r"Prefer double quotes where they won't require escape sequences.";

class PreferDoubleQuotes extends AnalysisRule {
  PreferDoubleQuotes()
    : super(name: LintNames.prefer_double_quotes, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.preferDoubleQuotes;

  @override
  List<String> get incompatibleRules => const [LintNames.prefer_single_quotes];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = QuoteVisitor(this, useSingle: false);
    registry.addSimpleStringLiteral(this, visitor);
    registry.addStringInterpolation(this, visitor);
  }
}
