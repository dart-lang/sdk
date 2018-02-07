// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.outline_builder;

import 'package:kernel/ast.dart' show ProcedureKind;

import '../../scanner/token.dart' show Token;

import '../builder/builder.dart';

import '../combinator.dart' show Combinator;

import '../fasta_codes.dart'
    show
        Message,
        messageExpectedBlockToSkip,
        messageInterpolationInUri,
        messageOperatorWithOptionalFormals,
        messageTypedefNotFunction,
        templateDuplicatedParameterName,
        templateDuplicatedParameterNameCause,
        templateOperatorMinusParameterMismatch,
        templateOperatorParameterMismatch0,
        templateOperatorParameterMismatch1,
        templateOperatorParameterMismatch2;

import '../modifier.dart' show abstractMask, externalMask, Modifier;

import '../operator.dart'
    show
        Operator,
        operatorFromString,
        operatorToString,
        operatorRequiredArgumentCount;

import '../parser.dart'
    show FormalParameterKind, IdentifierContext, MemberKind, optional;

import '../problems.dart' show unhandled;

import '../quote.dart' show unescapeString;

import 'source_library_builder.dart' show SourceLibraryBuilder;

import 'unhandled_listener.dart' show NullValue, UnhandledListener;

import '../configuration.dart' show Configuration;

enum MethodBody {
  Abstract,
  Regular,
  RedirectingFactoryBody,
}

class OutlineBuilder extends UnhandledListener {
  final SourceLibraryBuilder library;

  final bool enableNative;
  final bool stringExpectedAfterNative;

  String nativeMethodName;

  OutlineBuilder(SourceLibraryBuilder library)
      : library = library,
        enableNative =
            library.loader.target.backendTarget.enableNative(library.uri),
        stringExpectedAfterNative =
            library.loader.target.backendTarget.nativeExtensionExpectsString;

  @override
  Uri get uri => library.fileUri;

  @override
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
      int charOffset = pop();
      Object expression = pop();
      push(new MetadataBuilder.fromExpression(
          expression, postfix, library, charOffset));
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
  void endMetadataStar(int count) {
    debugEvent("MetadataStar");
    push(popList(count) ?? NullValue.Metadata);
  }

  @override
  void handleInvalidTopLevelDeclaration(Token endToken) {
    debugEvent("InvalidTopLevelDeclaration");
    pop(); // metadata star
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
    push(popList(count) ?? NullValue.Combinators);
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
    String prefix = pop(NullValue.Prefix);
    List<Configuration> configurations = pop();
    int uriOffset = popCharOffset();
    String uri = pop(); // For a conditional import, this is the default URI.
    List<MetadataBuilder> metadata = pop();
    library.addImport(metadata, uri, configurations, prefix, combinators,
        isDeferred, importKeyword.charOffset, prefixOffset, uriOffset);
    checkEmpty(importKeyword.charOffset);
  }

  @override
  void endConditionalUris(int count) {
    debugEvent("EndConditionalUris");
    push(popList(count) ?? NullValue.ConditionalUris);
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
      // Discard the metadata.
      pop();
      super.handleIdentifier(token, context);
      push(token.charOffset);
      String documentationComment = getDocumentationComment(token);
      push(documentationComment ?? NullValue.DocumentationComment);
    } else {
      super.handleIdentifier(token, context);
      push(token.charOffset);
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
      push(unescapeString(token.lexeme));
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
    String documentationComment = getDocumentationComment(libraryKeyword);
    Object name = pop();
    List<MetadataBuilder> metadata = pop();
    library.documentationComment = documentationComment;
    library.name = "${name}";
    library.metadata = metadata;
  }

  @override
  void beginClassOrNamedMixinApplication(Token token) {
    debugEvent("beginClassOrNamedMixinApplication");
    library.beginNestedDeclaration("class or mixin application");
  }

  @override
  void beginClassDeclaration(Token begin, Token name) {
    debugEvent("beginNamedMixinApplication");
    List<TypeVariableBuilder> typeVariables = pop();
    push(typeVariables ?? NullValue.TypeVariables);
    library.currentDeclaration
      ..name = name.lexeme
      ..typeVariables = typeVariables;
  }

  @override
  void beginNamedMixinApplication(Token beginToken, Token name) {
    debugEvent("beginNamedMixinApplication");
    List<TypeVariableBuilder> typeVariables = pop();
    push(typeVariables ?? NullValue.TypeVariables);
    library.currentDeclaration
      ..name = name.lexeme
      ..typeVariables = typeVariables;
  }

  @override
  void handleClassImplements(Token implementsKeyword, int interfacesCount) {
    debugEvent("handleClassImplements");
    push(popList(interfacesCount) ?? NullValue.TypeBuilderList);
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
    String documentationComment = getDocumentationComment(beginToken);
    List<TypeBuilder> interfaces = pop(NullValue.TypeBuilderList);
    int supertypeOffset = pop();
    TypeBuilder supertype = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    int charOffset = pop();
    String name = pop();
    if (typeVariables != null && supertype is MixinApplicationBuilder) {
      supertype.typeVariables = typeVariables;
    }
    int modifiers = Modifier.validate(pop());
    List<MetadataBuilder> metadata = pop();

    library.addClass(
        documentationComment,
        metadata,
        modifiers,
        name,
        typeVariables,
        supertype,
        interfaces,
        charOffset,
        endToken.charOffset,
        supertypeOffset);
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
  void beginTopLevelMethod(Token lastConsumed) {
    library.beginNestedDeclaration("#method", hasMembers: false);
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
    int modifiers = Modifier.validate(pop(), isAbstract: isAbstract);
    List<MetadataBuilder> metadata = pop();
    String documentationComment = getDocumentationComment(beginToken);
    checkEmpty(beginToken.charOffset);
    library.addProcedure(
        documentationComment,
        metadata,
        modifiers,
        returnType,
        name,
        typeVariables,
        formals,
        computeProcedureKind(getOrSet),
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
      super.handleUnrecoverableError(nativeToken, messageExpectedBlockToSkip);
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
  void beginMethod() {
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
    List<MetadataBuilder> metadata = pop();
    String documentationComment = getDocumentationComment(beginToken);
    library.addProcedure(
        documentationComment,
        metadata,
        modifiers,
        returnType,
        name,
        typeVariables,
        formals,
        kind,
        charOffset,
        formalsOffset,
        endToken.charOffset,
        nativeMethodName,
        isTopLevel: false);
    nativeMethodName = null;
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
    String documentationComment = getDocumentationComment(beginToken);
    List<TypeBuilder> interfaces = popIfNotNull(implementsKeyword);
    TypeBuilder mixinApplication = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    int charOffset = pop();
    String name = pop();
    int modifiers = Modifier.validate(pop());
    List<MetadataBuilder> metadata = pop();
    library.addNamedMixinApplication(documentationComment, metadata, name,
        typeVariables, modifiers, mixinApplication, interfaces, charOffset);
    checkEmpty(beginToken.charOffset);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    push(popList(count) ?? NullValue.TypeArguments);
  }

  @override
  void handleScript(Token token) {
    debugEvent("Script");
  }

  @override
  void handleType(Token beginToken, Token endToken) {
    debugEvent("Type");
    List<TypeBuilder> arguments = pop();
    int charOffset = pop();
    Object name = pop();
    push(library.addNamedType(name, arguments, charOffset));
  }

  @override
  void endTypeList(int count) {
    debugEvent("TypeList");
    push(popList(count) ?? NullValue.TypeList);
  }

  @override
  void endTypeVariables(int count, Token beginToken, Token endToken) {
    debugEvent("TypeVariables");
    push(popList(count) ?? NullValue.TypeVariables);
  }

  @override
  void handleVoidKeyword(Token token) {
    debugEvent("VoidKeyword");
    push(library.addVoidType(token.charOffset));
  }

  @override
  void endFormalParameter(Token thisKeyword, Token periodAfterThis,
      Token nameToken, FormalParameterKind kind, MemberKind memberKind) {
    debugEvent("FormalParameter");
    int charOffset = pop();
    String name = pop();
    TypeBuilder type = pop();
    int modifiers = Modifier.validate(pop());
    List<MetadataBuilder> metadata = pop();
    push(library.addFormalParameter(
        metadata, modifiers, type, name, thisKeyword != null, charOffset));
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
    List parameters = popList(count) ?? [];
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
      if (last is List) {
        formals = new List<FormalParameterBuilder>.filled(
            count + last.length, null,
            growable: true);
        // ignore: ARGUMENT_TYPE_NOT_ASSIGNABLE
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
              formals[1].name.length);
          addCompileTimeError(
              templateDuplicatedParameterNameCause
                  .withArguments(formals[1].name),
              formals[0].charOffset,
              formals[0].name.length);
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
                formal.name.length);
            addCompileTimeError(
                templateDuplicatedParameterNameCause.withArguments(formal.name),
                seenNames[formal.name].charOffset,
                seenNames[formal.name].name.length);
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
  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    String documentationComment = getDocumentationComment(enumKeyword);
    List constantNamesAndOffsets = popList(count * 3);
    int charOffset = pop();
    String name = pop();
    List<MetadataBuilder> metadata = pop();
    library.addEnum(documentationComment, metadata, name,
        constantNamesAndOffsets, charOffset, leftBrace?.endGroup?.charOffset);
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
  void endFunctionType(Token functionToken, Token endToken) {
    debugEvent("FunctionType");
    List<FormalParameterBuilder> formals = pop();
    pop(); // formals offset
    TypeBuilder returnType = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    push(library.addFunctionType(
        returnType, typeVariables, formals, functionToken.charOffset));
  }

  @override
  void endFunctionTypedFormalParameter() {
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
    String documentationComment = getDocumentationComment(typedefKeyword);
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
    library.addFunctionTypeAlias(documentationComment, metadata, name,
        typeVariables, functionType, charOffset);
    checkEmpty(typedefKeyword.charOffset);
  }

  @override
  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    debugEvent("endTopLevelFields");
    List fieldsInfo = popList(count * 4);
    TypeBuilder type = pop();
    int modifiers = Modifier.validate(pop());
    List<MetadataBuilder> metadata = pop();
    String documentationComment = getDocumentationComment(beginToken);
    library.addFields(
        documentationComment, metadata, modifiers, type, fieldsInfo);
    checkEmpty(beginToken.charOffset);
  }

  @override
  void endFields(int count, Token beginToken, Token endToken) {
    debugEvent("Fields");
    List fieldsInfo = popList(count * 4);
    TypeBuilder type = pop();
    int modifiers = Modifier.validate(pop());
    List<MetadataBuilder> metadata = pop();
    String documentationComment = getDocumentationComment(beginToken);
    library.addFields(
        documentationComment, metadata, modifiers, type, fieldsInfo);
  }

  @override
  void endTypeVariable(Token token, Token extendsOrSuper) {
    debugEvent("endTypeVariable");
    TypeBuilder bound = pop();
    int charOffset = pop();
    String name = pop();
    // TODO(paulberry): type variable metadata should not be ignored.  See
    // dartbug.com/28981.
    /* List<MetadataBuilder> metadata = */ pop();
    push(library.addTypeVariable(name, bound, charOffset));
  }

  @override
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    debugEvent("endPartOf");
    int charOffset = popCharOffset();
    Object containingLibrary = pop();
    List<MetadataBuilder> metadata = pop();
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
  void beginFactoryMethod(Token lastConsumed) {
    library.beginNestedDeclaration("#factory_method", hasMembers: false);
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
    var name = pop();
    int modifiers = Modifier.validate(pop());
    List<MetadataBuilder> metadata = pop();
    String documentationComment = getDocumentationComment(beginToken);
    library.addFactoryMethod(
        documentationComment,
        metadata,
        modifiers,
        name,
        formals,
        redirectionTarget,
        factoryKeyword.next.charOffset,
        formalsOffset,
        endToken.charOffset,
        nativeMethodName);
    nativeMethodName = null;
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
  void handleModifier(Token token) {
    debugEvent("Modifier");
    push(new Modifier.fromString(token.stringValue));
  }

  @override
  void handleModifiers(int count) {
    debugEvent("Modifiers");
    push(popList(count) ?? NullValue.Modifiers);
  }

  @override
  void addCompileTimeError(Message message, int charOffset, int length) {
    library.addCompileTimeError(message, charOffset, uri);
  }

  void addProblem(Message message, int charOffset, int length) {
    library.addProblem(message, charOffset, uri);
  }

  /// Return the documentation comment for the entity that starts at the
  /// given [token], or `null` if there is no preceding documentation comment.
  static String getDocumentationComment(Token token) {
    Token docToken = token.precedingComments;
    if (docToken == null) return null;
    bool inSlash = false;
    var buffer = new StringBuffer();
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
