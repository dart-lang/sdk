// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Do not use environment declared variables.';

class DoNotUseEnvironment extends LintRule {
  DoNotUseEnvironment()
    : super(name: LintNames.do_not_use_environment, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.do_not_use_environment;

  @override
  void registerNodeProcessors(NodeLintRegistry registry, RuleContext context) {
    var visitor = _Visitor(this);
    registry.addDotShorthandConstructorInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void reportIfUsingEnvironment(
    AstNode node,
    String constructorName,
    DartType staticType,
  ) {
    if (((staticType.isDartCoreBool ||
                staticType.isDartCoreInt ||
                staticType.isDartCoreString) &&
            constructorName == 'fromEnvironment') ||
        (staticType.isDartCoreBool && constructorName == 'hasEnvironment')) {
      String typeName;
      if (staticType.isDartCoreBool) {
        typeName = 'bool';
      } else if (staticType.isDartCoreInt) {
        typeName = 'int';
      } else if (staticType.isDartCoreString) {
        typeName = 'String';
      } else {
        throw StateError(
          'Unexpected type for environment constructor: $staticType',
        );
      }
      String fullMethodName = '$typeName.$constructorName';
      rule.reportAtNode(
        node,
        arguments: [fullMethodName],
        diagnosticCode: rule.diagnosticCode,
      );
    }
  }

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    var nameNode = node.constructorName;
    var staticType = node.staticType;
    if (staticType == null) {
      return;
    }
    reportIfUsingEnvironment(nameNode, nameNode.name, staticType);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var constructorNameNode = node.constructorName;
    if (constructorNameNode.element?.isFactory != true) {
      return;
    }
    var staticType = node.staticType;
    if (staticType == null) {
      return;
    }
    var constructorName = constructorNameNode.name?.name;
    if (constructorName == null) {
      return;
    }
    reportIfUsingEnvironment(constructorNameNode, constructorName, staticType);
  }
}
