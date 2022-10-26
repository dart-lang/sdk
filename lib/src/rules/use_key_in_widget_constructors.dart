// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../util/flutter_utils.dart';

const _desc = r'Use key in widget constructors.';

const _details = r'''
**DO** use key in widget constructors.

It's a good practice to expose the ability to provide a key when creating public
widgets.

**BAD:**
```dart
class MyPublicWidget extends StatelessWidget {
}
```

**GOOD:**
```dart
class MyPublicWidget extends StatelessWidget {
  MyPublicWidget({super.key});
}
```
''';

class UseKeyInWidgetConstructors extends LintRule {
  static const LintCode code = LintCode('use_key_in_widget_constructors',
      "Constructors for public widgets should have a named 'key' parameter.",
      correctionMessage: 'Try adding a named parameter to the constructor.');

  UseKeyInWidgetConstructors()
      : super(
            name: 'use_key_in_widget_constructors',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var classElement = node.declaredElement;
    if (classElement != null &&
        classElement.isPublic &&
        hasWidgetAsAscendant(classElement) &&
        classElement.constructors.where((e) => !e.isSynthetic).isEmpty) {
      rule.reportLintForToken(node.name);
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var constructorElement = node.declaredElement;
    if (constructorElement == null) {
      return;
    }
    var classElement = constructorElement.enclosingElement;
    if (constructorElement.isPublic &&
        !constructorElement.isFactory &&
        classElement.isPublic &&
        classElement is ClassElement &&
        hasWidgetAsAscendant(classElement) &&
        !isExactWidget(classElement) &&
        !_hasKeySuperParameterInitializerArg(node) &&
        !node.initializers.any((initializer) {
          if (initializer is SuperConstructorInvocation) {
            var staticElement = initializer.staticElement;
            return staticElement != null &&
                (!_defineKeyParameter(staticElement) ||
                    _defineKeyArgument(initializer.argumentList));
          } else if (initializer is RedirectingConstructorInvocation) {
            var staticElement = initializer.staticElement;
            return staticElement != null &&
                (!_defineKeyParameter(staticElement) ||
                    _defineKeyArgument(initializer.argumentList));
          }
          return false;
        })) {
      var errorNode = node.name ?? node.returnType;
      rule.reportLintForOffset(errorNode.offset, errorNode.length);
    }
    super.visitConstructorDeclaration(node);
  }

  bool _defineKeyArgument(ArgumentList argumentList) => argumentList.arguments
      .any((a) => a.staticParameterElement?.name == 'key');

  bool _defineKeyParameter(ConstructorElement element) =>
      element.parameters.any((e) => e.name == 'key' && _isKeyType(e.type));

  bool _hasKeySuperParameterInitializerArg(ConstructorDeclaration node) {
    for (var parameter in node.parameters.parameters) {
      var element = parameter.declaredElement;
      if (element is SuperFormalParameterElement && element.name == 'key') {
        return true;
      }
    }

    return false;
  }

  bool _isKeyType(DartType type) => type.implementsInterface('Key', '');
}
