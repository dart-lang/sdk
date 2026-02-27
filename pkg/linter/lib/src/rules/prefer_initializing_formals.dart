// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';

const _desc = r'Use initializing formals when possible.';

class PreferInitializingFormals extends AnalysisRule {
  PreferInitializingFormals()
    : super(name: LintNames.prefer_initializing_formals, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.preferInitializingFormals;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addConstructorDeclaration(this, visitor);
  }
}

/// Reports lints for a single constructor declaration.
class _ConstructorChecker {
  final AnalysisRule _rule;
  final ConstructorDeclaration _constructor;

  /// The elements for each constructor formal parameter.
  final List<Element?> _parameters;

  /// Elements for constructor parameters that are already initializing formals.
  final Set<Element> _initializingParameters = {};

  /// Group the AST nodes where we might show the lint by the field they
  /// initialize. If there are multiple places that initialize the same field,
  /// don't lint any of them. It would be confusing, because only one of them
  /// could be converted to an initializing formal and the linter doesn't know
  /// which one should be.
  final Map<Element, List<AstNode>> _nodesToLintByField = {};

  /// True if the "private_named_parameters" feature is enabled in the
  /// surrounding library.
  final bool _privateNamedParametersEnabled;

  _ConstructorChecker(
    this._rule,
    this._constructor, {
    required bool privateNamedParametersEnabled,
  }) : _parameters = _constructor.parameters.parameters
           .map((e) => e.declaredFragment?.element)
           .toList(),
       _privateNamedParametersEnabled = privateNamedParametersEnabled;

  void check() {
    // Don't lint initializers from parameters that are already initializing
    // formals.
    for (var parameterFragment in _constructor.parameters.parameterFragments) {
      if (parameterFragment == null) continue;

      var parameter = parameterFragment.element;
      // TODO(rnystrom): Handle declaring parameters for primary constructors
      // here too.
      if (parameter.isInitializingFormal) {
        _initializingParameters.add(parameter);
      }
    }

    // Look for constructor initializers to lint.
    for (var constructorInitializer in _constructor.initializers) {
      // Must be a public field initializer.
      if (constructorInitializer is! ConstructorFieldInitializer) continue;

      // Must be initializing from a variable.
      var initializerExpression = constructorInitializer.expression;
      if (initializerExpression is! SimpleIdentifier) continue;

      _checkInitializer(
        constructorInitializer,
        constructorInitializer.fieldName.element,
        initializerExpression.element,
      );
    }

    // If the constructor has a block body, look for field assignments in it.
    if (_constructor.body case BlockFunctionBody block) {
      for (var statement in block.block.statements) {
        // Must be an expression statement containing an assignment of the form
        // "this.x = x;" for some "x".
        //
        // We require this exact syntactic form to ensure that the field being
        // initialized is not just on this class but on the instance being
        // constructed by this constructor.
        if (statement case ExpressionStatement(
          expression: AssignmentExpression(
                leftHandSide: PropertyAccess(target: ThisExpression()),
              ) &&
              var assignment,
        )) {
          _checkInitializer(
            assignment,
            assignment.writeElement?.canonicalElement2,
            assignment.rightHandSide.canonicalElement,
          );
        }
      }
    }

    _nodesToLintByField.forEach((field, nodes) {
      for (var lintNode in nodes) {
        _rule.reportAtNode(lintNode, arguments: [field.name!]);
      }
    });
  }

  /// If the initialization of [field] with [parameter] should be linted, adds
  /// it to [_nodesToLintByField].
  void _checkInitializer(AstNode node, Element? field, Element? parameter) {
    // Must be assigning to an instance field.
    if (field is! FieldElement) return;
    if (field.isStatic) return;

    if (_initializingParameters.contains(parameter)) return;

    // Must be an actual field and not a setter.
    if (!field.isOriginDeclaration) return;

    // Must be assigning from a constructor parameter with a matching name.
    if (parameter is! FormalParameterElement) return;
    if (!_parameters.contains(parameter)) return;

    // An initializing formal is required to have a type that's a subtype of the
    // field type (assignability is not sufficient). If this requirement isn't
    // met, don't lint, because the corresponding fix will lead to a
    // compile-time error.
    var library = parameter.library!;
    if (!library.typeSystem.isSubtypeOf(parameter.type, field.type)) {
      return;
    }

    // Must be the same name (modulo privacy for private named parameters).
    if (field.isPrivate) {
      // Never lint on private names if the feature isn't supported.
      if (!_privateNamedParametersEnabled) return;

      // Only lint on private named parameters.
      if (parameter.isPositional) return;

      // Allow initializing a private field from a parameter with the same
      // private name or the corresponding public one.
      if (field.name != parameter.name && field.name != '_${parameter.name}') {
        return;
      }
    } else if (field.name != parameter.name) {
      return; // The name must match exactly.
    }

    // Must be initializing a field on the surrounding class and not an
    // inherited one.
    if (field.enclosingElement !=
        _constructor.declaredFragment?.element.enclosingElement) {
      return;
    }

    // There can't be any other references to the parameter. If there are, it's
    // possible removing the initializer/assignment and moving it up to be an
    // initializing formal could be a semantic change.
    var visitor = _ReferenceCounter(parameter);
    // Visit the initializers and body directly so that we ignore references in
    // the doc comment.
    _constructor.initializers.accept(visitor);
    _constructor.body.accept(visitor);
    if (visitor.count > 1) return;

    _nodesToLintByField.putIfAbsent(field, () => []).add(node);
  }
}

/// Counts references in the visited AST to a given parameter.
class _ReferenceCounter extends RecursiveAstVisitor<void> {
  final FormalParameterElement parameterElement;

  int count = 0;

  _ReferenceCounter(this.parameterElement);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element == parameterElement) {
      count++;
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule _rule;
  final RuleContext _context;

  _Visitor(this._rule, this._context);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // Skip factory constructors.
    // https://github.com/dart-lang/linter/issues/2441
    if (node.factoryKeyword != null) return;

    _ConstructorChecker(
      _rule,
      node,
      privateNamedParametersEnabled: _context.isFeatureEnabled(
        Feature.private_named_parameters,
      ),
    ).check();
  }
}
