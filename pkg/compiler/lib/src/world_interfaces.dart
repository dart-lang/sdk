// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/js_backend/no_such_method_registry_interfaces.dart';
import 'package:compiler/src/js_model/element_map_interfaces.dart';

import 'closure.dart';
import 'package:kernel/ast.dart' as ir;
import 'common/elements.dart';
import 'deferred_load/output_unit.dart' show OutputUnitData;
import 'elements/entities.dart';
import 'elements/names.dart';
import 'elements/types.dart';
import 'inferrer/abstract_value_domain.dart';
import 'js_backend/annotations.dart';
import 'js_backend/native_data.dart';
import 'js_backend/interceptor_data.dart';
import 'universe/class_hierarchy.dart';
import 'universe/selector.dart';

/// Common superinterface for [OpenWorld] and [JClosedWorld].
abstract class World {}

abstract class JClosedWorld implements World {
  AbstractValueDomain get abstractValueDomain;

  JCommonElements get commonElements;

  ClassHierarchy get classHierarchy;

  DartTypes get dartTypes;

  ElementEnvironment get elementEnvironment;

  NativeData get nativeData;

  AnnotationsData get annotationsData;

  ClosureData get closureDataLookup;

  OutputUnitData get outputUnitData;

  InterceptorData get interceptorData;

  NoSuchMethodData get noSuchMethodData;

  Iterable<MemberEntity> get liveInstanceMembers;

  JsToElementMap get elementMap;

  bool isUsedAsMixin(ClassEntity cls);

  bool includesClosureCall(Selector selector, AbstractValue? receiver);

  Iterable<MemberEntity> locateMembers(
      Selector selector, AbstractValue? receiver);

  bool fieldNeverChanges(MemberEntity element);

  Selector getSelector(ir.Expression node);

  Iterable<ClassEntity> mixinUsesOf(ClassEntity cls);

  bool isImplemented(ClassEntity cls);

  Iterable<ClassEntity> commonSupertypesOf(Iterable<ClassEntity> classes);

  bool hasElementIn(ClassEntity cls, Name name, MemberEntity element);

  bool hasAnySubclassThatMixes(ClassEntity superclass, ClassEntity mixin);

  bool hasAnySubclassThatImplements(ClassEntity superclass, ClassEntity type);

  bool hasAnySubclassOfMixinUseThatImplements(
      ClassEntity cls, ClassEntity type);

  bool needsNoSuchMethod(ClassEntity cls, Selector selector, ClassQuery query);

  bool includesClosureCallInDomain(Selector selector, AbstractValue receiver,
      AbstractValueDomain abstractValueDomain);

  Iterable<MemberEntity> locateMembersInDomain(Selector selector,
      AbstractValue? receiver, AbstractValueDomain abstractValueDomain);

  bool everySubtypeIsSubclassOfOrMixinUseOf(ClassEntity x, ClassEntity y);

  bool isSubclassOfMixinUseOf(ClassEntity cls, ClassEntity mixin);

  ClassEntity? getLubOfInstantiatedSubtypes(ClassEntity cls);

  ClassEntity? getLubOfInstantiatedSubclasses(ClassEntity cls);
}

// TODO(48820): Move back to `world.dart` when migrated.
/// A [BuiltWorld] is an immutable result of a [WorldBuilder].
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
