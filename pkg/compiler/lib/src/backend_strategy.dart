// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.backend_strategy;

import 'common.dart';
import 'common/codegen.dart';
import 'common/tasks.dart';
import 'deferred_load.dart' show OutputUnitData;
import 'enqueue.dart';
import 'elements/entities.dart';
import 'inferrer/types.dart';
import 'io/source_information.dart';
import 'js_backend/backend.dart';
import 'js_backend/enqueuer.dart';
import 'js_backend/inferred_data.dart';
import 'js_emitter/code_emitter_task.dart';
import 'serialization/serialization.dart';
import 'ssa/ssa.dart';
import 'universe/codegen_world_builder.dart';
import 'world.dart';

/// Strategy pattern that defines the element model used in type inference
/// and code generation.
abstract class BackendStrategy {
  List<CompilerTask> get tasks;

  FunctionCompiler get functionCompiler;

  CodeEmitterTask get emitterTask;

  /// Create the [JClosedWorld] from [closedWorld].
  JClosedWorld createJClosedWorld(
      KClosedWorld closedWorld, OutputUnitData outputUnitData);

  /// Registers [closedWorld] as the current closed world used by this backend
  /// strategy.
  ///
  /// This is used to support serialization after type inference.
  void registerJClosedWorld(JClosedWorld closedWorld);

  /// Called when the compiler starts running the codegen.
  ///
  /// Returns the [CodegenInputs] objects with the needed data.
  CodegenInputs onCodegenStart(
      GlobalTypeInferenceResults globalTypeInferenceResults);

  /// Creates an [Enqueuer] for code generation specific to this backend.
  CodegenEnqueuer createCodegenEnqueuer(
      CompilerTask task,
      JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults,
      CodegenInputs codegen,
      CodegenResults codegenResults);

  /// Called when code generation has been completed.
  void onCodegenEnd(CodegenInputs codegen);

  /// Creates the [SsaBuilder] used for the element model.
  SsaBuilder createSsaBuilder(
      CompilerTask task, SourceInformationStrategy sourceInformationStrategy);

  /// Creates a [SourceSpan] from [spannable] in context of [currentElement].
  SourceSpan spanFromSpannable(Spannable spannable, Entity currentElement);

  /// Creates the [TypesInferrer] used by this strategy.
  TypesInferrer createTypesInferrer(
      JClosedWorld closedWorld, InferredDataBuilder inferredDataBuilder);

  /// Calls [f] for every member that needs to be serialized for modular code
  /// generation and returns an [EntityWriter] for encoding these members in
  /// the serialized data.
  ///
  /// The needed members include members computed on demand during non-modular
  /// code generation, such as constructor bodies and and generator bodies.
  EntityWriter forEachCodegenMember(void Function(MemberEntity member) f);

  /// Prepare [source] to deserialize modular code generation data.
  void prepareCodegenReader(DataSource source);

  /// Generates the output and returns the total size of the generated code.
  int assembleProgram(JClosedWorld closedWorld, InferredData inferredData,
      CodegenInputs codegenInputs, CodegenWorld codegenWorld);
}
