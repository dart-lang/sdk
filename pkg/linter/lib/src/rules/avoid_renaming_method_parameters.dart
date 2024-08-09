// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';

const _desc = r"Don't rename parameters of overridden methods.";

const _details = r'''
**DON'T** rename parameters of overridden methods.

Methods that override another method, but do not have their own documentation
comment, will inherit the overridden method's comment when `dart doc` produces
documentation. If the inherited method contains the name of the parameter (in
square brackets), then `dart doc` cannot link it correctly.

**BAD:**
```dart
abstract class A {
  m(a);
}

abstract class B extends A {
  m(b);
}
```

**GOOD:**
```dart
abstract class A {
  m(a);
}

abstract class B extends A {
  m(a);
}
```

''';

class AvoidRenamingMethodParameters extends LintRule {
  AvoidRenamingMethodParameters()
      : super(
            name: 'avoid_renaming_method_parameters',
            description: _desc,
            details: _details,
            categories: {LintRuleCategory.documentationCommentMaintenance});

  @override
  LintCode get lintCode => LinterLintCode.avoid_renaming_method_parameters;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!context.isInLibDir) return;

    var visitor = _Visitor(this, context.libraryElement);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  /// Whether the `wildcard_variables` feature is enabled.
  final bool _wildCardVariablesEnabled;

  final LintRule rule;

  _Visitor(this.rule, LibraryElement? library)
      : _wildCardVariablesEnabled =
            library?.featureSet.isEnabled(Feature.wildcard_variables) ?? false;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isStatic) return;
    if (node.documentationComment != null) return;

    var parentNode = node.parent;
    if (parentNode is! Declaration) {
      return;
    }
    var parentElement = parentNode.declaredElement;
    // Note: there are no override semantics with extension methods.
    if (parentElement is! InterfaceElement) {
      return;
    }

    var classElement = parentElement;

    if (classElement.isPrivate) return;

    var parentMethod = classElement.lookUpInheritedMethod(
        node.name.lexeme, classElement.library);

    // If it's not an inherited method, check for an augmentation.
    if (parentMethod == null && node.isAugmentation) {
      var element = node.declaredElement;
      // Note that we only require an augmentation to conform to the previous
      // declaration/augmentation in the chain.
      var target = element?.augmentationTarget;
      if (target is MethodElement) {
        parentMethod = target;
      }
    }

    if (parentMethod == null) return;

    var nodeParams = node.parameters;
    if (nodeParams == null) {
      return;
    }

    var parameters = nodeParams.parameters.where((p) => !p.isNamed).toList();
    var parentParameters =
        parentMethod.parameters.where((p) => !p.isNamed).toList();
    var count = math.min(parameters.length, parentParameters.length);
    for (var i = 0; i < count; i++) {
      if (parentParameters.length <= i) break;

      var paramIdentifier = parameters[i].name;
      if (paramIdentifier == null) {
        continue;
      }

      var paramLexeme = paramIdentifier.lexeme;
      if (_wildCardVariablesEnabled && paramLexeme == '_') {
        continue; // wildcard identifier
      }

      if (paramLexeme != parentParameters[i].name) {
        rule.reportLintForToken(paramIdentifier,
            arguments: [paramIdentifier.lexeme, parentParameters[i].name]);
      }
    }
  }
}
