// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'Omit type annotations for local variables.';

const _details = r'''
**DON'T** redundantly type annotate initialized local variables.

Local variables, especially in modern code where functions tend to be small,
have very little scope. Omitting the type focuses the reader's attention on the
more important *name* of the variable and its initialized value.

**BAD:**
```dart
List<List<Ingredient>> possibleDesserts(Set<Ingredient> pantry) {
  List<List<Ingredient>> desserts = <List<Ingredient>>[];
  for (final List<Ingredient> recipe in cookbook) {
    if (pantry.containsAll(recipe)) {
      desserts.add(recipe);
    }
  }

  return desserts;
}
```

**GOOD:**
```dart
List<List<Ingredient>> possibleDesserts(Set<Ingredient> pantry) {
  var desserts = <List<Ingredient>>[];
  for (final recipe in cookbook) {
    if (pantry.containsAll(recipe)) {
      desserts.add(recipe);
    }
  }

  return desserts;
}
```

Sometimes the inferred type is not the type you want the variable to have. For
example, you may intend to assign values of other types later. In that case,
annotate the variable with the type you want.

**GOOD:**
```dart
Widget build(BuildContext context) {
  Widget result = Text('You won!');
  if (applyPadding) {
    result = Padding(padding: EdgeInsets.all(8.0), child: result);
  }
  return result;
}
```
''';

class OmitLocalVariableTypes extends LintRule {
  OmitLocalVariableTypes()
      : super(
          name: 'omit_local_variable_types',
          description: _desc,
          details: _details,
        );

  @override
  List<String> get incompatibleRules => const [
        'always_specify_types',
        'specify_nonobvious_local_variable_types',
      ];

  @override
  LintCode get lintCode => LinterLintCode.omit_local_variable_types;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context.typeProvider);
    registry.addForStatement(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final TypeProvider typeProvider;

  _Visitor(this.rule, this.typeProvider);

  @override
  void visitForStatement(ForStatement node) {
    var loopParts = node.forLoopParts;
    if (loopParts is ForPartsWithDeclarations) {
      _visitVariableDeclarationList(loopParts.variables);
    } else if (loopParts is ForEachPartsWithDeclaration) {
      var loopVariableType = loopParts.loopVariable.type;
      var staticType = loopVariableType?.type;
      if (staticType == null || staticType is DynamicType) return;

      var loopType = loopParts.iterable.staticType;
      if (loopType is! InterfaceType) return;

      var iterableType = loopType.asInstanceOf(typeProvider.iterableElement);
      if (iterableType == null) return;
      if (iterableType.typeArguments.isNotEmpty &&
          iterableType.typeArguments.first == staticType) {
        rule.reportLint(loopVariableType);
      }
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _visitVariableDeclarationList(node.variables);
  }

  void _visitVariableDeclarationList(VariableDeclarationList node) {
    var staticType = node.type?.type;
    if (staticType == null ||
        staticType is DynamicType ||
        staticType.isDartCoreNull) {
      return;
    }
    for (var child in node.variables) {
      var initializer = child.initializer;
      if (initializer == null || initializer.staticType != staticType) {
        return;
      }

      if (initializer is IntegerLiteral && !staticType.isDartCoreInt) {
        // Coerced int.
        return;
      }

      if (initializer.dependsOnDeclaredTypeForInference) {
        return;
      }
    }
    rule.reportLint(node.type);
  }
}

extension on Expression {
  bool get dependsOnDeclaredTypeForInference {
    if (this case MethodInvocation(:var methodName, typeArguments: null)) {
      var element = methodName.staticElement;
      if (element is FunctionElement) {
        if (element.returnType is TypeParameterType) {
          return true;
        }
      }
    }
    return false;
  }
}
