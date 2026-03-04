// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/extensions.dart'; // ignore: implementation_imports
import 'package:analyzer/src/utilities/extensions/string.dart'; // ignore: implementation_imports

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Use super-initializer parameters where possible.';

/// Return a set containing the elements of all of the parameters that are
/// referenced in the constructor [body].
Set<FormalParameterElement> _referencedParameters(FunctionBody? body) {
  if (body == null) return const {};
  var collector = _ReferencedParameterCollector();
  body.accept(collector);
  return collector.foundParameters;
}

class UseSuperParameters extends MultiAnalysisRule {
  UseSuperParameters()
    : super(
        name: LintNames.use_super_parameters,
        description: _desc,
        state: const RuleState.experimental(),
      );

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    diag.useSuperParametersMultiple,
    diag.useSuperParametersSingle,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isFeatureEnabled(Feature.super_parameters)) return;

    var visitor = _Visitor(this, context);
    registry.addConstructorDeclaration(this, visitor);
    registry.addPrimaryConstructorDeclaration(this, visitor);
  }
}

class _ReferencedParameterCollector extends RecursiveAstVisitor<void> {
  final Set<FormalParameterElement> foundParameters = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.element;
    if (element is FormalParameterElement) {
      foundParameters.add(element);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final RuleContext context;
  final MultiAnalysisRule rule;

  _Visitor(this.rule, this.context);

  void check(
    SourceRange errorRange,
    SuperConstructorInvocation superInvocation,
    FormalParameterList parameters,
    FunctionBody? body,
  ) {
    var constructorElement = superInvocation.element;
    if (constructorElement == null) return;

    // TODO(pq): consolidate logic shared w/ server
    //  (https://github.com/dart-lang/linter/issues/3263)

    var referencedParameters = _referencedParameters(body);

    var identifiers = _checkForConvertiblePositionalParams(
      constructorElement,
      superInvocation,
      parameters,
      referencedParameters,
    );

    // Bail if there are positional params that can't be converted.
    if (identifiers == null) return;

    for (var parameter in parameters.parameters) {
      var parameterElement = parameter.declaredFragment?.element;
      if (parameterElement == null) continue;
      if (parameterElement is FieldFormalParameterElement) continue;
      if (parameterElement.isNamed &&
          !referencedParameters.contains(parameterElement)) {
        if (_checkNamedParameter(
          parameter,
          parameterElement,
          constructorElement,
          superInvocation,
        )) {
          var identifier = parameter.name?.lexeme;
          if (identifier != null) {
            identifiers.add(identifier);
          }
        }
      }
    }

    if (identifiers.isEmpty) return;
    if (identifiers.length > 1) {
      var msg = identifiers.quotedAndCommaSeparatedWithAnd;
      rule.reportAtOffset(
        errorRange.offset,
        errorRange.length,
        diagnosticCode: diag.useSuperParametersMultiple,
        arguments: [msg],
      );
    } else {
      rule.reportAtOffset(
        errorRange.offset,
        errorRange.length,
        diagnosticCode: diag.useSuperParametersSingle,
        arguments: [identifiers.first],
      );
    }
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    for (var initializer in node.initializers.reversed) {
      if (initializer is SuperConstructorInvocation) {
        check(node.errorRange, initializer, node.parameters, node.body);
        return;
      }
    }
  }

  @override
  visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    if (node.body case var body?) {
      for (var initializer in body.initializers.reversed) {
        if (initializer is SuperConstructorInvocation) {
          check(node.errorRange, initializer, node.formalParameters, body.body);
          return;
        }
      }
    }
  }

  /// Check if all super positional parameters can be converted to use super-
  /// initializers. Return a list of convertible named parameters or `null` if
  /// there are parameters that can't be converted since this will short-circuit
  /// the lint.
  List<String>? _checkForConvertiblePositionalParams(
    ConstructorElement constructorElement,
    SuperConstructorInvocation superInvocation,
    FormalParameterList parameters,
    Set<FormalParameterElement> referencedParameters,
  ) {
    var positionalSuperArgs = <SimpleIdentifier>[];
    for (var arg in superInvocation.argumentList.arguments) {
      if (arg is SimpleIdentifier) {
        positionalSuperArgs.add(arg);
      } else if (arg is! NamedExpression) {
        return null;
      }
    }

    if (positionalSuperArgs.isEmpty) return [];

    var constructorParams = parameters.parameters;
    var convertibleConstructorParams = <String>[];
    var matchedConstructorParamIndex = 0;

    var seenSuperParams = <Element>{};

    // For each super arg, ensure there is a constructor param (in the right
    // order).
    for (var i = 0; i < positionalSuperArgs.length; ++i) {
      var superArg = positionalSuperArgs[i];
      var superParam = superArg.element;
      if (superParam is! FormalParameterElement) return null;
      if (superParam.isNamed) return null;

      // Check for the case where a super param is used more than once.
      if (!seenSuperParams.add(superParam)) return null;

      bool match = false;
      for (var i = 0; i < constructorParams.length && !match; ++i) {
        var constructorParam = constructorParams[i];
        if (constructorParam is FieldFormalParameter) return null;
        if (constructorParam is SuperFormalParameter) return null;
        var constructorElement = constructorParam.declaredFragment?.element;
        if (constructorElement == null) return null;
        if (referencedParameters.contains(constructorElement)) return null;
        if (constructorElement == superParam) {
          // Compare the types.
          var superType = superParam.type;
          var argType = constructorElement.type;
          if (!context.typeSystem.isSubtypeOf(argType, superType)) {
            return null;
          }

          match = true;
          var identifier = constructorParam.name?.lexeme;
          if (identifier == null) return null;
          convertibleConstructorParams.add(identifier);
          // Ensure we're not out of order.
          if (i < matchedConstructorParamIndex) return null;
          matchedConstructorParamIndex = i;
        }
      }
    }

    return convertibleConstructorParams;
  }

  /// Return `true` if the named [parameter] can be converted into a super
  /// initializing formal parameter.
  bool _checkNamedParameter(
    FormalParameter parameter,
    FormalParameterElement parameterElement,
    ConstructorElement superConstructor,
    SuperConstructorInvocation superInvocation,
  ) {
    var superParameter = _correspondingNamedParameter(
      superConstructor,
      parameterElement,
    );
    if (superParameter == null) return false;

    bool matchingArgument = false;
    var arguments = superInvocation.argumentList.arguments;
    for (var argument in arguments) {
      if (argument is NamedExpression &&
          argument.name.label.name == parameterElement.name) {
        var expression = argument.expression;
        if (expression is SimpleIdentifier &&
            expression.element == parameterElement) {
          matchingArgument = true;
          break;
        }
      }
    }
    if (!matchingArgument) {
      // If the parameter isn't being passed to the super constructor, then
      // don't lint.
      return false;
    }

    // Compare the types.
    var superType = superParameter.type;
    var thisType = parameterElement.type;
    if (!context.typeSystem.isAssignableTo(superType, thisType)) {
      // If the type of the parameter can't be assigned to the super parameter,
      // then don't lint.
      return false;
    }

    return true;
  }

  FormalParameterElement? _correspondingNamedParameter(
    ConstructorElement superConstructor,
    FormalParameterElement thisParameter,
  ) {
    for (var superParameter in superConstructor.formalParameters) {
      if (superParameter.isNamed && superParameter.name == thisParameter.name) {
        return superParameter;
      }
    }
    return null;
  }
}
