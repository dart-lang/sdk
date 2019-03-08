// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_type_variable_builder;

import 'package:kernel/ast.dart'
    show DartType, TypeParameter, TypeParameterType;

import '../fasta_codes.dart' show templateTypeArgumentsOnTypeVariable;

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
  final TypeParameter actualParameter;

  KernelTypeVariableBuilder actualOrigin;

  KernelTypeVariableBuilder(
      String name, KernelLibraryBuilder compilationUnit, int charOffset,
      [KernelTypeBuilder bound, TypeParameter actual])
      // TODO(32378): We would like to use '??' here instead, but in conjuction
      // with '..', it crashes Dart2JS.
      : actualParameter = actual != null
            ? (actual..fileOffset = charOffset)
            : (new TypeParameter(name, null)..fileOffset = charOffset),
        super(name, bound, compilationUnit, charOffset);

  KernelTypeVariableBuilder.fromKernel(
      TypeParameter parameter, LibraryBuilder compilationUnit)
      : actualParameter = parameter,
        super(parameter.name, null, compilationUnit, parameter.fileOffset);

  @override
  KernelTypeVariableBuilder get origin => actualOrigin ?? this;

  TypeParameter get parameter => origin.actualParameter;

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
      int charOffset = -1; // TODO(ahe): Provide these.
      Uri fileUri = null; // TODO(ahe): Provide these.
      library.addProblem(
          templateTypeArgumentsOnTypeVariable.withArguments(name),
          charOffset,
          name.length,
          fileUri);
    }
    return buildType(library, null);
  }

  KernelTypeBuilder asTypeBuilder() {
    return new KernelNamedTypeBuilder(name, null)..bind(this);
  }

  void finish(LibraryBuilder library, KernelClassBuilder object,
      TypeBuilder dynamicType) {
    if (isPatch) return;
    DartType objectType = object.buildType(library, null);
    parameter.bound ??= bound?.build(library) ?? objectType;
    // If defaultType is not set, initialize it to dynamic, unless the bound is
    // explicitly specified as Object, in which case defaultType should also be
    // Object. This makes sure instantiation of generic function types with an
    // explicit Object bound results in Object as the instantiated type.
    parameter.defaultType ??= defaultType?.build(library) ??
        (bound != null && parameter.bound == objectType
            ? objectType
            : dynamicType.build(library));
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

  @override
  bool operator ==(Object other) {
    return other is KernelTypeVariableBuilder && target == other.target;
  }

  @override
  int get hashCode => target.hashCode;

  static List<TypeParameter> kernelTypeParametersFromBuilders(
      List<TypeVariableBuilder> builders) {
    if (builders == null) return null;
    List<TypeParameter> result =
        new List<TypeParameter>.filled(builders.length, null, growable: true);
    for (int i = 0; i < builders.length; i++) {
      result[i] = builders[i].target;
    }
    return result;
  }
}
