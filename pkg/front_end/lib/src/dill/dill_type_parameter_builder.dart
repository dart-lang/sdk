// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: unused_import

import 'package:kernel/ast.dart';

import '../base/loader.dart';
import '../builder/declaration_builders.dart';
import '../builder/metadata_builder.dart';
import '../builder/type_builder.dart';

class DillNominalParameterBuilder extends NominalParameterBuilder {
  @override
  TypeBuilder? bound;

  @override
  TypeBuilder? defaultType;

  @override
  final bool isWildcard;

  @override
  final TypeParameter parameter;

  /// Restores a [NominalParameterBuilder] from kernel
  ///
  /// The [loader] parameter is supposed to be passed by the clients and be not
  /// null. It is needed to restore [bound] and [defaultType] of the type
  /// variable from dill. The null value of this parameter is used only once in
  /// [TypeBuilderComputer] to break the infinite loop of recovering type
  /// variables of some recursive declarations, like the declaration of `A` in
  /// the example below.
  ///
  ///   class A<X extends A<X>> {}
  DillNominalParameterBuilder(
    this.parameter, {
    required Loader? loader,
    this.isWildcard = false,
  }) : this.bound = loader?.computeTypeBuilder(parameter.bound),
       this.defaultType = loader?.computeTypeBuilder(parameter.defaultType),
       super(
         variableVariance: parameter.variance,
         nullability: parameter.computeNullabilityFromBound(),
       );

  @override
  String get name => parameter.name ?? "";

  @override
  // Coverage-ignore(suite): Not run.
  Uri? get fileUri => null;

  @override
  // Coverage-ignore(suite): Not run.
  int get fileOffset => parameter.fileOffset;

  @override
  TypeParameterKind get kind => TypeParameterKind.fromKernel;

  @override
  bool operator ==(Object other) {
    return other is NominalParameterBuilder && parameter == other.parameter;
  }

  @override
  int get hashCode {
    return parameter.hashCode;
  }
}

class DillStructuralParameterBuilder extends StructuralParameterBuilder {
  @override
  TypeBuilder? bound;

  @override
  TypeBuilder? defaultType;

  @override
  final bool isWildcard;

  /// The [StructuralParameter] built by this builder.
  @override
  final StructuralParameter parameter;

  DillStructuralParameterBuilder(this.parameter, {this.isWildcard = false})
    : super(nullability: parameter.computeNullabilityFromBound());

  @override
  String get name => parameter.name ?? "";

  @override
  // Coverage-ignore(suite): Not run.
  Uri? get fileUri => null;

  @override
  // Coverage-ignore(suite): Not run.
  int get fileOffset => parameter.fileOffset;

  @override
  // Coverage-ignore(suite): Not run.
  TypeParameterKind get kind => TypeParameterKind.fromKernel;
}
