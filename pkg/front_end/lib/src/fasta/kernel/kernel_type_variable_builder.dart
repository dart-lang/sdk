// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_type_variable_builder;

import 'package:kernel/ast.dart'
    show DartType, TypeParameter, TypeParameterType;

import '../deprecated_problems.dart' show deprecated_inputError;

import '../fasta_codes.dart' show templateTypeArgumentsOnTypeVariable;

import '../source/outline_listener.dart';

import 'kernel_builder.dart'
    show
        KernelClassBuilder,
        KernelLibraryBuilder,
        KernelNamedTypeBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        TypeBuilder,
        TypeVariableBuilder;

class KernelTypeVariableBuilder
    extends TypeVariableBuilder<KernelTypeBuilder, DartType> {
  final OutlineListener outlineListener;
  final TypeParameter actualParameter;

  KernelTypeVariableBuilder actualOrigin;

  Object binder;

  KernelTypeVariableBuilder(
      String name, KernelLibraryBuilder compilationUnit, int charOffset,
      [KernelTypeBuilder bound, TypeParameter actual])
      // TODO(32378): We would like to use '??' here instead, but in conjuction
      // with '..', it crashes Dart2JS.
      : outlineListener = compilationUnit?.outlineListener,
        actualParameter = actual != null
            ? (actual..fileOffset = charOffset)
            : (new TypeParameter(name, null)..fileOffset = charOffset),
        super(name, bound, compilationUnit, charOffset);

  KernelTypeVariableBuilder.fromKernel(
      TypeParameter parameter, KernelLibraryBuilder compilationUnit)
      : outlineListener = null,
        actualParameter = parameter,
        super(parameter.name, null, compilationUnit, parameter.fileOffset);

  @override
  KernelTypeVariableBuilder get origin => actualOrigin ?? this;

  TypeParameter get parameter => origin.actualParameter;

  @override
  bool get hasTarget => true;

  TypeParameter get target => parameter;

  DartType buildType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    if (arguments != null) {
      int charOffset = -1; // TODO(ahe): Provide these.
      Uri fileUri = null; // TODO(ahe): Provide these.
      library.addProblem(
          templateTypeArgumentsOnTypeVariable.withArguments(name),
          charOffset,
          name.length,
          fileUri);
    }
    return new TypeParameterType(parameter);
  }

  DartType buildTypesWithBuiltArguments(
      LibraryBuilder library, List<DartType> arguments) {
    if (arguments != null) {
      return deprecated_inputError(null, null,
          "Can't use type arguments with type parameter $parameter");
    } else {
      return buildType(library, null);
    }
  }

  KernelTypeBuilder asTypeBuilder() {
    return new KernelNamedTypeBuilder(outlineListener, charOffset, name, null)
      ..bind(this);
  }

  void finish(LibraryBuilder library, KernelClassBuilder object,
      TypeBuilder dynamicType) {
    if (isPatch) return;
    parameter.bound ??=
        bound?.build(library) ?? object.buildType(library, null);
    parameter.defaultType ??=
        defaultType?.build(library) ?? dynamicType.build(library);
  }

  void applyPatch(covariant KernelTypeVariableBuilder patch) {
    patch.actualOrigin = this;
  }

  KernelTypeVariableBuilder clone(List<TypeBuilder> newTypes) {
    // TODO(dmitryas): Figure out if using [charOffset] here is a good idea.
    // An alternative is to use the offset of the node the cloned type variable
    // is declared on.
    return new KernelTypeVariableBuilder(
        name, parent, charOffset, bound.clone(newTypes));
  }
}
