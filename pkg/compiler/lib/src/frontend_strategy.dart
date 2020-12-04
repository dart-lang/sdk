// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.frontend_strategy;

import 'common.dart';
import 'common/tasks.dart';
import 'common_elements.dart';
import 'compiler.dart' show Compiler;
import 'deferred_load.dart' show DeferredLoadTask;
import 'elements/entities.dart';
import 'enqueue.dart';
import 'js_backend/native_data.dart';
import 'js_backend/no_such_method_registry.dart';
import 'kernel/loader.dart';
import 'universe/world_impact.dart';

/// Strategy pattern that defines the connection between the input format and
/// the resolved element model.
abstract class FrontendStrategy {
  /// Registers a set of loaded libraries with this strategy.
  void registerLoadedLibraries(KernelResult result);

  /// Returns the [ElementEnvironment] for the element model used in this
  /// strategy.
  ElementEnvironment get elementEnvironment;

  /// Returns the [CommonElements] for the element model used in this
  /// strategy.
  CommonElements get commonElements;

  NativeBasicData get nativeBasicData;

  /// Creates a [DeferredLoadTask] for the element model used in this strategy.
  DeferredLoadTask createDeferredLoadTask(Compiler compiler);

  /// Support for classifying `noSuchMethod` implementations.
  NoSuchMethodRegistry get noSuchMethodRegistry;

  /// Called before processing of the resolution queue is started.
  void onResolutionStart();

  ResolutionEnqueuer createResolutionEnqueuer(
      CompilerTask task, Compiler compiler);

  /// Called when the resolution queue has been closed.
  void onResolutionEnd();

  /// Computes the main function from [mainLibrary] adding additional world
  /// impact to [impactBuilder].
  FunctionEntity computeMain(WorldImpactBuilder impactBuilder);

  /// Creates a [SourceSpan] from [spannable] in context of [currentElement].
  SourceSpan spanFromSpannable(Spannable spannable, Entity currentElement);
}

/// Class that performs the mechanics to investigate annotations in the code.
abstract class AnnotationProcessor {
  void extractNativeAnnotations(LibraryEntity library);

  void extractJsInteropAnnotations(LibraryEntity library);
}

/// Class that deletes the contents of an [WorldImpact] cache.
// TODO(redemption): this can be deleted when we sunset the old front end.
abstract class ImpactCacheDeleter {
  /// Removes the [WorldImpact] for [element] from the resolution cache. Later
  /// calls to [getWorldImpact] or [computeWorldImpact] returns an empty impact.
  void uncacheWorldImpact(Entity element);

  /// Removes the [WorldImpact]s for all [Element]s in the resolution cache. ,
  /// Later calls to [getWorldImpact] or [computeWorldImpact] returns an empty
  /// impact.
  void emptyCache();
}
