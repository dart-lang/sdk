// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.world;

import 'elements/entities.dart';
import 'elements/types.dart';
import 'js_backend/annotations.dart';
import 'universe/class_hierarchy.dart';
import 'universe/selector.dart' show Selector;

abstract class World {}

abstract class BuiltWorld {
  ClassHierarchy get classHierarchy;

  /// Calls [f] for each live generic method.
  void forEachGenericMethod(void Function(FunctionEntity) f);

  /// All types that are checked either through is, as or checked mode checks.
  Iterable<DartType> get isChecks;

  /// All type variables named in recipes.
  Set<TypeVariableType> get namedTypeVariablesNewRti;

  /// All directly instantiated types, that is, the types of
  /// [directlyInstantiatedClasses].
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<InterfaceType> get instantiatedTypes;

  // TODO(johnniwinther): Clean up these getters.
  /// Methods in instantiated classes that are potentially closurized.
  Iterable<FunctionEntity> get closurizedMembers;

  /// Static or top level methods that are closurized.
  Iterable<FunctionEntity> get closurizedStatics;

  /// Properties (fields and getters) which can be called as generic functions.
  Map<MemberEntity, DartType> get genericCallableProperties;

  /// Type variables used as type literals.
  Iterable<TypeVariableType> get typeVariableTypeLiterals;

  /// Live user-defined 'noSuchMethod' implementations.
  Iterable<FunctionEntity> get userNoSuchMethods;

  AnnotationsData get annotationsData;

  /// Calls [f] for each live generic instance methods.
  void forEachGenericInstanceMethod(void Function(FunctionEntity) f);

  /// Live generic local functions.
  Iterable<Local> get genericLocalFunctions;

  /// Call [f] for each generic [function] with the type arguments passed
  /// through static calls to [function].
  void forEachStaticTypeArgument(
      void f(Entity function, Set<DartType> typeArguments));

  /// Call [f] for each generic [selector] with the type arguments passed
  /// through dynamic calls to [selector].
  void forEachDynamicTypeArgument(
      void f(Selector selector, Set<DartType> typeArguments));
}
