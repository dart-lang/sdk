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
import '../extensions.dart';

const _desc = r'Use late for private members with a non-nullable type.';

const _details = r'''
Use `late` for private members with non-nullable types that are always expected
to be non-null. Thus it's clear that the field is not expected to be `null`
and it avoids null checks.

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

**OK:**
```dart
int? _i;
m() {
  _i?.abs();
  _i = null;
}
```

''';

bool _isPrivateExtension(AstNode parent) {
  if (parent is! ExtensionDeclaration) {
    return false;
  }
  var parentName = parent.name?.lexeme;
  return parentName == null || Identifier.isPrivateName(parentName);
}

class UseLateForPrivateFieldsAndVariables extends LintRule {
  static const LintCode code = LintCode(
      'use_late_for_private_fields_and_variables',
      "Use 'late' for private members with a non-nullable type.",
      correctionMessage: "Try making adding the modifier 'late'.");

  UseLateForPrivateFieldsAndVariables()
      : super(
          name: 'use_late_for_private_fields_and_variables',
          description: _desc,
          details: _details,
          state: State.experimental(),
          group: Group.style,
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends RecursiveAstVisitor<void> {
  static final lateables =
      <CompilationUnitElement, List<VariableDeclaration>>{};

  static final nullableAccess = <CompilationUnitElement, Set<Element>>{};
  final LintRule rule;

  final LinterContext context;

  CompilationUnitElement? currentUnit;
  _Visitor(this.rule, this.context);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var element = node.writeElement?.canonicalElement;
    if (element != null) {
      var assignee = node.leftHandSide;
      var rhsType = node.rightHandSide.staticType;
      if (assignee is SimpleIdentifier && assignee.inDeclarationContext()) {
        // This is OK.
      } else if (node.operator.type == TokenType.EQ &&
          rhsType != null &&
          context.typeSystem.isNonNullable(rhsType)) {
        // This is OK; non-null access.
      } else {
        nullableAccess[currentUnit]?.add(element);
      }
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // See: https://dart.dev/tools/diagnostic-messages#late_final_field_with_const_constructor
    for (var member in node.members) {
      if (member is ConstructorDeclaration && member.constKeyword != null) {
        return;
      }
    }

    super.visitClassDeclaration(node);
  }

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

      var unitsInContext =
          context.allUnits.map((e) => e.unit.declaredElement).toSet();
      var libraryUnitsInContext =
          declaredElement.library.units.where(unitsInContext.contains).toSet();
      var areAllLibraryUnitsVisited =
          libraryUnitsInContext.every(lateables.containsKey);
      if (areAllLibraryUnitsVisited) {
        _checkAccess(libraryUnitsInContext);

        // Clean up.
        for (var unit in libraryUnitsInContext) {
          lateables.remove(unit);
          nullableAccess.remove(unit);
        }
      }
    }
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    // See: https://dart.dev/tools/diagnostic-messages#late_final_field_with_const_constructor
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    var parent = node.parent;
    if (parent is ExtensionTypeDeclaration && !node.isStatic) return;
    if (parent != null) {
      var parentIsPrivateExtension = _isPrivateExtension(parent);
      for (var variable in node.fields.variables) {
        // See
        // https://github.com/dart-lang/linter/pull/2189#issuecomment-660115569.
        // We could also include public members in private classes but to do
        // that we'd need to ensure that there are no instances of either the
        // enclosing class or any subclass of the enclosing class that are ever
        // accessible outside this library.
        if (parentIsPrivateExtension ||
            Identifier.isPrivateName(variable.name.lexeme)) {
          _visit(variable);
        }
      }
    }
    super.visitFieldDeclaration(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    var element = node.staticElement?.canonicalElement;
    _visitIdentifierOrPropertyAccess(node, element);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    var element = node.propertyName.staticElement?.canonicalElement;
    _visitIdentifierOrPropertyAccess(node, element);
    super.visitPropertyAccess(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement?.canonicalElement;
    _visitIdentifierOrPropertyAccess(node, element);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (var variable in node.variables.variables) {
      if (Identifier.isPrivateName(variable.name.lexeme)) {
        _visit(variable);
      }
    }
    super.visitTopLevelVariableDeclaration(node);
  }

  void _checkAccess(Iterable<CompilationUnitElement> units) {
    var allNullableAccess =
        units.expand((unit) => nullableAccess[unit] ?? const {}).toSet();
    for (var unit in units) {
      for (var variable in lateables[unit] ?? const <VariableDeclaration>[]) {
        if (!allNullableAccess.contains(variable.declaredElement)) {
          rule.reporter.reportError(AnalysisError.tmp(
              source: unit.source,
              offset: variable.offset,
              length: variable.length,
              errorCode: rule.lintCode));
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

  /// Checks whether [expression], which must be an [Identifier] or
  /// [PropertyAccess], and its [canonicalElement], represent a nullable access.
  void _visitIdentifierOrPropertyAccess(
      Expression expression, Element? canonicalElement) {
    assert(expression is Identifier || expression is PropertyAccess);
    if (canonicalElement != null) {
      var parent = expression.parent;
      if (parent is Expression) {
        parent = parent.unParenthesized;
      }
      if (expression is SimpleIdentifier && expression.inDeclarationContext()) {
        // This is OK.
      } else if (parent is PostfixExpression &&
          parent.operand == expression &&
          parent.operator.type == TokenType.BANG) {
        // This is OK; non-null access.
      } else {
        nullableAccess[currentUnit]?.add(canonicalElement);
      }
    }
  }
}
