// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Facades for [Compiler] used from other parts of the system.
// TODO(48820): delete after the migration is complete.
library compiler.src.compiler_interfaces;

import '../compiler_api.dart' show CompilerOutput, Diagnostic;

import 'common/tasks.dart' show Measurer;
import 'deferred_load/deferred_load.dart' show DeferredLoadTask;
import 'deferred_load/program_split_constraints/nodes.dart' show ConstraintData;
import 'diagnostics/diagnostic_listener.dart' show DiagnosticMessage;
import 'diagnostics/diagnostic_listener.dart' show DiagnosticReporter;
import 'diagnostics/source_span.dart';
import 'diagnostics/spannable.dart';
import 'elements/entities.dart' show Entity;
import 'js_model/js_strategy_interfaces.dart';
import 'kernel/kernel_strategy.dart' show KernelFrontendStrategy;
import 'options.dart' show CompilerOptions;
import 'universe/world_impact.dart' show WorldImpact;
import 'compiler_migrated.dart';
import 'dump_info_javascript_monitor.dart';

/// Subset of [Compiler] needed by deferred loading.
///
/// See definitions on [Compiler] for documentation.
abstract class CompilerTypeInferenceFacade {
  JsBackendStrategy get backendStrategy;
  bool get disableTypeInference;
  Measurer get measurer;
}

/// Subset of [Compiler] needed by deferred loading.
///
/// See definitions on [Compiler] for documentation.
abstract class CompilerDeferredLoadingFacade {
  bool get compilationFailed;
  Measurer get measurer;
  DiagnosticReporter get reporter;
  Map<Entity, WorldImpact> get impactCache;
  CompilerOptions get options;
  KernelFrontendStrategy get frontendStrategy;
  CompilerOutput get outputProvider;
  ConstraintData? get programSplitConstraintsData;
}

/// Subset of [Compiler] needed by `DiagnosticListener`.
///
/// See definitions on [Compiler] for documentation.
abstract class CompilerDiagnosticsFacade {
  CompilerOptions get options;

  bool inUserCode(Entity element);

  Uri getCanonicalUri(Entity element);

  void reportDiagnostic(DiagnosticMessage message,
      List<DiagnosticMessage> infos, Diagnostic kind);

  void fatalDiagnosticReported(DiagnosticMessage message,
      List<DiagnosticMessage> infos, Diagnostic kind);

  bool get compilationFailed;

  SourceSpan spanFromSpannable(Spannable spannable, Entity? currentElement);
}

/// Subset of [Compiler] needed by kernel strategy
///
/// See definitions on [Compiler] for documentation.
abstract class CompilerKernelStrategyFacade {
  bool get compilationFailed;
  Measurer get measurer;
  DiagnosticReporter get reporter;
  Map<Entity, WorldImpact> get impactCache;
  CompilerOptions get options;
  KernelFrontendStrategy get frontendStrategy;
  CompilerOutput get outputProvider;
  ConstraintData? get programSplitConstraintsData;
  DeferredLoadTask get deferredLoadTask;
}

/// Subset of [Compiler] needed by type_graph_inferrer
///
/// See definitions on [Compiler] for documentation.
abstract class CompilerInferrerFacade {
  CompilerOptions get options;
  Progress get progress;
  DiagnosticReporter get reporter;
  CompilerOutput get outputProvider;
}

/// Subset of [Compiler] needed by dump-info
///
/// See definitions on [Compiler] for documentation.
abstract class CompilerDumpInfoFacade {
  CompilerOptions get options;
  Measurer get measurer;
  DiagnosticReporter get reporter;
  CompilerOutput get outputProvider;
  JsBackendStrategy get backendStrategy;
}

abstract class CompilerEmitterFacade {
  JsBackendStrategy get backendStrategy;
  CompilerOptions get options;
  Measurer get measurer;
  DiagnosticReporter get reporter;
  CompilerOutput get outputProvider;
  DumpInfoJavaScriptMonitor get dumpInfoTask;
}
