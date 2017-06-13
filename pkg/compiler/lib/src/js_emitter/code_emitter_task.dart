// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.code_emitter_task;

import 'package:js_runtime/shared/embedded_names.dart' show JsBuiltin;

import '../common.dart';
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../constants/values.dart';
import '../deferred_load.dart' show OutputUnit;
import '../elements/entities.dart';
import '../js/js.dart' as jsAst;
import '../js_backend/js_backend.dart' show JavaScriptBackend, Namer;
import '../universe/world_builder.dart' show CodegenWorldBuilder;
import '../world.dart' show ClosedWorld;
import 'full_emitter/emitter.dart' as full_js_emitter;
import 'lazy_emitter/emitter.dart' as lazy_js_emitter;
import 'program_builder/program_builder.dart';
import 'startup_emitter/emitter.dart' as startup_js_emitter;

import 'metadata_collector.dart' show MetadataCollector;
import 'native_emitter.dart' show NativeEmitter;
import 'type_test_registry.dart' show TypeTestRegistry;
import 'sorter.dart';

const USE_LAZY_EMITTER = const bool.fromEnvironment("dart2js.use.lazy.emitter");

/**
 * Generates the code for all used classes in the program. Static fields (even
 * in classes) are ignored, since they can be treated as non-class elements.
 *
 * The code for the containing (used) methods must exist in the `universe`.
 */
class CodeEmitterTask extends CompilerTask {
  TypeTestRegistry typeTestRegistry;
  NativeEmitter _nativeEmitter;
  MetadataCollector metadataCollector;
  EmitterFactory _emitterFactory;
  Emitter _emitter;
  final Compiler compiler;

  /// The [Sorter] use for ordering elements in the generated JavaScript.
  final Sorter sorter;

  JavaScriptBackend get backend => compiler.backend;

  @deprecated
  // This field should be removed. It's currently only needed for dump-info and
  // tests.
  // The field is set after the program has been emitted.
  /// Contains a list of all classes that are emitted.
  Set<ClassEntity> neededClasses;

  CodeEmitterTask(
      Compiler compiler, bool generateSourceMap, bool useStartupEmitter)
      : compiler = compiler,
        sorter = compiler.backendStrategy.sorter,
        super(compiler.measurer) {
    if (USE_LAZY_EMITTER) {
      _emitterFactory = new lazy_js_emitter.EmitterFactory();
    } else if (useStartupEmitter) {
      _emitterFactory = new startup_js_emitter.EmitterFactory(
          generateSourceMap: generateSourceMap);
    } else {
      _emitterFactory = new full_js_emitter.EmitterFactory(
          generateSourceMap: generateSourceMap);
    }
  }

  NativeEmitter get nativeEmitter {
    assert(
        _nativeEmitter != null,
        failedAt(
            NO_LOCATION_SPANNABLE, "NativeEmitter has not been created yet."));
    return _nativeEmitter;
  }

  Emitter get emitter {
    assert(_emitter != null,
        failedAt(NO_LOCATION_SPANNABLE, "Emitter has not been created yet."));
    return _emitter;
  }

  String get name => 'Code emitter';

  /// Returns true, if the emitter supports reflection.
  bool get supportsReflection => _emitterFactory.supportsReflection;

  /// Returns the closure expression of a static function.
  jsAst.Expression isolateStaticClosureAccess(FunctionEntity element) {
    return emitter.isolateStaticClosureAccess(element);
  }

  /// Returns the JS function that must be invoked to get the value of the
  /// lazily initialized static.
  jsAst.Expression isolateLazyInitializerAccess(FieldEntity element) {
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

  jsAst.Expression staticFieldAccess(FieldEntity e) {
    return emitter.staticFieldAccess(e);
  }

  /// Returns the JS function representing the given function.
  ///
  /// The function must be invoked and can not be used as closure.
  jsAst.Expression staticFunctionAccess(FunctionEntity e) {
    return emitter.staticFunctionAccess(e);
  }

  /// Returns the JS constructor of the given element.
  ///
  /// The returned expression must only be used in a JS `new` expression.
  jsAst.Expression constructorAccess(ClassEntity e) {
    return emitter.constructorAccess(e);
  }

  /// Returns the JS prototype of the given class [e].
  jsAst.Expression prototypeAccess(ClassEntity e,
      {bool hasBeenInstantiated: false}) {
    return emitter.prototypeAccess(e, hasBeenInstantiated);
  }

  /// Returns the JS prototype of the given interceptor class [e].
  jsAst.Expression interceptorPrototypeAccess(ClassEntity e) {
    return jsAst.js('#.prototype', interceptorClassAccess(e));
  }

  /// Returns the JS constructor of the given interceptor class [e].
  jsAst.Expression interceptorClassAccess(ClassEntity e) {
    return emitter.interceptorClassAccess(e);
  }

  /// Returns the JS expression representing the type [e].
  ///
  /// The given type [e] might be a Typedef.
  jsAst.Expression typeAccess(Entity e) {
    return emitter.typeAccess(e);
  }

  /// Returns the JS template for the given [builtin].
  jsAst.Template builtinTemplateFor(JsBuiltin builtin) {
    return emitter.templateForBuiltin(builtin);
  }

  void _finalizeRti() {
    // Compute the required type checks to know which classes need a
    // 'is$' method.
    typeTestRegistry.computeRequiredTypeChecks(backend.rtiChecksBuilder);
    // Compute the classes needed by RTI.
    typeTestRegistry.computeRtiNeededClasses(backend.rtiSubstitutions,
        backend.mirrorsData, backend.generatedCode.keys);
  }

  /// Creates the [Emitter] for this task.
  void createEmitter(Namer namer, ClosedWorld closedWorld,
      CodegenWorldBuilder codegenWorldBuilder) {
    measure(() {
      _nativeEmitter = new NativeEmitter(this, closedWorld, codegenWorldBuilder,
          backend.nativeCodegenEnqueuer);
      _emitter = _emitterFactory.createEmitter(this, namer, closedWorld);
      metadataCollector = new MetadataCollector(
          compiler.options,
          compiler.reporter,
          compiler.deferredLoadTask,
          _emitter,
          backend.constants,
          backend.typeVariableCodegenAnalysis,
          backend.mirrorsData,
          backend.rtiEncoder);
      typeTestRegistry = new TypeTestRegistry(
          codegenWorldBuilder, closedWorld, compiler.elementEnvironment);
    });
  }

  int assembleProgram(Namer namer, ClosedWorld closedWorld) {
    return measure(() {
      _finalizeRti();
      ProgramBuilder programBuilder = new ProgramBuilder(
          compiler.options,
          compiler.reporter,
          compiler.elementEnvironment,
          compiler.commonElements,
          compiler.types,
          compiler.deferredLoadTask,
          compiler.closureToClassMapper,
          compiler.codegenWorldBuilder,
          backend.nativeCodegenEnqueuer,
          closedWorld.backendUsage,
          backend.constants,
          closedWorld.nativeData,
          backend.rtiNeed,
          backend.mirrorsData,
          closedWorld.interceptorData,
          backend.superMemberData,
          typeTestRegistry.rtiChecks,
          backend.rtiEncoder,
          backend.rtiSubstitutions,
          backend.jsInteropAnalysis,
          backend.oneShotInterceptorData,
          backend.customElementsCodegenAnalysis,
          backend.generatedCode,
          namer,
          this,
          closedWorld,
          typeTestRegistry.rtiNeededClasses,
          compiler.mainFunction,
          isMockCompilation: compiler.isMockCompilation);
      int size = emitter.emitProgram(programBuilder);
      // TODO(floitsch): we shouldn't need the `neededClasses` anymore.
      neededClasses = programBuilder.collector.neededClasses;
      return size;
    });
  }
}

abstract class EmitterFactory {
  /// Returns true, if the emitter supports reflection.
  bool get supportsReflection;

  /// Create the [Emitter] for the emitter [task] that uses the given [namer].
  Emitter createEmitter(
      CodeEmitterTask task, Namer namer, ClosedWorld closedWorld);
}

abstract class Emitter {
  /// Uses the [programBuilder] to generate a model of the program, emits
  /// the program, and returns the size of the generated output.
  int emitProgram(ProgramBuilder programBuilder);

  /// Returns the JS function that must be invoked to get the value of the
  /// lazily initialized static.
  jsAst.Expression isolateLazyInitializerAccess(FieldEntity element);

  /// Returns the closure expression of a static function.
  jsAst.Expression isolateStaticClosureAccess(FunctionEntity element);

  /// Returns the JS code for accessing the embedded [global].
  jsAst.Expression generateEmbeddedGlobalAccess(String global);

  /// Returns the JS function representing the given function.
  ///
  /// The function must be invoked and can not be used as closure.
  jsAst.Expression staticFunctionAccess(FunctionEntity element);

  jsAst.Expression staticFieldAccess(FieldEntity element);

  /// Returns the JS constructor of the given element.
  ///
  /// The returned expression must only be used in a JS `new` expression.
  jsAst.Expression constructorAccess(ClassEntity e);

  /// Returns the JS prototype of the given class [e].
  jsAst.Expression prototypeAccess(ClassEntity e, bool hasBeenInstantiated);

  /// Returns the JS constructor of the given interceptor class [e].
  jsAst.Expression interceptorClassAccess(ClassEntity e);

  /// Returns the JS expression representing the type [e].
  jsAst.Expression typeAccess(Entity e);

  /// Returns the JS expression representing a function that returns 'null'
  jsAst.Expression generateFunctionThatReturnsNull();

  int compareConstants(ConstantValue a, ConstantValue b);
  bool isConstantInlinedOrAlreadyEmitted(ConstantValue constant);

  /// Returns the JS code for accessing the given [constant].
  jsAst.Expression constantReference(ConstantValue constant);

  /// Returns the JS template for the given [builtin].
  jsAst.Template templateForBuiltin(JsBuiltin builtin);

  /// Returns the size of the code generated for a given output [unit].
  int generatedSize(OutputUnit unit);
}

abstract class EmitterBase implements Emitter {
  Namer get namer;

  jsAst.PropertyAccess globalPropertyAccessForMember(MemberEntity element) {
    jsAst.Name name = namer.globalPropertyNameForMember(element);
    jsAst.PropertyAccess pa = new jsAst.PropertyAccess(
        new jsAst.VariableUse(namer.globalObjectForMember(element)), name);
    return pa;
  }

  jsAst.PropertyAccess globalPropertyAccessForClass(ClassEntity element) {
    jsAst.Name name = namer.globalPropertyNameForClass(element);
    jsAst.PropertyAccess pa = new jsAst.PropertyAccess(
        new jsAst.VariableUse(namer.globalObjectForClass(element)), name);
    return pa;
  }

  jsAst.PropertyAccess globalPropertyAccessForType(Entity element) {
    jsAst.Name name = namer.globalPropertyNameForType(element);
    jsAst.PropertyAccess pa = new jsAst.PropertyAccess(
        new jsAst.VariableUse(namer.globalObjectForType(element)), name);
    return pa;
  }

  @override
  jsAst.PropertyAccess staticFieldAccess(FieldEntity element) {
    return globalPropertyAccessForMember(element);
  }

  @override
  jsAst.PropertyAccess staticFunctionAccess(FunctionEntity element) {
    return globalPropertyAccessForMember(element);
  }

  @override
  jsAst.PropertyAccess constructorAccess(ClassEntity element) {
    return globalPropertyAccessForClass(element);
  }

  @override
  jsAst.PropertyAccess interceptorClassAccess(ClassEntity element) {
    return globalPropertyAccessForClass(element);
  }

  @override
  jsAst.PropertyAccess typeAccess(Entity element) {
    return globalPropertyAccessForType(element);
  }
}
