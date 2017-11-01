// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r"Prefer single quotes where they won't require escape sequences.";

const _details = '''

**DO** use single quotes where they wouldn't require additional escapes.

That means strings with an apostrophe may use double quotes so that the
apostrophe isn't escaped (note: we don't lint the other way around, ie, a single
quoted string with an escaped apostrophe is not flagged).

It's also rare, but possible, to have strings within string interpolations.  In
this case, its much more readable to use a double quote somewhere.  So double
quotes are allowed either within, or containing, an interpolated string literal.
Arguably strings within string interpolations should be its own type of lint.

**BAD:**
```
useStrings(
    "should be single quote",
    r"should be single quote",
    r"""should be single quotes""")
```

**GOOD:**
```
useStrings(
    'should be single quote',
    r'should be single quote",
    r\'''should be single quotes\''',
    "here's ok",
    "nested \${a ? 'strings' : 'can'} be wrapped by a double quote",
    'and nested \${a ? "strings" : "can be double quoted themselves"});
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

    // Bail out on 'strings ${x ? "containing" : "other"} strings'
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
  bool isNestedString(AstNode node) =>
      // careful: node.getAncestor will check the node itself.
      node.parent?.getAncestor((p) => p is StringInterpolation) != null;

  /// Strings interpolations can contain other string nodes. Check like this.
  bool containsString(StringInterpolation string) {
    final checkHasString = new _IsOrContainsStringVisitor();
    return string.elements.any((child) => child.accept(checkHasString));
  }
}

/// Do a top-down analysis to search for string nodes. Note, do not pass in
/// string nodes directly to this visitor, or you will always get true. Pass in
/// its children.
class _IsOrContainsStringVisitor extends UnifyingAstVisitor<bool> {
  /// Scan as little of the tree as possible, by bailing out on first match. For
  /// all leaf nodes, they will either have a method defined here and return
  /// true, or they will return false because leaves have no children.
  @override
  bool visitNode(AstNode node) =>
      _ImmediateChildrenVisitor.childrenOf(node).any(isOrContainsString);

  /// Different way to express `accept` in a way that's clearer in this visitor.
  bool isOrContainsString(AstNode node) => node.accept(this);

  @override
  bool visitSimpleStringLiteral(SimpleStringLiteral string) => true;

  @override
  bool visitStringInterpolation(StringInterpolation string) => true;
}

/// The only way to get immediate children in a unified, typesafe way, is to
/// call visitChildren on that node, and pass in a visitor. This collects at the
/// top level and stops.
class _ImmediateChildrenVisitor extends UnifyingAstVisitor {
  static List<AstNode> childrenOf(AstNode node) {
    final visitor = new _ImmediateChildrenVisitor();
    node.visitChildren(visitor);
    return visitor._children;
  }

  final _children = <AstNode>[];

  @override
  visitNode(AstNode node) {
    _children.add(node);
  }
}
