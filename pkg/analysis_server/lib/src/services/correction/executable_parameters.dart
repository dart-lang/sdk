// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';

/// [ExecutableElement], its parameters, and operations on them.
class ExecutableParameters {
  final AnalysisSessionHelper sessionHelper;
  final ExecutableElement executable;

  final List<ParameterElement> required = [];
  final List<ParameterElement> optionalPositional = [];
  final List<ParameterElement> named = [];

  factory ExecutableParameters(
      AnalysisSessionHelper sessionHelper, AstNode invocation) {
    Element element;
    // This doesn't handle FunctionExpressionInvocation.
    if (invocation is Annotation) {
      element = invocation.element;
    } else if (invocation is InstanceCreationExpression) {
      element = invocation.constructorName.staticElement;
    } else if (invocation is MethodInvocation) {
      element = invocation.methodName.staticElement;
    } else if (invocation is ConstructorReferenceNode) {
      element = invocation.staticElement;
    }
    if (element is ExecutableElement && !element.isSynthetic) {
      return ExecutableParameters._(sessionHelper, element);
    } else {
      return null;
    }
  }

  ExecutableParameters._(this.sessionHelper, this.executable) {
    for (var parameter in executable.parameters) {
      if (parameter.isRequiredPositional) {
        required.add(parameter);
      } else if (parameter.isOptionalPositional) {
        optionalPositional.add(parameter);
      } else if (parameter.isNamed) {
        named.add(parameter);
      }
    }
  }

  /// Return the path of the file in which the executable is declared.
  String get file => executable.source.fullName;

  /// Return the names of the named parameters.
  List<String> get namedNames {
    return named.map((parameter) => parameter.name).toList();
  }

  /// Return the [FormalParameterList] of the [executable], or `null` if it
  /// can't be found.
  Future<FormalParameterList> getParameterList() async {
    var result = await sessionHelper.getElementDeclaration(executable);
    var targetDeclaration = result.node;
    if (targetDeclaration is ConstructorDeclaration) {
      return targetDeclaration.parameters;
    } else if (targetDeclaration is FunctionDeclaration) {
      var function = targetDeclaration.functionExpression;
      return function.parameters;
    } else if (targetDeclaration is MethodDeclaration) {
      return targetDeclaration.parameters;
    }
    return null;
  }

  /// Return the [FormalParameter] of the [element] in [FormalParameterList],
  /// or `null` if it can't be found.
  Future<FormalParameter> getParameterNode(ParameterElement element) async {
    var result = await sessionHelper.getElementDeclaration(element);
    var declaration = result.node;
    for (var node = declaration; node != null; node = node.parent) {
      if (node is FormalParameter && node.parent is FormalParameterList) {
        return node;
      }
    }
    return null;
  }
}
