// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.named_type_builder;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:kernel/ast.dart' hide MapEntry;

import '../fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        Severity,
        Template,
        messageNotATypeContext,
        messageTypeVariableInStaticContext,
        messageTypedefCause,
        noLength,
        templateExtendingRestricted,
        templateMissingExplicitTypeArguments,
        templateNotAType,
        templateSupertypeIsIllegal,
        templateSupertypeIsTypeVariable,
        templateTypeArgumentMismatch,
        templateTypeArgumentsOnTypeVariable,
        templateTypeNotFound;

import '../identifiers.dart' show Identifier, QualifiedName, flattenName;

import '../messages.dart'
    show noLength, templateSupertypeIsIllegal, templateSupertypeIsTypeVariable;

import '../problems.dart' show unhandled;

import '../scope.dart';

import 'builder.dart';
import 'builtin_type_declaration_builder.dart';
import 'class_builder.dart';
import 'invalid_type_declaration_builder.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'prefix_builder.dart';
import 'type_alias_builder.dart';
import 'type_builder.dart';
import 'type_declaration_builder.dart';
import 'type_variable_builder.dart';
import 'void_type_declaration_builder.dart';

class NamedTypeBuilder extends TypeBuilder {
  final Object name;

  List<TypeBuilder> arguments;

  final NullabilityBuilder nullabilityBuilder;

  @override
  final Uri fileUri;

  @override
  final int charOffset;

  @override
  TypeDeclarationBuilder declaration;

  NamedTypeBuilder(this.name, this.nullabilityBuilder, this.arguments,
      this.fileUri, this.charOffset);

  NamedTypeBuilder.fromTypeDeclarationBuilder(
      this.declaration, this.nullabilityBuilder,
      [this.arguments, this.fileUri, this.charOffset])
      : this.name = declaration.name;

  bool get isVoidType => declaration is VoidTypeDeclarationBuilder;

  @override
  void bind(TypeDeclarationBuilder declaration) {
    this.declaration = declaration?.origin;
  }

  int get nameOffset {
    if (name is Identifier) {
      Identifier identifier = name;
      return identifier.charOffset;
    }
    return -1; // TODO(eernst): make it possible to get offset.
  }

  int get nameLength {
    if (name is Identifier) {
      Identifier identifier = name;
      return identifier.name.length;
    } else if (name is String) {
      String nameString = name;
      return nameString.length;
    } else {
      return noLength;
    }
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
        declaration = buildInvalidTypeDeclarationBuilder(
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
    declaration = buildInvalidTypeDeclarationBuilder(
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
      declaration = buildInvalidTypeDeclarationBuilder(
          message.withLocation(fileUri, charOffset, noLength));
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

  InvalidTypeDeclarationBuilder buildInvalidTypeDeclarationBuilder(
      LocatedMessage message,
      {List<LocatedMessage> context}) {
    // TODO(ahe): Consider if it makes sense to pass a QualifiedName to
    // InvalidTypeBuilder?
    return new InvalidTypeDeclarationBuilder(
        flattenName(name, message.charOffset, message.uri), message,
        context: context);
  }

  Supertype handleInvalidSupertype(LibraryBuilder library, int charOffset,
      Uri fileUri, TypeAliasBuilder aliasBuilder) {
    Template<Message Function(String name)> template =
        declaration.isTypeVariable
            ? templateSupertypeIsTypeVariable
            : templateSupertypeIsIllegal;
    if (aliasBuilder != null) {
      library.addProblem(
          template.withArguments(flattenName(name, charOffset, fileUri)),
          charOffset,
          noLength,
          fileUri,
          context: [
            messageTypedefCause.withLocation(
                aliasBuilder.fileUri, aliasBuilder.charOffset, noLength),
          ]);
    } else {
      library.addProblem(
          template.withArguments(flattenName(name, charOffset, fileUri)),
          charOffset,
          noLength,
          fileUri);
    }
    return null;
  }

  // TODO(johnniwinther): Store [origin] on the built type.
  DartType build(LibraryBuilder library,
      [TypedefType origin, bool notInstanceContext]) {
    assert(declaration != null, "Declaration has not been resolved on $this.");
    if (notInstanceContext == true && declaration.isTypeVariable) {
      TypeVariableBuilder typeParameterBuilder = declaration;
      TypeParameter typeParameter = typeParameterBuilder.parameter;
      if (typeParameter.parent is Class || typeParameter.parent is Extension) {
        library.addProblem(
            messageTypeVariableInStaticContext,
            charOffset ?? TreeNode.noOffset,
            noLength,
            fileUri ?? library.fileUri);
        return const InvalidType();
      }
    }

    return declaration.buildType(
        library, nullabilityBuilder, arguments, notInstanceContext);
  }

  Supertype buildSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    TypeDeclarationBuilder declaration = this.declaration;
    TypeAliasBuilder aliasBuilder; // Non-null if a type alias is used.
    if (declaration is ClassBuilder) {
      if (declaration.isNullClass && !library.mayImplementRestrictedTypes) {
        library.addProblem(
            templateExtendingRestricted.withArguments(declaration.name),
            charOffset,
            noLength,
            fileUri);
      }
      return declaration.buildSupertype(library, arguments);
    } else if (declaration is TypeAliasBuilder) {
      aliasBuilder = declaration;
      DartType type =
          declaration.buildType(library, library.nonNullableBuilder, arguments);
      if (type is InterfaceType) {
        return new Supertype(type.classNode, type.typeArguments);
      } else if (type is NullType) {
        // Even though Null is disallowed as a supertype, ClassHierarchyBuilder
        // still expects it to be built to the respective InterfaceType
        // referencing the deprecated class.
        // TODO(dmitryas): Remove the dependency on the deprecated Null class
        // from ClassHierarchyBuilder.
        TypeDeclarationBuilder unaliasedDeclaration = this.declaration;
        // The following code assumes that the declaration is a TypeAliasBuilder
        // that through a chain of other TypeAliasBuilders (possibly, the chian
        // length is 0) references a ClassBuilder of the Null class.  Otherwise,
        // it won't produce the NullType on the output.
        while (unaliasedDeclaration is TypeAliasBuilder) {
          unaliasedDeclaration =
              (unaliasedDeclaration as TypeAliasBuilder).type.declaration;
          assert(unaliasedDeclaration != null);
        }
        assert(unaliasedDeclaration is ClassBuilder &&
            unaliasedDeclaration.name == "Null");
        return new Supertype(
            (unaliasedDeclaration as ClassBuilder).cls, const <DartType>[]);
      } else if (type is FutureOrType) {
        // Even though FutureOr is disallowed as a supertype,
        // ClassHierarchyBuilder still expects it to be built to the respective
        // InterfaceType referencing the deprecated class.  In contrast with
        // Null, it doesn't surface as an error due to FutureOr class not having
        // any inheritable members.
        // TODO(dmitryas): Remove the dependency on the deprecated FutureOr
        // class from ClassHierarchyBuilder.
        TypeDeclarationBuilder unaliasedDeclaration = this.declaration;
        // The following code assumes that the declaration is a TypeAliasBuilder
        // that through a chain of other TypeAliasBuilders (possibly, the chian
        // length is 0) references a ClassBuilder of the FutureOr class.
        // Otherwise, it won't produce the FutureOrType on the output.
        while (unaliasedDeclaration is TypeAliasBuilder) {
          unaliasedDeclaration =
              (unaliasedDeclaration as TypeAliasBuilder).type.declaration;
          assert(unaliasedDeclaration != null);
        }
        assert(unaliasedDeclaration is ClassBuilder &&
            unaliasedDeclaration.name == "FutureOr");
        return new Supertype((unaliasedDeclaration as ClassBuilder).cls,
            <DartType>[type.typeArgument]);
      } else {
        // Do nothing: handleInvalidSuper below will handle the erroneous case.
      }
    } else if (declaration is InvalidTypeDeclarationBuilder) {
      library.addProblem(
          declaration.message.messageObject,
          declaration.message.charOffset,
          declaration.message.length,
          declaration.message.uri,
          severity: Severity.error);
      return null;
    }
    return handleInvalidSupertype(library, charOffset, fileUri, aliasBuilder);
  }

  Supertype buildMixedInType(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    TypeDeclarationBuilder declaration = this.declaration;
    TypeAliasBuilder aliasBuilder; // Non-null if a type alias is used.
    if (declaration is ClassBuilder) {
      return declaration.buildMixedInType(library, arguments);
    } else if (declaration is TypeAliasBuilder) {
      aliasBuilder = declaration;
      DartType type =
          declaration.buildType(library, library.nonNullableBuilder, arguments);
      if (type is InterfaceType) {
        return new Supertype(type.classNode, type.typeArguments);
      }
    } else if (declaration is InvalidTypeDeclarationBuilder) {
      library.addProblem(
          declaration.message.messageObject,
          declaration.message.charOffset,
          declaration.message.length,
          declaration.message.uri,
          severity: Severity.error);
      return null;
    }
    return handleInvalidSupertype(library, charOffset, fileUri, aliasBuilder);
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
        NamedTypeBuilder result = new NamedTypeBuilder(
            name, nullabilityBuilder, arguments, fileUri, charOffset);
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
      clonedArguments = new List<TypeBuilder>.filled(arguments.length, null);
      for (int i = 0; i < clonedArguments.length; i++) {
        clonedArguments[i] = arguments[i].clone(newTypes);
      }
    }
    NamedTypeBuilder newType = new NamedTypeBuilder(
        name, nullabilityBuilder, clonedArguments, fileUri, charOffset);
    if (declaration is BuiltinTypeDeclarationBuilder) {
      newType.declaration = declaration;
    } else {
      newTypes.add(newType);
    }
    return newType;
  }

  NamedTypeBuilder withNullabilityBuilder(
      NullabilityBuilder nullabilityBuilder) {
    return new NamedTypeBuilder(
        name, nullabilityBuilder, arguments, fileUri, charOffset)
      ..bind(declaration);
  }
}
