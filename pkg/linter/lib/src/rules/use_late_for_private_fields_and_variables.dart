// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Use late for private members with a non-nullable type.';

bool _isPrivateExtension(AstNode parent) {
  if (parent is! ExtensionDeclaration) {
    return false;
  }
  var parentName = parent.name?.lexeme;
  return parentName == null || Identifier.isPrivateName(parentName);
}

class UseLateForPrivateFieldsAndVariables extends LintRule {
  UseLateForPrivateFieldsAndVariables()
    : super(
        name: LintNames.use_late_for_private_fields_and_variables,
        description: _desc,
        state: const RuleState.experimental(),
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.useLateForPrivateFieldsAndVariables;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
    registry.afterLibrary(this, () => visitor.afterLibrary());
  }
}

class _Visitor extends RecursiveAstVisitor<void> {
  final Map<LibraryFragment, List<VariableDeclaration>> lateables =
      <LibraryFragment, List<VariableDeclaration>>{};

  final Set<Element> nullableAccess = <Element>{};

  final LintRule rule;
  final RuleContext context;

  /// The "current" [LibraryFragment], which is set by
  /// [visitCompilationUnit].
  late LibraryFragment currentLibraryFragment;

  _Visitor(this.rule, this.context);

  void afterLibrary() {
    for (var contextUnit in context.allUnits) {
      var libraryFragment = contextUnit.unit.declaredFragment;
      var variables = lateables[libraryFragment];
      if (variables == null) continue;
      for (var variable in variables) {
        var variableElement = variable.declaredFragment?.element;
        if (!nullableAccess.contains(variableElement)) {
          var contextUnit = context.allUnits.firstWhereOrNull(
            (u) => u.unit.declaredFragment == libraryFragment,
          );
          if (contextUnit == null) continue;
          contextUnit.diagnosticReporter.atNode(variable, rule.diagnosticCode);
        }
      }
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var element = node.writeElement?.canonicalElement2;
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
        nullableAccess.add(element.baseElement);
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
    var declaredFragment = node.declaredFragment;
    if (declaredFragment == null) return;
    currentLibraryFragment = declaredFragment;

    super.visitCompilationUnit(node);
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
    var element = node.element?.canonicalElement2;
    _visitIdentifierOrPropertyAccess(node, element);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    var element = node.propertyName.element?.canonicalElement2;
    _visitIdentifierOrPropertyAccess(node, element);
    super.visitPropertyAccess(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.element?.canonicalElement2;
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

  void _visit(VariableDeclaration variable) {
    if (variable.isLate) return;
    if (variable.isSynthetic) return;
    var declaredElement = variable.declaredFragment?.element;
    if (declaredElement == null ||
        context.typeSystem.isNonNullable(declaredElement.type)) {
      return;
    }
    lateables.putIfAbsent(currentLibraryFragment, () => []).add(variable);
  }

  /// Checks whether [expression], which must be an [Identifier] or
  /// [PropertyAccess], and its [canonicalElement], represent a nullable access.
  void _visitIdentifierOrPropertyAccess(
    Expression expression,
    Element? canonicalElement,
  ) {
    assert(expression is Identifier || expression is PropertyAccess);
    if (canonicalElement == null) return;

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
      nullableAccess.add(canonicalElement.baseElement);
    }
  }
}
