// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';

const _desc =
    r'Avoid wrapping fields in getters and setters just to be "safe".';

class UnnecessaryGettersSetters extends AnalysisRule {
  UnnecessaryGettersSetters()
    : super(name: LintNames.unnecessary_getters_setters, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.unnecessaryGettersSetters;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.isAugmentation) return;

    _check(node.members);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    if (node.isAugmentation) return;

    _check(node.members);
  }

  void _check(NodeList<ClassMember> members) {
    var getters = <String, MethodDeclaration>{};
    var setters = <String, MethodDeclaration>{};

    // Build getter/setter maps
    for (var method in members.whereType<MethodDeclaration>()) {
      var methodName = method.name.lexeme;
      if (method.isGetter) {
        getters[methodName] = method;
      } else if (method.isSetter) {
        setters[methodName] = method;
      }
    }

    // Only select getters with setter pairs
    for (var id in getters.keys) {
      _visitGetterSetter(getters[id]!, setters[id]);
    }
  }

  void _visitGetterSetter(MethodDeclaration getter, MethodDeclaration? setter) {
    if (setter == null) return;
    var getterElement = getter.declaredFragment?.element;
    var setterElement = setter.declaredFragment?.element;
    if (getterElement == null || setterElement == null) return;
    if (isSimpleSetter(setter) &&
        isSimpleGetter(getter) &&
        getterElement.metadata.annotations.isEmpty &&
        setterElement.metadata.annotations.isEmpty) {
      // Just flag the getter (https://github.com/dart-lang/linter/issues/2851)
      rule.reportAtToken(getter.name);
    }
  }
}
