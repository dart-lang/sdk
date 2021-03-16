// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc = r'Use late for private members with non-nullable type.';

const _details = r'''

Use late for private members with non-nullable types that are always expected to
be non-null. Thus it's clear that the field is not expected to be `null` and it
avoids null checks.

**BAD:**
```dart
int? _i;
m() {
  _i!.abs();
}
```

**GOOD:**
```dart
late int _i;
m() {
  _i.abs();
}
```

''';

bool _isPrivateExtension(AstNode parent) {
  if (parent is! ExtensionDeclaration) {
    return false;
  }
  var parentName = parent.name?.name;
  return parentName == null || Identifier.isPrivateName(parentName);
}

class UseLateForPrivateFieldsAndVariables extends LintRule
    implements NodeLintRule {
  UseLateForPrivateFieldsAndVariables()
      : super(
          name: 'use_late_for_private_fields_and_variables',
          description: _desc,
          details: _details,
          maturity: Maturity.experimental,
          group: Group.style,
        );

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends UnifyingAstVisitor<void> {
  static final lateables =
      <CompilationUnitElement, List<VariableDeclaration>>{};

  static final nullableAccess = <CompilationUnitElement, Set<Element>>{};
  final LintRule rule;

  final LinterContext context;

  CompilationUnitElement? currentUnit;
  _Visitor(this.rule, this.context);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (node.featureSet.isEnabled(Feature.non_nullable)) {
      var declaredElement = node.declaredElement;
      if (declaredElement == null) {
        return;
      }
      lateables.putIfAbsent(declaredElement, () => []);
      nullableAccess.putIfAbsent(declaredElement, () => {});
      currentUnit = declaredElement;

      super.visitCompilationUnit(node);

      final unitsInContext =
          context.allUnits.map((e) => e.unit.declaredElement).toSet();
      final libraryUnitsInContext =
          declaredElement.library.units.where(unitsInContext.contains).toSet();
      final areAllLibraryUnitsVisited =
          libraryUnitsInContext.every(lateables.containsKey);
      if (areAllLibraryUnitsVisited) {
        _checkAccess(libraryUnitsInContext);

        // clean up
        libraryUnitsInContext.forEach((unit) {
          lateables.remove(unit);
          nullableAccess.remove(unit);
        });
      }
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    for (var variable in node.fields.variables) {
      final parent = node.parent;
      // see https://github.com/dart-lang/linter/pull/2189#issuecomment-660115569
      // We could also include public members in private classes but to do that
      // we'd need to ensure that there are no instances of either the
      // enclosing class or any subclass of the enclosing class that are ever
      // accessible outside this library.
      if (parent != null &&
          (Identifier.isPrivateName(variable.name.name) ||
              _isPrivateExtension(parent))) {
        _visit(variable);
      }
    }
    super.visitFieldDeclaration(node);
  }

  @override
  void visitNode(AstNode node) {
    var parent = node.parent;

    Element? element;
    if (parent is AssignmentExpression && parent.leftHandSide == node) {
      element = DartTypeUtilities.getCanonicalElement(parent.writeElement);
    } else {
      element = DartTypeUtilities.getCanonicalElementFromIdentifier(node);
    }

    if (element != null) {
      if (parent is Expression) {
        parent = parent.unParenthesized;
      }
      if (node is SimpleIdentifier && node.inDeclarationContext()) {
        // ok
      } else if (parent is PostfixExpression &&
          parent.operand == node &&
          parent.operator.type == TokenType.BANG) {
        // ok non-null access
      } else if (parent is AssignmentExpression &&
          parent.operator.type == TokenType.EQ &&
          DartTypeUtilities.isNonNullable(
              context, parent.rightHandSide.staticType)) {
        // ok non-null access
      } else {
        nullableAccess[currentUnit]?.add(element);
      }
    }
    super.visitNode(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (var variable in node.variables.variables) {
      if (Identifier.isPrivateName(variable.name.name)) {
        _visit(variable);
      }
    }
    super.visitTopLevelVariableDeclaration(node);
  }

  void _checkAccess(Iterable<CompilationUnitElement> units) {
    final allNullableAccess =
        units.expand((unit) => nullableAccess[unit] ?? const {}).toSet();
    for (final unit in units) {
      for (var variable in lateables[unit] ?? const <VariableDeclaration>[]) {
        if (!allNullableAccess.contains(variable.declaredElement)) {
          rule.reporter.reportError(AnalysisError(
              unit.source, variable.offset, variable.length, rule.lintCode));
        }
      }
    }
  }

  void _visit(VariableDeclaration variable) {
    if (variable.isLate) {
      return;
    }
    if (variable.isSynthetic) {
      return;
    }
    var declaredElement = variable.declaredElement;
    if (declaredElement == null ||
        context.typeSystem.isNonNullable(declaredElement.type)) {
      return;
    }
    lateables[currentUnit]?.add(variable);
  }
}
