// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/ast.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/element/type.dart'; // ignore: implementation_imports
import 'package:pub_semver/src/version.dart'; // ignore: implementation_imports

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'For synchronous values, `Future.syncValue` is more performant.';

class FutureSyncValue extends AnalysisRule {
  static final constructorSince = Version(3, 10, 0);

  new()
    : super(
        name: LintNames.future_sync_value,
        description: _desc,
        state: .stable(since: .new(3, 14, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.futureSyncValue;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var element = context.libraryElement;
    if (element != null &&
        element.languageVersion.effective.compareTo(constructorSince) < 0) {
      return;
    }
    var visitor = _FutureSyncValueVisitor(
      this,
      context.typeProvider,
      context.libraryElement!.languageVersion.effective,
    );
    registry.addInstanceCreationExpression(this, visitor);
    registry.addDotShorthandConstructorInvocation(this, visitor);
  }
}

class _FutureSyncValueVisitor extends SimpleAstVisitor<void> {
  static const valueConstructorName = 'value';
  static const syncValueConstructorName = 'syncValue';
  final FutureSyncValue rule;
  final TypeProvider typeProvider;
  final Version version;

  new(this.rule, this.typeProvider, this.version);

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    _report(
      node.constructorName.token,
      node.staticType,
      node.argumentList.arguments.firstOrNull,
    );
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _report(
      node.constructorName.name?.token,
      node.staticType,
      node.argumentList.arguments.firstOrNull,
    );
  }

  bool _isFuture(DartType? type) {
    if (type == null) return false;
    return type.asInstanceOf(typeProvider.futureElement) != null ||
        type.asInstanceOf(typeProvider.futureOrElement) != null;
  }

  void _report(Token? token, DartType? instance, Argument? argument) {
    if (token == null || token.lexeme != valueConstructorName) return;
    if (instance == null || !instance.isDartAsyncFuture) return;
    if (!_valueSyncConstructorExists(instance.element)) return;
    if (argument == null) return;
    if (_isFuture(argument.argumentExpression.staticType) ||
        argument.argumentExpression.staticType == DynamicTypeImpl.instance) {
      return;
    }
    rule.reportAtToken(token);
  }

  bool _valueSyncConstructorExists(Element? element) =>
      element is ClassElement &&
      element.constructors.any(
        (constructor) => constructor.name == syncValueConstructorName,
      );
}
