// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = "Prefer single quotes where it won't require escape sequences";

const _details = '''

**DO** use single quotes where it wouldn't require additional escapes

**BAD:**
```
useStrings(
    "should be single",
    r"should be single",
    r"""should be single""",
    "here's ok");
```

**GOOD:**
```
useStrings(
    'should be single',
    r'should be single",
    r\'''should be single\''',
    "here's ok");
```

''';

class PreferSingleQuotes extends LintRule {
  _Visitor _visitor;
  PreferSingleQuotes()
      : super(
            name: 'prefer_single_quotes',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitSimpleStringLiteral(SimpleStringLiteral string) {
    if (string.isSingleQuoted || string.value.contains("'")) {
      return;
    }

    // Bail out on "strings ${x ? 'containing' : 'other'} strings"
    if (!isNestedString(string)) {
      rule.reportLintForToken(string.literal);
    }
  }

  @override
  visitStringInterpolation(StringInterpolation string) {
    if (string.isSingleQuoted) {
      return;
    }

    // slightly more complicated check there are no single quotes
    if (string.elements
        .any((e) => e is InterpolationString && e.value.contains("'"))) {
      return;
    }

    // Bail out on "strings ${x ? 'containing' : 'other'} strings"
    if (!containsString(string) && !isNestedString(string)) {
      rule.reportLint(string);
    }
  }

  /// Strings can be within interpolations (ie, nested). Check like this.
  bool isNestedString(AstNode node) {
    final checkWithinString = new _WithinStringVisitor();
    node.parent?.accept(checkWithinString);

    return checkWithinString.withinString;
  }

  /// Strings interpolations can contain other string nodes. Check like this.
  bool containsString(StringInterpolation string) {
    final checkHasString = new _HasStringVisitor();
    for (final child in string.elements) {
      child.accept(checkHasString);
    }

    return checkHasString.hasString;
  }
}

/// Do a depth analysis to search for string nodes. Note, do not pass in string
/// nodes directly to this visitor, or you will always get true. Pass in its
/// children.
class _HasStringVisitor extends RecursiveAstVisitor {
  bool hasString = false;

  @override
  visitSimpleStringLiteral(SimpleStringLiteral string) {
    hasString = true;
  }

  @override
  visitStringInterpolation(StringInterpolation string) {
    hasString = true;
  }
}

/// Do a bottom-up analysis to search for string nodes. Note, do not pass in
/// string nodes directly to this visitor, or you will always get true. Pass in
/// its parent.
class _WithinStringVisitor extends UnifyingAstVisitor {
  bool withinString = false;

  @override
  visitNode(AstNode n) {
    n.parent?.accept(this);
  }

  @override
  visitSimpleStringLiteral(SimpleStringLiteral string) {
    withinString = true;
  }

  @override
  visitStringInterpolation(StringInterpolation string) {
    withinString = true;
  }
}
