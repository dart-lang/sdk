// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Hooks for injecting a macro implementation.
///
/// Do not use: this is not a public API and is subject to arbitrary changes.
library;

import 'package:macros/macros.dart';
import 'package:macros/src/executor.dart';

/// If set, overrides the analyzer's macro implementation.
MacroImplementation? macroImplementation;

/// An injected macro implementation.
class MacroImplementation {
  final MacroPackageConfigs packageConfigs;
  final MacroRunner runner;

  MacroImplementation({required this.packageConfigs, required this.runner});
}

/// Which annotations are associated with macros.
abstract class MacroPackageConfigs {
  /// Whether the annotation with the specified [name] in the library at [uri]
  /// is a macro.
  bool isMacro(Uri uri, String name);
}

abstract class MacroRunner {
  /// Run the macro for the annotation with the specified [name] in the library
  /// at [uri].
  RunningMacro run(Uri uri, String name);
}

abstract class RunningMacro {
  /// Executes the macro's phase two, declarations.
  Future<MacroExecutionResult> executeDeclarationsPhase(MacroTarget target,
      DeclarationPhaseIntrospector declarationsPhaseIntrospector);

  /// Executes the macro's phase three, definitions.
  Future<MacroExecutionResult> executeDefinitionsPhase(MacroTarget target,
      DefinitionPhaseIntrospector definitionPhaseIntrospector);

  /// Executes the macro's phase one, types.
  Future<MacroExecutionResult> executeTypesPhase(
      MacroTarget target, TypePhaseIntrospector typePhaseIntrospector);
}
