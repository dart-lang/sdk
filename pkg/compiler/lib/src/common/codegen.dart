// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.codegen;

import '../common.dart';
import '../elements/resolution_types.dart'
    show ResolutionDartType, ResolutionInterfaceType;
import '../elements/elements.dart'
    show
        ClassElement,
        Element,
        FunctionElement,
        LocalFunctionElement,
        MemberElement,
        ResolvedAst;
import '../elements/entities.dart';
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../universe/use.dart' show ConstantUse, DynamicUse, StaticUse, TypeUse;
import '../universe/world_impact.dart'
    show WorldImpact, WorldImpactBuilderImpl, WorldImpactVisitor;
import '../util/util.dart' show Pair, Setlet;
import 'work.dart' show WorkItem;

class CodegenImpact extends WorldImpact {
  const CodegenImpact();

  Iterable<Pair<ResolutionDartType, ResolutionDartType>>
      get typeVariableBoundsSubtypeChecks {
    return const <Pair<ResolutionDartType, ResolutionDartType>>[];
  }

  Iterable<String> get constSymbols => const <String>[];

  Iterable<Set<ClassEntity>> get specializedGetInterceptors {
    return const <Set<ClassEntity>>[];
  }

  bool get usesInterceptor => false;

  Iterable<Element> get asyncMarkers => const <FunctionElement>[];
}

class _CodegenImpact extends WorldImpactBuilderImpl implements CodegenImpact {
  Setlet<Pair<ResolutionDartType, ResolutionDartType>>
      _typeVariableBoundsSubtypeChecks;
  Setlet<String> _constSymbols;
  List<Set<ClassEntity>> _specializedGetInterceptors;
  bool _usesInterceptor = false;
  Setlet<FunctionElement> _asyncMarkers;

  _CodegenImpact();

  void apply(WorldImpactVisitor visitor) {
    staticUses.forEach(visitor.visitStaticUse);
    dynamicUses.forEach(visitor.visitDynamicUse);
    typeUses.forEach(visitor.visitTypeUse);
  }

  void registerTypeVariableBoundsSubtypeCheck(
      ResolutionDartType subtype, ResolutionDartType supertype) {
    if (_typeVariableBoundsSubtypeChecks == null) {
      _typeVariableBoundsSubtypeChecks =
          new Setlet<Pair<ResolutionDartType, ResolutionDartType>>();
    }
    _typeVariableBoundsSubtypeChecks.add(
        new Pair<ResolutionDartType, ResolutionDartType>(subtype, supertype));
  }

  Iterable<Pair<ResolutionDartType, ResolutionDartType>>
      get typeVariableBoundsSubtypeChecks {
    return _typeVariableBoundsSubtypeChecks != null
        ? _typeVariableBoundsSubtypeChecks
        : const <Pair<ResolutionDartType, ResolutionDartType>>[];
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

  void registerAsyncMarker(FunctionElement element) {
    if (_asyncMarkers == null) {
      _asyncMarkers = new Setlet<FunctionElement>();
    }
    _asyncMarkers.add(element);
  }

  Iterable<Element> get asyncMarkers {
    return _asyncMarkers != null ? _asyncMarkers : const <FunctionElement>[];
  }
}

// TODO(johnniwinther): Split this class into interface and implementation.
// TODO(johnniwinther): Move this implementation to the JS backend.
class CodegenRegistry {
  final MemberElement currentElement;
  final _CodegenImpact worldImpact;

  CodegenRegistry(MemberElement currentElement)
      : this.currentElement = currentElement,
        this.worldImpact = new _CodegenImpact();

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
      ResolutionDartType subtype, ResolutionDartType supertype) {
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

  void registerInstantiation(ResolutionInterfaceType type) {
    registerTypeUse(new TypeUse.instantiation(type));
  }

  void registerAsyncMarker(FunctionElement element) {
    worldImpact.registerAsyncMarker(element);
  }
}

/// [WorkItem] used exclusively by the [CodegenEnqueuer].
class CodegenWorkItem extends WorkItem {
  CodegenRegistry registry;
  final ResolvedAst resolvedAst;
  final JavaScriptBackend backend;

  factory CodegenWorkItem(JavaScriptBackend backend, MemberElement element) {
    // If this assertion fails, the resolution callbacks of the backend may be
    // missing call of form registry.registerXXX. Alternatively, the code
    // generation could spuriously be adding dependencies on things we know we
    // don't need.
    assert(invariant(element, element.hasResolvedAst,
        message: "$element has no resolved ast."));
    ResolvedAst resolvedAst = element.resolvedAst;
    return new CodegenWorkItem.internal(resolvedAst, backend);
  }

  CodegenWorkItem.internal(ResolvedAst resolvedAst, this.backend)
      : this.resolvedAst = resolvedAst;

  MemberElement get element => resolvedAst.element;

  WorldImpact run() {
    registry = new CodegenRegistry(element);
    return backend.codegen(this);
  }

  String toString() => 'CodegenWorkItem(${resolvedAst.element})';
}
