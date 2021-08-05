// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.outline_builder;

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show
        Assert,
        DeclarationKind,
        FormalParameterKind,
        IdentifierContext,
        lengthOfSpan,
        MemberKind,
        optional;

import 'package:_fe_analyzer_shared/src/parser/quote.dart' show unescapeString;

import 'package:_fe_analyzer_shared/src/parser/stack_listener.dart'
    show FixedNullableList, NullValue, ParserRecovery;

import 'package:_fe_analyzer_shared/src/parser/value_kind.dart';

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;

import 'package:kernel/ast.dart'
    show AsyncMarker, InvalidType, Nullability, ProcedureKind, Variance;

import '../builder/constructor_reference_builder.dart';
import '../builder/enum_builder.dart';
import '../builder/fixed_type_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_type_builder.dart';
import '../builder/invalid_type_declaration_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/mixin_application_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_variable_builder.dart';
import '../builder/unresolved_type.dart';

import '../combinator.dart' show Combinator;

import '../configuration.dart' show Configuration;

import '../fasta_codes.dart';

import '../identifiers.dart' show QualifiedName, flattenName;

import '../ignored_parser_errors.dart' show isIgnoredParserError;

import '../kernel/type_algorithms.dart';
import '../kernel/utils.dart';

import '../modifier.dart'
    show
        Const,
        Covariant,
        External,
        Final,
        Modifier,
        Static,
        Var,
        abstractMask,
        constMask,
        covariantMask,
        externalMask,
        finalMask,
        lateMask,
        mixinDeclarationMask,
        requiredMask,
        staticMask;

import '../operator.dart'
    show
        Operator,
        operatorFromString,
        operatorToString,
        operatorRequiredArgumentCount;

import '../problems.dart' show unhandled;

import 'source_extension_builder.dart';

import 'source_library_builder.dart'
    show
        TypeParameterScopeBuilder,
        TypeParameterScopeKind,
        FieldInfo,
        SourceLibraryBuilder;

import 'stack_listener_impl.dart';

import 'value_kinds.dart';

enum MethodBody {
  Abstract,
  Regular,
  RedirectingFactoryBody,
}

class OutlineBuilder extends StackListenerImpl {
  final SourceLibraryBuilder libraryBuilder;

  final bool enableNative;
  final bool stringExpectedAfterNative;
  bool inAbstractClass = false;
  bool inConstructor = false;
  bool inConstructorName = false;
  int importIndex = 0;

  String? nativeMethodName;

  /// Counter used for naming unnamed extension declarations.
  int unnamedExtensionCounter = 0;

  OutlineBuilder(SourceLibraryBuilder library)
      : libraryBuilder = library,
        enableNative =
            library.loader.target.backendTarget.enableNative(library.importUri),
        stringExpectedAfterNative =
            library.loader.target.backendTarget.nativeExtensionExpectsString;

  @override
  Uri get uri => libraryBuilder.fileUri;

  int popCharOffset() => pop() as int;

  List<String>? popIdentifierList(int count) {
    if (count == 0) return null;
    List<String> list = new List<String>.filled(count, /* dummyValue = */ '');
    bool isParserRecovery = false;
    for (int i = count - 1; i >= 0; i--) {
      popCharOffset();
      Object? identifier = pop();
      if (identifier is ParserRecovery) {
        isParserRecovery = true;
      } else {
        list[i] = identifier as String;
      }
    }
    return isParserRecovery ? null : list;
  }

  @override
  void endMetadata(Token beginToken, Token? periodBeforeName, Token endToken) {
    debugEvent("Metadata");
    pop(); // arguments
    if (periodBeforeName != null) {
      pop(); // offset
      pop(); // constructor name
    }
    pop(); // type arguments
    pop(); // offset
    Object? sentinel = pop(); // prefix or constructor
    push(sentinel is ParserRecovery
        ? sentinel
        : new MetadataBuilder(beginToken));
  }

  @override
  void endMetadataStar(int count) {
    debugEvent("MetadataStar");
    push(const FixedNullableList<MetadataBuilder>()
            .popNonNullable(stack, count, dummyMetadataBuilder) ??
        NullValue.Metadata);
  }

  @override
  void handleInvalidTopLevelDeclaration(Token endToken) {
    debugEvent("InvalidTopLevelDeclaration");
    pop(); // metadata star
  }

  @override
  void endHide(Token hideKeyword) {
    debugEvent("Hide");
    Object? names = pop();
    if (names is ParserRecovery) {
      push(names);
    } else {
      push(new Combinator.hide(names as Iterable<String>,
          hideKeyword.charOffset, libraryBuilder.fileUri));
    }
  }

  @override
  void endShow(Token showKeyword) {
    debugEvent("Show");
    Object? names = pop();
    if (names is ParserRecovery) {
      push(names);
    } else {
      push(new Combinator.show(names as Iterable<String>,
          showKeyword.charOffset, libraryBuilder.fileUri));
    }
  }

  @override
  void endCombinators(int count) {
    debugEvent("Combinators");
    push(const FixedNullableList<Combinator>()
            .popNonNullable(stack, count, dummyCombinator) ??
        NullValue.Combinators);
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    debugEvent("Export");
    List<Combinator>? combinators = pop() as List<Combinator>?;
    List<Configuration>? configurations = pop() as List<Configuration>?;
    int uriOffset = popCharOffset();
    String uri = pop() as String;
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    libraryBuilder.addExport(metadata, uri, configurations, combinators,
        exportKeyword.charOffset, uriOffset);
    checkEmpty(exportKeyword.charOffset);
  }

  @override
  void handleImportPrefix(Token? deferredKeyword, Token? asKeyword) {
    debugEvent("ImportPrefix");
    if (asKeyword == null) {
      // If asKeyword is null, then no prefix has been pushed on the stack.
      // Push a placeholder indicating that there is no prefix.
      push(NullValue.Prefix);
      push(-1);
    }
    push(deferredKeyword != null);
  }

  @override
  void endImport(Token importKeyword, Token? semicolon) {
    debugEvent("EndImport");
    List<Combinator>? combinators = pop() as List<Combinator>?;
    bool isDeferred = pop() as bool;
    int prefixOffset = popCharOffset();
    Object? prefix = pop(NullValue.Prefix);
    List<Configuration>? configurations = pop() as List<Configuration>?;
    int uriOffset = popCharOffset();
    String uri =
        pop() as String; // For a conditional import, this is the default URI.
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    checkEmpty(importKeyword.charOffset);
    if (prefix is ParserRecovery) return;
    libraryBuilder.addImport(
        metadata,
        uri,
        configurations,
        prefix as String?,
        combinators,
        isDeferred,
        importKeyword.charOffset,
        prefixOffset,
        uriOffset,
        importIndex++);
  }

  @override
  void endConditionalUris(int count) {
    debugEvent("EndConditionalUris");
    push(const FixedNullableList<Configuration>()
            .popNonNullable(stack, count, dummyConfiguration) ??
        NullValue.ConditionalUris);
  }

  @override
  void endConditionalUri(Token ifKeyword, Token leftParen, Token? equalSign) {
    debugEvent("EndConditionalUri");
    int charOffset = popCharOffset();
    String uri = pop() as String;
    if (equalSign != null) popCharOffset();
    String condition = popIfNotNull(equalSign) as String? ?? "true";
    Object? dottedName = pop();
    if (dottedName is ParserRecovery) {
      push(dottedName);
    } else {
      push(new Configuration(charOffset, dottedName as String, condition, uri));
    }
  }

  @override
  void handleDottedName(int count, Token firstIdentifier) {
    debugEvent("DottedName");
    List<String>? names = popIdentifierList(count);
    if (names == null) {
      push(new ParserRecovery(firstIdentifier.charOffset));
    } else {
      push(names.join('.'));
    }
  }

  @override
  void handleRecoverImport(Token? semicolon) {
    debugEvent("RecoverImport");
    pop(); // combinators
    pop(NullValue.Deferred); // deferredKeyword
    pop(); // prefixOffset
    pop(NullValue.Prefix); // prefix
    pop(); // conditionalUris
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    debugEvent("Part");
    int charOffset = popCharOffset();
    String uri = pop() as String;
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    libraryBuilder.addPart(metadata, uri, charOffset);
    checkEmpty(partKeyword.charOffset);
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    debugEvent("OperatorName");
    push(operatorFromString(token.stringValue!));
    push(token.charOffset);
  }

  @override
  void handleInvalidOperatorName(Token operatorKeyword, Token token) {
    debugEvent("InvalidOperatorName");
    push('invalid');
    push(token.charOffset);
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    if (context == IdentifierContext.enumValueDeclaration) {
      debugEvent("handleIdentifier");
      List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
      if (token.isSynthetic) {
        push(new ParserRecovery(token.charOffset));
      } else {
        push(new EnumConstantInfo(metadata, token.lexeme, token.charOffset));
      }
    } else {
      super.handleIdentifier(token, context);
      push(token.charOffset);
    }
    if (inConstructor && context == IdentifierContext.methodDeclaration) {
      inConstructorName = true;
    }
  }

  @override
  void handleNoName(Token token) {
    super.handleNoName(token);
    push(token.charOffset);
  }

  @override
  void handleStringPart(Token token) {
    debugEvent("StringPart");
    // Ignore string parts - report error later.
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    debugEvent("endLiteralString");
    if (interpolationCount == 0) {
      Token token = pop() as Token;
      push(unescapeString(token.lexeme, token, this));
      push(token.charOffset);
    } else {
      Token beginToken = pop() as Token;
      int charOffset = beginToken.charOffset;
      push("${SourceLibraryBuilder.MALFORMED_URI_SCHEME}:bad${charOffset}");
      push(charOffset);
      // Point to dollar sign
      int interpolationOffset = charOffset + beginToken.lexeme.length;
      addProblem(messageInterpolationInUri, interpolationOffset, 1);
    }
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    debugEvent("NativeClause");
    if (hasName) {
      // Pop the native clause which in this case is a StringLiteral.
      pop(); // Char offset.
      Object? name = pop();
      if (name is ParserRecovery) {
        nativeMethodName = '';
      } else {
        nativeMethodName = name as String; // String.
      }
    } else {
      nativeMethodName = '';
    }
  }

  @override
  void handleStringJuxtaposition(Token startToken, int literalCount) {
    debugEvent("StringJuxtaposition");
    List<String> list =
        new List<String>.filled(literalCount, /* dummyValue = */ '');
    int charOffset = -1;
    for (int i = literalCount - 1; i >= 0; i--) {
      charOffset = popCharOffset();
      list[i] = pop() as String;
    }
    push(list.join(""));
    push(charOffset);
  }

  @override
  void handleIdentifierList(int count) {
    debugEvent("endIdentifierList");
    push(popIdentifierList(count) ??
        (count == 0 ? NullValue.IdentifierList : new ParserRecovery(-1)));
  }

  @override
  void handleQualified(Token period) {
    assert(checkState(period, [
      /*suffix offset*/ ValueKinds.Integer,
      /*suffix*/ ValueKinds.NameOrParserRecovery,
      /*prefix offset*/ ValueKinds.Integer,
      /*prefix*/ unionOfKinds([
        ValueKinds.Name,
        ValueKinds.ParserRecovery,
        ValueKinds.QualifiedName
      ]),
    ]));
    debugEvent("handleQualified");
    int suffixOffset = popCharOffset();
    Object? suffix = pop();
    int offset = popCharOffset();
    Object prefix = pop()!;
    if (prefix is ParserRecovery) {
      push(prefix);
    } else if (suffix is ParserRecovery) {
      push(suffix);
    } else {
      assert(identical(suffix, period.next!.lexeme));
      assert(suffixOffset == period.next!.charOffset);
      push(new QualifiedName(prefix, period.next!));
    }
    push(offset);
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    debugEvent("endLibraryName");
    popCharOffset();
    Object? name = pop();
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    if (name is! ParserRecovery) {
      libraryBuilder.name =
          flattenName(name!, offsetForToken(libraryKeyword), uri);
    }
    libraryBuilder.metadata = metadata;
  }

  @override
  void beginClassOrNamedMixinApplicationPrelude(Token token) {
    debugEvent("beginClassOrNamedMixinApplicationPrelude");
    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.classOrNamedMixinApplication,
        "class or mixin application");
  }

  @override
  void beginClassDeclaration(Token begin, Token? abstractToken, Token name) {
    debugEvent("beginClassDeclaration");
    List<TypeVariableBuilder>? typeVariables =
        pop() as List<TypeVariableBuilder>?;
    push(typeVariables ?? NullValue.TypeVariables);
    libraryBuilder.currentTypeParameterScopeBuilder
        .markAsClassDeclaration(name.lexeme, name.charOffset, typeVariables);
    libraryBuilder.setCurrentClassName(name.lexeme);
    inAbstractClass = abstractToken != null;
    push(abstractToken != null ? abstractMask : 0);
  }

  @override
  void beginMixinDeclaration(Token mixinKeyword, Token name) {
    debugEvent("beginMixinDeclaration");
    List<TypeVariableBuilder>? typeVariables =
        pop() as List<TypeVariableBuilder>?;
    push(typeVariables ?? NullValue.TypeVariables);
    libraryBuilder.currentTypeParameterScopeBuilder
        .markAsMixinDeclaration(name.lexeme, name.charOffset, typeVariables);
    libraryBuilder.setCurrentClassName(name.lexeme);
  }

  @override
  void beginClassOrMixinBody(DeclarationKind kind, Token token) {
    if (kind == DeclarationKind.Extension) {
      assert(checkState(token, [
        unionOfKinds([ValueKinds.ParserRecovery, ValueKinds.TypeBuilder])
      ]));
      Object? extensionThisType = peek();
      if (extensionThisType is TypeBuilder) {
        libraryBuilder.currentTypeParameterScopeBuilder
            .registerExtensionThisType(extensionThisType);
      } else {
        // TODO(johnniwinther): Supply an invalid type as the extension on type.
      }
    }
    debugEvent("beginClassOrMixinBody");
    // Resolve unresolved types from the class header (i.e., superclass, mixins,
    // and implemented types) before adding members from the class body which
    // should not shadow these unresolved types.
    libraryBuilder.currentTypeParameterScopeBuilder.resolveTypes(
        libraryBuilder.currentTypeParameterScopeBuilder.typeVariables,
        libraryBuilder);
  }

  @override
  void beginNamedMixinApplication(
      Token begin, Token? abstractToken, Token name) {
    debugEvent("beginNamedMixinApplication");
    List<TypeVariableBuilder>? typeVariables =
        pop() as List<TypeVariableBuilder>?;
    push(typeVariables ?? NullValue.TypeVariables);
    libraryBuilder.currentTypeParameterScopeBuilder.markAsNamedMixinApplication(
        name.lexeme, name.charOffset, typeVariables);
    push(abstractToken != null ? abstractMask : 0);
  }

  @override
  void handleClassOrMixinImplements(
      Token? implementsKeyword, int interfacesCount) {
    debugEvent("ClassOrMixinImplements");
    push(const FixedNullableList<TypeBuilder>()
            .popNonNullable(stack, interfacesCount, dummyTypeBuilder) ??
        NullValue.TypeBuilderList);
  }

  @override
  void handleRecoverClassHeader() {
    debugEvent("handleRecoverClassHeader");
    // TODO(jensj): Possibly use these instead... E.g. "class A extend B {}"
    // will get here (because it's 'extends' with an 's') and discard the B...
    // Also Analyzer actually merges the information meaning that the two could
    // give different errors (if, say, one later assigns
    // A to a variable of type B).
    pop(NullValue.TypeBuilderList); // Interfaces.
    pop(); // Supertype offset.
    pop(); // Supertype.
  }

  @override
  void handleRecoverMixinHeader() {
    debugEvent("handleRecoverMixinHeader");
    // TODO(jensj): Possibly use these instead...
    // See also handleRecoverClassHeader
    pop(NullValue.TypeBuilderList); // Interfaces.
    pop(NullValue.TypeBuilderList); // Supertype constraints.
  }

  @override
  void handleClassExtends(Token? extendsKeyword, int typeCount) {
    debugEvent("handleClassExtends");
    while (typeCount > 1) {
      pop();
      typeCount--;
    }
    push(extendsKeyword?.charOffset ?? -1);
  }

  @override
  void handleMixinOn(Token? onKeyword, int typeCount) {
    debugEvent("handleMixinOn");
    push(const FixedNullableList<TypeBuilder>()
            .popNonNullable(stack, typeCount, dummyTypeBuilder) ??
        new ParserRecovery(offsetForToken(onKeyword)));
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    debugEvent("endClassDeclaration");
    List<TypeBuilder>? interfaces =
        pop(NullValue.TypeBuilderList) as List<TypeBuilder>?;
    int supertypeOffset = popCharOffset();
    TypeBuilder? supertype = nullIfParserRecovery(pop()) as TypeBuilder?;
    int modifiers = pop() as int;
    List<TypeVariableBuilder>? typeVariables =
        pop() as List<TypeVariableBuilder>?;
    int nameOffset = popCharOffset();
    Object? name = pop();
    if (typeVariables != null && supertype is MixinApplicationBuilder) {
      supertype.typeVariables = typeVariables;
    }
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    inAbstractClass = false;
    checkEmpty(beginToken.charOffset);
    if (name is ParserRecovery) {
      libraryBuilder
          .endNestedDeclaration(
              TypeParameterScopeKind.classDeclaration, "<syntax-error>")
          .resolveTypes(typeVariables, libraryBuilder);
      return;
    }

    final int startCharOffset =
        metadata == null ? beginToken.charOffset : metadata.first.charOffset;

    if (libraryBuilder.isNonNullableByDefault) {
      String classNameForErrors = "${name}";
      TypeBuilder? supertypeForErrors = supertype is MixinApplicationBuilder
          ? supertype.supertype
          : supertype;
      List<TypeBuilder>? mixins =
          supertype is MixinApplicationBuilder ? supertype.mixins : null;
      if (supertypeForErrors != null) {
        if (supertypeForErrors.nullabilityBuilder.build(libraryBuilder) ==
            Nullability.nullable) {
          libraryBuilder.addProblem(
              templateNullableSuperclassError
                  .withArguments(supertypeForErrors.fullNameForErrors),
              nameOffset,
              classNameForErrors.length,
              uri);
        }
      }
      if (mixins != null) {
        for (TypeBuilder mixin in mixins) {
          if (mixin.nullabilityBuilder.build(libraryBuilder) ==
              Nullability.nullable) {
            libraryBuilder.addProblem(
                templateNullableMixinError
                    .withArguments(mixin.fullNameForErrors),
                nameOffset,
                classNameForErrors.length,
                uri);
          }
        }
      }
      if (interfaces != null) {
        for (TypeBuilder interface in interfaces) {
          if (interface.nullabilityBuilder.build(libraryBuilder) ==
              Nullability.nullable) {
            libraryBuilder.addProblem(
                templateNullableInterfaceError
                    .withArguments(interface.fullNameForErrors),
                nameOffset,
                classNameForErrors.length,
                uri);
          }
        }
      }
    }

    libraryBuilder.addClass(
        metadata,
        modifiers,
        name as String,
        typeVariables,
        supertype,
        interfaces,
        startCharOffset,
        nameOffset,
        endToken.charOffset,
        supertypeOffset);

    libraryBuilder.setCurrentClassName(null);
  }

  Object? nullIfParserRecovery(Object? node) {
    return node is ParserRecovery ? null : node;
  }

  @override
  void endMixinDeclaration(Token mixinToken, Token endToken) {
    debugEvent("endMixinDeclaration");
    List<TypeBuilder>? interfaces =
        pop(NullValue.TypeBuilderList) as List<TypeBuilder>?;
    List<TypeBuilder>? supertypeConstraints =
        nullIfParserRecovery(pop()) as List<TypeBuilder>?;
    List<TypeVariableBuilder>? typeVariables =
        pop(NullValue.TypeVariables) as List<TypeVariableBuilder>?;
    int nameOffset = popCharOffset();
    Object? name = pop();
    List<MetadataBuilder>? metadata =
        pop(NullValue.Metadata) as List<MetadataBuilder>?;
    checkEmpty(mixinToken.charOffset);
    if (name is ParserRecovery) {
      libraryBuilder
          .endNestedDeclaration(
              TypeParameterScopeKind.mixinDeclaration, "<syntax-error>")
          .resolveTypes(typeVariables, libraryBuilder);
      return;
    }
    int startOffset =
        metadata == null ? mixinToken.charOffset : metadata.first.charOffset;
    TypeBuilder? supertype;
    if (supertypeConstraints != null && supertypeConstraints.isNotEmpty) {
      if (supertypeConstraints.length == 1) {
        supertype = supertypeConstraints.first;
      } else {
        supertype = new MixinApplicationBuilder(
            supertypeConstraints.first,
            supertypeConstraints.skip(1).toList(),
            supertypeConstraints.first.fileUri!,
            supertypeConstraints.first.charOffset!);
      }
    }

    if (libraryBuilder.isNonNullableByDefault) {
      String classNameForErrors = "${name}";
      if (supertypeConstraints != null) {
        for (TypeBuilder supertype in supertypeConstraints) {
          if (supertype.nullabilityBuilder.build(libraryBuilder) ==
              Nullability.nullable) {
            libraryBuilder.addProblem(
                templateNullableSuperclassError
                    .withArguments(supertype.fullNameForErrors),
                nameOffset,
                classNameForErrors.length,
                uri);
          }
        }
      }
      if (interfaces != null) {
        for (TypeBuilder interface in interfaces) {
          if (interface.nullabilityBuilder.build(libraryBuilder) ==
              Nullability.nullable) {
            libraryBuilder.addProblem(
                templateNullableInterfaceError
                    .withArguments(interface.fullNameForErrors),
                nameOffset,
                classNameForErrors.length,
                uri);
          }
        }
      }
    }

    libraryBuilder.addMixinDeclaration(
        metadata,
        mixinDeclarationMask,
        name as String,
        typeVariables,
        supertype,
        interfaces,
        startOffset,
        nameOffset,
        endToken.charOffset,
        -1);
    libraryBuilder.setCurrentClassName(null);
  }

  @override
  void beginExtensionDeclarationPrelude(Token extensionKeyword) {
    assert(checkState(extensionKeyword, [ValueKinds.MetadataListOrNull]));
    debugEvent("beginExtensionDeclaration");
    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.extensionDeclaration, "extension");
  }

  @override
  void beginExtensionDeclaration(Token extensionKeyword, Token? nameToken) {
    assert(checkState(extensionKeyword,
        [ValueKinds.TypeVariableListOrNull, ValueKinds.MetadataListOrNull]));
    debugEvent("beginExtensionDeclaration");
    List<TypeVariableBuilder>? typeVariables =
        pop() as List<TypeVariableBuilder>?;
    int offset = nameToken?.charOffset ?? extensionKeyword.charOffset;
    String name = nameToken?.lexeme ??
        // Synthesized name used internally.
        '_extension#${unnamedExtensionCounter++}';
    push(name);
    push(offset);
    push(typeVariables ?? NullValue.TypeVariables);
    libraryBuilder.currentTypeParameterScopeBuilder
        .markAsExtensionDeclaration(name, offset, typeVariables);
  }

  @override
  void endExtensionDeclaration(Token extensionKeyword, Token? typeKeyword,
      Token onKeyword, Token endToken) {
    assert(checkState(extensionKeyword, [
      unionOfKinds([ValueKinds.ParserRecovery, ValueKinds.TypeBuilder]),
      ValueKinds.TypeVariableListOrNull,
      ValueKinds.Integer,
      ValueKinds.NameOrNull,
      ValueKinds.MetadataListOrNull
    ]));
    debugEvent("endExtensionDeclaration");
    Object? onType = pop();
    if (onType is ParserRecovery) {
      ParserRecovery parserRecovery = onType;
      onType = new FixedTypeBuilder(
          const InvalidType(), uri, parserRecovery.charOffset);
    }
    List<TypeVariableBuilder>? typeVariables =
        pop(NullValue.TypeVariables) as List<TypeVariableBuilder>?;
    int nameOffset = popCharOffset();
    String? name = pop(NullValue.Name) as String?;
    if (name == null) {
      nameOffset = extensionKeyword.charOffset;
      name = '$nameOffset';
    }
    List<MetadataBuilder>? metadata =
        pop(NullValue.Metadata) as List<MetadataBuilder>?;
    checkEmpty(extensionKeyword.charOffset);
    int startOffset = metadata == null
        ? extensionKeyword.charOffset
        : metadata.first.charOffset;
    bool isExtensionTypeDeclaration = typeKeyword != null;
    if (!libraryBuilder.enableExtensionTypesInLibrary &&
        isExtensionTypeDeclaration) {
      addProblem(
          templateExperimentNotEnabled.withArguments('extension-types',
              libraryBuilder.enableExtensionTypesVersionInLibrary.toText()),
          extensionKeyword.next!.charOffset,
          extensionKeyword.next!.length);
    }
    libraryBuilder.addExtensionDeclaration(
        metadata,
        // TODO(johnniwinther): Support modifiers on extensions?
        0,
        name,
        typeVariables,
        onType as TypeBuilder,
        isExtensionTypeDeclaration,
        startOffset,
        nameOffset,
        endToken.charOffset);
  }

  ProcedureKind computeProcedureKind(Token? token) {
    if (token == null) return ProcedureKind.Method;
    if (optional("get", token)) return ProcedureKind.Getter;
    if (optional("set", token)) return ProcedureKind.Setter;
    return unhandled(
        token.lexeme, "computeProcedureKind", token.charOffset, uri);
  }

  @override
  void beginTopLevelMethod(Token lastConsumed, Token? externalToken) {
    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.topLevelMethod, "#method",
        hasMembers: false);
    push(externalToken != null ? externalMask : 0);
  }

  @override
  void endTopLevelMethod(Token beginToken, Token? getOrSet, Token endToken) {
    debugEvent("endTopLevelMethod");
    MethodBody kind = pop() as MethodBody;
    AsyncMarker asyncModifier = pop() as AsyncMarker;
    List<FormalParameterBuilder>? formals =
        pop() as List<FormalParameterBuilder>?;
    int formalsOffset = popCharOffset();
    List<TypeVariableBuilder>? typeVariables =
        pop() as List<TypeVariableBuilder>?;
    int charOffset = popCharOffset();
    Object? name = pop();
    TypeBuilder? returnType = pop() as TypeBuilder?;
    bool isAbstract = kind == MethodBody.Abstract;
    if (getOrSet != null && optional("set", getOrSet)) {
      if (formals == null || formals.length != 1) {
        // This isn't abstract as we'll add an error-recovery node in
        // [BodyBuilder.finishFunction].
        isAbstract = false;
      }
      if (returnType != null && !returnType.isVoidType) {
        addProblem(messageNonVoidReturnSetter, beginToken.charOffset, noLength);
        // Use implicit void as recovery.
        returnType = null;
      }
    }
    int modifiers = pop() as int;
    modifiers = Modifier.addAbstractMask(modifiers, isAbstract: isAbstract);
    if (nativeMethodName != null) {
      modifiers |= externalMask;
    }
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    checkEmpty(beginToken.charOffset);
    libraryBuilder
        .endNestedDeclaration(TypeParameterScopeKind.topLevelMethod, "#method")
        .resolveTypes(typeVariables, libraryBuilder);
    if (name is ParserRecovery) return;
    final int startCharOffset =
        metadata == null ? beginToken.charOffset : metadata.first.charOffset;
    libraryBuilder.addProcedure(
        metadata,
        modifiers,
        returnType,
        name as String,
        typeVariables,
        formals,
        computeProcedureKind(getOrSet),
        startCharOffset,
        charOffset,
        formalsOffset,
        endToken.charOffset,
        nativeMethodName,
        asyncModifier,
        isInstanceMember: false,
        isExtensionMember: false);
    nativeMethodName = null;
  }

  @override
  void handleNativeFunctionBody(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBody");
    if (nativeMethodName != null) {
      push(MethodBody.Regular);
    } else {
      push(MethodBody.Abstract);
    }
  }

  @override
  void handleNativeFunctionBodyIgnored(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBodyIgnored");
  }

  @override
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    if (!enableNative) {
      super.handleRecoverableError(
          messageExpectedBlockToSkip, nativeToken, nativeToken);
    }
    push(MethodBody.Regular);
  }

  @override
  void handleNoFunctionBody(Token token) {
    debugEvent("NoFunctionBody");
    if (nativeMethodName != null) {
      push(MethodBody.Regular);
    } else {
      push(MethodBody.Abstract);
    }
  }

  @override
  void handleFunctionBodySkipped(Token token, bool isExpressionBody) {
    debugEvent("handleFunctionBodySkipped");
    push(MethodBody.Regular);
  }

  @override
  void beginMethod(
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? varFinalOrConst,
      Token? getOrSet,
      Token name) {
    inConstructor =
        name.lexeme == libraryBuilder.currentTypeParameterScopeBuilder.name &&
            getOrSet == null;
    List<Modifier>? modifiers;
    if (externalToken != null) {
      modifiers ??= <Modifier>[];
      modifiers.add(External);
    }
    if (staticToken != null) {
      if (!inConstructor) {
        modifiers ??= <Modifier>[];
        modifiers.add(Static);
      }
    }
    if (covariantToken != null) {
      modifiers ??= <Modifier>[];
      modifiers.add(Covariant);
    }
    if (varFinalOrConst != null) {
      String lexeme = varFinalOrConst.lexeme;
      if (identical('var', lexeme)) {
        modifiers ??= <Modifier>[];
        modifiers.add(Var);
      } else if (identical('final', lexeme)) {
        modifiers ??= <Modifier>[];
        modifiers.add(Final);
      } else {
        modifiers ??= <Modifier>[];
        modifiers.add(Const);
      }
    }
    push(varFinalOrConst?.charOffset ?? -1);
    push(modifiers ?? NullValue.Modifiers);
    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.staticOrInstanceMethodOrConstructor, "#method",
        hasMembers: false);
  }

  @override
  void endClassMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _endClassMethod(getOrSet, beginToken, beginParam, beginInitializers,
        endToken, _MethodKind.classMethod);
  }

  void endClassConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _endClassMethod(getOrSet, beginToken, beginParam, beginInitializers,
        endToken, _MethodKind.classConstructor);
  }

  void endMixinMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _endClassMethod(getOrSet, beginToken, beginParam, beginInitializers,
        endToken, _MethodKind.mixinMethod);
  }

  void endExtensionMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _endClassMethod(getOrSet, beginToken, beginParam, beginInitializers,
        endToken, _MethodKind.extensionMethod);
  }

  void endMixinConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _endClassMethod(getOrSet, beginToken, beginParam, beginInitializers,
        endToken, _MethodKind.mixinConstructor);
  }

  void endExtensionConstructor(Token? getOrSet, Token beginToken,
      Token beginParam, Token? beginInitializers, Token endToken) {
    _endClassMethod(getOrSet, beginToken, beginParam, beginInitializers,
        endToken, _MethodKind.extensionConstructor);
  }

  void _endClassMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken, _MethodKind methodKind) {
    assert(checkState(beginToken, [ValueKinds.MethodBody]));
    debugEvent("Method");
    MethodBody bodyKind = pop() as MethodBody;
    if (bodyKind == MethodBody.RedirectingFactoryBody) {
      // This will cause an error later.
      pop();
    }
    assert(checkState(beginToken, [
      ValueKinds.AsyncModifier,
      ValueKinds.FormalsOrNull,
      ValueKinds.Integer, // formals offset
      ValueKinds.TypeVariableListOrNull,
      ValueKinds.Integer, // name offset
      unionOfKinds([
        ValueKinds.Name,
        ValueKinds.QualifiedName,
        ValueKinds.Operator,
        ValueKinds.ParserRecovery,
      ]),
      ValueKinds.TypeBuilderOrNull,
      ValueKinds.ModifiersOrNull,
      ValueKinds.Integer, // var/final/const offset
      ValueKinds.MetadataListOrNull,
    ]));
    AsyncMarker asyncModifier = pop() as AsyncMarker;
    List<FormalParameterBuilder>? formals =
        pop() as List<FormalParameterBuilder>?;
    int formalsOffset = popCharOffset();
    List<TypeVariableBuilder>? typeVariables =
        pop() as List<TypeVariableBuilder>?;
    int charOffset = popCharOffset();
    Object? nameOrOperator = pop();
    if (Operator.subtract == nameOrOperator && formals == null) {
      nameOrOperator = Operator.unaryMinus;
    }
    Object? name;
    ProcedureKind kind;
    if (nameOrOperator is Operator) {
      name = operatorToString(nameOrOperator);
      kind = ProcedureKind.Operator;
      int requiredArgumentCount = operatorRequiredArgumentCount(nameOrOperator);
      if ((formals?.length ?? 0) != requiredArgumentCount) {
        Template<Message Function(String name)> template;
        switch (requiredArgumentCount) {
          case 0:
            template = templateOperatorParameterMismatch0;
            break;

          case 1:
            if (Operator.subtract == nameOrOperator) {
              template = templateOperatorMinusParameterMismatch;
            } else {
              template = templateOperatorParameterMismatch1;
            }
            break;

          case 2:
            template = templateOperatorParameterMismatch2;
            break;

          default:
            unhandled("$requiredArgumentCount", "operatorRequiredArgumentCount",
                charOffset, uri);
        }
        String string = name as String;
        addProblem(template.withArguments(string), charOffset, string.length);
      } else {
        if (formals != null) {
          for (FormalParameterBuilder formal in formals) {
            if (!formal.isRequired) {
              addProblem(messageOperatorWithOptionalFormals, formal.charOffset,
                  formal.name.length);
            }
          }
        }
      }
      if (typeVariables != null) {
        TypeVariableBuilder typeVariableBuilder = typeVariables.first;
        addProblem(messageOperatorWithTypeParameters,
            typeVariableBuilder.charOffset, typeVariableBuilder.name.length);
      }
    } else {
      name = nameOrOperator;
      kind = computeProcedureKind(getOrSet);
    }
    TypeBuilder? returnType = pop() as TypeBuilder?;
    bool isAbstract = bodyKind == MethodBody.Abstract;
    if (getOrSet != null && optional("set", getOrSet)) {
      if (formals == null || formals.length != 1) {
        // This isn't abstract as we'll add an error-recovery node in
        // [BodyBuilder.finishFunction].
        isAbstract = false;
      }
      if (returnType != null && !returnType.isVoidType) {
        addProblem(messageNonVoidReturnSetter,
            returnType.charOffset ?? beginToken.charOffset, noLength);
        // Use implicit void as recovery.
        returnType = null;
      }
    }
    if (nameOrOperator == Operator.indexSet &&
        returnType != null &&
        !returnType.isVoidType) {
      addProblem(messageNonVoidReturnOperator,
          returnType.charOffset ?? beginToken.offset, noLength);
      // Use implicit void as recovery.
      returnType = null;
    }
    int modifiers = Modifier.toMask(pop() as List<Modifier>?);
    modifiers = Modifier.addAbstractMask(modifiers, isAbstract: isAbstract);
    if (nativeMethodName != null) {
      modifiers |= externalMask;
    }
    bool isConst = (modifiers & constMask) != 0;
    int varFinalOrConstOffset = popCharOffset();
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;

    TypeParameterScopeBuilder declarationBuilder =
        libraryBuilder.endNestedDeclaration(
            TypeParameterScopeKind.staticOrInstanceMethodOrConstructor,
            "#method");
    if (name is ParserRecovery) {
      nativeMethodName = null;
      inConstructor = false;
      declarationBuilder.resolveTypes(typeVariables, libraryBuilder);
      return;
    }

    String? constructorName;
    switch (methodKind) {
      case _MethodKind.classConstructor:
      case _MethodKind.mixinConstructor:
      case _MethodKind.extensionConstructor:
        constructorName = libraryBuilder.computeAndValidateConstructorName(
                name, charOffset) ??
            name as String?;
        break;
      case _MethodKind.classMethod:
      case _MethodKind.mixinMethod:
      case _MethodKind.extensionMethod:
        break;
    }
    bool isStatic = (modifiers & staticMask) != 0;
    if (constructorName == null &&
        !isStatic &&
        libraryBuilder.currentTypeParameterScopeBuilder.kind ==
            TypeParameterScopeKind.extensionDeclaration) {
      TypeParameterScopeBuilder extension =
          libraryBuilder.currentTypeParameterScopeBuilder;
      Map<TypeVariableBuilder, TypeBuilder>? substitution;
      if (extension.typeVariables != null) {
        // We synthesize the names of the generated [TypeParameter]s, i.e.
        // rename 'T' to '#T'. We cannot do it on the builders because their
        // names are used to create the scope.
        List<TypeVariableBuilder> synthesizedTypeVariables = libraryBuilder
            .copyTypeVariables(extension.typeVariables!, declarationBuilder,
                isExtensionTypeParameter: true);
        substitution = {};
        for (int i = 0; i < synthesizedTypeVariables.length; i++) {
          substitution[extension.typeVariables![i]] =
              new NamedTypeBuilder.fromTypeDeclarationBuilder(
                  synthesizedTypeVariables[i],
                  const NullabilityBuilder.omitted());
        }
        if (typeVariables != null) {
          typeVariables = synthesizedTypeVariables..addAll(typeVariables);
        } else {
          typeVariables = synthesizedTypeVariables;
        }
      }
      List<FormalParameterBuilder> synthesizedFormals = [];
      TypeBuilder thisType = extension.extensionThisType;
      if (substitution != null) {
        List<TypeBuilder> unboundTypes = [];
        List<TypeVariableBuilder> unboundTypeVariables = [];
        thisType = substitute(thisType, substitution,
            unboundTypes: unboundTypes,
            unboundTypeVariables: unboundTypeVariables)!;
        for (TypeBuilder unboundType in unboundTypes) {
          extension.addType(new UnresolvedType(
              unboundType, thisType.charOffset!, thisType.fileUri!));
        }
        libraryBuilder.boundlessTypeVariables.addAll(unboundTypeVariables);
      }
      synthesizedFormals.add(new FormalParameterBuilder(
          null, finalMask, thisType, extensionThisName, null, charOffset,
          fileUri: uri, isExtensionThis: true));
      if (formals != null) {
        synthesizedFormals.addAll(formals);
      }
      formals = synthesizedFormals;
    }

    declarationBuilder.resolveTypes(typeVariables, libraryBuilder);
    if (constructorName != null) {
      if (isConst &&
          bodyKind != MethodBody.Abstract &&
          !libraryBuilder.enableConstFunctionsInLibrary) {
        addProblem(messageConstConstructorWithBody, varFinalOrConstOffset, 5);
        modifiers &= ~constMask;
      }
      if (returnType != null) {
        addProblem(messageConstructorWithReturnType,
            returnType.charOffset ?? beginToken.offset, noLength);
        returnType = null;
      }
      final int startCharOffset =
          metadata == null ? beginToken.charOffset : metadata.first.charOffset;
      libraryBuilder.addConstructor(
          metadata,
          modifiers,
          returnType,
          name,
          constructorName,
          typeVariables,
          formals,
          startCharOffset,
          charOffset,
          formalsOffset,
          endToken.charOffset,
          nativeMethodName,
          beginInitializers: beginInitializers,
          forAbstractClass: inAbstractClass);
    } else {
      if (isConst) {
        // TODO(danrubel): consider removing this
        // because it is an error to have a const method.
        modifiers &= ~constMask;
      }
      final int startCharOffset =
          metadata == null ? beginToken.charOffset : metadata.first.charOffset;
      bool isExtensionMember = methodKind == _MethodKind.extensionMethod;
      libraryBuilder.addProcedure(
          metadata,
          modifiers,
          returnType,
          name as String,
          typeVariables,
          formals,
          kind,
          startCharOffset,
          charOffset,
          formalsOffset,
          endToken.charOffset,
          nativeMethodName,
          asyncModifier,
          isInstanceMember: !isStatic,
          isExtensionMember: isExtensionMember);
    }
    nativeMethodName = null;
    inConstructor = false;
  }

  @override
  void handleNamedMixinApplicationWithClause(Token withKeyword) {
    debugEvent("NamedMixinApplicationWithClause");
    Object? mixins = pop();
    Object? supertype = pop();
    if (mixins is ParserRecovery) {
      push(mixins);
    } else if (supertype is ParserRecovery) {
      push(supertype);
    } else {
      push(libraryBuilder.addMixinApplication(supertype as TypeBuilder?,
          mixins as List<TypeBuilder>, withKeyword.charOffset));
    }
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equals, Token? implementsKeyword, Token endToken) {
    debugEvent("endNamedMixinApplication");
    List<TypeBuilder>? interfaces =
        popIfNotNull(implementsKeyword) as List<TypeBuilder>?;
    Object? mixinApplication = pop();
    int modifiers = pop() as int;
    List<TypeVariableBuilder>? typeVariables =
        pop() as List<TypeVariableBuilder>?;
    int charOffset = popCharOffset();
    Object? name = pop();
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    checkEmpty(beginToken.charOffset);
    if (name is ParserRecovery || mixinApplication is ParserRecovery) {
      libraryBuilder
          .endNestedDeclaration(
              TypeParameterScopeKind.namedMixinApplication, "<syntax-error>")
          .resolveTypes(typeVariables, libraryBuilder);
      return;
    }

    if (libraryBuilder.isNonNullableByDefault) {
      String classNameForErrors = "${name}";
      MixinApplicationBuilder mixinApplicationBuilder =
          mixinApplication as MixinApplicationBuilder;
      TypeBuilder? supertype = mixinApplicationBuilder.supertype;
      List<TypeBuilder> mixins = mixinApplicationBuilder.mixins;
      if (supertype != null && supertype is! MixinApplicationBuilder) {
        if (supertype.nullabilityBuilder.build(libraryBuilder) ==
            Nullability.nullable) {
          libraryBuilder.addProblem(
              templateNullableSuperclassError
                  .withArguments(supertype.fullNameForErrors),
              charOffset,
              classNameForErrors.length,
              uri);
        }
      }
      for (TypeBuilder mixin in mixins) {
        if (mixin.nullabilityBuilder.build(libraryBuilder) ==
            Nullability.nullable) {
          libraryBuilder.addProblem(
              templateNullableMixinError.withArguments(mixin.fullNameForErrors),
              charOffset,
              classNameForErrors.length,
              uri);
        }
      }
      if (interfaces != null) {
        for (TypeBuilder interface in interfaces) {
          if (interface.nullabilityBuilder.build(libraryBuilder) ==
              Nullability.nullable) {
            libraryBuilder.addProblem(
                templateNullableInterfaceError
                    .withArguments(interface.fullNameForErrors),
                charOffset,
                classNameForErrors.length,
                uri);
          }
        }
      }
    }

    int startCharOffset = beginToken.charOffset;
    int charEndOffset = endToken.charOffset;
    libraryBuilder.addNamedMixinApplication(
        metadata,
        name as String,
        typeVariables,
        modifiers,
        mixinApplication as TypeBuilder?,
        interfaces,
        startCharOffset,
        charOffset,
        charEndOffset);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    push(const FixedNullableList<TypeBuilder>()
            .popNonNullable(stack, count, dummyTypeBuilder) ??
        NullValue.TypeArguments);
  }

  @override
  void handleInvalidTypeArguments(Token token) {
    debugEvent("InvalidTypeArguments");
    pop(NullValue.TypeArguments);
  }

  @override
  void handleScript(Token token) {
    debugEvent("Script");
  }

  @override
  void handleNonNullAssertExpression(Token bang) {
    if (!libraryBuilder.isNonNullableByDefault) {
      reportNonNullAssertExpressionNotEnabled(bang);
    }
  }

  @override
  void handleType(Token beginToken, Token? questionMark) {
    debugEvent("Type");
    if (!libraryBuilder.isNonNullableByDefault) {
      reportErrorIfNullableType(questionMark);
    }
    bool isMarkedAsNullable = questionMark != null;
    List<TypeBuilder>? arguments = pop() as List<TypeBuilder>?;
    int charOffset = popCharOffset();
    Object name = pop()!;
    if (name is ParserRecovery) {
      push(name);
    } else {
      push(libraryBuilder.addNamedType(
          name,
          libraryBuilder.nullableBuilderIfTrue(isMarkedAsNullable),
          arguments,
          charOffset));
    }
  }

  @override
  void endTypeList(int count) {
    debugEvent("TypeList");
    push(const FixedNullableList<TypeBuilder>()
            .popNonNullable(stack, count, dummyTypeBuilder) ??
        new ParserRecovery(-1));
  }

  @override
  void handleNoTypeVariables(Token token) {
    super.handleNoTypeVariables(token);
    inConstructorName = false;
  }

  @override
  void handleVoidKeyword(Token token) {
    debugEvent("VoidKeyword");
    push(libraryBuilder.addVoidType(token.charOffset));
  }

  @override
  void handleVoidKeywordWithTypeArguments(Token token) {
    debugEvent("VoidKeyword");
    /*List<TypeBuilder> arguments =*/ pop();
    push(libraryBuilder.addVoidType(token.charOffset));
  }

  @override
  void beginFormalParameter(Token token, MemberKind kind, Token? requiredToken,
      Token? covariantToken, Token? varFinalOrConst) {
    if (requiredToken != null && !libraryBuilder.isNonNullableByDefault) {
      reportNonNullableModifierError(requiredToken);
    }
    push((covariantToken != null ? covariantMask : 0) |
        (requiredToken != null ? requiredMask : 0) |
        Modifier.validateVarFinalOrConst(varFinalOrConst?.lexeme));
  }

  @override
  void endFormalParameter(
      Token? thisKeyword,
      Token? periodAfterThis,
      Token nameToken,
      Token? initializerStart,
      Token? initializerEnd,
      FormalParameterKind kind,
      MemberKind memberKind) {
    debugEvent("FormalParameter");
    int charOffset = popCharOffset();
    Object? name = pop();
    TypeBuilder? type = nullIfParserRecovery(pop()) as TypeBuilder?;
    int modifiers = pop() as int;
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    if (name is ParserRecovery) {
      push(name);
    } else {
      push(libraryBuilder.addFormalParameter(
          metadata,
          modifiers,
          type,
          name == null ? FormalParameterBuilder.noNameSentinel : name as String,
          thisKeyword != null,
          charOffset,
          initializerStart));
    }
  }

  @override
  void beginFormalParameterDefaultValueExpression() {
    // Ignored for now.
  }

  @override
  void endFormalParameterDefaultValueExpression() {
    debugEvent("FormalParameterDefaultValueExpression");
    // Ignored for now.
  }

  @override
  void handleValuedFormalParameter(Token equals, Token token) {
    debugEvent("ValuedFormalParameter");
    // Ignored for now.
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    debugEvent("FormalParameterWithoutValue");
    // Ignored for now.
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    debugEvent("OptionalFormalParameters");
    FormalParameterKind kind = optional("{", beginToken)
        ? FormalParameterKind.optionalNamed
        : FormalParameterKind.optionalPositional;
    // When recovering from an empty list of optional arguments, count may be
    // 0. It might be simpler if the parser didn't call this method in that
    // case, however, then [beginOptionalFormalParameters] wouldn't always be
    // matched by this method.
    List<FormalParameterBuilder>? parameters =
        const FixedNullableList<FormalParameterBuilder>()
            .popNonNullable(stack, count, dummyFormalParameterBuilder);
    if (parameters == null) {
      push(new ParserRecovery(offsetForToken(beginToken)));
    } else {
      for (FormalParameterBuilder parameter in parameters) {
        parameter.kind = kind;
      }
      push(parameters);
    }
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    debugEvent("FormalParameters");
    List<FormalParameterBuilder>? formals;
    if (count == 1) {
      Object? last = pop();
      if (last is List<FormalParameterBuilder>) {
        formals = last;
      } else if (last is! ParserRecovery) {
        assert(last != null);
        formals = [last as FormalParameterBuilder];
      }
    } else if (count > 1) {
      Object? last = pop();
      count--;
      if (last is ParserRecovery) {
        discard(count);
      } else if (last is List<FormalParameterBuilder>) {
        formals = const FixedNullableList<FormalParameterBuilder>()
            .popPaddedNonNullable(
                stack, count, last.length, dummyFormalParameterBuilder);
        if (formals != null) {
          formals.setRange(count, formals.length, last);
        }
      } else {
        formals = const FixedNullableList<FormalParameterBuilder>()
            .popPaddedNonNullable(stack, count, 1, dummyFormalParameterBuilder);
        if (formals != null) {
          formals[count] = last as FormalParameterBuilder;
        }
      }
    }
    if (formals != null) {
      assert(formals.isNotEmpty);
      if (formals.length == 2) {
        // The name may be null for generalized function types.
        if (formals[0].name != FormalParameterBuilder.noNameSentinel &&
            formals[0].name == formals[1].name) {
          addProblem(
              templateDuplicatedParameterName.withArguments(formals[1].name),
              formals[1].charOffset,
              formals[1].name.length,
              context: [
                templateDuplicatedParameterNameCause
                    .withArguments(formals[1].name)
                    .withLocation(
                        uri, formals[0].charOffset, formals[0].name.length)
              ]);
        }
      } else if (formals.length > 2) {
        Map<String, FormalParameterBuilder> seenNames =
            <String, FormalParameterBuilder>{};
        for (FormalParameterBuilder formal in formals) {
          if (formal.name == FormalParameterBuilder.noNameSentinel) continue;
          if (seenNames.containsKey(formal.name)) {
            addProblem(
                templateDuplicatedParameterName.withArguments(formal.name),
                formal.charOffset,
                formal.name.length,
                context: [
                  templateDuplicatedParameterNameCause
                      .withArguments(formal.name)
                      .withLocation(uri, seenNames[formal.name]!.charOffset,
                          seenNames[formal.name]!.name.length)
                ]);
          } else {
            seenNames[formal.name] = formal;
          }
        }
      }
    }
    push(beginToken.charOffset);
    push(formals ?? NullValue.FormalParameters);
  }

  @override
  void handleNoFormalParameters(Token token, MemberKind kind) {
    push(token.charOffset);
    super.handleNoFormalParameters(token, kind);
  }

  @override
  void endAssert(Token assertKeyword, Assert kind, Token leftParenthesis,
      Token? commaToken, Token semicolonToken) {
    debugEvent("Assert");
    // Do nothing
  }

  @override
  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    debugEvent("Enum");
    List<EnumConstantInfo?>? enumConstantInfos =
        const FixedNullableList<EnumConstantInfo>().pop(stack, count);
    int charOffset = popCharOffset(); // identifier char offset.
    int startCharOffset = enumKeyword.charOffset;
    Object? name = pop();
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    checkEmpty(enumKeyword.charOffset);
    if (name is ParserRecovery) return;
    libraryBuilder.addEnum(metadata, name as String, enumConstantInfos,
        startCharOffset, charOffset, leftBrace.endGroup!.charOffset);
  }

  @override
  void beginFunctionTypeAlias(Token token) {
    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.typedef, "#typedef",
        hasMembers: false);
  }

  @override
  void beginFunctionType(Token beginToken) {
    debugEvent("beginFunctionType");
    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.functionType, "#function_type",
        hasMembers: false);
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    debugEvent("beginFunctionTypedFormalParameter");
    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.functionType, "#function_type",
        hasMembers: false);
  }

  @override
  void endFunctionType(Token functionToken, Token? questionMark) {
    debugEvent("FunctionType");
    if (!libraryBuilder.isNonNullableByDefault) {
      reportErrorIfNullableType(questionMark);
    }
    List<FormalParameterBuilder>? formals =
        pop() as List<FormalParameterBuilder>?;
    pop(); // formals offset
    TypeBuilder? returnType = pop() as TypeBuilder?;
    List<TypeVariableBuilder>? typeVariables =
        pop() as List<TypeVariableBuilder>?;
    push(libraryBuilder.addFunctionType(
        returnType,
        typeVariables,
        formals,
        libraryBuilder.nullableBuilderIfTrue(questionMark != null),
        uri,
        functionToken.charOffset));
  }

  @override
  void endFunctionTypedFormalParameter(Token nameToken, Token? question) {
    debugEvent("FunctionTypedFormalParameter");
    List<FormalParameterBuilder>? formals =
        pop() as List<FormalParameterBuilder>?;
    int formalsOffset = popCharOffset();
    TypeBuilder? returnType = pop() as TypeBuilder?;
    List<TypeVariableBuilder>? typeVariables =
        pop() as List<TypeVariableBuilder>?;
    if (!libraryBuilder.isNonNullableByDefault) {
      reportErrorIfNullableType(question);
    }
    push(libraryBuilder.addFunctionType(
        returnType,
        typeVariables,
        formals,
        libraryBuilder.nullableBuilderIfTrue(question != null),
        uri,
        formalsOffset));
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token? equals, Token endToken) {
    debugEvent("endFunctionTypeAlias");
    List<TypeVariableBuilder>? typeVariables;
    Object? name;
    int charOffset;
    TypeBuilder? aliasedType;
    if (equals == null) {
      List<FormalParameterBuilder>? formals =
          pop() as List<FormalParameterBuilder>?;
      pop(); // formals offset
      typeVariables = pop() as List<TypeVariableBuilder>?;
      charOffset = popCharOffset();
      name = pop();
      TypeBuilder? returnType = pop() as TypeBuilder?;
      // Create a nested declaration that is ended below by
      // `library.addFunctionType`.
      if (name is ParserRecovery) {
        pop(); // Metadata.
        libraryBuilder
            .endNestedDeclaration(
                TypeParameterScopeKind.typedef, "<syntax-error>")
            .resolveTypes(typeVariables, libraryBuilder);
        return;
      }
      libraryBuilder.beginNestedDeclaration(
          TypeParameterScopeKind.functionType, "#function_type",
          hasMembers: false);
      // TODO(dmitryas): Make sure that RHS of typedefs can't have '?'.
      aliasedType = libraryBuilder.addFunctionType(returnType, null, formals,
          const NullabilityBuilder.omitted(), uri, charOffset);
    } else {
      Object? type = pop();
      typeVariables = pop() as List<TypeVariableBuilder>?;
      charOffset = popCharOffset();
      name = pop();
      if (name is ParserRecovery) {
        pop(); // Metadata.
        libraryBuilder
            .endNestedDeclaration(
                TypeParameterScopeKind.functionType, "<syntax-error>")
            .resolveTypes(typeVariables, libraryBuilder);
        return;
      }
      if (type is FunctionTypeBuilder &&
          !libraryBuilder.enableNonfunctionTypeAliasesInLibrary) {
        if (type.nullabilityBuilder.build(libraryBuilder) ==
                Nullability.nullable &&
            libraryBuilder.isNonNullableByDefault) {
          // The error is reported when the non-nullable experiment is enabled.
          // Otherwise, the attempt to use a nullable type will be reported
          // elsewhere.
          addProblem(
              messageTypedefNullableType, equals.charOffset, equals.length);
        } else {
          // TODO(ahe): We need to start a nested declaration when parsing the
          // formals and return type so we can correctly bind
          // `type.typeVariables`. A typedef can have type variables, and a new
          // function type can also have type variables (representing the type
          // of a generic function).
          aliasedType = type;
        }
      } else if (libraryBuilder.enableNonfunctionTypeAliasesInLibrary) {
        if (type is TypeBuilder) {
          aliasedType = type;
        } else {
          addProblem(messageTypedefNotType, equals.charOffset, equals.length);
        }
      } else {
        // TODO(ahe): Improve this error message.
        addProblem(messageTypedefNotFunction, equals.charOffset, equals.length);
      }
    }
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    checkEmpty(typedefKeyword.charOffset);
    libraryBuilder.addFunctionTypeAlias(
        metadata, name as String, typeVariables, aliasedType, charOffset);
  }

  @override
  void endTopLevelFields(
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    debugEvent("endTopLevelFields");
    if (!libraryBuilder.isNonNullableByDefault) {
      reportNonNullableModifierError(lateToken);
      if (externalToken != null) {
        handleRecoverableError(
            messageExternalField, externalToken, externalToken);
        externalToken = null;
      }
    } else {
      if (externalToken != null && lateToken != null) {
        handleRecoverableError(
            messageExternalLateField, externalToken, externalToken);
        externalToken = null;
      }
    }
    List<FieldInfo>? fieldInfos = popFieldInfos(count);
    TypeBuilder? type = nullIfParserRecovery(pop()) as TypeBuilder?;
    int modifiers = (externalToken != null ? externalMask : 0) |
        (staticToken != null ? staticMask : 0) |
        (covariantToken != null ? covariantMask : 0) |
        (lateToken != null ? lateMask : 0) |
        Modifier.validateVarFinalOrConst(varFinalOrConst?.lexeme);
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    checkEmpty(beginToken.charOffset);
    if (fieldInfos == null) return;
    libraryBuilder.addFields(
        metadata, modifiers, /* isTopLevel = */ true, type, fieldInfos);
  }

  @override
  void endClassFields(
      Token? abstractToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    debugEvent("Fields");
    if (!libraryBuilder.isNonNullableByDefault) {
      reportNonNullableModifierError(lateToken);
      if (abstractToken != null) {
        handleRecoverableError(
            messageAbstractClassMember, abstractToken, abstractToken);
        abstractToken = null;
      }
      if (externalToken != null) {
        handleRecoverableError(
            messageExternalField, externalToken, externalToken);
        externalToken = null;
      }
    } else {
      if (staticToken != null && abstractToken != null) {
        handleRecoverableError(
            messageAbstractStaticField, abstractToken, abstractToken);
        abstractToken = null;
      }
      if (abstractToken != null && lateToken != null) {
        handleRecoverableError(
            messageAbstractLateField, abstractToken, abstractToken);
        abstractToken = null;
      } else if (externalToken != null && lateToken != null) {
        handleRecoverableError(
            messageExternalLateField, externalToken, externalToken);
        externalToken = null;
      }
    }
    List<FieldInfo>? fieldInfos = popFieldInfos(count);
    TypeBuilder? type = pop() as TypeBuilder?;
    int modifiers = (abstractToken != null ? abstractMask : 0) |
        (externalToken != null ? externalMask : 0) |
        (staticToken != null ? staticMask : 0) |
        (covariantToken != null ? covariantMask : 0) |
        (lateToken != null ? lateMask : 0) |
        Modifier.validateVarFinalOrConst(varFinalOrConst?.lexeme);
    if (staticToken == null && modifiers & constMask != 0) {
      // It is a compile-time error if an instance variable is declared to be
      // constant.
      addProblem(messageConstInstanceField, varFinalOrConst!.charOffset,
          varFinalOrConst.length);
      modifiers &= ~constMask;
    }
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    if (fieldInfos == null) return;
    libraryBuilder.addFields(
        metadata, modifiers, /* isTopLevel = */ false, type, fieldInfos);
  }

  List<FieldInfo>? popFieldInfos(int count) {
    if (count == 0) return null;
    List<FieldInfo> fieldInfos =
        new List<FieldInfo>.filled(count, dummyFieldInfo);
    bool isParserRecovery = false;
    for (int i = count - 1; i != -1; i--) {
      int charEndOffset = popCharOffset();
      Token? beforeLast = pop() as Token?;
      Token? initializerTokenForInference = pop() as Token?;
      int charOffset = popCharOffset();
      Object? name = pop(NullValue.Identifier);
      if (name is ParserRecovery) {
        isParserRecovery = true;
      } else {
        fieldInfos[i] = new FieldInfo(name as String, charOffset,
            initializerTokenForInference, beforeLast, charEndOffset);
      }
    }
    return isParserRecovery ? null : fieldInfos;
  }

  @override
  void beginTypeVariable(Token token) {
    debugEvent("beginTypeVariable");
    int charOffset = popCharOffset();
    Object? name = pop();
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    if (name is ParserRecovery) {
      push(name);
    } else {
      push(libraryBuilder.addTypeVariable(
          metadata, name as String, null, charOffset, uri));
    }
  }

  @override
  void handleTypeVariablesDefined(Token token, int count) {
    debugEvent("TypeVariablesDefined");
    assert(count > 0);
    push(const FixedNullableList<TypeVariableBuilder>()
            .popNonNullable(stack, count, dummyTypeVariableBuilder) ??
        NullValue.TypeVariables);
  }

  @override
  void endTypeVariable(
      Token token, int index, Token? extendsOrSuper, Token? variance) {
    debugEvent("endTypeVariable");
    TypeBuilder? bound = nullIfParserRecovery(pop()) as TypeBuilder?;
    // Peek to leave type parameters on top of stack.
    List<TypeVariableBuilder>? typeParameters =
        peek() as List<TypeVariableBuilder>?;
    if (typeParameters != null) {
      typeParameters[index].bound = bound;
      if (variance != null) {
        if (!libraryBuilder.enableVarianceInLibrary) {
          reportVarianceModifierNotEnabled(variance);
        }
        typeParameters[index].variance = Variance.fromString(variance.lexeme);
      }
    }
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    debugEvent("endTypeVariables");

    // Peek to leave type parameters on top of stack.
    List<TypeVariableBuilder>? typeParameters =
        peek() as List<TypeVariableBuilder>?;

    Map<String, TypeVariableBuilder>? typeVariablesByName;
    if (typeParameters != null) {
      for (TypeVariableBuilder builder in typeParameters) {
        if (builder.bound != null) {
          if (typeVariablesByName == null) {
            typeVariablesByName = new Map<String, TypeVariableBuilder>();
            for (TypeVariableBuilder builder in typeParameters) {
              typeVariablesByName[builder.name] = builder;
            }
          }

          // Find cycle: If there's no cycle we can at most step through all
          // `typeParameters` (at which point the last builders bound will be
          // null).
          // If there is a cycle with `builder` 'inside' the steps to get back
          // to it will also be bound by `typeParameters.length`.
          // If there is a cycle without `builder` 'inside' we will just ignore
          // it for now. It will be reported when processing one of the
          // `builder`s that is in fact `inside` the cycle. This matches the
          // cyclic class hierarchy error.
          TypeVariableBuilder? bound = builder;
          for (int steps = 0;
              bound!.bound != null && steps < typeParameters.length;
              ++steps) {
            bound = typeVariablesByName[bound.bound!.name];
            if (bound == null || bound == builder) break;
          }
          if (bound == builder && bound!.bound != null) {
            // Write out cycle.
            List<String> via = <String>[];
            bound = typeVariablesByName[builder.bound!.name];
            while (bound != builder) {
              via.add(bound!.name);
              bound = typeVariablesByName[bound.bound!.name];
            }
            Message message = via.isEmpty
                ? templateDirectCycleInTypeVariables.withArguments(builder.name)
                : templateCycleInTypeVariables.withArguments(
                    builder.name, via.join("', '"));
            addProblem(message, builder.charOffset, builder.name.length);
            builder.bound = new NamedTypeBuilder(
                builder.name,
                const NullabilityBuilder.omitted(),
                null,
                uri,
                builder.charOffset)
              ..bind(new InvalidTypeDeclarationBuilder(
                  builder.name,
                  message.withLocation(
                      uri, builder.charOffset, builder.name.length)));
          }
        }
      }
    }

    if (inConstructorName) {
      addProblem(messageConstructorWithTypeParameters,
          offsetForToken(beginToken), lengthOfSpan(beginToken, endToken));
      inConstructorName = false;
    }
  }

  @override
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    debugEvent("endPartOf");
    int charOffset = popCharOffset();
    Object? containingLibrary = pop();
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    if (hasName) {
      libraryBuilder.addPartOf(metadata,
          flattenName(containingLibrary!, charOffset, uri), null, charOffset);
    } else {
      libraryBuilder.addPartOf(
          metadata, null, containingLibrary as String?, charOffset);
    }
  }

  @override
  void endConstructorReference(
      Token start, Token? periodBeforeName, Token endToken) {
    debugEvent("ConstructorReference");
    popIfNotNull(periodBeforeName); // charOffset.
    String? suffix = popIfNotNull(periodBeforeName) as String?;
    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;
    int charOffset = popCharOffset();
    Object name = pop()!;
    if (name is ParserRecovery) {
      push(name);
    } else {
      push(libraryBuilder.addConstructorReference(
          name, typeArguments, suffix, charOffset));
    }
  }

  @override
  void beginFactoryMethod(
      Token lastConsumed, Token? externalToken, Token? constToken) {
    inConstructor = true;
    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.factoryMethod, "#factory_method",
        hasMembers: false);
    push((externalToken != null ? externalMask : 0) |
        (constToken != null ? constMask : 0));
  }

  @override
  void endClassFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    debugEvent("ClassFactoryMethod");
    MethodBody kind = pop() as MethodBody;
    ConstructorReferenceBuilder? redirectionTarget;
    if (kind == MethodBody.RedirectingFactoryBody) {
      redirectionTarget =
          nullIfParserRecovery(pop()) as ConstructorReferenceBuilder?;
    }
    AsyncMarker asyncModifier = pop() as AsyncMarker;
    List<FormalParameterBuilder>? formals =
        pop() as List<FormalParameterBuilder>?;
    int formalsOffset = popCharOffset();
    pop(); // type variables
    int charOffset = popCharOffset();
    Object name = pop()!;
    int modifiers = pop() as int;
    if (nativeMethodName != null) {
      modifiers |= externalMask;
    }
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    if (name is ParserRecovery) {
      libraryBuilder.endNestedDeclaration(
          TypeParameterScopeKind.factoryMethod, "<syntax-error>");
      return;
    }
    libraryBuilder.addFactoryMethod(
      metadata,
      modifiers,
      name,
      formals,
      redirectionTarget,
      beginToken.charOffset,
      charOffset,
      formalsOffset,
      endToken.charOffset,
      nativeMethodName,
      asyncModifier,
    );
    nativeMethodName = null;
    inConstructor = false;
  }

  @override
  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    debugEvent("RedirectingFactoryBody");
    push(MethodBody.RedirectingFactoryBody);
  }

  @override
  void handleConstFactory(Token constKeyword) {
    debugEvent("ConstFactory");
    if (!libraryBuilder.enableConstFunctionsInLibrary) {
      handleRecoverableError(messageConstFactory, constKeyword, constKeyword);
    }
  }

  @override
  void endFieldInitializer(Token assignmentOperator, Token token) {
    debugEvent("FieldInitializer");
    Token beforeLast = assignmentOperator.next!;
    Token next = beforeLast.next!;
    while (next != token && !next.isEof) {
      // To avoid storing the rest of the token stream, we need to identify the
      // token before [token]. That token will be the last token of the
      // initializer expression and by setting its tail to EOF we only store
      // the tokens for the expression.
      // TODO(ahe): Might be clearer if this search was moved to
      // `library.addFields`.
      // TODO(ahe): I don't even think this is necessary. [token] points to ;
      // or , and we don't otherwise store tokens.
      beforeLast = next;
      next = next.next!;
    }
    push(assignmentOperator.next);
    push(beforeLast);
    push(token.charOffset);
  }

  @override
  void handleNoFieldInitializer(Token token) {
    debugEvent("NoFieldInitializer");
    push(NullValue.FieldInitializer);
    push(NullValue.FieldInitializer);
    push(token.charOffset);
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    debugEvent("Initializers");
    // Ignored for now.
  }

  @override
  void handleNoInitializers() {
    debugEvent("NoInitializers");
    // This is a constructor initializer and it's ignored for now.
  }

  @override
  void handleInvalidMember(Token endToken) {
    debugEvent("InvalidMember");
    pop(); // metadata star
  }

  @override
  void endMember() {
    debugEvent("Member");
    assert(nativeMethodName == null);
  }

  @override
  void handleClassWithClause(Token withKeyword) {
    debugEvent("ClassWithClause");

    Object? mixins = pop();
    int extendsOffset = popCharOffset();
    Object? supertype = pop();
    if (supertype is ParserRecovery || mixins is ParserRecovery) {
      push(new ParserRecovery(withKeyword.charOffset));
    } else {
      push(libraryBuilder.addMixinApplication(supertype as TypeBuilder?,
          mixins as List<TypeBuilder>, withKeyword.charOffset));
    }
    push(extendsOffset);
  }

  @override
  void handleClassNoWithClause() {
    debugEvent("ClassNoWithClause");
  }

  @override
  void handleClassHeader(Token begin, Token classKeyword, Token? nativeToken) {
    debugEvent("ClassHeader");
    nativeMethodName = null;
  }

  @override
  void handleMixinHeader(Token mixinKeyword) {
    debugEvent("handleMixinHeader");
    nativeMethodName = null;
  }

  @override
  void endClassOrMixinBody(
      DeclarationKind kind, int memberCount, Token beginToken, Token endToken) {
    debugEvent("ClassOrMixinBody");
  }

  @override
  void handleAsyncModifier(Token? asyncToken, Token? starToken) {
    debugEvent("AsyncModifier");
    push(asyncMarkerFromTokens(asyncToken, starToken));
  }

  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled: false, List<LocatedMessage>? context}) {
    libraryBuilder.addProblem(message, charOffset, length, uri,
        wasHandled: wasHandled, context: context);
  }

  @override
  bool isIgnoredError(Code<dynamic> code, Token token) {
    return isIgnoredParserError(code, token) ||
        super.isIgnoredError(code, token);
  }

  @override
  void debugEvent(String name) {
    // printEvent('OutlineBuilder: $name');
  }

  @override
  void handleNewAsIdentifier(Token token) {
    if (!libraryBuilder.enableConstructorTearOffsInLibrary) {
      addProblem(
          templateExperimentNotEnabled.withArguments(
              'constructor-tearoffs',
              libraryBuilder.enableConstructorTearOffsVersionInLibrary
                  .toText()),
          token.charOffset,
          token.length);
    }
  }
}

enum _MethodKind {
  classConstructor,
  classMethod,
  mixinConstructor,
  mixinMethod,
  extensionConstructor,
  extensionMethod,
}
