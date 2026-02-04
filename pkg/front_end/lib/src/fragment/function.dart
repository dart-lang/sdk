// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

/// A fragment with function syntax, i.e. a method, getter, setter, constructor,
/// or factory.
sealed class FunctionFragment {
  /// Creates [FunctionBodyBuildingContext] for building this
  /// [FunctionFragment].
  ///
  /// If the fragment should not be built, for instance if is erroneous, `null`
  /// is returned.
  FunctionBodyBuildingContext? createFunctionBodyBuildingContext();
}

abstract class FunctionBodyBuildingContext {
  /// Returns the [MemberKind] for the function body being built.
  MemberKind get memberKind;

  /// Returns `true` if the function should be finished after parsing.
  ///
  /// This allows for delaying finishing the function until primary constructor
  /// bodies have been parsed.
  bool get shouldFinishFunction;

  BodyBuilderContext createBodyBuilderContext();

  ExtensionScope get extensionScope;

  LookupScope get typeParameterScope;

  LocalScope get formalParameterScope;

  VariableDeclaration? get thisVariable;

  List<TypeParameter>? get thisTypeParameters;

  InferenceDataForTesting? get inferenceDataForTesting;
}
