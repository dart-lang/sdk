// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';

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
  static const LintCode code = LintCode('omit_local_variable_types',
      'Unnecessary type annotation on a local variable.',
      correctionMessage: 'Try removing the type annotation.');

  OmitLocalVariableTypes()
      : super(
            name: 'omit_local_variable_types',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  List<String> get incompatibleRules => const ['always_specify_types'];

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addForStatement(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitForStatement(ForStatement node) {
    var loopParts = node.forLoopParts;
    if (loopParts is ForPartsWithDeclarations) {
      _visitVariableDeclarationList(loopParts.variables);
    } else if (loopParts is ForEachPartsWithDeclaration) {
      var loopVariableType = loopParts.loopVariable.type;
      var staticType = loopVariableType?.type;
      if (staticType == null || staticType is DynamicType) {
        return;
      }
      var iterableType = loopParts.iterable.staticType;
      if (iterableType is InterfaceType) {
        // TODO(srawlins): Is `DartType.asInstanceOf` the more correct API here?
        var iterableInterfaces = iterableType.implementedInterfaces
            .where((type) => type.isDartCoreIterable);
        if (iterableInterfaces.length == 1 &&
            iterableInterfaces.first.typeArguments.first == staticType) {
          rule.reportLint(loopVariableType);
        }
      }
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _visitVariableDeclarationList(node.variables);
  }

  bool _dependsOnDeclaredTypeForInference(Expression? initializer) {
    if (initializer is MethodInvocation) {
      if (initializer.typeArguments == null) {
        var element = initializer.methodName.staticElement;
        if (element is FunctionElement) {
          if (element.returnType is TypeParameterType) {
            return true;
          }
        }
      }
    }
    return false;
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
      if (initializer?.staticType != staticType) {
        return;
      }
      if (_dependsOnDeclaredTypeForInference(initializer)) {
        return;
      }
    }
    rule.reportLint(node);
  }
}
