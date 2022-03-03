// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../api.dart';
import '../executor/augmentation_library.dart';
import '../executor/introspection_impls.dart';
import '../executor/response_impls.dart';
import '../executor.dart';

/// A [MacroExecutor] implementation which delegates most work to other
/// executors which are spawned through a provided callback.
class MultiMacroExecutor extends MacroExecutor with AugmentationLibraryBuilder {
  /// Individual executors indexed by [MacroClassIdentifier] or
  /// [MacroInstanceIdentifier].
  final _executors = <Object, MacroExecutor>{};

  /// The function to spawn an actual macro executor for a given [loadMacro]
  /// request.
  final Future<MacroExecutor> Function(Uri library, String name,
      {Uri? precompiledKernelUri}) _spawnExecutor;

  MultiMacroExecutor(this._spawnExecutor);

  @override
  void close() {
    for (MacroExecutor executor in _executors.values) {
      executor.close();
    }
    _executors.clear();
  }

  @override
  Future<MacroExecutionResult> executeDeclarationsPhase(
          MacroInstanceIdentifier macro,
          DeclarationImpl declaration,
          IdentifierResolver identifierResolver,
          TypeResolver typeResolver,
          ClassIntrospector classIntrospector) =>
      _executors[macro]!.executeDeclarationsPhase(macro, declaration,
          identifierResolver, typeResolver, classIntrospector);

  @override
  Future<MacroExecutionResult> executeDefinitionsPhase(
          MacroInstanceIdentifier macro,
          DeclarationImpl declaration,
          IdentifierResolver identifierResolver,
          TypeResolver typeResolver,
          ClassIntrospector classIntrospector,
          TypeDeclarationResolver typeDeclarationResolver) =>
      _executors[macro]!.executeDefinitionsPhase(
          macro,
          declaration,
          identifierResolver,
          typeResolver,
          classIntrospector,
          typeDeclarationResolver);

  @override
  Future<MacroExecutionResult> executeTypesPhase(MacroInstanceIdentifier macro,
          DeclarationImpl declaration, IdentifierResolver identifierResolver) =>
      _executors[macro]!
          .executeTypesPhase(macro, declaration, identifierResolver);

  @override
  Future<MacroInstanceIdentifier> instantiateMacro(
      MacroClassIdentifier macroClass,
      String constructor,
      Arguments arguments) async {
    MacroExecutor executor = _executors[macroClass]!;
    MacroInstanceIdentifier instance =
        await executor.instantiateMacro(macroClass, constructor, arguments);
    _executors[instance] = executor;
    return instance;
  }

  @override
  Future<MacroClassIdentifier> loadMacro(Uri library, String name,
      {Uri? precompiledKernelUri}) async {
    MacroClassIdentifier identifier =
        new MacroClassIdentifierImpl(library, name);
    _executors.remove(identifier)?.close();

    MacroExecutor executor = await _spawnExecutor(library, name,
        precompiledKernelUri: precompiledKernelUri);
    _executors[identifier] = executor;
    return identifier;
  }
}
