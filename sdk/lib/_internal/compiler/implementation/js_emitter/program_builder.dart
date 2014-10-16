// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.program_builder;

import 'model.dart';
import '../common.dart';
import '../js/js.dart' as js;

import '../js_backend/js_backend.dart' show Namer, JavaScriptBackend;
import '../js_emitter/js_emitter.dart' as emitterTask show
    CodeEmitterTask,
    Emitter;

import '../universe/universe.dart' show Universe;
import '../deferred_load.dart' show DeferredLoadTask, OutputUnit;

part 'registry.dart';

class ProgramBuilder {
  final Compiler _compiler;
  final Namer namer;
  final emitterTask.CodeEmitterTask _task;

  final Registry _registry;

  ProgramBuilder(Compiler compiler,
                 this.namer,
                 this._task)
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

  /// Mapping from [ConstantValue] to constructed [Constant]. We need this to
  /// update field-initializers to point to the ConstantModel.
  final Map<ConstantValue, Constant> _constants = <ConstantValue, Constant>{};

  Program buildProgram() {
    _task.outputClassLists.forEach(_registry.registerElements);
    _task.outputStaticLists.forEach(_registry.registerElements);

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
        _buildConstants(fragment),
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
        mainOutput,
        _buildLibraries(fragment),
        _buildConstants(fragment));
    _outputs[fragment.outputUnit] = result;
    return result;
  }

  List<Constant> _buildConstants(Fragment fragment) {
    List<ConstantValue> constantValues =
        _task.outputConstantLists[fragment.outputUnit];
    if (constantValues == null) return const <Constant>[];
    return constantValues.map((ConstantValue constantValue) {
      assert(!_constants.containsKey(constantValue));
      String name = namer.constantName(constantValue);
      String constantObject = namer.globalObjectForConstant(constantValue);
      Holder holder = _registry.registerHolder(constantObject);
      Constant constant = new Constant(name, holder, constantValue);
      _constants[constantValue] = constant;
      return constant;
    }).toList();
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
}
