// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.codegen;

import '../elements/elements.dart' show ClassElement, LocalFunctionElement;
import '../elements/entities.dart';
import '../elements/types.dart' show DartType, InterfaceType;
import '../universe/use.dart' show ConstantUse, DynamicUse, StaticUse, TypeUse;
import '../universe/world_impact.dart'
    show WorldImpact, WorldImpactBuilderImpl, WorldImpactVisitor;
import '../util/enumset.dart';
import '../util/util.dart' show Pair, Setlet;
import 'work.dart' show WorkItem;

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

  Iterable<AsyncMarker> get asyncMarkers => <AsyncMarker>[];
}

class _CodegenImpact extends WorldImpactBuilderImpl implements CodegenImpact {
  Setlet<Pair<DartType, DartType>> _typeVariableBoundsSubtypeChecks;
  Setlet<String> _constSymbols;
  List<Set<ClassEntity>> _specializedGetInterceptors;
  bool _usesInterceptor = false;
  EnumSet<AsyncMarker> _asyncMarkers;

  _CodegenImpact();

  void apply(WorldImpactVisitor visitor) {
    staticUses.forEach(visitor.visitStaticUse);
    dynamicUses.forEach(visitor.visitDynamicUse);
    typeUses.forEach(visitor.visitTypeUse);
  }

  void registerTypeVariableBoundsSubtypeCheck(
      DartType subtype, DartType supertype) {
    if (_typeVariableBoundsSubtypeChecks == null) {
      _typeVariableBoundsSubtypeChecks = new Setlet<Pair<DartType, DartType>>();
    }
    _typeVariableBoundsSubtypeChecks
        .add(new Pair<DartType, DartType>(subtype, supertype));
  }

  Iterable<Pair<DartType, DartType>> get typeVariableBoundsSubtypeChecks {
    return _typeVariableBoundsSubtypeChecks != null
        ? _typeVariableBoundsSubtypeChecks
        : const <Pair<DartType, DartType>>[];
  }

  void registerConstSymbol(String name) {
    if (_constSymbols == null) {
      _constSymbols = new Setlet<String>();
    }
    _constSymbols.add(name);
  }

  Iterable<String> get constSymbols {
    return _constSymbols != null ? _constSymbols : const <String>[];
  }

  void registerSpecializedGetInterceptor(Set<ClassEntity> classes) {
    if (_specializedGetInterceptors == null) {
      _specializedGetInterceptors = <Set<ClassEntity>>[];
    }
    _specializedGetInterceptors.add(classes);
  }

  Iterable<Set<ClassEntity>> get specializedGetInterceptors {
    return _specializedGetInterceptors != null
        ? _specializedGetInterceptors
        : const <Set<ClassEntity>>[];
  }

  void registerUseInterceptor() {
    _usesInterceptor = true;
  }

  bool get usesInterceptor => _usesInterceptor;

  void registerAsyncMarker(AsyncMarker asyncMarker) {
    if (_asyncMarkers == null) {
      _asyncMarkers = new EnumSet<AsyncMarker>();
    }
    _asyncMarkers.add(asyncMarker);
  }

  Iterable<AsyncMarker> get asyncMarkers {
    return _asyncMarkers != null
        ? _asyncMarkers.iterable(AsyncMarker.values)
        : const <AsyncMarker>[];
  }
}

// TODO(johnniwinther): Split this class into interface and implementation.
// TODO(johnniwinther): Move this implementation to the JS backend.
class CodegenRegistry {
  final MemberEntity currentElement;
  final _CodegenImpact worldImpact;

  CodegenRegistry(this.currentElement)
      : this.worldImpact = new _CodegenImpact();

  bool get isForResolution => false;

  String toString() => 'CodegenRegistry for $currentElement';

  @deprecated
  void registerInstantiatedClass(ClassElement element) {
    registerInstantiation(element.rawType);
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

  void registerInstantiatedClosure(LocalFunctionElement element) {
    worldImpact.registerStaticUse(new StaticUse.closure(element));
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
}

/// [WorkItem] used exclusively by the [CodegenEnqueuer].
abstract class CodegenWorkItem extends WorkItem {
  CodegenRegistry get registry;
}
