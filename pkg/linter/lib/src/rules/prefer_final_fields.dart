// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';

const _desc = r'Private field could be `final`.';

class PreferFinalFields extends AnalysisRule {
  new() : super(name: LintNames.prefer_final_fields, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.preferFinalFields;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addAssignmentExpression(this, visitor);
    registry.addFieldDeclaration(this, visitor);
    registry.addPostfixExpression(this, visitor);
    registry.addPrefixExpression(this, visitor);
    registry.addPrimaryConstructorDeclaration(this, visitor);
    registry.afterLibrary(this, visitor.afterLibrary);
  }
}

/// Collects candidate fields and mutated fields from all units of the
/// library, and reports the candidates that are never mutated after the
/// whole library is visited.
class _Visitor(final AnalysisRule rule, final RuleContext context)
    extends SimpleAstVisitor<void> {
  /// The candidate fields explicitly declared in this library, with the unit
  /// that declares each one.
  final Map<FieldElement, (RuleContextUnit, VariableDeclaration)> _fields = {};

  /// The candidate fields declared via a declaring parameter in this library,
  /// with the unit that declares each one.
  final Map<FieldElement, (RuleContextUnit, FormalParameter)>
  _fieldsFromParameters = {};

  /// The fields that are assigned anywhere in this library.
  ///
  /// Kept separately from the candidates, because an assignment might be
  /// visited before the declaration of the field, for example when it is in a
  /// method above the field, or in another unit.
  final Set<FieldElement> _mutatedFields = {};

  void afterLibrary() {
    for (var MapEntry(key: field, value: (unit, variable)) in _fields.entries) {
      if (_mutatedFields.contains(field)) continue;

      // TODO(srawlins): We could look at the constructors once and store a set
      // of which fields are initialized by any, and a set of which fields are
      // initialized by all. This would conceivably improve performance.
      var classDeclaration = variable.parent?.parent?.parent?.parent;
      var constructors = <ConstructorDeclaration>[];
      if (classDeclaration is ClassDeclaration) {
        constructors = classDeclaration.body.members
            .whereType<ConstructorDeclaration>()
            .toList();
      }

      var isSetInAnyConstructor = constructors.any(
        (constructor) => field.isSetInConstructor(constructor),
      );

      if (isSetInAnyConstructor) {
        var isSetInEveryConstructor = constructors.every(
          (constructor) => field.isSetInConstructor(constructor),
        );

        if (isSetInEveryConstructor) {
          _report(unit, variable, variable.name);
        }
      } else if (field.hasInitializer) {
        _report(unit, variable, variable.name);
      }
    }

    for (var MapEntry(key: field, value: (unit, parameter))
        in _fieldsFromParameters.entries) {
      if (_mutatedFields.contains(field)) continue;
      _report(unit, parameter, parameter.name!);
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _addMutatedField(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.isInvalidExtensionTypeField) return;
    if (node.parent?.parent is EnumDeclaration) return;
    if (node.fields.isFinal || node.fields.isConst) {
      return;
    }

    for (var variable in node.fields.variables) {
      var element = variable.declaredFragment?.element;
      if (element is FieldElement &&
          element.name != null &&
          element.isPrivate &&
          !_overridesField(element)) {
        _fields[element] = (context.currentUnit!, variable);
      }
    }
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _addMutatedField(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    var operator = node.operator;
    if (operator.type == TokenType.MINUS_MINUS ||
        operator.type == TokenType.PLUS_PLUS) {
      _addMutatedField(node);
    }
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    var declaration = node.parent;
    if (declaration is EnumDeclaration ||
        declaration is ExtensionTypeDeclaration) {
      return;
    }

    for (var parameter in node.formalParameters.parameters) {
      var element = parameter.declaredFragment?.element;
      if (element is FieldFormalParameterElement &&
          element.isDeclaring &&
          element.name != null &&
          element.isPrivate) {
        var field = element.field;
        if (field != null && !field.isFinal && !_overridesField(field)) {
          _fieldsFromParameters[field] = (context.currentUnit!, parameter);
        }
      }
    }
  }

  void _addMutatedField(CompoundAssignmentExpression assignment) {
    var element = assignment.writeElement?.canonicalElement2;
    element = element?.baseElement;

    if (element is FieldElement) {
      _mutatedFields.add(element);
    }
  }

  bool _overridesField(FieldElement field) {
    var enclosingElement = field.enclosingElement;
    if (enclosingElement is! InterfaceElement) return false;

    return enclosingElement.getOverridden(
          Name.forLibrary(field.library, '${field.name!}='),
        ) !=
        null;
  }

  /// Reports [node], which is in [unit].
  ///
  /// This does not use `rule.reportAtNode`, because it reports to the unit
  /// that is currently being visited. In [afterLibrary] that is the last unit
  /// of the library, not necessarily [unit], so the diagnostic would be
  /// attached to the wrong file, with offsets from another file.
  void _report(RuleContextUnit unit, AstNode node, Token name) {
    unit.diagnosticReporter.atNode(
      node,
      rule.diagnosticCode,
      arguments: [name.lexeme],
    );
  }
}

extension on FieldElement {
  bool isSetInConstructor(ConstructorDeclaration constructor) =>
      constructor.initializers.any(isSetInInitializer) ||
      constructor.parameters.parameters.any(isSetInParameter);

  /// Whether `this` is initialized in [initializer].
  bool isSetInInitializer(ConstructorInitializer initializer) =>
      initializer is ConstructorFieldInitializer &&
      initializer.fieldName.canonicalElement == this;

  /// Whether `this` is initialized with [parameter].
  bool isSetInParameter(FormalParameter parameter) {
    var formalField = parameter.declaredFragment?.element;
    return formalField is FieldFormalParameterElement &&
        formalField.field == this;
  }
}
