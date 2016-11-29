// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.codegen;

import '../common.dart';
import '../common/backend_api.dart' show Backend;
import '../constants/values.dart' show ConstantValue;
import '../dart_types.dart' show DartType, InterfaceType;
import '../elements/elements.dart'
    show
        AstElement,
        ClassElement,
        Element,
        FunctionElement,
        LocalFunctionElement,
        ResolvedAst;
import '../enqueue.dart' show Enqueuer;
import '../universe/use.dart' show DynamicUse, StaticUse, TypeUse;
import '../universe/world_impact.dart'
    show WorldImpact, WorldImpactBuilderImpl, WorldImpactVisitor;
import '../util/util.dart' show Pair, Setlet;
import 'work.dart' show WorkItem;

class CodegenImpact extends WorldImpact {
  const CodegenImpact();

  Iterable<ConstantValue> get compileTimeConstants => const <ConstantValue>[];

  Iterable<Pair<DartType, DartType>> get typeVariableBoundsSubtypeChecks {
    return const <Pair<DartType, DartType>>[];
  }

  Iterable<String> get constSymbols => const <String>[];

  Iterable<Set<ClassElement>> get specializedGetInterceptors {
    return const <Set<ClassElement>>[];
  }

  bool get usesInterceptor => false;

  Iterable<ClassElement> get typeConstants => const <ClassElement>[];

  Iterable<Element> get asyncMarkers => const <FunctionElement>[];
}

class _CodegenImpact extends WorldImpactBuilderImpl implements CodegenImpact {
  Setlet<ConstantValue> _compileTimeConstants;
  Setlet<Pair<DartType, DartType>> _typeVariableBoundsSubtypeChecks;
  Setlet<String> _constSymbols;
  List<Set<ClassElement>> _specializedGetInterceptors;
  bool _usesInterceptor = false;
  Setlet<ClassElement> _typeConstants;
  Setlet<FunctionElement> _asyncMarkers;

  _CodegenImpact();

  void apply(WorldImpactVisitor visitor) {
    staticUses.forEach(visitor.visitStaticUse);
    dynamicUses.forEach(visitor.visitDynamicUse);
    typeUses.forEach(visitor.visitTypeUse);
  }

  void registerCompileTimeConstant(ConstantValue constant) {
    if (_compileTimeConstants == null) {
      _compileTimeConstants = new Setlet<ConstantValue>();
    }
    _compileTimeConstants.add(constant);
  }

  Iterable<ConstantValue> get compileTimeConstants {
    return _compileTimeConstants != null
        ? _compileTimeConstants
        : const <ConstantValue>[];
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

  void registerSpecializedGetInterceptor(Set<ClassElement> classes) {
    if (_specializedGetInterceptors == null) {
      _specializedGetInterceptors = <Set<ClassElement>>[];
    }
    _specializedGetInterceptors.add(classes);
  }

  Iterable<Set<ClassElement>> get specializedGetInterceptors {
    return _specializedGetInterceptors != null
        ? _specializedGetInterceptors
        : const <Set<ClassElement>>[];
  }

  void registerUseInterceptor() {
    _usesInterceptor = true;
  }

  bool get usesInterceptor => _usesInterceptor;

  void registerTypeConstant(ClassElement element) {
    if (_typeConstants == null) {
      _typeConstants = new Setlet<ClassElement>();
    }
    _typeConstants.add(element);
  }

  Iterable<ClassElement> get typeConstants {
    return _typeConstants != null ? _typeConstants : const <ClassElement>[];
  }

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
  final Element currentElement;
  final _CodegenImpact worldImpact;

  CodegenRegistry(AstElement currentElement)
      : this.currentElement = currentElement,
        this.worldImpact = new _CodegenImpact();

  bool get isForResolution => false;

  String toString() => 'CodegenRegistry for $currentElement';

  /// Add the uses in [impact] to the impact of this registry.
  void addImpact(WorldImpact impact) {
    worldImpact.addImpact(impact);
  }

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

  void registerCompileTimeConstant(ConstantValue constant) {
    worldImpact.registerCompileTimeConstant(constant);
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

  void registerSpecializedGetInterceptor(Set<ClassElement> classes) {
    worldImpact.registerSpecializedGetInterceptor(classes);
  }

  void registerUseInterceptor() {
    worldImpact.registerUseInterceptor();
  }

  void registerTypeConstant(ClassElement element) {
    worldImpact.registerTypeConstant(element);
  }

  void registerInstantiation(InterfaceType type) {
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
  final Backend backend;

  factory CodegenWorkItem(Backend backend, AstElement element) {
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
      : this.resolvedAst = resolvedAst,
        super(resolvedAst.element);

  WorldImpact run() {
    registry = new CodegenRegistry(element);
    return backend.codegen(this);
  }

  String toString() => 'CodegenWorkItem(${resolvedAst.element})';
}
