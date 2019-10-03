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
        Builder,
        Identifier,
        LibraryBuilder,
        NullabilityBuilder,
        PrefixBuilder,
        QualifiedName,
        Scope,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder,
        flattenName;

import '../kernel/kernel_builder.dart'
    show
        ClassBuilder,
        InvalidTypeBuilder,
        LibraryBuilder,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder,
        flattenName;

class NamedTypeBuilder extends TypeBuilder {
  final Object name;

  List<TypeBuilder> arguments;

  final NullabilityBuilder nullabilityBuilder;

  @override
  TypeDeclarationBuilder declaration;

  NamedTypeBuilder(this.name, this.nullabilityBuilder, this.arguments);

  NamedTypeBuilder.fromTypeDeclarationBuilder(
      this.declaration, this.nullabilityBuilder,
      [this.arguments])
      : this.name = declaration.name;

  @override
  void bind(TypeDeclarationBuilder declaration) {
    this.declaration = declaration?.origin;
  }

  @override
  void resolveIn(
      Scope scope, int charOffset, Uri fileUri, LibraryBuilder library) {
    if (declaration != null) return;
    final Object name = this.name;
    Builder member;
    if (name is QualifiedName) {
      Object qualifier = name.qualifier;
      String prefixName = flattenName(qualifier, charOffset, fileUri);
      Builder prefix = scope.lookup(prefixName, charOffset, fileUri);
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
      if (!declaration.isExtension) {
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
    nullabilityBuilder.writeNullabilityOn(buffer);
    return buffer;
  }

  InvalidTypeBuilder buildInvalidType(LocatedMessage message,
      {List<LocatedMessage> context}) {
    // TODO(ahe): Consider if it makes sense to pass a QualifiedName to
    // InvalidTypeBuilder?
    return new InvalidTypeBuilder(
        flattenName(name, message.charOffset, message.uri), message,
        context: context);
  }

  Supertype handleInvalidSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    Template<Message Function(String name)> template =
        declaration.isTypeVariable
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
    assert(declaration != null, "Declaration has not been resolved on $this.");
    return declaration.buildType(library, nullabilityBuilder, arguments);
  }

  Supertype buildSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    TypeDeclarationBuilder declaration = this.declaration;
    if (declaration is ClassBuilder) {
      return declaration.buildSupertype(library, arguments);
    } else if (declaration is InvalidTypeBuilder) {
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
    if (declaration is ClassBuilder) {
      return declaration.buildMixedInType(library, arguments);
    } else if (declaration is InvalidTypeBuilder) {
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
        NamedTypeBuilder result =
            new NamedTypeBuilder(name, nullabilityBuilder, arguments);
        if (declaration != null) {
          result.bind(declaration);
        } else {
          throw new UnsupportedError("Unbound type in substitution: $result.");
        }
        return result;
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
    NamedTypeBuilder newType =
        new NamedTypeBuilder(name, nullabilityBuilder, clonedArguments);
    newTypes.add(newType);
    return newType;
  }

  NamedTypeBuilder withNullabilityBuilder(
      NullabilityBuilder nullabilityBuilder) {
    return new NamedTypeBuilder(name, nullabilityBuilder, arguments)
      ..bind(declaration);
  }
}
