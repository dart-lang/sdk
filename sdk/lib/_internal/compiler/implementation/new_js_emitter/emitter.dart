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

class Emitter {
  final Compiler compiler;
  final CodeEmitterTask oldEmitter;

  Emitter(this.compiler, this.oldEmitter);

  Set<ClassElement> get neededClasses => oldEmitter.neededClasses;
  JavaScriptBackend get backend => compiler.backend;
  Namer get namer => oldEmitter.namer;
  Universe get universe => compiler.codegenWorld;

  final Map<LibraryElement, List<Element>> _libraryElements =
      <LibraryElement, List<Element>>{};
  final Map<ClassElement, Class> _classes =
      <ClassElement, Class>{};
  final Map<String, Holder> _holders =
      <String, Holder>{};

  void emitProgram() {
    Program program = _buildProgram();
    String code = js.prettyPrint(program.emit(compiler), compiler)
        .getText();
    compiler.outputProvider('', 'js')
        ..add(oldEmitter.buildGeneratedBy())
        ..add(code)
        ..close();
    compiler.assembledCode = code;
  }

  Program _buildProgram() {
    Iterable<Element> neededStatics = backend.generatedCode.keys
        .where((Element e) => !e.isInstanceMember && !e.isField);

    Elements.sortedByPosition(neededClasses).forEach(_registerElement);
    Elements.sortedByPosition(neededStatics).forEach(_registerElement);

    // TODO(kasperl): There's code that implicitly needs access to the special
    // $ holder so we have to register that. Can we track if we have to?
    _registerHolder(r'$');

    // Construct the program from the libraries and the registered holders.
    Iterable<Library> libraries = _libraryElements.keys.map(_buildLibrary);
    Program result = new Program(
        namer.elementAccess(compiler.mainFunction),
        libraries.toList(growable: false),
        _holders.values.toList(growable: false));

    // Resolve the superclass references after we've processed all the classes.
    _classes.forEach((ClassElement element, Class c) {
      if (element.superclass != null) {
        c.setSuperclass(_classes[element.superclass]);
      }
    });
    return result;
  }

  Library _buildLibrary(LibraryElement library) {
    List<Element> elements = _libraryElements[library];
    String uri = library.canonicalUri.toString();

    List<StaticMethod> statics = elements
        .where((e) => e is FunctionElement)
        .map(_buildStaticMethod)
        .toList();

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
    implementation.forEachMember(visitMember,includeBackendMembers: true);
    String name = namer.getNameOfClass(element);
    String holder = namer.globalObjectFor(element);
    Class result = new Class(name, _registerHolder(holder), methods);
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
    return new StaticMethod(name, _registerHolder(holder), code);
  }

  StaticMethod _buildStaticMethodTearOff(FunctionElement element) {
    String name = namer.getStaticClosureName(element);
    String holder = namer.globalObjectFor(element);
    // TODO(kasperl): This clearly doesn't work yet.
    js.Expression code = js.js.string("<<unimplemented>>");
    return new StaticMethod(name, _registerHolder(holder), code);
  }

  void _registerElement(Element element) {
    _libraryElements.putIfAbsent(element.library, () => []).add(element);
  }

  Holder _registerHolder(String name) {
    return _holders.putIfAbsent(name, () => new Holder(name, _holders.length));
  }
}

