// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.new_js_emitter.model;

import '../common/elements.dart';
import '../constants/values.dart' show ConstantValue;
import '../deferred_load/output_unit.dart' show OutputUnit;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js/js.dart' as js show Expression, Name, Statement, TokenFinalizer;
import '../js/js_debug.dart' as js show nodeToString;
import '../js_backend/runtime_types_codegen.dart';
import 'metadata_collector.dart' show MetadataCollector;

class Program {
  final List<Fragment> fragments;
  final bool outputContainsConstantList;
  final bool needsNativeSupport;

  // If this field is not `null` then its value must be emitted in the embedded
  // global `TYPE_TO_INTERCEPTOR_MAP`. The map references constants and classes.
  final js.Expression? typeToInterceptorMap;

  // TODO(floitsch): we should store the metadata directly instead of storing
  // the collector. However, the old emitter still updates the data.
  final MetadataCollector _metadataCollector;
  final Iterable<js.TokenFinalizer> finalizers;

  Program(this.fragments, this.typeToInterceptorMap, this._metadataCollector,
      this.finalizers,
      {required this.needsNativeSupport,
      required this.outputContainsConstantList});

  void mergeOutputUnitMetadata(OutputUnit target, OutputUnit source) {
    _metadataCollector.mergeOutputUnitMetadata(target, source);
  }

  /// Accessor for the list of type entries for a given [OutputUnit].
  ///
  /// There is one list for each output unit. The list belonging to the main
  /// unit must be emitted in the `TYPES` embedded global. The list references
  /// constants and must hence be emitted after constants have been initialized.
  ///
  /// Note: the metadata is derived from the task's `metadataCollector`. The
  /// list is only a placeholder and will be filled in once metadata collection
  /// is finalized.
  js.Expression metadataTypesForOutputUnit(OutputUnit unit) {
    return _metadataCollector.getTypesForOutputUnit(unit);
  }

  bool get isSplit => fragments.length > 1;
  Iterable<Fragment> get deferredFragments => fragments.skip(1);
  Fragment get mainFragment => fragments.first;
}

/// This class represents one output file.
///
/// If no library is deferred, there is only one [Fragment] of type
/// [MainFragment].
abstract class Fragment {
  /// The outputUnit should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final OutputUnit outputUnit;

  final List<Library> libraries;
  final List<Constant> constants;
  // TODO(floitsch): should we move static fields into libraries or classes?
  final List<StaticField> staticNonFinalFields;
  // TODO(floitsch): lazy fields should be in their library or even class.
  final List<StaticField> staticLazilyInitializedFields;

  /// Output file name without extension.
  final String outputFileName;

  Fragment(
      this.outputUnit,
      this.outputFileName,
      this.libraries,
      this.staticNonFinalFields,
      this.staticLazilyInitializedFields,
      this.constants);

  bool get isMainFragment;
}

/// The main output file.
///
/// This code emitted from this [Fragment] must be loaded first. It can then load
/// other [DeferredFragment]s.
class MainFragment extends Fragment {
  final js.Statement invokeMain;

  // TODO(50081): We should collect a list of stub objects in the model to
  // support different stubs in different units, and merging units and their
  // stubs.
  final js.Expression? recordTypeStubs;

  MainFragment(
      OutputUnit outputUnit,
      String outputFileName,
      this.invokeMain,
      this.recordTypeStubs,
      List<Library> libraries,
      List<StaticField> staticNonFinalFields,
      List<StaticField> staticLazilyInitializedFields,
      List<Constant> constants)
      : super(outputUnit, outputFileName, libraries, staticNonFinalFields,
            staticLazilyInitializedFields, constants);

  @override
  bool get isMainFragment => true;

  @override
  String toString() {
    return 'MainFragment()';
  }
}

/// An output (file) for deferred code.
class DeferredFragment extends Fragment {
  final String name;

  DeferredFragment(
      OutputUnit outputUnit,
      String outputFileName,
      this.name,
      List<Library> libraries,
      List<StaticField> staticNonFinalFields,
      List<StaticField> staticLazilyInitializedFields,
      List<Constant> constants)
      : super(outputUnit, outputFileName, libraries, staticNonFinalFields,
            staticLazilyInitializedFields, constants);

  @override
  bool get isMainFragment => false;

  @override
  String toString() {
    return 'DeferredFragment(name=${name})';
  }
}

class Constant {
  final js.Name name;
  final ConstantValue value;

  Constant(this.name, this.value);

  @override
  String toString() {
    return 'Constant(name=${name.key},value=${value.toStructuredText(null)})';
  }
}

class Library {
  /// The element should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final LibraryEntity element;

  final String uri;
  final List<StaticMethod> statics;
  final List<Class> classes;
  final List<ClassTypeData> classTypeData;

  Library(
      this.element, this.uri, this.statics, this.classes, this.classTypeData);

  @override
  String toString() {
    return 'Library(uri=${uri},element=${element})';
  }
}

class StaticField {
  /// The element should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final FieldEntity element;

  final js.Name name;
  // Null for static non-final fields.
  final js.Name? getterName;
  // TODO(floitsch): the holder for static fields is the isolate object. We
  // could remove this field and use the isolate object directly.
  final js.Expression code;
  final bool isFinal;
  final bool isLazy;
  final bool isInitializedByConstant;

  StaticField(this.element, this.name, this.getterName, this.code,
      {required this.isFinal,
      required this.isLazy,
      this.isInitializedByConstant = false});

  @override
  String toString() {
    return 'StaticField(name=${name.key},element=${element})';
  }
}

class ClassTypeData {
  /// The element should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final ClassEntity element;

  final ClassChecks classChecks;
  final Set<TypeVariableType> namedTypeVariables = {};

  ClassTypeData(this.element, this.classChecks);

  bool isTriviallyChecked(CommonElements commonElements) =>
      classChecks.checks.every((TypeCheck check) =>
          check.cls == commonElements.objectClass || check.cls == element);
}

// TODO(sra): There are a lot of fields here that apply in limited cases
// (e.g. isClosureBaseClass is true for one class). Can we refactor the special
// case information, for example, into a subclass, or an extension object?
class Class {
  /// The element should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final ClassEntity element;

  // TODO(joshualitt): Now that we collect all rti needed classes and handle
  // them separately, we should investigate whether or not we still need to
  // store the type data on the class.
  final ClassTypeData typeData;

  final js.Name name;
  Class? superclass;
  Class? mixinClass;
  final List<Method> methods;
  final List<Field> fields;
  final List<StubMethod> isChecks;
  final List<StubMethod> checkedSetters;
  final List<StubMethod> gettersSetters;

  /// Stub methods for this class that are call stubs for getters.
  final List<StubMethod> callStubs;

  /// noSuchMethod stubs in the special case that the class is Object.
  final List<StubMethod> noSuchMethodStubs;

  final bool hasRtiField; // Per-instance runtime type information pseudo-field.
  final bool onlyForRti;
  final bool onlyForConstructor;
  final bool isDirectlyInstantiated;
  final bool isNative;

  /// `true` if this is the one class that is the root of all 'Closure' classes.
  final bool isClosureBaseClass;

  /// If non-null, this class is used as a base class for closures with a fixed
  /// small number of arguments in order to inherit `Function.apply`
  /// metadata. The value is the fixed number of arguments.
  final int? sharedClosureApplyMetadata;

  final bool isMixinApplicationWithMembers;

  // If the class implements a function type, and the type is encoded in the
  // metadata table, then this field contains the index into that field.
  final js.Expression? functionTypeIndex;

  final int? recordShapeTag;
  final js.Expression? recordShapeRecipe;

  /// Whether the class must be evaluated eagerly.
  bool isEager = false;

  /// Leaf tags. See [NativeEmitter.prepareNativeClasses].
  List<String>? nativeLeafTags;

  /// Non-leaf tags. See [NativeEmitter.prepareNativeClasses].
  List<String>? nativeNonLeafTags;

  /// Native extensions. See [NativeEmitter.prepareNativeClasses].
  List<Class>? nativeExtensions;

  Class(
      this.element,
      this.typeData,
      this.name,
      this.methods,
      this.fields,
      this.callStubs,
      this.noSuchMethodStubs,
      this.checkedSetters,
      this.gettersSetters,
      this.isChecks,
      this.functionTypeIndex,
      {required this.hasRtiField,
      required this.onlyForRti,
      required this.onlyForConstructor,
      required this.isDirectlyInstantiated,
      required this.isNative,
      required this.isClosureBaseClass,
      this.sharedClosureApplyMetadata,
      required this.isMixinApplicationWithMembers,
      this.recordShapeRecipe,
      this.recordShapeTag});

  bool get isSimpleMixinApplication => false;

  js.Name? get superclassName => superclass?.name;

  @override
  String toString() => 'Class(name=${name.key},element=$element)';
}

class MixinApplication extends Class {
  MixinApplication(
      ClassEntity element,
      ClassTypeData typeData,
      js.Name name,
      List<Field> instanceFields,
      List<StubMethod> callStubs,
      List<StubMethod> checkedSetters,
      List<StubMethod> gettersSetters,
      List<StubMethod> isChecks,
      js.Expression? functionTypeIndex,
      {required super.hasRtiField,
      required super.onlyForRti,
      required super.onlyForConstructor,
      required super.isDirectlyInstantiated})
      : super(
            element,
            typeData,
            name,
            const <Method>[],
            instanceFields,
            callStubs,
            const <StubMethod>[],
            checkedSetters,
            gettersSetters,
            isChecks,
            functionTypeIndex,
            isNative: false,
            isClosureBaseClass: false,
            isMixinApplicationWithMembers: false);

  @override
  bool get isSimpleMixinApplication => true;

  @override
  String toString() => 'Mixin(name=${name.key},element=$element)';
}

/// A field.
///
/// In general represents an instance field, but for reflection may also
/// represent static fields.
class Field {
  /// The element should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final FieldEntity element;

  final js.Name name;
  final js.Name accessorName;

  /// 00: Does not need any getter.
  /// 01:  function() { return this.field; }
  /// 10:  function(receiver) { return receiver.field; }
  /// 11:  function(receiver) { return this.field; }
  final int getterFlags;

  /// 00: Does not need any setter.
  /// 01:  function(value) { this.field = value; }
  /// 10:  function(receiver, value) { receiver.field = value; }
  /// 11:  function(receiver, value) { this.field = value; }
  final int setterFlags;

  final bool needsCheckedSetter;

  final ConstantValue? initializerInAllocator;

  final ConstantValue? constantValue;

  final bool isElided;

  // TODO(floitsch): support renamed fields.
  Field(
      this.element,
      this.name,
      this.accessorName,
      this.getterFlags,
      this.setterFlags,
      this.needsCheckedSetter,
      this.initializerInAllocator,
      this.constantValue,
      this.isElided);

  bool get needsGetter => getterFlags != 0;
  bool get needsUncheckedSetter => setterFlags != 0;

  bool get needsInterceptedGetter => getterFlags > 1;
  bool get needsInterceptedSetter => setterFlags > 1;

  bool get needsInterceptedGetterOnReceiver => getterFlags == 2;
  bool get needsInterceptedSetterOnReceiver => setterFlags == 2;

  bool get needsInterceptedGetterOnThis => getterFlags == 3;
  bool get needsInterceptedSetterOnThis => setterFlags == 3;

  @override
  String toString() {
    return 'Field(name=${name.key},element=${element})';
  }
}

abstract class Method {
  /// The element should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final MemberEntity? element;

  /// The name of the method. If the method is a [ParameterStubMethod] for a
  /// static function, then the name can be `null`. In that case, only the
  /// [ParameterStubMethod.callName] should be used.
  final js.Name? name;
  final js.Expression code;

  Method(this.element, this.name, this.code);
}

/// A method that corresponds to a method in the original Dart program.
abstract class DartMethod extends Method {
  final bool needsTearOff;
  final js.Name? tearOffName;
  final List<ParameterStubMethod> parameterStubs;
  final bool canBeApplied;
  final int applyIndex;

  // Is non-null if [needsTearOff].
  //
  // If the type is encoded in the metadata table this field contains an index
  // into the table. Otherwise the type contains type variables in which case
  // this field holds a function computing the function signature.
  final js.Expression? functionType;

  // Signature information for this method. [optionalParameterDefaultValues] is
  // only required and stored here if the method [canBeApplied]. The count is
  // always stored to help select specialized tear-off paths.
  final int requiredParameterCount;
  final Object? /* Map | List */ optionalParameterDefaultValues;

  // If this method can be torn off, contains the name of the corresponding
  // call method. For example, for the member `foo$1$name` it would be
  // `call$1$name` (in unminified mode).
  final js.Name? callName;

  DartMethod(FunctionEntity super.element, super.name, super.code,
      this.parameterStubs, this.callName,
      {required this.needsTearOff,
      this.tearOffName,
      required this.canBeApplied,
      required this.requiredParameterCount,
      this.optionalParameterDefaultValues,
      this.functionType,
      required this.applyIndex}) {
    assert(!needsTearOff || tearOffName != null);
    assert(!canBeApplied || optionalParameterDefaultValues != null);
  }

  bool get isStatic;
}

class InstanceMethod extends DartMethod {
  /// An alternative name for this method. This is used to model calls to
  /// a method via `super`. If [aliasName] is non-null, the emitter has to
  /// ensure that this method is registered on the prototype under both [name]
  /// and [aliasName].
  final js.Name? aliasName;

  /// `true` if the tear-off needs to access methods directly rather than rely
  /// on JavaScript prototype lookup. This happens when a tear-off getter is
  /// called via `super.method` and there is a shadowing definition of `method`
  /// in some subclass.
  // TODO(sra): Consider instead having an alias per stub, creating tear-off
  // trampolines that target the stubs.
  final bool tearOffNeedsDirectAccess;

  /// True if this is the implicit `call` instance method of an anonymous
  /// closure. This predicate is false for explicit `call` methods and for
  /// functions that can be torn off.
  final bool isClosureCallMethod;

  final bool inheritsApplyMetadata;

  /// True if the interceptor calling convention is used for this method.
  final bool isIntercepted;

  /// Name called via the general 'catch all' path of Function.apply.
  ///final js.Name applyName;

  InstanceMethod(
    super.element,
    super.name,
    super.code,
    super.parameterStubs,
    super.callName, {
    required super.needsTearOff,
    super.tearOffName,
    this.aliasName,
    required this.tearOffNeedsDirectAccess,
    required super.canBeApplied,
    required super.requiredParameterCount,
    /* List | Map */ super.optionalParameterDefaultValues,
    required this.isClosureCallMethod,
    required this.inheritsApplyMetadata,
    required this.isIntercepted,
    super.functionType,
    required super.applyIndex,
  });

  @override
  bool get isStatic => false;

  @override
  String toString() {
    return 'InstanceMethod(name=${name!.key},element=${element}'
        ',code=${js.nodeToString(code)})';
  }
}

/// A method that is generated by the backend and has not direct correspondence
/// to a method in the original Dart program. Examples are getter and setter
/// stubs and stubs to dispatch calls to methods with optional parameters.
class StubMethod extends Method {
  StubMethod(js.Name? name, js.Expression code, {MemberEntity? element})
      : super(element, name, code);

  @override
  String toString() {
    return 'StubMethod(name=${name!.key},element=${element}'
        ',code=${js.nodeToString(code)})';
  }
}

/// A stub that adapts and redirects to the main method (the one containing)
/// the actual code.
///
/// For example, given a method `foo$2(x, [y: 499])` a possible parameter
/// stub-method could be `foo$1(x) => foo$2(x, 499)`.
///
/// ParameterStubMethods are always attached to (static or instance) methods.
class ParameterStubMethod extends StubMethod {
  /// The `call` name of this stub.
  ///
  /// When an instance method is torn off, it is invoked as a `call` member and
  /// not it's original name anymore. The [callName] provides the stub's
  /// name when it is used this way.
  ///
  /// If a stub's member can not be torn off, the [callName] is `null`.
  js.Name? callName;

  ParameterStubMethod(super.name, this.callName, super.code,
      {required super.element});

  @override
  String toString() {
    return 'ParameterStubMethod(name=${name!.key}, callName=${callName?.key}'
        ', element=${element}'
        ', code=${js.nodeToString(code)})';
  }
}

abstract class StaticMethod implements Method {}

class StaticDartMethod extends DartMethod implements StaticMethod {
  StaticDartMethod(super.element, super.name, super.code, super.parameterStubs,
      super.callName,
      {required super.needsTearOff,
      super.tearOffName,
      required super.canBeApplied,
      required super.requiredParameterCount,
      /* List | Map */ super.optionalParameterDefaultValues,
      super.functionType,
      required super.applyIndex});

  @override
  bool get isStatic => true;

  @override
  String toString() {
    return 'StaticDartMethod(name=${name!.key},element=${element}'
        ',code=${js.nodeToString(code)})';
  }
}

class StaticStubMethod extends StubMethod implements StaticMethod {
  LibraryEntity library;
  StaticStubMethod(this.library, js.Name name, js.Expression code)
      : super(name, code);

  @override
  String toString() {
    return 'StaticStubMethod(name=${name!.key},element=${element}}'
        ',code=${js.nodeToString(code)})';
  }
}
