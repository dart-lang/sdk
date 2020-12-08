// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.code_emitter_task;

import '../common.dart';
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../constants/values.dart';
import '../deferred_load.dart' show OutputUnit;
import '../elements/entities.dart';
import '../js/js.dart' as jsAst;
import '../js_backend/backend.dart' show CodegenInputs;
import '../js_backend/inferred_data.dart';
import '../js_backend/namer.dart' show Namer;
import '../js_model/js_strategy.dart';
import '../options.dart';
import '../universe/codegen_world_builder.dart';
import '../world.dart' show JClosedWorld;
import 'program_builder/program_builder.dart';
import 'startup_emitter/emitter.dart' as startup_js_emitter;
import 'startup_emitter/fragment_merger.dart' as fragment_merger;

import 'metadata_collector.dart' show MetadataCollector;
import 'model.dart';
import 'native_emitter.dart' show NativeEmitter;
import 'type_test_registry.dart' show TypeTestRegistry;

/// Generates the code for all used classes in the program. Static fields (even
/// in classes) are ignored, since they can be treated as non-class elements.
///
/// The code for the containing (used) methods must exist in the `universe`.
class CodeEmitterTask extends CompilerTask {
  TypeTestRegistry typeTestRegistry;
  NativeEmitter _nativeEmitter;
  MetadataCollector metadataCollector;
  Emitter _emitter;
  final Compiler _compiler;
  final bool _generateSourceMap;

  JsBackendStrategy get _backendStrategy => _compiler.backendStrategy;

  CompilerOptions get options => _compiler.options;

  @deprecated
  // This field should be removed. It's currently only needed for dump-info and
  // tests.
  // The field is set after the program has been emitted.
  /// Contains a list of all classes that are emitted.
  Set<ClassEntity> neededClasses;

  CodeEmitterTask(this._compiler, this._generateSourceMap)
      : super(_compiler.measurer);

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

  @override
  String get name => 'Code emitter';

  void _finalizeRti(CodegenInputs codegen, CodegenWorld codegenWorld) {
    // Compute the required type checks to know which classes need a
    // 'is$' method.
    typeTestRegistry.computeRequiredTypeChecks(
        _backendStrategy.rtiChecksBuilder, codegenWorld);
    // Compute the classes needed by RTI.
    typeTestRegistry.computeRtiNeededClasses(
        codegen.rtiSubstitutions, _backendStrategy.generatedCode.keys);
  }

  /// Creates the [Emitter] for this task.
  void createEmitter(
      Namer namer, CodegenInputs codegen, JClosedWorld closedWorld) {
    measure(() {
      _nativeEmitter = new NativeEmitter(
          this, closedWorld, _backendStrategy.nativeCodegenEnqueuer);
      _emitter = new startup_js_emitter.EmitterImpl(
          _compiler.options,
          _compiler.reporter,
          _compiler.outputProvider,
          _compiler.dumpInfoTask,
          namer,
          closedWorld,
          codegen.rtiRecipeEncoder,
          _nativeEmitter,
          _backendStrategy.sourceInformationStrategy,
          this,
          _generateSourceMap);
      metadataCollector = new MetadataCollector(
          _compiler.options,
          _compiler.reporter,
          _emitter,
          codegen.rtiRecipeEncoder,
          closedWorld.elementEnvironment);
      typeTestRegistry = new TypeTestRegistry(
          _compiler.options, closedWorld.elementEnvironment);
    });
  }

  int assembleProgram(
      Namer namer,
      JClosedWorld closedWorld,
      InferredData inferredData,
      CodegenInputs codegenInputs,
      CodegenWorld codegenWorld) {
    return measure(() {
      measureSubtask('finalize rti', () {
        _finalizeRti(codegenInputs, codegenWorld);
      });
      ProgramBuilder programBuilder = ProgramBuilder(
          _compiler.options,
          _compiler.reporter,
          closedWorld.elementEnvironment,
          closedWorld.commonElements,
          closedWorld.outputUnitData,
          codegenWorld,
          _backendStrategy.nativeCodegenEnqueuer,
          closedWorld.backendUsage,
          closedWorld.nativeData,
          closedWorld.rtiNeed,
          closedWorld.interceptorData,
          typeTestRegistry.rtiChecks,
          codegenInputs.rtiRecipeEncoder,
          codegenWorld.oneShotInterceptorData,
          _backendStrategy.customElementsCodegenAnalysis,
          _backendStrategy.generatedCode,
          namer,
          this,
          closedWorld,
          closedWorld.fieldAnalysis,
          inferredData,
          _backendStrategy.sourceInformationStrategy,
          closedWorld.sorter,
          typeTestRegistry.rtiNeededClasses,
          closedWorld.elementEnvironment.mainFunction);
      int size = emitter.emitProgram(programBuilder, codegenWorld);
      // TODO(floitsch): we shouldn't need the `neededClasses` anymore.
      neededClasses = programBuilder.collector.neededClasses;
      return size;
    });
  }
}

/// Interface for the subset of the [Emitter] that can be used during modular
/// code generation.
///
/// Note that the emission phase is not itself modular but performed on
/// the closed world computed by the codegen enqueuer.
abstract class ModularEmitter {
  /// Returns the JS prototype of the given class [e].
  jsAst.Expression prototypeAccess(ClassEntity e, {bool hasBeenInstantiated});

  /// Returns the JS function representing the given function.
  ///
  /// The function must be invoked and can not be used as closure.
  jsAst.Expression staticFunctionAccess(FunctionEntity element);

  jsAst.Expression staticFieldAccess(FieldEntity element);

  /// Returns the JS function that must be invoked to get the value of the
  /// lazily initialized static.
  jsAst.Expression isolateLazyInitializerAccess(covariant FieldEntity element);

  /// Returns the closure expression of a static function.
  jsAst.Expression staticClosureAccess(covariant FunctionEntity element);

  /// Returns the JS constructor of the given element.
  ///
  /// The returned expression must only be used in a JS `new` expression.
  jsAst.Expression constructorAccess(ClassEntity e);

  /// Returns the JS expression representing the type [e].
  jsAst.Expression typeAccess(Entity e);

  /// Returns the JS name representing the type [e].
  jsAst.Name typeAccessNewRti(Entity e);

  /// Returns the JS name representing the type variable [e].
  jsAst.Name typeVariableAccessNewRti(TypeVariableEntity e);

  /// Returns the JS code for accessing the embedded [global].
  jsAst.Expression generateEmbeddedGlobalAccess(String global);

  /// Returns the JS code for accessing the given [constant].
  jsAst.Expression constantReference(ConstantValue constant);

  /// Returns the JS code for accessing the global property [global].
  String generateEmbeddedGlobalAccessString(String global);
}

/// Interface for the emitter that is used during the emission phase on the
/// closed world computed by the codegen enqueuer.
///
/// These methods are _not_ available during modular code generation.
abstract class Emitter implements ModularEmitter {
  Program get programForTesting;

  List<fragment_merger.PreFragment> get preDeferredFragmentsForTesting;

  /// Uses the [programBuilder] to generate a model of the program, emits
  /// the program, and returns the size of the generated output.
  int emitProgram(ProgramBuilder programBuilder, CodegenWorld codegenWorld);

  /// Returns the JS prototype of the given interceptor class [e].
  jsAst.Expression interceptorPrototypeAccess(ClassEntity e);

  /// Returns the JS constructor of the given interceptor class [e].
  jsAst.Expression interceptorClassAccess(ClassEntity e);

  /// Returns the JS expression representing a function that returns 'null'
  jsAst.Expression generateFunctionThatReturnsNull();

  int compareConstants(ConstantValue a, ConstantValue b);
  bool isConstantInlinedOrAlreadyEmitted(ConstantValue constant);

  /// Returns the size of the code generated for a given output [unit].
  int generatedSize(OutputUnit unit);
}
