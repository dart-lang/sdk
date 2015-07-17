// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

const USE_LAZY_EMITTER = const bool.fromEnvironment("dart2js.use.lazy.emitter");
const USE_STARTUP_EMITTER =
    const bool.fromEnvironment("dart2js.use.startup.emitter");

/**
 * Generates the code for all used classes in the program. Static fields (even
 * in classes) are ignored, since they can be treated as non-class elements.
 *
 * The code for the containing (used) methods must exist in the `universe`.
 */
class CodeEmitterTask extends CompilerTask {
  // TODO(floitsch): the code-emitter task should not need a namer.
  final Namer namer;
  final TypeTestRegistry typeTestRegistry;
  NativeEmitter nativeEmitter;
  MetadataCollector metadataCollector;
  Emitter emitter;

  /// Records if a type variable is read dynamically for type tests.
  final Set<TypeVariableElement> readTypeVariables =
      new Set<TypeVariableElement>();

  JavaScriptBackend get backend => compiler.backend;

  @deprecated
  // This field should be removed. It's currently only needed for dump-info and
  // tests.
  // The field is set after the program has been emitted.
  /// Contains a list of all classes that are emitted.
  Set<ClassElement> neededClasses;

  CodeEmitterTask(Compiler compiler, Namer namer, bool generateSourceMap)
      : super(compiler),
        this.namer = namer,
        this.typeTestRegistry = new TypeTestRegistry(compiler) {
    nativeEmitter = new NativeEmitter(this);
    if (USE_LAZY_EMITTER) {
      emitter = new lazy_js_emitter.Emitter(compiler, namer, nativeEmitter);
    } else if (USE_STARTUP_EMITTER) {
      emitter = new startup_js_emitter.Emitter(compiler, namer, nativeEmitter);
    } else {
      emitter =
          new full_js_emitter.Emitter(compiler, namer, generateSourceMap, this);
    }
    metadataCollector = new MetadataCollector(compiler, emitter);
  }

  String get name => 'Code emitter';

  /// Returns the closure expression of a static function.
  jsAst.Expression isolateStaticClosureAccess(FunctionElement element) {
    return emitter.isolateStaticClosureAccess(element);
  }

  /// Returns the JS function that must be invoked to get the value of the
  /// lazily initialized static.
  jsAst.Expression isolateLazyInitializerAccess(FieldElement element) {
    return emitter.isolateLazyInitializerAccess(element);
  }

  /// Returns the JS code for accessing the embedded [global].
  jsAst.Expression generateEmbeddedGlobalAccess(String global) {
    return emitter.generateEmbeddedGlobalAccess(global);
  }

  /// Returns the JS code for accessing the given [constant].
  jsAst.Expression constantReference(ConstantValue constant) {
    return emitter.constantReference(constant);
  }

  jsAst.Expression staticFieldAccess(FieldElement e) {
    return emitter.staticFieldAccess(e);
  }

  /// Returns the JS function representing the given function.
  ///
  /// The function must be invoked and can not be used as closure.
  jsAst.Expression staticFunctionAccess(FunctionElement e) {
    return emitter.staticFunctionAccess(e);
  }

  /// Returns the JS constructor of the given element.
  ///
  /// The returned expression must only be used in a JS `new` expression.
  jsAst.Expression constructorAccess(ClassElement e) {
    return emitter.constructorAccess(e);
  }

  /// Returns the JS prototype of the given class [e].
  jsAst.Expression prototypeAccess(ClassElement e,
                                   {bool hasBeenInstantiated: false}) {
    return emitter.prototypeAccess(e, hasBeenInstantiated);
  }

  /// Returns the JS prototype of the given interceptor class [e].
  jsAst.Expression interceptorPrototypeAccess(ClassElement e) {
    return jsAst.js('#.prototype', interceptorClassAccess(e));
  }

  /// Returns the JS constructor of the given interceptor class [e].
  jsAst.Expression interceptorClassAccess(ClassElement e) {
    return emitter.interceptorClassAccess(e);
  }

  /// Returns the JS expression representing the type [e].
  ///
  /// The given type [e] might be a Typedef.
  jsAst.Expression typeAccess(Element e) {
    return emitter.typeAccess(e);
  }

  /// Returns the JS template for the given [builtin].
  jsAst.Template builtinTemplateFor(JsBuiltin builtin) {
    return emitter.templateForBuiltin(builtin);
  }

  void registerReadTypeVariable(TypeVariableElement element) {
    readTypeVariables.add(element);
  }

  Set<ClassElement> _finalizeRti() {
    // Compute the required type checks to know which classes need a
    // 'is$' method.
    typeTestRegistry.computeRequiredTypeChecks();
    // Compute the classes needed by RTI.
    return typeTestRegistry.computeRtiNeededClasses();
  }

  int assembleProgram() {
    return measure(() {
      emitter.invalidateCaches();

      Set<ClassElement> rtiNeededClasses = _finalizeRti();
      ProgramBuilder programBuilder = new ProgramBuilder(
          compiler, namer, this, emitter, rtiNeededClasses);
      int size = emitter.emitProgram(programBuilder);
      // TODO(floitsch): we shouldn't need the `neededClasses` anymore.
      neededClasses = programBuilder.collector.neededClasses;
      return size;
    });
  }
}

abstract class Emitter {
  /// Uses the [programBuilder] to generate a model of the program, emits
  /// the program, and returns the size of the generated output.
  int emitProgram(ProgramBuilder programBuilder);

  /// Returns true, if the emitter supports reflection.
  bool get supportsReflection;

  /// Returns the JS function that must be invoked to get the value of the
  /// lazily initialized static.
  jsAst.Expression isolateLazyInitializerAccess(FieldElement element);

  /// Returns the closure expression of a static function.
  jsAst.Expression isolateStaticClosureAccess(FunctionElement element);

  /// Returns the JS code for accessing the embedded [global].
  jsAst.Expression generateEmbeddedGlobalAccess(String global);

  /// Returns the JS function representing the given function.
  ///
  /// The function must be invoked and can not be used as closure.
  jsAst.Expression staticFunctionAccess(FunctionElement element);

  jsAst.Expression staticFieldAccess(FieldElement element);

  /// Returns the JS constructor of the given element.
  ///
  /// The returned expression must only be used in a JS `new` expression.
  jsAst.Expression constructorAccess(ClassElement e);

  /// Returns the JS prototype of the given class [e].
  jsAst.Expression prototypeAccess(ClassElement e, bool hasBeenInstantiated);

  /// Returns the JS constructor of the given interceptor class [e].
  jsAst.Expression interceptorClassAccess(ClassElement e);

  /// Returns the JS expression representing the type [e].
  jsAst.Expression typeAccess(Element e);

  /// Returns the JS expression representing a function that returns 'null'
  jsAst.Expression generateFunctionThatReturnsNull();

  int compareConstants(ConstantValue a, ConstantValue b);
  bool isConstantInlinedOrAlreadyEmitted(ConstantValue constant);

  /// Returns the JS code for accessing the given [constant].
  jsAst.Expression constantReference(ConstantValue constant);

  /// Returns the JS template for the given [builtin].
  jsAst.Template templateForBuiltin(JsBuiltin builtin);

  void invalidateCaches();
}
