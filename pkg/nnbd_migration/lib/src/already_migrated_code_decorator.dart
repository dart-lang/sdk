// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edge_origin.dart';
import 'package:nnbd_migration/src/nullability_node.dart';

/// This class transforms ordinary [DartType]s into their corresponding
/// [DecoratedType]s, assuming the [DartType]s come from code that has already
/// been migrated to NNBD.
class AlreadyMigratedCodeDecorator {
  final NullabilityGraph _graph;

  final TypeProvider _typeProvider;

  AlreadyMigratedCodeDecorator(this._graph, this._typeProvider);

  /// Transforms [type], which should have come from code that has already been
  /// migrated to NNBD, into the corresponding [DecoratedType].
  DecoratedType decorate(DartType type, Element element) {
    if (type.isVoid || type.isDynamic) {
      var node = NullabilityNode.forAlreadyMigrated();
      _graph.makeNullable(node, AlwaysNullableTypeOrigin.forElement(element));
      return DecoratedType(type, node);
    }
    NullabilityNode node;
    var nullabilitySuffix = type.nullabilitySuffix;
    if (nullabilitySuffix == NullabilitySuffix.question) {
      node = NullabilityNode.forAlreadyMigrated();
      _graph.makeNullable(node, AlreadyMigratedTypeOrigin.forElement(element));
    } else {
      node = NullabilityNode.forAlreadyMigrated();
      _graph.makeNonNullableUnion(
          node, AlreadyMigratedTypeOrigin.forElement(element));
    }
    if (type is FunctionType) {
      for (var element in type.typeFormals) {
        var bound = element.bound;
        DecoratedType decoratedBound;
        if (bound == null) {
          decoratedBound = decorate(
              (_typeProvider.objectType as TypeImpl)
                  .withNullability(NullabilitySuffix.question),
              element);
        } else {
          decoratedBound = decorate(bound, element);
        }
        DecoratedTypeParameterBounds.current.put(element, decoratedBound);
      }
      var positionalParameters = <DecoratedType>[];
      var namedParameters = <String, DecoratedType>{};
      for (var parameter in type.parameters) {
        if (parameter.isPositional) {
          positionalParameters.add(decorate(parameter.type, element));
        } else {
          namedParameters[parameter.name] = decorate(parameter.type, element);
        }
      }
      return DecoratedType(type, node,
          returnType: decorate(type.returnType, element),
          namedParameters: namedParameters,
          positionalParameters: positionalParameters);
    } else if (type is InterfaceType) {
      var typeParameters = type.element.typeParameters;
      if (typeParameters.isNotEmpty) {
        assert(type.typeArguments.length == typeParameters.length);
        return DecoratedType(type, node, typeArguments: [
          for (var t in type.typeArguments) decorate(t, element)
        ]);
      }
      return DecoratedType(type, node);
    } else if (type is TypeParameterType) {
      return DecoratedType(type, node);
    } else {
      // TODO(paulberry)
      throw UnimplementedError(
          'Unable to decorate already-migrated type $type');
    }
  }

  /// Get all the decorated immediate supertypes of the non-migrated class
  /// [class_].
  Iterable<DecoratedType> getImmediateSupertypes(ClassElement class_) {
    var allSupertypes = <DartType>[];
    var supertype = class_.supertype;
    if (supertype != null) {
      allSupertypes.add(supertype);
    }
    allSupertypes.addAll(class_.superclassConstraints);
    allSupertypes.addAll(class_.interfaces);
    allSupertypes.addAll(class_.mixins);
    var type = class_.thisType;
    if (type.isDartAsyncFuture) {
      // Add FutureOr<T> as a supertype of Future<T>.
      allSupertypes.add(_typeProvider.futureOrType2(type.typeArguments.single));
    }
    return [for (var t in allSupertypes) decorate(t, class_)];
  }
}
