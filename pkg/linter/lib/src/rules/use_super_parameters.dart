// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/utilities/extensions/string.dart'; // ignore: implementation_imports

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Use super-initializer parameters where possible.';

/// Return a set containing the elements of all of the parameters that are
/// referenced in the body of the [constructor].
Set<FormalParameterElement> _referencedParameters(
    ConstructorDeclaration constructor) {
  var collector = _ReferencedParameterCollector();
  constructor.body.accept(collector);
  return collector.foundParameters;
}

class UseSuperParameters extends LintRule {
  UseSuperParameters()
      : super(
          name: LintNames.use_super_parameters,
          description: _desc,
          state: State.experimental(),
        );

  @override
  List<LintCode> get lintCodes => [
        LinterLintCode.use_super_parameters_multiple,
        LinterLintCode.use_super_parameters_single
      ];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!context.isEnabled(Feature.super_parameters)) return;

    var visitor = _Visitor(this, context);
    registry.addConstructorDeclaration(this, visitor);
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
  final LinterContext context;
  final LintRule rule;

  _Visitor(this.rule, this.context);

  void check(
      ConstructorDeclaration node,
      SuperConstructorInvocation superInvocation,
      FormalParameterList parameters) {
    var constructorElement = superInvocation.element;
    if (constructorElement == null) return;

    // TODO(pq): consolidate logic shared w/ server
    //  (https://github.com/dart-lang/linter/issues/3263)

    var referencedParameters = _referencedParameters(node);

    var identifiers = _checkForConvertiblePositionalParams(
        constructorElement, superInvocation, parameters, referencedParameters);

    // Bail if there are positional params that can't be converted.
    if (identifiers == null) return;

    for (var parameter in parameters.parameters) {
      var parameterElement = parameter.declaredFragment?.element;
      if (parameterElement == null) continue;
      if (parameterElement is FieldFormalParameterElement2) continue;
      if (parameterElement.isNamed &&
          !referencedParameters.contains(parameterElement)) {
        if (_checkNamedParameter(
            parameter, parameterElement, constructorElement, superInvocation)) {
          var identifier = parameter.name?.lexeme;
          if (identifier != null) {
            identifiers.add(identifier);
          }
        }
      }
    }

    _reportLint(node, identifiers);
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    for (var initializer in node.initializers.reversed) {
      if (initializer is SuperConstructorInvocation) {
        check(node, initializer, node.parameters);
        return;
      }
    }
  }

  /// Check if all super positional parameters can be converted to use super-
  /// initializers. Return a list of convertible named parameters or `null` if
  /// there are parameters that can't be converted since this will short-circuit
  /// the lint.
  List<String>? _checkForConvertiblePositionalParams(
      ConstructorElement2 constructorElement,
      SuperConstructorInvocation superInvocation,
      FormalParameterList parameters,
      Set<FormalParameterElement> referencedParameters) {
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

    var seenSuperParams = <Element2>{};

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
      ConstructorElement2 superConstructor,
      SuperConstructorInvocation superInvocation) {
    var superParameter =
        _correspondingNamedParameter(superConstructor, parameterElement);
    if (superParameter == null) return false;

    bool matchingArgument = false;
    var arguments = superInvocation.argumentList.arguments;
    for (var argument in arguments) {
      if (argument is NamedExpression &&
          argument.name.label.name == parameterElement.name3) {
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
      ConstructorElement2 superConstructor,
      FormalParameterElement thisParameter) {
    for (var superParameter in superConstructor.formalParameters) {
      if (superParameter.isNamed &&
          superParameter.name3 == thisParameter.name3) {
        return superParameter;
      }
    }
    return null;
  }

  void _reportLint(ConstructorDeclaration node, List<String> identifiers) {
    if (identifiers.isEmpty) return;
    var target = node.name ?? node.returnType;
    if (identifiers.length > 1) {
      var msg = identifiers.quotedAndCommaSeparatedWithAnd;
      rule.reportLintForOffset(target.offset, target.length,
          errorCode: LinterLintCode.use_super_parameters_multiple,
          arguments: [msg]);
    } else {
      rule.reportLintForOffset(target.offset, target.length,
          errorCode: LinterLintCode.use_super_parameters_single,
          arguments: [identifiers.first]);
    }
  }
}
