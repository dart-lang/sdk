// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Await only futures.';

class AwaitOnlyFutures extends LintRule {
  AwaitOnlyFutures()
      : super(
          name: LintNames.await_only_futures,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.await_only_futures;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addAwaitExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAwaitExpression(AwaitExpression node) {
    if (node.expression is NullLiteral) return;

    var type = node.expression.staticType;
    if (!(type == null ||
        type.element3 is ExtensionTypeElement2 ||
        type.isDartAsyncFuture ||
        type is DynamicType ||
        type is InvalidType ||
        type.extendsClass('Future', 'dart.async') ||
        type.implementsInterface('Future', 'dart.async') ||
        type.isDartAsyncFutureOr)) {
      rule.reportLintForToken(node.awaitKeyword, arguments: [type]);
    }
  }
}
