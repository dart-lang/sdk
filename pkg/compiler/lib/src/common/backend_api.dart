// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.backend_api;

import '../common.dart';
import '../common/codegen.dart' show CodegenImpact;
import '../common/resolution.dart' show ResolutionImpact;
import '../constants/expressions.dart' show ConstantExpression;
import '../elements/types.dart';
import '../elements/resolution_types.dart'
    show ResolutionDartType, ResolutionInterfaceType;
import '../elements/entities.dart';
import '../enqueue.dart' show ResolutionEnqueuer;
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
  WorldImpact transformResolutionImpact(
      ResolutionEnqueuer enqueuer, ResolutionImpact worldImpact) {
    return worldImpact;
  }
}

/// Interface for serialization of backend specific data.
class BackendSerialization {
  const BackendSerialization();

  SerializerPlugin get serializer => const SerializerPlugin();
  DeserializerPlugin get deserializer => const DeserializerPlugin();
}

/// Interface providing access to core classes used by the backend.
abstract class BackendClasses {
  /// Returns the backend implementation class for `int`. This is the `JSInt`
  /// class.
  ClassEntity get intClass;

  /// Returns the backend implementation class for `double`. This is the
  /// `JSDouble` class.
  ClassEntity get doubleClass;

  /// Returns the backend implementation class for `num`. This is the `JSNum`
  /// class.
  ClassEntity get numClass;

  /// Returns the backend implementation class for `String`. This is the
  /// `JSString` class.
  ClassEntity get stringClass;

  /// Returns the backend implementation class for `List`. This is the
  /// `JSArray` class.
  ClassEntity get listClass;

  /// Returns the backend dummy class used to track mutable implementations of
  /// `List` in type masks. This is the `JSMutableArray` class.
  ClassEntity get mutableListClass;

  /// Returns the backend dummy class used to track growable implementations of
  /// `List` in type masks. This is the `JSExtendableArray` class.
  ClassEntity get growableListClass;

  /// Returns the backend dummy class used to track fixed-sized implementations
  /// of `List` in type masks. This is the `JSFixedArray` class.
  ClassEntity get fixedListClass;

  /// Returns the backend dummy class used to track unmodifiable (constant)
  /// implementations of `List` in type masks. This is the `JSUnmodifiableArray`
  /// class.
  ClassEntity get constListClass;

  /// Returns the backend implementation class for map literals. This is the
  /// `LinkedHashMap` class.
  ClassEntity get mapClass;

  /// Returns the backend superclass for implementations of constant map
  /// literals. This is the `ConstantMap` class.
  ClassEntity get constMapClass;

  /// Returns the backend implementation class for `Function`. This is the
  /// `Function` class from 'dart:core'.
  ClassEntity get functionClass;

  /// Returns the backend implementation class for `Type`. This is the
  /// `TypeImpl` class.
  ClassEntity get typeClass;

  /// Returns the type of the implementation class for `Type`.
  InterfaceType get typeType;

  /// Returns the backend implementation class for `bool`. This is the `JSBool`
  /// class.
  ClassEntity get boolClass;

  /// Returns the backend implementation class for `null`. This is the `JSNull`
  /// class.
  ClassEntity get nullClass;

  /// Returns the backend dummy class used to track unsigned 32-bit integer
  /// values in type masks. This is the `JSUint32` class.
  ClassEntity get uint32Class;

  /// Returns the backend dummy class used to track unsigned 31-bit integer
  /// values in type masks. This is the `JSUint31` class.
  ClassEntity get uint31Class;

  /// Returns the backend dummy class used to track position values in type
  /// masks. This is the `JSPositiveInt` class.
  ClassEntity get positiveIntClass;

  /// Returns the backend implementation class for the `Iterable` used in
  /// `sync*` methods. This is the `_SyncStarIterable` class in dart:async.
  ClassEntity get syncStarIterableClass;

  /// Returns the backend implementation class for the `Future` used in
  /// `async` methods. This is the `_Future` class in dart:async.
  ClassEntity get asyncFutureClass;

  /// Returns the backend implementation class for the `Stream` used in
  /// `async*` methods. This is the `_ControllerStream` class in dart:async.
  ClassEntity get asyncStarStreamClass;

  /// Returns the backend superclass directly indexable class, that is classes
  /// that natively support the `[]` operator. This is the `JSIndexable` class.
  ClassEntity get indexableClass;

  /// Returns the backend superclass directly indexable class, that is classes
  /// that natively support the `[]=` operator. This is the `JSMutableIndexable`
  /// class.
  ClassEntity get mutableIndexableClass;

  /// Returns the backend class used to mark native classes that support integer
  /// indexing, that is `[]` and `[]=` where the key is an integer. This is the
  /// `JavaScriptIndexingBehavior` class.
  ClassEntity get indexingBehaviorClass;

  /// Returns the backend superclass for all intercepted classes. This is the
  /// `Interceptor` class.
  ClassEntity get interceptorClass;

  /// Returns `true` if [element] is a default implementation of `Object.==`.
  /// This either `Object.==`, `Intercepter.==` or `Null.==`.
  bool isDefaultEqualityImplementation(MemberEntity element);

  /// Returns `true` if [cls] is a native class.
  bool isNativeClass(ClassEntity element);

  /// Returns the type of the constant map implementation for a const map
  /// literal of [sourceType]. If [hasProtoKey] the map contains key of value
  /// '__proto__' and if [onlyStringKeys] all keys are string constants.
  InterfaceType getConstantMapTypeFor(InterfaceType sourceType,
      {bool hasProtoKey: false, bool onlyStringKeys: false});

  /// Returns the type of the constant symbol implementation class.
  InterfaceType get symbolType;

  /// Returns the field of the constant symbol implementation class that holds
  /// its internal name.
  FieldEntity get symbolField;
}
