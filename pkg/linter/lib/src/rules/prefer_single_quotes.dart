// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Only use double quotes for strings containing single quotes.';

class PreferSingleQuotes extends LintRule {
  PreferSingleQuotes()
      : super(
          name: LintNames.prefer_single_quotes,
          description: _desc,
        );

  @override
  List<String> get incompatibleRules => const [LintNames.prefer_double_quotes];

  @override
  LintCode get lintCode => LinterLintCode.prefer_single_quotes;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = QuoteVisitor(this, useSingle: true);
    registry.addSimpleStringLiteral(this, visitor);
    registry.addStringInterpolation(this, visitor);
  }
}

class QuoteVisitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final bool useSingle;

  QuoteVisitor(
    this.rule, {
    required this.useSingle,
  });

  /// Strings interpolations can contain other string nodes. Check like this.
  bool containsString(StringInterpolation string) {
    var checkHasString = _IsOrContainsStringVisitor();
    return string.elements
        .any((child) => child.accept(checkHasString) ?? false);
  }

  /// Strings can be within interpolations (ie, nested). Check like this.
  bool isNestedString(AstNode node) =>
      // careful: node.getAncestor will check the node itself.
      node.parent?.thisOrAncestorOfType<StringInterpolation>() != null;

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (useSingle && (node.isSingleQuoted || node.value.contains("'")) ||
        !useSingle && (!node.isSingleQuoted || node.value.contains('"'))) {
      return;
    }

    // Bail out on 'strings ${x ? "containing" : "other"} strings'
    if (!isNestedString(node)) {
      rule.reportLintForToken(node.literal);
    }
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    if (useSingle && node.isSingleQuoted ||
        !useSingle && !node.isSingleQuoted) {
      return;
    }

    // slightly more complicated check there are no single quotes
    if (node.elements.any((e) =>
        e is InterpolationString &&
        (useSingle && e.value.contains("'") ||
            !useSingle && e.value.contains('"')))) {
      return;
    }

    // Bail out on "strings ${x ? 'containing' : 'other'} strings"
    if (!containsString(node) && !isNestedString(node)) {
      rule.reportLint(node);
    }
  }
}

/// The only way to get immediate children in a unified, typesafe way, is to
/// call visitChildren on that node, and pass in a visitor. This collects at the
/// top level and stops.
class _ImmediateChildrenVisitor extends UnifyingAstVisitor<void> {
  final _children = <AstNode>[];

  @override
  void visitNode(AstNode node) {
    _children.add(node);
  }

  static List<AstNode> childrenOf(AstNode node) {
    var visitor = _ImmediateChildrenVisitor();
    node.visitChildren(visitor);
    return visitor._children;
  }
}

/// Do a top-down analysis to search for string nodes. Note, do not pass in
/// string nodes directly to this visitor, or you will always get true. Pass in
/// its children.
class _IsOrContainsStringVisitor extends UnifyingAstVisitor<bool> {
  /// Different way to express `accept` in a way that's clearer in this visitor.
  bool isOrContainsString(AstNode node) => node.accept(this) ?? false;

  /// Scan as little of the tree as possible, by bailing out on first match. For
  /// all leaf nodes, they will either have a method defined here and return
  /// true, or they will return false because leaves have no children.
  @override
  bool visitNode(AstNode node) =>
      _ImmediateChildrenVisitor.childrenOf(node).any(isOrContainsString);

  @override
  bool visitSimpleStringLiteral(SimpleStringLiteral string) => true;

  @override
  bool visitStringInterpolation(StringInterpolation string) => true;
}
