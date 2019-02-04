// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.named_type_builder;

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

import '../problems.dart' show unhandled;

import 'builder.dart'
    show
        Declaration,
        Identifier,
        InvalidTypeBuilder,
        LibraryBuilder,
        PrefixBuilder,
        QualifiedName,
        Scope,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder,
        flattenName;

abstract class NamedTypeBuilder<T extends TypeBuilder, R> extends TypeBuilder {
  final Object name;

  List<T> arguments;

  @override
  TypeDeclarationBuilder<T, R> declaration;

  NamedTypeBuilder(this.name, this.arguments);

  @override
  InvalidTypeBuilder<T, R> buildInvalidType(LocatedMessage message,
      {List<LocatedMessage> context});

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
        declaration = buildInvalidType(templateTypeArgumentsOnTypeVariable
            .withArguments(typeName)
            .withLocation(fileUri, typeNameOffset, typeName.length));
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
    declaration = buildInvalidType(
        template
            .withArguments(flatName)
            .withLocation(fileUri, charOffset, length),
        context: context);
  }

  @override
  void check(int charOffset, Uri fileUri) {
    if (arguments != null &&
        arguments.length != declaration.typeVariablesCount) {
      declaration = buildInvalidType(templateTypeArgumentMismatch
          .withArguments(declaration.typeVariablesCount)
          .withLocation(fileUri, charOffset, noLength));
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
    for (T t in arguments) {
      if (!first) buffer.write(", ");
      first = false;
      t.printOn(buffer);
    }
    buffer.write(">");
    return buffer;
  }
}
