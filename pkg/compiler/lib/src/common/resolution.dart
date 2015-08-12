// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.resolution;

import '../compiler.dart' show
    Compiler;
import '../dart_types.dart' show
    DartType;
import '../elements/elements.dart' show
    AstElement;
import '../enqueue.dart' show
    ResolutionEnqueuer,
    WorldImpact;
import '../tree/tree.dart' show
    AsyncForIn,
    Send;
import 'registry.dart' show
    Registry;
import 'work.dart' show
    ItemCompilationContext,
    WorkItem;

/// [WorkItem] used exclusively by the [ResolutionEnqueuer].
class ResolutionWorkItem extends WorkItem {
  bool _isAnalyzed = false;

  ResolutionWorkItem(AstElement element,
                     ItemCompilationContext compilationContext)
      : super(element, compilationContext);

  WorldImpact run(Compiler compiler, ResolutionEnqueuer world) {
    WorldImpact impact = compiler.analyze(this, world);
    _isAnalyzed = true;
    return impact;
  }

  bool get isAnalyzed => _isAnalyzed;
}

/// Backend callbacks function specific to the resolution phase.
class ResolutionCallbacks {
  /// Register that [node] is a call to `assert`.
  void onAssert(Send node, Registry registry) {}

  /// Register that an 'await for' has been seen.
  void onAsyncForIn(AsyncForIn node, Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program uses string interpolation.
  void onStringInterpolation(Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program has a catch statement.
  void onCatchStatement(Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program explicitly throws an exception.
  void onThrowExpression(Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program has a global variable with a lazy initializer.
  void onLazyField(Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program uses a type variable as an expression.
  void onTypeVariableExpression(Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program uses a type literal.
  void onTypeLiteral(DartType type, Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program has a catch statement with a stack trace.
  void onStackTraceInCatch(Registry registry) {}

  /// Register an is check to the backend.
  void onIsCheck(DartType type, Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program has a for-in loop.
  void onSyncForIn(Registry registry) {}

  /// Register an as check to the backend.
  void onAsCheck(DartType type, Registry registry) {}

  /// Registers that a type variable bounds check might occur at runtime.
  void onTypeVariableBoundCheck(Registry registry) {}

  /// Register that the application may throw a [NoSuchMethodError].
  void onThrowNoSuchMethod(Registry registry) {}

  /// Register that the application may throw a [RuntimeError].
  void onThrowRuntimeError(Registry registry) {}

  /// Register that the application may throw an
  /// [AbstractClassInstantiationError].
  void onAbstractClassInstantiation(Registry registry) {}

  /// Register that the application may throw a [FallThroughError].
  void onFallThroughError(Registry registry) {}

  /// Register that a super call will end up calling
  /// [: super.noSuchMethod :].
  void onSuperNoSuchMethod(Registry registry) {}

  /// Register that the application creates a constant map.
  void onMapLiteral(Registry registry, DartType type, bool isConstant) {}

  /// Called when resolving the `Symbol` constructor.
  void onSymbolConstructor(Registry registry) {}
}
