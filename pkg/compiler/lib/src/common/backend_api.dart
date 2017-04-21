// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.backend_api;

import '../common/resolution.dart' show ResolutionImpact;
import '../constants/expressions.dart' show ConstantExpression;
import '../elements/resolution_types.dart'
    show ResolutionDartType, ResolutionInterfaceType;
import '../serialization/serialization.dart'
    show DeserializerPlugin, SerializerPlugin;
import '../tree/tree.dart' show Node;
import '../universe/world_impact.dart' show WorldImpact;

/// Interface for resolving native data for a target specific element.
abstract class NativeRegistry {
  /// Registers [nativeData] as part of the resolution impact.
  void registerNativeData(dynamic nativeData);
}

/// Interface for resolving calls to foreign functions.
abstract class ForeignResolver {
  /// Returns the constant expression of [node], or `null` if [node] is not
  /// a constant expression.
  ConstantExpression getConstant(Node node);

  /// Registers [type] as instantiated.
  void registerInstantiatedType(ResolutionInterfaceType type);

  /// Resolves [typeName] to a type in the context of [node].
  ResolutionDartType resolveTypeFromString(Node node, String typeName);
}

/// Target-specific transformation for resolution world impacts.
///
/// This processes target-agnostic [ResolutionImpact]s and creates [WorldImpact]
/// in which backend/target specific impact data is added, for example: if
/// certain feature is used that requires some helper code from the backend
/// libraries, this will be included by the impact transformer.
class ImpactTransformer {
  /// Transform the [ResolutionImpact] into a [WorldImpact] adding the
  /// backend dependencies for features used in [worldImpact].
  WorldImpact transformResolutionImpact(ResolutionImpact worldImpact) {
    return worldImpact;
  }
}

/// Interface for serialization of backend specific data.
class BackendSerialization {
  const BackendSerialization();

  SerializerPlugin get serializer => const SerializerPlugin();
  DeserializerPlugin get deserializer => const DeserializerPlugin();
}
