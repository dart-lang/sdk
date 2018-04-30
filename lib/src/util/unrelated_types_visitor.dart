// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

_InterfaceTypePredicate _buildImplementsDefinitionPredicate(
        InterfaceTypeDefinition definition) =>
    (InterfaceType interface) =>
        interface.name == definition.name &&
        interface.element.library.name == definition.library;

List<InterfaceType> _findImplementedInterfaces(InterfaceType type,
        {List<InterfaceType> acc: const []}) =>
    acc.contains(type)
        ? acc
        : type.interfaces.fold(
            <InterfaceType>[type],
            (List<InterfaceType> acc, InterfaceType e) => new List.from(acc)
              ..addAll(_findImplementedInterfaces(e, acc: acc)));

DartType _findIterableTypeArgument(
    InterfaceTypeDefinition definition, InterfaceType type,
    {List<InterfaceType> accumulator: const []}) {
  if (type == null ||
      type.isObject ||
      type.isDynamic ||
      accumulator.contains(type)) {
    return null;
  }

  _InterfaceTypePredicate predicate =
      _buildImplementsDefinitionPredicate(definition);
  if (predicate(type)) {
    return type.typeArguments.first;
  }

  List<InterfaceType> implementedInterfaces = _findImplementedInterfaces(type);
  InterfaceType interface =
      implementedInterfaces.firstWhere(predicate, orElse: () => null);
  if (interface != null && interface.typeArguments.isNotEmpty) {
    return interface.typeArguments.first;
  }

  return _findIterableTypeArgument(definition, type.superclass,
      accumulator: [type]..addAll(accumulator)..addAll(implementedInterfaces));
}

bool _isParameterizedMethodInvocation(
        String methodName, MethodInvocation node) =>
    node.methodName.name == methodName &&
    node.argumentList.arguments.length == 1;

typedef bool _InterfaceTypePredicate(InterfaceType type);

/// Base class for visitor used in rules where we want to lint about invoking
/// methods on generic classes where the parameter is unrelated to the parameter
/// type of the class. Extending this visitor is as simple as knowing the method,
/// class and library that uniquely define the target, i.e. implement only
/// [definition] and [methodName].
abstract class UnrelatedTypesProcessors extends SimpleAstVisitor<void> {
  final LintRule rule;

  UnrelatedTypesProcessors(this.rule);

  InterfaceTypeDefinition get definition;

  String get methodName;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isParameterizedMethodInvocation(methodName, node)) {
      return;
    }

    DartType type;
    if (node.target != null) {
      type = node.target.bestType;
    } else {
      var classDeclaration =
          (node.getAncestor((a) => a is ClassDeclaration) as ClassDeclaration);
      type = classDeclaration == null
          ? null
          : resolutionMap
              .elementDeclaredByClassDeclaration(classDeclaration)
              ?.type;
    }
    Expression argument = node.argumentList.arguments.first;
    if (type is InterfaceType &&
        DartTypeUtilities.unrelatedTypes(
            argument.bestType, _findIterableTypeArgument(definition, type))) {
      rule.reportLint(node);
    }
  }
}
