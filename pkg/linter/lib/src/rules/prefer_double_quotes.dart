// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';
import '../rules/prefer_single_quotes.dart';

const _desc =
    r"Prefer double quotes where they won't require escape sequences.";

const _details = '''
**DO** use double quotes where they wouldn't require additional escapes.

That means strings with a double quote may use apostrophes so that the double
quote isn't escaped (note: we don't lint the other way around, ie, a double
quoted string with an escaped double quote is not flagged).

It's also rare, but possible, to have strings within string interpolations.  In
this case, it's much more readable to use a single quote somewhere.  So single
quotes are allowed either within, or containing, an interpolated string literal.
Arguably strings within string interpolations should be its own type of lint.

**BAD:**
```dart
useStrings(
    'should be double quote',
    r'should be double quote',
    r\'''should be double quotes\''')
```

**GOOD:**
```dart
useStrings(
    "should be double quote",
    r"should be double quote",
    r"""should be double quotes""",
    'ok with " inside',
    'nested \${a ? "strings" : "can"} be wrapped by a double quote',
    "and nested \${a ? 'strings' : 'can be double quoted themselves'}");
```

''';

class PreferDoubleQuotes extends LintRule {
  static const LintCode code = LintCode(
      'prefer_double_quotes', 'Unnecessary use of single quotes.',
      correctionMessage:
          'Try using double quotes unless the string contains double quotes.');

  PreferDoubleQuotes()
      : super(
            name: 'prefer_double_quotes',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  List<String> get incompatibleRules => const ['prefer_single_quotes'];

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = QuoteVisitor(this, useSingle: false);
    registry.addSimpleStringLiteral(this, visitor);
    registry.addStringInterpolation(this, visitor);
  }
}
