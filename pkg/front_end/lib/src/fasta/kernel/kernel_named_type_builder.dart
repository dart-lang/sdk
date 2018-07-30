// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_interface_type_builder;

import 'package:kernel/ast.dart' show DartType, InvalidType, Supertype;

import '../fasta_codes.dart' show Message;

import '../messages.dart'
    show noLength, templateSupertypeIsIllegal, templateSupertypeIsTypeVariable;

import '../source/outline_listener.dart';

import 'kernel_builder.dart'
    show
        KernelClassBuilder,
        KernelInvalidTypeBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        NamedTypeBuilder,
        QualifiedName,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder;

class KernelNamedTypeBuilder
    extends NamedTypeBuilder<KernelTypeBuilder, DartType>
    implements KernelTypeBuilder {
  final int charOffset;

  KernelNamedTypeBuilder(OutlineListener outlineListener, this.charOffset,
      Object name, List<KernelTypeBuilder> arguments)
      : super(outlineListener, name, arguments);

  KernelInvalidTypeBuilder buildInvalidType(int charOffset, Uri fileUri,
      [Message message]) {
    // TODO(ahe): Consider if it makes sense to pass a QualifiedName to
    // KernelInvalidTypeBuilder?
    return new KernelInvalidTypeBuilder("$name", charOffset, fileUri, message);
  }

  Supertype handleInvalidSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    var template = declaration.isTypeVariable
        ? templateSupertypeIsTypeVariable
        : templateSupertypeIsIllegal;
    library.addCompileTimeError(
        template.withArguments("$name"), charOffset, noLength, fileUri);
    return null;
  }

  DartType build(LibraryBuilder library) {
    DartType type = declaration.buildType(library, arguments);
    _storeType(library, type);
    return type;
  }

  Supertype buildSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    TypeDeclarationBuilder declaration = this.declaration;
    if (declaration is KernelClassBuilder) {
      var supertype = declaration.buildSupertype(library, arguments);
      _storeType(library, supertype.asInterfaceType);
      return supertype;
    } else if (declaration is KernelInvalidTypeBuilder) {
      library.addCompileTimeError(
          declaration.message.messageObject,
          declaration.message.charOffset,
          declaration.message.length,
          declaration.message.uri);
      _storeType(library, const InvalidType());
      return null;
    } else {
      _storeType(library, const InvalidType());
      return handleInvalidSupertype(library, charOffset, fileUri);
    }
  }

  Supertype buildMixedInType(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    TypeDeclarationBuilder declaration = this.declaration;
    if (declaration is KernelClassBuilder) {
      var supertype = declaration.buildMixedInType(library, arguments);
      _storeType(library, supertype.asInterfaceType);
      return supertype;
    } else if (declaration is KernelInvalidTypeBuilder) {
      library.addCompileTimeError(
          declaration.message.messageObject,
          declaration.message.charOffset,
          declaration.message.length,
          declaration.message.uri);
      _storeType(library, const InvalidType());
      return null;
    } else {
      _storeType(library, const InvalidType());
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
        return new KernelNamedTypeBuilder(
            outlineListener, charOffset, name, arguments)
          ..bind(declaration);
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
    KernelNamedTypeBuilder newType = new KernelNamedTypeBuilder(
        outlineListener, charOffset, name, clonedArguments);
    newTypes.add(newType);
    return newType;
  }

  int get _storeOffset {
    // TODO(scheglov) Can we always make charOffset the "suffix" offset?
    var name = this.name;
    return name is QualifiedName ? name.charOffset : charOffset;
  }

  void _storeType(LibraryBuilder library, DartType type) {
    if (outlineListener != null) {
      if (arguments != null && !this.declaration.buildsArguments) {
        for (var argument in arguments) {
          argument.build(library);
        }
      }
      TypeDeclarationBuilder<KernelTypeBuilder, DartType> storeDeclaration;
      if (actualDeclaration != null) {
        storeDeclaration = actualDeclaration;
        type = storeDeclaration.buildType(library, null);
      } else {
        storeDeclaration = declaration;
      }
      var target = storeDeclaration.hasTarget ? storeDeclaration.target : null;
      outlineListener.store(_storeOffset, false, reference: target, type: type);
    }
  }
}
