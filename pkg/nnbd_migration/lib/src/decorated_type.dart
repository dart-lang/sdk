// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' show SourceEdit;
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/potential_modification.dart';

/// Representation of a type in the code to be migrated.  In addition to
/// tracking the (unmigrated) [DartType], we track the [ConstraintVariable]s
/// indicating whether the type, and the types that compose it, are nullable.
class DecoratedType {
  final DartType type;

  final NullabilityNode node;

  /// If `this` is a function type, the [DecoratedType] of its return type.
  final DecoratedType returnType;

  /// If `this` is a function type, the [DecoratedType] of each of its
  /// positional parameters (including both required and optional positional
  /// parameters).
  final List<DecoratedType> positionalParameters;

  /// If `this` is a function type, the [DecoratedType] of each of its named
  /// parameters.
  final Map<String, DecoratedType> namedParameters;

  /// If `this` is a parameterized type, the [DecoratedType] of each of its
  /// type parameters.
  ///
  /// TODO(paulberry): how should we handle generic typedefs?
  final List<DecoratedType> typeArguments;

  DecoratedType(this.type, this.node,
      {this.returnType,
      this.positionalParameters = const [],
      this.namedParameters = const {},
      this.typeArguments = const []}) {
    assert(node != null);
  }

  /// Creates a [DecoratedType] corresponding to the given [element], which is
  /// presumed to have come from code that is already migrated.
  factory DecoratedType.forElement(Element element, NullabilityGraph graph) {
    DecoratedType decorate(DartType type) {
      if (type.isVoid || type.isDynamic) {
        return DecoratedType(type, graph.always);
      }
      assert((type as TypeImpl).nullabilitySuffix ==
          NullabilitySuffix.star); // TODO(paulberry)
      if (type is FunctionType) {
        var positionalParameters = <DecoratedType>[];
        var namedParameters = <String, DecoratedType>{};
        for (var parameter in type.parameters) {
          if (parameter.isPositional) {
            positionalParameters.add(decorate(parameter.type));
          } else {
            namedParameters[parameter.name] = decorate(parameter.type);
          }
        }
        return DecoratedType(type, graph.never,
            returnType: decorate(type.returnType),
            namedParameters: namedParameters,
            positionalParameters: positionalParameters);
      } else if (type is InterfaceType) {
        if (type.typeParameters.isNotEmpty) {
          // TODO(paulberry)
          throw UnimplementedError('Decorating ${type.displayName}');
        }
        return DecoratedType(type, graph.never);
      } else if (type is TypeParameterType) {
        return DecoratedType(type, graph.never);
      } else {
        throw type.runtimeType; // TODO(paulberry)
      }
    }

    // Sanity check:
    // Ensure the element is not from a library that is being migrated.
    // If this assertion fires, it probably means that the NodeBuilder failed to
    // generate the appropriate decorated type for the element when it was
    // visiting the source file.
    if (graph.isBeingMigrated(element.source)) {
      throw 'Internal Error: DecorateType.forElement should not be called'
          ' for elements being migrated: ${element.runtimeType} :: $element';
    }

    DecoratedType decoratedType;
    if (element is ExecutableElement) {
      decoratedType = decorate(element.type);
    } else if (element is TopLevelVariableElement) {
      decoratedType = decorate(element.type);
    } else if (element is TypeParameterElement) {
      // By convention, type parameter elements are decorated with the type of
      // their bounds.
      decoratedType = decorate(element.bound ?? DynamicTypeImpl.instance);
    } else {
      // TODO(paulberry)
      throw UnimplementedError('Decorating ${element.runtimeType}');
    }
    return decoratedType;
  }

  /// Creates a decorated type corresponding to [type], with fresh nullability
  /// nodes everywhere that don't correspond to any source location.  These
  /// nodes can later be unioned with other nodes.
  factory DecoratedType.forImplicitFunction(
      FunctionType type, NullabilityNode node, NullabilityGraph graph,
      {DecoratedType returnType}) {
    if (type.typeFormals.isNotEmpty) {
      throw new UnimplementedError('Decorating a generic function type');
    }
    var positionalParameters = <DecoratedType>[];
    var namedParameters = <String, DecoratedType>{};
    for (var parameter in type.parameters) {
      if (parameter.isPositional) {
        positionalParameters
            .add(DecoratedType.forImplicitType(parameter.type, graph));
      } else {
        namedParameters[parameter.name] =
            DecoratedType.forImplicitType(parameter.type, graph);
      }
    }
    return DecoratedType(type, node,
        returnType:
            returnType ?? DecoratedType.forImplicitType(type.returnType, graph),
        namedParameters: namedParameters,
        positionalParameters: positionalParameters);
  }

  /// Creates a DecoratedType corresponding to [type], with fresh nullability
  /// nodes everywhere that don't correspond to any source location.  These
  /// nodes can later be unioned with other nodes.
  factory DecoratedType.forImplicitType(DartType type, NullabilityGraph graph) {
    if (type.isDynamic || type.isVoid) {
      return DecoratedType(type, graph.always);
    } else if (type is InterfaceType) {
      return DecoratedType(type, NullabilityNode.forInferredType(),
          typeArguments: type.typeArguments
              .map((t) => DecoratedType.forImplicitType(t, graph))
              .toList());
    } else if (type is FunctionType) {
      return DecoratedType.forImplicitFunction(
          type, NullabilityNode.forInferredType(), graph);
    } else if (type is TypeParameterType) {
      return DecoratedType(type, NullabilityNode.forInferredType());
    }
    // TODO(paulberry)
    throw UnimplementedError(
        'DecoratedType.forImplicitType(${type.runtimeType})');
  }

  /// If `this` represents an interface type, returns the substitution necessary
  /// to produce this type using the class's type as a starting point.
  /// Otherwise throws an exception.
  ///
  /// For instance, if `this` represents `List<int?1>`, returns the substitution
  /// `{T: int?1}`, where `T` is the [TypeParameterElement] for `List`'s type
  /// parameter.
  Map<TypeParameterElement, DecoratedType> get asSubstitution {
    var type = this.type;
    if (type is InterfaceType) {
      return Map<TypeParameterElement, DecoratedType>.fromIterables(
          type.element.typeParameters, typeArguments);
    } else {
      throw StateError(
          'Tried to convert a non-interface type to a substitution');
    }
  }

  /// If this type is a function type, returns its generic formal parameters.
  /// Otherwise returns `null`.
  List<TypeParameterElement> get typeFormals {
    var type = this.type;
    if (type is FunctionType) {
      return type.typeFormals;
    } else {
      return null;
    }
  }

  /// Converts one function type into another by substituting the given
  /// [argumentTypes] for the function's generic parameters.
  DecoratedType instantiate(List<DecoratedType> argumentTypes) {
    var type = this.type as FunctionType;
    var typeFormals = type.typeFormals;
    List<DartType> undecoratedArgumentTypes = [];
    Map<TypeParameterElement, DecoratedType> substitution = {};
    for (int i = 0; i < argumentTypes.length; i++) {
      var argumentType = argumentTypes[i];
      undecoratedArgumentTypes.add(argumentType.type);
      substitution[typeFormals[i]] = argumentType;
    }
    return _substituteFunctionAfterFormals(
        type.instantiate(undecoratedArgumentTypes), substitution);
  }

  /// Apply the given [substitution] to this type.
  ///
  /// [undecoratedResult] is the result of the substitution, as determined by
  /// the normal type system.  If not supplied, it is inferred.
  DecoratedType substitute(
      Map<TypeParameterElement, DecoratedType> substitution,
      [DartType undecoratedResult]) {
    if (substitution.isEmpty) return this;
    if (undecoratedResult == null) {
      List<DartType> argumentTypes = [];
      List<DartType> parameterTypes = [];
      for (var entry in substitution.entries) {
        argumentTypes.add(entry.value.type);
        parameterTypes.add(entry.key.type);
      }
      undecoratedResult = type.substitute2(argumentTypes, parameterTypes);
    }
    return _substitute(substitution, undecoratedResult);
  }

  @override
  String toString() {
    var trailing = node.debugSuffix;
    var type = this.type;
    if (type is TypeParameterType || type is VoidType) {
      return '$type$trailing';
    } else if (type is InterfaceType) {
      var name = type.element.name;
      var args = '';
      if (type.typeArguments.isNotEmpty) {
        args = '<${type.typeArguments.join(', ')}>';
      }
      return '$name$args$trailing';
    } else if (type is FunctionType) {
      String formals = '';
      if (type.typeFormals.isNotEmpty) {
        formals = '<${type.typeFormals.join(', ')}>';
      }
      List<Object> argStrings =
          positionalParameters.map((p) => p.toString()).toList();
      for (var entry in namedParameters.entries) {
        argStrings.add('${entry.key}: ${entry.value}');
      }
      var args = argStrings.join(', ');
      return '$returnType Function$formals($args)$trailing';
    } else if (type is DynamicTypeImpl) {
      return 'dynamic';
    } else {
      throw '$type'; // TODO(paulberry)
    }
  }

  /// Creates a shallow copy of `this`, replacing the nullability node.
  DecoratedType withNode(NullabilityNode node) => DecoratedType(type, node,
      returnType: returnType,
      positionalParameters: positionalParameters,
      namedParameters: namedParameters,
      typeArguments: typeArguments);

  /// Internal implementation of [_substitute], used as a recursion target.
  DecoratedType _substitute(
      Map<TypeParameterElement, DecoratedType> substitution,
      DartType undecoratedResult) {
    var type = this.type;
    if (type is FunctionType && undecoratedResult is FunctionType) {
      assert(type.typeFormals.isEmpty); // TODO(paulberry)
      return _substituteFunctionAfterFormals(undecoratedResult, substitution);
    } else if (type is InterfaceType && undecoratedResult is InterfaceType) {
      List<DecoratedType> newTypeArguments = [];
      for (int i = 0; i < typeArguments.length; i++) {
        newTypeArguments.add(typeArguments[i]
            .substitute(substitution, undecoratedResult.typeArguments[i]));
      }
      return DecoratedType(undecoratedResult, node,
          typeArguments: newTypeArguments);
    } else if (type is TypeParameterType) {
      var inner = substitution[type.element];
      if (inner == null) {
        return this;
      } else {
        return inner
            .withNode(NullabilityNode.forSubstitution(inner.node, node));
      }
    } else if (type is VoidType) {
      return this;
    }
    throw '$type.substitute($substitution)'; // TODO(paulberry)
  }

  /// Performs the logic that is common to substitution and function type
  /// instantiation.  Namely, a decorated type is formed whose undecorated type
  /// is [undecoratedResult], and whose return type, positional parameters, and
  /// named parameters are formed by performing the given [substitution].
  DecoratedType _substituteFunctionAfterFormals(FunctionType undecoratedResult,
      Map<TypeParameterElement, DecoratedType> substitution) {
    var newPositionalParameters = <DecoratedType>[];
    for (int i = 0; i < positionalParameters.length; i++) {
      var numRequiredParameters = undecoratedResult.normalParameterTypes.length;
      var undecoratedParameterType = i < numRequiredParameters
          ? undecoratedResult.normalParameterTypes[i]
          : undecoratedResult.optionalParameterTypes[i - numRequiredParameters];
      newPositionalParameters.add(positionalParameters[i]
          ._substitute(substitution, undecoratedParameterType));
    }
    return DecoratedType(undecoratedResult, node,
        returnType:
            returnType._substitute(substitution, undecoratedResult.returnType),
        positionalParameters: newPositionalParameters);
  }
}

/// A [DecoratedType] based on a type annotation appearing explicitly in the
/// source code.
///
/// This class implements [PotentialModification] because it knows how to update
/// the source code to reflect its nullability.
class DecoratedTypeAnnotation extends DecoratedType
    implements PotentialModification {
  final int _offset;

  DecoratedTypeAnnotation(
      DartType type, NullabilityNode nullabilityNode, this._offset,
      {List<DecoratedType> typeArguments = const [],
      DecoratedType returnType,
      List<DecoratedType> positionalParameters = const [],
      Map<String, DecoratedType> namedParameters = const {}})
      : super(type, nullabilityNode,
            typeArguments: typeArguments,
            returnType: returnType,
            positionalParameters: positionalParameters,
            namedParameters: namedParameters);

  @override
  bool get isEmpty => !node.isNullable;

  @override
  Iterable<SourceEdit> get modifications =>
      isEmpty ? [] : [SourceEdit(_offset, 0, '?')];
}
