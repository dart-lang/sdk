// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// A contributor that produces suggestions for super formal parameters that
/// are based on the parameters declared by the invoked super-constructor.
/// The enclosing declaration is expected to be a constructor.
class SuperFormalContributor extends DartCompletionContributor {
  SuperFormalContributor(super.request, super.builder);

  @override
  Future<void> computeSuggestions({
    required OperationPerformanceImpl performance,
  }) async {
    var node = request.target.containingNode;
    if (node is! SuperFormalParameter) {
      return;
    }

    var element = node.declaredElement as SuperFormalParameterElementImpl;

    var constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) {
      return;
    }

    var constructorElement = constructor.declaredElement;
    constructorElement as ConstructorElementImpl;

    var superConstructor = constructorElement.superConstructor;
    if (superConstructor == null) {
      return;
    }

    if (node.isNamed) {
      var superConstructorInvocation = constructor.initializers
          .whereType<SuperConstructorInvocation>()
          .singleOrNull;
      var specified = <String>{
        ...constructorElement.parameters.map((e) => e.name),
        ...?superConstructorInvocation?.argumentList.arguments
            .whereType<NamedExpression>()
            .map((e) => e.name.label.name),
      };
      for (var superParameter in superConstructor.parameters) {
        if (superParameter.isNamed &&
            !specified.contains(superParameter.name)) {
          builder.suggestSuperFormalParameter(superParameter);
        }
      }
    }

    if (node.isPositional) {
      var indexOfThis = element.indexIn(constructorElement);
      var superPositionalList = superConstructor.parameters
          .where((parameter) => parameter.isPositional)
          .toList();
      if (indexOfThis >= 0 && indexOfThis < superPositionalList.length) {
        var superPositional = superPositionalList[indexOfThis];
        builder.suggestSuperFormalParameter(superPositional);
      }
    }
  }
}
