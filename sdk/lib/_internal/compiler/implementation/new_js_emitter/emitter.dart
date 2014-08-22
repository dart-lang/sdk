// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.new_js_emitter.emitter;

import 'model.dart';
import '../common.dart';
import '../js/js.dart' as js;

import '../js_backend/js_backend.dart' show Namer, JavaScriptBackend;
import '../js_emitter/js_emitter.dart' show CodeEmitterTask;
import '../universe/universe.dart' show Universe;
import '../deferred_load.dart' show DeferredLoadTask, OutputUnit;

part 'registry.dart';

class Emitter {
  final Compiler _compiler;
  final CodeEmitterTask _oldEmitter;

  final Registry _registry;

  Emitter(Compiler compiler, this._oldEmitter)
      : this._compiler = compiler,
        this._registry = new Registry(compiler.deferredLoadTask);

  JavaScriptBackend get backend => _compiler.backend;
  Namer get namer => _oldEmitter.namer;
  Universe get universe => _compiler.codegenWorld;

  /// Mapping from [ClassElement] to constructed [Class]. We need this to
  /// update the superclass in the [Class].
  final Map<ClassElement, Class> _classes = <ClassElement, Class>{};

  void emitProgram() {
    Program program = _buildProgram();
    program.emit(_compiler);
  }

  Program _buildProgram() {
    Set<ClassElement> neededClasses = _oldEmitter.neededClasses;
    Iterable<Element> neededStatics = backend.generatedCode.keys
        .where((Element e) => !e.isInstanceMember && !e.isField);

    Elements.sortedByPosition(neededClasses).forEach(_registry.registerElement);
    Elements.sortedByPosition(neededStatics).forEach(_registry.registerElement);

    // TODO(kasperl): There's code that implicitly needs access to the special
    // $ holder so we have to register that. Can we track if we have to?
    _registry.registerHolder(r'$');

    MainOutput mainOutput = _buildMainOutput(_registry.mainFragment);
    Iterable<Output> deferredOutputs = _registry.deferredFragments
        .skip(1) // Skip the main library elements.
        .map((fragment) => _buildDeferredOutput(mainOutput, fragment));

    List<Output> outputs = new List<Output>(_registry.fragmentCount);
    outputs[0] = mainOutput;
    outputs.setAll(1, deferredOutputs);

    Program result = new Program(outputs);

    // Resolve the superclass references after we've processed all the classes.
    _classes.forEach((ClassElement element, Class c) {
      if (element.superclass != null) {
        c.setSuperclass(_classes[element.superclass]);
      }
    });
    return result;
  }

  MainOutput _buildMainOutput(Fragment fragment) {
    // Construct the main output from the libraries and the registered holders.
    return new MainOutput(
        namer.elementAccess(_compiler.mainFunction),
        _buildLibraries(fragment),
        _registry.holders.toList(growable: false));
  }

  DeferredOutput _buildDeferredOutput(MainOutput mainOutput,
                                      Fragment fragment) {
    return new DeferredOutput(mainOutput, _buildLibraries(fragment));
  }

  List<Library> _buildLibraries(Fragment fragment) {
    List<Library> libraries = new List<Library>(fragment.length);
    int count = 0;
    fragment.forEach((LibraryElement library, List<Element> elements) {
      libraries[count++] = _buildLibrary(library, elements);
    });
    return libraries;
  }

  // Note that a library-element may have multiple [Library]s, if it is split
  // into multiple output units.
  Library _buildLibrary(LibraryElement library, List<Element> elements) {
    String uri = library.canonicalUri.toString();

    List<StaticMethod> statics = elements
        .where((e) => e is FunctionElement).map(_buildStaticMethod).toList();

    statics.addAll(elements
        .where((e) => e is FunctionElement)
        .where((e) => universe.staticFunctionsNeedingGetter.contains(e))
        .map(_buildStaticMethodTearOff));

    List<Class> classes = elements
        .where((e) => e is ClassElement)
        .map(_buildClass)
        .toList(growable: false);

    return new Library(uri, statics, classes);
  }

  Class _buildClass(ClassElement element) {
    List<Method> methods = [];
    void visitMember(ClassElement enclosing, Element member) {
      assert(invariant(element, member.isDeclaration));
      if (!member.isAbstract && member.isInstanceMember && member.isFunction) {
        js.Expression code = backend.generatedCode[member];
        // TODO(kasperl): Figure out under which conditions code is null.
        if (code != null) methods.add(_buildMethod(member, code));
      }
    }
    ClassElement implementation = element.implementation;
    implementation.forEachMember(visitMember, includeBackendMembers: true);
    String name = namer.getNameOfClass(element);
    String holder = namer.globalObjectFor(element);
    Class result = new Class(name, _registry.registerHolder(holder), methods);
    _classes[element] = result;
    return result;
  }

  Method _buildMethod(FunctionElement element, js.Expression code) {
    String name = namer.getNameOfInstanceMember(element);
    return new Method(name, code);
  }

  StaticMethod _buildStaticMethod(FunctionElement element) {
    String name = namer.getNameOfMember(element);
    String holder = namer.globalObjectFor(element);
    js.Expression code = backend.generatedCode[element];
    return new StaticMethod(name, _registry.registerHolder(holder), code);
  }

  StaticMethod _buildStaticMethodTearOff(FunctionElement element) {
    String name = namer.getStaticClosureName(element);
    String holder = namer.globalObjectFor(element);
    // TODO(kasperl): This clearly doesn't work yet.
    js.Expression code = js.js.string("<<unimplemented>>");
    return new StaticMethod(name, _registry.registerHolder(holder), code);
  }
}
