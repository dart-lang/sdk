// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'api.dart';
import 'bootstrap.dart'; // For doc comments only.
import 'executor_shared/serialization.dart';

/// Exposes a platform specific [MacroExecutor], through a top level
/// `Future<MacroExecutor> start()` function.
///
/// TODO: conditionally load isolate_mirrors_executor.dart once conditional
/// imports of mirrors are supported in AOT (issue #48057).
import 'fake_executor/fake_executor.dart'
    if (dart.library.isolate) 'isolated_executor/isolated_executor.dart'
    as executor_impl show start;

/// The interface used by Dart language implementations, in order to load
/// and execute macros, as well as produce library augmentations from those
/// macro applications.
///
/// This class more clearly defines the role of a Dart language implementation
/// during macro discovery and expansion, and unifies how augmentation libraries
/// are produced.
abstract class MacroExecutor {
  /// Returns a platform specific [MacroExecutor]. On unsupported platforms this
  /// will be a fake executor object, which will throw an [UnsupportedError] if
  /// used.
  ///
  /// Note that some implementations will also require calls to [loadMacro]
  /// to pass a `precompiledKernelUri`.
  static Future<MacroExecutor> start() => executor_impl.start();

  /// Invoked when an implementation discovers a new macro definition in a
  /// [library] with [name], and prepares this executor to run the macro.
  ///
  /// May be invoked more than once for the same macro, which will cause the
  /// macro to be re-loaded. Previous [MacroClassIdentifier]s and
  /// [MacroInstanceIdentifier]s given for this macro will be invalid after
  /// that point and should be discarded.
  ///
  /// The [precompiledKernelUri] if passed must point to a kernel program for
  /// the given macro. A bootstrap Dart program can be generated with the
  /// [bootstrapMacroIsolate] function, and the result should be compiled to
  /// kernel and passed here.
  ///
  /// Some implementations may require [precompiledKernelUri] to be passed, and
  /// will throw an [UnsupportedError] if it is not.
  ///
  /// Throws an exception if the macro fails to load.
  Future<MacroClassIdentifier> loadMacro(Uri library, String name,
      {Uri? precompiledKernelUri});

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
      MacroInstanceIdentifier macro, covariant Declaration declaration);

  /// Runs the declarations phase for [macro] on a given [declaration].
  ///
  /// Throws an exception if there is an error executing the macro.
  Future<MacroExecutionResult> executeDeclarationsPhase(
      MacroInstanceIdentifier macro,
      covariant Declaration declaration,
      TypeResolver typeResolver,
      ClassIntrospector classIntrospector);

  /// Runs the definitions phase for [macro] on a given [declaration].
  ///
  /// Throws an exception if there is an error executing the macro.
  Future<MacroExecutionResult> executeDefinitionsPhase(
      MacroInstanceIdentifier macro,
      covariant Declaration declaration,
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
class Arguments implements Serializable {
  final List<Object?> positional;

  final Map<String, Object?> named;

  Arguments(this.positional, this.named);

  factory Arguments.deserialize(Deserializer deserializer) {
    deserializer
      ..moveNext()
      ..expectList();
    List<Object?> positionalArgs = [
      for (bool hasNext = deserializer.moveNext();
          hasNext;
          hasNext = deserializer.moveNext())
        _deserializeArg(deserializer, alreadyMoved: true),
    ];
    deserializer
      ..moveNext()
      ..expectList();
    Map<String, Object?> namedArgs = {
      for (bool hasNext = deserializer.moveNext();
          hasNext;
          hasNext = deserializer.moveNext())
        deserializer.expectString(): _deserializeArg(deserializer),
    };
    return new Arguments(positionalArgs, namedArgs);
  }

  static Object? _deserializeArg(Deserializer deserializer,
      {bool alreadyMoved = false}) {
    if (!alreadyMoved) deserializer.moveNext();
    _ArgumentKind kind = _ArgumentKind.values[deserializer.expectNum()];
    switch (kind) {
      case _ArgumentKind.nil:
        return null;
      case _ArgumentKind.string:
        deserializer.moveNext();
        return deserializer.expectString();
      case _ArgumentKind.bool:
        deserializer.moveNext();
        return deserializer.expectBool();
      case _ArgumentKind.num:
        deserializer.moveNext();
        return deserializer.expectNum();
      case _ArgumentKind.list:
        deserializer.moveNext();
        deserializer.expectList();
        return [
          for (bool hasNext = deserializer.moveNext();
              hasNext;
              hasNext = deserializer.moveNext())
            _deserializeArg(deserializer, alreadyMoved: true),
        ];
      case _ArgumentKind.map:
        deserializer.moveNext();
        deserializer.expectList();
        return {
          for (bool hasNext = deserializer.moveNext();
              hasNext;
              hasNext = deserializer.moveNext())
            _deserializeArg(deserializer, alreadyMoved: true):
                _deserializeArg(deserializer),
        };
    }
  }

  void serialize(Serializer serializer) {
    serializer.startList();
    for (Object? arg in positional) {
      _serializeArg(arg, serializer);
    }
    serializer.endList();

    serializer.startList();
    for (MapEntry<String, Object?> arg in named.entries) {
      serializer.addString(arg.key);
      _serializeArg(arg.value, serializer);
    }
    serializer.endList();
  }

  static void _serializeArg(Object? arg, Serializer serializer) {
    if (arg == null) {
      serializer.addNum(_ArgumentKind.nil.index);
    } else if (arg is String) {
      serializer
        ..addNum(_ArgumentKind.string.index)
        ..addString(arg);
    } else if (arg is num) {
      serializer
        ..addNum(_ArgumentKind.num.index)
        ..addNum(arg);
    } else if (arg is bool) {
      serializer
        ..addNum(_ArgumentKind.bool.index)
        ..addBool(arg);
    } else if (arg is List) {
      serializer
        ..addNum(_ArgumentKind.list.index)
        ..startList();
      for (Object? item in arg) {
        _serializeArg(item, serializer);
      }
      serializer.endList();
    } else if (arg is Map) {
      serializer
        ..addNum(_ArgumentKind.map.index)
        ..startList();
      for (MapEntry<Object?, Object?> entry in arg.entries) {
        _serializeArg(entry.key, serializer);
        _serializeArg(entry.value, serializer);
      }
      serializer.endList();
    } else {
      throw new UnsupportedError('Unsupported argument type $arg');
    }
  }
}

/// An opaque identifier for a macro class, retrieved by
/// [MacroExecutor.loadMacro].
///
/// Used to execute or reload this macro in the future.
abstract class MacroClassIdentifier implements Serializable {}

/// An opaque identifier for an instance of a macro class, retrieved by
/// [MacroExecutor.instantiateMacro].
///
/// Used to execute or reload this macro in the future.
abstract class MacroInstanceIdentifier implements Serializable {}

/// A summary of the results of running a macro in a given phase.
///
/// All modifications are expressed in terms of library augmentation
/// declarations.
abstract class MacroExecutionResult implements Serializable {
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

/// Used for serializing and deserializing arguments.
enum _ArgumentKind { string, bool, num, list, map, nil }
