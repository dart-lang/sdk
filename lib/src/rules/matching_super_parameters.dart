// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';

const _desc = r'Use matching super parameter names.';

const _details = r'''
**DO** use super parameter names that match their corresponding super
constructor's parameter names.

**BAD:**

```dart
class Rectangle {
  final int width;
  final int height;
  
  Rectangle(this.width, this.height);
}

class ColoredRectangle extends Rectangle {
  final Color color;
  
  ColoredRectangle(
    this.color,
    super.height, // Bad, actually corresponds to the `width` parameter.
    super.width, // Bad, actually corresponds to the `height` parameter.
  ); 
}
```

**GOOD:**

```dart
class Rectangle {
  final int width;
  final int height;
  
  Rectangle(this.width, this.height);
}

class ColoredRectangle extends Rectangle {
  final Color color;
  
  ColoredRectangle(
    this.color,
    super.width,
    super.height, 
  ); 
}
```
''';

class MatchingSuperParameters extends LintRule {
  static const LintCode code = LintCode(
      'matching_super_parameters',
      "The super parameter named '{0}'' does not share the same name as the "
          "corresponding parameter in the super constructor, '{1}'.",
      correctionMessage:
          'Try using the name of the corresponding parameter in the super '
          'constructor.');

  MatchingSuperParameters()
      : super(
            name: 'matching_super_parameters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  const _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var positionalSuperParameters = <SuperFormalParameter>[];
    for (var parameter in node.parameters.parameters) {
      if (parameter is SuperFormalParameter && parameter.isPositional) {
        positionalSuperParameters.add(parameter);
      }
    }
    if (positionalSuperParameters.isEmpty) {
      // We are only concerned with positional super-parameters.
      return;
    }
    var superInvocation =
        node.initializers.whereType<SuperConstructorInvocation>().firstOrNull;
    var superConstructor = superInvocation?.staticElement;
    if (superConstructor == null) {
      var class_ = node.parent;
      if (class_ is ClassDeclaration) {
        superConstructor =
            class_.declaredElement?.supertype?.element.unnamedConstructor;
      }
    }
    if (superConstructor is! ConstructorElement) {
      return;
    }
    var positionalParametersOfSuper =
        superConstructor.parameters.where((p) => p.isPositional).toList();
    if (positionalParametersOfSuper.length < positionalSuperParameters.length) {
      // More positional parameters are passed to super constructor than it
      // has positional parameters, an error.
      return;
    }
    for (var i = 0; i < positionalSuperParameters.length; i++) {
      var superParameter = positionalSuperParameters[i];
      var superParameterName = superParameter.name.lexeme;
      var parameterOfSuperName = positionalParametersOfSuper[i].name;
      if (superParameterName != parameterOfSuperName) {
        rule.reportLint(superParameter,
            arguments: [superParameterName, parameterOfSuperName]);
      }
    }
  }
}
