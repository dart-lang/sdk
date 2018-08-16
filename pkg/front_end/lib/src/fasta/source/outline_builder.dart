// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.outline_builder;

import 'dart:math' show min;

import 'package:kernel/ast.dart' show ProcedureKind;

import '../../scanner/token.dart' show Token;

import '../builder/builder.dart';

import '../builder/metadata_builder.dart' show ExpressionMetadataBuilder;

import '../combinator.dart' show Combinator;

import '../fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        messageConstConstructorWithBody,
        messageConstMethod,
        messageConstructorWithReturnType,
        messageConstructorWithTypeParameters,
        messageExpectedBlockToSkip,
        messageInterpolationInUri,
        messageOperatorWithOptionalFormals,
        messageStaticConstructor,
        messageTypedefNotFunction,
        templateDuplicatedParameterName,
        templateDuplicatedParameterNameCause,
        templateOperatorMinusParameterMismatch,
        templateOperatorParameterMismatch0,
        templateOperatorParameterMismatch1,
        templateOperatorParameterMismatch2;

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
        FormalParameterKind,
        IdentifierContext,
        lengthOfSpan,
        MemberKind,
        offsetForToken,
        optional;

import '../problems.dart' show unhandled;

import '../quote.dart' show unescapeString;

import 'source_library_builder.dart' show SourceLibraryBuilder;

import 'stack_listener.dart' show NullValue, StackListener;

import '../configuration.dart' show Configuration;

import '../kernel/kernel_builder.dart'
    show
        KernelFormalParameterBuilder,
        KernelNamedTypeBuilder,
        KernelTypeBuilder;

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
    List<String> list = new List<String>.filled(count, null, growable: true);
    for (int i = count - 1; i >= 0; i--) {
      popCharOffset();
      list[i] = pop();
    }
    return list;
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    debugEvent("Metadata");
    List arguments = pop();
    popIfNotNull(periodBeforeName); // charOffset.
    String postfix = popIfNotNull(periodBeforeName);
    List<TypeBuilder> typeArguments = pop();
    if (arguments == null) {
      pop(); // charOffset
      Object expression = pop();
      push(new MetadataBuilder.fromExpression(
          expression, postfix, library, beginToken.charOffset));
    } else {
      int charOffset = pop();
      Object typeName = pop();
      push(new MetadataBuilder.fromConstructor(
          library.addConstructorReference(
              typeName, typeArguments, postfix, charOffset),
          arguments,
          library,
          beginToken.charOffset));
    }
  }

  @override
  void beginMetadataStar(Token token) {
    push(token);
  }

  @override
  void endMetadataStar(int count) {
    debugEvent("MetadataStar");
    if (count == 0) {
      pop();
      push(NullValue.MetadataToken);
      push(NullValue.Metadata);
    } else {
      push(popList(
          count,
          new List<ExpressionMetadataBuilder<TypeBuilder>>.filled(count, null,
              growable: true)));
    }
  }

  @override
  void handleInvalidTopLevelDeclaration(Token endToken) {
    debugEvent("InvalidTopLevelDeclaration");
    pop(); // metadata star
    pop(); // metadataToken
  }

  @override
  void endHide(Token hideKeyword) {
    debugEvent("Hide");
    List<String> names = pop();
    push(new Combinator.hide(names, hideKeyword.charOffset, library.fileUri));
  }

  @override
  void endShow(Token showKeyword) {
    debugEvent("Show");
    List<String> names = pop();
    push(new Combinator.show(names, showKeyword.charOffset, library.fileUri));
  }

  @override
  void endCombinators(int count) {
    debugEvent("Combinators");
    push(popList(
            count, new List<Combinator>.filled(count, null, growable: true)) ??
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
    pop(); // metadataToken
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
    String prefix = pop(NullValue.Prefix);
    List<Configuration> configurations = pop();
    int uriOffset = popCharOffset();
    String uri = pop(); // For a conditional import, this is the default URI.
    List<MetadataBuilder> metadata = pop();
    pop(); // metadataToken
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
    checkEmpty(importKeyword.charOffset);
  }

  @override
  void endConditionalUris(int count) {
    debugEvent("EndConditionalUris");
    push(popList(count,
            new List<Configuration>.filled(count, null, growable: true)) ??
        NullValue.ConditionalUris);
  }

  @override
  void endConditionalUri(Token ifKeyword, Token leftParen, Token equalSign) {
    debugEvent("EndConditionalUri");
    int charOffset = popCharOffset();
    String uri = pop();
    if (equalSign != null) popCharOffset();
    String condition = popIfNotNull(equalSign) ?? "true";
    String dottedName = pop();
    push(new Configuration(charOffset, dottedName, condition, uri));
  }

  @override
  void handleDottedName(int count, Token firstIdentifier) {
    debugEvent("DottedName");
    push(popIdentifierList(count).join('.'));
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
    pop(); // metadataToken
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
      super.handleIdentifier(token, context);
      push(token.charOffset);
      var docComment = documentationCommentBefore(token);
      push(docComment?.text ?? NullValue.DocumentationComment);
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
      addCompileTimeError(messageInterpolationInUri, interpolationOffset, 1);
    }
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    debugEvent("NativeClause");
    if (hasName) {
      // Pop the native clause which in this case is a StringLiteral.
      pop(); // Char offset.
      nativeMethodName = pop(); // String.
    } else {
      nativeMethodName = '';
    }
  }

  @override
  void handleStringJuxtaposition(int literalCount) {
    debugEvent("StringJuxtaposition");
    List<String> list =
        new List<String>.filled(literalCount, null, growable: false);
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
    push(popIdentifierList(count) ?? NullValue.IdentifierList);
  }

  @override
  void handleQualified(Token period) {
    debugEvent("handleQualified");
    int suffixOffset = pop();
    String suffix = pop();
    int offset = pop();
    var prefix = pop();
    push(new QualifiedName(prefix, suffix, suffixOffset));
    push(offset);
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    debugEvent("endLibraryName");
    popCharOffset();
    Object name = pop();
    List<MetadataBuilder> metadata = pop();
    Token metadataToken = pop();
    var docComment = documentationComment(libraryKeyword, metadataToken);
    library.documentationComment = docComment?.text;
    library.name = "${name}";
    library.metadata = metadata;
  }

  @override
  void beginClassOrNamedMixinApplication(Token token) {
    debugEvent("beginClassOrNamedMixinApplication");
    library.beginNestedDeclaration("class or mixin application");
  }

  @override
  void beginClassDeclaration(Token begin, Token abstractToken, Token name) {
    debugEvent("beginNamedMixinApplication");
    List<TypeVariableBuilder> typeVariables = pop();
    push(typeVariables ?? NullValue.TypeVariables);
    library.currentDeclaration
      ..name = name.lexeme
      ..charOffset = name.charOffset
      ..typeVariables = typeVariables;
    push(abstractToken != null ? abstractMask : 0);
  }

  @override
  void beginNamedMixinApplication(
      Token begin, Token abstractToken, Token name) {
    debugEvent("beginNamedMixinApplication");
    List<TypeVariableBuilder> typeVariables = pop();
    push(typeVariables ?? NullValue.TypeVariables);
    library.currentDeclaration
      ..name = name.lexeme
      ..charOffset = name.charOffset
      ..typeVariables = typeVariables;
    push(abstractToken != null ? abstractMask : 0);
  }

  @override
  void handleClassImplements(Token implementsKeyword, int interfacesCount) {
    debugEvent("handleClassImplements");
    push(popList(
            interfacesCount,
            new List<KernelNamedTypeBuilder>.filled(interfacesCount, null,
                growable: true)) ??
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
  void handleClassExtends(Token extendsKeyword) {
    debugEvent("handleClassExtends");
    push(extendsKeyword?.charOffset ?? -1);
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    debugEvent("endClassDeclaration");
    List<TypeBuilder> interfaces = pop(NullValue.TypeBuilderList);
    int supertypeOffset = pop();
    TypeBuilder supertype = pop();
    int modifiers = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    int charOffset = pop();
    String name = pop();
    if (typeVariables != null && supertype is MixinApplicationBuilder) {
      supertype.typeVariables = typeVariables;
    }
    List<MetadataBuilder> metadata = pop();
    Token metadataToken = pop();
    var docComment = documentationComment(beginToken, metadataToken);

    final int startCharOffset =
        metadata == null ? beginToken.charOffset : metadata.first.charOffset;

    int codeStartOffset =
        _chooseCodeStartOffset(docComment, metadataToken, beginToken);
    int codeEndOffset = endToken.end;

    library.addClass(
        docComment?.text,
        metadata,
        modifiers,
        name,
        typeVariables,
        supertype,
        interfaces,
        startCharOffset,
        charOffset,
        endToken.charOffset,
        supertypeOffset,
        codeStartOffset,
        codeEndOffset);
    checkEmpty(beginToken.charOffset);
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
    library.beginNestedDeclaration("#method", hasMembers: false);
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
    String name = pop();
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
    List<MetadataBuilder> metadata = pop();
    Token metadataToken = pop();
    var docComment = documentationComment(beginToken, metadataToken);
    checkEmpty(beginToken.charOffset);
    library
        .endNestedDeclaration("#method")
        .resolveTypes(typeVariables, library);
    final int startCharOffset =
        metadata == null ? beginToken.charOffset : metadata.first.charOffset;

    int codeStartOffset =
        _chooseCodeStartOffset(docComment, metadataToken, beginToken);
    int codeEndOffset = endToken.end;

    library.addProcedure(
        docComment?.text,
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
        codeStartOffset,
        codeEndOffset,
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
      Token varFinalOrConst, Token name) {
    inConstructor = name?.lexeme == library.currentDeclaration.name;
    List<Modifier> modifiers = <Modifier>[];
    if (externalToken != null) {
      modifiers.add(External);
    }
    if (staticToken != null) {
      if (inConstructor) {
        handleRecoverableError(
            messageStaticConstructor, staticToken, staticToken);
      } else {
        modifiers.add(Static);
      }
    }
    if (covariantToken != null) {
      modifiers.add(Covariant);
    }
    if (varFinalOrConst != null) {
      String lexeme = varFinalOrConst.lexeme;
      if (identical('var', lexeme)) {
        modifiers.add(Var);
      } else if (identical('final', lexeme)) {
        modifiers.add(Final);
      } else {
        modifiers.add(Const);
      }
    }
    push(varFinalOrConst?.charOffset ?? -1);
    push(modifiers);
    library.beginNestedDeclaration("#method", hasMembers: false);
  }

  @override
  void endMethod(
      Token getOrSet, Token beginToken, Token beginParam, Token endToken) {
    debugEvent("Method");
    MethodBody bodyKind = pop();
    if (bodyKind == MethodBody.RedirectingFactoryBody) {
      // This will cause an error later.
      pop();
    }
    List<FormalParameterBuilder> formals = pop();
    int formalsOffset = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    int charOffset = pop();
    dynamic nameOrOperator = pop();
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
        var template;
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
        addCompileTimeError(
            template.withArguments(name), charOffset, string.length);
      } else {
        if (formals != null) {
          for (FormalParameterBuilder formal in formals) {
            if (!formal.isRequired) {
              addCompileTimeError(messageOperatorWithOptionalFormals,
                  formal.charOffset, formal.name.length);
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
    if ((modifiers & externalMask) != 0) {
      modifiers &= ~abstractMask;
    }
    bool isConst = (modifiers & constMask) != 0;
    int varFinalOrConstOffset = pop();
    List<MetadataBuilder> metadata = pop();
    Token metadataToken = pop();
    var docComment = documentationComment(beginToken, metadataToken);
    library
        .endNestedDeclaration("#method")
        .resolveTypes(typeVariables, library);
    String constructorName =
        kind == ProcedureKind.Getter || kind == ProcedureKind.Setter
            ? null
            : library.computeAndValidateConstructorName(name, charOffset);
    if (constructorName != null) {
      if (isConst && bodyKind != MethodBody.Abstract) {
        addCompileTimeError(
            messageConstConstructorWithBody, varFinalOrConstOffset, 5);
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
          docComment?.text,
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
          nativeMethodName);
    } else {
      if (isConst) {
        addCompileTimeError(messageConstMethod, varFinalOrConstOffset, 5);
        modifiers &= ~constMask;
      }
      final int startCharOffset =
          metadata == null ? beginToken.charOffset : metadata.first.charOffset;

      int codeStartOffset =
          _chooseCodeStartOffset(docComment, metadataToken, beginToken);
      int codeEndOffset = endToken.end;

      library.addProcedure(
          docComment?.text,
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
          codeStartOffset,
          codeEndOffset,
          isTopLevel: false);
    }
    nativeMethodName = null;
    inConstructor = false;
  }

  @override
  void endMixinApplication(Token withKeyword) {
    debugEvent("MixinApplication");
    List<TypeBuilder> mixins = pop();
    TypeBuilder supertype = pop();
    push(
        library.addMixinApplication(supertype, mixins, withKeyword.charOffset));
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equals, Token implementsKeyword, Token endToken) {
    debugEvent("endNamedMixinApplication");
    List<TypeBuilder> interfaces = popIfNotNull(implementsKeyword);
    TypeBuilder mixinApplication = pop();
    int modifiers = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    int charOffset = pop();
    String name = pop();
    List<MetadataBuilder> metadata = pop();
    Token metadataToken = pop();
    var docComment = documentationComment(beginToken, metadataToken);

    int codeStartOffset =
        _chooseCodeStartOffset(docComment, metadataToken, beginToken);
    int codeEndOffset = endToken.end;

    library.addNamedMixinApplication(
        docComment?.text,
        metadata,
        name,
        typeVariables,
        modifiers,
        mixinApplication,
        interfaces,
        charOffset,
        codeStartOffset,
        codeEndOffset);
    checkEmpty(beginToken.charOffset);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    push(popList(count,
            new List<KernelTypeBuilder>.filled(count, null, growable: true)) ??
        NullValue.TypeArguments);
  }

  @override
  void handleScript(Token token) {
    debugEvent("Script");
  }

  @override
  void handleType(Token beginToken) {
    debugEvent("Type");
    List<TypeBuilder> arguments = pop();
    int charOffset = pop();
    Object name = pop();
    push(library.addNamedType(name, arguments, charOffset));
  }

  @override
  void endTypeList(int count) {
    debugEvent("TypeList");
    push(popList(
            count,
            new List<KernelNamedTypeBuilder>.filled(count, null,
                growable: true)) ??
        NullValue.TypeList);
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
  void beginFormalParameter(Token token, MemberKind kind, Token covariantToken,
      Token varFinalOrConst) {
    push((covariantToken != null ? covariantMask : 0) |
        Modifier.validateVarFinalOrConst(varFinalOrConst?.lexeme));
  }

  @override
  void endFormalParameter(Token thisKeyword, Token periodAfterThis,
      Token nameToken, FormalParameterKind kind, MemberKind memberKind) {
    debugEvent("FormalParameter");
    int charOffset = pop();
    String name = pop();
    TypeBuilder type = pop();
    int modifiers = pop();
    List<MetadataBuilder> metadata = pop();
    pop(); // metadataToken
    push(library.addFormalParameter(
        metadata, modifiers, type, name, thisKeyword != null, charOffset));
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
    var parameters = new List<KernelFormalParameterBuilder>.filled(count, null,
        growable: true);
    popList(count, parameters);
    for (FormalParameterBuilder parameter in parameters) {
      parameter.kind = kind;
    }
    push(parameters);
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    debugEvent("FormalParameters");
    List<FormalParameterBuilder> formals;
    if (count == 1) {
      var last = pop();
      if (last is List) {
        formals = new List<FormalParameterBuilder>.from(last);
      } else {
        formals = <FormalParameterBuilder>[last];
      }
    } else if (count > 1) {
      var last = pop();
      count--;
      if (last is List<FormalParameterBuilder>) {
        formals = new List<FormalParameterBuilder>.filled(
            count + last.length, null,
            growable: true);
        formals.setRange(count, formals.length, last);
      } else {
        formals = new List<FormalParameterBuilder>.filled(count + 1, null,
            growable: true);
        formals[count] = last;
      }
      popList(count, formals);
    }
    if (formals != null) {
      if (formals.length == 2) {
        // The name may be null for generalized function types.
        if (formals[0].name != null && formals[0].name == formals[1].name) {
          addCompileTimeError(
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
            addCompileTimeError(
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
    List<Object> constantNamesAndOffsets = popList(
        count * 5, new List<Object>.filled(count * 5, null, growable: true));
    int charOffset = pop();
    String name = pop();
    List<MetadataBuilder> metadata = pop();
    Token metadataToken = pop();
    var docComment = documentationComment(enumKeyword, metadataToken);
    library.addEnum(docComment?.text, metadata, name, constantNamesAndOffsets,
        charOffset, leftBrace?.endGroup?.charOffset);
    checkEmpty(enumKeyword.charOffset);
  }

  @override
  void beginFunctionTypeAlias(Token token) {
    library.beginNestedDeclaration("#typedef", hasMembers: false);
  }

  @override
  void beginFunctionType(Token beginToken) {
    debugEvent("beginFunctionType");
    library.beginNestedDeclaration("#function_type", hasMembers: false);
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    debugEvent("beginFunctionTypedFormalParameter");
    library.beginNestedDeclaration("#function_type", hasMembers: false);
  }

  @override
  void endFunctionType(Token functionToken) {
    debugEvent("FunctionType");
    List<FormalParameterBuilder> formals = pop();
    pop(); // formals offset
    TypeBuilder returnType = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    push(library.addFunctionType(
        returnType, typeVariables, formals, functionToken.charOffset));
  }

  @override
  void endFunctionTypedFormalParameter(Token nameToken) {
    debugEvent("FunctionTypedFormalParameter");
    List<FormalParameterBuilder> formals = pop();
    int formalsOffset = pop();
    TypeBuilder returnType = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    push(library.addFunctionType(
        returnType, typeVariables, formals, formalsOffset));
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    debugEvent("endFunctionTypeAlias");
    List<TypeVariableBuilder> typeVariables;
    String name;
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
      library.beginNestedDeclaration("#function_type", hasMembers: false);
      functionType =
          library.addFunctionType(returnType, null, formals, charOffset);
    } else {
      var type = pop();
      typeVariables = pop();
      charOffset = pop();
      name = pop();
      if (type is FunctionTypeBuilder) {
        // TODO(ahe): We need to start a nested declaration when parsing the
        // formals and return type so we can correctly bind
        // `type.typeVariables`. A typedef can have type variables, and a new
        // function type can also have type variables (representing the type of
        // a generic function).
        functionType = type;
      } else {
        // TODO(ahe): Improve this error message.
        addCompileTimeError(
            messageTypedefNotFunction, equals.charOffset, equals.length);
      }
    }
    List<MetadataBuilder> metadata = pop();
    Token metadataToken = pop();
    var docComment = documentationComment(typedefKeyword, metadataToken);
    library.addFunctionTypeAlias(docComment?.text, metadata, name,
        typeVariables, functionType, charOffset);
    checkEmpty(typedefKeyword.charOffset);
  }

  @override
  void endTopLevelFields(Token staticToken, Token covariantToken,
      Token varFinalOrConst, int count, Token beginToken, Token endToken) {
    debugEvent("endTopLevelFields");
    List<Object> fieldsInfo = popList(
        count * 4, new List<Object>.filled(count * 4, null, growable: true));
    TypeBuilder type = pop();
    int modifiers = (staticToken != null ? staticMask : 0) |
        (covariantToken != null ? covariantMask : 0) |
        Modifier.validateVarFinalOrConst(varFinalOrConst?.lexeme);
    List<MetadataBuilder> metadata = pop();
    Token metadataToken = pop();
    var docComment = documentationComment(beginToken, metadataToken);
    library.addFields(docComment?.text, metadata, modifiers, type, fieldsInfo);
    checkEmpty(beginToken.charOffset);
  }

  @override
  void endFields(Token staticToken, Token covariantToken, Token varFinalOrConst,
      int count, Token beginToken, Token endToken) {
    debugEvent("Fields");
    List<Object> fieldsInfo = popList(
        count * 4, new List<Object>.filled(count * 4, null, growable: true));
    TypeBuilder type = pop();
    int modifiers = (staticToken != null ? staticMask : 0) |
        (covariantToken != null ? covariantMask : 0) |
        Modifier.validateVarFinalOrConst(varFinalOrConst?.lexeme);
    List<MetadataBuilder> metadata = pop();
    Token metadataToken = pop();
    var docComment = documentationComment(beginToken, metadataToken);
    library.addFields(docComment?.text, metadata, modifiers, type, fieldsInfo);
  }

  @override
  void beginTypeVariable(Token token) {
    debugEvent("beginTypeVariable");
    int charOffset = pop();
    String name = pop();
    // TODO(paulberry): type variable metadata should not be ignored.  See
    // dartbug.com/28981.
    /* List<MetadataBuilder> metadata = */ pop();
    pop(); // metadataToken

    push(library.addTypeVariable(name, null, charOffset));
  }

  @override
  void handleTypeVariablesDefined(Token token, int count) {
    debugEvent("TypeVariablesDefined");
    assert(count > 0);
    push(popList(count, new List<TypeVariableBuilder>(count)));
  }

  @override
  void endTypeVariable(Token token, int index, Token extendsOrSuper) {
    debugEvent("endTypeVariable");
    TypeBuilder bound = pop();
    // Peek to leave type parameters on top of stack.
    List typeParameters = peek();

    typeParameters[index].bound = bound;
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    debugEvent("endTypeVariables");

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
    Object containingLibrary = pop();
    List<MetadataBuilder> metadata = pop();
    pop(); // metadataToken
    if (hasName) {
      library.addPartOf(metadata, "$containingLibrary", null, charOffset);
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
    push(library.addConstructorReference(
        name, typeArguments, suffix, charOffset));
  }

  @override
  void beginFactoryMethod(
      Token lastConsumed, Token externalToken, Token constToken) {
    inConstructor = true;
    library.beginNestedDeclaration("#factory_method", hasMembers: false);
    push((externalToken != null ? externalMask : 0) |
        (constToken != null ? constMask : 0));
  }

  @override
  void endFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    debugEvent("FactoryMethod");
    MethodBody kind = pop();
    ConstructorReferenceBuilder redirectionTarget;
    if (kind == MethodBody.RedirectingFactoryBody) {
      redirectionTarget = pop();
    }
    List<FormalParameterBuilder> formals = pop();
    int formalsOffset = pop();
    pop(); // type variables
    int charOffset = pop();
    Object name = pop();
    int modifiers = pop();
    List<MetadataBuilder> metadata = pop();
    Token metadataToken = pop();
    var docComment = documentationComment(beginToken, metadataToken);
    library.addFactoryMethod(
        docComment?.text,
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
      beforeLast = next;
      next = next.next;
    }
    push(assignmentOperator.next);
    push(beforeLast);
  }

  @override
  void handleNoFieldInitializer(Token token) {
    debugEvent("NoFieldInitializer");
    push(NullValue.FieldInitializer);
    push(NullValue.FieldInitializer);
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
    pop(); // metadataToken
  }

  @override
  void endMember() {
    debugEvent("Member");
    assert(nativeMethodName == null);
  }

  @override
  void handleClassHeader(Token begin, Token classKeyword, Token nativeToken) {
    debugEvent("ClassHeader");
    nativeMethodName = null;
  }

  @override
  void endClassBody(int memberCount, Token beginToken, Token endToken) {
    debugEvent("ClassBody");
  }

  @override
  void handleAsyncModifier(Token asyncToken, Token starToken) {
    debugEvent("AsyncModifier");
  }

  @override
  void addCompileTimeError(Message message, int charOffset, int length,
      {List<LocatedMessage> context}) {
    library.addCompileTimeError(message, charOffset, length, uri,
        context: context);
  }

  void addProblem(Message message, int charOffset, int length,
      {List<LocatedMessage> context}) {
    library.addProblem(message, charOffset, length, uri, context: context);
  }

  static int _chooseCodeStartOffset(
      _DocumentationComment docComment, Token metadataToken, Token beginToken) {
    if (docComment != null && metadataToken != null) {
      return min(docComment.offset, metadataToken.charOffset);
    }
    if (docComment != null) {
      return docComment.offset;
    }
    if (metadataToken != null) {
      return metadataToken.charOffset;
    }
    return beginToken.offset;
  }

  /// Return the documentation comment for the [beginToken] or [metadataToken],
  /// or `null` if there is no preceding documentation comment in either of
  /// these nodes.
  static _DocumentationComment documentationComment(
      Token beginToken, Token metadataToken) {
    return documentationCommentBefore(beginToken) ??
        documentationCommentBefore(metadataToken);
  }

  /// Return the documentation comment for the entity that starts at the
  /// given [token], or `null` if there is no preceding documentation comment.
  static _DocumentationComment documentationCommentBefore(Token token) {
    Token commentToken = token?.precedingComments;
    if (commentToken == null) return null;
    bool inSlash = false;
    Token firstDocToken;
    StringBuffer buffer;
    while (commentToken != null) {
      String lexeme = commentToken.lexeme;
      if (lexeme.startsWith('/**')) {
        inSlash = false;
        firstDocToken = commentToken;
        buffer = new StringBuffer();
        buffer.write(lexeme);
      } else if (lexeme.startsWith('///')) {
        if (!inSlash || buffer == null) {
          inSlash = true;
          firstDocToken = commentToken;
          buffer = new StringBuffer();
        }
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.write(lexeme);
      }
      commentToken = commentToken.next;
    }
    if (buffer == null) return null;
    return new _DocumentationComment(
        firstDocToken.charOffset, buffer.toString());
  }

  @override
  void debugEvent(String name) {
    // printEvent('OutlineBuilder: $name');
  }
}

class _DocumentationComment {
  final int offset;
  final String text;

  _DocumentationComment(this.offset, this.text);
}
