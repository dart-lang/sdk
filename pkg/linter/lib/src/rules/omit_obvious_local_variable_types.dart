// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';

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
  for (List<Ingredient> recipe in cookbook) {
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
  for (List<Ingredient> recipe in cookbook) {
    if (pantry.containsAll(recipe)) {
      desserts.add(recipe);
    }
  }

  return desserts;
}
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

bool _sameOrNull(DartType? t1, DartType? t2) =>
    t1 == null || t2 == null || t1 == t2;

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
    if (staticType == null ||
        staticType is DynamicType ||
        staticType.isDartCoreNull) {
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

extension on CollectionElement {
  DartType? get elementType {
    var self = this; // Enable promotion.
    switch (self) {
      case MapLiteralEntry():
        return null;
      case ForElement():
        // No need to compute the type of a non-obvious element.
        return null;
      case IfElement():
        // We just need a candidate type, ignore `else`.
        return self.thenElement.elementType;
      case Expression():
        return self.staticType;
      case SpreadElement():
        return self.expression.staticType.elementTypeOfIterable;
      case NullAwareElement():
        // This should be the non-nullable version of `self.value.staticType`,
        // but since it requires computation, we return null.
        return null;
    }
  }

  bool get hasObviousType {
    var self = this; // Enable promotion.
    switch (self) {
      case MapLiteralEntry():
        return self.key.hasObviousType && self.value.hasObviousType;
      case ForElement():
        return false;
      case IfElement():
        return self.thenElement.hasObviousType &&
            (self.elseElement?.hasObviousType ?? true);
      case Expression():
        return self.hasObviousType;
      case SpreadElement():
        return self.expression.hasObviousType;
      case NullAwareElement():
        return self.value.hasObviousType;
    }
  }

  DartType? get keyType {
    var self = this; // Enable promotion.
    switch (self) {
      case MapLiteralEntry():
        return self.key.elementType;
      default:
        return null;
    }
  }

  DartType? get valueType {
    var self = this; // Enable promotion.
    switch (self) {
      case MapLiteralEntry():
        return self.value.elementType;
      default:
        return null;
    }
  }
}

extension on DartType? {
  DartType? get elementTypeOfIterable {
    var self = this; // Enable promotion.
    if (self == null) return null;
    if (self is InterfaceType) {
      var iterableInterfaces =
          self.implementedInterfaces.where((type) => type.isDartCoreIterable);
      if (iterableInterfaces.length == 1) {
        return iterableInterfaces.first.typeArguments.first;
      }
    }
    return null;
  }
}

extension on Expression {
  bool get hasObviousType {
    var self = this; // Enable promotion.
    switch (self) {
      case TypedLiteral():
        if (self.typeArguments != null) {
          // A collection literal with explicit type arguments is trivial.
          return true;
        }
        // A collection literal with no explicit type arguments.
        DartType? theObviousType, theObviousKeyType, theObviousValueType;
        NodeList<CollectionElement> elements = switch (self) {
          ListLiteral() => self.elements,
          SetOrMapLiteral() => self.elements
        };
        for (var element in elements) {
          if (element.hasObviousType) {
            theObviousType ??= element.elementType;
            theObviousKeyType ??= element.keyType;
            theObviousValueType ??= element.valueType;
            if (!_sameOrNull(theObviousType, element.elementType) ||
                !_sameOrNull(theObviousKeyType, element.keyType) ||
                !_sameOrNull(theObviousValueType, element.valueType)) {
              return false;
            }
          } else {
            return false;
          }
        }
        var theSelfElementType = self.staticType.elementTypeOfIterable;
        return theSelfElementType == theObviousType;
      case Literal():
        // An atomic literal: `Literal` and not `TypedLiteral`.
        if (self is IntegerLiteral &&
            (self.staticType?.isDartCoreDouble ?? false)) {
          return false;
        }
        return true;
      case InstanceCreationExpression():
        var createdType = self.constructorName.type;
        if (createdType.typeArguments != null) {
          // Explicit type arguments provided.
          return true;
        } else {
          DartType? dartType = createdType.type;
          if (dartType != null) {
            if (dartType is InterfaceType &&
                dartType.element.typeParameters.isNotEmpty) {
              // A raw type is not trivial.
              return false;
            }
            // A non-generic class or extension type.
            return true;
          } else {
            // An unknown type is not trivial.
            return false;
          }
        }
      case CascadeExpression():
        return self.target.hasObviousType;
      case AsExpression():
        return true;
    }
    return false;
  }
}
