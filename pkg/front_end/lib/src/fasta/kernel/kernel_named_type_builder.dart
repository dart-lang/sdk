// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_interface_type_builder;

import 'package:kernel/ast.dart' show DartType, Supertype;

import '../fasta_codes.dart' show LocatedMessage;

import '../messages.dart'
    show noLength, templateSupertypeIsIllegal, templateSupertypeIsTypeVariable;

import '../severity.dart' show Severity;

import 'kernel_builder.dart'
    show
        KernelClassBuilder,
        KernelInvalidTypeBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        NamedTypeBuilder,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder,
        flattenName;

class KernelNamedTypeBuilder
    extends NamedTypeBuilder<KernelTypeBuilder, DartType>
    implements KernelTypeBuilder {
  KernelNamedTypeBuilder(Object name, List<KernelTypeBuilder> arguments)
      : super(name, arguments);

  KernelInvalidTypeBuilder buildInvalidType(LocatedMessage message,
      {List<LocatedMessage> context}) {
    // TODO(ahe): Consider if it makes sense to pass a QualifiedName to
    // KernelInvalidTypeBuilder?
    return new KernelInvalidTypeBuilder(
        flattenName(name, message.charOffset, message.uri), message,
        context: context);
  }

  Supertype handleInvalidSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    var template = declaration.isTypeVariable
        ? templateSupertypeIsTypeVariable
        : templateSupertypeIsIllegal;
    library.addProblem(
        template.withArguments(flattenName(name, charOffset, fileUri)),
        charOffset,
        noLength,
        fileUri);
    return null;
  }

  DartType build(LibraryBuilder library) {
    return declaration.buildType(library, arguments);
  }

  Supertype buildSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    TypeDeclarationBuilder declaration = this.declaration;
    if (declaration is KernelClassBuilder) {
      return declaration.buildSupertype(library, arguments);
    } else if (declaration is KernelInvalidTypeBuilder) {
      library.addProblem(
          declaration.message.messageObject,
          declaration.message.charOffset,
          declaration.message.length,
          declaration.message.uri,
          severity: Severity.error);
      return null;
    } else {
      return handleInvalidSupertype(library, charOffset, fileUri);
    }
  }

  Supertype buildMixedInType(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    TypeDeclarationBuilder declaration = this.declaration;
    if (declaration is KernelClassBuilder) {
      return declaration.buildMixedInType(library, arguments);
    } else if (declaration is KernelInvalidTypeBuilder) {
      library.addProblem(
          declaration.message.messageObject,
          declaration.message.charOffset,
          declaration.message.length,
          declaration.message.uri,
          severity: Severity.error);
      return null;
    } else {
      return handleInvalidSupertype(library, charOffset, fileUri);
    }
  }

  TypeBuilder subst(Map<TypeVariableBuilder, TypeBuilder> substitution) {
    TypeBuilder result = substitution[declaration];
    if (result != null) {
      assert(declaration is TypeVariableBuilder);
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
        return new KernelNamedTypeBuilder(name, arguments)..bind(declaration);
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
