// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

/// A fragment with function syntax, i.e. a method, getter, setter, constructor,
/// or factory.
sealed class FunctionFragment {
  FunctionBodyBuildingContext createFunctionBodyBuildingContext();
}

abstract class FunctionBodyBuildingContext {
  /// Returns the [MemberKind] for the function body being built.
  MemberKind get memberKind;

  /// Returns `true` if the function body should be built.
  // TODO(johnniwinther): Avoid the need for this.
  bool get shouldBuild;

  BodyBuilderContext createBodyBuilderContext();

  LookupScope get typeParameterScope;

  LocalScope computeFormalParameterScope(LookupScope typeParameterScope);

  VariableDeclaration? get thisVariable;

  List<TypeParameter>? get thisTypeParameters;

  InferenceDataForTesting? get inferenceDataForTesting;
}
