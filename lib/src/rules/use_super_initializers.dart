// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/utilities/extensions/string.dart'; // ignore: implementation_imports

import '../analyzer.dart';

const _desc = r'Use super-initializer parameters where possible.';

const _details = r'''
"Forwarding constructor"s, that do nothing except forward parameters to their 
superclass constructors should take advantage of super-initializer parameters 
rather than repeating the names of parameters when passing them to the 
superclass constructors.  This makes the code more concise and easier to read
and maintain.

**DO** use super-initializer parameters where possible.

**BAD:**
```dart
class A {
  A({int? x, int? y});
}
class B extends A {
  B({int? x, int? y}) : super(x: x, y: y);
}
```

**GOOD:**
```dart
class A {
  A({int? x, int? y});
}
class B extends A {
  B({super.x, super.y});
}
```
''';

class UseSuperInitializers extends LintRule {
  static const LintCode singleParam =
      LintCode('use_super_initializers', "Convert '{0}' to a super parameter.");
  static const LintCode multipleParams =
      LintCode('use_super_initializers', 'Convert {0} to super parameters.');

  UseSuperInitializers()
      : super(
            name: 'use_super_initializers',
            description: _desc,
            details: _details,
            maturity: Maturity.experimental,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!context.isEnabled(Feature.super_parameters)) return;

    var visitor = _Visitor(this, context);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LinterContext context;
  final LintRule rule;

  _Visitor(this.rule, this.context);

  void check(SuperConstructorInvocation superInvocation,
      FormalParameterList parameters) {
    var constructorElement = superInvocation.staticElement;
    if (constructorElement == null) return;

    // todo(pq): consolidate logic shared w/ server
    //  (https://github.com/dart-lang/linter/issues/3263)

    // Bail if there are positional params that can't be converted.
    if (!_checkForConvertiblePositionalParams(
        constructorElement, superInvocation, parameters)) {
      return;
    }

    for (var parameter in parameters.parameters) {
      var parameterElement = parameter.declaredElement;
      if (parameterElement == null) continue;
      if (parameterElement.isNamed) {
        if (_checkNamedParameter(
            parameter, parameterElement, constructorElement, superInvocation)) {
          _reportOnIdentifier(parameter.identifier);
        }
      }
    }
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    for (var initializer in node.initializers.reversed) {
      if (initializer is SuperConstructorInvocation) {
        check(initializer, node.parameters);
        return;
      }
    }
  }

  /// Check if all super positional parameters can be converted to use super-
  /// initializers. Return `false` if there are parameters that can't be
  /// converted since this will short-circuit the lint.
  bool _checkForConvertiblePositionalParams(
      ConstructorElement constructorElement,
      SuperConstructorInvocation superInvocation,
      FormalParameterList parameters) {
    var positionalSuperArgs = <SimpleIdentifier>[];
    for (var arg in superInvocation.argumentList.arguments) {
      if (arg is SimpleIdentifier) {
        positionalSuperArgs.add(arg);
      } else if (arg is! NamedExpression) {
        return false;
      }
    }

    if (positionalSuperArgs.isEmpty) return true;

    var constructorParams = parameters.parameters;
    var convertibleConstructorParams = <FormalParameter>[];
    var matchedConstructorParamIndex = 0;

    // For each super arg, ensure there is a constructor param (in the right
    // order).
    for (var i = 0; i < positionalSuperArgs.length; ++i) {
      var superArg = positionalSuperArgs[i];
      var superParam = superArg.staticElement;
      if (superParam is! ParameterElement) return false;
      bool match = false;
      for (var i = 0; i < constructorParams.length && !match; ++i) {
        var constructorParam = constructorParams[i];
        var constructorElement = constructorParam.declaredElement;
        if (constructorElement == null) continue;
        if (constructorElement == superParam) {
          // Compare the types.
          var superType = superParam.type;
          var argType = constructorElement.type;
          if (!context.typeSystem.isSubtypeOf(argType, superType)) {
            return false;
          }

          match = true;
          convertibleConstructorParams.add(constructorParam);
          // Ensure we're not out of order.
          if (i < matchedConstructorParamIndex) return false;
          matchedConstructorParamIndex = i;
        }
      }
    }
    _reportOnFirstParam(convertibleConstructorParams);

    return true;
  }

  /// Return `true` if the named [parameter] can be converted into a super
  /// initializing formal parameter.
  bool _checkNamedParameter(
      FormalParameter parameter,
      ParameterElement parameterElement,
      ConstructorElement superConstructor,
      SuperConstructorInvocation superInvocation) {
    var superParameter =
        _correspondingNamedParameter(superConstructor, parameterElement);
    if (superParameter == null) return false;

    bool matchingArgument = false;
    var arguments = superInvocation.argumentList.arguments;
    for (var argument in arguments) {
      if (argument is NamedExpression &&
          argument.name.label.name == parameterElement.name) {
        var expression = argument.expression;
        if (expression is SimpleIdentifier &&
            expression.staticElement == parameterElement) {
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

  ParameterElement? _correspondingNamedParameter(
      ConstructorElement superConstructor, ParameterElement thisParameter) {
    for (var superParameter in superConstructor.parameters) {
      if (superParameter.isNamed && superParameter.name == thisParameter.name) {
        return superParameter;
      }
    }
    return null;
  }

  void _reportOnFirstParam(List<FormalParameter> params) {
    var firstIdentifier = params.first.identifier;
    if (firstIdentifier == null) return;

    if (params.length == 1) {
      _reportOnIdentifier(firstIdentifier);
    } else {
      var identifiers = <String>[];
      for (var param in params) {
        var name = param.identifier?.name;
        if (name == null) return; // Bail.
        identifiers.add(name);
      }
      var msg = identifiers.quotedAndCommaSeparatedWithAnd;
      rule.reportLint(firstIdentifier,
          errorCode: UseSuperInitializers.multipleParams, arguments: [msg]);
    }
  }

  void _reportOnIdentifier(SimpleIdentifier? identifier) {
    if (identifier == null) return;
    rule.reportLint(identifier,
        errorCode: UseSuperInitializers.singleParam,
        arguments: [identifier.name]);
  }
}
