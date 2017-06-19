// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.backend_strategy;

import 'closure.dart' show ClosureConversionTask;
import 'common/tasks.dart';
import 'compiler.dart' show Compiler;
import 'enqueue.dart';
import 'io/source_information.dart';
import 'js_backend/js_backend.dart';
import 'js_backend/native_data.dart';
import 'js_emitter/sorter.dart';
import 'ssa/ssa.dart';
import 'universe/world_builder.dart';
import 'world.dart';

/// Strategy pattern that defines the element model used in type inference
/// and code generation.
abstract class BackendStrategy {
  /// Create the [ClosedWorldRefiner] for [closedWorld].
  ClosedWorldRefiner createClosedWorldRefiner(ClosedWorld closedWorld);

  /// Create the task that analyzes the code to see what closures need to be
  /// rewritten.
  ClosureConversionTask createClosureConversionTask(Compiler compiler);

  /// The [Sorter] used for sorting elements in the generated code.
  Sorter get sorter;

  /// Creates the [CodegenWorldBuilder] used by the codegen enqueuer.
  CodegenWorldBuilder createCodegenWorldBuilder(
      NativeBasicData nativeBasicData,
      ClosedWorld closedWorld,
      SelectorConstraintsStrategy selectorConstraintsStrategy);

  /// Creates the [WorkItemBuilder] used by the codegen enqueuer.
  WorkItemBuilder createCodegenWorkItemBuilder(ClosedWorld closedWorld);

  /// Creates the [SsaBuilder] used for the element model.
  SsaBuilder createSsaBuilder(CompilerTask task, JavaScriptBackend backend,
      SourceInformationStrategy sourceInformationStrategy);

  /// Returns the [SourceInformationStrategy] use for the element model.
  SourceInformationStrategy get sourceInformationStrategy;
}
