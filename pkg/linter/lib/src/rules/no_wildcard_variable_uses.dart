// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/element/extensions.dart'; //ignore: implementation_imports

import '../analyzer.dart';
import '../util/ascii_utils.dart';

const _desc = r"Don't use wildcard parameters or variables.";

class NoWildcardVariableUses extends LintRule {
  NoWildcardVariableUses()
      : super(
          name: LintNames.no_wildcard_variable_uses,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.no_wildcard_variable_uses;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (context.libraryElement2.hasWildcardVariablesFeatureEnabled2) return;

    var visitor = _Visitor(this);
    registry.addSimpleIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.element;
    if (element is! LocalVariableElement2 &&
        element is! FormalParameterElement) {
      return;
    }

    if (node.name.isJustUnderscores) {
      rule.reportLint(node);
    }
  }
}
