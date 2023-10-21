// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.codegen;

import 'package:js_ast/src/precedence.dart' as js show PRIMARY;

import '../common/elements.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart' show DartType, InterfaceType;
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/backend.dart';
import '../js_backend/codegen_inputs.dart';
import '../js_backend/namer.dart'
    show AsyncName, Namer, operatorNameToIdentifier, StringBackedName;
import '../js_backend/deferred_holder_expression.dart'
    show DeferredHolderExpression;
import '../js_backend/string_reference.dart' show StringReference;
import '../js_backend/type_reference.dart' show TypeReference;
import '../js_emitter/js_emitter.dart' show Emitter;
import '../js_model/elements.dart';
import '../native/behavior.dart';
import '../serialization/serialization.dart';
import '../universe/feature.dart';
import '../universe/resource_identifier.dart' show ResourceIdentifier;
import '../universe/selector.dart';
import '../universe/use.dart' show ConstantUse, DynamicUse, StaticUse, TypeUse;
import '../universe/world_impact.dart' show WorldImpact, WorldImpactBuilderImpl;
import '../util/enumset.dart';
import '../util/util.dart';

class CodegenImpact extends WorldImpact {
  const CodegenImpact();

  factory CodegenImpact.readFromDataSource(DataSourceReader source) =
      _CodegenImpact.readFromDataSource;

  void writeToDataSink(DataSinkWriter sink) {
    throw UnsupportedError('CodegenImpact.writeToDataSink');
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
  Set<Pair<DartType, DartType>>? _typeVariableBoundsSubtypeChecks;
  Set<String>? _constSymbols;
  List<Set<ClassEntity>>? _specializedGetInterceptors;
  bool _usesInterceptor = false;
  EnumSet<AsyncMarker>? _asyncMarkers;
  Set<GenericInstantiation>? _genericInstantiations;
  List<NativeBehavior>? _nativeBehaviors;
  Set<FunctionEntity>? _nativeMethods;
  Set<Selector>? _oneShotInterceptors;

  _CodegenImpact(this.member);

  _CodegenImpact.internal(
      this.member,
      Set<DynamicUse>? dynamicUses,
      Set<StaticUse>? staticUses,
      Set<TypeUse>? typeUses,
      Set<ConstantUse>? constantUses,
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

  factory _CodegenImpact.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    MemberEntity member = source.readMember();
    final dynamicUses = source
        .readListOrNull(() => DynamicUse.readFromDataSource(source))
        ?.toSet();
    final staticUses = source
        .readListOrNull(() => StaticUse.readFromDataSource(source))
        ?.toSet();
    final typeUses = source
        .readListOrNull(() => TypeUse.readFromDataSource(source))
        ?.toSet();
    final constantUses = source
        .readListOrNull(() => ConstantUse.readFromDataSource(source))
        ?.toSet();
    final typeVariableBoundsSubtypeChecks = source.readListOrNull(() {
      return Pair(source.readDartType(), source.readDartType());
    })?.toSet();
    final constSymbols = source.readStrings(emptyAsNull: true)?.toSet();
    final specializedGetInterceptors = source.readListOrNull(() {
      return source.readClasses().toSet();
    });
    bool usesInterceptor = source.readBool();
    final asyncMarkersValue = source.readIntOrNull();
    final asyncMarkers = asyncMarkersValue != null
        ? EnumSet<AsyncMarker>.fromValue(asyncMarkersValue)
        : null;
    final genericInstantiations = source
        .readListOrNull(() => GenericInstantiation.readFromDataSource(source))
        ?.toSet();
    final nativeBehaviors =
        source.readListOrNull(() => NativeBehavior.readFromDataSource(source));
    final nativeMethods = source.readMembersOrNull<FunctionEntity>()?.toSet();
    final oneShotInterceptors = source
        .readListOrNull(() => Selector.readFromDataSource(source))
        ?.toSet();
    source.end(tag);
    return _CodegenImpact.internal(
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
  void writeToDataSink(DataSinkWriter sink) {
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

  void registerTypeVariableBoundsSubtypeCheck(
      DartType subtype, DartType supertype) {
    (_typeVariableBoundsSubtypeChecks ??= {})
        .add(Pair<DartType, DartType>(subtype, supertype));
  }

  @override
  Iterable<Pair<DartType, DartType>> get typeVariableBoundsSubtypeChecks {
    return _typeVariableBoundsSubtypeChecks ?? const {};
  }

  void registerConstSymbol(String name) {
    (_constSymbols ??= {}).add(name);
  }

  @override
  Iterable<String> get constSymbols {
    return _constSymbols ?? const [];
  }

  void registerSpecializedGetInterceptor(Set<ClassEntity> classes) {
    (_specializedGetInterceptors ??= []).add(classes);
  }

  @override
  Iterable<Set<ClassEntity>> get specializedGetInterceptors {
    return _specializedGetInterceptors ?? const [];
  }

  void registerUseInterceptor() {
    _usesInterceptor = true;
  }

  @override
  bool get usesInterceptor => _usesInterceptor;

  void registerAsyncMarker(AsyncMarker asyncMarker) {
    (_asyncMarkers ??= EnumSet()).add(asyncMarker);
  }

  @override
  Iterable<AsyncMarker> get asyncMarkers {
    return _asyncMarkers == null
        ? const []
        : _asyncMarkers!.iterable(AsyncMarker.values);
  }

  void registerGenericInstantiation(GenericInstantiation instantiation) {
    (_genericInstantiations ??= {}).add(instantiation);
  }

  @override
  Iterable<GenericInstantiation> get genericInstantiations {
    return _genericInstantiations ?? const [];
  }

  void registerNativeBehavior(NativeBehavior nativeBehavior) {
    (_nativeBehaviors ??= []).add(nativeBehavior);
  }

  @override
  Iterable<NativeBehavior> get nativeBehaviors {
    return _nativeBehaviors ?? const [];
  }

  void registerNativeMethod(FunctionEntity function) {
    (_nativeMethods ??= {}).add(function);
  }

  @override
  Iterable<FunctionEntity> get nativeMethods {
    return _nativeMethods ?? const [];
  }

  void registerOneShotInterceptor(Selector selector) {
    (_oneShotInterceptors ??= {}).add(selector);
  }

  @override
  Iterable<Selector> get oneShotInterceptors {
    return _oneShotInterceptors ?? const [];
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
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
  late final List<ModularName> _names = [];
  late final List<ModularExpression> _expressions = [];

  CodegenRegistry(this._elementEnvironment, this._currentElement)
      : this._worldImpact = _CodegenImpact(_currentElement);

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
    _worldImpact.registerStaticUse(StaticUse.callMethod(element));
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
    registerTypeUse(TypeUse.instantiation(type));
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

  void registerModularName(covariant ModularName name) {
    _names.add(name);
  }

  void registerModularExpression(covariant ModularExpression expression) {
    _expressions.add(expression);
  }

  CodegenResult close(js.Fun? code) {
    return CodegenResult(
        code,
        _worldImpact,
        js.DeferredExpressionData(_names.isEmpty ? const [] : _names,
            _expressions.isEmpty ? const [] : _expressions));
  }
}

/// Code generation results computed on-demand.
///
/// This is used in the non-modular codegen enqueuer driving code generation.
class OnDemandCodegenResults extends CodegenResults {
  @override
  final CodegenInputs codegenInputs;
  final FunctionCompiler _functionCompiler;

  OnDemandCodegenResults(this.codegenInputs, this._functionCompiler);

  @override
  CodegenResult getCodegenResults(MemberEntity member) {
    return _functionCompiler.compile(member);
  }
}

/// The code generation result for a single [MemberEntity].
class CodegenResult {
  static const String tag = 'codegen-result';

  final js.Fun? code;
  final CodegenImpact impact;
  final js.DeferredExpressionData deferredExpressionData;

  CodegenResult(this.code, this.impact, this.deferredExpressionData);

  /// Reads a [CodegenResult] object from [source].
  factory CodegenResult.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    js.Fun? code = source.readJsNodeOrNull() as js.Fun?;
    CodegenImpact impact = CodegenImpact.readFromDataSource(source);
    final deferredExpressionData =
        js.DeferredExpressionRegistry.readDataFromDataSource(source);
    source.end(tag);
    if (code != null) {
      code = code.withAnnotation(deferredExpressionData) as js.Fun;
    }
    return CodegenResult(code, impact, deferredExpressionData);
  }

  /// Writes the [CodegenResult] object to [sink].
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    final registry = js.DeferredExpressionRegistry();
    sink.withDeferredExpressionRegistry(
        registry, () => sink.writeJsNodeOrNull(code));
    impact.writeToDataSink(sink);
    registry.writeToDataSink(sink);
    sink.end(tag);
  }

  void applyModularState(Namer namer, Emitter emitter) {
    final Set<ModularName> updated = Set.identity();
    for (ModularName name in deferredExpressionData.modularNames) {
      if (!updated.add(name)) continue;
      switch (name.kind) {
        case ModularNameKind.rtiField:
          name.value = namer.rtiFieldJsName;
          break;
        case ModularNameKind.className:
          name.value = namer.className(name.data as ClassEntity);
          break;
        case ModularNameKind.aliasedSuperMember:
          name.value =
              namer.aliasedSuperMemberPropertyName(name.data as MemberEntity);
          break;
        case ModularNameKind.staticClosure:
          name.value = namer.staticClosureName(name.data as FunctionEntity);
          break;
        case ModularNameKind.methodProperty:
          name.value = namer.methodPropertyName(name.data as FunctionEntity);
          break;
        case ModularNameKind.operatorIs:
          name.value = namer.operatorIs(name.data as ClassEntity);
          break;
        case ModularNameKind.instanceMethod:
          name.value = namer.instanceMethodName(name.data as FunctionEntity);
          break;
        case ModularNameKind.instanceField:
          name.value =
              namer.instanceFieldPropertyName(name.data as FieldEntity);
          break;
        case ModularNameKind.invocation:
          name.value = namer.invocationName(name.data as Selector);
          break;
        case ModularNameKind.lazyInitializer:
          name.value = namer.lazyInitializerName(name.data as FieldEntity);
          break;
        case ModularNameKind.globalPropertyNameForClass:
          name.value =
              namer.globalPropertyNameForClass(name.data as ClassEntity);
          break;
        case ModularNameKind.globalPropertyNameForMember:
          name.value =
              namer.globalPropertyNameForMember(name.data as MemberEntity);
          break;
        case ModularNameKind.globalNameForInterfaceTypeVariable:
          name.value = namer.globalNameForInterfaceTypeVariable(
              name.data as TypeVariableEntity);
          break;
        case ModularNameKind.nameForGetInterceptor:
          name.value = namer.nameForGetInterceptor(name.set!);
          break;
        case ModularNameKind.nameForOneShotInterceptor:
          name.value =
              namer.nameForOneShotInterceptor(name.data as Selector, name.set!);
          break;
        case ModularNameKind.asName:
          name.value = namer.asName(name.data as String);
          break;
      }
    }
    for (ModularExpression expression
        in deferredExpressionData.modularExpressions) {
      switch (expression.kind) {
        case ModularExpressionKind.constant:
          expression.value = emitter
              .constantReference(expression.data as ConstantValue)
              .withSourceInformation(expression.sourceInformation);
          break;
        case ModularExpressionKind.embeddedGlobalAccess:
          expression.value = emitter
              .generateEmbeddedGlobalAccess(expression.data as String)
              .withSourceInformation(expression.sourceInformation);
          break;
      }
    }
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write('CodegenResult(code=');
    sb.write(code != null ? js.DebugPrint(code!) : '<null>,');
    sb.write('impact=$impact,');
    sb.write('modularNames=${deferredExpressionData.modularNames},');
    sb.write('modularExpressions=${deferredExpressionData.modularExpressions}');
    sb.write(')');
    return sb.toString();
  }
}

enum ModularExpressionKind {
  constant,
  embeddedGlobalAccess,
}

class ModularExpression extends js.DeferredExpression
    implements js.AstContainer {
  static const String tag = 'modular-expression';

  final ModularExpressionKind kind;
  final Object data;
  js.Expression? _value;

  ModularExpression(this.kind, this.data);

  factory ModularExpression.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ModularExpressionKind kind = source.readEnum(ModularExpressionKind.values);
    Object data;
    switch (kind) {
      case ModularExpressionKind.constant:
        data = source.readConstant();
        break;
      case ModularExpressionKind.embeddedGlobalAccess:
        data = source.readString();
        break;
    }
    source.end(tag);
    return ModularExpression(kind, data);
  }

  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeEnum(kind);
    switch (kind) {
      case ModularExpressionKind.constant:
        sink.writeConstant(data as ConstantValue);
        break;
      case ModularExpressionKind.embeddedGlobalAccess:
        sink.writeString(data as String);
        break;
    }
    sink.end(tag);
  }

  @override
  bool get isFinalized => _value != null;

  @override
  js.Expression get value {
    return _value!;
  }

  void set value(js.Expression node) {
    assert(!isFinalized);
    _value = node.withSourceInformation(sourceInformation);
  }

  @override
  int get precedenceLevel => _value?.precedenceLevel ?? js.PRIMARY;

  @override
  Iterable<js.Node> get containedNodes {
    return _value != null ? [_value!] : const [];
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
    StringBuffer sb = StringBuffer();
    sb.write('ModularExpression(kind=$kind,data=');
    if (data is ConstantValue) {
      sb.write((data as ConstantValue).toStructuredText(null));
    } else {
      sb.write(data);
    }
    sb.write(',value=$_value)');
    return sb.toString();
  }

  @override
  String nonfinalizedDebugText() {
    switch (kind) {
      case ModularExpressionKind.constant:
        return 'ModularExpression"<constant>"';
      case ModularExpressionKind.embeddedGlobalAccess:
        return 'ModularExpression"init.$data"';
    }
  }
}

enum JsNodeKind {
  comment,
  await,
  regExpLiteral,
  property,
  methodDefinition,
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
  arrowFunction,
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
  deferredHolderExpression,
}

/// Tags used for debugging serialization/deserialization boundary mismatches.
class JsNodeTags {
  static const String tag = 'js-node';
  static const String comment = 'js-comment';
  static const String await = 'js-await';
  static const String regExpLiteral = 'js-regExpLiteral';
  static const String property = 'js-property';
  static const String methodDefinition = 'js-methodDefinition';
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
  static const String arrowFunction = 'js-arrowFunction';
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
  static const String deferredHolderExpression = 'js-deferredHolderExpression';
}

enum JsAnnotationKind {
  string,
  resourceIdentifier,
}

/// Visitor that serializes a [js.Node] into a [DataSinkWriter].
///
/// Collects deferred expressions into [deferredExpressionData] as it encounters
/// them in the AST.
class JsNodeSerializer implements js.NodeVisitor<void> {
  final DataSinkWriter sink;
  final js.DeferredExpressionRegistry? _registry;

  JsNodeSerializer._(this.sink, this._registry);

  static void writeToDataSink(DataSinkWriter sink, js.Node node,
      js.DeferredExpressionRegistry? registry) {
    sink.begin(JsNodeTags.tag);
    JsNodeSerializer serializer = JsNodeSerializer._(sink, registry);
    serializer.visit(node);
    sink.end(JsNodeTags.tag);
  }

  void visitOrNull(js.Node? node) {
    final isNotNull = node != null;
    sink.writeBool(isNotNull);
    if (isNotNull) {
      visit(node);
    }
  }

  void visit(js.Node node) {
    node.accept(this);
  }

  void visitList(Iterable<js.Node> nodes) {
    sink.writeList(nodes, visit);
  }

  void _writeInfo(js.Node node) {
    final sourceInformation = node.sourceInformation as SourceInformation?;
    final annotations = node.annotations;
    // Low bit encodes presence of `sourceInformation`, higher bits the number
    // of annotations.
    final infoCode =
        (sourceInformation == null ? 0 : 1) + 2 * annotations.length;
    sink.writeInt(infoCode);
    final hasSourceInformation = infoCode.isOdd;
    final annotationCount = infoCode ~/ 2;
    if (hasSourceInformation) {
      sink.writeCached<SourceInformation>(sourceInformation,
          (SourceInformation sourceInformation) {
        SourceInformation.writeToDataSink(sink, sourceInformation);
      });
    }
    for (int i = 0; i < annotationCount; i++) {
      _writeAnnotation(annotations[i]);
    }
  }

  void _writeAnnotation(Object annotation) {
    if (annotation is String) {
      sink.writeEnum(JsAnnotationKind.string);
      sink.writeString(annotation);
    } else if (annotation is ResourceIdentifier) {
      sink.writeEnum(JsAnnotationKind.resourceIdentifier);
      annotation.writeToDataSink(sink);
    } else {
      throw UnsupportedError(
          'JsNodeAnnotation ${annotation.runtimeType}: $annotation');
    }
  }

  @override
  void visitInterpolatedDeclaration(js.InterpolatedDeclaration node) {
    throw UnsupportedError('JsNodeSerializer.visitInterpolatedDeclaration');
  }

  @override
  void visitInterpolatedStatement(js.InterpolatedStatement node) {
    throw UnsupportedError('JsNodeSerializer.visitInterpolatedStatement');
  }

  @override
  void visitInterpolatedSelector(js.InterpolatedSelector node) {
    throw UnsupportedError('JsNodeSerializer.visitInterpolatedDeclaration');
  }

  @override
  void visitInterpolatedParameter(js.InterpolatedParameter node) {
    throw UnsupportedError('JsNodeSerializer.visitInterpolatedParameter');
  }

  @override
  void visitInterpolatedLiteral(js.InterpolatedLiteral node) {
    throw UnsupportedError('JsNodeSerializer.visitInterpolatedLiteral');
  }

  @override
  void visitInterpolatedExpression(js.InterpolatedExpression node) {
    throw UnsupportedError('JsNodeSerializer.visitInterpolatedExpression');
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
  void visitMethodDefinition(js.MethodDefinition node) {
    sink.writeEnum(JsNodeKind.methodDefinition);
    sink.begin(JsNodeTags.methodDefinition);
    visit(node.name);
    visit(node.function);
    sink.end(JsNodeTags.methodDefinition);
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
      sink.writeCached<ModularName>(node, (_) {
        node.writeToDataSink(sink);
        _writeInfo(node);
      }, identity: true);
      _registry?.registerModularName(node);
      sink.end(JsNodeTags.modularName);
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
      throw UnsupportedError(
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
    throw UnsupportedError('JsNodeSerializer.visitDeferredString');
  }

  @override
  void visitDeferredStatement(js.DeferredStatement node) {
    throw UnsupportedError('JsNodeSerializer.visitDeferredStatement');
  }

  @override
  void visitDeferredNumber(js.DeferredNumber node) {
    throw UnsupportedError('JsNodeSerializer.visitDeferredNumber');
  }

  @override
  void visitDeferredExpression(js.DeferredExpression node) {
    if (node is ModularExpression) {
      sink.writeEnum(JsNodeKind.modularExpression);
      sink.begin(JsNodeTags.modularExpression);
      sink.writeCached<ModularExpression>(node, (_) {
        node.writeToDataSink(sink);
        _writeInfo(node);
      }, identity: true);
      _registry?.registerModularExpression(node);
      sink.end(JsNodeTags.modularExpression);
    } else if (node is TypeReference) {
      sink.writeEnum(JsNodeKind.typeReference);
      sink.begin(JsNodeTags.typeReference);
      sink.writeCached<TypeReference>(node, (_) {
        node.writeToDataSink(sink);
        _writeInfo(node);
      }, identity: true);
      _registry?.registerTypeReference(node);
      sink.end(JsNodeTags.typeReference);
    } else if (node is StringReference) {
      sink.writeEnum(JsNodeKind.stringReference);
      sink.begin(JsNodeTags.stringReference);
      sink.writeCached<StringReference>(node, (_) {
        node.writeToDataSink(sink);
        _writeInfo(node);
      }, identity: true);
      _registry?.registerStringReference(node);
      sink.end(JsNodeTags.stringReference);
    } else if (node is DeferredHolderExpression) {
      sink.writeEnum(JsNodeKind.deferredHolderExpression);
      sink.begin(JsNodeTags.deferredHolderExpression);
      sink.writeCached<DeferredHolderExpression>(node, (_) {
        node.writeToDataSink(sink);
        _writeInfo(node);
      }, identity: true);
      _registry?.registerDeferredHolderExpression(node);
      sink.end(JsNodeTags.deferredHolderExpression);
    } else {
      throw UnsupportedError(
          'Unexpected deferred expression: ${node.runtimeType}.');
    }
  }

  @override
  void visitFun(js.Fun node) {
    sink.writeEnum(JsNodeKind.function);
    sink.begin(JsNodeTags.function);
    visitList(node.params);
    sink.writeDeferrable(
        () => sink.writeList(node.body.statements, sink.writeJsNode));
    sink.writeEnum(node.asyncModifier);
    sink.end(JsNodeTags.function);
    _writeInfo(node);
  }

  @override
  void visitArrowFunction(js.ArrowFunction node) {
    sink.writeEnum(JsNodeKind.arrowFunction);
    sink.begin(JsNodeTags.arrowFunction);
    visitList(node.params);
    visit(node.body);
    sink.writeEnum(node.asyncModifier);
    sink.end(JsNodeTags.arrowFunction);
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
    visitOrNull(node.value);
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
    visitOrNull(node.catchPart);
    visitOrNull(node.finallyPart);
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
    visitOrNull(node.value);
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
    visitOrNull(node.init);
    visitOrNull(node.condition);
    visitOrNull(node.update);
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

/// Helper class that deserializes a [js.Node] from [DataSourceReader].
class JsNodeDeserializer {
  final DataSourceReader source;

  JsNodeDeserializer._(this.source);

  static js.Node readFromDataSource(DataSourceReader source) {
    source.begin(JsNodeTags.tag);
    JsNodeDeserializer deserializer = JsNodeDeserializer._(source);
    js.Node node = deserializer.read();
    source.end(JsNodeTags.tag);
    return node;
  }

  T? readOrNull<T extends js.Node>() {
    bool hasValue = source.readBool();
    if (!hasValue) return null;
    return read();
  }

  static List<js.Statement> _readFunBodyStatements(DataSourceReader source) {
    return source.readList(() => source.readJsNode() as js.Statement);
  }

  T read<T extends js.Node>() {
    JsNodeKind kind = source.readEnum(JsNodeKind.values);
    js.Node node;
    bool needsInfo = true;
    switch (kind) {
      case JsNodeKind.comment:
        source.begin(JsNodeTags.comment);
        node = js.Comment(source.readString());
        source.end(JsNodeTags.comment);
        break;
      case JsNodeKind.await:
        source.begin(JsNodeTags.await);
        node = js.Await(read());
        source.end(JsNodeTags.await);
        break;
      case JsNodeKind.regExpLiteral:
        source.begin(JsNodeTags.regExpLiteral);
        node = js.RegExpLiteral(source.readString());
        source.end(JsNodeTags.regExpLiteral);
        break;
      case JsNodeKind.property:
        source.begin(JsNodeTags.property);
        js.Expression name = read();
        js.Expression value = read();
        node = js.Property(name, value);
        source.end(JsNodeTags.property);
        break;
      case JsNodeKind.methodDefinition:
        source.begin(JsNodeTags.methodDefinition);
        js.Expression name = read();
        final function = read() as js.Fun;
        node = js.MethodDefinition(name, function);
        source.end(JsNodeTags.methodDefinition);
        break;
      case JsNodeKind.objectInitializer:
        source.begin(JsNodeTags.objectInitializer);
        List<js.Property> properties = readList();
        bool isOneLiner = source.readBool();
        node = js.ObjectInitializer(properties, isOneLiner: isOneLiner);
        source.end(JsNodeTags.objectInitializer);
        break;
      case JsNodeKind.arrayHole:
        source.begin(JsNodeTags.arrayHole);
        node = js.ArrayHole();
        source.end(JsNodeTags.arrayHole);
        break;
      case JsNodeKind.arrayInitializer:
        source.begin(JsNodeTags.arrayInitializer);
        List<js.Expression> elements = readList();
        node = js.ArrayInitializer(elements);
        source.end(JsNodeTags.arrayInitializer);
        break;
      case JsNodeKind.parentheses:
        source.begin(JsNodeTags.parentheses);
        node = js.Parentheses(read());
        source.end(JsNodeTags.parentheses);
        break;
      case JsNodeKind.modularName:
        source.begin(JsNodeTags.modularName);
        needsInfo = false;
        node = source.readCached<ModularName>(
            () => _readInfo(ModularName.readFromDataSource(source)));
        source.end(JsNodeTags.modularName);
        break;
      case JsNodeKind.asyncName:
        source.begin(JsNodeTags.asyncName);
        js.Name prefix = read();
        js.Name base = read();
        node = AsyncName(prefix, base);
        source.end(JsNodeTags.asyncName);
        break;
      case JsNodeKind.stringBackedName:
        source.begin(JsNodeTags.stringBackedName);
        node = StringBackedName(source.readString());
        source.end(JsNodeTags.stringBackedName);
        break;
      case JsNodeKind.stringConcatenation:
        source.begin(JsNodeTags.stringConcatenation);
        List<js.Literal> parts = readList();
        node = js.StringConcatenation(parts);
        source.end(JsNodeTags.stringConcatenation);
        break;
      case JsNodeKind.literalNull:
        source.begin(JsNodeTags.literalNull);
        node = js.LiteralNull();
        source.end(JsNodeTags.literalNull);
        break;
      case JsNodeKind.literalNumber:
        source.begin(JsNodeTags.literalNumber);
        node = js.LiteralNumber(source.readString());
        source.end(JsNodeTags.literalNumber);
        break;
      case JsNodeKind.literalString:
        source.begin(JsNodeTags.literalString);
        node = js.LiteralString(source.readString());
        source.end(JsNodeTags.literalString);
        break;
      case JsNodeKind.literalStringFromName:
        source.begin(JsNodeTags.literalStringFromName);
        js.Name name = read();
        node = js.LiteralStringFromName(name);
        source.end(JsNodeTags.literalStringFromName);
        break;
      case JsNodeKind.literalBool:
        source.begin(JsNodeTags.literalBool);
        node = js.LiteralBool(source.readBool());
        source.end(JsNodeTags.literalBool);
        break;
      case JsNodeKind.modularExpression:
        source.begin(JsNodeTags.modularExpression);
        needsInfo = false;
        node = source.readCached<ModularExpression>(
            () => _readInfo(ModularExpression.readFromDataSource(source)));
        source.end(JsNodeTags.modularExpression);
        break;
      case JsNodeKind.function:
        source.begin(JsNodeTags.function);
        List<js.Parameter> params = readList();
        js.Block body = js.DeferredBlock(
            source.readDeferrable(_readFunBodyStatements, cacheData: false));
        js.AsyncModifier asyncModifier =
            source.readEnum(js.AsyncModifier.values);
        node = js.Fun(params, body, asyncModifier: asyncModifier);
        source.end(JsNodeTags.function);
        break;
      case JsNodeKind.arrowFunction:
        source.begin(JsNodeTags.arrowFunction);
        List<js.Parameter> params = readList();
        js.Node body = read();
        js.AsyncModifier asyncModifier =
            source.readEnum(js.AsyncModifier.values);
        node = js.ArrowFunction(params, body, asyncModifier: asyncModifier);
        source.end(JsNodeTags.arrowFunction);
        break;
      case JsNodeKind.namedFunction:
        source.begin(JsNodeTags.namedFunction);
        js.Declaration name = read();
        js.Fun function = read();
        node = js.NamedFunction(name, function);
        source.end(JsNodeTags.namedFunction);
        break;
      case JsNodeKind.access:
        source.begin(JsNodeTags.access);
        js.Expression receiver = read();
        js.Expression selector = read();
        node = js.PropertyAccess(receiver, selector);
        source.end(JsNodeTags.access);
        break;
      case JsNodeKind.parameter:
        source.begin(JsNodeTags.parameter);
        node = js.Parameter(source.readString());
        source.end(JsNodeTags.parameter);
        break;
      case JsNodeKind.variableDeclaration:
        source.begin(JsNodeTags.variableDeclaration);
        String name = source.readString();
        bool allowRename = source.readBool();
        node = js.VariableDeclaration(name, allowRename: allowRename);
        source.end(JsNodeTags.variableDeclaration);
        break;
      case JsNodeKind.thisExpression:
        source.begin(JsNodeTags.thisExpression);
        node = js.This();
        source.end(JsNodeTags.thisExpression);
        break;
      case JsNodeKind.variableUse:
        source.begin(JsNodeTags.variableUse);
        node = js.VariableUse(source.readString());
        source.end(JsNodeTags.variableUse);
        break;
      case JsNodeKind.postfix:
        source.begin(JsNodeTags.postfix);
        String op = source.readString();
        js.Expression argument = read();
        node = js.Postfix(op, argument);
        source.end(JsNodeTags.postfix);
        break;
      case JsNodeKind.prefix:
        source.begin(JsNodeTags.prefix);
        String op = source.readString();
        js.Expression argument = read();
        node = js.Prefix(op, argument);
        source.end(JsNodeTags.prefix);
        break;
      case JsNodeKind.binary:
        source.begin(JsNodeTags.binary);
        String op = source.readString();
        js.Expression left = read();
        js.Expression right = read();
        node = js.Binary(op, left, right);
        source.end(JsNodeTags.binary);
        break;
      case JsNodeKind.callExpression:
        source.begin(JsNodeTags.callExpression);
        js.Expression target = read();
        List<js.Expression> arguments = readList();
        node = js.Call(target, arguments);
        source.end(JsNodeTags.callExpression);
        break;
      case JsNodeKind.newExpression:
        source.begin(JsNodeTags.newExpression);
        js.Expression cls = read();
        List<js.Expression> arguments = readList();
        node = js.New(cls, arguments);
        source.end(JsNodeTags.newExpression);
        break;
      case JsNodeKind.conditional:
        source.begin(JsNodeTags.conditional);
        js.Expression condition = read();
        js.Expression then = read();
        js.Expression otherwise = read();
        node = js.Conditional(condition, then, otherwise);
        source.end(JsNodeTags.conditional);
        break;
      case JsNodeKind.variableInitialization:
        source.begin(JsNodeTags.variableInitialization);
        js.Declaration declaration = read();
        final value = source.readValueOrNull(read) as js.Expression?;
        node = js.VariableInitialization(declaration, value);
        source.end(JsNodeTags.variableInitialization);
        break;
      case JsNodeKind.assignment:
        source.begin(JsNodeTags.assignment);
        js.Expression leftHandSide = read();
        final op = source.readStringOrNull();
        js.Expression value = read();
        node = js.Assignment.compound(leftHandSide, op, value);
        source.end(JsNodeTags.assignment);
        break;
      case JsNodeKind.variableDeclarationList:
        source.begin(JsNodeTags.variableDeclarationList);
        List<js.VariableInitialization> declarations = readList();
        bool indentSplits = source.readBool();
        node = js.VariableDeclarationList(declarations,
            indentSplits: indentSplits);
        source.end(JsNodeTags.variableDeclarationList);
        break;
      case JsNodeKind.literalExpression:
        source.begin(JsNodeTags.literalExpression);
        node = js.LiteralExpression(source.readString());
        source.end(JsNodeTags.literalExpression);
        break;
      case JsNodeKind.dartYield:
        source.begin(JsNodeTags.dartYield);
        js.Expression expression = read();
        bool hasStar = source.readBool();
        node = js.DartYield(expression, hasStar);
        source.end(JsNodeTags.dartYield);
        break;
      case JsNodeKind.literalStatement:
        source.begin(JsNodeTags.literalStatement);
        node = js.LiteralStatement(source.readString());
        source.end(JsNodeTags.literalStatement);
        break;
      case JsNodeKind.labeledStatement:
        source.begin(JsNodeTags.labeledStatement);
        String label = source.readString();
        js.Statement body = read();
        node = js.LabeledStatement(label, body);
        source.end(JsNodeTags.labeledStatement);
        break;
      case JsNodeKind.functionDeclaration:
        source.begin(JsNodeTags.functionDeclaration);
        js.Declaration name = read();
        js.Fun function = read();
        node = js.FunctionDeclaration(name, function);
        source.end(JsNodeTags.functionDeclaration);
        break;
      case JsNodeKind.switchDefault:
        source.begin(JsNodeTags.switchDefault);
        js.Block body = read();
        node = js.Default(body);
        source.end(JsNodeTags.switchDefault);
        break;
      case JsNodeKind.switchCase:
        source.begin(JsNodeTags.switchCase);
        js.Expression expression = read();
        js.Block body = read();
        node = js.Case(expression, body);
        source.end(JsNodeTags.switchCase);
        break;
      case JsNodeKind.switchStatement:
        source.begin(JsNodeTags.switchStatement);
        js.Expression key = read();
        List<js.SwitchClause> cases = readList();
        node = js.Switch(key, cases);
        source.end(JsNodeTags.switchStatement);
        break;
      case JsNodeKind.catchClause:
        source.begin(JsNodeTags.catchClause);
        js.Declaration declaration = read();
        js.Block body = read();
        node = js.Catch(declaration, body);
        source.end(JsNodeTags.catchClause);
        break;
      case JsNodeKind.tryStatement:
        source.begin(JsNodeTags.tryStatement);
        js.Block body = read();
        final catchPart = source.readValueOrNull(read) as js.Catch?;
        final finallyPart = source.readValueOrNull(read) as js.Block?;
        node = js.Try(body, catchPart, finallyPart);
        source.end(JsNodeTags.tryStatement);
        break;
      case JsNodeKind.throwStatement:
        source.begin(JsNodeTags.throwStatement);
        js.Expression expression = read();
        node = js.Throw(expression);
        source.end(JsNodeTags.throwStatement);
        break;
      case JsNodeKind.returnStatement:
        source.begin(JsNodeTags.returnStatement);
        final value = source.readValueOrNull(read) as js.Expression?;
        node = js.Return(value);
        source.end(JsNodeTags.returnStatement);
        break;
      case JsNodeKind.breakStatement:
        source.begin(JsNodeTags.breakStatement);
        final targetLabel = source.readStringOrNull();
        node = js.Break(targetLabel);
        source.end(JsNodeTags.breakStatement);
        break;
      case JsNodeKind.continueStatement:
        source.begin(JsNodeTags.continueStatement);
        final targetLabel = source.readStringOrNull();
        node = js.Continue(targetLabel);
        source.end(JsNodeTags.continueStatement);
        break;
      case JsNodeKind.doStatement:
        source.begin(JsNodeTags.doStatement);
        js.Statement body = read();
        js.Expression condition = read();
        node = js.Do(body, condition);
        source.end(JsNodeTags.doStatement);
        break;
      case JsNodeKind.whileStatement:
        source.begin(JsNodeTags.whileStatement);
        js.Expression condition = read();
        js.Statement body = read();
        node = js.While(condition, body);
        source.end(JsNodeTags.whileStatement);
        break;
      case JsNodeKind.forInStatement:
        source.begin(JsNodeTags.forInStatement);
        js.Expression leftHandSide = read();
        js.Expression object = read();
        js.Statement body = read();
        node = js.ForIn(leftHandSide, object, body);
        source.end(JsNodeTags.forInStatement);
        break;
      case JsNodeKind.forStatement:
        source.begin(JsNodeTags.forStatement);
        final init = readOrNull() as js.Expression?;
        final condition = readOrNull() as js.Expression?;
        final update = readOrNull() as js.Expression?;
        js.Statement body = read();
        node = js.For(init, condition, update, body);
        source.end(JsNodeTags.forStatement);
        break;
      case JsNodeKind.ifStatement:
        source.begin(JsNodeTags.ifStatement);
        js.Expression condition = read();
        js.Statement then = read();
        js.Statement otherwise = read();
        node = js.If(condition, then, otherwise);
        source.end(JsNodeTags.ifStatement);
        break;
      case JsNodeKind.emptyStatement:
        source.begin(JsNodeTags.emptyStatement);
        node = js.EmptyStatement();
        source.end(JsNodeTags.emptyStatement);
        break;
      case JsNodeKind.expressionStatement:
        source.begin(JsNodeTags.expressionStatement);
        node = js.ExpressionStatement(read());
        source.end(JsNodeTags.expressionStatement);
        break;
      case JsNodeKind.block:
        source.begin(JsNodeTags.block);
        List<js.Statement> statements = readList();
        node = js.Block(statements);
        source.end(JsNodeTags.block);
        break;
      case JsNodeKind.program:
        source.begin(JsNodeTags.program);
        List<js.Statement> body = readList();
        node = js.Program(body);
        source.end(JsNodeTags.program);
        break;
      case JsNodeKind.stringReference:
        source.begin(JsNodeTags.stringReference);
        needsInfo = false;
        node = source.readCached<StringReference>(
            () => _readInfo(StringReference.readFromDataSource(source)));
        source.end(JsNodeTags.stringReference);
        break;
      case JsNodeKind.typeReference:
        source.begin(JsNodeTags.typeReference);
        needsInfo = false;
        node = source.readCached<TypeReference>(
            () => _readInfo(TypeReference.readFromDataSource(source)));
        source.end(JsNodeTags.typeReference);
        break;
      case JsNodeKind.deferredHolderExpression:
        source.begin(JsNodeTags.deferredHolderExpression);
        needsInfo = false;
        node = source.readCached<DeferredHolderExpression>(() =>
            _readInfo(DeferredHolderExpression.readFromDataSource(source)));
        source.end(JsNodeTags.deferredHolderExpression);
        break;
    }

    return needsInfo ? _readInfo(node) : node as T;
  }

  T _readInfo<T extends js.Node>(js.Node node) {
    final infoCode = source.readInt();
    final hasSourceInformation = infoCode.isOdd;
    final annotationCount = infoCode ~/ 2;
    if (hasSourceInformation) {
      final sourceInformation = source.readCachedOrNull<SourceInformation>(() {
        return SourceInformation.readFromDataSource(source);
      });
      node = node.withSourceInformation(sourceInformation);
    }
    for (int i = 0; i < annotationCount; i++) {
      node = node.withAnnotation(_readAnnotation());
    }
    return node as T;
  }

  List<T> readList<T extends js.Node>() {
    return source.readList(read);
  }

  Object _readAnnotation() {
    final kind = source.readEnum(JsAnnotationKind.values);
    switch (kind) {
      case JsAnnotationKind.string:
        return source.readString();
      case JsAnnotationKind.resourceIdentifier:
        return ResourceIdentifier.readFromDataSource(source);
    }
  }
}

enum ModularNameKind {
  rtiField,
  className,
  aliasedSuperMember,
  staticClosure,
  methodProperty,
  operatorIs,
  instanceMethod,
  instanceField,
  invocation,
  lazyInitializer,
  globalPropertyNameForClass,
  globalPropertyNameForMember,
  globalNameForInterfaceTypeVariable,
  nameForGetInterceptor,
  nameForOneShotInterceptor,
  asName,
}

class ModularName extends js.Name implements js.AstContainer {
  static const String tag = 'modular-name';

  final ModularNameKind kind;
  js.Name? _value;
  final Object? data;
  final Set<ClassEntity>? set;

  ModularName(this.kind, {this.data, this.set});

  factory ModularName.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ModularNameKind kind = source.readEnum(ModularNameKind.values);
    Object? data;
    Set<ClassEntity>? set;
    switch (kind) {
      case ModularNameKind.rtiField:
        break;
      case ModularNameKind.className:
      case ModularNameKind.operatorIs:
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
    return ModularName(kind, data: data, set: set);
  }

  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeEnum(kind);
    switch (kind) {
      case ModularNameKind.rtiField:
        break;
      case ModularNameKind.className:
      case ModularNameKind.operatorIs:
      case ModularNameKind.globalPropertyNameForClass:
        sink.writeClass(data as ClassEntity);
        break;
      case ModularNameKind.aliasedSuperMember:
      case ModularNameKind.staticClosure:
      case ModularNameKind.methodProperty:
      case ModularNameKind.instanceField:
      case ModularNameKind.instanceMethod:
      case ModularNameKind.lazyInitializer:
      case ModularNameKind.globalPropertyNameForMember:
        sink.writeMember(data as MemberEntity);
        break;
      case ModularNameKind.invocation:
        final selector = data as Selector;
        selector.writeToDataSink(sink);
        break;
      case ModularNameKind.globalNameForInterfaceTypeVariable:
        final typeVariable = data as TypeVariableEntity;
        sink.writeTypeVariable(typeVariable);
        break;
      case ModularNameKind.nameForGetInterceptor:
        sink.writeClasses(set);
        break;
      case ModularNameKind.nameForOneShotInterceptor:
        final selector = data as Selector;
        selector.writeToDataSink(sink);
        sink.writeClasses(set);
        break;
      case ModularNameKind.asName:
        sink.writeString(data as String);
        break;
    }
    sink.end(tag);
  }

  @override
  bool get isFinalized => _value != null;

  js.Name get value {
    assert(isFinalized, 'value not set for $this');
    return _value!;
  }

  void set value(js.Name node) {
    assert(!isFinalized);
    assert((node as dynamic) != null);
    _value = node.withSourceInformation(sourceInformation) as js.Name;
  }

  @override
  String get key {
    assert(isFinalized);
    return _value!.key;
  }

  @override
  String get name {
    assert(isFinalized, 'value not set for $this');
    return _value!.name;
  }

  @override
  bool get allowRename {
    assert(isFinalized, 'value not set for $this');
    return _value!.allowRename;
  }

  @override
  Iterable<js.Node> get containedNodes {
    return _value != null ? [_value!] : const [];
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

  @override
  String nonfinalizedDebugText() {
    switch (kind) {
      case ModularNameKind.rtiField:
        return r'ModularName"$ti"';
      case ModularNameKind.instanceField:
        return 'ModularName"field:${(data as Entity).name}"';
      case ModularNameKind.instanceMethod:
        return 'ModularName"${_instanceMethodName(data as MemberEntity)}"';
      case ModularNameKind.methodProperty:
        return 'ModularName"methodProperty:${(data as Entity).name}"';
      case ModularNameKind.operatorIs:
        return 'ModularName"is:${_className(data as ClassEntity)}"';
      case ModularNameKind.className:
        return 'ModularName"class:${_className(data as ClassEntity)}"';
      case ModularNameKind.globalPropertyNameForClass:
        return 'ModularName"classref:${_className(data as ClassEntity)}"';
      case ModularNameKind.aliasedSuperMember:
        MemberEntity member = (data as MemberEntity);
        String className = _className(member.enclosingClass!);
        String invocationName = operatorNameToIdentifier(member.name)!;
        final description = "$className.$invocationName";
        return 'ModularName"alias:$description"';
      case ModularNameKind.staticClosure:
        return 'ModularName"closure:${_qualifiedStaticName(data as MemberEntity)}"';
      case ModularNameKind.lazyInitializer:
        return 'ModularName"lazy:${(data as MemberEntity).name}"';
      case ModularNameKind.globalPropertyNameForMember:
        MemberEntity member = data as MemberEntity;
        return 'ModularName"ref:${_qualifiedStaticName(member)}"';
      case ModularNameKind.invocation:
        return 'ModularName"selector:${_selectorText(data as Selector)}"';
      case ModularNameKind.nameForOneShotInterceptor:
        return 'ModularName"oneshot:${_selectorText(data as Selector)}"';
      case ModularNameKind.globalNameForInterfaceTypeVariable:
        break;
      case ModularNameKind.nameForGetInterceptor:
        return 'ModularName"getInterceptor"';
      case ModularNameKind.asName:
        return 'ModularName"asName:$data"';
    }
    return super.nonfinalizedDebugText();
  }

  String _className(ClassEntity cls) {
    return cls.name.replaceAll('&', '_');
  }

  String _qualifiedStaticName(MemberEntity member) {
    if (member is ConstructorEntity || member.isStatic) {
      return '${_className(member.enclosingClass!)}.${member.name!}';
    }
    return member.name!;
  }

  String _instanceMethodInvocationName(MemberEntity member) {
    String invocationName = operatorNameToIdentifier(member.name)!;
    if (member.isGetter) invocationName = r'get$' + invocationName;
    if (member.isSetter) invocationName = r'set$' + invocationName;
    return invocationName;
  }

  String _instanceMethodName(MemberEntity member) {
    if (member is ConstructorBodyEntity) {
      return 'constructorBody:${_qualifiedStaticName(member.constructor)}';
    }
    if (member is JGeneratorBody) {
      MemberEntity function = member.function;
      return 'generatorBody:'
          '${_className(function.enclosingClass!)}.'
          '${_instanceMethodInvocationName(function)}';
    }
    return 'instanceMethod:${_instanceMethodInvocationName(member)}';
  }

  String _selectorText(Selector selector) {
    // Approximation to unminified selector.
    if (selector.isGetter) return r'get$' + selector.name;
    if (selector.isSetter) return r'set$' + selector.name;
    if (selector.isOperator || selector.isIndex || selector.isIndexSet) {
      return operatorNameToIdentifier(selector.name)!;
    }
    List<String> parts = [
      selector.name,
      if (selector.callStructure.typeArgumentCount > 0)
        '${selector.callStructure.typeArgumentCount}',
      '${selector.callStructure.argumentCount}',
      ...selector.callStructure.getOrderedNamedArguments()
    ];
    return parts.join(r'$');
  }
}

/// Interface for reading the code generation results for all [MemberEntity]s.
abstract class CodegenResults {
  CodegenInputs get codegenInputs;
  CodegenResult getCodegenResults(MemberEntity member);
}

/// Deserialized code generation results.
///
/// This is used for modular code generation.
class DeserializedCodegenResults extends CodegenResults {
  @override
  final CodegenInputs codegenInputs;

  final Map<MemberEntity, CodegenResult> _map;

  DeserializedCodegenResults(this.codegenInputs, this._map);

  @override
  CodegenResult getCodegenResults(MemberEntity member) {
    // We only access these results once as it is picked up by the work queue
    // so it is safe to remove and free up space in the map. With deferred
    // deserialization this will also free the Deferrable holder.
    return _map.remove(member)!;
  }
}
