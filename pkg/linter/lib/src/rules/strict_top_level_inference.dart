// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/element.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Specify type annotations.';

class StrictTopLevelInference extends LintRule {
  StrictTopLevelInference()
    : super(name: LintNames.strict_top_level_inference, description: _desc);

  @override
  List<LintCode> get lintCodes => [
    LinterLintCode.strict_top_level_inference_add_type,
    LinterLintCode.strict_top_level_inference_replace_keyword,
    LinterLintCode.strict_top_level_inference_split_to_types,
  ];

  @override
  void registerNodeProcessors(
    NodeLintRegistry registry,
    LinterContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addVariableDeclarationList(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final bool _wildCardVariablesEnabled;

  final LintRule rule;

  final LinterContext context;

  _Visitor(this.rule, this.context)
    : _wildCardVariablesEnabled = context.isEnabled(Feature.wildcard_variables);

  bool isWildcardIdentifier(String lexeme) =>
      _wildCardVariablesEnabled && lexeme == '_';

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _checkFormalParameters(node.parameters.parameters);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is! CompilationUnit) return;
    if (node.returnType == null && !node.isSetter) {
      _report(node.name);
    }

    if (node.functionExpression.parameters case var parameters?) {
      _checkFormalParameters(parameters.parameters);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var fragment = node.declaredFragment;
    if (fragment is PropertyAccessorFragment) {
      var element = fragment.element;
      if (node.isGetter) {
        _checkGetter(node, element);
      } else {
        _checkSetter(node, element);
      }
    } else if (fragment is MethodElementImpl) {
      _checkMethod(node, fragment);
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.type != null) return;
    if (node.parent is! TopLevelVariableDeclaration &&
        node.parent is! FieldDeclaration) {
      return;
    }
    var variablesMissingAnInitializer =
        node.variables.where((v) => v.initializer == null).toList();

    if (variablesMissingAnInitializer.isEmpty) return;

    // At this point, we know that a type was not specified for the declaration
    // list, and at least one of the variables declared does not have an
    // initializer.

    if (node.variables.length == 1) {
      var variable = node.variables.single;
      var overriddenMember = context.inheritanceManager.overriddenMember(
        variable.declaredFragment?.element,
      );
      if (overriddenMember == null) {
        _report(variable.name, keyword: node.keyword);
      }
    } else {
      // Handle the multiple-variable case separately so that we can instead
      // report `LinterLintCode.strict_top_level_inference_split_to_types`.
      for (var variable in variablesMissingAnInitializer) {
        var overriddenMember = context.inheritanceManager.overriddenMember(
          variable.declaredFragment?.element,
        );
        if (overriddenMember == null) {
          rule.reportLintForToken(
            variable.name,
            errorCode: LinterLintCode.strict_top_level_inference_split_to_types,
          );
        }
      }
    }
  }

  void _checkFormalParameters(
    List<FormalParameter> parameters, {
    ExecutableElement2? overriddenMember,
  }) {
    for (var i = 0; i < parameters.length; i++) {
      var parameter = parameters[i];
      var parameterName = parameter.name;
      if (parameterName != null && isWildcardIdentifier(parameterName.lexeme)) {
        continue;
      }

      if (parameter is DefaultFormalParameter) {
        parameter = parameter.parameter;
      }
      if (parameter is! SimpleFormalParameter) {
        // Every type of parameter other than simple formal parameters get a type
        // one way or another:
        // * Field formal parameters have an explicit type or it is derived from
        //   the field type.
        // * Super formal parameters have an explicit type or it is derived from
        //   the super constructor's corresponding parameter's type.
        // * Function-typed formal parameters have a function type, possibly with
        //   implicit return and parameter types.
        return;
      }

      if (parameter.type != null) return;
      if (overriddenMember == null) {
        _report(parameterName, keyword: parameter.keyword);
      } else {
        if (parameter.isPositional) {
          if (overriddenMember.formalParameters.length <= i ||
              overriddenMember.formalParameters[i].isNamed) {
            // The overridden member does not have a corresponding parameter.
            _report(parameterName, keyword: parameter.keyword);
          }
        } else {
          var overriddenParameter = overriddenMember.formalParameters
              .firstWhereOrNull((p) => p.isNamed);
          if (overriddenParameter == null) {
            // The overridden member does not have a corresponding parameter.
            _report(parameterName, keyword: parameter.keyword);
          }
        }
      }
    }
  }

  void _checkGetter(MethodDeclaration node, PropertyAccessorElement2 element) {
    if (node.returnType != null) return;

    if (!_isOverride(node, element)) {
      rule.reportLintForToken(
        node.name,
        errorCode: LinterLintCode.strict_top_level_inference_add_type,
      );
    }
  }

  void _checkMethod(MethodDeclaration node, MethodElementImpl element) {
    if (element.typeInferenceError != null) {
      // Inferring the return type and/or one or more parameter types resulted
      // in a type inference error. Do not report lint in this case.
      return;
    }

    var container = element.enclosingFragment!.element;
    var noOverride =
        node.isStatic ||
        container is ExtensionElement2 ||
        container is ExtensionTypeElement2;

    if (noOverride) {
      if (node.returnType == null) {
        rule.reportLintForToken(
          node.name,
          errorCode: LinterLintCode.strict_top_level_inference_add_type,
        );
      }
      if (node.parameters case var parameters?) {
        _checkFormalParameters(parameters.parameters);
      }
    } else {
      var overriddenMember = context.inheritanceManager.overriddenMember(
        node.declaredFragment?.element,
      );
      if (overriddenMember == null && node.returnType == null) {
        _report(node.name);
      }
      if (node.parameters case var parameters?) {
        _checkFormalParameters(
          parameters.parameters,
          overriddenMember: overriddenMember,
        );
      }
    }
  }

  void _checkSetter(MethodDeclaration node, PropertyAccessorElement2 element) {
    var parameter = node.parameters?.parameters.firstOrNull;
    if (parameter == null) return;
    if (parameter is! SimpleFormalParameter) return;
    if (parameter.type != null) return;

    if (!_isOverride(node, element)) {
      rule.reportLintForToken(
        node.name,
        errorCode: LinterLintCode.strict_top_level_inference_add_type,
      );
    }
  }

  bool _isOverride(MethodDeclaration node, PropertyAccessorElement2 element) {
    var container = element.enclosingElement2;
    if (node.isStatic) return false;
    if (container is ExtensionElement2) return false;
    if (container is ExtensionTypeElement2) return false;
    var overriddenMember = context.inheritanceManager.overriddenMember(
      node.declaredFragment?.element,
    );
    return overriddenMember != null;
  }

  void _report(Token? errorToken, {Token? keyword}) {
    if (keyword == null || keyword.type == Keyword.FINAL) {
      rule.reportLintForToken(
        errorToken,
        errorCode: LinterLintCode.strict_top_level_inference_add_type,
      );
    } else if (keyword.type == Keyword.VAR) {
      rule.reportLintForToken(
        errorToken,
        arguments: [keyword.lexeme],
        errorCode: LinterLintCode.strict_top_level_inference_replace_keyword,
      );
    }
  }
}
