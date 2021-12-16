// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'api.dart';

/// The interface used by Dart language implementations, in order to load
/// and execute macros, as well as produce library augmentations from those
/// macro applications.
///
/// This class more clearly defines the role of a Dart language implementation
/// during macro discovery and expansion, and unifies how augmentation libraries
/// are produced.
abstract class MacroExecutor {
  /// Invoked when an implementation discovers a new macro definition in a
  /// [library] with [name], and prepares this executor to run the macro.
  ///
  /// May be invoked more than once for the same macro, which will cause the
  /// macro to be re-loaded. Previous [MacroClassIdentifier]s and
  /// [MacroInstanceIdentifier]s given for this macro will be invalid after
  /// that point and should be discarded.
  ///
  /// Throws an exception if the macro fails to load.
  Future<MacroClassIdentifier> loadMacro(Uri library, String name);

  /// Creates an instance of [macroClass] in the executor, and returns an
  /// identifier for that instance.
  ///
  /// Throws an exception if an instance is not created.
  Future<MacroInstanceIdentifier> instantiateMacro(
      MacroClassIdentifier macroClass, String constructor, Arguments arguments);

  /// Runs the type phase for [macro] on a given [declaration].
  ///
  /// Throws an exception if there is an error executing the macro.
  Future<MacroExecutionResult> executeTypesPhase(
      MacroInstanceIdentifier macro, Declaration declaration);

  /// Runs the declarations phase for [macro] on a given [declaration].
  ///
  /// Throws an exception if there is an error executing the macro.
  Future<MacroExecutionResult> executeDeclarationsPhase(
      MacroInstanceIdentifier macro,
      Declaration declaration,
      TypeResolver typeResolver,
      ClassIntrospector classIntrospector);

  /// Runs the definitions phase for [macro] on a given [declaration].
  ///
  /// Throws an exception if there is an error executing the macro.
  Future<MacroExecutionResult> executeDefinitionsPhase(
      MacroInstanceIdentifier macro,
      Declaration declaration,
      TypeResolver typeResolver,
      ClassIntrospector classIntrospector,
      TypeDeclarationResolver typeDeclarationResolver);

  /// Combines multiple [MacroExecutionResult]s into a single library
  /// augmentation file, and returns a [String] representing that file.
  Future<String> buildAugmentationLibrary(
      Iterable<MacroExecutionResult> macroResults);

  /// Tell the executor to shut down and clean up any resources it may have
  /// allocated.
  void close();
}

/// The arguments passed to a macro constructor.
///
/// All argument instances must be of type [Code] or a built-in value type that
/// is serializable (num, bool, String, null, etc).
class Arguments {
  final List<Object?> positional;

  final Map<String, Object?> named;

  Arguments(this.positional, this.named);
}

/// An opaque identifier for a macro class, retrieved by
/// [MacroExecutor.loadMacro].
///
/// Used to execute or reload this macro in the future.
abstract class MacroClassIdentifier {}

/// An opaque identifier for an instance of a macro class, retrieved by
/// [MacroExecutor.instantiateMacro].
///
/// Used to execute or reload this macro in the future.
abstract class MacroInstanceIdentifier {}

/// A summary of the results of running a macro in a given phase.
///
/// All modifications are expressed in terms of library augmentation
/// declarations.
abstract class MacroExecutionResult {
  /// Any library imports that should be added to support the code used in
  /// the augmentations.
  Iterable<DeclarationCode> get imports;

  /// Any augmentations that should be applied as a result of executing a macro.
  Iterable<DeclarationCode> get augmentations;
}

/// Each of the different macro execution phases.
enum Phase {
  /// Only new types are added in this phase.
  types,

  /// New non-type declarations are added in this phase.
  declarations,

  /// This phase allows augmenting existing declarations.
  definitions,
}
