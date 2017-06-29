// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.new_js_emitter.model;

import '../constants/values.dart' show ConstantValue;
import '../deferred_load.dart' show OutputUnit;
import '../elements/entities.dart';
import '../js/js.dart' as js show Expression, Name, Statement, TokenFinalizer;
import '../js/js_debug.dart' as js show nodeToString;
import 'js_emitter.dart' show MetadataCollector;

class Program {
  final List<Fragment> fragments;
  final List<Holder> holders;
  final bool outputContainsConstantList;
  final bool needsNativeSupport;
  final bool hasIsolateSupport;
  final bool hasSoftDeferredClasses;

  /// A map from load id to the list of fragments that need to be loaded.
  final Map<String, List<Fragment>> loadMap;

  /// A map from names to strings.
  ///
  /// This map is needed to support `const Symbol` expressions;
  final Map<js.Name, String> symbolsMap;

  // If this field is not `null` then its value must be emitted in the embedded
  // global `TYPE_TO_INTERCEPTOR_MAP`. The map references constants and classes.
  final js.Expression typeToInterceptorMap;

  // TODO(floitsch): we should store the metadata directly instead of storing
  // the collector. However, the old emitter still updates the data.
  final MetadataCollector _metadataCollector;
  final Iterable<js.TokenFinalizer> finalizers;

  Program(this.fragments, this.holders, this.loadMap, this.symbolsMap,
      this.typeToInterceptorMap, this._metadataCollector, this.finalizers,
      {this.needsNativeSupport,
      this.outputContainsConstantList,
      this.hasIsolateSupport,
      this.hasSoftDeferredClasses}) {
    assert(needsNativeSupport != null);
    assert(outputContainsConstantList != null);
    assert(hasIsolateSupport != null);
  }

  /// A list of metadata expressions.
  ///
  /// This list must be emitted in the `METADATA` embedded global.
  /// The list references constants and must hence be emitted after constants
  /// have been initialized.
  ///
  /// Note: the metadata is derived from the task's `metadataCollector`. The
  /// list must not be emitted before all operations on it are done. For
  /// example, the old emitter generates metadata when emitting reflection
  /// data.
  js.Expression get metadata => _metadataCollector.globalMetadata;

  /// Accessor for the list of metadata entries for a given [OutputUnit].
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

/**
 * This class represents a JavaScript object that contains static state, like
 * classes or functions.
 */
class Holder {
  final String name;
  final int index;
  final bool isStaticStateHolder;
  final bool isConstantsHolder;

  Holder(this.name, this.index,
      {this.isStaticStateHolder: false, this.isConstantsHolder: false});
}

/**
 * This class represents one output file.
 *
 * If no library is deferred, there is only one [Fragment] of type
 * [MainFragment].
 */
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

/**
 * The main output file.
 *
 * This code emitted from this [Fragment] must be loaded first. It can then load
 * other [DeferredFragment]s.
 */
class MainFragment extends Fragment {
  final js.Statement invokeMain;

  MainFragment(
      OutputUnit outputUnit,
      String outputFileName,
      this.invokeMain,
      List<Library> libraries,
      List<StaticField> staticNonFinalFields,
      List<StaticField> staticLazilyInitializedFields,
      List<Constant> constants)
      : super(outputUnit, outputFileName, libraries, staticNonFinalFields,
            staticLazilyInitializedFields, constants);

  bool get isMainFragment => true;
}

/**
 * An output (file) for deferred code.
 */
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

  bool get isMainFragment => false;
}

class Constant {
  final js.Name name;
  final Holder holder;
  final ConstantValue value;

  Constant(this.name, this.holder, this.value);
}

abstract class FieldContainer {
  List<Field> get staticFieldsForReflection;
}

class Library implements FieldContainer {
  /// The element should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final LibraryEntity element;

  final String uri;
  final List<StaticMethod> statics;
  final List<Class> classes;

  final List<Field> staticFieldsForReflection;

  Library(this.element, this.uri, this.statics, this.classes,
      this.staticFieldsForReflection);
}

class StaticField {
  /// The element should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final FieldEntity element;

  js.Name name;
  // TODO(floitsch): the holder for static fields is the isolate object. We
  // could remove this field and use the isolate object directly.
  final Holder holder;
  final js.Expression code;
  final bool isFinal;
  final bool isLazy;

  StaticField(this.element, this.name, this.holder, this.code, this.isFinal,
      this.isLazy);
}

class Class implements FieldContainer {
  /// The element should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final ClassEntity element;

  final js.Name name;
  final Holder holder;
  Class _superclass;
  final List<Method> methods;
  final List<Field> fields;
  final List<StubMethod> isChecks;
  final List<StubMethod> checkedSetters;

  /// Stub methods for this class that are call stubs for getters.
  final List<StubMethod> callStubs;

  /// noSuchMethod stubs in the special case that the class is Object.
  final List<StubMethod> noSuchMethodStubs;
  final List<Field> staticFieldsForReflection;
  final bool hasRtiField; // Per-instance runtime type information pseudo-field.
  final bool onlyForRti;
  final bool isDirectlyInstantiated;
  final bool isNative;
  final bool isClosureBaseClass; // Common base class for closures.

  /// Whether this class should be soft deferred.
  ///
  /// A soft-deferred class is only fully initialized at first instantiation.
  final bool isSoftDeferred;

  // If the class implements a function type, and the type is encoded in the
  // metatada table, then this field contains the index into that field.
  final js.Expression functionTypeIndex;

  /// Whether the class must be evaluated eagerly.
  bool isEager = false;

  /// Leaf tags. See [NativeEmitter.prepareNativeClasses].
  List<String> nativeLeafTags;

  /// Non-leaf tags. See [NativeEmitter.prepareNativeClasses].
  List<String> nativeNonLeafTags;

  /// Native extensions. See [NativeEmitter.prepareNativeClasses].
  List<Class> nativeExtensions;

  Class(
      this.element,
      this.name,
      this.holder,
      this.methods,
      this.fields,
      this.staticFieldsForReflection,
      this.callStubs,
      this.noSuchMethodStubs,
      this.checkedSetters,
      this.isChecks,
      this.functionTypeIndex,
      {this.hasRtiField,
      this.onlyForRti,
      this.isDirectlyInstantiated,
      this.isNative,
      this.isClosureBaseClass,
      this.isSoftDeferred = false}) {
    assert(onlyForRti != null);
    assert(isDirectlyInstantiated != null);
    assert(isNative != null);
    assert(isClosureBaseClass != null);
  }

  bool get isMixinApplication => false;
  Class get superclass => _superclass;

  void setSuperclass(Class superclass) {
    _superclass = superclass;
  }

  js.Name get superclassName => superclass == null ? null : superclass.name;

  int get superclassHolderIndex =>
      (superclass == null) ? 0 : superclass.holder.index;

  String toString() => 'Class(${element.name})';
}

class MixinApplication extends Class {
  Class _mixinClass;

  MixinApplication(
      ClassEntity element,
      js.Name name,
      Holder holder,
      List<Field> instanceFields,
      List<Field> staticFieldsForReflection,
      List<StubMethod> callStubs,
      List<StubMethod> checkedSetters,
      List<StubMethod> isChecks,
      js.Expression functionTypeIndex,
      {bool hasRtiField,
      bool onlyForRti,
      bool isDirectlyInstantiated})
      : super(
            element,
            name,
            holder,
            const <Method>[],
            instanceFields,
            staticFieldsForReflection,
            callStubs,
            const <StubMethod>[],
            checkedSetters,
            isChecks,
            functionTypeIndex,
            hasRtiField: hasRtiField,
            onlyForRti: onlyForRti,
            isDirectlyInstantiated: isDirectlyInstantiated,
            isNative: false,
            isClosureBaseClass: false);

  bool get isMixinApplication => true;
  Class get mixinClass => _mixinClass;

  void setMixinClass(Class mixinClass) {
    _mixinClass = mixinClass;
  }
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

  // TODO(floitsch): support renamed fields.
  Field(this.element, this.name, this.accessorName, this.getterFlags,
      this.setterFlags, this.needsCheckedSetter);

  bool get needsGetter => getterFlags != 0;
  bool get needsUncheckedSetter => setterFlags != 0;

  bool get needsInterceptedGetter => getterFlags > 1;
  bool get needsInterceptedSetter => setterFlags > 1;

  bool get needsInterceptedGetterOnReceiver => getterFlags == 2;
  bool get needsInterceptedSetterOnReceiver => setterFlags == 2;

  bool get needsInterceptedGetterOnThis => getterFlags == 3;
  bool get needsInterceptedSetterOnThis => setterFlags == 3;
}

abstract class Method {
  /// The element should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final MemberEntity element;

  /// The name of the method. If the method is a [ParameterStubMethod] for a
  /// static function, then the name can be `null`. In that case, only the
  /// [ParameterStubMethod.callName] should be used.
  final js.Name name;
  final js.Expression code;

  Method(this.element, this.name, this.code);
}

/// A method that corresponds to a method in the original Dart program.
abstract class DartMethod extends Method {
  final bool needsTearOff;
  final js.Name tearOffName;
  final List<ParameterStubMethod> parameterStubs;
  final bool canBeApplied;
  final bool canBeReflected;

  // Is non-null if [needsTearOff] or [canBeReflected].
  //
  // If the type is encoded in the metadata table this field contains an index
  // into the table. Otherwise the type contains type variables in which case
  // this field holds a function computing the function signature.
  final js.Expression functionType;

  // Signature information for this method. This is only required and stored
  // here if the method [canBeApplied] or [canBeReflected]
  final int requiredParameterCount;
  final /* Map | List */ optionalParameterDefaultValues;

  // If this method can be torn off, contains the name of the corresponding
  // call method. For example, for the member `foo$1$name` it would be
  // `call$1$name` (in unminified mode).
  final js.Name callName;

  DartMethod(FunctionEntity element, js.Name name, js.Expression code,
      this.parameterStubs, this.callName,
      {this.needsTearOff,
      this.tearOffName,
      this.canBeApplied,
      this.canBeReflected,
      this.requiredParameterCount,
      this.optionalParameterDefaultValues,
      this.functionType})
      : super(element, name, code) {
    assert(needsTearOff != null);
    assert(!needsTearOff || tearOffName != null);
    assert(canBeApplied != null);
    assert(canBeReflected != null);
    assert((!canBeReflected && !canBeApplied) ||
        (requiredParameterCount != null &&
            optionalParameterDefaultValues != null));
  }

  bool get isStatic;
}

class InstanceMethod extends DartMethod {
  /// An alternative name for this method. This is used to model calls to
  /// a method via `super`. If [aliasName] is non-null, the emitter has to
  /// ensure that this method is registered on the prototype under both [name]
  /// and [aliasName].
  final js.Name aliasName;

  /// True if this is the implicit `call` instance method of an anonymous
  /// closure. This predicate is false for explicit `call` methods and for
  /// functions that can be torn off.
  final bool isClosureCallMethod;

  InstanceMethod(FunctionEntity element, js.Name name, js.Expression code,
      List<ParameterStubMethod> parameterStubs, js.Name callName,
      {bool needsTearOff,
      js.Name tearOffName,
      this.aliasName,
      bool canBeApplied,
      bool canBeReflected,
      int requiredParameterCount,
      /* List | Map */ optionalParameterDefaultValues,
      this.isClosureCallMethod,
      js.Expression functionType})
      : super(element, name, code, parameterStubs, callName,
            needsTearOff: needsTearOff,
            tearOffName: tearOffName,
            canBeApplied: canBeApplied,
            canBeReflected: canBeReflected,
            requiredParameterCount: requiredParameterCount,
            optionalParameterDefaultValues: optionalParameterDefaultValues,
            functionType: functionType) {
    assert(isClosureCallMethod != null);
  }

  bool get isStatic => false;
}

/// A method that is generated by the backend and has not direct correspondence
/// to a method in the original Dart program. Examples are getter and setter
/// stubs and stubs to dispatch calls to methods with optional parameters.
class StubMethod extends Method {
  StubMethod(js.Name name, js.Expression code, {MemberEntity element})
      : super(element, name, code);

  String toString() {
    return 'stub[name=${name},element=${element},code=${js.nodeToString(code)}]';
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
  js.Name callName;

  ParameterStubMethod(js.Name name, this.callName, js.Expression code)
      : super(name, code);
}

abstract class StaticMethod implements Method {
  Holder get holder;
}

class StaticDartMethod extends DartMethod implements StaticMethod {
  final Holder holder;

  StaticDartMethod(
      FunctionEntity element,
      js.Name name,
      this.holder,
      js.Expression code,
      List<ParameterStubMethod> parameterStubs,
      js.Name callName,
      {bool needsTearOff,
      js.Name tearOffName,
      bool canBeApplied,
      bool canBeReflected,
      int requiredParameterCount,
      /* List | Map */ optionalParameterDefaultValues,
      js.Expression functionType})
      : super(element, name, code, parameterStubs, callName,
            needsTearOff: needsTearOff,
            tearOffName: tearOffName,
            canBeApplied: canBeApplied,
            canBeReflected: canBeReflected,
            requiredParameterCount: requiredParameterCount,
            optionalParameterDefaultValues: optionalParameterDefaultValues,
            functionType: functionType);

  bool get isStatic => true;

  String toString() {
    return 'static_method[name=${name},element=${element}}]';
  }
}

class StaticStubMethod extends StubMethod implements StaticMethod {
  Holder holder;
  StaticStubMethod(js.Name name, this.holder, js.Expression code)
      : super(name, code);
}
