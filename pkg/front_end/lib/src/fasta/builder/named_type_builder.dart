// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.named_type_builder;

import 'package:kernel/ast.dart';

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
        templateExperimentNotEnabled,
        templateExtendingRestricted,
        templateNotAType,
        templateSupertypeIsIllegal,
        templateSupertypeIsIllegalAliased,
        templateSupertypeIsNullableAliased,
        templateSupertypeIsTypeVariable,
        templateTypeArgumentMismatch,
        templateTypeArgumentsOnTypeVariable,
        templateTypeNotFound;

import '../identifiers.dart' show Identifier, QualifiedName, flattenName;

import '../problems.dart' show unhandled;

import '../scope.dart';

import '../source/source_library_builder.dart';

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

/// Enum used to determine how instance type variable access is allowed.
enum InstanceTypeVariableAccessState {
  /// Instance type variable access is allowed.
  ///
  /// This is used for valid references to instance type variables, like
  ///
  ///     class Class<T> {
  ///       void instanceMethod(T t) {}
  ///     }
  Allowed,

  /// Instance type variable access is disallowed and results in a compile-time
  /// error.
  ///
  /// This is used for static references to instance type variables, like
  ///
  ///     class Class<T> {
  ///       static void staticMethod(T t) {}
  ///     }
  ///
  /// The type is resolved as an [InvalidType].
  Disallowed,

  /// Instance type variable access is invalid since it occurs in an invalid
  /// context. The occurrence _doesn't_ result in a compile-time error.
  ///
  /// This is used for references to instance type variables where they might
  /// be valid if the context where, like
  ///
  ///     class Extension<T> {
  ///       T field; // Instance extension fields are not allowed.
  ///     }
  ///
  /// The type is resolved as an [InvalidType].
  Invalid,

  /// Instance type variable access is unexpected and results in an assertion
  /// failure.
  ///
  /// This is used for [NamedTypeBuilder]s for known non-type variable types,
  /// like for `Object` and `String`.
  Unexpected,
}

class NamedTypeBuilder extends TypeBuilder {
  @override
  final Object name;

  List<TypeBuilder>? arguments;

  @override
  final NullabilityBuilder nullabilityBuilder;

  @override
  final Uri? fileUri;

  @override
  final int? charOffset;

  TypeDeclarationBuilder? _declaration;

  final InstanceTypeVariableAccessState _instanceTypeVariableAccess;

  final bool _forTypeLiteral;

  DartType? _type;

  NamedTypeBuilder(this.name, this.nullabilityBuilder,
      {this.arguments,
      this.fileUri,
      this.charOffset,
      required InstanceTypeVariableAccessState instanceTypeVariableAccess,
      bool forTypeLiteral: false})
      : assert(name is String || name is QualifiedName),
        this._instanceTypeVariableAccess = instanceTypeVariableAccess,
        this._forTypeLiteral = forTypeLiteral;

  NamedTypeBuilder.forDartType(DartType this._type,
      TypeDeclarationBuilder this._declaration, this.nullabilityBuilder,
      {this.arguments})
      : this.name = _declaration.name,
        this._instanceTypeVariableAccess =
            InstanceTypeVariableAccessState.Unexpected,
        this.fileUri = null,
        this.charOffset = null,
        this._forTypeLiteral = false;

  NamedTypeBuilder.fromTypeDeclarationBuilder(
      TypeDeclarationBuilder this._declaration, this.nullabilityBuilder,
      {this.arguments,
      this.fileUri,
      this.charOffset,
      required InstanceTypeVariableAccessState instanceTypeVariableAccess,
      DartType? type})
      : this.name = _declaration.name,
        this._forTypeLiteral = false,
        this._instanceTypeVariableAccess = instanceTypeVariableAccess,
        this._type = type;

  NamedTypeBuilder.forInvalidType(
      String this.name, this.nullabilityBuilder, LocatedMessage message,
      {List<LocatedMessage>? context})
      : _declaration =
            new InvalidTypeDeclarationBuilder(name, message, context: context),
        this.fileUri = message.uri,
        this.charOffset = message.charOffset,
        this._instanceTypeVariableAccess =
            InstanceTypeVariableAccessState.Unexpected,
        this._forTypeLiteral = false,
        this._type = const InvalidType();

  @override
  TypeDeclarationBuilder? get declaration => _declaration;

  @override
  bool get isVoidType => declaration is VoidTypeDeclarationBuilder;

  void bind(LibraryBuilder libraryBuilder, TypeDeclarationBuilder declaration) {
    _declaration = declaration.origin;
    _check(libraryBuilder);
  }

  String get nameText {
    if (name is Identifier) {
      Identifier identifier = name as Identifier;
      return identifier.name;
    } else {
      assert(name is String);
      return name as String;
    }
  }

  int get nameOffset {
    if (name is Identifier) {
      Identifier identifier = name as Identifier;
      return identifier.charOffset;
    }
    return charOffset!;
  }

  int get nameLength {
    return nameText.length;
  }

  void resolveIn(
      Scope scope, int charOffset, Uri fileUri, LibraryBuilder library) {
    if (_declaration != null) return;
    final Object name = this.name;
    Builder? member;
    if (name is QualifiedName) {
      Object qualifier = name.qualifier;
      String prefixName = flattenName(qualifier, charOffset, fileUri);
      Builder? prefix = scope.lookup(prefixName, charOffset, fileUri);
      if (prefix is PrefixBuilder) {
        member = prefix.lookup(name.name, name.charOffset, fileUri);
      }
    } else if (name is String) {
      member = scope.lookup(name, charOffset, fileUri);
    } else {
      unhandled("${name.runtimeType}", "resolveIn", charOffset, fileUri);
    }
    if (member is TypeDeclarationBuilder) {
      bind(library, member);
    } else {
      Template<Message Function(String name)> template =
          member == null ? templateTypeNotFound : templateNotAType;
      String flatName = flattenName(name, charOffset, fileUri);
      int length = name is Identifier
          ? name.endCharOffset - charOffset
          : flatName.length;
      Message message;
      List<LocatedMessage>? context;
      if (member == null) {
        template = templateTypeNotFound;
        message = template.withArguments(flatName);
      } else {
        template = templateNotAType;
        context = <LocatedMessage>[
          messageNotATypeContext.withLocation(
              member.fileUri!,
              member.charOffset,
              name is Identifier ? name.name.length : "$name".length)
        ];
        message = template.withArguments(flatName);
      }
      library.addProblem(message, charOffset, length, fileUri,
          context: context);
      TypeDeclarationBuilder declaration = buildInvalidTypeDeclarationBuilder(
          message.withLocation(fileUri, charOffset, length),
          context: context);
      bind(library, declaration);
    }
  }

  void _check(LibraryBuilder library) {
    if (_declaration is InvalidTypeDeclarationBuilder) {
      return;
    }
    if (arguments != null) {
      if (_declaration!.isTypeVariable) {
        String typeName = nameText;
        int typeNameOffset = nameOffset;
        Message message =
            templateTypeArgumentsOnTypeVariable.withArguments(typeName);
        library.addProblem(message, typeNameOffset, typeName.length, fileUri);
        // TODO(johnniwinther): Should we retain the declaration to support
        //  additional errors?
        _declaration = buildInvalidTypeDeclarationBuilder(
            message.withLocation(fileUri!, typeNameOffset, typeName.length));
      } else if (arguments!.length != declaration!.typeVariablesCount) {
        int typeNameLength = nameLength;
        int typeNameOffset = nameOffset;
        Message message = templateTypeArgumentMismatch
            .withArguments(declaration!.typeVariablesCount);
        library.addProblem(message, typeNameOffset, typeNameLength, fileUri);
        _declaration = buildInvalidTypeDeclarationBuilder(
            message.withLocation(fileUri!, typeNameOffset, typeNameLength));
      }
    }
    if (_declaration!.isExtension &&
        library is SourceLibraryBuilder &&
        !library.enableExtensionTypesInLibrary) {
      Message message = templateExperimentNotEnabled.withArguments(
          'extension-types',
          library.enableExtensionTypesVersionInLibrary.toText());
      int typeNameLength = nameLength;
      int typeNameOffset = nameOffset;
      library.addProblem(message, typeNameOffset, typeNameLength, fileUri);
      _declaration = buildInvalidTypeDeclarationBuilder(
          message.withLocation(fileUri!, typeNameOffset, typeNameLength));
    } else if (_declaration!.isTypeVariable) {
      TypeVariableBuilder typeParameterBuilder =
          _declaration as TypeVariableBuilder;
      if (typeParameterBuilder.kind == TypeVariableKind.classMixinOrEnum ||
          typeParameterBuilder.kind == TypeVariableKind.extension ||
          typeParameterBuilder.kind == TypeVariableKind.extensionSynthesized) {
        switch (_instanceTypeVariableAccess) {
          case InstanceTypeVariableAccessState.Disallowed:
            int typeNameLength = nameLength;
            int typeNameOffset = nameOffset;
            Message message = messageTypeVariableInStaticContext;
            library.addProblem(
                message, typeNameOffset, typeNameLength, fileUri);
            _declaration = buildInvalidTypeDeclarationBuilder(
                message.withLocation(fileUri!, typeNameOffset, typeNameLength));
            return;
          case InstanceTypeVariableAccessState.Invalid:
            int typeNameLength = nameLength;
            int typeNameOffset = nameOffset;
            Message message = messageTypeVariableInStaticContext;
            _declaration = buildInvalidTypeDeclarationBuilder(
                message.withLocation(fileUri!, typeNameOffset, typeNameLength));
            return;
          case InstanceTypeVariableAccessState.Unexpected:
            assert(false,
                "Unexpected instance type variable $typeParameterBuilder");
            break;
          case InstanceTypeVariableAccessState.Allowed:
            break;
        }
      }
    }
  }

  @override
  String get debugName => "NamedTypeBuilder";

  @override
  StringBuffer printOn(StringBuffer buffer) {
    buffer.write(flattenName(name, charOffset ?? TreeNode.noOffset, fileUri));
    if (arguments?.isEmpty ?? true) return buffer;
    buffer.write("<");
    bool first = true;
    for (TypeBuilder t in arguments!) {
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
      {List<LocatedMessage>? context}) {
    // TODO(ahe): Consider if it makes sense to pass a QualifiedName to
    // InvalidTypeBuilder?
    return new InvalidTypeDeclarationBuilder(
        flattenName(name, message.charOffset, message.uri), message,
        context: context);
  }

  Supertype? _handleInvalidSupertype(LibraryBuilder library) {
    Template<Message Function(String name)> template =
        declaration!.isTypeVariable
            ? templateSupertypeIsTypeVariable
            : templateSupertypeIsIllegal;
    library.addProblem(template.withArguments(fullNameForErrors), charOffset!,
        noLength, fileUri);
    return null;
  }

  Supertype? _handleInvalidAliasedSupertype(
      LibraryBuilder library, TypeAliasBuilder aliasBuilder, DartType type) {
    // Don't report the error in case of InvalidType. An error has already been
    // reported in this case.
    if (type is InvalidType) return null;

    Message message;
    if (declaration!.isTypeVariable) {
      message =
          templateSupertypeIsTypeVariable.withArguments(fullNameForErrors);
    } else
    // ignore: unnecessary_null_comparison
    if (type != null && type.nullability == Nullability.nullable) {
      message = templateSupertypeIsNullableAliased.withArguments(
          fullNameForErrors, type, library.isNonNullableByDefault);
    } else {
      message = templateSupertypeIsIllegalAliased.withArguments(
          fullNameForErrors, type, library.isNonNullableByDefault);
    }
    library.addProblem(message, charOffset!, noLength, fileUri, context: [
      messageTypedefCause.withLocation(
          aliasBuilder.fileUri, aliasBuilder.charOffset, noLength),
    ]);
    return null;
  }

  @override
  DartType build(LibraryBuilder library) {
    return _type ??= _buildInternal(library);
  }

  DartType _declarationBuildType(LibraryBuilder library) {
    if (_forTypeLiteral) {
      return declaration!
          .buildTypeLiteralType(library, nullabilityBuilder, arguments);
    } else {
      return declaration!.buildType(library, nullabilityBuilder, arguments);
    }
  }

  DartType _buildInternal(LibraryBuilder library) {
    assert(declaration != null, "Declaration has not been resolved on $this.");
    if (library is SourceLibraryBuilder) {
      int uncheckedTypedefTypeCount = library.uncheckedTypedefTypes.length;
      DartType builtType = _declarationBuildType(library);
      // Set locations for new unchecked TypedefTypes for error reporting.
      for (int i = uncheckedTypedefTypeCount;
          i < library.uncheckedTypedefTypes.length;
          ++i) {
        // TODO(johnniwinther): Pass the uri/offset through the build methods
        // to avoid this.
        library.uncheckedTypedefTypes[i]
          ..fileUri ??= fileUri
          ..offset ??= charOffset;
      }
      return builtType;
    } else {
      return _declarationBuildType(library);
    }
  }

  @override
  Supertype? buildSupertype(LibraryBuilder library) {
    TypeDeclarationBuilder declaration = this.declaration!;
    if (declaration is ClassBuilder) {
      if (declaration.isNullClass && !library.mayImplementRestrictedTypes) {
        library.addProblem(
            templateExtendingRestricted.withArguments(declaration.name),
            charOffset!,
            noLength,
            fileUri);
      }
      return declaration.buildSupertype(library, arguments);
    } else if (declaration is TypeAliasBuilder) {
      TypeAliasBuilder aliasBuilder = declaration;
      DartType type = build(library);
      if (type is InterfaceType && type.nullability != Nullability.nullable) {
        return new Supertype(type.classNode, type.typeArguments);
      } else if (type is NullType) {
        // Even though Null is disallowed as a supertype, ClassHierarchyBuilder
        // still expects it to be built to the respective InterfaceType
        // referencing the deprecated class.
        // TODO(dmitryas): Remove the dependency on the deprecated Null class
        // from ClassHierarchyBuilder.
        TypeDeclarationBuilder? unaliasedDeclaration = this.declaration;
        // The following code assumes that the declaration is a TypeAliasBuilder
        // that through a chain of other TypeAliasBuilders (possibly, the chain
        // length is 0) references a ClassBuilder of the Null class.  Otherwise,
        // it won't produce the NullType on the output.
        while (unaliasedDeclaration is TypeAliasBuilder) {
          unaliasedDeclaration = unaliasedDeclaration.type?.declaration;
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
        TypeDeclarationBuilder? unaliasedDeclaration = this.declaration;
        // The following code assumes that the declaration is a TypeAliasBuilder
        // that through a chain of other TypeAliasBuilders (possibly, the chain
        // length is 0) references a ClassBuilder of the FutureOr class.
        // Otherwise, it won't produce the FutureOrType on the output.
        while (unaliasedDeclaration is TypeAliasBuilder) {
          unaliasedDeclaration = unaliasedDeclaration.type?.declaration;
          assert(unaliasedDeclaration != null);
        }
        assert(unaliasedDeclaration is ClassBuilder &&
            unaliasedDeclaration.name == "FutureOr");
        return new Supertype((unaliasedDeclaration as ClassBuilder).cls,
            <DartType>[type.typeArgument]);
      }
      return _handleInvalidAliasedSupertype(library, aliasBuilder, type);
    } else if (declaration is InvalidTypeDeclarationBuilder) {
      library.addProblem(
          declaration.message.messageObject,
          declaration.message.charOffset,
          declaration.message.length,
          declaration.message.uri,
          severity: Severity.error);
      return null;
    }
    return _handleInvalidSupertype(library);
  }

  @override
  Supertype? buildMixedInType(LibraryBuilder library) {
    TypeDeclarationBuilder declaration = this.declaration!;
    if (declaration is ClassBuilder) {
      return declaration.buildMixedInType(library, arguments);
    } else if (declaration is TypeAliasBuilder) {
      TypeAliasBuilder aliasBuilder = declaration;
      DartType type = build(library);
      if (type is InterfaceType && type.nullability != Nullability.nullable) {
        return new Supertype(type.classNode, type.typeArguments);
      }
      return _handleInvalidAliasedSupertype(library, aliasBuilder, type);
    } else if (declaration is InvalidTypeDeclarationBuilder) {
      library.addProblem(
          declaration.message.messageObject,
          declaration.message.charOffset,
          declaration.message.length,
          declaration.message.uri,
          severity: Severity.error);
      return null;
    }
    return _handleInvalidSupertype(library);
  }

  @override
  TypeBuilder subst(Map<TypeVariableBuilder, TypeBuilder> substitution) {
    TypeBuilder? result = substitution[declaration];
    if (result != null) {
      assert(declaration is TypeVariableBuilder);
      return result;
    } else if (this.arguments != null) {
      List<TypeBuilder>? arguments;
      int i = 0;
      for (TypeBuilder argument in this.arguments!) {
        TypeBuilder type = argument.subst(substitution);
        if (type != argument) {
          arguments ??= this.arguments!.toList();
          arguments[i] = type;
        }
        i++;
      }
      if (arguments != null) {
        return new NamedTypeBuilder.fromTypeDeclarationBuilder(
            declaration!, nullabilityBuilder,
            arguments: arguments,
            fileUri: fileUri,
            charOffset: charOffset,
            instanceTypeVariableAccess: _instanceTypeVariableAccess);
      }
    }
    return this;
  }

  @override
  NamedTypeBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    List<TypeBuilder>? clonedArguments;
    if (arguments != null) {
      clonedArguments =
          new List<TypeBuilder>.generate(arguments!.length, (int i) {
        return arguments![i]
            .clone(newTypes, contextLibrary, contextDeclaration);
      }, growable: false);
    }
    NamedTypeBuilder newType = new NamedTypeBuilder(name, nullabilityBuilder,
        arguments: clonedArguments,
        fileUri: fileUri,
        charOffset: charOffset,
        instanceTypeVariableAccess: _instanceTypeVariableAccess);
    if (declaration is BuiltinTypeDeclarationBuilder) {
      newType._declaration = declaration;
    } else {
      newTypes.add(newType);
    }
    return newType;
  }

  @override
  NamedTypeBuilder withNullabilityBuilder(
      NullabilityBuilder nullabilityBuilder) {
    return new NamedTypeBuilder.fromTypeDeclarationBuilder(
        declaration!, nullabilityBuilder,
        arguments: arguments,
        fileUri: fileUri,
        charOffset: charOffset,
        instanceTypeVariableAccess: _instanceTypeVariableAccess);
  }

  /// Returns a copy of this named type using the provided type [arguments]
  /// instead of the original type arguments.
  NamedTypeBuilder withArguments(List<TypeBuilder> arguments) {
    if (_declaration != null) {
      return new NamedTypeBuilder.fromTypeDeclarationBuilder(
          _declaration!, nullabilityBuilder,
          arguments: arguments,
          fileUri: fileUri,
          charOffset: charOffset,
          instanceTypeVariableAccess: _instanceTypeVariableAccess);
    } else {
      return new NamedTypeBuilder(name, nullabilityBuilder,
          arguments: arguments,
          fileUri: fileUri,
          charOffset: charOffset,
          instanceTypeVariableAccess: _instanceTypeVariableAccess);
    }
  }
}
