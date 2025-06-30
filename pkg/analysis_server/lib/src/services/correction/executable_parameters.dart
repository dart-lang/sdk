// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';

/// [ExecutableElement], its parameters, and operations on them.
class ExecutableParameters {
  final AnalysisSessionHelper sessionHelper;
  final ExecutableElement executable;
  final ExecutableFragment firstFragment;

  final List<FormalParameterElement> required = [];
  final List<FormalParameterElement> optionalPositional = [];
  final List<FormalParameterElement> named = [];

  ExecutableParameters._(
    this.sessionHelper,
    this.executable,
    this.firstFragment,
  ) {
    for (var parameter in executable.formalParameters) {
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
  String get file => firstFragment.libraryFragment.source.fullName;

  /// Return the names of the named parameters.
  List<String> get namedNames {
    return named.map((parameter) => parameter.name3).nonNulls.toList();
  }

  /// Return the [FormalParameterList] of the [executable], or `null` if it
  /// can't be found.
  Future<FormalParameterList?> getParameterList() async {
    var result = await sessionHelper.getFragmentDeclaration(firstFragment);
    var targetDeclaration = result?.node;
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

  /// Return the [FormalParameter] of the [fragment] in [FormalParameterList],
  /// or `null` if it can't be found.
  Future<FormalParameter?> getParameterNode(
    FormalParameterFragment fragment,
  ) async {
    var result = await sessionHelper.getFragmentDeclaration(fragment);
    var declaration = result?.node;
    for (var node = declaration; node != null; node = node.parent) {
      if (node is FormalParameter && node.parent is FormalParameterList) {
        return node;
      }
    }
    return null;
  }

  static ExecutableParameters? forInvocation(
    AnalysisSessionHelper sessionHelper,
    AstNode? invocation,
  ) {
    Element? element;
    // This doesn't handle FunctionExpressionInvocation.
    if (invocation is Annotation) {
      element = invocation.element;
    } else if (invocation is InstanceCreationExpression) {
      element = invocation.constructorName.element;
    } else if (invocation is MethodInvocation) {
      element = invocation.methodName.element;
    } else if (invocation is ConstructorReferenceNode) {
      element = invocation.element;
    }
    var firstFragment = element?.firstFragment;
    if (element is ExecutableElement &&
        !element.isSynthetic &&
        firstFragment is ExecutableFragment) {
      return ExecutableParameters._(sessionHelper, element, firstFragment);
    } else {
      return null;
    }
  }
}
