// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' show SourceEdit;
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/potential_modification.dart';

/// Representation of a type in the code to be migrated.  In addition to
/// tracking the (unmigrated) [DartType], we track the [ConstraintVariable]s
/// indicating whether the type, and the types that compose it, are nullable.
class DecoratedType {
  /// Mapping from type parameter elements to the decorated types of those type
  /// parameters' bounds.
  ///
  /// This expando only applies to type parameters whose enclosing element is
  /// `null`.  Type parameters whose enclosing element is not `null` should be
  /// stored in [Variables._decoratedTypeParameterBounds].
  static final _decoratedTypeParameterBounds = Expando<DecoratedType>();

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

  /// If `this` is a function type, the [DecoratedType] of each of the bounds of
  /// its type parameters.
  final List<DecoratedType> typeFormalBounds;

  DecoratedType(this.type, this.node,
      {this.returnType,
      this.positionalParameters = const [],
      this.namedParameters = const {},
      this.typeArguments = const [],
      this.typeFormalBounds = const []}) {
    assert(() {
      assert(node != null);
      var type = this.type;
      if (type is InterfaceType) {
        assert(returnType == null);
        assert(positionalParameters.isEmpty);
        assert(namedParameters.isEmpty);
        assert(typeFormalBounds.isEmpty);
        assert(typeArguments.length == type.typeArguments.length);
        for (int i = 0; i < typeArguments.length; i++) {
          assert(typeArguments[i].type == type.typeArguments[i]);
        }
      } else if (type is FunctionType) {
        assert(typeFormalBounds.length == type.typeFormals.length);
        for (int i = 0; i < typeFormalBounds.length; i++) {
          var declaredBound = type.typeFormals[i].bound;
          if (declaredBound == null) {
            assert(typeFormalBounds[i].type.isDartCoreObject);
          } else {
            assert(typeFormalBounds[i].type == declaredBound);
          }
        }
        assert(returnType.type == type.returnType);
        int positionalParameterCount = 0;
        int namedParameterCount = 0;
        for (var parameter in type.parameters) {
          if (parameter.isNamed) {
            assert(namedParameters[parameter.name].type == parameter.type);
            namedParameterCount++;
          } else {
            assert(positionalParameters[positionalParameterCount].type ==
                parameter.type);
            positionalParameterCount++;
          }
        }
        assert(positionalParameters.length == positionalParameterCount);
        assert(namedParameters.length == namedParameterCount);
        assert(typeArguments.isEmpty);
      } else if (node is TypeParameterType) {
        assert(returnType == null);
        assert(positionalParameters.isEmpty);
        assert(namedParameters.isEmpty);
        assert(typeArguments.isEmpty);
        assert(typeFormalBounds.isEmpty);
      } else {
        assert(returnType == null);
        assert(positionalParameters.isEmpty);
        assert(namedParameters.isEmpty);
        assert(typeArguments.isEmpty);
        assert(typeFormalBounds.isEmpty);
      }
      return true;
    }());
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

  /// Creates a [DecoratedType] for a synthetic type parameter, to be used
  /// during comparison of generic function types.
  DecoratedType._forTypeParameterSubstitution(
      TypeParameterElementImpl parameter)
      : type = TypeParameterTypeImpl(parameter),
        node = null,
        returnType = null,
        positionalParameters = const [],
        namedParameters = const {},
        typeArguments = const [],
        typeFormalBounds = const [] {
    // We'll be storing the type parameter bounds in
    // [_decoratedTypeParameterBounds] so the type parameter needs to have an
    // enclosing element of `null`.
    assert(parameter.enclosingElement == null);
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

  @override
  bool operator ==(Object other) {
    if (other is DecoratedType) {
      if (!identical(this.node, other.node)) return false;
      var thisType = this.type;
      var otherType = other.type;
      if (thisType is FunctionType && otherType is FunctionType) {
        if (thisType.normalParameterTypes.length !=
            otherType.normalParameterTypes.length) {
          return false;
        }
        if (thisType.typeFormals.length != otherType.typeFormals.length) {
          return false;
        }
        var thisReturnType = this.returnType;
        var otherReturnType = other.returnType;
        var thisPositionalParameters = this.positionalParameters;
        var otherPositionalParameters = other.positionalParameters;
        var thisNamedParameters = this.namedParameters;
        var otherNamedParameters = other.namedParameters;
        if (!_compareTypeFormalLists(
            thisType.typeFormals, otherType.typeFormals)) {
          // Create a fresh set of type variables and substitute so we can
          // compare safely.
          var thisSubstitution = <TypeParameterElement, DecoratedType>{};
          var otherSubstitution = <TypeParameterElement, DecoratedType>{};
          var newParameters = <TypeParameterElement>[];
          for (int i = 0; i < thisType.typeFormals.length; i++) {
            var newParameter = TypeParameterElementImpl.synthetic(
                thisType.typeFormals[i].name);
            newParameters.add(newParameter);
            var newParameterType =
                DecoratedType._forTypeParameterSubstitution(newParameter);
            thisSubstitution[thisType.typeFormals[i]] = newParameterType;
            otherSubstitution[otherType.typeFormals[i]] = newParameterType;
          }
          for (int i = 0; i < thisType.typeFormals.length; i++) {
            var thisBound =
                this.typeFormalBounds[i].substitute(thisSubstitution);
            var otherBound =
                other.typeFormalBounds[i].substitute(otherSubstitution);
            if (thisBound != otherBound) return false;
            recordTypeParameterBound(newParameters[i], thisBound);
          }
          // TODO(paulberry): need to substitute bounds and compare them.
          thisReturnType = thisReturnType.substitute(thisSubstitution);
          otherReturnType = otherReturnType.substitute(otherSubstitution);
          thisPositionalParameters =
              _substituteList(thisPositionalParameters, thisSubstitution);
          otherPositionalParameters =
              _substituteList(otherPositionalParameters, otherSubstitution);
          thisNamedParameters =
              _substituteMap(thisNamedParameters, thisSubstitution);
          otherNamedParameters =
              _substituteMap(otherNamedParameters, otherSubstitution);
        }
        if (thisReturnType != otherReturnType) return false;
        if (!_compareLists(
            thisPositionalParameters, otherPositionalParameters)) {
          return false;
        }
        if (!_compareMaps(thisNamedParameters, otherNamedParameters)) {
          return false;
        }
        return true;
      } else if (thisType is InterfaceType && otherType is InterfaceType) {
        if (thisType.element != otherType.element) return false;
        if (!_compareLists(this.typeArguments, other.typeArguments)) {
          return false;
        }
        return true;
      } else {
        return thisType == otherType;
      }
    }
    return false;
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
        args = '<${typeArguments.join(', ')}>';
      }
      return '$name$args$trailing';
    } else if (type is FunctionType) {
      String formals = '';
      if (type.typeFormals.isNotEmpty) {
        formals = '<${type.typeFormals.join(', ')}>';
      }
      List<String> paramStrings = [];
      for (int i = 0; i < positionalParameters.length; i++) {
        var prefix = '';
        if (i == type.normalParameterTypes.length) {
          prefix = '[';
        }
        paramStrings.add('$prefix${positionalParameters[i]}');
      }
      if (type.normalParameterTypes.length < positionalParameters.length) {
        paramStrings.last += ']';
      }
      if (namedParameters.isNotEmpty) {
        var prefix = '{';
        for (var entry in namedParameters.entries) {
          paramStrings.add('$prefix${entry.key}: ${entry.value}');
          prefix = '';
        }
        paramStrings.last += '}';
      }
      var args = paramStrings.join(', ');
      return '$returnType Function$formals($args)$trailing';
    } else if (type is DynamicTypeImpl) {
      return 'dynamic';
    } else if (type.isBottom) {
      return 'Never$trailing';
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

  List<DecoratedType> _substituteList(List<DecoratedType> list,
      Map<TypeParameterElement, DecoratedType> substitution) {
    return list.map((t) => t.substitute(substitution)).toList();
  }

  Map<String, DecoratedType> _substituteMap(Map<String, DecoratedType> map,
      Map<TypeParameterElement, DecoratedType> substitution) {
    var result = <String, DecoratedType>{};
    for (var entry in map.entries) {
      result[entry.key] = entry.value.substitute(substitution);
    }
    return result;
  }

  /// Retrieves the decorated bound of the given [typeParameter].
  ///
  /// [typeParameter] must have an enclosing element of `null`.  Type parameters
  /// whose enclosing element is not `null` are tracked by the [Variables]
  /// class.
  static DecoratedType decoratedTypeParameterBound(
      TypeParameterElement typeParameter) {
    assert(typeParameter.enclosingElement == null);
    return _decoratedTypeParameterBounds[typeParameter];
  }

  /// Stores he decorated bound of the given [typeParameter].
  ///
  /// [typeParameter] must have an enclosing element of `null`.  Type parameters
  /// whose enclosing element is not `null` are tracked by the [Variables]
  /// class.
  static void recordTypeParameterBound(
      TypeParameterElement typeParameter, DecoratedType bound) {
    assert(typeParameter.enclosingElement == null);
    _decoratedTypeParameterBounds[typeParameter] = bound;
  }

  static bool _compareLists(
      List<DecoratedType> list1, List<DecoratedType> list2) {
    if (identical(list1, list2)) return true;
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  static bool _compareMaps(
      Map<String, DecoratedType> map1, Map<String, DecoratedType> map2) {
    if (identical(map1, map2)) return true;
    if (map1.length != map2.length) return false;
    for (var entry in map1.entries) {
      if (entry.value != map2[entry.key]) return false;
    }
    return true;
  }

  static bool _compareTypeFormalLists(List<TypeParameterElement> formals1,
      List<TypeParameterElement> formals2) {
    if (identical(formals1, formals2)) return true;
    if (formals1.length != formals2.length) return false;
    for (int i = 0; i < formals1.length; i++) {
      if (!identical(formals1[i], formals2[i])) return false;
    }
    return true;
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
