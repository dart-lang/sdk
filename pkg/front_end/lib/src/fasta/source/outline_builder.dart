// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.outline_builder;

import 'package:kernel/ast.dart' show ProcedureKind, Variance;

import '../builder/builder.dart';

import '../combinator.dart' show Combinator;

import '../configuration.dart' show Configuration;

import '../fasta_codes.dart'
    show
        Code,
        LocatedMessage,
        Message,
        messageConstConstructorWithBody,
        messageConstInstanceField,
        messageConstructorWithReturnType,
        messageConstructorWithTypeParameters,
        messageExpectedBlockToSkip,
        messageInterpolationInUri,
        messageOperatorWithOptionalFormals,
        messageTypedefNotFunction,
        Template,
        templateCycleInTypeVariables,
        templateDirectCycleInTypeVariables,
        templateDuplicatedParameterName,
        templateDuplicatedParameterNameCause,
        templateOperatorMinusParameterMismatch,
        templateOperatorParameterMismatch0,
        templateOperatorParameterMismatch1,
        templateOperatorParameterMismatch2;

import '../ignored_parser_errors.dart' show isIgnoredParserError;

// TODO(ahe): The outline isn't supposed to import kernel-specific builders.
import '../kernel/kernel_builder.dart'
    show
        MetadataBuilder,
        MixinApplicationBuilder,
        NamedTypeBuilder,
        TypeBuilder;

import '../kernel/type_algorithms.dart';

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

import '../parser.dart'
    show
        Assert,
        DeclarationKind,
        FormalParameterKind,
        IdentifierContext,
        lengthOfSpan,
        MemberKind,
        offsetForToken,
        optional;

import '../problems.dart' show unhandled;

import '../quote.dart' show unescapeString;

import '../scanner.dart' show Token;

import 'source_library_builder.dart'
    show
        TypeParameterScopeBuilder,
        TypeParameterScopeKind,
        FieldInfo,
        SourceLibraryBuilder;

import 'stack_listener.dart'
    show FixedNullableList, NullValue, ParserRecovery, StackListener;

import 'value_kinds.dart';

enum MethodBody {
  Abstract,
  Regular,
  RedirectingFactoryBody,
}

class OutlineBuilder extends StackListener {
  final SourceLibraryBuilder library;

  final bool enableNative;
  final bool stringExpectedAfterNative;
  bool inConstructor = false;
  bool inConstructorName = false;
  int importIndex = 0;

  String nativeMethodName;

  /// Counter used for naming unnamed extension declarations.
  int unnamedExtensionCounter = 0;

  OutlineBuilder(SourceLibraryBuilder library)
      : library = library,
        enableNative =
            library.loader.target.backendTarget.enableNative(library.uri),
        stringExpectedAfterNative =
            library.loader.target.backendTarget.nativeExtensionExpectsString;

  @override
  Uri get uri => library.fileUri;

  int popCharOffset() => pop();

  List<String> popIdentifierList(int count) {
    if (count == 0) return null;
    List<String> list = new List<String>(count);
    bool isParserRecovery = false;
    for (int i = count - 1; i >= 0; i--) {
      popCharOffset();
      Object identifier = pop();
      if (identifier is ParserRecovery) {
        isParserRecovery = true;
      } else {
        list[i] = identifier;
      }
    }
    return isParserRecovery ? null : list;
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    debugEvent("Metadata");
    pop(); // arguments
    if (periodBeforeName != null) {
      pop(); // offset
      pop(); // constructor name
    }
    pop(); // type arguments
    pop(); // offset
    Object sentinel = pop(); // prefix or constructor
    push(sentinel is ParserRecovery
        ? sentinel
        : new MetadataBuilder(beginToken));
  }

  @override
  void endMetadataStar(int count) {
    debugEvent("MetadataStar");
    push(const FixedNullableList<MetadataBuilder>().pop(stack, count) ??
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
    Object names = pop();
    if (names is ParserRecovery) {
      push(names);
    } else {
      push(new Combinator.hide(names, hideKeyword.charOffset, library.fileUri));
    }
  }

  @override
  void endShow(Token showKeyword) {
    debugEvent("Show");
    Object names = pop();
    if (names is ParserRecovery) {
      push(names);
    } else {
      push(new Combinator.show(names, showKeyword.charOffset, library.fileUri));
    }
  }

  @override
  void endCombinators(int count) {
    debugEvent("Combinators");
    push(const FixedNullableList<Combinator>().pop(stack, count) ??
        NullValue.Combinators);
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    debugEvent("Export");
    List<Combinator> combinators = pop();
    List<Configuration> configurations = pop();
    int uriOffset = popCharOffset();
    String uri = pop();
    List<MetadataBuilder> metadata = pop();
    library.addExport(metadata, uri, configurations, combinators,
        exportKeyword.charOffset, uriOffset);
    checkEmpty(exportKeyword.charOffset);
  }

  @override
  void handleImportPrefix(Token deferredKeyword, Token asKeyword) {
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
  void endImport(Token importKeyword, Token semicolon) {
    debugEvent("EndImport");
    List<Combinator> combinators = pop();
    bool isDeferred = pop();
    int prefixOffset = pop();
    Object prefix = pop(NullValue.Prefix);
    List<Configuration> configurations = pop();
    int uriOffset = popCharOffset();
    String uri = pop(); // For a conditional import, this is the default URI.
    List<MetadataBuilder> metadata = pop();
    checkEmpty(importKeyword.charOffset);
    if (prefix is ParserRecovery) return;
    library.addImport(
        metadata,
        uri,
        configurations,
        prefix,
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
    push(const FixedNullableList<Configuration>().pop(stack, count) ??
        NullValue.ConditionalUris);
  }

  @override
  void endConditionalUri(Token ifKeyword, Token leftParen, Token equalSign) {
    debugEvent("EndConditionalUri");
    int charOffset = popCharOffset();
    String uri = pop();
    if (equalSign != null) popCharOffset();
    String condition = popIfNotNull(equalSign) ?? "true";
    Object dottedName = pop();
    if (dottedName is ParserRecovery) {
      push(dottedName);
    } else {
      push(new Configuration(charOffset, dottedName, condition, uri));
    }
  }

  @override
  void handleDottedName(int count, Token firstIdentifier) {
    debugEvent("DottedName");
    List<String> names = popIdentifierList(count);
    if (names == null) {
      push(new ParserRecovery(firstIdentifier.charOffset));
    } else {
      push(names.join('.'));
    }
  }

  @override
  void handleRecoverImport(Token semicolon) {
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
    String uri = pop();
    List<MetadataBuilder> metadata = pop();
    library.addPart(metadata, uri, charOffset);
    checkEmpty(partKeyword.charOffset);
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    debugEvent("OperatorName");
    push(operatorFromString(token.stringValue));
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
      List<MetadataBuilder> metadata = pop();
      if (token.isSynthetic) {
        push(new ParserRecovery(token.charOffset));
      } else {
        push(new EnumConstantInfo(metadata, token.lexeme, token.charOffset,
            getDocumentationComment(token)));
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
      Token token = pop();
      push(unescapeString(token.lexeme, token, this));
      push(token.charOffset);
    } else {
      Token beginToken = pop();
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
      Object name = pop();
      if (name is ParserRecovery) {
        nativeMethodName = '';
      } else {
        nativeMethodName = name; // String.
      }
    } else {
      nativeMethodName = '';
    }
  }

  @override
  void handleStringJuxtaposition(int literalCount) {
    debugEvent("StringJuxtaposition");
    List<String> list = new List<String>(literalCount);
    int charOffset = -1;
    for (int i = literalCount - 1; i >= 0; i--) {
      charOffset = pop();
      list[i] = pop();
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
      /*suffix offset*/ ValueKind.Integer,
      /*suffix*/ ValueKind.NameOrParserRecovery,
      /*prefix offset*/ ValueKind.Integer,
      /*prefix*/ unionOfKinds(
          [ValueKind.Name, ValueKind.ParserRecovery, ValueKind.QualifiedName]),
    ]));
    debugEvent("handleQualified");
    int suffixOffset = pop();
    Object suffix = pop();
    int offset = pop();
    Object prefix = pop();
    if (prefix is ParserRecovery) {
      push(prefix);
    } else if (suffix is ParserRecovery) {
      push(suffix);
    } else {
      assert(identical(suffix, period.next.lexeme));
      assert(suffixOffset == period.next.charOffset);
      push(new QualifiedName(prefix, period.next));
    }
    push(offset);
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    debugEvent("endLibraryName");
    popCharOffset();
    String documentationComment = getDocumentationComment(libraryKeyword);
    Object name = pop();
    List<MetadataBuilder> metadata = pop();
    library.documentationComment = documentationComment;
    if (name is! ParserRecovery) {
      library.name = flattenName(name, offsetForToken(libraryKeyword), uri);
    }
    library.metadata = metadata;
  }

  @override
  void beginClassOrNamedMixinApplicationPrelude(Token token) {
    debugEvent("beginClassOrNamedMixinApplication");
    library.beginNestedDeclaration(
        TypeParameterScopeKind.classOrNamedMixinApplication,
        "class or mixin application");
  }

  @override
  void beginClassDeclaration(Token begin, Token abstractToken, Token name) {
    debugEvent("beginClassDeclaration");
    List<TypeVariableBuilder> typeVariables = pop();
    push(typeVariables ?? NullValue.TypeVariables);
    library.currentTypeParameterScopeBuilder
        .markAsClassDeclaration(name.lexeme, name.charOffset, typeVariables);
    push(abstractToken != null ? abstractMask : 0);
  }

  @override
  void beginMixinDeclaration(Token mixinKeyword, Token name) {
    debugEvent("beginMixinDeclaration");
    List<TypeVariableBuilder> typeVariables = pop();
    push(typeVariables ?? NullValue.TypeVariables);
    library.currentTypeParameterScopeBuilder
        .markAsMixinDeclaration(name.lexeme, name.charOffset, typeVariables);
  }

  @override
  void beginClassOrMixinBody(DeclarationKind kind, Token token) {
    if (kind == DeclarationKind.Extension) {
      assert(checkState(token, [
        unionOfKinds([ValueKind.ParserRecovery, ValueKind.TypeBuilder])
      ]));
      Object extensionThisType = peek();
      if (extensionThisType is TypeBuilder) {
        library.currentTypeParameterScopeBuilder
            .registerExtensionThisType(extensionThisType);
      } else {
        // TODO(johnniwinther): Supply an invalid type as the extension on type.
      }
    }
    debugEvent("beginClassOrMixinBody");
    // Resolve unresolved types from the class header (i.e., superclass, mixins,
    // and implemented types) before adding members from the class body which
    // should not shadow these unresolved types.
    library.currentTypeParameterScopeBuilder.resolveTypes(
        library.currentTypeParameterScopeBuilder.typeVariables, library);
  }

  @override
  void beginNamedMixinApplication(
      Token begin, Token abstractToken, Token name) {
    debugEvent("beginNamedMixinApplication");
    List<TypeVariableBuilder> typeVariables = pop();
    push(typeVariables ?? NullValue.TypeVariables);
    library.currentTypeParameterScopeBuilder.markAsNamedMixinApplication(
        name.lexeme, name.charOffset, typeVariables);
    push(abstractToken != null ? abstractMask : 0);
  }

  @override
  void handleClassOrMixinImplements(
      Token implementsKeyword, int interfacesCount) {
    debugEvent("ClassOrMixinImplements");
    push(const FixedNullableList<NamedTypeBuilder>()
            .pop(stack, interfacesCount) ??
        NullValue.TypeBuilderList);
  }

  @override
  void handleRecoverClassHeader() {
    debugEvent("handleRecoverClassHeader");
    pop(NullValue.TypeBuilderList); // Interfaces.
    pop(); // Supertype offset.
    pop(); // Supertype.
  }

  @override
  void handleRecoverMixinHeader() {
    debugEvent("handleRecoverMixinHeader");
    pop(NullValue.TypeBuilderList); // Interfaces.
    pop(NullValue.TypeBuilderList); // Supertype constraints.
  }

  @override
  void handleClassExtends(Token extendsKeyword) {
    debugEvent("handleClassExtends");
    push(extendsKeyword?.charOffset ?? -1);
  }

  @override
  void handleMixinOn(Token onKeyword, int typeCount) {
    debugEvent("handleMixinOn");
    push(const FixedNullableList<NamedTypeBuilder>().pop(stack, typeCount) ??
        new ParserRecovery(offsetForToken(onKeyword)));
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    debugEvent("endClassDeclaration");
    String documentationComment = getDocumentationComment(beginToken);
    List<TypeBuilder> interfaces = pop(NullValue.TypeBuilderList);
    int supertypeOffset = pop();
    TypeBuilder supertype = nullIfParserRecovery(pop());
    int modifiers = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    int nameOffset = pop();
    Object name = pop();
    if (typeVariables != null && supertype is MixinApplicationBuilder) {
      supertype.typeVariables = typeVariables;
    }
    List<MetadataBuilder> metadata = pop();
    checkEmpty(beginToken.charOffset);
    if (name is ParserRecovery) {
      library.endNestedDeclaration(
          TypeParameterScopeKind.classDeclaration, "<syntax-error>");
      return;
    }

    final int startCharOffset =
        metadata == null ? beginToken.charOffset : metadata.first.charOffset;

    library.addClass(
        documentationComment,
        metadata,
        modifiers,
        name,
        typeVariables,
        supertype,
        interfaces,
        startCharOffset,
        nameOffset,
        endToken.charOffset,
        supertypeOffset);
  }

  Object nullIfParserRecovery(Object node) {
    return node is ParserRecovery ? null : node;
  }

  @override
  void endMixinDeclaration(Token mixinToken, Token endToken) {
    debugEvent("endMixinDeclaration");
    String documentationComment = getDocumentationComment(mixinToken);
    List<TypeBuilder> interfaces = pop(NullValue.TypeBuilderList);
    List<TypeBuilder> supertypeConstraints = nullIfParserRecovery(pop());
    List<TypeVariableBuilder> typeVariables = pop(NullValue.TypeVariables);
    int nameOffset = pop();
    Object name = pop();
    List<MetadataBuilder> metadata = pop(NullValue.Metadata);
    checkEmpty(mixinToken.charOffset);
    if (name is ParserRecovery) {
      library.endNestedDeclaration(
          TypeParameterScopeKind.mixinDeclaration, "<syntax-error>");
      return;
    }
    int startOffset =
        metadata == null ? mixinToken.charOffset : metadata.first.charOffset;
    TypeBuilder supertype;
    if (supertypeConstraints != null && supertypeConstraints.isNotEmpty) {
      if (supertypeConstraints.length == 1) {
        supertype = supertypeConstraints.first;
      } else {
        supertype = new MixinApplicationBuilder(
            supertypeConstraints.first, supertypeConstraints.skip(1).toList());
      }
    }
    library.addMixinDeclaration(
        documentationComment,
        metadata,
        mixinDeclarationMask,
        name,
        typeVariables,
        supertype,
        interfaces,
        startOffset,
        nameOffset,
        endToken.charOffset,
        -1);
  }

  @override
  void beginExtensionDeclarationPrelude(Token extensionKeyword) {
    assert(checkState(extensionKeyword, [ValueKind.MetadataListOrNull]));
    debugEvent("beginExtensionDeclaration");
    library.beginNestedDeclaration(
        TypeParameterScopeKind.extensionDeclaration, "extension");
  }

  @override
  void beginExtensionDeclaration(Token extensionKeyword, Token nameToken) {
    assert(checkState(extensionKeyword,
        [ValueKind.TypeVariableListOrNull, ValueKind.MetadataListOrNull]));
    debugEvent("beginExtensionDeclaration");
    List<TypeVariableBuilder> typeVariables = pop();
    int offset = nameToken?.charOffset ?? extensionKeyword.charOffset;
    String name = nameToken?.lexeme ??
        // Synthesized name used internally.
        '_extension#${unnamedExtensionCounter++}';
    push(name);
    push(offset);
    push(typeVariables ?? NullValue.TypeVariables);
    library.currentTypeParameterScopeBuilder
        .markAsExtensionDeclaration(name, offset, typeVariables);
  }

  @override
  void endExtensionDeclaration(
      Token extensionKeyword, Token onKeyword, Token endToken) {
    assert(checkState(extensionKeyword, [
      unionOfKinds([ValueKind.ParserRecovery, ValueKind.TypeBuilder]),
      ValueKind.TypeVariableListOrNull,
      ValueKind.Integer,
      ValueKind.NameOrNull,
      ValueKind.MetadataListOrNull
    ]));
    debugEvent("endExtensionDeclaration");
    String documentationComment = getDocumentationComment(extensionKeyword);
    TypeBuilder supertype = pop();
    List<TypeVariableBuilder> typeVariables = pop(NullValue.TypeVariables);
    int nameOffset = pop();
    String name = pop(NullValue.Name);
    if (name == null) {
      nameOffset = extensionKeyword.charOffset;
      name = '$nameOffset';
    }
    List<MetadataBuilder> metadata = pop(NullValue.Metadata);
    checkEmpty(extensionKeyword.charOffset);
    int startOffset = metadata == null
        ? extensionKeyword.charOffset
        : metadata.first.charOffset;
    library.addExtensionDeclaration(
        documentationComment,
        metadata,
        // TODO(johnniwinther): Support modifiers on extensions?
        0,
        name,
        typeVariables,
        supertype,
        startOffset,
        nameOffset,
        endToken.charOffset);
  }

  ProcedureKind computeProcedureKind(Token token) {
    if (token == null) return ProcedureKind.Method;
    if (optional("get", token)) return ProcedureKind.Getter;
    if (optional("set", token)) return ProcedureKind.Setter;
    return unhandled(
        token.lexeme, "computeProcedureKind", token.charOffset, uri);
  }

  @override
  void beginTopLevelMethod(Token lastConsumed, Token externalToken) {
    library.beginNestedDeclaration(
        TypeParameterScopeKind.topLevelMethod, "#method",
        hasMembers: false);
    push(externalToken != null ? externalMask : 0);
  }

  @override
  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    debugEvent("endTopLevelMethod");
    MethodBody kind = pop();
    List<FormalParameterBuilder> formals = pop();
    int formalsOffset = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    int charOffset = pop();
    Object name = pop();
    TypeBuilder returnType = pop();
    bool isAbstract = kind == MethodBody.Abstract;
    if (getOrSet != null && optional("set", getOrSet)) {
      if (formals == null || formals.length != 1) {
        // This isn't abstract as we'll add an error-recovery node in
        // [BodyBuilder.finishFunction].
        isAbstract = false;
      }
    }
    int modifiers = pop();
    if (isAbstract) {
      modifiers |= abstractMask;
    }
    if (nativeMethodName != null) {
      modifiers |= externalMask;
    }
    List<MetadataBuilder> metadata = pop();
    checkEmpty(beginToken.charOffset);
    library
        .endNestedDeclaration(TypeParameterScopeKind.topLevelMethod, "#method")
        .resolveTypes(typeVariables, library);
    if (name is ParserRecovery) return;
    final int startCharOffset =
        metadata == null ? beginToken.charOffset : metadata.first.charOffset;
    String documentationComment = getDocumentationComment(beginToken);
    library.addProcedure(
        documentationComment,
        metadata,
        modifiers,
        returnType,
        name,
        typeVariables,
        formals,
        computeProcedureKind(getOrSet),
        startCharOffset,
        charOffset,
        formalsOffset,
        endToken.charOffset,
        nativeMethodName,
        isTopLevel: true);
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
  void beginMethod(Token externalToken, Token staticToken, Token covariantToken,
      Token varFinalOrConst, Token getOrSet, Token name) {
    inConstructor =
        name?.lexeme == library.currentTypeParameterScopeBuilder.name &&
            getOrSet == null;
    List<Modifier> modifiers;
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
    library.beginNestedDeclaration(
        TypeParameterScopeKind.staticOrInstanceMethodOrConstructor, "#method",
        hasMembers: false);
  }

  @override
  void endClassMethod(Token getOrSet, Token beginToken, Token beginParam,
      Token beginInitializers, Token endToken) {
    assert(checkState(beginToken, [ValueKind.MethodBody]));
    debugEvent("Method");
    MethodBody bodyKind = pop();
    if (bodyKind == MethodBody.RedirectingFactoryBody) {
      // This will cause an error later.
      pop();
    }
    assert(checkState(beginToken, [
      ValueKind.FormalsOrNull,
      ValueKind.Integer, // formals offset
      ValueKind.TypeVariableListOrNull,
      ValueKind.Integer, // name offset
      unionOfKinds([
        ValueKind.Name,
        ValueKind.QualifiedName,
        ValueKind.Operator,
        ValueKind.ParserRecovery,
      ]),
      ValueKind.TypeBuilderOrNull,
      ValueKind.ModifiersOrNull,
      ValueKind.Integer, // var/final/const offset
      ValueKind.MetadataListOrNull,
    ]));
    List<FormalParameterBuilder> formals = pop();
    int formalsOffset = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    int charOffset = pop();
    Object nameOrOperator = pop();
    if (Operator.subtract == nameOrOperator && formals == null) {
      nameOrOperator = Operator.unaryMinus;
    }
    Object name;
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
        String string = name;
        addProblem(template.withArguments(name), charOffset, string.length);
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
    } else {
      name = nameOrOperator;
      kind = computeProcedureKind(getOrSet);
    }
    TypeBuilder returnType = pop();
    bool isAbstract = bodyKind == MethodBody.Abstract;
    if (getOrSet != null && optional("set", getOrSet)) {
      if (formals == null || formals.length != 1) {
        // This isn't abstract as we'll add an error-recovery node in
        // [BodyBuilder.finishFunction].
        isAbstract = false;
      }
    }
    int modifiers = Modifier.validate(pop(), isAbstract: isAbstract);
    if (nativeMethodName != null) {
      modifiers |= externalMask;
    }
    if ((modifiers & externalMask) != 0) {
      modifiers &= ~abstractMask;
    }
    bool isConst = (modifiers & constMask) != 0;
    int varFinalOrConstOffset = pop();
    List<MetadataBuilder> metadata = pop();
    String documentationComment = getDocumentationComment(beginToken);

    TypeParameterScopeBuilder declarationBuilder = library.endNestedDeclaration(
        TypeParameterScopeKind.staticOrInstanceMethodOrConstructor, "#method");
    if (name is ParserRecovery) {
      nativeMethodName = null;
      inConstructor = false;
      declarationBuilder.resolveTypes(typeVariables, library);
      return;
    }

    String constructorName =
        kind == ProcedureKind.Getter || kind == ProcedureKind.Setter
            ? null
            : library.computeAndValidateConstructorName(name, charOffset);
    if (constructorName == null &&
        (modifiers & staticMask) == 0 &&
        library.currentTypeParameterScopeBuilder.kind ==
            TypeParameterScopeKind.extensionDeclaration) {
      TypeParameterScopeBuilder extension =
          library.currentTypeParameterScopeBuilder;
      Map<TypeVariableBuilder, TypeBuilder> substitution;
      if (extension.typeVariables != null) {
        // We synthesize the names of the generated [TypeParameter]s, i.e.
        // rename 'T' to '#T'. We cannot do it on the builders because their
        // names are used to create the scope.
        List<TypeVariableBuilder> synthesizedTypeVariables = library
            .copyTypeVariables(extension.typeVariables, declarationBuilder,
                isExtensionTypeParameter: true);
        substitution = {};
        for (int i = 0; i < synthesizedTypeVariables.length; i++) {
          substitution[extension.typeVariables[i]] =
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
            unboundTypeVariables: unboundTypeVariables);
        for (TypeBuilder unboundType in unboundTypes) {
          extension.addType(new UnresolvedType(unboundType, -1, null));
        }
        library.boundlessTypeVariables.addAll(unboundTypeVariables);
      }
      synthesizedFormals.add(new FormalParameterBuilder(
          null, finalMask, thisType, "#this", null, charOffset, uri));
      if (formals != null) {
        synthesizedFormals.addAll(formals);
      }
      formals = synthesizedFormals;
    }

    declarationBuilder.resolveTypes(typeVariables, library);
    if (constructorName != null) {
      if (isConst && bodyKind != MethodBody.Abstract) {
        addProblem(messageConstConstructorWithBody, varFinalOrConstOffset, 5);
        modifiers &= ~constMask;
      }
      if (returnType != null) {
        // TODO(danrubel): Report this error on the return type
        handleRecoverableError(
            messageConstructorWithReturnType, beginToken, beginToken);
        returnType = null;
      }
      final int startCharOffset =
          metadata == null ? beginToken.charOffset : metadata.first.charOffset;
      library.addConstructor(
          documentationComment,
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
          beginInitializers: beginInitializers);
    } else {
      if (isConst) {
        // TODO(danrubel): consider removing this
        // because it is an error to have a const method.
        modifiers &= ~constMask;
      }
      final int startCharOffset =
          metadata == null ? beginToken.charOffset : metadata.first.charOffset;
      library.addProcedure(
          documentationComment,
          metadata,
          modifiers,
          returnType,
          name,
          typeVariables,
          formals,
          kind,
          startCharOffset,
          charOffset,
          formalsOffset,
          endToken.charOffset,
          nativeMethodName,
          isTopLevel: false);
    }
    nativeMethodName = null;
    inConstructor = false;
  }

  @override
  void handleNamedMixinApplicationWithClause(Token withKeyword) {
    debugEvent("NamedMixinApplicationWithClause");
    Object mixins = pop();
    Object supertype = pop();
    if (mixins is ParserRecovery) {
      push(mixins);
    } else if (supertype is ParserRecovery) {
      push(supertype);
    } else {
      push(library.addMixinApplication(
          supertype, mixins, withKeyword.charOffset));
    }
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equals, Token implementsKeyword, Token endToken) {
    debugEvent("endNamedMixinApplication");
    String documentationComment = getDocumentationComment(beginToken);
    List<TypeBuilder> interfaces = popIfNotNull(implementsKeyword);
    Object mixinApplication = pop();
    int modifiers = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    int charOffset = pop();
    Object name = pop();
    List<MetadataBuilder> metadata = pop();
    checkEmpty(beginToken.charOffset);
    if (name is ParserRecovery || mixinApplication is ParserRecovery) {
      library.endNestedDeclaration(
          TypeParameterScopeKind.namedMixinApplication, "<syntax-error>");
      return;
    }

    int startCharOffset = beginToken.charOffset;
    int charEndOffset = endToken.charOffset;
    library.addNamedMixinApplication(
        documentationComment,
        metadata,
        name,
        typeVariables,
        modifiers,
        mixinApplication,
        interfaces,
        startCharOffset,
        charOffset,
        charEndOffset);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    push(const FixedNullableList<TypeBuilder>().pop(stack, count) ??
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
    if (!library.loader.target.enableNonNullable) {
      reportNonNullAssertExpressionNotEnabled(bang);
    }
  }

  @override
  void handleType(Token beginToken, Token questionMark) {
    debugEvent("Type");
    if (!library.loader.target.enableNonNullable) {
      reportErrorIfNullableType(questionMark);
    }
    bool isMarkedAsNullable = questionMark != null;
    List<TypeBuilder> arguments = pop();
    int charOffset = pop();
    Object name = pop();
    if (name is ParserRecovery) {
      push(name);
    } else {
      push(library.addNamedType(
          name,
          library.nullableBuilderIfTrue(isMarkedAsNullable),
          arguments,
          charOffset));
    }
  }

  @override
  void endTypeList(int count) {
    debugEvent("TypeList");
    push(const FixedNullableList<NamedTypeBuilder>().pop(stack, count) ??
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
    push(library.addVoidType(token.charOffset));
  }

  @override
  void beginFormalParameter(Token token, MemberKind kind, Token requiredToken,
      Token covariantToken, Token varFinalOrConst) {
    // TODO(danrubel): handle required token
    if (!library.loader.target.enableNonNullable) {
      reportNonNullableModifierError(requiredToken);
    }
    push((covariantToken != null ? covariantMask : 0) |
        (requiredToken != null ? requiredMask : 0) |
        Modifier.validateVarFinalOrConst(varFinalOrConst?.lexeme));
  }

  @override
  void endFormalParameter(
      Token thisKeyword,
      Token periodAfterThis,
      Token nameToken,
      Token initializerStart,
      Token initializerEnd,
      FormalParameterKind kind,
      MemberKind memberKind) {
    debugEvent("FormalParameter");
    int charOffset = pop();
    Object name = pop();
    TypeBuilder type = nullIfParserRecovery(pop());
    int modifiers = pop();
    List<MetadataBuilder> metadata = pop();
    if (name is ParserRecovery) {
      push(name);
    } else {
      push(library.addFormalParameter(metadata, modifiers, type, name,
          thisKeyword != null, charOffset, initializerStart));
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
    List<FormalParameterBuilder> parameters =
        const FixedNullableList<FormalParameterBuilder>().pop(stack, count);
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
    List<FormalParameterBuilder> formals;
    if (count == 1) {
      Object last = pop();
      if (last is List<FormalParameterBuilder>) {
        formals = last;
      } else if (last is! ParserRecovery) {
        assert(last != null);
        formals = new List<FormalParameterBuilder>(1);
        formals[0] = last;
      }
    } else if (count > 1) {
      Object last = pop();
      count--;
      if (last is ParserRecovery) {
        discard(count);
      } else if (last is List<FormalParameterBuilder>) {
        formals = const FixedNullableList<FormalParameterBuilder>()
            .popPadded(stack, count, last.length);
        if (formals != null) {
          formals.setRange(count, formals.length, last);
        }
      } else {
        formals = const FixedNullableList<FormalParameterBuilder>()
            .popPadded(stack, count, 1);
        if (formals != null) {
          formals[count] = last;
        }
      }
    }
    if (formals != null) {
      assert(formals.isNotEmpty);
      if (formals.length == 2) {
        // The name may be null for generalized function types.
        if (formals[0].name != null && formals[0].name == formals[1].name) {
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
          if (formal.name == null) continue;
          if (seenNames.containsKey(formal.name)) {
            addProblem(
                templateDuplicatedParameterName.withArguments(formal.name),
                formal.charOffset,
                formal.name.length,
                context: [
                  templateDuplicatedParameterNameCause
                      .withArguments(formal.name)
                      .withLocation(uri, seenNames[formal.name].charOffset,
                          seenNames[formal.name].name.length)
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
      Token commaToken, Token semicolonToken) {
    debugEvent("Assert");
    // Do nothing
  }

  @override
  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    debugEvent("Enum");
    String documentationComment = getDocumentationComment(enumKeyword);
    List<EnumConstantInfo> enumConstantInfos =
        const FixedNullableList<EnumConstantInfo>().pop(stack, count);
    int charOffset = pop(); // identifier char offset.
    int startCharOffset = enumKeyword.charOffset;
    Object name = pop();
    List<MetadataBuilder> metadata = pop();
    checkEmpty(enumKeyword.charOffset);
    if (name is ParserRecovery) return;
    library.addEnum(documentationComment, metadata, name, enumConstantInfos,
        startCharOffset, charOffset, leftBrace?.endGroup?.charOffset);
  }

  @override
  void beginFunctionTypeAlias(Token token) {
    library.beginNestedDeclaration(TypeParameterScopeKind.typedef, "#typedef",
        hasMembers: false);
  }

  @override
  void beginFunctionType(Token beginToken) {
    debugEvent("beginFunctionType");
    library.beginNestedDeclaration(
        TypeParameterScopeKind.functionType, "#function_type",
        hasMembers: false);
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    debugEvent("beginFunctionTypedFormalParameter");
    library.beginNestedDeclaration(
        TypeParameterScopeKind.functionType, "#function_type",
        hasMembers: false);
  }

  @override
  void endFunctionType(Token functionToken, Token questionMark) {
    debugEvent("FunctionType");
    if (!library.loader.target.enableNonNullable) {
      reportErrorIfNullableType(questionMark);
    }
    List<FormalParameterBuilder> formals = pop();
    pop(); // formals offset
    TypeBuilder returnType = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    push(library.addFunctionType(
        returnType,
        typeVariables,
        formals,
        library.nullableBuilderIfTrue(questionMark != null),
        functionToken.charOffset));
  }

  @override
  void endFunctionTypedFormalParameter(Token nameToken, Token question) {
    debugEvent("FunctionTypedFormalParameter");
    List<FormalParameterBuilder> formals = pop();
    int formalsOffset = pop();
    TypeBuilder returnType = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    if (!library.loader.target.enableNonNullable) {
      reportErrorIfNullableType(question);
    }
    push(library.addFunctionType(returnType, typeVariables, formals,
        library.nullableBuilderIfTrue(question != null), formalsOffset));
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    debugEvent("endFunctionTypeAlias");
    String documentationComment = getDocumentationComment(typedefKeyword);
    List<TypeVariableBuilder> typeVariables;
    Object name;
    int charOffset;
    FunctionTypeBuilder functionType;
    if (equals == null) {
      List<FormalParameterBuilder> formals = pop();
      pop(); // formals offset
      typeVariables = pop();
      charOffset = pop();
      name = pop();
      TypeBuilder returnType = pop();
      // Create a nested declaration that is ended below by
      // `library.addFunctionType`.
      if (name is ParserRecovery) {
        pop(); // Metadata.
        library.endNestedDeclaration(
            TypeParameterScopeKind.typedef, "<syntax-error>");
        return;
      }
      library.beginNestedDeclaration(
          TypeParameterScopeKind.functionType, "#function_type",
          hasMembers: false);
      // TODO(dmitryas): Make sure that RHS of typedefs can't have '?'.
      functionType = library.addFunctionType(returnType, null, formals,
          const NullabilityBuilder.omitted(), charOffset);
    } else {
      Object type = pop();
      typeVariables = pop();
      charOffset = pop();
      name = pop();
      if (name is ParserRecovery) {
        pop(); // Metadata.
        library.endNestedDeclaration(
            TypeParameterScopeKind.functionType, "<syntax-error>");
        return;
      }
      if (type is FunctionTypeBuilder) {
        // TODO(ahe): We need to start a nested declaration when parsing the
        // formals and return type so we can correctly bind
        // `type.typeVariables`. A typedef can have type variables, and a new
        // function type can also have type variables (representing the type of
        // a generic function).
        functionType = type;
      } else {
        // TODO(ahe): Improve this error message.
        addProblem(messageTypedefNotFunction, equals.charOffset, equals.length);
      }
    }
    List<MetadataBuilder> metadata = pop();
    checkEmpty(typedefKeyword.charOffset);
    library.addFunctionTypeAlias(documentationComment, metadata, name,
        typeVariables, functionType, charOffset);
  }

  @override
  void endTopLevelFields(
      Token staticToken,
      Token covariantToken,
      Token lateToken,
      Token varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    debugEvent("endTopLevelFields");
    if (!library.loader.target.enableNonNullable) {
      reportNonNullableModifierError(lateToken);
    }
    List<FieldInfo> fieldInfos = popFieldInfos(count);
    TypeBuilder type = nullIfParserRecovery(pop());
    int modifiers = (staticToken != null ? staticMask : 0) |
        (covariantToken != null ? covariantMask : 0) |
        (lateToken != null ? lateMask : 0) |
        Modifier.validateVarFinalOrConst(varFinalOrConst?.lexeme);
    List<MetadataBuilder> metadata = pop();
    checkEmpty(beginToken.charOffset);
    if (fieldInfos == null) return;
    String documentationComment = getDocumentationComment(beginToken);
    library.addFields(
        documentationComment, metadata, modifiers, type, fieldInfos);
  }

  @override
  void endClassFields(Token staticToken, Token covariantToken, Token lateToken,
      Token varFinalOrConst, int count, Token beginToken, Token endToken) {
    debugEvent("Fields");
    if (!library.loader.target.enableNonNullable) {
      reportNonNullableModifierError(lateToken);
    }
    List<FieldInfo> fieldInfos = popFieldInfos(count);
    TypeBuilder type = pop();
    int modifiers = (staticToken != null ? staticMask : 0) |
        (covariantToken != null ? covariantMask : 0) |
        (lateToken != null ? lateMask : 0) |
        Modifier.validateVarFinalOrConst(varFinalOrConst?.lexeme);
    if (staticToken == null && modifiers & constMask != 0) {
      // It is a compile-time error if an instance variable is declared to be
      // constant.
      addProblem(messageConstInstanceField, varFinalOrConst.charOffset,
          varFinalOrConst.length);
      modifiers &= ~constMask;
    }
    List<MetadataBuilder> metadata = pop();
    if (fieldInfos == null) return;
    String documentationComment = getDocumentationComment(beginToken);
    library.addFields(
        documentationComment, metadata, modifiers, type, fieldInfos);
  }

  List<FieldInfo> popFieldInfos(int count) {
    if (count == 0) return null;
    List<FieldInfo> fieldInfos = new List<FieldInfo>(count);
    bool isParserRecovery = false;
    for (int i = count - 1; i != -1; i--) {
      int charEndOffset = pop();
      Token beforeLast = pop();
      Token initializerTokenForInference = pop();
      int charOffset = pop();
      Object name = pop(NullValue.Identifier);
      if (name is ParserRecovery) {
        isParserRecovery = true;
      } else {
        fieldInfos[i] = new FieldInfo(name, charOffset,
            initializerTokenForInference, beforeLast, charEndOffset);
      }
    }
    return isParserRecovery ? null : fieldInfos;
  }

  @override
  void beginTypeVariable(Token token) {
    debugEvent("beginTypeVariable");
    int charOffset = pop();
    Object name = pop();
    // TODO(paulberry): type variable metadata should not be ignored.  See
    // dartbug.com/28981.
    /* List<MetadataBuilder<TypeBuilder>> metadata = */ pop();
    if (name is ParserRecovery) {
      push(name);
    } else {
      push(library.addTypeVariable(name, null, charOffset));
    }
  }

  @override
  void handleTypeVariablesDefined(Token token, int count) {
    debugEvent("TypeVariablesDefined");
    assert(count > 0);
    push(const FixedNullableList<TypeVariableBuilder>().pop(stack, count) ??
        NullValue.TypeVariables);
  }

  @override
  void endTypeVariable(
      Token token, int index, Token extendsOrSuper, Token variance) {
    debugEvent("endTypeVariable");
    TypeBuilder bound = nullIfParserRecovery(pop());
    // Peek to leave type parameters on top of stack.
    List<TypeVariableBuilder> typeParameters = peek();
    if (typeParameters != null) {
      typeParameters[index].bound = bound;
      if (variance != null) {
        typeParameters[index].variance = Variance.fromString(variance.lexeme);
      }
    }
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    debugEvent("endTypeVariables");

    // Peek to leave type parameters on top of stack.
    List<TypeVariableBuilder> typeParameters = peek();

    Map<String, TypeVariableBuilder> typeVariablesByName;
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
          TypeVariableBuilder bound = builder;
          for (int steps = 0;
              bound.bound != null && steps < typeParameters.length;
              ++steps) {
            bound = typeVariablesByName[bound.bound.name];
            if (bound == null || bound == builder) break;
          }
          if (bound == builder && bound.bound != null) {
            // Write out cycle.
            List<String> via = new List<String>();
            bound = typeVariablesByName[builder.bound.name];
            while (bound != builder) {
              via.add(bound.name);
              bound = typeVariablesByName[bound.bound.name];
            }
            Message message = via.isEmpty
                ? templateDirectCycleInTypeVariables.withArguments(builder.name)
                : templateCycleInTypeVariables.withArguments(
                    builder.name, via.join("', '"));
            addProblem(message, builder.charOffset, builder.name.length);
            builder.bound = new NamedTypeBuilder(
                builder.name, const NullabilityBuilder.omitted(), null)
              ..bind(new InvalidTypeBuilder(
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
  void handleVarianceModifier(Token variance) {
    if (!library.loader.target.enableVariance) {
      reportVarianceModifierNotEnabled(variance);
    }
  }

  @override
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    debugEvent("endPartOf");
    int charOffset = popCharOffset();
    Object containingLibrary = pop();
    List<MetadataBuilder> metadata = pop();
    if (hasName) {
      library.addPartOf(metadata,
          flattenName(containingLibrary, charOffset, uri), null, charOffset);
    } else {
      library.addPartOf(metadata, null, containingLibrary, charOffset);
    }
  }

  @override
  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    debugEvent("ConstructorReference");
    popIfNotNull(periodBeforeName); // charOffset.
    String suffix = popIfNotNull(periodBeforeName);
    List<TypeBuilder> typeArguments = pop();
    int charOffset = pop();
    Object name = pop();
    if (name is ParserRecovery) {
      push(name);
    } else {
      push(library.addConstructorReference(
          name, typeArguments, suffix, charOffset));
    }
  }

  @override
  void beginFactoryMethod(
      Token lastConsumed, Token externalToken, Token constToken) {
    inConstructor = true;
    library.beginNestedDeclaration(
        TypeParameterScopeKind.factoryMethod, "#factory_method",
        hasMembers: false);
    push((externalToken != null ? externalMask : 0) |
        (constToken != null ? constMask : 0));
  }

  @override
  void endClassFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    debugEvent("ClassFactoryMethod");
    MethodBody kind = pop();
    ConstructorReferenceBuilder redirectionTarget;
    if (kind == MethodBody.RedirectingFactoryBody) {
      redirectionTarget = nullIfParserRecovery(pop());
    }
    List<FormalParameterBuilder> formals = pop();
    int formalsOffset = pop();
    pop(); // type variables
    int charOffset = pop();
    Object name = pop();
    int modifiers = pop();
    if (nativeMethodName != null) {
      modifiers |= externalMask;
    }
    List<MetadataBuilder> metadata = pop();
    if (name is ParserRecovery) {
      library.endNestedDeclaration(
          TypeParameterScopeKind.factoryMethod, "<syntax-error>");
      return;
    }
    String documentationComment = getDocumentationComment(beginToken);
    library.addFactoryMethod(
        documentationComment,
        metadata,
        modifiers,
        name,
        formals,
        redirectionTarget,
        beginToken.charOffset,
        charOffset,
        formalsOffset,
        endToken.charOffset,
        nativeMethodName);
    nativeMethodName = null;
    inConstructor = false;
  }

  @override
  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    debugEvent("RedirectingFactoryBody");
    push(MethodBody.RedirectingFactoryBody);
  }

  @override
  void endFieldInitializer(Token assignmentOperator, Token token) {
    debugEvent("FieldInitializer");
    Token beforeLast = assignmentOperator.next;
    Token next = beforeLast.next;
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
      next = next.next;
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

    Object mixins = pop();
    int extendsOffset = pop();
    Object supertype = pop();
    if (supertype is ParserRecovery || mixins is ParserRecovery) {
      push(new ParserRecovery(withKeyword.charOffset));
    } else {
      push(library.addMixinApplication(
          supertype, mixins, withKeyword.charOffset));
    }
    push(extendsOffset);
  }

  @override
  void handleClassNoWithClause() {
    debugEvent("ClassNoWithClause");
  }

  @override
  void handleClassHeader(Token begin, Token classKeyword, Token nativeToken) {
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
  void handleAsyncModifier(Token asyncToken, Token starToken) {
    debugEvent("AsyncModifier");
  }

  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled: false, List<LocatedMessage> context}) {
    library.addProblem(message, charOffset, length, uri,
        wasHandled: wasHandled, context: context);
  }

  @override
  bool isIgnoredError(Code<dynamic> code, Token token) {
    return isIgnoredParserError(code, token) ||
        super.isIgnoredError(code, token);
  }

  /// Return the documentation comment for the entity that starts at the
  /// given [token], or `null` if there is no preceding documentation comment.
  static String getDocumentationComment(Token token) {
    Token docToken = token.precedingComments;
    if (docToken == null) return null;
    bool inSlash = false;
    StringBuffer buffer = new StringBuffer();
    while (docToken != null) {
      String lexeme = docToken.lexeme;
      if (lexeme.startsWith('/**')) {
        inSlash = false;
        buffer.clear();
        buffer.write(lexeme);
      } else if (lexeme.startsWith('///')) {
        if (!inSlash) {
          inSlash = true;
          buffer.clear();
        }
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.write(lexeme);
      }
      docToken = docToken.next;
    }
    return buffer.toString();
  }

  @override
  void debugEvent(String name) {
    // printEvent('OutlineBuilder: $name');
  }
}
