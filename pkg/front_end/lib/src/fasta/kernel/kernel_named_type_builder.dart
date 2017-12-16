// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_interface_type_builder;

import 'package:kernel/ast.dart' show DartType, Supertype;

import '../messages.dart'
    show templateSupertypeIsIllegal, templateSupertypeIsTypeVariable;

import 'kernel_builder.dart'
    show
        KernelClassBuilder,
        KernelInvalidTypeBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        NamedTypeBuilder,
        TypeBuilder,
        TypeVariableBuilder;

class KernelNamedTypeBuilder
    extends NamedTypeBuilder<KernelTypeBuilder, DartType>
    implements KernelTypeBuilder {
  KernelNamedTypeBuilder(Object name, List<KernelTypeBuilder> arguments)
      : super(name, arguments);

  KernelInvalidTypeBuilder buildInvalidType(int charOffset, Uri fileUri) {
    // TODO(ahe): Consider if it makes sense to pass a QualifiedName to
    // KernelInvalidTypeBuilder?
    return new KernelInvalidTypeBuilder("$name", charOffset, fileUri);
  }

  Supertype handleInvalidSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    var template = builder.isTypeVariable
        ? templateSupertypeIsTypeVariable
        : templateSupertypeIsIllegal;
    library.addCompileTimeError(
        template.withArguments("$name"), charOffset, fileUri);
    return null;
  }

  DartType build(LibraryBuilder library) {
    return builder.buildType(library, arguments);
  }

  Supertype buildSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    if (builder is KernelClassBuilder) {
      KernelClassBuilder builder = this.builder;
      return builder.buildSupertype(library, arguments);
    } else {
      return handleInvalidSupertype(library, charOffset, fileUri);
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
        return new KernelNamedTypeBuilder(name, arguments)..bind(builder);
      }
    }
    return this;
  }
}
