// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/nullability_node.dart';

/// This class transforms ordinary [DartType]s into their corresponding
/// [DecoratedType]s, assuming the [DartType]s come from code that has already
/// been migrated to NNBD.
class AlreadyMigratedCodeDecorator {
  final NullabilityGraph _graph;

  AlreadyMigratedCodeDecorator(this._graph);

  /// Transforms [type], which should have come from code that has already been
  /// migrated to NNBD, into the corresponding [DecoratedType].
  DecoratedType decorate(DartType type) {
    if (type.isVoid || type.isDynamic) {
      return DecoratedType(type, _graph.always);
    }
    var nullabilitySuffix = (type as TypeImpl).nullabilitySuffix;
    if (nullabilitySuffix == NullabilitySuffix.question) {
      // TODO(paulberry): add support for depending on already-migrated packages
      // containing nullable types.
      throw UnimplementedError(
          'Migration depends on an already-migrated nullable type');
    } else {
      // Currently, all types passed to this method have nullability suffix `star`
      // because (a) we don't yet have a migrated SDK, and (b) we haven't added
      // support to the migrator for analyzing packages that have already been
      // migrated with NNBD enabled.
      // TODO(paulberry): fix this assertion when things change.
      assert(nullabilitySuffix == NullabilitySuffix.star);
    }
    if (type is FunctionType) {
      if (type.typeFormals.isNotEmpty) {
        throw UnimplementedError('Decorating generic function type');
      }
      var positionalParameters = <DecoratedType>[];
      var namedParameters = <String, DecoratedType>{};
      for (var parameter in type.parameters) {
        if (parameter.isPositional) {
          positionalParameters.add(decorate(parameter.type));
        } else {
          namedParameters[parameter.name] = decorate(parameter.type);
        }
      }
      return DecoratedType(type, _graph.never,
          returnType: decorate(type.returnType),
          namedParameters: namedParameters,
          positionalParameters: positionalParameters);
    } else if (type is InterfaceType) {
      if (type.typeParameters.isNotEmpty) {
        // TODO(paulberry)
        throw UnimplementedError('Decorating ${type.displayName}');
      }
      return DecoratedType(type, _graph.never);
    } else if (type is TypeParameterType) {
      return DecoratedType(type, _graph.never);
    } else {
      // TODO(paulberry)
      throw UnimplementedError(
          'Unable to decorate already-migrated type $type');
    }
  }
}
