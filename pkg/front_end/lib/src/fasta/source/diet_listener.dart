// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.diet_listener;

import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart'
    show TypeInferenceEngine;

import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart'
    show TypeInferenceListener;

import 'package:kernel/ast.dart' show AsyncMarker, Class, InterfaceType;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import '../fasta_codes.dart' show FastaMessage, codeExpectedBlockToSkip;

import '../parser/parser.dart' show MemberKind, Parser, optional;

import '../../scanner/token.dart' show BeginToken, Token;

import '../parser/dart_vm_native.dart' show removeNativeClause;

import '../util/link.dart' show Link;

import '../errors.dart' show Crash, InputError, inputError, internalError;

import 'stack_listener.dart' show StackListener;

import '../kernel/body_builder.dart' show BodyBuilder;

import '../builder/builder.dart';

import 'source_library_builder.dart' show SourceLibraryBuilder;

class DietListener extends StackListener {
  final SourceLibraryBuilder library;

  final ClassHierarchy hierarchy;

  final CoreTypes coreTypes;

  final bool enableNative;

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
        enableNative = library.loader.target.enableNative(library);

  void discard(int n) {
    for (int i = 0; i < n; i++) {
      pop();
    }
  }

  @override
  void endMetadataStar(int count, bool forParameter) {
    debugEvent("MetadataStar");
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    debugEvent("Metadata");
    popIfNotNull(periodBeforeName);
    discard(1);
  }

  @override
  void endPartOf(Token partKeyword, Token semicolon, bool hasName) {
    debugEvent("PartOf");
    if (hasName) discard(1);
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
  void handleFunctionType(Token functionToken, Token endToken) {
    debugEvent("FunctionType");
    discard(1);
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    debugEvent("FunctionTypeAlias");
    if (equals != null) {
      // This is a `typedef NAME = TYPE`.
      discard(1); // Name.
    } else {
      discard(2); // Name + endToken.
    }
    checkEmpty(typedefKeyword.charOffset);
  }

  @override
  void endFields(int count, Token beginToken, Token endToken) {
    debugEvent("Fields");
    List<String> names = popList(count);
    Builder builder = lookupBuilder(beginToken, null, names.first);
    buildFields(beginToken, false, builder);
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
    checkEmpty(beginToken.charOffset);
    buildFunctionBody(bodyToken, lookupBuilder(beginToken, getOrSet, name),
        MemberKind.TopLevelMethod);
  }

  @override
  void handleNoFunctionBody(Token token) {
    debugEvent("NoFunctionBody");
  }

  @override
  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    debugEvent("TopLevelFields");
    List<String> names = popList(count);
    Builder builder = lookupBuilder(beginToken, null, names.first);
    buildFields(beginToken, true, builder);
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
    discard(1);
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
  void endConditionalUri(Token ifKeyword, Token equalitySign) {
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
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    debugEvent("Export");
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    debugEvent("Part");
  }

  @override
  void endTypeVariable(Token token, Token extendsOrSuper) {
    debugEvent("TypeVariable");
    discard(1);
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
    BeginToken bodyToken = pop();
    String name = pop();
    checkEmpty(beginToken.charOffset);
    if (bodyToken == null || optional("=", bodyToken.endGroup.next)) {
      return;
    }
    buildFunctionBody(
        bodyToken, lookupBuilder(beginToken, null, name), MemberKind.Factory);
  }

  @override
  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    debugEvent("RedirectingFactoryBody");
    discard(1); // ConstructorReference.
  }

  @override
  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    debugEvent("Method");
    Token bodyToken = pop();
    String name = pop();
    checkEmpty(beginToken.charOffset);
    if (bodyToken == null) {
      return;
    }
    ProcedureBuilder builder = lookupBuilder(beginToken, getOrSet, name);
    buildFunctionBody(
        bodyToken,
        builder,
        builder.isStatic
            ? MemberKind.StaticMethod
            : MemberKind.NonStaticMethod);
  }

  StackListener createListener(
      MemberBuilder builder, Scope memberScope, bool isInstanceMember,
      [Scope formalParameterScope]) {
    var listener = new TypeInferenceListener();
    InterfaceType thisType;
    if (builder.isClassMember) {
      // Note: we set thisType regardless of whether we are building a static
      // member, since that provides better error recovery.
      Class cls = builder.parent.target;
      thisType = cls.thisType;
    }
    var typeInferrer =
        typeInferenceEngine.createLocalTypeInferrer(uri, listener, thisType);
    return new BodyBuilder(library, builder, memberScope, formalParameterScope,
        hierarchy, coreTypes, currentClass, isInstanceMember, uri, typeInferrer)
      ..constantExpressionRequired = builder.isConstructor && builder.isConst;
  }

  void buildFunctionBody(
      Token token, ProcedureBuilder builder, MemberKind kind) {
    Scope typeParameterScope = builder.computeTypeParameterScope(memberScope);
    Scope formalParameterScope =
        builder.computeFormalParameterScope(typeParameterScope);
    assert(typeParameterScope != null);
    assert(formalParameterScope != null);
    parseFunctionBody(
        createListener(builder, typeParameterScope, builder.isInstanceMember,
            formalParameterScope),
        token,
        kind);
  }

  void buildFields(Token token, bool isTopLevel, MemberBuilder builder) {
    // TODO(paulberry): don't re-parse the field if we've already parsed it
    // for type inference.
    parseFields(createListener(builder, memberScope, builder.isInstanceMember),
        token, isTopLevel);
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
    assert(currentClass == null);
    currentClass = lookupBuilder(token, null, name);
    assert(memberScope == library.scope);
    memberScope = currentClass.scope;
  }

  @override
  void endClassBody(int memberCount, Token beginToken, Token endToken) {
    debugEvent("ClassBody");
    currentClass = null;
    checkEmpty(beginToken.charOffset);
    memberScope = library.scope;
  }

  @override
  void endClassDeclaration(
      int interfacesCount,
      Token beginToken,
      Token classKeyword,
      Token extendsKeyword,
      Token implementsKeyword,
      Token endToken) {
    debugEvent("ClassDeclaration");
    checkEmpty(beginToken.charOffset);
  }

  @override
  void endEnum(Token enumKeyword, Token endBrace, int count) {
    debugEvent("Enum");
    discard(count);
    pop(); // Name.
    checkEmpty(enumKeyword.charOffset);
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equals, Token implementsKeyword, Token endToken) {
    debugEvent("NamedMixinApplication");
    pop(); // Name.
    checkEmpty(beginToken.charOffset);
  }

  @override
  Token handleUnrecoverableError(Token token, FastaMessage message) {
    if (enableNative && message.code == codeExpectedBlockToSkip) {
      Token recover = library.loader.target.skipNativeClause(token);
      if (recover != null) return recover;
    }
    return super.handleUnrecoverableError(token, message);
  }

  @override
  Link<Token> handleMemberName(Link<Token> identifiers) {
    if (!enableNative || identifiers.isEmpty) return identifiers;
    return removeNativeClause(identifiers);
  }

  AsyncMarker getAsyncMarker(StackListener listener) => listener.pop();

  void parseFunctionBody(StackListener listener, Token token, MemberKind kind) {
    try {
      Parser parser = new Parser(listener);
      token = parser.parseFormalParametersOpt(token, kind);
      var formals = listener.pop();
      listener.checkEmpty(token.charOffset);
      listener.prepareInitializers();
      token = parser.parseInitializersOpt(token);
      token = parser.parseAsyncModifier(token);
      AsyncMarker asyncModifier = getAsyncMarker(listener) ?? AsyncMarker.Sync;
      bool isExpression = false;
      bool allowAbstract = asyncModifier == AsyncMarker.Sync;
      parser.parseFunctionBody(token, isExpression, allowAbstract);
      var body = listener.pop();
      listener.checkEmpty(token.charOffset);
      listener.finishFunction(formals, asyncModifier, body);
    } on InputError {
      rethrow;
    } catch (e, s) {
      throw new Crash(uri, token.charOffset, e, s);
    }
  }

  void parseFields(StackListener listener, Token token, bool isTopLevel) {
    Parser parser = new Parser(listener);
    if (isTopLevel) {
      token = parser.parseTopLevelMember(token);
    } else {
      token = parser.parseMember(token);
    }
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
      return internalError("Builder not found: $name", uri, token.charOffset);
    }
    if (builder.next != null) {
      return inputError(uri, token.charOffset, "Duplicated name: $name");
    }
    return builder;
  }

  @override
  void addCompileTimeErrorFromMessage(FastaMessage message) {
    library.addCompileTimeError(message.charOffset, message.message,
        fileUri: message.uri,
        // We assume this error has already been reported by OutlineBuilder.
        silent: true);
  }

  @override
  void debugEvent(String name) {
    // printEvent(name);
  }
}
