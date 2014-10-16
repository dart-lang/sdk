// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.new_js_emitter.model;

import '../js/js.dart' as js show Expression;
import '../constants/values.dart' show ConstantValue;

class Program {
  final List<Output> outputs;
  /// A map from load id to the list of outputs that need to be loaded.
  final Map<String, List<Output>> loadMap;

  Program(this.outputs, this.loadMap);
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

  /// Output file name without extension.
  final String outputFileName;

  Output(this.outputFileName,
         this.libraries,
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
             List<Constant> constants,
             this.holders)
      : super(outputFileName, libraries, constants);

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
                 List<Constant> constants)
      : super(outputFileName, libraries, constants);
}

class Constant {
  final String name;
  final Holder holder;
  final ConstantValue value;

  Constant(this.name, this.holder, this.value);
}

class Library {
  final String uri;
  final List<StaticMethod> statics;
  final List<Class> classes;
  Library(this.uri, this.statics, this.classes);
}

class Class {
  final String name;
  final Holder holder;
  Class superclass;
  final List<Method> methods;
  Class(this.name, this.holder, this.methods);

  void setSuperclass(Class superclass) {
    this.superclass = superclass;
  }

  String get superclassName
      => (superclass == null) ? "" : superclass.name;
  int get superclassHolderIndex
      => (superclass == null) ? 0 : superclass.holder.index;
}

class Method {
  final String name;
  final js.Expression code;
  Method(this.name, this.code);
}

class StaticMethod extends Method {
  final Holder holder;
  StaticMethod(String name, this.holder, js.Expression code)
      : super(name, code);
}
