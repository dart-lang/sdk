// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.codegen;

import '../common_elements.dart';
import '../elements/entities.dart';
import '../elements/types.dart' show DartType, InterfaceType;
import '../native/behavior.dart';
import '../js/js.dart' as js;
import '../universe/feature.dart';
import '../universe/use.dart' show ConstantUse, DynamicUse, StaticUse, TypeUse;
import '../universe/world_impact.dart'
    show WorldImpact, WorldImpactBuilderImpl, WorldImpactVisitor;
import '../util/enumset.dart';
import '../util/util.dart' show Pair, Setlet;

class CodegenImpact extends WorldImpact {
  const CodegenImpact();

  Iterable<Pair<DartType, DartType>> get typeVariableBoundsSubtypeChecks {
    return const <Pair<DartType, DartType>>[];
  }

  Iterable<String> get constSymbols => const <String>[];

  Iterable<Set<ClassEntity>> get specializedGetInterceptors {
    return const <Set<ClassEntity>>[];
  }

  bool get usesInterceptor => false;

  Iterable<AsyncMarker> get asyncMarkers => const <AsyncMarker>[];

  Iterable<GenericInstantiation> get genericInstantiations =>
      const <GenericInstantiation>[];

  Iterable<NativeBehavior> get nativeBehaviors => const [];

  Iterable<FunctionEntity> get nativeMethods => const [];
}

class _CodegenImpact extends WorldImpactBuilderImpl implements CodegenImpact {
  Setlet<Pair<DartType, DartType>> _typeVariableBoundsSubtypeChecks;
  Setlet<String> _constSymbols;
  List<Set<ClassEntity>> _specializedGetInterceptors;
  bool _usesInterceptor = false;
  EnumSet<AsyncMarker> _asyncMarkers;
  Set<GenericInstantiation> _genericInstantiations;
  List<NativeBehavior> _nativeBehaviors;
  Set<FunctionEntity> _nativeMethods;

  _CodegenImpact();

  @override
  void apply(WorldImpactVisitor visitor) {
    staticUses.forEach(visitor.visitStaticUse);
    dynamicUses.forEach(visitor.visitDynamicUse);
    typeUses.forEach(visitor.visitTypeUse);
  }

  void registerTypeVariableBoundsSubtypeCheck(
      DartType subtype, DartType supertype) {
    _typeVariableBoundsSubtypeChecks ??= new Setlet<Pair<DartType, DartType>>();
    _typeVariableBoundsSubtypeChecks
        .add(new Pair<DartType, DartType>(subtype, supertype));
  }

  @override
  Iterable<Pair<DartType, DartType>> get typeVariableBoundsSubtypeChecks {
    return _typeVariableBoundsSubtypeChecks != null
        ? _typeVariableBoundsSubtypeChecks
        : const <Pair<DartType, DartType>>[];
  }

  void registerConstSymbol(String name) {
    _constSymbols ??= new Setlet<String>();
    _constSymbols.add(name);
  }

  @override
  Iterable<String> get constSymbols {
    return _constSymbols != null ? _constSymbols : const <String>[];
  }

  void registerSpecializedGetInterceptor(Set<ClassEntity> classes) {
    _specializedGetInterceptors ??= <Set<ClassEntity>>[];
    _specializedGetInterceptors.add(classes);
  }

  @override
  Iterable<Set<ClassEntity>> get specializedGetInterceptors {
    return _specializedGetInterceptors != null
        ? _specializedGetInterceptors
        : const <Set<ClassEntity>>[];
  }

  void registerUseInterceptor() {
    _usesInterceptor = true;
  }

  @override
  bool get usesInterceptor => _usesInterceptor;

  void registerAsyncMarker(AsyncMarker asyncMarker) {
    _asyncMarkers ??= new EnumSet<AsyncMarker>();
    _asyncMarkers.add(asyncMarker);
  }

  @override
  Iterable<AsyncMarker> get asyncMarkers {
    return _asyncMarkers != null
        ? _asyncMarkers.iterable(AsyncMarker.values)
        : const <AsyncMarker>[];
  }

  void registerGenericInstantiation(GenericInstantiation instantiation) {
    _genericInstantiations ??= new Set<GenericInstantiation>();
    _genericInstantiations.add(instantiation);
  }

  @override
  Iterable<GenericInstantiation> get genericInstantiations {
    return _genericInstantiations ?? const <GenericInstantiation>[];
  }

  void registerNativeBehavior(NativeBehavior nativeBehavior) {
    _nativeBehaviors ??= [];
    _nativeBehaviors.add(nativeBehavior);
  }

  @override
  Iterable<NativeBehavior> get nativeBehaviors {
    return _nativeBehaviors ?? const <NativeBehavior>[];
  }

  void registerNativeMethod(FunctionEntity function) {
    _nativeMethods ??= {};
    _nativeMethods.add(function);
  }

  @override
  Iterable<FunctionEntity> get nativeMethods {
    return _nativeMethods ?? const [];
  }
}

// TODO(johnniwinther): Split this class into interface and implementation.
// TODO(johnniwinther): Move this implementation to the JS backend.
class CodegenRegistry {
  final ElementEnvironment _elementEnvironment;
  final MemberEntity currentElement;
  final _CodegenImpact worldImpact;

  CodegenRegistry(this._elementEnvironment, this.currentElement)
      : this.worldImpact = new _CodegenImpact();

  bool get isForResolution => false;

  @override
  String toString() => 'CodegenRegistry for $currentElement';

  @deprecated
  void registerInstantiatedClass(ClassEntity element) {
    registerInstantiation(_elementEnvironment.getRawType(element));
  }

  void registerStaticUse(StaticUse staticUse) {
    worldImpact.registerStaticUse(staticUse);
  }

  void registerDynamicUse(DynamicUse dynamicUse) {
    worldImpact.registerDynamicUse(dynamicUse);
  }

  void registerTypeUse(TypeUse typeUse) {
    worldImpact.registerTypeUse(typeUse);
  }

  void registerConstantUse(ConstantUse constantUse) {
    worldImpact.registerConstantUse(constantUse);
  }

  void registerTypeVariableBoundsSubtypeCheck(
      DartType subtype, DartType supertype) {
    worldImpact.registerTypeVariableBoundsSubtypeCheck(subtype, supertype);
  }

  void registerInstantiatedClosure(FunctionEntity element) {
    worldImpact.registerStaticUse(new StaticUse.callMethod(element));
  }

  void registerConstSymbol(String name) {
    worldImpact.registerConstSymbol(name);
  }

  void registerSpecializedGetInterceptor(Set<ClassEntity> classes) {
    worldImpact.registerSpecializedGetInterceptor(classes);
  }

  void registerUseInterceptor() {
    worldImpact.registerUseInterceptor();
  }

  void registerInstantiation(InterfaceType type) {
    registerTypeUse(new TypeUse.instantiation(type));
  }

  void registerAsyncMarker(AsyncMarker asyncMarker) {
    worldImpact.registerAsyncMarker(asyncMarker);
  }

  void registerGenericInstantiation(GenericInstantiation instantiation) {
    worldImpact.registerGenericInstantiation(instantiation);
  }

  void registerNativeBehavior(NativeBehavior nativeBehavior) {
    worldImpact.registerNativeBehavior(nativeBehavior);
  }

  void registerNativeMethod(FunctionEntity function) {
    worldImpact.registerNativeMethod(function);
  }
}

class CodegenResult {
  js.Fun code;
  CodegenImpact impact;

  CodegenResult(this.code, this.impact);
}
