// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.named_type_builder;

import 'package:kernel/ast.dart' show DartType, Supertype;

import '../fasta_codes.dart'
    show
        Message,
        Template,
        noLength,
        templateMissingExplicitTypeArguments,
        messageNotATypeContext,
        LocatedMessage,
        templateNotAType,
        templateTypeArgumentMismatch,
        templateTypeArgumentsOnTypeVariable,
        templateTypeNotFound;

import '../messages.dart'
    show noLength, templateSupertypeIsIllegal, templateSupertypeIsTypeVariable;

import '../problems.dart' show unhandled;

import '../severity.dart' show Severity;

import 'builder.dart'
    show
        Declaration,
        Identifier,
        LibraryBuilder,
        PrefixBuilder,
        QualifiedName,
        Scope,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder,
        flattenName;

import '../kernel/kernel_builder.dart'
    show
        KernelClassBuilder,
        KernelInvalidTypeBuilder,
        LibraryBuilder,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder,
        flattenName;

class NamedTypeBuilder extends TypeBuilder {
  final Object name;

  List<TypeBuilder> arguments;

  @override
  TypeDeclarationBuilder<TypeBuilder, DartType> declaration;

  NamedTypeBuilder(this.name, this.arguments);

  @override
  void bind(TypeDeclarationBuilder declaration) {
    this.declaration = declaration?.origin;
  }

  @override
  void resolveIn(
      Scope scope, int charOffset, Uri fileUri, LibraryBuilder library) {
    if (declaration != null) return;
    final name = this.name;
    Declaration member;
    if (name is QualifiedName) {
      Object qualifier = name.qualifier;
      String prefixName = flattenName(qualifier, charOffset, fileUri);
      Declaration prefix = scope.lookup(prefixName, charOffset, fileUri);
      if (prefix is PrefixBuilder) {
        member = prefix.lookup(name.name, name.charOffset, fileUri);
      }
    } else if (name is String) {
      member = scope.lookup(name, charOffset, fileUri);
    } else {
      unhandled("${name.runtimeType}", "resolveIn", charOffset, fileUri);
    }
    if (member is TypeVariableBuilder) {
      declaration = member.origin;
      if (arguments != null) {
        String typeName;
        int typeNameOffset;
        if (name is Identifier) {
          typeName = name.name;
          typeNameOffset = name.charOffset;
        } else {
          typeName = name;
          typeNameOffset = charOffset;
        }
        Message message =
            templateTypeArgumentsOnTypeVariable.withArguments(typeName);
        library.addProblem(message, typeNameOffset, typeName.length, fileUri);
        declaration = buildInvalidType(
            message.withLocation(fileUri, typeNameOffset, typeName.length));
      }
      return;
    } else if (member is TypeDeclarationBuilder) {
      declaration = member.origin;
      if (arguments == null && declaration.typeVariablesCount != 0) {
        String typeName;
        int typeNameOffset;
        if (name is Identifier) {
          typeName = name.name;
          typeNameOffset = name.charOffset;
        } else {
          typeName = name;
          typeNameOffset = charOffset;
        }
        library.addProblem(
            templateMissingExplicitTypeArguments
                .withArguments(declaration.typeVariablesCount),
            typeNameOffset,
            typeName.length,
            fileUri);
      }
      return;
    }
    Template<Message Function(String name)> template =
        member == null ? templateTypeNotFound : templateNotAType;
    String flatName = flattenName(name, charOffset, fileUri);
    List<LocatedMessage> context;
    if (member != null) {
      context = <LocatedMessage>[
        messageNotATypeContext.withLocation(member.fileUri, member.charOffset,
            name is Identifier ? name.name.length : "$name".length)
      ];
    }
    int length =
        name is Identifier ? name.endCharOffset - charOffset : flatName.length;
    Message message = template.withArguments(flatName);
    library.addProblem(message, charOffset, length, fileUri, context: context);
    declaration = buildInvalidType(
        message.withLocation(fileUri, charOffset, length),
        context: context);
  }

  @override
  void check(LibraryBuilder library, int charOffset, Uri fileUri) {
    if (arguments != null &&
        arguments.length != declaration.typeVariablesCount) {
      Message message = templateTypeArgumentMismatch
          .withArguments(declaration.typeVariablesCount);
      library.addProblem(message, charOffset, noLength, fileUri);
      declaration =
          buildInvalidType(message.withLocation(fileUri, charOffset, noLength));
    }
  }

  @override
  void normalize(int charOffset, Uri fileUri) {
    if (arguments != null &&
        arguments.length != declaration.typeVariablesCount) {
      // [arguments] will be normalized later if they are null.
      arguments = null;
    }
  }

  String get debugName => "NamedTypeBuilder";

  StringBuffer printOn(StringBuffer buffer) {
    buffer.write(name);
    if (arguments?.isEmpty ?? true) return buffer;
    buffer.write("<");
    bool first = true;
    for (TypeBuilder t in arguments) {
      if (!first) buffer.write(", ");
      first = false;
      t.printOn(buffer);
    }
    buffer.write(">");
    return buffer;
  }

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
      List<TypeBuilder> arguments;
      int i = 0;
      for (TypeBuilder argument in this.arguments) {
        TypeBuilder type = argument.subst(substitution);
        if (type != argument) {
          arguments ??= this.arguments.toList();
          arguments[i] = type;
        }
        i++;
      }
      if (arguments != null) {
        return new NamedTypeBuilder(name, arguments)..bind(declaration);
      }
    }
    return this;
  }

  NamedTypeBuilder clone(List<TypeBuilder> newTypes) {
    List<TypeBuilder> clonedArguments;
    if (arguments != null) {
      clonedArguments = new List<TypeBuilder>(arguments.length);
      for (int i = 0; i < clonedArguments.length; i++) {
        clonedArguments[i] = arguments[i].clone(newTypes);
      }
    }
    NamedTypeBuilder newType = new NamedTypeBuilder(name, clonedArguments);
    newTypes.add(newType);
    return newType;
  }
}
