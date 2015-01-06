// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.new_js_emitter.model;

import '../js/js.dart' as js show Expression;
import '../constants/values.dart' show ConstantValue;

import '../common.dart';

class Program {
  final List<Output> outputs;
  final bool outputContainsConstantList;
  /// A map from load id to the list of outputs that need to be loaded.
  final Map<String, List<Output>> loadMap;

  Program(this.outputs, this.outputContainsConstantList, this.loadMap);
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
 * If no library is deferred, there is only one [Output] of type [MainOutput].
 */
abstract class Output {
  bool get isMainOutput => mainOutput == this;
  MainOutput get mainOutput;
  final List<Library> libraries;
  final List<Constant> constants;
  // TODO(floitsch): should we move static fields into libraries or classes?
  final List<StaticField> staticNonFinalFields;
  // TODO(floitsch): lazy fields should be in their library or even class.
  final List<StaticField> staticLazilyInitializedFields;

  /// Output file name without extension.
  final String outputFileName;

  Output(this.outputFileName,
         this.libraries,
         this.staticNonFinalFields,
         this.staticLazilyInitializedFields,
         this.constants);
}

/**
 * The main output file.
 *
 * This code emitted from this [Output] must be loaded first. It can then load
 * other [DeferredOutput]s.
 */
class MainOutput extends Output {
  final js.Expression main;
  final List<Holder> holders;

  MainOutput(String outputFileName,
             this.main,
             List<Library> libraries,
             List<StaticField> staticNonFinalFields,
             List<StaticField> staticLazilyInitializedFields,
             List<Constant> constants,
             this.holders)
      : super(outputFileName,
              libraries,
              staticNonFinalFields,
              staticLazilyInitializedFields,
              constants);

  MainOutput get mainOutput => this;
}

/**
 * An output (file) for deferred code.
 */
class DeferredOutput extends Output {
  final MainOutput mainOutput;
  final String name;

  List<Holder> get holders => mainOutput.holders;

  DeferredOutput(String outputFileName,
                 this.name,
                 this.mainOutput,
                 List<Library> libraries,
                 List<StaticField> staticNonFinalFields,
                 List<StaticField> staticLazilyInitializedFields,
                 List<Constant> constants)
      : super(outputFileName,
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

class Library {
  /// The element should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final Element element;

  final String uri;
  final List<StaticMethod> statics;
  final List<Class> classes;

  Library(this.element, this.uri, this.statics, this.classes);
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

class Class {
  /// The element should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final Element element;

  final String name;
  final Holder holder;
  Class _superclass;
  final List<Method> methods;
  final List<InstanceField> fields;
  final bool onlyForRti;
  final bool isDirectlyInstantiated;

  /// Whether the class must be evaluated eagerly.
  bool isEager = false;

  Class(this.element,
        this.name, this.holder, this.methods, this.fields,
        {this.onlyForRti,
         this.isDirectlyInstantiated}) {
    assert(onlyForRti != null);
    assert(isDirectlyInstantiated != null);
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

  MixinApplication(Element element,
                   String name, Holder holder,
                   List<Method> methods,
                   List<InstanceField> fields,
                   {bool onlyForRti,
                    bool isDirectlyInstantiated})
      : super(element,
              name, holder, methods, fields,
              onlyForRti: onlyForRti,
              isDirectlyInstantiated: isDirectlyInstantiated);

  bool get isMixinApplication => true;
  Class get mixinClass => _mixinClass;

  void setMixinClass(Class mixinClass) {
    _mixinClass = mixinClass;
  }
}

class InstanceField {
  /// The element should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final Element element;

  final String name;

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

  // TODO(floitsch): support renamed fields.
  InstanceField(this.element, this.name, this.getterFlags, this.setterFlags);

  bool get needsGetter => getterFlags != 0;
  bool get needsSetter => setterFlags != 0;
}

class Method {
  /// The element should only be used during the transition to the new model.
  /// Uses indicate missing information in the model.
  final Element element;

  final String name;
  final js.Expression code;
  Method(this.element, this.name, this.code);
}

class StubMethod extends Method {
  StubMethod(String name, js.Expression code) : super(null, name, code);
}

class StaticMethod extends Method {
  final Holder holder;
  StaticMethod(Element element, String name, this.holder, js.Expression code)
      : super(element, name, code);
}

class StaticStubMethod extends StaticMethod {
  StaticStubMethod(String name, Holder holder, js.Expression code)
      : super(null, name, holder, code);
}
