// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.diet_listener;

import 'package:kernel/ast.dart'
    show AsyncMarker, Class, InterfaceType, Typedef;
import 'package:kernel/ast.dart';

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import '../../scanner/token.dart' show Token;

import '../builder/builder.dart';

import '../deprecated_problems.dart'
    show Crash, deprecated_InputError, deprecated_inputError;

import '../fasta_codes.dart'
    show
        Message,
        codeExpectedBlockToSkip,
        messageExpectedBlockToSkip,
        templateInternalProblemNotFound;

import '../kernel/body_builder.dart' show BodyBuilder;

import '../parser/native_support.dart'
    show removeNativeClause, skipNativeClause;

import '../parser.dart' show MemberKind, Parser, closeBraceTokenFor, optional;

import '../problems.dart' show internalProblem;

import '../type_inference/type_inference_engine.dart' show TypeInferenceEngine;

import '../type_inference/type_inference_listener.dart'
    show TypeInferenceListener;

import '../util/link.dart' show Link;

import 'source_library_builder.dart' show SourceLibraryBuilder;

import 'stack_listener.dart' show NullValue, StackListener;

class DietListener extends StackListener {
  final SourceLibraryBuilder library;

  final ClassHierarchy hierarchy;

  final CoreTypes coreTypes;

  final bool enableNative;

  final bool stringExpectedAfterNative;

  final TypeInferenceEngine typeInferenceEngine;

  ClassBuilder currentClass;

  /// For top-level declarations, this is the library scope. For class members,
  /// this is the instance scope of [currentClass].
  Scope memberScope;

  @override
  Uri uri;

  DietListener(SourceLibraryBuilder library, this.hierarchy, this.coreTypes,
      this.typeInferenceEngine)
      : library = library,
        uri = library.fileUri,
        memberScope = library.scope,
        enableNative =
            library.loader.target.backendTarget.enableNative(library.uri),
        stringExpectedAfterNative =
            library.loader.target.backendTarget.nativeExtensionExpectsString;

  void discard(int n) {
    for (int i = 0; i < n; i++) {
      pop();
    }
  }

  @override
  void endMetadataStar(int count) {
    debugEvent("MetadataStar");
    push(popList(count)?.first ?? NullValue.Metadata);
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    debugEvent("Metadata");
    discard(periodBeforeName == null ? 1 : 2);
    push(beginToken);
  }

  @override
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    debugEvent("PartOf");
    if (hasName) discard(1);
    discard(1); // Metadata.
  }

  @override
  void handleInvalidTopLevelDeclaration(Token beginToken) {
    debugEvent("InvalidTopLevelDeclaration");
    pop(); // metadata star
  }

  @override
  void handleNoArguments(Token token) {
    debugEvent("NoArguments");
  }

  @override
  void handleModifiers(int count) {
    debugEvent("Modifiers");
  }

  @override
  void handleNoTypeArguments(Token token) {
    debugEvent("NoTypeArguments");
  }

  @override
  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    debugEvent("NoConstructorReferenceContinuationAfterTypeArguments");
  }

  @override
  void handleNoType(Token token) {
    debugEvent("NoType");
  }

  @override
  void handleType(Token beginToken, Token endToken) {
    debugEvent("Type");
    discard(1);
  }

  @override
  void endTypeList(int count) {
    debugEvent("TypeList");
  }

  @override
  void endMixinApplication(Token withKeyword) {
    debugEvent("MixinApplication");
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
  }

  @override
  void endFieldInitializer(Token assignmentOperator, Token token) {
    debugEvent("FieldInitializer");
  }

  @override
  void handleNoFieldInitializer(Token token) {
    debugEvent("NoFieldInitializer");
  }

  @override
  void handleNoTypeVariables(Token token) {
    debugEvent("NoTypeVariables");
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    debugEvent("FormalParameters");
    assert(count == 0); // Count is always 0 as the diet parser skips formals.
    if (kind != MemberKind.GeneralizedFunctionType &&
        identical(peek(), "-") &&
        identical(beginToken.next, endToken)) {
      pop();
      push("unary-");
    }
    push(beginToken);
  }

  @override
  void handleNoFormalParameters(Token token, MemberKind kind) {
    debugEvent("NoFormalParameters");
    if (identical(peek(), "-")) {
      pop();
      push("unary-");
    }
    push(token);
  }

  @override
  void endFunctionType(Token functionToken, Token endToken) {
    debugEvent("FunctionType");
    discard(1);
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    debugEvent("FunctionTypeAlias");

    if (equals == null) pop(); // endToken
    String name = pop();
    Token metadata = pop();

    Builder typedefBuilder = lookupBuilder(typedefKeyword, null, name);
    parseMetadata(typedefBuilder, metadata,
        (typedefBuilder.target as Typedef).addAnnotation);

    checkEmpty(typedefKeyword.charOffset);
  }

  @override
  void endFields(int count, Token beginToken, Token endToken) {
    debugEvent("Fields");
    buildFields(count, beginToken, false);
  }

  @override
  void handleAsyncModifier(Token asyncToken, Token startToken) {
    debugEvent("AsyncModifier");
  }

  @override
  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    debugEvent("TopLevelMethod");
    Token bodyToken = pop();
    String name = pop();
    Token metadata = pop();
    checkEmpty(beginToken.charOffset);
    buildFunctionBody(bodyToken, lookupBuilder(beginToken, getOrSet, name),
        MemberKind.TopLevelMethod, metadata);
  }

  @override
  void handleNoFunctionBody(Token token) {
    debugEvent("NoFunctionBody");
  }

  @override
  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    debugEvent("TopLevelFields");
    buildFields(count, beginToken, true);
  }

  @override
  void handleVoidKeyword(Token token) {
    debugEvent("VoidKeyword");
  }

  @override
  void handleNoInitializers() {
    debugEvent("NoInitializers");
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    debugEvent("Initializers");
  }

  @override
  void handleQualified(Token period) {
    debugEvent("handleQualified");
    // TODO(ahe): Shared with outline_builder.dart.
    String name = pop();
    String receiver = pop();
    push("$receiver.$name");
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    debugEvent("endLibraryName");
    discard(2); // Name and metadata.
  }

  @override
  void beginLiteralString(Token token) {
    debugEvent("beginLiteralString");
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    debugEvent("endLiteralString");
    discard(interpolationCount);
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    debugEvent("NativeClause");
  }

  @override
  void handleScript(Token token) {
    debugEvent("Script");
  }

  @override
  void handleStringJuxtaposition(int literalCount) {
    debugEvent("StringJuxtaposition");
  }

  @override
  void endDottedName(int count, Token firstIdentifier) {
    debugEvent("DottedName");
    discard(count);
  }

  @override
  void endConditionalUri(
      Token ifKeyword, Token leftParen, Token equalSign, Token rightParen) {
    debugEvent("ConditionalUri");
  }

  @override
  void endConditionalUris(int count) {
    debugEvent("ConditionalUris");
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    debugEvent("OperatorName");
    push(token.stringValue);
  }

  @override
  void endIdentifierList(int count) {
    debugEvent("IdentifierList");
    discard(count);
  }

  @override
  void endShow(Token showKeyword) {
    debugEvent("Show");
  }

  @override
  void endHide(Token hideKeyword) {
    debugEvent("Hide");
  }

  @override
  void endCombinators(int count) {
    debugEvent("Combinators");
  }

  @override
  void endImport(Token importKeyword, Token DeferredKeyword, Token asKeyword,
      Token semicolon) {
    debugEvent("Import");
    popIfNotNull(asKeyword);
    discard(1); // Metadata.
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    debugEvent("Export");
    discard(1); // Metadata.
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    debugEvent("Part");
    discard(1); // Metadata.
  }

  @override
  void endTypeVariable(Token token, Token extendsOrSuper) {
    debugEvent("TypeVariable");
    discard(2); // Name and metadata.
  }

  @override
  void endTypeVariables(int count, Token beginToken, Token endToken) {
    debugEvent("TypeVariables");
  }

  @override
  void handleModifier(Token token) {
    debugEvent("Modifier");
  }

  @override
  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    debugEvent("ConstructorReference");
    popIfNotNull(periodBeforeName);
  }

  @override
  void endFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    debugEvent("FactoryMethod");
    Token bodyToken = pop();
    String name = pop();
    Token metadata = pop();
    checkEmpty(beginToken.charOffset);
    if (bodyToken == null ||
        optional("=", closeBraceTokenFor(bodyToken).next)) {
      // TODO(ahe): Don't skip this. We need to compile metadata and
      // redirecting factory bodies.
      return;
    }
    buildFunctionBody(bodyToken, lookupBuilder(beginToken, null, name),
        MemberKind.Factory, metadata);
  }

  @override
  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    debugEvent("RedirectingFactoryBody");
    discard(1); // ConstructorReference.
  }

  @override
  void handleNativeFunctionBody(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBody");
  }

  @override
  void handleNativeFunctionBodyIgnored(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBodyIgnored");
  }

  @override
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBodySkipped");
    if (!enableNative) {
      super.handleUnrecoverableError(nativeToken, messageExpectedBlockToSkip);
    }
  }

  @override
  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    debugEvent("Method");
    Token bodyToken = pop();
    String name = pop();
    Token metadata = pop();
    checkEmpty(beginToken.charOffset);
    if (bodyToken == null) {
      // TODO(ahe): Don't skip this. We need to compile metadata.
      return;
    }
    ProcedureBuilder builder = lookupBuilder(beginToken, getOrSet, name);
    buildFunctionBody(
        bodyToken,
        builder,
        builder.isStatic ? MemberKind.StaticMethod : MemberKind.NonStaticMethod,
        metadata);
  }

  StackListener createListener(
      ModifierBuilder builder, Scope memberScope, bool isInstanceMember,
      [Scope formalParameterScope, TypeInferenceListener listener]) {
    listener ??= new TypeInferenceListener();
    InterfaceType thisType;
    if (builder.isClassMember) {
      // Note: we set thisType regardless of whether we are building a static
      // member, since that provides better error recovery.
      Class cls = builder.parent.target;
      thisType = cls.thisType;
    }
    var typeInferrer = library.disableTypeInference
        ? typeInferenceEngine.createDisabledTypeInferrer()
        : typeInferenceEngine.createLocalTypeInferrer(uri, listener, thisType);
    return new BodyBuilder(library, builder, memberScope, formalParameterScope,
        hierarchy, coreTypes, currentClass, isInstanceMember, uri, typeInferrer)
      ..constantExpressionRequired = builder.isConstructor && builder.isConst;
  }

  void buildFunctionBody(
      Token token, ProcedureBuilder builder, MemberKind kind, Token metadata) {
    Scope typeParameterScope = builder.computeTypeParameterScope(memberScope);
    Scope formalParameterScope =
        builder.computeFormalParameterScope(typeParameterScope);
    assert(typeParameterScope != null);
    assert(formalParameterScope != null);
    parseFunctionBody(
        createListener(builder, typeParameterScope, builder.isInstanceMember,
            formalParameterScope),
        token,
        metadata,
        kind);
  }

  void buildFields(int count, Token token, bool isTopLevel) {
    List<String> names = popList(count);
    Builder builder = lookupBuilder(token, null, names.first);
    Token metadata = pop();
    // TODO(paulberry): don't re-parse the field if we've already parsed it
    // for type inference.
    parseFields(createListener(builder, memberScope, builder.isInstanceMember),
        token, metadata, isTopLevel);
  }

  @override
  void endMember() {
    debugEvent("Member");
    checkEmpty(-1);
  }

  @override
  void beginClassBody(Token token) {
    debugEvent("beginClassBody");
    String name = pop();
    Token metadata = pop();
    assert(currentClass == null);
    assert(memberScope == library.scope);

    Builder classBuilder = lookupBuilder(token, null, name);
    parseMetadata(
        classBuilder, metadata, (classBuilder.target as Class).addAnnotation);

    currentClass = classBuilder;
    memberScope = currentClass.scope;
  }

  @override
  void endClassBody(int memberCount, Token beginToken, Token endToken) {
    debugEvent("ClassBody");
    currentClass = null;
    memberScope = library.scope;
  }

  @override
  void endClassDeclaration(
      int interfacesCount,
      Token beginToken,
      Token classKeyword,
      Token extendsKeyword,
      Token implementsKeyword,
      Token nativeToken,
      Token endToken) {
    debugEvent("ClassDeclaration");
    checkEmpty(beginToken.charOffset);
  }

  @override
  void endEnum(Token enumKeyword, Token endBrace, int count) {
    debugEvent("Enum");
    discard(count + 2); // Name and metadata.
    checkEmpty(enumKeyword.charOffset);
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equals, Token implementsKeyword, Token endToken) {
    debugEvent("NamedMixinApplication");
    discard(2); // Name and metadata.
    checkEmpty(beginToken.charOffset);
  }

  @override
  Token handleUnrecoverableError(Token token, Message message) {
    if (enableNative && message.code == codeExpectedBlockToSkip) {
      Token recover = skipNativeClause(token, stringExpectedAfterNative);
      if (recover != null) return recover;
    }
    return super.handleUnrecoverableError(token, message);
  }

  @override
  Link<Token> handleMemberName(Link<Token> identifiers) {
    if (!enableNative || identifiers.isEmpty) return identifiers;
    return removeNativeClause(identifiers, stringExpectedAfterNative);
  }

  AsyncMarker getAsyncMarker(StackListener listener) => listener.pop();

  /// Invokes the listener's [finishFunction] method.
  ///
  /// This is a separate method so that it may be overridden by a derived class
  /// if more computation must be done before finishing the function.
  void listenerFinishFunction(
      StackListener listener,
      Token token,
      Token metadata,
      MemberKind kind,
      List metadataConstants,
      dynamic formals,
      AsyncMarker asyncModifier,
      dynamic body) {
    listener.finishFunction(metadataConstants, formals, asyncModifier, body);
  }

  /// Invokes the listener's [finishFields] method.
  ///
  /// This is a separate method so that it may be overridden by a derived class
  /// if more computation must be done before finishing the function.
  void listenerFinishFields(StackListener listener, Token startToken,
      Token metadata, bool isTopLevel) {
    listener.finishFields();
  }

  void parseFunctionBody(StackListener listener, Token startToken,
      Token metadata, MemberKind kind) {
    Token token = startToken;
    try {
      Parser parser = new Parser(listener);
      List metadataConstants;
      if (metadata != null) {
        parser.parseMetadataStar(metadata);
        metadataConstants = listener.pop();
      }
      token = parser.parseFormalParametersOpt(token, kind);
      var formals = listener.pop();
      listener.checkEmpty(token.charOffset);
      token = parser.parseInitializersOpt(token);
      token = parser.parseAsyncModifier(token);
      AsyncMarker asyncModifier = getAsyncMarker(listener) ?? AsyncMarker.Sync;
      bool isExpression = false;
      bool allowAbstract = asyncModifier == AsyncMarker.Sync;
      parser.parseFunctionBody(token, isExpression, allowAbstract);
      var body = listener.pop();
      listener.checkEmpty(token.charOffset);
      listenerFinishFunction(listener, startToken, metadata, kind,
          metadataConstants, formals, asyncModifier, body);
    } on deprecated_InputError {
      rethrow;
    } catch (e, s) {
      throw new Crash(uri, token.charOffset, e, s);
    }
  }

  void parseFields(StackListener listener, Token startToken, Token metadata,
      bool isTopLevel) {
    Token token = startToken;
    Parser parser = new Parser(listener);
    if (isTopLevel) {
      // There's a slight asymmetry between [parseTopLevelMember] and
      // [parseMember] because the former doesn't call `parseMetadataStar`.
      token = parser.parseMetadataStar(metadata ?? token);
      token = parser.parseTopLevelMember(token);
    } else {
      token = parser.parseMember(metadata ?? token);
    }
    listenerFinishFields(listener, startToken, metadata, isTopLevel);
    listener.checkEmpty(token.charOffset);
  }

  Builder lookupBuilder(Token token, Token getOrSet, String name) {
    // TODO(ahe): Can I move this to Scope or ScopeBuilder?
    Builder builder;
    if (currentClass != null) {
      if (getOrSet != null && optional("set", getOrSet)) {
        builder = currentClass.scope.setters[name];
      } else {
        builder = currentClass.scope.local[name];
      }
      if (builder == null) {
        if (name == currentClass.name) {
          name = "";
        } else {
          int index = name.indexOf(".");
          name = name.substring(index + 1);
        }
        builder = currentClass.constructors.local[name];
      }
    } else if (getOrSet != null && optional("set", getOrSet)) {
      builder = library.scope.setters[name];
    } else {
      builder = library.scopeBuilder[name];
    }
    if (builder == null) {
      return internalProblem(
          templateInternalProblemNotFound.withArguments(name),
          token.charOffset,
          uri);
    }
    if (builder.next != null) {
      return deprecated_inputError(
          uri, token.charOffset, "Duplicated name: $name");
    }
    return builder;
  }

  @override
  void addCompileTimeError(Message message, int charOffset) {
    library.addCompileTimeError(message, charOffset, uri,
        // We assume this error has already been reported by OutlineBuilder.
        silent: true);
  }

  @override
  void debugEvent(String name) {
    // printEvent('DietListener: $name');
  }

  void parseMetadata(Builder builder, Token metadata,
      void addAnnotation(Expression annotation)) {
    if (metadata != null) {
      var listener = createListener(builder, memberScope, false);
      var parser = new Parser(listener);
      parser.parseMetadataStar(metadata);
      List<Expression> metadataConstants = listener.finishMetadata();
      metadataConstants.forEach(addAnnotation);
    }
  }
}
