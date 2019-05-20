// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.codegen;

import 'package:js_ast/src/precedence.dart' as js show PRIMARY;

import '../common_elements.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart' show DartType, InterfaceType;
import '../js/js.dart' as js;
import '../native/behavior.dart';
import '../universe/feature.dart';
import '../universe/use.dart' show ConstantUse, DynamicUse, StaticUse, TypeUse;
import '../universe/world_impact.dart'
    show WorldImpact, WorldImpactBuilderImpl, WorldImpactVisitor;
import '../util/enumset.dart';
import '../util/util.dart';

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
  final MemberEntity _currentElement;
  final _CodegenImpact _worldImpact;
  List<ModularName> _names;
  List<ModularExpression> _expressions;

  CodegenRegistry(this._elementEnvironment, this._currentElement)
      : this._worldImpact = new _CodegenImpact();

  @override
  String toString() => 'CodegenRegistry for $_currentElement';

  @deprecated
  void registerInstantiatedClass(ClassEntity element) {
    registerInstantiation(_elementEnvironment.getRawType(element));
  }

  void registerStaticUse(StaticUse staticUse) {
    _worldImpact.registerStaticUse(staticUse);
  }

  void registerDynamicUse(DynamicUse dynamicUse) {
    _worldImpact.registerDynamicUse(dynamicUse);
  }

  void registerTypeUse(TypeUse typeUse) {
    _worldImpact.registerTypeUse(typeUse);
  }

  void registerConstantUse(ConstantUse constantUse) {
    _worldImpact.registerConstantUse(constantUse);
  }

  void registerTypeVariableBoundsSubtypeCheck(
      DartType subtype, DartType supertype) {
    _worldImpact.registerTypeVariableBoundsSubtypeCheck(subtype, supertype);
  }

  void registerInstantiatedClosure(FunctionEntity element) {
    _worldImpact.registerStaticUse(new StaticUse.callMethod(element));
  }

  void registerConstSymbol(String name) {
    _worldImpact.registerConstSymbol(name);
  }

  void registerSpecializedGetInterceptor(Set<ClassEntity> classes) {
    _worldImpact.registerSpecializedGetInterceptor(classes);
  }

  void registerUseInterceptor() {
    _worldImpact.registerUseInterceptor();
  }

  void registerInstantiation(InterfaceType type) {
    registerTypeUse(new TypeUse.instantiation(type));
  }

  void registerAsyncMarker(AsyncMarker asyncMarker) {
    _worldImpact.registerAsyncMarker(asyncMarker);
  }

  void registerGenericInstantiation(GenericInstantiation instantiation) {
    _worldImpact.registerGenericInstantiation(instantiation);
  }

  void registerNativeBehavior(NativeBehavior nativeBehavior) {
    _worldImpact.registerNativeBehavior(nativeBehavior);
  }

  void registerNativeMethod(FunctionEntity function) {
    _worldImpact.registerNativeMethod(function);
  }

  void registerModularName(ModularName name) {
    _names ??= [];
    _names.add(name);
  }

  void registerModularExpression(ModularExpression expression) {
    _expressions ??= [];
    _expressions.add(expression);
  }

  CodegenResult close(js.Fun code) {
    return new CodegenResult(
        code, _worldImpact, _names ?? const [], _expressions ?? const []);
  }
}

class CodegenResult {
  final js.Fun code;
  final CodegenImpact impact;
  final Iterable<ModularName> modularNames;
  final Iterable<ModularExpression> modularExpressions;

  CodegenResult(
      this.code, this.impact, this.modularNames, this.modularExpressions);

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('CodegenResult(code=');
    sb.write(code != null ? js.DebugPrint(code) : '<null>,');
    sb.write('impact=$impact,');
    sb.write('modularNames=$modularNames,');
    sb.write('modularExpressions=$modularExpressions');
    sb.write(')');
    return sb.toString();
  }
}

enum ModularNameKind {
  rtiField,
  runtimeTypeName,
  className,
  aliasedSuperMember,
  staticClosure,
  methodProperty,
  operatorIs,
  operatorIsType,
  substitution,
  instanceMethod,
  instanceField,
  invocation,
  lazyInitializer,
  globalPropertyNameForClass,
  globalPropertyNameForType,
  globalPropertyNameForMember,
  nameForGetInterceptor,
  nameForGetOneShotInterceptor,
  asName,
}

class ModularName extends js.Name implements js.AstContainer {
  final ModularNameKind kind;
  js.Name _value;
  final Object data;
  final Set<ClassEntity> set;

  ModularName(this.kind, {this.data, this.set});

  js.Name get value {
    assert(_value != null);
    return _value;
  }

  void set value(js.Name node) {
    assert(_value == null);
    assert(node != null);
    _value = node.withSourceInformation(sourceInformation);
  }

  @override
  String get key {
    assert(_value != null);
    return _value.key;
  }

  @override
  String get name {
    assert(_value != null);
    return _value.name;
  }

  @override
  bool get allowRename {
    assert(_value != null);
    return _value.allowRename;
  }

  @override
  int compareTo(js.Name other) {
    assert(_value != null);
    return _value.compareTo(other);
  }

  @override
  Iterable<js.Node> get containedNodes {
    return _value != null ? [_value] : const [];
  }

  @override
  int get hashCode {
    return Hashing.setHash(set, Hashing.objectsHash(kind, data));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModularName &&
        kind == other.kind &&
        data == other.data &&
        equalSets(set, other.set);
  }

  @override
  String toString() => 'ModularName(kind=$kind,data=$data,value=$value)';
}

enum ModularExpressionKind {
  globalObjectForLibrary,
  globalObjectForClass,
  globalObjectForType,
  globalObjectForMember,
  constant,
  embeddedGlobalAccess,
}

class ModularExpression extends js.DeferredExpression
    implements js.AstContainer {
  final ModularExpressionKind kind;
  final Object data;
  js.Expression _value;

  ModularExpression(this.kind, this.data);

  @override
  js.Expression get value {
    assert(_value != null);
    return _value;
  }

  void set value(js.Expression node) {
    assert(_value == null);
    assert(node != null);
    _value = node.withSourceInformation(sourceInformation);
  }

  @override
  int get precedenceLevel => _value?.precedenceLevel ?? js.PRIMARY;

  @override
  Iterable<js.Node> get containedNodes {
    return _value != null ? [_value] : const [];
  }

  @override
  int get hashCode {
    return Hashing.objectsHash(kind, data);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModularExpression &&
        kind == other.kind &&
        data == other.data;
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('ModularExpression(kind=$kind,data=');
    if (data is ConstantValue) {
      sb.write((data as ConstantValue).toStructuredText());
    } else {
      sb.write(data);
    }
    sb.write(',value=$_value)');
    return sb.toString();
  }
}
