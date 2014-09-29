// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.new_js_emitter.emitter;

import 'model.dart';
import 'model_emitter.dart';
import '../common.dart';
import '../js/js.dart' as js;

import '../dart2jslib.dart' show PrimitiveConstant;
import '../tree/tree.dart' show DartString;

import '../js_backend/js_backend.dart' show Namer, JavaScriptBackend;
import '../js_emitter/js_emitter.dart' as emitterTask show
    CodeEmitterTask,
    Emitter;

import '../universe/universe.dart' show Universe;
import '../deferred_load.dart' show DeferredLoadTask, OutputUnit;

part 'registry.dart';

class Emitter implements emitterTask.Emitter {
  final Compiler _compiler;
  final Namer namer;
  final emitterTask.CodeEmitterTask _oldEmitter;

  final Registry _registry;

  Emitter(Compiler compiler,
          this.namer,
          bool generateSourceMap,
          this._oldEmitter)
      : this._compiler = compiler,
        this._registry = new Registry(compiler);

  JavaScriptBackend get backend => _compiler.backend;
  Universe get universe => _compiler.codegenWorld;

  /// Mapping from [ClassElement] to constructed [Class]. We need this to
  /// update the superclass in the [Class].
  final Map<ClassElement, Class> _classes = <ClassElement, Class>{};

  /// Mapping from [OutputUnit] to constructed [Output]. We need this to
  /// generate the deferredLoadingMap (to know which hunks to load).
  final Map<OutputUnit, Output> _outputs = <OutputUnit, Output>{};

  void emitProgram() {
    Program program = _buildProgram();
    new ModelEmitter(_compiler).emitProgram(program);
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
        .map((fragment) => _buildDeferredOutput(mainOutput, fragment));

    List<Output> outputs = new List<Output>(_registry.fragmentCount);
    outputs[0] = mainOutput;
    outputs.setAll(1, deferredOutputs);

    Program result = new Program(outputs, _buildLoadMap());

    // Resolve the superclass references after we've processed all the classes.
    _classes.forEach((ClassElement element, Class c) {
      if (element.superclass != null) {
        c.setSuperclass(_classes[element.superclass]);
      }
    });
    return result;
  }

  /// Builds a map from loadId to outputs-to-load.
  Map<String, List<Output>> _buildLoadMap() {
    List<OutputUnit> convertHunks(List<OutputUnit> hunks) {
      return hunks.map((OutputUnit unit) => _outputs[unit])
          .toList(growable: false);
    }

    Map<String, List<Output>> loadMap = <String, List<Output>>{};
    _compiler.deferredLoadTask.hunksToLoad
        .forEach((String loadId, List<OutputUnit> outputUnits) {
      loadMap[loadId] = outputUnits
          .map((OutputUnit unit) => _outputs[unit])
          .toList(growable: false);
    });
    return loadMap;
  }

  MainOutput _buildMainOutput(Fragment fragment) {
    // Construct the main output from the libraries and the registered holders.
    MainOutput result = new MainOutput(
        "",  // The empty string is the name for the main output file.
        namer.elementAccess(_compiler.mainFunction),
        _buildLibraries(fragment),
        _registry.holders.toList(growable: false));
    _outputs[fragment.outputUnit] = result;
    return result;
  }

  /// Returns a name composed of the main output file name and [name].
  String _outputFileName(String name) {
    assert(name != "");
    String outPath = _compiler.outputUri != null
        ? _compiler.outputUri.path
        : "out";
    String outName = outPath.substring(outPath.lastIndexOf('/') + 1);
    return "${outName}_$name";
  }

  DeferredOutput _buildDeferredOutput(MainOutput mainOutput,
                                      Fragment fragment) {
    DeferredOutput result = new DeferredOutput(
        _outputFileName(fragment.name), fragment.name,
        mainOutput, _buildLibraries(fragment));
    _outputs[fragment.outputUnit] = result;
    return result;
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
      if (Elements.isNonAbstractInstanceMethod(member)) {
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
    js.Expression code = js.string("<<unimplemented>>");
    return new StaticMethod(name, _registry.registerHolder(holder), code);
  }

  // TODO(floitsch): copied from OldEmitter. Adjust or share.
  bool isConstantInlinedOrAlreadyEmitted(Constant constant) {
    if (constant.isFunction) return true;    // Already emitted.
    if (constant.isPrimitive) return true;   // Inlined.
    if (constant.isDummy) return true;       // Inlined.
    // The name is null when the constant is already a JS constant.
    // TODO(floitsch): every constant should be registered, so that we can
    // share the ones that take up too much space (like some strings).
    if (namer.constantName(constant) == null) return true;
    return false;
  }

  // TODO(floitsch): copied from OldEmitter. Adjust or share.
  int compareConstants(Constant a, Constant b) {
    // Inlined constants don't affect the order and sometimes don't even have
    // names.
    int cmp1 = isConstantInlinedOrAlreadyEmitted(a) ? 0 : 1;
    int cmp2 = isConstantInlinedOrAlreadyEmitted(b) ? 0 : 1;
    if (cmp1 + cmp2 < 2) return cmp1 - cmp2;

    // Emit constant interceptors first. Constant interceptors for primitives
    // might be used by code that builds other constants.  See Issue 18173.
    if (a.isInterceptor != b.isInterceptor) {
      return a.isInterceptor ? -1 : 1;
    }

    // Sorting by the long name clusters constants with the same constructor
    // which compresses a tiny bit better.
    int r = namer.constantLongName(a).compareTo(namer.constantLongName(b));
    if (r != 0) return r;
    // Resolve collisions in the long name by using the constant name (i.e. JS
    // name) which is unique.
    return namer.constantName(a).compareTo(namer.constantName(b));
  }

  js.Expression generateEmbeddedGlobalAccess(String global) {
    // TODO(floitsch): We should not use "init" for globals.
    return js.string("init.$global");
  }

  js.Expression constantReference(Constant value) {
    if (!value.isPrimitive) return js.string("<<unimplemented>>");
    PrimitiveConstant constant = value;
    if (constant.isBool) return new js.LiteralBool(constant.isTrue);
    if (constant.isString) {
      DartString dartString = constant.value;
      return js.string(dartString.slowToString());
    }
    if (constant.isNum) return js.number(constant.value);
    if (constant.isNull) return new js.LiteralNull();
    return js.string("<<unimplemented>>");
  }

  void invalidateCaches() {}
}
