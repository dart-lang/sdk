// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';
import '../util/obvious_types.dart';

const _desc = r'Omit obvious type annotations for local variables.';

const _details = r'''
Don't type annotate initialized local variables when the type is obvious.

Local variables, especially in modern code where functions tend to be small,
have very little scope. Omitting the type focuses the reader's attention on the
more important *name* of the variable and its initialized value. Hence, local
variable type annotations that are obvious should be omitted.

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

const cookbook = <List<Ingredient>>[....];
```

**GOOD:**
```dart
List<List<Ingredient>> possibleDesserts(Set<Ingredient> pantry) {
  var desserts = <List<Ingredient>>[];
  for (final List<Ingredient> recipe in cookbook) {
    if (pantry.containsAll(recipe)) {
      desserts.add(recipe);
    }
  }

  return desserts;
}

const cookbook = <List<Ingredient>>[....];
```

Sometimes the inferred type is not the type you want the variable to have. For
example, you may intend to assign values of other types later. You may also
wish to write a type annotation explicitly because the type of the initializing
expression is non-obvious and it will be helpful for future readers of the
code to document this type. Or you may wish to commit to a specific type such
that future updates of dependencies (in nearby code, in imports, anywhere)
will not silently change the type of that variable, thus introducing
compile-time errors or run-time bugs in locations where this variable is used.
In those cases, go ahead and annotate the variable with the type you want.

**GOOD:**
```dart
Widget build(BuildContext context) {
  Widget result = someGenericFunction(42) ?? Text('You won!');
  if (applyPadding) {
    result = Padding(padding: EdgeInsets.all(8.0), child: result);
  }
  return result;
}
```

**This rule is experimental.** It is being evaluated, and it may be changed
or removed. Feedback on its behavior is welcome! The main issue is here:
https://github.com/dart-lang/linter/issues/3480.
''';

class OmitObviousLocalVariableTypes extends LintRule {
  OmitObviousLocalVariableTypes()
      : super(
            name: 'omit_obvious_local_variable_types',
            description: _desc,
            details: _details,
            state: State.experimental(),
            categories: {LintRuleCategory.style});

  @override
  List<String> get incompatibleRules => const ['always_specify_types'];

  @override
  LintCode get lintCode => LinterLintCode.omit_obvious_local_variable_types;

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
      var iterable = loopParts.iterable;
      if (!iterable.hasObviousType) {
        return;
      }
      var iterableType = iterable.staticType;
      if (iterableType.elementTypeOfIterable == staticType) {
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
    if (staticType == null || staticType.isDartCoreNull) {
      return;
    }
    for (var child in node.variables) {
      var initializer = child.initializer;
      if (initializer != null && !initializer.hasObviousType) {
        return;
      }
      if (initializer?.staticType != staticType) {
        return;
      }
    }
    rule.reportLint(node.type);
  }
}
