// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.code_emitter_task;

import '../common/metrics.dart' show Metric, Metrics, CountMetric;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../constants/values.dart';
import '../deferred_load/output_unit.dart' show OutputUnit;
import '../elements/entities.dart';
import '../js/js.dart' as jsAst;
import '../js_backend/codegen_inputs.dart' show CodegenInputs;
import '../js_backend/inferred_data.dart';
import '../js_backend/namer.dart' show Namer;
import '../js_backend/runtime_types.dart' show RuntimeTypesChecks;
import '../js_model/js_strategy.dart';
import '../js_model/js_world.dart' show JClosedWorld;
import '../options.dart';
import '../universe/codegen_world_builder.dart';
import 'program_builder/program_builder.dart';
import 'startup_emitter/emitter.dart' as startup_js_emitter;
import 'startup_emitter/fragment_merger.dart';

import 'js_emitter.dart';
import 'model.dart';

/// Generates the code for all used classes in the program. Static fields (even
/// in classes) are ignored, since they can be treated as non-class elements.
///
/// The code for the containing (used) methods must exist in the `universe`.
class CodeEmitterTask extends CompilerTask {
  late final RuntimeTypesChecks _rtiChecks;
  late final NativeEmitter nativeEmitter;
  late final MetadataCollector metadataCollector;
  late final Emitter emitter;
  final Compiler _compiler;
  final bool _generateSourceMap;

  JsBackendStrategy get _backendStrategy => _compiler.backendStrategy;

  CompilerOptions get options => _compiler.options;

  /// The field is set after the program has been emitted.
  /// Contains a list of all classes that are emitted.
  /// Currently used for testing and dump-info.
  late final Set<ClassEntity> neededClasses;

  /// See [neededClasses] but for class types.
  late final Set<ClassEntity> neededClassTypes;

  _EmitterMetrics? _emitterMetrics;
  _EmitterMetrics get emitterMetrics => _emitterMetrics ??= _EmitterMetrics();
  @override
  Metrics get metrics => _emitterMetrics ?? Metrics.none();

  CodeEmitterTask(this._compiler, this._generateSourceMap)
      : super(_compiler.measurer);

  @override
  String get name => 'Code emitter';

  void _finalizeRti(CodegenInputs codegen, CodegenWorld codegenWorld) {
    // Compute the required type checks to know which classes need a
    // 'is$' method.
    _rtiChecks = _backendStrategy.rtiChecksBuilder
        .computeRequiredChecks(codegenWorld, options);
  }

  /// Creates the [Emitter] for this task.
  void createEmitter(
      Namer namer, CodegenInputs codegen, JClosedWorld closedWorld) {
    measure(() {
      nativeEmitter = NativeEmitter(
          this, closedWorld, _backendStrategy.nativeCodegenEnqueuer);
      emitter = startup_js_emitter.EmitterImpl(
          _compiler.options,
          _compiler.reporter,
          _compiler.outputProvider,
          _compiler.dumpInfoTask,
          namer,
          closedWorld,
          codegen.rtiRecipeEncoder,
          nativeEmitter,
          _backendStrategy.sourceInformationStrategy,
          this,
          _generateSourceMap);
      metadataCollector = MetadataCollector(
          _compiler.reporter, emitter, codegen.rtiRecipeEncoder);
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
          closedWorld.elementEnvironment,
          closedWorld.commonElements,
          closedWorld.outputUnitData,
          codegenWorld,
          _backendStrategy.nativeCodegenEnqueuer,
          closedWorld.backendUsage,
          closedWorld.nativeData,
          closedWorld.rtiNeed,
          closedWorld.interceptorData,
          _rtiChecks,
          codegenInputs.rtiRecipeEncoder,
          codegenWorld.oneShotInterceptorData,
          _backendStrategy.customElementsCodegenAnalysis,
          _backendStrategy.recordsCodegen,
          _backendStrategy.generatedCode,
          namer,
          this,
          closedWorld,
          closedWorld.fieldAnalysis,
          closedWorld.recordData,
          inferredData,
          _backendStrategy.sourceInformationStrategy,
          closedWorld.sorter,
          _rtiChecks.requiredClasses,
          closedWorld.elementEnvironment.mainFunction!);
      int size = emitter.emitProgram(programBuilder, codegenWorld);
      neededClasses = programBuilder.collector.neededClasses;
      neededClassTypes = programBuilder.collector.neededClassTypes;
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
  jsAst.Expression prototypeAccess(ClassEntity e);

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

  /// Returns the JS name representing the type [e].
  jsAst.Name typeAccessNewRti(ClassEntity e);

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
  Program? get programForTesting;

  List<PreFragment>? get preDeferredFragmentsForTesting;

  /// The set of omitted [OutputUnits].
  Set<OutputUnit> get omittedOutputUnits;

  /// A map of loadId to list of [FinalizedFragments].
  Map<String, List<FinalizedFragment>> get finalizedFragmentsToLoad;

  /// The [FragmentMerger] itself.
  FragmentMerger get fragmentMerger;

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

class _EmitterMetrics implements Metrics {
  @override
  String get namespace => 'emitter';

  CountMetric hunkListElements = CountMetric('hunkListElements');

  @override
  Iterable<Metric> get primary => [];

  @override
  Iterable<Metric> get secondary => [hunkListElements];
}
