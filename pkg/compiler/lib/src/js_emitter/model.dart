// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.new_js_emitter.model;

import '../js/js.dart' as js show Expression;
import '../constants/values.dart' show ConstantValue;

import '../deferred_load.dart' show OutputUnit;

import '../common.dart';

class Program {
  final List<Fragment> fragments;
  final bool outputContainsConstantList;
  final bool outputContainsNativeClasses;
  /// A map from load id to the list of fragments that need to be loaded.
  final Map<String, List<Fragment>> loadMap;

  // If this field is not `null` then its value must be emitted in the embedded
  // global `TYPE_TO_INTERCEPTOR_MAP`. The map references constants and classes.
  final js.Expression typeToInterceptorMap;

  Program(this.fragments,
          this.loadMap,
          this.typeToInterceptorMap,
          {this.outputContainsNativeClasses,
           this.outputContainsConstantList}) {
    assert(outputContainsNativeClasses != null);
    assert(outputContainsConstantList != null);
  }

  bool get isSplit => fragments.length > 1;
  Iterable<Fragment> get deferredFragments => fragments.skip(1);
}

/**
 * This class represents a JavaScript object that contains static state, like
 * classes or functions.
 */
class Holder {
  final String name;
  final int index;
  Holder(this.name, this.index);
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

  Fragment(this.outputUnit,
           this.outputFileName,
           this.libraries,
           this.staticNonFinalFields,
           this.staticLazilyInitializedFields,
           this.constants);

  bool get isMainFragment => mainFragment == this;
  MainFragment get mainFragment;
}

/**
 * The main output file.
 *
 * This code emitted from this [Fragment] must be loaded first. It can then load
 * other [DeferredFragment]s.
 */
class MainFragment extends Fragment {
  final js.Expression main;
  final List<Holder> holders;

  MainFragment(OutputUnit outputUnit,
               String outputFileName,
               this.main,
               List<Library> libraries,
               List<StaticField> staticNonFinalFields,
               List<StaticField> staticLazilyInitializedFields,
               List<Constant> constants,
               this.holders)
      : super(outputUnit,
              outputFileName,
              libraries,
              staticNonFinalFields,
              staticLazilyInitializedFields,
              constants);

  MainFragment get mainFragment => this;
}

/**
 * An output (file) for deferred code.
 */
class DeferredFragment extends Fragment {
  final MainFragment mainFragment;
  final String name;

  List<Holder> get holders => mainFragment.holders;

  DeferredFragment(OutputUnit outputUnit,
                   String outputFileName,
                   this.name,
                   this.mainFragment,
                   List<Library> libraries,
                   List<StaticField> staticNonFinalFields,
                   List<StaticField> staticLazilyInitializedFields,
                   List<Constant> constants)
      : super(outputUnit,
              outputFileName,
              libraries,
              staticNonFinalFields,
              staticLazilyInitializedFields,
              constants);
}

class Constant {
  final String name;
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
  final Element element;

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
  final Element element;

  final String name;
  // TODO(floitsch): the holder for static fields is the isolate object. We
  // could remove this field and use the isolate object directly.
  final Holder holder;
  final js.Expression code;
  final bool isFinal;
  final bool isLazy;

  StaticField(this.element,
              this.name, this.holder, this.code,
              this.isFinal, this.isLazy);
}

class Class implements FieldContainer {
  /// The element should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final Element element;

  final String name;
  final Holder holder;
  Class _superclass;
  final List<Method> methods;
  final List<Field> fields;
  final List<StubMethod> isChecks;
  final List<StubMethod> callStubs;
  final List<Field> staticFieldsForReflection;
  final bool onlyForRti;
  final bool isDirectlyInstantiated;
  final bool isNative;

  // If the class implements a function type, and the type is encoded in the
  // metatada table, then this field contains the index into that field.
  final int functionTypeIndex;

  /// Whether the class must be evaluated eagerly.
  bool isEager = false;

  /// Data that must be emitted with the class for native interop.
  String nativeInfo;

  Class(this.element, this.name, this.holder,
        this.methods,
        this.fields,
        this.staticFieldsForReflection,
        this.callStubs,
        this.isChecks,
        this.functionTypeIndex,
        {this.onlyForRti,
         this.isDirectlyInstantiated,
         this.isNative}) {
    assert(onlyForRti != null);
    assert(isDirectlyInstantiated != null);
    assert(isNative != null);
  }

  bool get isMixinApplication => false;
  Class get superclass => _superclass;

  void setSuperclass(Class superclass) {
    _superclass = superclass;
  }

  String get superclassName
      => (superclass == null) ? "" : superclass.name;
  int get superclassHolderIndex
      => (superclass == null) ? 0 : superclass.holder.index;
}

class MixinApplication extends Class {
  Class _mixinClass;

  MixinApplication(Element element, String name, Holder holder,
                   List<Field> instanceFields,
                   List<Field> staticFieldsForReflection,
                   List<StubMethod> callStubs,
                   List<StubMethod> isChecks,
                   int functionTypeIndex,
                   {bool onlyForRti,
                    bool isDirectlyInstantiated})
      : super(element,
              name, holder,
              const <Method>[],
              instanceFields,
              staticFieldsForReflection,
              callStubs,
              isChecks, functionTypeIndex,
              onlyForRti: onlyForRti,
              isDirectlyInstantiated: isDirectlyInstantiated,
              isNative: false);

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
  final Element element;

  final String name;
  final String accessorName;

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
  Field(this.element, this.name, this.accessorName,
        this.getterFlags, this.setterFlags,
        this.needsCheckedSetter);

  bool get needsGetter => getterFlags != 0;
  bool get needsUncheckedSetter => setterFlags != 0;

  bool get needsInterceptedGetter => getterFlags > 1;
  bool get needsInterceptedSetter => setterFlags > 1;
}

abstract class Method {
  /// The element should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final Element element;
  final String name;
  final js.Expression code;

  Method(this.element, this.name, this.code);
}

/**
 * A method that corresponds to a method in the original Dart program.
 */
class DartMethod extends Method {
  final bool needsTearOff;
  final String tearOffName;
  // TODO(herhut): Directly store stubs instead/
  final bool needsStubs;
  // TODO(herhut): Directly store aliases instead.
  final bool canBeApplied;
  final bool canBeReflected;

  DartMethod(Element element, String name, js.Expression code,
      {this.needsTearOff, this.tearOffName, this.needsStubs, this.canBeApplied,
       this.canBeReflected})
      : super(element, name, code) {
    assert(needsTearOff != null);
    assert(!needsTearOff || tearOffName != null);
    assert(canBeApplied != null);
    assert(canBeReflected != null);
    assert(needsStubs != null);
  }
}

class InstanceMethod extends DartMethod {
  // TODO(herhut): Directly store aliases instead.
  final bool hasSuperAlias;
  final bool isClosure;

  InstanceMethod(element, name, code,
      {bool needsTearOff,
       String tearOffName,
       this.hasSuperAlias,
       bool canBeApplied,
       bool canBeReflected,
       this.isClosure,
       bool needsStubs})
      : super(element, name, code,
              needsTearOff: needsTearOff,
              tearOffName: tearOffName,
              canBeApplied: canBeApplied,
              canBeReflected: canBeReflected,
              needsStubs: needsStubs) {
    assert(hasSuperAlias != null);
    assert(isClosure != null);
  }
}

/**
 * A method that is generated by the backend and has not direct correspondence
 * to a method in the original Dart program. Examples are getter and setter
 * stubs and stubs to dispatch calls to methods with optional parameters.
 */
class StubMethod extends Method {
  StubMethod(String name, js.Expression code,
             {Element element})
      : super(element, name, code);
}

class StaticMethod extends DartMethod {
  final Holder holder;
  StaticMethod(Element element, String name, this.holder, js.Expression code,
               {bool needsTearOff, String tearOffName, bool canBeApplied,
                bool canBeReflected, bool needsStubs})
      : super(element, name, code,
              needsTearOff: needsTearOff,
              tearOffName : tearOffName,
              canBeApplied : canBeApplied,
              canBeReflected : canBeReflected,
              needsStubs : needsStubs);
}

class StaticStubMethod extends StubMethod {
  Holder holder;
  StaticStubMethod(String name, this.holder, js.Expression code)
      : super(name, code);
}
