// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/nullability_node_target.dart';

/// Representation of a type in the code to be migrated.  In addition to
/// tracking the (unmigrated) [DartType], we track the [ConstraintVariable]s
/// indicating whether the type, and the types that compose it, are nullable.
class DecoratedType implements DecoratedTypeInfo {
  @override
  final DartType type;

  @override
  final NullabilityNode node;

  @override
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
    assert(() {
      assert(node != null);
      var type = this.type;
      if (type is InterfaceType) {
        assert(returnType == null);
        assert(positionalParameters.isEmpty);
        assert(namedParameters.isEmpty);
        assert(typeArguments.length == type.typeArguments.length);
        for (int i = 0; i < typeArguments.length; i++) {
          assert(typeArguments[i].type == type.typeArguments[i],
              '${typeArguments[i].type} != ${type.typeArguments[i]}');
        }
      } else if (type is FunctionType) {
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
      } else {
        assert(returnType == null);
        assert(positionalParameters.isEmpty);
        assert(namedParameters.isEmpty);
        assert(typeArguments.isEmpty);
      }
      return true;
    }());
  }

  /// Creates a decorated type corresponding to [type], with fresh nullability
  /// nodes everywhere that don't correspond to any source location.  These
  /// nodes can later be unioned with other nodes.
  factory DecoratedType.forImplicitFunction(
      TypeProvider typeProvider,
      FunctionType type,
      NullabilityNode node,
      NullabilityGraph graph,
      NullabilityNodeTarget target,
      {DecoratedType returnType}) {
    var positionalParameters = <DecoratedType>[];
    var namedParameters = <String, DecoratedType>{};
    int index = 0;
    for (var parameter in type.parameters) {
      if (parameter.isPositional) {
        positionalParameters.add(DecoratedType.forImplicitType(typeProvider,
            parameter.type, graph, target.positionalParameter(index++)));
      } else {
        var name = parameter.name;
        namedParameters[name] = DecoratedType.forImplicitType(
            typeProvider, parameter.type, graph, target.namedParameter(name));
      }
    }
    for (var element in type.typeFormals) {
      if (DecoratedTypeParameterBounds.current.get(element) == null) {
        DecoratedTypeParameterBounds.current.put(
            element,
            DecoratedType.forImplicitType(
                typeProvider,
                element.bound ?? typeProvider.objectType,
                graph,
                target.typeFormalBound(element.name)));
      }
    }
    return DecoratedType(type, node,
        returnType: returnType ??
            DecoratedType.forImplicitType(
                typeProvider, type.returnType, graph, target.returnType()),
        namedParameters: namedParameters,
        positionalParameters: positionalParameters);
  }

  /// Creates a DecoratedType corresponding to [type], with fresh nullability
  /// nodes everywhere that don't correspond to any source location.  These
  /// nodes can later be unioned with other nodes.
  factory DecoratedType.forImplicitType(TypeProvider typeProvider,
      DartType type, NullabilityGraph graph, NullabilityNodeTarget target,
      {List<DecoratedType> typeArguments}) {
    var nullabilityNode = NullabilityNode.forInferredType(target);
    if (type is InterfaceType) {
      assert(() {
        if (typeArguments != null) {
          assert(typeArguments.length == type.typeArguments.length);
          for (var i = 0; i < typeArguments.length; ++i) {
            assert(typeArguments[i].type == type.typeArguments[i]);
          }
        }
        return true;
      }());

      int index = 0;
      typeArguments ??= type.typeArguments
          .map((t) => DecoratedType.forImplicitType(
              typeProvider, t, graph, target.typeArgument(index++)))
          .toList();
      return DecoratedType(type, nullabilityNode, typeArguments: typeArguments);
    } else if (type is FunctionType) {
      if (typeArguments != null) {
        throw 'Not supported: implicit function type with explicit type '
            'arguments';
      }
      return DecoratedType.forImplicitFunction(
          typeProvider, type, nullabilityNode, graph, target);
    } else {
      assert(typeArguments == null);
      return DecoratedType(type, nullabilityNode);
    }
  }

  /// Creates a [DecoratedType] for a synthetic type parameter, to be used
  /// during comparison of generic function types.
  DecoratedType._forTypeParameterSubstitution(TypeParameterElement parameter)
      : type = TypeParameterTypeImpl(
          element: parameter,
          nullabilitySuffix: NullabilitySuffix.star,
        ),
        node = null,
        returnType = null,
        positionalParameters = const [],
        namedParameters = const {},
        typeArguments = const [] {
    // We'll be storing the type parameter bounds in
    // [_decoratedTypeParameterBounds] so the type parameter needs to have an
    // enclosing element of `null`.
    assert(parameter.enclosingElement == null,
        '$parameter should not have parent ${parameter.enclosingElement}');
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
      if (!identical(node, other.node)) return false;
      var thisType = type;
      var otherType = other.type;
      if (thisType is FunctionType && otherType is FunctionType) {
        if (thisType.normalParameterTypes.length !=
            otherType.normalParameterTypes.length) {
          return false;
        }
        if (thisType.typeFormals.length != otherType.typeFormals.length) {
          return false;
        }
        var renamed = RenamedDecoratedFunctionTypes.match(
            this, other, (bound1, bound2) => bound1 == bound2);
        if (renamed == null) return false;
        if (renamed.returnType1 != renamed.returnType2) return false;
        if (!_compareLists(
            renamed.positionalParameters1, renamed.positionalParameters2)) {
          return false;
        }
        if (!_compareMaps(renamed.namedParameters1, renamed.namedParameters2)) {
          return false;
        }
        return true;
      } else if (thisType is InterfaceType && otherType is InterfaceType) {
        if (thisType.element != otherType.element) return false;
        if (!_compareLists(typeArguments, other.typeArguments)) {
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
    assert(argumentTypes.length == typeFormals.length);
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

  @override
  DecoratedTypeInfo namedParameter(String name) => namedParameters[name];

  @override
  DecoratedTypeInfo positionalParameter(int i) => positionalParameters[i];

  /// Updates the [roles] map with information about the nullability nodes
  /// pointed to by this decorated type.
  ///
  /// Each entry stored in [roles] maps the role of the node to the node itself.
  /// Roles look like pathnames, where each path component is an integer to
  /// represent a type argument (or a positional parameter type, in the case of
  /// a function type), an name to represent a named parameter type, or `@r` to
  /// represent a return type.
  void recordRoles(Map<String, NullabilityNode> roles,
      {String rolePrefix = ''}) {
    roles[rolePrefix] = node;
    returnType?.recordRoles(roles, rolePrefix: '$rolePrefix/@r');
    for (int i = 0; i < positionalParameters.length; i++) {
      positionalParameters[i].recordRoles(roles, rolePrefix: '$rolePrefix/$i');
    }
    for (var entry in namedParameters.entries) {
      entry.value.recordRoles(roles, rolePrefix: '$rolePrefix/${entry.key}');
    }
    for (int i = 0; i < typeArguments.length; i++) {
      typeArguments[i].recordRoles(roles, rolePrefix: '$rolePrefix/$i');
    }
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
      var type = this.type;
      undecoratedResult = Substitution.fromPairs(
        substitution.keys.toList(),
        substitution.values.map((d) => d.type).toList(),
      ).substituteType(type);
      if (undecoratedResult is FunctionType && type is FunctionType) {
        for (int i = 0; i < undecoratedResult.typeFormals.length; i++) {
          DecoratedTypeParameterBounds.current.put(
              undecoratedResult.typeFormals[i],
              DecoratedTypeParameterBounds.current.get(type.typeFormals[i]));
        }
      }
    }
    return _substitute(substitution, undecoratedResult);
  }

  @override
  String toString() {
    var trailing = node == null ? '' : node.debugSuffix;
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

  @override
  DecoratedTypeInfo typeArgument(int i) => typeArguments[i];

  /// Creates a shallow copy of `this`, replacing the nullability node.
  DecoratedType withNode(NullabilityNode node) => DecoratedType(type, node,
      returnType: returnType,
      positionalParameters: positionalParameters,
      namedParameters: namedParameters,
      typeArguments: typeArguments);

  /// Creates a shallow copy of `this`, replacing the nullability node and the
  /// type.
  DecoratedType withNodeAndType(NullabilityNode node, DartType type) =>
      DecoratedType(type, node,
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
      var typeFormals = type.typeFormals;
      assert(typeFormals.length == undecoratedResult.typeFormals.length);
      if (typeFormals.isNotEmpty) {
        // The analyzer sometimes allocates fresh type variables when performing
        // substitutions, so we need to reflect that in our decorations by
        // substituting to use the type variables the analyzer used.
        substitution =
            Map<TypeParameterElement, DecoratedType>.from(substitution);
        for (int i = 0; i < typeFormals.length; i++) {
          // Check if it's a fresh type variable.
          if (undecoratedResult.typeFormals[i].enclosingElement == null) {
            substitution[typeFormals[i]] =
                DecoratedType._forTypeParameterSubstitution(
                    undecoratedResult.typeFormals[i]);
          }
        }
        for (int i = 0; i < typeFormals.length; i++) {
          var typeFormal = typeFormals[i];
          var oldDecoratedBound =
              DecoratedTypeParameterBounds.current.get(typeFormal);
          var undecoratedResult2 = undecoratedResult.typeFormals[i].bound;
          if (undecoratedResult2 == null) {
            if (oldDecoratedBound == null) {
              assert(
                  false, 'Could not find old decorated bound for type formal');
              // Recover the best we can by assuming a bound of `dynamic`.
              oldDecoratedBound = DecoratedType(
                  DynamicTypeImpl.instance,
                  NullabilityNode.forInferredType(
                      NullabilityNodeTarget.text('Type parameter bound')));
            }
            undecoratedResult2 = oldDecoratedBound.type;
          }
          var newDecoratedBound =
              oldDecoratedBound._substitute(substitution, undecoratedResult2);
          if (identical(typeFormal, undecoratedResult.typeFormals[i])) {
            assert(oldDecoratedBound == newDecoratedBound);
          } else {
            DecoratedTypeParameterBounds.current
                .put(typeFormal, newDecoratedBound);
          }
        }
      }
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
        return inner.withNodeAndType(
            NullabilityNode.forSubstitution(inner.node, node),
            undecoratedResult);
      }
    } else if (type.isVoid || type.isDynamic) {
      return this;
    }
    throw '$type.substitute($type | $substitution)'; // TODO(paulberry)
  }

  /// Performs the logic that is common to substitution and function type
  /// instantiation.  Namely, a decorated type is formed whose undecorated type
  /// is [undecoratedResult], and whose return type, positional parameters, and
  /// named parameters are formed by performing the given [substitution].
  DecoratedType _substituteFunctionAfterFormals(FunctionType undecoratedResult,
      Map<TypeParameterElement, DecoratedType> substitution) {
    var newPositionalParameters = <DecoratedType>[];
    var numRequiredParameters = undecoratedResult.normalParameterTypes.length;
    for (int i = 0; i < positionalParameters.length; i++) {
      var undecoratedParameterType = i < numRequiredParameters
          ? undecoratedResult.normalParameterTypes[i]
          : undecoratedResult.optionalParameterTypes[i - numRequiredParameters];
      newPositionalParameters.add(positionalParameters[i]
          ._substitute(substitution, undecoratedParameterType));
    }
    var newNamedParameters = <String, DecoratedType>{};
    for (var entry in namedParameters.entries) {
      var name = entry.key;
      var undecoratedParameterType =
          undecoratedResult.namedParameterTypes[name];
      newNamedParameters[name] =
          (entry.value._substitute(substitution, undecoratedParameterType));
    }
    return DecoratedType(undecoratedResult, node,
        returnType:
            returnType._substitute(substitution, undecoratedResult.returnType),
        positionalParameters: newPositionalParameters,
        namedParameters: newNamedParameters);
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
}

/// Data structure mapping type parameters to their decorated bounds.
///
/// Since we need to be able to access this mapping globally throughout the
/// migration engine, from places where we can't easily inject it, the current
/// mapping is stored in a static variable.
class DecoratedTypeParameterBounds {
  /// The [DecoratedTypeParameterBounds] currently in use, or `null` if we are
  /// not currently in a stage of migration where we need access to the
  /// decorated types of type parameter bounds.
  ///
  /// If `null`, then attempts to look up the decorated types of type parameter
  /// bounds will fail.
  static DecoratedTypeParameterBounds current;

  final _orphanBounds = Expando<DecoratedType>();

  final _parentedBounds = <TypeParameterElement, DecoratedType>{};

  DecoratedType get(TypeParameterElement element) {
    if (element.enclosingElement == null) {
      return _orphanBounds[element];
    } else {
      return _parentedBounds[element];
    }
  }

  void put(TypeParameterElement element, DecoratedType bounds) {
    if (element.enclosingElement == null) {
      _orphanBounds[element] = bounds;
    } else {
      _parentedBounds[element] = bounds;
    }
  }
}

/// Helper class that renames the type parameters in two decorated function
/// types so that they match.
class RenamedDecoratedFunctionTypes {
  final DecoratedType returnType1;

  final DecoratedType returnType2;

  final List<DecoratedType> positionalParameters1;

  final List<DecoratedType> positionalParameters2;

  final Map<String, DecoratedType> namedParameters1;

  final Map<String, DecoratedType> namedParameters2;

  RenamedDecoratedFunctionTypes._(
      this.returnType1,
      this.returnType2,
      this.positionalParameters1,
      this.positionalParameters2,
      this.namedParameters1,
      this.namedParameters2);

  /// Attempt to find a renaming of the type parameters of [type1] and [type2]
  /// (both of which should be function types) such that the generic type
  /// parameters match.
  ///
  /// The callback [boundsMatcher] is used to determine whether type parameter
  /// bounds match.
  ///
  /// If such a renaming can be found, it is returned.  If not, `null` is
  /// returned.
  static RenamedDecoratedFunctionTypes match(
      DecoratedType type1,
      DecoratedType type2,
      bool Function(DecoratedType, DecoratedType) boundsMatcher) {
    if (!_isNeeded(type1.typeFormals, type2.typeFormals)) {
      return RenamedDecoratedFunctionTypes._(
          type1.returnType,
          type2.returnType,
          type1.positionalParameters,
          type2.positionalParameters,
          type1.namedParameters,
          type2.namedParameters);
    }
    // Create a fresh set of type variables and substitute so we can
    // compare safely.
    var substitution1 = <TypeParameterElement, DecoratedType>{};
    var substitution2 = <TypeParameterElement, DecoratedType>{};
    var newParameters = <TypeParameterElement>[];
    for (int i = 0; i < type1.typeFormals.length; i++) {
      var newParameter =
          TypeParameterElementImpl.synthetic(type1.typeFormals[i].name);
      newParameters.add(newParameter);
      var newParameterType =
          DecoratedType._forTypeParameterSubstitution(newParameter);
      substitution1[type1.typeFormals[i]] = newParameterType;
      substitution2[type2.typeFormals[i]] = newParameterType;
    }
    for (int i = 0; i < type1.typeFormals.length; i++) {
      var bound1 = DecoratedTypeParameterBounds.current
          .get((type1.type as FunctionType).typeFormals[i])
          .substitute(substitution1);
      var bound2 = DecoratedTypeParameterBounds.current
          .get((type2.type as FunctionType).typeFormals[i])
          .substitute(substitution2);
      if (!boundsMatcher(bound1, bound2)) return null;
      DecoratedTypeParameterBounds.current.put(newParameters[i], bound1);
    }
    var returnType1 = type1.returnType.substitute(substitution1);
    var returnType2 = type2.returnType.substitute(substitution2);
    var positionalParameters1 =
        _substituteList(type1.positionalParameters, substitution1);
    var positionalParameters2 =
        _substituteList(type2.positionalParameters, substitution2);
    var namedParameters1 = _substituteMap(type1.namedParameters, substitution1);
    var namedParameters2 = _substituteMap(type2.namedParameters, substitution2);
    return RenamedDecoratedFunctionTypes._(
        returnType1,
        returnType2,
        positionalParameters1,
        positionalParameters2,
        namedParameters1,
        namedParameters2);
  }

  static bool _isNeeded(List<TypeParameterElement> formals1,
      List<TypeParameterElement> formals2) {
    if (identical(formals1, formals2)) return false;
    if (formals1.length != formals2.length) return true;
    for (int i = 0; i < formals1.length; i++) {
      if (!identical(formals1[i], formals2[i])) return true;
    }
    return false;
  }

  static List<DecoratedType> _substituteList(List<DecoratedType> list,
      Map<TypeParameterElement, DecoratedType> substitution) {
    return list.map((t) => t.substitute(substitution)).toList();
  }

  static Map<String, DecoratedType> _substituteMap(
      Map<String, DecoratedType> map,
      Map<TypeParameterElement, DecoratedType> substitution) {
    var result = <String, DecoratedType>{};
    for (var entry in map.entries) {
      result[entry.key] = entry.value.substitute(substitution);
    }
    return result;
  }
}
