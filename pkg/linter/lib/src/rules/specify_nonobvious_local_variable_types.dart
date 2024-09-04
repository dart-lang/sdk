// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';
import '../util/obvious_types.dart';

const _desc = r'Specify non-obvious type annotations for local variables.';

const _details = r'''
Do type annotate initialized local variables when the type is non-obvious.

Type annotations on local variables can serve as a request for type inference,
documenting the expected outcome of the type inference step, and declaratively
allowing the compiler and analyzer to solve the possibly complex task of 
finding type arguments and annotations in the initializing expression that
yield the desired result.

Type annotations on local variables can also inform readers about the type
of the initializing expression, which will allow them to proceed reading the
subsequent lines of code with known good information about the type of the
given variable (which may not be immediately evident by looking at the
initializing expression).

An expression is considered to have a non-obvious type when it does not
have an obvious type.

An expression e has an obvious type in the following cases:

- e is a non-collection literal. For instance, 1, true, 'Hello, $name!'.
- e is a collection literal with actual type arguments. For instance,
  <int, bool>{}.
- e is a list literal or a set literal where at least one element has an
  obvious type, and all elements have the same type. For instance, [1, 2] and
  { [true, false], [] }, but not [1, 1.5].
- e is a map literal where all key-value pair have a key with an obvious type
  and a value with an obvious type, and all keys have the same type, and all 
  values have the same type. For instance, { #a: <int>[] }, but not
  {1: 1, 2: true}.
- e is an instance creation expression whose class part is not raw. For 
  instance C(14) if C is a non-generic class, or C<int>(14) if C accepts one
  type argument, but not C(14) if C accepts one or more type arguments.
- e is a cascade whose target has an obvious type. For instance,
  1..isEven..isEven has an obvious type because 1 has an obvious type.
- e is a type cast. For instance, myComplexpression as int.

**BAD:**
```dart
List<List<Ingredient>> possibleDesserts(Set<Ingredient> pantry) {
  var desserts = genericFunctionDeclaredFarAway(<num>[42], 'Something');
  for (final recipe in cookbook) {
    if (pantry.containsAll(recipe)) {
      desserts.add(recipe);
    }
  }

  return desserts;
}

const List<List<Ingredient>> cookbook = ...;
```

**GOOD:**
```dart
List<List<Ingredient>> possibleDesserts(Set<Ingredient> pantry) {
  List<List<Ingredient>> desserts = genericFunctionDeclaredFarAway(
    <num>[42], 
    'Something',
  );
  for (final List<Ingredient> recipe in cookbook) {
    if (pantry.containsAll(recipe)) {
      desserts.add(recipe);
    }
  }

  return desserts;
}

const List<List<Ingredient>> cookbook = ...;
```

**This rule is experimental.** It is being evaluated, and it may be changed
or removed. Feedback on its behavior is welcome! The main issue is here:
https://github.com/dart-lang/linter/issues/3480.
''';

class SpecifyNonObviousLocalVariableTypes extends LintRule {
  SpecifyNonObviousLocalVariableTypes()
      : super(
          name: 'specify_nonobvious_local_variable_types',
          description: _desc,
          details: _details,
          state: State.experimental(),
        );

  @override
  List<String> get incompatibleRules => const ['omit_local_variable_types'];

  @override
  LintCode get lintCode =>
      LinterLintCode.specify_nonobvious_local_variable_types;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addForStatement(this, visitor);
    registry.addPatternVariableDeclarationStatement(this, visitor);
    registry.addSwitchStatement(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _PatternVisitor extends GeneralizingAstVisitor<void> {
  final LintRule rule;

  _PatternVisitor(this.rule);

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    var staticType = node.type?.type;
    if (staticType != null &&
        staticType is! DynamicType &&
        !staticType.isDartCoreNull) {
      return;
    }
    rule.reportLint(node);
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
      if (staticType != null && staticType is! DynamicType) {
        return;
      }
      var iterable = loopParts.iterable;
      if (iterable.hasObviousType) {
        return;
      }
      rule.reportLint(loopParts.loopVariable, ignoreSyntheticNodes: false);
    }
  }

  @override
  void visitPatternVariableDeclarationStatement(
      PatternVariableDeclarationStatement node) {
    if (node.declaration.expression.hasObviousType) return;
    _PatternVisitor(rule).visitDartPattern(node.declaration.pattern);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {}

  @override
  void visitSwitchStatement(SwitchStatement node) {
    if (node.expression.hasObviousType) return;
    for (SwitchMember member in node.members) {
      if (member is SwitchPatternCase) {
        _PatternVisitor(rule).visitSwitchPatternCase(member);
      }
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _visitVariableDeclarationList(node.variables);
  }

  void _visitVariableDeclarationList(VariableDeclarationList node) {
    var staticType = node.type?.type;
    if (staticType != null && !staticType.isDartCoreNull) {
      return;
    }
    bool aDeclaredTypeIsNeeded = false;
    var variablesThatNeedAType = <VariableDeclaration>[];
    for (var child in node.variables) {
      var initializer = child.initializer;
      if (initializer == null) {
        aDeclaredTypeIsNeeded = true;
        variablesThatNeedAType.add(child);
      } else {
        if (!initializer.hasObviousType) {
          aDeclaredTypeIsNeeded = true;
          variablesThatNeedAType.add(child);
        }
      }
    }
    if (aDeclaredTypeIsNeeded) {
      if (node.variables.length == 1) {
        rule.reportLint(node);
      } else {
        // Multiple variables, report each of them separately. No fix.
        variablesThatNeedAType.forEach(rule.reportLint);
      }
    }
  }
}
