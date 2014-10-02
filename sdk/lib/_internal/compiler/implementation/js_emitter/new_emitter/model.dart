// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.new_js_emitter.model;

import '../../js/js.dart' as js show Expression;

class Program {
  final List<Output> outputs;
  /// A map from load id to the list of outputs that need to be loaded.
  final Map<String, List<Output>> loadMap;

  Program(this.outputs, this.loadMap);
}

class Holder {
  final String name;
  final int index;
  Holder(this.name, this.index);
}

abstract class Output {
  bool get isMainOutput => mainOutput == this;
  MainOutput get mainOutput;
  final List<Library> libraries;

  /// Output file name without extension.
  final String outputFileName;

  Output(this.outputFileName, this.libraries);
}

class MainOutput extends Output {
  final js.Expression main;
  final List<Holder> holders;

  MainOutput(
      String outputFileName, this.main, List<Library> libraries, this.holders)
      : super(outputFileName, libraries);

  MainOutput get mainOutput => this;
}

class DeferredOutput extends Output {
  final MainOutput mainOutput;
  final String name;

  List<Holder> get holders => mainOutput.holders;

  DeferredOutput(String outputFileName, this.name,
                 this.mainOutput, List<Library> libraries)
      : super(outputFileName, libraries);
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
