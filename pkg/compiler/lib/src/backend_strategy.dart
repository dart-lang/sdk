// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.backend_strategy;

import 'common.dart';
import 'common/tasks.dart';
import 'deferred_load.dart' show OutputUnitData;
import 'enqueue.dart';
import 'elements/entities.dart';
import 'inferrer/types.dart';
import 'io/source_information.dart';
import 'js_backend/inferred_data.dart';
import 'js_backend/native_data.dart';
import 'ssa/ssa.dart';
import 'universe/codegen_world_builder.dart';
import 'universe/world_builder.dart';
import 'world.dart';

/// Strategy pattern that defines the element model used in type inference
/// and code generation.
abstract class BackendStrategy {
  /// Create the [JClosedWorld] from [closedWorld].
  JClosedWorld createJClosedWorld(
      KClosedWorld closedWorld, OutputUnitData outputUnitData);

  /// Registers [closedWorld] as the current closed world used by this backend
  /// strategy.
  ///
  /// This is used to support serialization after type inference.
  void registerJClosedWorld(JClosedWorld closedWorld);

  /// Creates the [CodegenWorldBuilder] used by the codegen enqueuer.
  CodegenWorldBuilder createCodegenWorldBuilder(
      NativeBasicData nativeBasicData,
      JClosedWorld closedWorld,
      SelectorConstraintsStrategy selectorConstraintsStrategy);

  /// Creates the [WorkItemBuilder] used by the codegen enqueuer.
  WorkItemBuilder createCodegenWorkItemBuilder();

  /// Creates the [SsaBuilder] used for the element model.
  SsaBuilder createSsaBuilder(
      CompilerTask task, SourceInformationStrategy sourceInformationStrategy);

  /// Returns the [SourceInformationStrategy] use for the element model.
  SourceInformationStrategy get sourceInformationStrategy;

  /// Creates a [SourceSpan] from [spannable] in context of [currentElement].
  SourceSpan spanFromSpannable(Spannable spannable, Entity currentElement);

  /// Creates the [TypesInferrer] used by this strategy.
  TypesInferrer createTypesInferrer(
      JClosedWorld closedWorld, InferredDataBuilder inferredDataBuilder);
}
