// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../extensions.dart';

const _desc =
    r'Avoid wrapping fields in getters and setters just to be "safe".';

class UnnecessaryGettersSetters extends LintRule {
  UnnecessaryGettersSetters()
      : super(
          name: LintNames.unnecessary_getters_setters,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.unnecessary_getters_setters;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

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
        getterElement.metadata2.annotations.isEmpty &&
        setterElement.metadata2.annotations.isEmpty) {
      // Just flag the getter (https://github.com/dart-lang/linter/issues/2851)
      rule.reportLintForToken(getter.name);
    }
  }
}
