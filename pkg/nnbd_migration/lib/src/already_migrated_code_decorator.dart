// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/element_type_provider.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edge_origin.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/nullability_node_target.dart';

/// This class transforms ordinary [DartType]s into their corresponding
/// [DecoratedType]s, assuming the [DartType]s come from code that has already
/// been migrated to NNBD.
class AlreadyMigratedCodeDecorator {
  final NullabilityGraph _graph;

  final TypeProvider _typeProvider;

  final LineInfo Function(String) _getLineInfo;

  AlreadyMigratedCodeDecorator(
      this._graph, this._typeProvider, this._getLineInfo);

  /// Transforms [type], which should have come from code that has already been
  /// migrated to NNBD, into the corresponding [DecoratedType].
  ///
  /// TODO(paulberry): do we still need element or can we use target now?
  DecoratedType decorate(
      DartType type, Element element, NullabilityNodeTarget target) {
    if (type.isVoid || type.isDynamic) {
      var node = NullabilityNode.forAlreadyMigrated(target);
      _graph.makeNullableUnion(
          node, AlwaysNullableTypeOrigin.forElement(element, type.isVoid));
      return DecoratedType(type, node);
    }
    NullabilityNode node;
    var nullabilitySuffix = type.nullabilitySuffix;
    if (nullabilitySuffix == NullabilitySuffix.question) {
      node = NullabilityNode.forAlreadyMigrated(target);
      _graph.makeNullableUnion(
          node, AlreadyMigratedTypeOrigin.forElement(element, true));
    } else {
      node = NullabilityNode.forAlreadyMigrated(target);
      _graph.makeNonNullableUnion(
          node, AlreadyMigratedTypeOrigin.forElement(element, false));
    }
    if (type is FunctionType) {
      for (var element in type.typeFormals) {
        DecoratedTypeParameterBounds.current.put(
            element,
            decorate(
                element.bound ??
                    (_typeProvider.objectType as TypeImpl)
                        .withNullability(NullabilitySuffix.question),
                element,
                target.typeFormalBound(element.name)));
      }
      var positionalParameters = <DecoratedType>[];
      var namedParameters = <String, DecoratedType>{};
      int index = 0;
      for (var parameter in type.parameters) {
        if (parameter.isPositional) {
          positionalParameters.add(decorate(
              parameter.type, element, target.positionalParameter(index++)));
        } else {
          var name = parameter.name;
          namedParameters[name] =
              decorate(parameter.type, element, target.namedParameter(name));
        }
      }
      return DecoratedType(type, node,
          returnType: decorate(type.returnType, element, target.returnType()),
          namedParameters: namedParameters,
          positionalParameters: positionalParameters);
    } else if (type is InterfaceType) {
      var typeParameters = type.element.typeParameters;
      if (typeParameters.isNotEmpty) {
        assert(type.typeArguments.length == typeParameters.length);
        int index = 0;
        return DecoratedType(type, node, typeArguments: [
          for (var t in type.typeArguments)
            decorate(t, element, target.typeArgument(index++))
        ]);
      }
      return DecoratedType(type, node);
    } else if (type is TypeParameterType) {
      return DecoratedType(type, node);
    } else if (type.isBottom) {
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
    allSupertypes.addAll(class_.preMigrationInterfaces);
    allSupertypes.addAll(class_.mixins);
    var type = class_.thisType;
    if (type.isDartAsyncFuture) {
      // Add FutureOr<T> as a supertype of Future<T>.
      allSupertypes.add(_typeProvider.futureOrType2(type.typeArguments.single));
    }
    return [
      for (var t in allSupertypes)
        decorate(t, class_, NullabilityNodeTarget.element(class_, _getLineInfo))
    ];
  }
}

extension on ClassElement {
  List<InterfaceType> get preMigrationInterfaces {
    var previousElementTypeProvider = ElementTypeProvider.current;
    try {
      ElementTypeProvider.current = const ElementTypeProvider();
      return interfaces;
    } finally {
      ElementTypeProvider.current = previousElementTypeProvider;
    }
  }
}
