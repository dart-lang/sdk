// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_type_variable_builder;

import 'package:kernel/ast.dart'
    show DartType, TypeParameter, TypeParameterType;

import '../deprecated_problems.dart' show deprecated_inputError;

import '../fasta_codes.dart' show templateTypeArgumentsOnTypeVariable;

import 'kernel_builder.dart'
    show
        KernelClassBuilder,
        KernelLibraryBuilder,
        KernelNamedTypeBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        TypeVariableBuilder;

class KernelTypeVariableBuilder
    extends TypeVariableBuilder<KernelTypeBuilder, DartType> {
  final TypeParameter actualParameter;

  KernelTypeVariableBuilder actualOrigin;

  KernelTypeVariableBuilder(
      String name, KernelLibraryBuilder compilationUnit, int charOffset,
      [KernelTypeBuilder bound])
      : actualParameter = new TypeParameter(name, null)
          ..fileOffset = charOffset,
        super(name, bound, compilationUnit, charOffset);

  @override
  KernelTypeVariableBuilder get origin => actualOrigin ?? this;

  TypeParameter get parameter => origin.actualParameter;

  TypeParameter get target => parameter;

  DartType buildType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    if (arguments != null) {
      int charOffset = -1; // TODO(ahe): Provide these.
      Uri fileUri = null; // TODO(ahe): Provide these.
      library.addWarning(
          templateTypeArgumentsOnTypeVariable.withArguments(name),
          charOffset,
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
    return new KernelNamedTypeBuilder(name, null)..bind(this);
  }

  void finish(LibraryBuilder library, KernelClassBuilder object) {
    if (isPatch) return;
    parameter.bound ??=
        bound?.build(library) ?? object.buildType(library, null);
  }

  void applyPatch(covariant KernelTypeVariableBuilder patch) {
    patch.actualOrigin = this;
  }
}
