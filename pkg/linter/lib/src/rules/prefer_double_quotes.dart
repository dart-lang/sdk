// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';
import '../rules/prefer_single_quotes.dart';

const _desc =
    r"Prefer double quotes where they won't require escape sequences.";

class PreferDoubleQuotes extends LintRule {
  PreferDoubleQuotes()
      : super(
          name: LintNames.prefer_double_quotes,
          description: _desc,
        );

  @override
  List<String> get incompatibleRules => const [LintNames.prefer_single_quotes];

  @override
  LintCode get lintCode => LinterLintCode.prefer_double_quotes;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = QuoteVisitor(this, useSingle: false);
    registry.addSimpleStringLiteral(this, visitor);
    registry.addStringInterpolation(this, visitor);
  }
}
