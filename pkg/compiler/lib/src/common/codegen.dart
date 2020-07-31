// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.codegen;

import 'package:js_ast/src/precedence.dart' as js show PRIMARY;

import '../common.dart';
import '../common_elements.dart';
import '../constants/values.dart';
import '../deferred_load.dart';
import '../elements/entities.dart';
import '../elements/types.dart' show DartType, InterfaceType;
import '../inferrer/abstract_value_domain.dart';
import '../inferrer/types.dart';
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/backend.dart';
import '../js_backend/namer.dart';
import '../js_backend/string_reference.dart' show StringReference;
import '../js_backend/type_reference.dart' show TypeReference;
import '../js_emitter/code_emitter_task.dart' show Emitter;
import '../js_model/type_recipe.dart' show TypeRecipe;
import '../native/behavior.dart';
import '../serialization/serialization.dart';
import '../ssa/ssa.dart';
import '../universe/feature.dart';
import '../universe/selector.dart';
import '../universe/use.dart' show ConstantUse, DynamicUse, StaticUse, TypeUse;
import '../universe/world_impact.dart'
    show WorldImpact, WorldImpactBuilderImpl, WorldImpactVisitor;
import '../util/enumset.dart';
import '../util/util.dart';
import '../world.dart';

class CodegenImpact extends WorldImpact {
  const CodegenImpact();

  factory CodegenImpact.readFromDataSource(DataSource source) =
      _CodegenImpact.readFromDataSource;

  void writeToDataSink(DataSink sink) {
    throw new UnsupportedError('CodegenImpact.writeToDataSink');
  }

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

  Iterable<Selector> get oneShotInterceptors => const [];
}

class _CodegenImpact extends WorldImpactBuilderImpl implements CodegenImpact {
  static const String tag = 'codegen-impact';

  @override
  final MemberEntity member;
  Set<Pair<DartType, DartType>> _typeVariableBoundsSubtypeChecks;
  Set<String> _constSymbols;
  List<Set<ClassEntity>> _specializedGetInterceptors;
  bool _usesInterceptor = false;
  EnumSet<AsyncMarker> _asyncMarkers;
  Set<GenericInstantiation> _genericInstantiations;
  List<NativeBehavior> _nativeBehaviors;
  Set<FunctionEntity> _nativeMethods;
  Set<Selector> _oneShotInterceptors;

  _CodegenImpact(this.member);

  _CodegenImpact.internal(
      this.member,
      Set<DynamicUse> dynamicUses,
      Set<StaticUse> staticUses,
      Set<TypeUse> typeUses,
      Set<ConstantUse> constantUses,
      this._typeVariableBoundsSubtypeChecks,
      this._constSymbols,
      this._specializedGetInterceptors,
      this._usesInterceptor,
      this._asyncMarkers,
      this._genericInstantiations,
      this._nativeBehaviors,
      this._nativeMethods,
      this._oneShotInterceptors)
      : super.internal(dynamicUses, staticUses, typeUses, constantUses);

  factory _CodegenImpact.readFromDataSource(DataSource source) {
    source.begin(tag);
    MemberEntity member = source.readMember();
    Set<DynamicUse> dynamicUses = source
        .readList(() => DynamicUse.readFromDataSource(source),
            emptyAsNull: true)
        ?.toSet();
    Set<StaticUse> staticUses = source
        .readList(() => StaticUse.readFromDataSource(source), emptyAsNull: true)
        ?.toSet();
    Set<TypeUse> typeUses = source
        .readList(() => TypeUse.readFromDataSource(source), emptyAsNull: true)
        ?.toSet();
    Set<ConstantUse> constantUses = source
        .readList(() => ConstantUse.readFromDataSource(source),
            emptyAsNull: true)
        ?.toSet();
    Set<Pair<DartType, DartType>> typeVariableBoundsSubtypeChecks =
        source.readList(() {
      return new Pair(source.readDartType(), source.readDartType());
    }, emptyAsNull: true)?.toSet();
    Set<String> constSymbols = source.readStrings(emptyAsNull: true)?.toSet();
    List<Set<ClassEntity>> specializedGetInterceptors = source.readList(() {
      return source.readClasses().toSet();
    }, emptyAsNull: true);
    bool usesInterceptor = source.readBool();
    int asyncMarkersValue = source.readIntOrNull();
    EnumSet<AsyncMarker> asyncMarkers = asyncMarkersValue != null
        ? new EnumSet.fromValue(asyncMarkersValue)
        : null;
    Set<GenericInstantiation> genericInstantiations = source
        .readList(() => GenericInstantiation.readFromDataSource(source),
            emptyAsNull: true)
        ?.toSet();
    List<NativeBehavior> nativeBehaviors = source.readList(
        () => NativeBehavior.readFromDataSource(source),
        emptyAsNull: true);
    Set<FunctionEntity> nativeMethods =
        source.readMembers<FunctionEntity>(emptyAsNull: true)?.toSet();
    Set<Selector> oneShotInterceptors = source
        .readList(() => Selector.readFromDataSource(source), emptyAsNull: true)
        ?.toSet();
    source.end(tag);
    return new _CodegenImpact.internal(
        member,
        dynamicUses,
        staticUses,
        typeUses,
        constantUses,
        typeVariableBoundsSubtypeChecks,
        constSymbols,
        specializedGetInterceptors,
        usesInterceptor,
        asyncMarkers,
        genericInstantiations,
        nativeBehaviors,
        nativeMethods,
        oneShotInterceptors);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeMember(member);
    sink.writeList(dynamicUses, (DynamicUse use) => use.writeToDataSink(sink),
        allowNull: true);
    sink.writeList(staticUses, (StaticUse use) => use.writeToDataSink(sink),
        allowNull: true);
    sink.writeList(typeUses, (TypeUse use) => use.writeToDataSink(sink),
        allowNull: true);
    sink.writeList(constantUses, (ConstantUse use) => use.writeToDataSink(sink),
        allowNull: true);
    sink.writeList<Pair<DartType, DartType>>(_typeVariableBoundsSubtypeChecks,
        (pair) {
      sink.writeDartType(pair.a);
      sink.writeDartType(pair.b);
    }, allowNull: true);
    sink.writeStrings(_constSymbols, allowNull: true);
    sink.writeList(_specializedGetInterceptors, sink.writeClasses,
        allowNull: true);
    sink.writeBool(_usesInterceptor);
    sink.writeIntOrNull(_asyncMarkers?.value);
    sink.writeList(
        _genericInstantiations,
        (GenericInstantiation instantiation) =>
            instantiation.writeToDataSink(sink),
        allowNull: true);
    sink.writeList(_nativeBehaviors,
        (NativeBehavior behavior) => behavior.writeToDataSink(sink),
        allowNull: true);
    sink.writeMembers(_nativeMethods, allowNull: true);
    sink.writeList(_oneShotInterceptors,
        (Selector selector) => selector.writeToDataSink(sink),
        allowNull: true);
    sink.end(tag);
  }

  @override
  void apply(WorldImpactVisitor visitor) {
    staticUses.forEach((StaticUse use) => visitor.visitStaticUse(member, use));
    dynamicUses.forEach((DynamicUse use) => visitor.visitDynamicUse);
    typeUses.forEach((TypeUse use) => visitor.visitTypeUse(member, use));
    constantUses
        .forEach((ConstantUse use) => visitor.visitConstantUse(member, use));
  }

  void registerTypeVariableBoundsSubtypeCheck(
      DartType subtype, DartType supertype) {
    _typeVariableBoundsSubtypeChecks ??= {};
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
    _constSymbols ??= {};
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
    _genericInstantiations ??= {};
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

  void registerOneShotInterceptor(Selector selector) {
    _oneShotInterceptors ??= {};
    _oneShotInterceptors.add(selector);
  }

  @override
  Iterable<Selector> get oneShotInterceptors {
    return _oneShotInterceptors ?? const [];
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('CodegenImpact:');
    WorldImpact.printOn(sb, this);

    void add(String title, Iterable iterable) {
      if (iterable.isNotEmpty) {
        sb.write('\n $title:');
        iterable.forEach((e) => sb.write('\n  $e'));
      }
    }

    add('typeVariableBoundsSubtypeChecks', typeVariableBoundsSubtypeChecks);
    add('constSymbols', constSymbols);
    add('specializedGetInterceptors', specializedGetInterceptors);
    if (usesInterceptor) {
      sb.write('\n usesInterceptor: true');
    }
    add('asyncMarkers', asyncMarkers);
    add('genericInstantiations', genericInstantiations);
    add('nativeBehaviors', nativeBehaviors);
    add('nativeMethods', nativeMethods);
    add('oneShotInterceptors', oneShotInterceptors);

    return sb.toString();
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
      : this._worldImpact = new _CodegenImpact(_currentElement);

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

  void registerOneShotInterceptor(Selector selector) {
    _worldImpact.registerOneShotInterceptor(selector);
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

/// Interface for reading the code generation results for all [MemberEntity]s.
abstract class CodegenResults {
  GlobalTypeInferenceResults get globalTypeInferenceResults;
  CodegenInputs get codegenInputs;
  CodegenResult getCodegenResults(MemberEntity member);
}

/// Code generation results computed on-demand.
///
/// This is used in the non-modular codegen enqueuer driving code generation.
class OnDemandCodegenResults extends CodegenResults {
  @override
  final GlobalTypeInferenceResults globalTypeInferenceResults;
  @override
  final CodegenInputs codegenInputs;
  final SsaFunctionCompiler _functionCompiler;

  OnDemandCodegenResults(this.globalTypeInferenceResults, this.codegenInputs,
      this._functionCompiler);

  @override
  CodegenResult getCodegenResults(MemberEntity member) {
    return _functionCompiler.compile(member);
  }
}

/// Deserialized code generation results.
///
/// This is used for modular code generation.
class DeserializedCodegenResults extends CodegenResults {
  @override
  final GlobalTypeInferenceResults globalTypeInferenceResults;
  @override
  final CodegenInputs codegenInputs;

  final Map<MemberEntity, CodegenResult> _map;

  DeserializedCodegenResults(
      this.globalTypeInferenceResults, this.codegenInputs, this._map);

  @override
  CodegenResult getCodegenResults(MemberEntity member) {
    CodegenResult result = _map[member];
    if (result == null) {
      failedAt(member,
          "No codegen results from $member (${identityHashCode(member)}).");
    }
    return result;
  }
}

/// The code generation result for a single [MemberEntity].
class CodegenResult {
  static const String tag = 'codegen-result';

  final js.Fun code;
  final CodegenImpact impact;
  final Iterable<ModularName> modularNames;
  final Iterable<ModularExpression> modularExpressions;

  CodegenResult(
      this.code, this.impact, this.modularNames, this.modularExpressions);

  /// Reads a [CodegenResult] object from [source].
  ///
  /// The [ModularName] and [ModularExpression] nodes read during
  /// deserialization are collected in [modularNames] and [modularExpressions]
  /// to avoid the need for visiting the [code] node post deserialization.
  factory CodegenResult.readFromDataSource(
      DataSource source,
      List<ModularName> modularNames,
      List<ModularExpression> modularExpressions) {
    source.begin(tag);
    js.Fun code = source.readJsNodeOrNull();
    CodegenImpact impact = CodegenImpact.readFromDataSource(source);
    source.end(tag);
    return new CodegenResult(code, impact, modularNames, modularExpressions);
  }

  /// Writes the [CodegenResult] object to [sink].
  ///
  /// The [modularNames] and [modularExpressions] fields are not directly
  /// serializes because these are embedded in the [code] node and collected
  /// through this during deserialization.
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeJsNodeOrNull(code);
    impact.writeToDataSink(sink);
    sink.end(tag);
  }

  void applyModularState(Namer namer, Emitter emitter) {
    for (ModularName name in modularNames) {
      switch (name.kind) {
        case ModularNameKind.rtiField:
          name.value = namer.rtiFieldJsName;
          break;
        case ModularNameKind.runtimeTypeName:
          name.value = namer.runtimeTypeName(name.data);
          break;
        case ModularNameKind.className:
          name.value = namer.className(name.data);
          break;
        case ModularNameKind.aliasedSuperMember:
          name.value = namer.aliasedSuperMemberPropertyName(name.data);
          break;
        case ModularNameKind.staticClosure:
          name.value = namer.staticClosureName(name.data);
          break;
        case ModularNameKind.methodProperty:
          name.value = namer.methodPropertyName(name.data);
          break;
        case ModularNameKind.operatorIs:
          name.value = namer.operatorIs(name.data);
          break;
        case ModularNameKind.operatorIsType:
          name.value = namer.operatorIsType(name.data);
          break;
        case ModularNameKind.substitution:
          name.value = namer.substitutionName(name.data);
          break;
        case ModularNameKind.instanceMethod:
          name.value = namer.instanceMethodName(name.data);
          break;
        case ModularNameKind.instanceField:
          name.value = namer.instanceFieldPropertyName(name.data);
          break;
        case ModularNameKind.invocation:
          name.value = namer.invocationName(name.data);
          break;
        case ModularNameKind.lazyInitializer:
          name.value = namer.lazyInitializerName(name.data);
          break;
        case ModularNameKind.globalPropertyNameForClass:
          name.value = namer.globalPropertyNameForClass(name.data);
          break;
        case ModularNameKind.globalPropertyNameForType:
          name.value = namer.globalPropertyNameForType(name.data);
          break;
        case ModularNameKind.globalPropertyNameForMember:
          name.value = namer.globalPropertyNameForMember(name.data);
          break;
        case ModularNameKind.globalNameForInterfaceTypeVariable:
          name.value = namer.globalNameForInterfaceTypeVariable(name.data);
          break;
        case ModularNameKind.nameForGetInterceptor:
          name.value = namer.nameForGetInterceptor(name.set);
          break;
        case ModularNameKind.nameForOneShotInterceptor:
          name.value = namer.nameForOneShotInterceptor(name.data, name.set);
          break;
        case ModularNameKind.asName:
          name.value = namer.asName(name.data);
          break;
      }
    }
    for (ModularExpression expression in modularExpressions) {
      switch (expression.kind) {
        case ModularExpressionKind.globalObjectForLibrary:
          expression.value = namer
              .readGlobalObjectForLibrary(expression.data)
              .withSourceInformation(expression.sourceInformation);
          break;
        case ModularExpressionKind.globalObjectForClass:
          expression.value = namer
              .readGlobalObjectForClass(expression.data)
              .withSourceInformation(expression.sourceInformation);
          break;
        case ModularExpressionKind.globalObjectForType:
          expression.value = namer
              .readGlobalObjectForType(expression.data)
              .withSourceInformation(expression.sourceInformation);
          break;
        case ModularExpressionKind.globalObjectForMember:
          expression.value = namer
              .readGlobalObjectForMember(expression.data)
              .withSourceInformation(expression.sourceInformation);
          break;
        case ModularExpressionKind.constant:
          expression.value = emitter
              .constantReference(expression.data)
              .withSourceInformation(expression.sourceInformation);
          break;
        case ModularExpressionKind.embeddedGlobalAccess:
          expression.value = emitter
              .generateEmbeddedGlobalAccess(expression.data)
              .withSourceInformation(expression.sourceInformation);
          break;
      }
    }
  }

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
  globalNameForInterfaceTypeVariable,
  nameForGetInterceptor,
  nameForOneShotInterceptor,
  asName,
}

class ModularName extends js.Name implements js.AstContainer {
  static const String tag = 'modular-name';

  final ModularNameKind kind;
  js.Name _value;
  final Object data;
  final Set<ClassEntity> set;

  ModularName(this.kind, {this.data, this.set});

  factory ModularName.readFromDataSource(DataSource source) {
    source.begin(tag);
    ModularNameKind kind = source.readEnum(ModularNameKind.values);
    Object data;
    Set<ClassEntity> set;
    switch (kind) {
      case ModularNameKind.rtiField:
        break;
      case ModularNameKind.globalPropertyNameForType:
      case ModularNameKind.runtimeTypeName:
      case ModularNameKind.className:
      case ModularNameKind.operatorIs:
      case ModularNameKind.substitution:
      case ModularNameKind.globalPropertyNameForClass:
        data = source.readClass();
        break;
      case ModularNameKind.aliasedSuperMember:
      case ModularNameKind.staticClosure:
      case ModularNameKind.methodProperty:
      case ModularNameKind.instanceField:
      case ModularNameKind.instanceMethod:
      case ModularNameKind.lazyInitializer:
      case ModularNameKind.globalPropertyNameForMember:
        data = source.readMember();
        break;
      case ModularNameKind.operatorIsType:
        data = source.readDartType();
        break;
      case ModularNameKind.invocation:
        data = Selector.readFromDataSource(source);
        break;
      case ModularNameKind.globalNameForInterfaceTypeVariable:
        data = source.readTypeVariable();
        break;
      case ModularNameKind.nameForGetInterceptor:
        set = source.readClasses().toSet();
        break;
      case ModularNameKind.nameForOneShotInterceptor:
        data = Selector.readFromDataSource(source);
        set = source.readClasses().toSet();
        break;
      case ModularNameKind.asName:
        data = source.readString();
        break;
    }
    source.end(tag);
    return new ModularName(kind, data: data, set: set);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeEnum(kind);
    switch (kind) {
      case ModularNameKind.rtiField:
        break;
      case ModularNameKind.globalPropertyNameForType:
      case ModularNameKind.runtimeTypeName:
      case ModularNameKind.className:
      case ModularNameKind.operatorIs:
      case ModularNameKind.substitution:
      case ModularNameKind.globalPropertyNameForClass:
        sink.writeClass(data);
        break;
      case ModularNameKind.aliasedSuperMember:
      case ModularNameKind.staticClosure:
      case ModularNameKind.methodProperty:
      case ModularNameKind.instanceField:
      case ModularNameKind.instanceMethod:
      case ModularNameKind.lazyInitializer:
      case ModularNameKind.globalPropertyNameForMember:
        sink.writeMember(data);
        break;
      case ModularNameKind.operatorIsType:
        sink.writeDartType(data);
        break;
      case ModularNameKind.invocation:
        Selector selector = data;
        selector.writeToDataSink(sink);
        break;
      case ModularNameKind.globalNameForInterfaceTypeVariable:
        TypeVariableEntity typeVariable = data;
        sink.writeTypeVariable(typeVariable);
        break;
      case ModularNameKind.nameForGetInterceptor:
        sink.writeClasses(set);
        break;
      case ModularNameKind.nameForOneShotInterceptor:
        Selector selector = data;
        selector.writeToDataSink(sink);
        sink.writeClasses(set);
        break;
      case ModularNameKind.asName:
        sink.writeString(data);
        break;
    }
    sink.end(tag);
  }

  js.Name get value {
    assert(_value != null, 'value not set for $this');
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
    assert(_value != null, 'value not set for $this');
    return _value.name;
  }

  @override
  bool get allowRename {
    assert(_value != null, 'value not set for $this');
    return _value.allowRename;
  }

  @override
  int compareTo(js.Name other) {
    assert(_value != null, 'value not set for $this');
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
  String toString() =>
      'ModularName(kind=$kind, data=$data, value=${_value?.key})';
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
  static const String tag = 'modular-expression';

  final ModularExpressionKind kind;
  final Object data;
  js.Expression _value;

  ModularExpression(this.kind, this.data);

  factory ModularExpression.readFromDataSource(DataSource source) {
    source.begin(tag);
    ModularExpressionKind kind = source.readEnum(ModularExpressionKind.values);
    Object data;
    switch (kind) {
      case ModularExpressionKind.globalObjectForLibrary:
        data = source.readLibrary();
        break;
      case ModularExpressionKind.globalObjectForClass:
        data = source.readClass();
        break;
      case ModularExpressionKind.globalObjectForType:
        data = source.readClass();
        break;
      case ModularExpressionKind.globalObjectForMember:
        data = source.readMember();
        break;
      case ModularExpressionKind.constant:
        data = source.readConstant();
        break;
      case ModularExpressionKind.embeddedGlobalAccess:
        data = source.readString();
        break;
    }
    source.end(tag);
    return new ModularExpression(kind, data);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeEnum(kind);
    switch (kind) {
      case ModularExpressionKind.globalObjectForLibrary:
        sink.writeLibrary(data);
        break;
      case ModularExpressionKind.globalObjectForClass:
        sink.writeClass(data);
        break;
      case ModularExpressionKind.globalObjectForType:
        sink.writeClass(data);
        break;
      case ModularExpressionKind.globalObjectForMember:
        sink.writeMember(data);
        break;
      case ModularExpressionKind.constant:
        sink.writeConstant(data);
        break;
      case ModularExpressionKind.embeddedGlobalAccess:
        sink.writeString(data);
        break;
    }
    sink.end(tag);
  }

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
      sb.write((data as ConstantValue).toStructuredText(null));
    } else {
      sb.write(data);
    }
    sb.write(',value=$_value)');
    return sb.toString();
  }
}

enum JsNodeKind {
  comment,
  await,
  regExpLiteral,
  property,
  objectInitializer,
  arrayHole,
  arrayInitializer,
  parentheses,
  modularName,
  asyncName,
  stringBackedName,
  stringConcatenation,
  literalNull,
  literalNumber,
  literalString,
  literalStringFromName,
  literalBool,
  modularExpression,
  function,
  namedFunction,
  access,
  parameter,
  variableDeclaration,
  thisExpression,
  variableUse,
  postfix,
  prefix,
  binary,
  callExpression,
  newExpression,
  conditional,
  variableInitialization,
  assignment,
  variableDeclarationList,
  literalExpression,
  dartYield,
  literalStatement,
  labeledStatement,
  functionDeclaration,
  switchDefault,
  switchCase,
  switchStatement,
  catchClause,
  tryStatement,
  throwStatement,
  returnStatement,
  breakStatement,
  continueStatement,
  doStatement,
  whileStatement,
  forInStatement,
  forStatement,
  ifStatement,
  emptyStatement,
  expressionStatement,
  block,
  program,
  stringReference,
  typeReference,
}

/// Tags used for debugging serialization/deserialization boundary mismatches.
class JsNodeTags {
  static const String tag = 'js-node';
  static const String comment = 'js-comment';
  static const String await = 'js-await';
  static const String regExpLiteral = 'js-regExpLiteral';
  static const String property = 'js-property';
  static const String objectInitializer = 'js-objectInitializer';
  static const String arrayHole = 'js-arrayHole';
  static const String arrayInitializer = 'js-arrayInitializer';
  static const String parentheses = 'js-parentheses';
  static const String modularName = 'js-modularName';
  static const String asyncName = 'js-asyncName';
  static const String stringBackedName = 'js-stringBackedName';
  static const String stringConcatenation = 'js-stringConcatenation';
  static const String literalNull = 'js-literalNull';
  static const String literalNumber = 'js-literalNumber';
  static const String literalString = 'js-literalString';
  static const String literalStringFromName = 'js-literalStringFromName';
  static const String literalBool = 'js-literalBool';
  static const String modularExpression = 'js-modularExpression';
  static const String function = 'js-function';
  static const String namedFunction = 'js-namedFunction';
  static const String access = 'js-access';
  static const String parameter = 'js-parameter';
  static const String variableDeclaration = 'js-variableDeclaration';
  static const String thisExpression = 'js-thisExpression';
  static const String variableUse = 'js-variableUse';
  static const String postfix = 'js-postfix';
  static const String prefix = 'js-prefix';
  static const String binary = 'js-binary';
  static const String callExpression = 'js-callExpression';
  static const String newExpression = 'js-newExpression';
  static const String conditional = 'js-conditional';
  static const String variableInitialization = 'js-variableInitialization';
  static const String assignment = 'js-assignment';
  static const String variableDeclarationList = 'js-variableDeclarationList';
  static const String literalExpression = 'js-literalExpression';
  static const String dartYield = 'js-dartYield';
  static const String literalStatement = 'js-literalStatement';
  static const String labeledStatement = 'js-labeledStatement';
  static const String functionDeclaration = 'js-functionDeclaration';
  static const String switchDefault = 'js-switchDefault';
  static const String switchCase = 'js-switchCase';
  static const String switchStatement = 'js-switchStatement';
  static const String catchClause = 'js-catchClause';
  static const String tryStatement = 'js-tryStatement';
  static const String throwStatement = 'js-throwStatement';
  static const String returnStatement = 'js-returnStatement';
  static const String breakStatement = 'js-breakStatement';
  static const String continueStatement = 'js-continueStatement';
  static const String doStatement = 'js-doStatement';
  static const String whileStatement = 'js-whileStatement';
  static const String forInStatement = 'js-forInStatement';
  static const String forStatement = 'js-forStatement';
  static const String ifStatement = 'js-ifStatement';
  static const String emptyStatement = 'js-emptyStatement';
  static const String expressionStatement = 'js-expressionStatement';
  static const String block = 'js-block';
  static const String program = 'js-program';
  static const String stringReference = 'js-stringReference';
  static const String typeReference = 'js-typeReference';
}

/// Visitor that serializes a [js.Node] into a [DataSink].
class JsNodeSerializer implements js.NodeVisitor<void> {
  final DataSink sink;

  JsNodeSerializer._(this.sink);

  static void writeToDataSink(DataSink sink, js.Node node) {
    sink.begin(JsNodeTags.tag);
    JsNodeSerializer serializer = new JsNodeSerializer._(sink);
    serializer.visit(node);
    sink.end(JsNodeTags.tag);
  }

  void visit(js.Node node, {bool allowNull: false}) {
    if (allowNull) {
      sink.writeBool(node != null);
      if (node != null) {
        node.accept(this);
      }
    } else {
      node.accept(this);
    }
  }

  void visitList(Iterable<js.Node> nodes) {
    sink.writeList(nodes, visit);
  }

  void _writeInfo(js.Node node) {
    sink.writeCached<SourceInformation>(node.sourceInformation,
        (SourceInformation sourceInformation) {
      SourceInformation.writeToDataSink(sink, sourceInformation);
    });
  }

  @override
  void visitInterpolatedDeclaration(js.InterpolatedDeclaration node) {
    throw new UnsupportedError('JsNodeSerializer.visitInterpolatedDeclaration');
  }

  @override
  void visitInterpolatedStatement(js.InterpolatedStatement node) {
    throw new UnsupportedError('JsNodeSerializer.visitInterpolatedStatement');
  }

  @override
  void visitInterpolatedSelector(js.InterpolatedSelector node) {
    throw new UnsupportedError('JsNodeSerializer.visitInterpolatedDeclaration');
  }

  @override
  void visitInterpolatedParameter(js.InterpolatedParameter node) {
    throw new UnsupportedError('JsNodeSerializer.visitInterpolatedParameter');
  }

  @override
  void visitInterpolatedLiteral(js.InterpolatedLiteral node) {
    throw new UnsupportedError('JsNodeSerializer.visitInterpolatedLiteral');
  }

  @override
  void visitInterpolatedExpression(js.InterpolatedExpression node) {
    throw new UnsupportedError('JsNodeSerializer.visitInterpolatedExpression');
  }

  @override
  void visitComment(js.Comment node) {
    sink.writeEnum(JsNodeKind.comment);
    sink.begin(JsNodeTags.comment);
    sink.writeString(node.comment);
    sink.end(JsNodeTags.comment);
    _writeInfo(node);
  }

  @override
  void visitAwait(js.Await node) {
    sink.writeEnum(JsNodeKind.await);
    sink.begin(JsNodeTags.await);
    visit(node.expression);
    sink.end(JsNodeTags.await);
    _writeInfo(node);
  }

  @override
  void visitRegExpLiteral(js.RegExpLiteral node) {
    sink.writeEnum(JsNodeKind.regExpLiteral);
    sink.begin(JsNodeTags.regExpLiteral);
    sink.writeString(node.pattern);
    sink.end(JsNodeTags.regExpLiteral);
    _writeInfo(node);
  }

  @override
  void visitProperty(js.Property node) {
    sink.writeEnum(JsNodeKind.property);
    sink.begin(JsNodeTags.property);
    visit(node.name);
    visit(node.value);
    sink.end(JsNodeTags.property);
    _writeInfo(node);
  }

  @override
  void visitObjectInitializer(js.ObjectInitializer node) {
    sink.writeEnum(JsNodeKind.objectInitializer);
    sink.begin(JsNodeTags.objectInitializer);
    visitList(node.properties);
    sink.writeBool(node.isOneLiner);
    sink.end(JsNodeTags.objectInitializer);
    _writeInfo(node);
  }

  @override
  void visitArrayHole(js.ArrayHole node) {
    sink.writeEnum(JsNodeKind.arrayHole);
    sink.begin(JsNodeTags.arrayHole);
    sink.end(JsNodeTags.arrayHole);
    _writeInfo(node);
  }

  @override
  void visitArrayInitializer(js.ArrayInitializer node) {
    sink.writeEnum(JsNodeKind.arrayInitializer);
    sink.begin(JsNodeTags.arrayInitializer);
    visitList(node.elements);
    sink.end(JsNodeTags.arrayInitializer);
    _writeInfo(node);
  }

  @override
  void visitParentheses(js.Parentheses node) {
    sink.writeEnum(JsNodeKind.parentheses);
    sink.begin(JsNodeTags.parentheses);
    visit(node.enclosed);
    sink.end(JsNodeTags.parentheses);
    _writeInfo(node);
  }

  @override
  void visitName(js.Name node) {
    if (node is ModularName) {
      sink.writeEnum(JsNodeKind.modularName);
      sink.begin(JsNodeTags.modularName);
      node.writeToDataSink(sink);
      sink.end(JsNodeTags.modularName);
      _writeInfo(node);
    } else if (node is AsyncName) {
      sink.writeEnum(JsNodeKind.asyncName);
      sink.begin(JsNodeTags.asyncName);
      visit(node.prefix);
      visit(node.base);
      sink.end(JsNodeTags.asyncName);
      _writeInfo(node);
    } else if (node is StringBackedName) {
      sink.writeEnum(JsNodeKind.stringBackedName);
      sink.begin(JsNodeTags.stringBackedName);
      sink.writeString(node.name);
      sink.end(JsNodeTags.stringBackedName);
      _writeInfo(node);
    } else {
      throw new UnsupportedError(
          'Unexpected deferred expression: ${node.runtimeType}.');
    }
  }

  @override
  void visitStringConcatenation(js.StringConcatenation node) {
    sink.writeEnum(JsNodeKind.stringConcatenation);
    sink.begin(JsNodeTags.stringConcatenation);
    visitList(node.parts);
    sink.end(JsNodeTags.stringConcatenation);
    _writeInfo(node);
  }

  @override
  void visitLiteralNull(js.LiteralNull node) {
    sink.writeEnum(JsNodeKind.literalNull);
    sink.begin(JsNodeTags.literalNull);
    sink.end(JsNodeTags.literalNull);
    _writeInfo(node);
  }

  @override
  void visitLiteralNumber(js.LiteralNumber node) {
    sink.writeEnum(JsNodeKind.literalNumber);
    sink.begin(JsNodeTags.literalNumber);
    sink.writeString(node.value);
    sink.end(JsNodeTags.literalNumber);
    _writeInfo(node);
  }

  @override
  void visitLiteralString(js.LiteralString node) {
    if (node is js.LiteralStringFromName) {
      sink.writeEnum(JsNodeKind.literalStringFromName);
      sink.begin(JsNodeTags.literalStringFromName);
      visit(node.name);
      sink.end(JsNodeTags.literalStringFromName);
    } else {
      sink.writeEnum(JsNodeKind.literalString);
      sink.begin(JsNodeTags.literalString);
      sink.writeString(node.value);
      sink.end(JsNodeTags.literalString);
    }
    _writeInfo(node);
  }

  @override
  void visitLiteralBool(js.LiteralBool node) {
    sink.writeEnum(JsNodeKind.literalBool);
    sink.begin(JsNodeTags.literalBool);
    sink.writeBool(node.value);
    sink.end(JsNodeTags.literalBool);
    _writeInfo(node);
  }

  @override
  void visitDeferredString(js.DeferredString node) {
    throw new UnsupportedError('JsNodeSerializer.visitDeferredString');
  }

  @override
  void visitDeferredNumber(js.DeferredNumber node) {
    throw new UnsupportedError('JsNodeSerializer.visitDeferredNumber');
  }

  @override
  void visitDeferredExpression(js.DeferredExpression node) {
    if (node is ModularExpression) {
      sink.writeEnum(JsNodeKind.modularExpression);
      sink.begin(JsNodeTags.modularExpression);
      node.writeToDataSink(sink);
      sink.end(JsNodeTags.modularExpression);
      _writeInfo(node);
    } else if (node is TypeReference) {
      sink.writeEnum(JsNodeKind.typeReference);
      sink.begin(JsNodeTags.typeReference);
      node.writeToDataSink(sink);
      sink.end(JsNodeTags.typeReference);
      _writeInfo(node);
    } else if (node is StringReference) {
      sink.writeEnum(JsNodeKind.stringReference);
      sink.begin(JsNodeTags.stringReference);
      node.writeToDataSink(sink);
      sink.end(JsNodeTags.stringReference);
      _writeInfo(node);
    } else {
      throw new UnsupportedError(
          'Unexpected deferred expression: ${node.runtimeType}.');
    }
  }

  @override
  void visitFun(js.Fun node) {
    sink.writeEnum(JsNodeKind.function);
    sink.begin(JsNodeTags.function);
    visitList(node.params);
    visit(node.body);
    sink.writeEnum(node.asyncModifier);
    sink.end(JsNodeTags.function);
    _writeInfo(node);
  }

  @override
  void visitNamedFunction(js.NamedFunction node) {
    sink.writeEnum(JsNodeKind.namedFunction);
    sink.begin(JsNodeTags.namedFunction);
    visit(node.name);
    visit(node.function);
    sink.end(JsNodeTags.namedFunction);
    _writeInfo(node);
  }

  @override
  void visitAccess(js.PropertyAccess node) {
    sink.writeEnum(JsNodeKind.access);
    sink.begin(JsNodeTags.access);
    visit(node.receiver);
    visit(node.selector);
    sink.end(JsNodeTags.access);
    _writeInfo(node);
  }

  @override
  void visitParameter(js.Parameter node) {
    sink.writeEnum(JsNodeKind.parameter);
    sink.begin(JsNodeTags.parameter);
    sink.writeString(node.name);
    sink.end(JsNodeTags.parameter);
    _writeInfo(node);
  }

  @override
  void visitVariableDeclaration(js.VariableDeclaration node) {
    sink.writeEnum(JsNodeKind.variableDeclaration);
    sink.begin(JsNodeTags.variableDeclaration);
    sink.writeString(node.name);
    sink.writeBool(node.allowRename);
    sink.end(JsNodeTags.variableDeclaration);
    _writeInfo(node);
  }

  @override
  void visitThis(js.This node) {
    sink.writeEnum(JsNodeKind.thisExpression);
    sink.begin(JsNodeTags.thisExpression);
    sink.end(JsNodeTags.thisExpression);
    _writeInfo(node);
  }

  @override
  void visitVariableUse(js.VariableUse node) {
    sink.writeEnum(JsNodeKind.variableUse);
    sink.begin(JsNodeTags.variableUse);
    sink.writeString(node.name);
    sink.end(JsNodeTags.variableUse);
    _writeInfo(node);
  }

  @override
  void visitPostfix(js.Postfix node) {
    sink.writeEnum(JsNodeKind.postfix);
    sink.begin(JsNodeTags.postfix);
    sink.writeString(node.op);
    visit(node.argument);
    sink.end(JsNodeTags.postfix);
    _writeInfo(node);
  }

  @override
  void visitPrefix(js.Prefix node) {
    sink.writeEnum(JsNodeKind.prefix);
    sink.begin(JsNodeTags.prefix);
    sink.writeString(node.op);
    visit(node.argument);
    sink.end(JsNodeTags.prefix);
    _writeInfo(node);
  }

  @override
  void visitBinary(js.Binary node) {
    sink.writeEnum(JsNodeKind.binary);
    sink.begin(JsNodeTags.binary);
    sink.writeString(node.op);
    visit(node.left);
    visit(node.right);
    sink.end(JsNodeTags.binary);
    _writeInfo(node);
  }

  @override
  void visitCall(js.Call node) {
    sink.writeEnum(JsNodeKind.callExpression);
    sink.begin(JsNodeTags.callExpression);
    visit(node.target);
    visitList(node.arguments);
    sink.end(JsNodeTags.callExpression);
    _writeInfo(node);
  }

  @override
  void visitNew(js.New node) {
    sink.writeEnum(JsNodeKind.newExpression);
    sink.begin(JsNodeTags.newExpression);
    visit(node.target);
    visitList(node.arguments);
    sink.end(JsNodeTags.newExpression);
    _writeInfo(node);
  }

  @override
  void visitConditional(js.Conditional node) {
    sink.writeEnum(JsNodeKind.conditional);
    sink.begin(JsNodeTags.conditional);
    visit(node.condition);
    visit(node.then);
    visit(node.otherwise);
    sink.end(JsNodeTags.conditional);
    _writeInfo(node);
  }

  @override
  void visitVariableInitialization(js.VariableInitialization node) {
    sink.writeEnum(JsNodeKind.variableInitialization);
    sink.begin(JsNodeTags.variableInitialization);
    visit(node.declaration);
    visit(node.value, allowNull: true);
    sink.end(JsNodeTags.variableInitialization);
    _writeInfo(node);
  }

  @override
  void visitAssignment(js.Assignment node) {
    sink.writeEnum(JsNodeKind.assignment);
    sink.begin(JsNodeTags.assignment);
    visit(node.leftHandSide);
    sink.writeStringOrNull(node.op);
    visit(node.value);
    sink.end(JsNodeTags.assignment);
    _writeInfo(node);
  }

  @override
  void visitVariableDeclarationList(js.VariableDeclarationList node) {
    sink.writeEnum(JsNodeKind.variableDeclarationList);
    sink.begin(JsNodeTags.variableDeclarationList);
    visitList(node.declarations);
    sink.writeBool(node.indentSplits);
    sink.end(JsNodeTags.variableDeclarationList);
    _writeInfo(node);
  }

  @override
  void visitLiteralExpression(js.LiteralExpression node) {
    sink.writeEnum(JsNodeKind.literalExpression);
    sink.begin(JsNodeTags.literalExpression);
    sink.writeString(node.template);
    visitList(node.inputs);
    sink.end(JsNodeTags.literalExpression);
    _writeInfo(node);
  }

  @override
  void visitDartYield(js.DartYield node) {
    sink.writeEnum(JsNodeKind.dartYield);
    sink.begin(JsNodeTags.dartYield);
    visit(node.expression);
    sink.writeBool(node.hasStar);
    sink.end(JsNodeTags.dartYield);
    _writeInfo(node);
  }

  @override
  void visitLiteralStatement(js.LiteralStatement node) {
    sink.writeEnum(JsNodeKind.literalStatement);
    sink.begin(JsNodeTags.literalStatement);
    sink.writeString(node.code);
    sink.end(JsNodeTags.literalStatement);
    _writeInfo(node);
  }

  @override
  void visitLabeledStatement(js.LabeledStatement node) {
    sink.writeEnum(JsNodeKind.labeledStatement);
    sink.begin(JsNodeTags.labeledStatement);
    sink.writeString(node.label);
    visit(node.body);
    sink.end(JsNodeTags.labeledStatement);
    _writeInfo(node);
  }

  @override
  void visitFunctionDeclaration(js.FunctionDeclaration node) {
    sink.writeEnum(JsNodeKind.functionDeclaration);
    sink.begin(JsNodeTags.functionDeclaration);
    visit(node.name);
    visit(node.function);
    sink.end(JsNodeTags.functionDeclaration);
    _writeInfo(node);
  }

  @override
  void visitDefault(js.Default node) {
    sink.writeEnum(JsNodeKind.switchDefault);
    sink.begin(JsNodeTags.switchDefault);
    visit(node.body);
    sink.end(JsNodeTags.switchDefault);
    _writeInfo(node);
  }

  @override
  void visitCase(js.Case node) {
    sink.writeEnum(JsNodeKind.switchCase);
    sink.begin(JsNodeTags.switchCase);
    visit(node.expression);
    visit(node.body);
    sink.end(JsNodeTags.switchCase);
    _writeInfo(node);
  }

  @override
  void visitSwitch(js.Switch node) {
    sink.writeEnum(JsNodeKind.switchStatement);
    sink.begin(JsNodeTags.switchStatement);
    visit(node.key);
    visitList(node.cases);
    sink.end(JsNodeTags.switchStatement);
    _writeInfo(node);
  }

  @override
  void visitCatch(js.Catch node) {
    sink.writeEnum(JsNodeKind.catchClause);
    sink.begin(JsNodeTags.catchClause);
    visit(node.declaration);
    visit(node.body);
    sink.end(JsNodeTags.catchClause);
    _writeInfo(node);
  }

  @override
  void visitTry(js.Try node) {
    sink.writeEnum(JsNodeKind.tryStatement);
    sink.begin(JsNodeTags.tryStatement);
    visit(node.body);
    visit(node.catchPart, allowNull: true);
    visit(node.finallyPart, allowNull: true);
    sink.end(JsNodeTags.tryStatement);
    _writeInfo(node);
  }

  @override
  void visitThrow(js.Throw node) {
    sink.writeEnum(JsNodeKind.throwStatement);
    sink.begin(JsNodeTags.throwStatement);
    visit(node.expression);
    sink.end(JsNodeTags.throwStatement);
    _writeInfo(node);
  }

  @override
  void visitReturn(js.Return node) {
    sink.writeEnum(JsNodeKind.returnStatement);
    sink.begin(JsNodeTags.returnStatement);
    visit(node.value, allowNull: true);
    sink.end(JsNodeTags.returnStatement);
    _writeInfo(node);
  }

  @override
  void visitBreak(js.Break node) {
    sink.writeEnum(JsNodeKind.breakStatement);
    sink.begin(JsNodeTags.breakStatement);
    sink.writeStringOrNull(node.targetLabel);
    sink.end(JsNodeTags.breakStatement);
    _writeInfo(node);
  }

  @override
  void visitContinue(js.Continue node) {
    sink.writeEnum(JsNodeKind.continueStatement);
    sink.begin(JsNodeTags.continueStatement);
    sink.writeStringOrNull(node.targetLabel);
    sink.end(JsNodeTags.continueStatement);
    _writeInfo(node);
  }

  @override
  void visitDo(js.Do node) {
    sink.writeEnum(JsNodeKind.doStatement);
    sink.begin(JsNodeTags.doStatement);
    visit(node.body);
    visit(node.condition);
    sink.end(JsNodeTags.doStatement);
    _writeInfo(node);
  }

  @override
  void visitWhile(js.While node) {
    sink.writeEnum(JsNodeKind.whileStatement);
    sink.begin(JsNodeTags.whileStatement);
    visit(node.condition);
    visit(node.body);
    sink.end(JsNodeTags.whileStatement);
    _writeInfo(node);
  }

  @override
  void visitForIn(js.ForIn node) {
    sink.writeEnum(JsNodeKind.forInStatement);
    sink.begin(JsNodeTags.forInStatement);
    visit(node.leftHandSide);
    visit(node.object);
    visit(node.body);
    sink.end(JsNodeTags.forInStatement);
    _writeInfo(node);
  }

  @override
  void visitFor(js.For node) {
    sink.writeEnum(JsNodeKind.forStatement);
    sink.begin(JsNodeTags.forStatement);
    visit(node.init, allowNull: true);
    visit(node.condition, allowNull: true);
    visit(node.update, allowNull: true);
    visit(node.body);
    sink.end(JsNodeTags.forStatement);
    _writeInfo(node);
  }

  @override
  void visitIf(js.If node) {
    sink.writeEnum(JsNodeKind.ifStatement);
    sink.begin(JsNodeTags.ifStatement);
    visit(node.condition);
    visit(node.then);
    visit(node.otherwise);
    sink.end(JsNodeTags.ifStatement);
    _writeInfo(node);
  }

  @override
  void visitEmptyStatement(js.EmptyStatement node) {
    sink.writeEnum(JsNodeKind.emptyStatement);
    sink.begin(JsNodeTags.emptyStatement);
    sink.end(JsNodeTags.emptyStatement);
    _writeInfo(node);
  }

  @override
  void visitExpressionStatement(js.ExpressionStatement node) {
    sink.writeEnum(JsNodeKind.expressionStatement);
    sink.begin(JsNodeTags.expressionStatement);
    visit(node.expression);
    sink.end(JsNodeTags.expressionStatement);
    _writeInfo(node);
  }

  @override
  void visitBlock(js.Block node) {
    sink.writeEnum(JsNodeKind.block);
    sink.begin(JsNodeTags.block);
    visitList(node.statements);
    sink.end(JsNodeTags.block);
    _writeInfo(node);
  }

  @override
  void visitProgram(js.Program node) {
    sink.writeEnum(JsNodeKind.program);
    sink.begin(JsNodeTags.program);
    visitList(node.body);
    sink.end(JsNodeTags.program);
    _writeInfo(node);
  }
}

/// Helper class that deserializes a [js.Node] from [DataSource].
///
/// Deserialized [ModularName]s and [ModularExpression]s are collected in the
/// [modularNames] and [modularExpressions] lists.
class JsNodeDeserializer {
  final DataSource source;
  final List<ModularName> modularNames;
  final List<ModularExpression> modularExpressions;

  JsNodeDeserializer._(this.source, this.modularNames, this.modularExpressions);

  static js.Node readFromDataSource(
      DataSource source,
      List<ModularName> modularNames,
      List<ModularExpression> modularExpressions) {
    source.begin(JsNodeTags.tag);
    JsNodeDeserializer deserializer =
        new JsNodeDeserializer._(source, modularNames, modularExpressions);
    js.Node node = deserializer.read();
    source.end(JsNodeTags.tag);
    return node;
  }

  T read<T extends js.Node>({bool allowNull: false}) {
    if (allowNull) {
      bool hasValue = source.readBool();
      if (!hasValue) return null;
    }
    JsNodeKind kind = source.readEnum(JsNodeKind.values);
    js.Node node;
    switch (kind) {
      case JsNodeKind.comment:
        source.begin(JsNodeTags.comment);
        node = new js.Comment(source.readString());
        source.end(JsNodeTags.comment);
        break;
      case JsNodeKind.await:
        source.begin(JsNodeTags.await);
        node = new js.Await(read());
        source.end(JsNodeTags.await);
        break;
      case JsNodeKind.regExpLiteral:
        source.begin(JsNodeTags.regExpLiteral);
        node = new js.RegExpLiteral(source.readString());
        source.end(JsNodeTags.regExpLiteral);
        break;
      case JsNodeKind.property:
        source.begin(JsNodeTags.property);
        js.Expression name = read();
        js.Expression value = read();
        node = new js.Property(name, value);
        source.end(JsNodeTags.property);
        break;
      case JsNodeKind.objectInitializer:
        source.begin(JsNodeTags.objectInitializer);
        List<js.Property> properties = readList();
        bool isOneLiner = source.readBool();
        node = new js.ObjectInitializer(properties, isOneLiner: isOneLiner);
        source.end(JsNodeTags.objectInitializer);
        break;
      case JsNodeKind.arrayHole:
        source.begin(JsNodeTags.arrayHole);
        node = new js.ArrayHole();
        source.end(JsNodeTags.arrayHole);
        break;
      case JsNodeKind.arrayInitializer:
        source.begin(JsNodeTags.arrayInitializer);
        List<js.Expression> elements = readList();
        node = new js.ArrayInitializer(elements);
        source.end(JsNodeTags.arrayInitializer);
        break;
      case JsNodeKind.parentheses:
        source.begin(JsNodeTags.parentheses);
        node = new js.Parentheses(read());
        source.end(JsNodeTags.parentheses);
        break;
      case JsNodeKind.modularName:
        source.begin(JsNodeTags.modularName);
        ModularName modularName = ModularName.readFromDataSource(source);
        modularNames.add(modularName);
        node = modularName;
        source.end(JsNodeTags.modularName);
        break;
      case JsNodeKind.asyncName:
        source.begin(JsNodeTags.asyncName);
        js.Name prefix = read();
        js.Name base = read();
        node = new AsyncName(prefix, base);
        source.end(JsNodeTags.asyncName);
        break;
      case JsNodeKind.stringBackedName:
        source.begin(JsNodeTags.stringBackedName);
        node = new StringBackedName(source.readString());
        source.end(JsNodeTags.stringBackedName);
        break;
      case JsNodeKind.stringConcatenation:
        source.begin(JsNodeTags.stringConcatenation);
        List<js.Literal> parts = readList();
        node = new js.StringConcatenation(parts);
        source.end(JsNodeTags.stringConcatenation);
        break;
      case JsNodeKind.literalNull:
        source.begin(JsNodeTags.literalNull);
        node = new js.LiteralNull();
        source.end(JsNodeTags.literalNull);
        break;
      case JsNodeKind.literalNumber:
        source.begin(JsNodeTags.literalNumber);
        node = new js.LiteralNumber(source.readString());
        source.end(JsNodeTags.literalNumber);
        break;
      case JsNodeKind.literalString:
        source.begin(JsNodeTags.literalString);
        node = new js.LiteralString(source.readString());
        source.end(JsNodeTags.literalString);
        break;
      case JsNodeKind.literalStringFromName:
        source.begin(JsNodeTags.literalStringFromName);
        js.Name name = read();
        node = new js.LiteralStringFromName(name);
        source.end(JsNodeTags.literalStringFromName);
        break;
      case JsNodeKind.literalBool:
        source.begin(JsNodeTags.literalBool);
        node = new js.LiteralBool(source.readBool());
        source.end(JsNodeTags.literalBool);
        break;
      case JsNodeKind.modularExpression:
        source.begin(JsNodeTags.modularExpression);
        ModularExpression modularExpression =
            ModularExpression.readFromDataSource(source);
        modularExpressions.add(modularExpression);
        node = modularExpression;
        source.end(JsNodeTags.modularExpression);
        break;
      case JsNodeKind.function:
        source.begin(JsNodeTags.function);
        List<js.Parameter> params = readList();
        js.Block body = read();
        js.AsyncModifier asyncModifier =
            source.readEnum(js.AsyncModifier.values);
        node = new js.Fun(params, body, asyncModifier: asyncModifier);
        source.end(JsNodeTags.function);
        break;
      case JsNodeKind.namedFunction:
        source.begin(JsNodeTags.namedFunction);
        js.Declaration name = read();
        js.Fun function = read();
        node = new js.NamedFunction(name, function);
        source.end(JsNodeTags.namedFunction);
        break;
      case JsNodeKind.access:
        source.begin(JsNodeTags.access);
        js.Expression receiver = read();
        js.Expression selector = read();
        node = new js.PropertyAccess(receiver, selector);
        source.end(JsNodeTags.access);
        break;
      case JsNodeKind.parameter:
        source.begin(JsNodeTags.parameter);
        node = new js.Parameter(source.readString());
        source.end(JsNodeTags.parameter);
        break;
      case JsNodeKind.variableDeclaration:
        source.begin(JsNodeTags.variableDeclaration);
        String name = source.readString();
        bool allowRename = source.readBool();
        node = new js.VariableDeclaration(name, allowRename: allowRename);
        source.end(JsNodeTags.variableDeclaration);
        break;
      case JsNodeKind.thisExpression:
        source.begin(JsNodeTags.thisExpression);
        node = new js.This();
        source.end(JsNodeTags.thisExpression);
        break;
      case JsNodeKind.variableUse:
        source.begin(JsNodeTags.variableUse);
        node = new js.VariableUse(source.readString());
        source.end(JsNodeTags.variableUse);
        break;
      case JsNodeKind.postfix:
        source.begin(JsNodeTags.postfix);
        String op = source.readString();
        js.Expression argument = read();
        node = new js.Postfix(op, argument);
        source.end(JsNodeTags.postfix);
        break;
      case JsNodeKind.prefix:
        source.begin(JsNodeTags.prefix);
        String op = source.readString();
        js.Expression argument = read();
        node = new js.Prefix(op, argument);
        source.end(JsNodeTags.prefix);
        break;
      case JsNodeKind.binary:
        source.begin(JsNodeTags.binary);
        String op = source.readString();
        js.Expression left = read();
        js.Expression right = read();
        node = new js.Binary(op, left, right);
        source.end(JsNodeTags.binary);
        break;
      case JsNodeKind.callExpression:
        source.begin(JsNodeTags.callExpression);
        js.Expression target = read();
        List<js.Expression> arguments = readList();
        node = new js.Call(target, arguments);
        source.end(JsNodeTags.callExpression);
        break;
      case JsNodeKind.newExpression:
        source.begin(JsNodeTags.newExpression);
        js.Expression cls = read();
        List<js.Expression> arguments = readList();
        node = new js.New(cls, arguments);
        source.end(JsNodeTags.newExpression);
        break;
      case JsNodeKind.conditional:
        source.begin(JsNodeTags.conditional);
        js.Expression condition = read();
        js.Expression then = read();
        js.Expression otherwise = read();
        node = new js.Conditional(condition, then, otherwise);
        source.end(JsNodeTags.conditional);
        break;
      case JsNodeKind.variableInitialization:
        source.begin(JsNodeTags.variableInitialization);
        js.Declaration declaration = read();
        js.Expression value = source.readValueOrNull(read);
        node = new js.VariableInitialization(declaration, value);
        source.end(JsNodeTags.variableInitialization);
        break;
      case JsNodeKind.assignment:
        source.begin(JsNodeTags.assignment);
        js.Expression leftHandSide = read();
        String op = source.readStringOrNull();
        js.Expression value = read();
        node = new js.Assignment.compound(leftHandSide, op, value);
        source.end(JsNodeTags.assignment);
        break;
      case JsNodeKind.variableDeclarationList:
        source.begin(JsNodeTags.variableDeclarationList);
        List<js.VariableInitialization> declarations = readList();
        bool indentSplits = source.readBool();
        node = new js.VariableDeclarationList(declarations,
            indentSplits: indentSplits);
        source.end(JsNodeTags.variableDeclarationList);
        break;
      case JsNodeKind.literalExpression:
        source.begin(JsNodeTags.literalExpression);
        String template = source.readString();
        List<js.Expression> inputs = readList();
        node = new js.LiteralExpression.withData(template, inputs);
        source.end(JsNodeTags.literalExpression);
        break;
      case JsNodeKind.dartYield:
        source.begin(JsNodeTags.dartYield);
        js.Expression expression = read();
        bool hasStar = source.readBool();
        node = new js.DartYield(expression, hasStar);
        source.end(JsNodeTags.dartYield);
        break;
      case JsNodeKind.literalStatement:
        source.begin(JsNodeTags.literalStatement);
        node = new js.LiteralStatement(source.readString());
        source.end(JsNodeTags.literalStatement);
        break;
      case JsNodeKind.labeledStatement:
        source.begin(JsNodeTags.labeledStatement);
        String label = source.readString();
        js.Statement body = read();
        node = new js.LabeledStatement(label, body);
        source.end(JsNodeTags.labeledStatement);
        break;
      case JsNodeKind.functionDeclaration:
        source.begin(JsNodeTags.functionDeclaration);
        js.Declaration name = read();
        js.Fun function = read();
        node = new js.FunctionDeclaration(name, function);
        source.end(JsNodeTags.functionDeclaration);
        break;
      case JsNodeKind.switchDefault:
        source.begin(JsNodeTags.switchDefault);
        js.Block body = read();
        node = new js.Default(body);
        source.end(JsNodeTags.switchDefault);
        break;
      case JsNodeKind.switchCase:
        source.begin(JsNodeTags.switchCase);
        js.Expression expression = read();
        js.Block body = read();
        node = new js.Case(expression, body);
        source.end(JsNodeTags.switchCase);
        break;
      case JsNodeKind.switchStatement:
        source.begin(JsNodeTags.switchStatement);
        js.Expression key = read();
        List<js.SwitchClause> cases = readList();
        node = new js.Switch(key, cases);
        source.end(JsNodeTags.switchStatement);
        break;
      case JsNodeKind.catchClause:
        source.begin(JsNodeTags.catchClause);
        js.Declaration declaration = read();
        js.Block body = read();
        node = new js.Catch(declaration, body);
        source.end(JsNodeTags.catchClause);
        break;
      case JsNodeKind.tryStatement:
        source.begin(JsNodeTags.tryStatement);
        js.Block body = read();
        js.Catch catchPart = source.readValueOrNull(read);
        js.Block finallyPart = source.readValueOrNull(read);
        node = new js.Try(body, catchPart, finallyPart);
        source.end(JsNodeTags.tryStatement);
        break;
      case JsNodeKind.throwStatement:
        source.begin(JsNodeTags.throwStatement);
        js.Expression expression = read();
        node = new js.Throw(expression);
        source.end(JsNodeTags.throwStatement);
        break;
      case JsNodeKind.returnStatement:
        source.begin(JsNodeTags.returnStatement);
        js.Expression value = source.readValueOrNull(read);
        node = new js.Return(value);
        source.end(JsNodeTags.returnStatement);
        break;
      case JsNodeKind.breakStatement:
        source.begin(JsNodeTags.breakStatement);
        String targetLabel = source.readStringOrNull();
        node = new js.Break(targetLabel);
        source.end(JsNodeTags.breakStatement);
        break;
      case JsNodeKind.continueStatement:
        source.begin(JsNodeTags.continueStatement);
        String targetLabel = source.readStringOrNull();
        node = new js.Continue(targetLabel);
        source.end(JsNodeTags.continueStatement);
        break;
      case JsNodeKind.doStatement:
        source.begin(JsNodeTags.doStatement);
        js.Statement body = read();
        js.Expression condition = read();
        node = new js.Do(body, condition);
        source.end(JsNodeTags.doStatement);
        break;
      case JsNodeKind.whileStatement:
        source.begin(JsNodeTags.whileStatement);
        js.Expression condition = read();
        js.Statement body = read();
        node = new js.While(condition, body);
        source.end(JsNodeTags.whileStatement);
        break;
      case JsNodeKind.forInStatement:
        source.begin(JsNodeTags.forInStatement);
        js.Expression leftHandSide = read();
        js.Expression object = read();
        js.Statement body = read();
        node = new js.ForIn(leftHandSide, object, body);
        source.end(JsNodeTags.forInStatement);
        break;
      case JsNodeKind.forStatement:
        source.begin(JsNodeTags.forStatement);
        js.Expression init = read(allowNull: true);
        js.Expression condition = read(allowNull: true);
        js.Expression update = read(allowNull: true);
        js.Statement body = read();
        node = new js.For(init, condition, update, body);
        source.end(JsNodeTags.forStatement);
        break;
      case JsNodeKind.ifStatement:
        source.begin(JsNodeTags.ifStatement);
        js.Expression condition = read();
        js.Statement then = read();
        js.Statement otherwise = read();
        node = new js.If(condition, then, otherwise);
        source.end(JsNodeTags.ifStatement);
        break;
      case JsNodeKind.emptyStatement:
        source.begin(JsNodeTags.emptyStatement);
        node = new js.EmptyStatement();
        source.end(JsNodeTags.emptyStatement);
        break;
      case JsNodeKind.expressionStatement:
        source.begin(JsNodeTags.expressionStatement);
        node = new js.ExpressionStatement(read());
        source.end(JsNodeTags.expressionStatement);
        break;
      case JsNodeKind.block:
        source.begin(JsNodeTags.block);
        List<js.Statement> statements = readList();
        node = new js.Block(statements);
        source.end(JsNodeTags.block);
        break;
      case JsNodeKind.program:
        source.begin(JsNodeTags.program);
        List<js.Statement> body = readList();
        node = new js.Program(body);
        source.end(JsNodeTags.program);
        break;
      case JsNodeKind.stringReference:
        source.begin(JsNodeTags.stringReference);
        node = StringReference.readFromDataSource(source);
        source.end(JsNodeTags.stringReference);
        break;
      case JsNodeKind.typeReference:
        source.begin(JsNodeTags.typeReference);
        node = TypeReference.readFromDataSource(source);
        source.end(JsNodeTags.typeReference);
        break;
    }
    SourceInformation sourceInformation =
        source.readCached<SourceInformation>(() {
      return SourceInformation.readFromDataSource(source);
    });
    if (sourceInformation != null) {
      node = node.withSourceInformation(sourceInformation);
    }
    return node;
  }

  List<T> readList<T extends js.Node>({bool emptyAsNull: false}) {
    return source.readList(read, emptyAsNull: emptyAsNull);
  }
}

class CodegenReaderImpl implements CodegenReader {
  final JClosedWorld closedWorld;
  final List<ModularName> modularNames;
  final List<ModularExpression> modularExpressions;

  CodegenReaderImpl(
      this.closedWorld, this.modularNames, this.modularExpressions);

  @override
  AbstractValue readAbstractValue(DataSource source) {
    return closedWorld.abstractValueDomain
        .readAbstractValueFromDataSource(source);
  }

  @override
  js.Node readJsNode(DataSource source) {
    return JsNodeDeserializer.readFromDataSource(
        source, modularNames, modularExpressions);
  }

  @override
  OutputUnit readOutputUnitReference(DataSource source) {
    return closedWorld.outputUnitData.outputUnits[source.readInt()];
  }

  @override
  TypeRecipe readTypeRecipe(DataSource source) {
    return TypeRecipe.readFromDataSource(source);
  }
}

class CodegenWriterImpl implements CodegenWriter {
  final JClosedWorld closedWorld;

  CodegenWriterImpl(this.closedWorld);

  @override
  void writeAbstractValue(DataSink sink, AbstractValue value) {
    closedWorld.abstractValueDomain.writeAbstractValueToDataSink(sink, value);
  }

  @override
  void writeJsNode(DataSink sink, js.Node node) {
    JsNodeSerializer.writeToDataSink(sink, node);
  }

  @override
  void writeOutputUnitReference(DataSink sink, OutputUnit value) {
    sink.writeInt(closedWorld.outputUnitData.outputUnits.indexOf(value));
  }

  @override
  void writeTypeRecipe(DataSink sink, TypeRecipe recipe) {
    recipe.writeToDataSink(sink);
  }
}
