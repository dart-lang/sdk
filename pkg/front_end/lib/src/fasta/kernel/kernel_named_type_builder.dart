// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_interface_type_builder;

import 'package:kernel/ast.dart' show
    DartType,
    DynamicType,
    Supertype,
    VoidType;

import '../errors.dart' show
    inputError;

import 'kernel_builder.dart' show
    KernelClassBuilder,
    KernelInvalidTypeBuilder,
    KernelTypeBuilder,
    NamedTypeBuilder,
    TypeBuilder,
    TypeDeclarationBuilder,
    TypeVariableBuilder;

class KernelNamedTypeBuilder extends NamedTypeBuilder<KernelTypeBuilder>
    implements KernelTypeBuilder {
  TypeDeclarationBuilder<KernelTypeBuilder, DartType> builder;

  KernelNamedTypeBuilder(String name, List<KernelTypeBuilder> arguments,
      int charOffset, Uri fileUri)
      : super(name, arguments, charOffset, fileUri);

  KernelInvalidTypeBuilder buildInvalidType(String name) {
    // TODO(ahe): Record error instead of printing.
    print("$fileUri:$charOffset: Type not found: $name");
    return new KernelInvalidTypeBuilder(name, charOffset, fileUri);
  }

  DartType handleMissingType() {
    // TODO(ahe): Record error instead of printing.
    print("$fileUri:$charOffset: No type for: $name");
    return const DynamicType();
  }

  Supertype handleMissingSuperType() {
    throw inputError(fileUri, charOffset, "No type for: $name");
  }

  DartType build() {
    if (name == "void") return const VoidType();
    if (name == "dynamic") return const DynamicType();
    if (builder == null) return handleMissingType();
    return builder.buildType(arguments);
  }

  Supertype buildSupertype() {
    if (name == "void") return null;
    if (name == "dynamic") return null;
    if (builder == null) return handleMissingSuperType();
    if (builder is KernelClassBuilder) {
      KernelClassBuilder builder = this.builder;
      return builder.buildSupertype(arguments);
    } else {
      return handleMissingSuperType();
    }
  }

  TypeBuilder subst(Map<TypeVariableBuilder, TypeBuilder> substitution) {
    TypeBuilder result = substitution[builder];
    if (result != null) {
      assert(builder is TypeVariableBuilder);
      return result;
    } else if (arguments != null) {
      List<KernelTypeBuilder> arguments;
      int i = 0;
      for (KernelTypeBuilder argument in this.arguments) {
        KernelTypeBuilder type = argument.subst(substitution);
        if (type != argument) {
          arguments ??= this.arguments.toList();
          arguments[i] = type;
        }
        i++;
      }
      if (arguments != null) {
        return new KernelNamedTypeBuilder(name, arguments, charOffset, fileUri)
            ..builder = builder;
      }
    }
    return this;
  }
}
