// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

typedef _InterfaceTypePredicate = bool Function(InterfaceType type);

/// Returns a predicate which returns whether a given [InterfaceTypeDefinition]
/// is equal to [definition].
_InterfaceTypePredicate _buildImplementsDefinitionPredicate(
        InterfaceTypeDefinition definition) =>
    (InterfaceType interface) =>
        interface.element.name == definition.name &&
        interface.element.library.name == definition.library;

/// Returns all implemented interfaces of [type].
///
/// This flattens all of the super-interfaces of [type] into one list.
List<InterfaceType> _findImplementedInterfaces(InterfaceType type,
        {List<InterfaceType> accumulator = const []}) =>
    accumulator.contains(type)
        ? accumulator
        : type.interfaces.fold(
            <InterfaceType>[type],
            (List<InterfaceType> acc, InterfaceType e) => List.from(acc)
              ..addAll(_findImplementedInterfaces(e, accumulator: acc)));

/// Returns the first type argument on [definition], as implemented by [type].
///
/// In the simplest case, [type] is the same class as [definition]. For
/// example, given the definition `List<E>` and the type `List<int>`,
/// this function returns the DartType for `int`.
///
/// In a more complicated case, we must traverse [type]'s interfaces to find
/// [definition]. For example, given the definition `Set<E>` and the type `A`
/// where `A implements B<List, String>` and `B<E, F> implements Set<F>, C<E>`,
/// this function returns the DartType for `String`.
DartType _findIterableTypeArgument(
    InterfaceTypeDefinition definition, InterfaceType type,
    {List<InterfaceType> accumulator = const []}) {
  if (type == null ||
      type.isObject ||
      type.isDynamic ||
      accumulator.contains(type)) {
    return null;
  }

  final predicate = _buildImplementsDefinitionPredicate(definition);
  if (predicate(type)) {
    return type.typeArguments.first;
  }

  final implementedInterfaces = _findImplementedInterfaces(type);
  final interface =
      implementedInterfaces.firstWhere(predicate, orElse: () => null);
  if (interface != null && interface.typeArguments.isNotEmpty) {
    return interface.typeArguments.first;
  }

  return _findIterableTypeArgument(definition, type.superclass,
      accumulator: [type, ...accumulator, ...implementedInterfaces]);
}

bool _isParameterizedMethodInvocation(
        String methodName, MethodInvocation node) =>
    node.methodName.name == methodName &&
    node.argumentList.arguments.length == 1;

/// Base class for visitor used in rules where we want to lint about invoking
/// methods on generic classes where the type of the singular argument is
/// unrelated to the singular type argument of the class. Extending this
/// visitor is as simple as knowing the method, class and library that uniquely
/// define the target, i.e. implement only [definition] and [methodName].
abstract class UnrelatedTypesProcessors extends SimpleAstVisitor<void> {
  final LintRule rule;
  final TypeSystem typeSystem;

  UnrelatedTypesProcessors(this.rule, this.typeSystem);

  /// The type definition which this [UnrelatedTypesProcessors] is concerned
  /// with.
  InterfaceTypeDefinition get definition;

  /// The name of the method which this [UnrelatedTypesProcessors] is concerned
  /// with.
  String get methodName;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isParameterizedMethodInvocation(methodName, node)) {
      return;
    }

    // At this point, we know that [node] is an invocation of a method which
    // has the same name as the method that this UnrelatedTypesProcessors] is
    // concerned with, and that the method has a single parameter.
    //
    // We've completed the "cheap" checks, and must now continue with the
    // arduous task of determining whether the method target implements
    // [definition].

    DartType targetType;
    if (node.target != null) {
      targetType = node.target.staticType;
    } else {
      final classDeclaration =
          node.thisOrAncestorOfType<ClassOrMixinDeclaration>();
      if (classDeclaration == null) {
        targetType = null;
      } else if (classDeclaration is ClassDeclaration) {
        targetType = classDeclaration.declaredElement?.thisType;
      } else if (classDeclaration is MixinDeclaration) {
        targetType = classDeclaration.declaredElement?.thisType;
      }
    }
    final argument = node.argumentList.arguments.first;

    // Finally, determine whether the type of the argument is related to the
    // type of the method target.
    if (targetType is InterfaceType &&
        DartTypeUtilities.unrelatedTypes(typeSystem, argument.staticType,
            _findIterableTypeArgument(definition, targetType))) {
      rule.reportLint(node);
    }
  }
}
