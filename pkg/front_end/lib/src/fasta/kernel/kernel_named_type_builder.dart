// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_interface_type_builder;

import 'package:kernel/ast.dart' show DartType, Supertype;

import '../fasta_codes.dart' show Message;

import '../messages.dart'
    show noLength, templateSupertypeIsIllegal, templateSupertypeIsTypeVariable;

import 'kernel_builder.dart'
    show
        KernelClassBuilder,
        KernelInvalidTypeBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        NamedTypeBuilder,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder;

class KernelNamedTypeBuilder
    extends NamedTypeBuilder<KernelTypeBuilder, DartType>
    implements KernelTypeBuilder {
  KernelNamedTypeBuilder(Object name, List<KernelTypeBuilder> arguments)
      : super(name, arguments);

  KernelInvalidTypeBuilder buildInvalidType(int charOffset, Uri fileUri,
      [Message message]) {
    // TODO(ahe): Consider if it makes sense to pass a QualifiedName to
    // KernelInvalidTypeBuilder?
    return new KernelInvalidTypeBuilder("$name", charOffset, fileUri, message);
  }

  Supertype handleInvalidSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    var template = builder.isTypeVariable
        ? templateSupertypeIsTypeVariable
        : templateSupertypeIsIllegal;
    library.addCompileTimeError(
        template.withArguments("$name"), charOffset, noLength, fileUri);
    return null;
  }

  DartType build(LibraryBuilder library) {
    return builder.buildType(library, arguments);
  }

  Supertype buildSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    TypeDeclarationBuilder declaration = builder;
    if (declaration is KernelClassBuilder) {
      return declaration.buildSupertype(library, arguments);
    } else if (declaration is KernelInvalidTypeBuilder) {
      library.addCompileTimeError(
          declaration.message.messageObject,
          declaration.message.charOffset,
          declaration.message.length,
          declaration.message.uri);
      return null;
    } else {
      return handleInvalidSupertype(library, charOffset, fileUri);
    }
  }

  Supertype buildMixedInType(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    TypeDeclarationBuilder declaration = builder;
    if (declaration is KernelClassBuilder) {
      return declaration.buildMixedInType(library, arguments);
    } else if (declaration is KernelInvalidTypeBuilder) {
      library.addCompileTimeError(
          declaration.message.messageObject,
          declaration.message.charOffset,
          declaration.message.length,
          declaration.message.uri);
      return null;
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

  KernelNamedTypeBuilder clone(List<TypeBuilder> newTypes) {
    List<KernelTypeBuilder> clonedArguments;
    if (arguments != null) {
      clonedArguments = new List<KernelTypeBuilder>(arguments.length);
      for (int i = 0; i < clonedArguments.length; i++) {
        clonedArguments[i] = arguments[i].clone(newTypes);
      }
    }
    KernelNamedTypeBuilder newType =
        new KernelNamedTypeBuilder(name, clonedArguments);
    newTypes.add(newType);
    return newType;
  }
}
