// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.diet_listener;

import 'package:kernel/ast.dart'
    show
        AsyncMarker,
        Expression,
        InterfaceType,
        Library,
        LibraryDependency,
        LibraryPart,
        TreeNode,
        VariableDeclaration;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import '../../scanner/token.dart' show Token;

import '../builder/builder.dart';

import '../constant_context.dart' show ConstantContext;

import '../crash.dart' show Crash;

import '../fasta_codes.dart'
    show
        Code,
        LocatedMessage,
        Message,
        messageExpectedBlockToSkip,
        templateInternalProblemNotFound;

import '../ignored_parser_errors.dart' show isIgnoredParserError;

import '../kernel/kernel_body_builder.dart' show KernelBodyBuilder;

import '../kernel/kernel_builder.dart'
    show
        KernelFormalParameterBuilder,
        KernelFunctionTypeBuilder,
        KernelTypeAliasBuilder,
        KernelTypeBuilder;

import '../parser.dart' show Assert, MemberKind, Parser, optional;

import '../problems.dart'
    show DebugAbort, internalProblem, unexpected, unhandled;

import '../type_inference/type_inference_engine.dart' show TypeInferenceEngine;

import 'source_library_builder.dart' show SourceLibraryBuilder;

import 'stack_listener.dart'
    show FixedNullableList, NullValue, ParserRecovery, StackListener;

import '../quote.dart' show unescapeString;

class DietListener extends StackListener {
  final SourceLibraryBuilder library;

  final ClassHierarchy hierarchy;

  final CoreTypes coreTypes;

  final bool enableNative;

  final bool stringExpectedAfterNative;

  final TypeInferenceEngine typeInferenceEngine;

  int importExportDirectiveIndex = 0;
  int partDirectiveIndex = 0;

  ClassBuilder currentClass;

  bool currentClassIsParserRecovery = false;

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

  @override
  void endMetadataStar(int count) {
    debugEvent("MetadataStar");
    if (count > 0) {
      discard(count - 1);
      push(pop(NullValue.Metadata));
    } else {
      push(NullValue.Metadata);
    }
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
  void handleNoTypeArguments(Token token) {
    debugEvent("NoTypeArguments");
  }

  @override
  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    debugEvent("NoConstructorReferenceContinuationAfterTypeArguments");
  }

  @override
  void handleNoType(Token lastConsumed) {
    debugEvent("NoType");
  }

  @override
  void handleType(Token beginToken, Token questionMark) {
    debugEvent("Type");
    discard(1);
  }

  @override
  void endTypeList(int count) {
    debugEvent("TypeList");
  }

  @override
  void handleNamedMixinApplicationWithClause(Token withKeyword) {
    debugEvent("NamedMixinApplicationWithClause");
  }

  @override
  void handleClassWithClause(Token withKeyword) {
    debugEvent("ClassWithClause");
  }

  @override
  void handleClassNoWithClause() {
    debugEvent("ClassNoWithClause");
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
  }

  @override
  void handleInvalidTypeArguments(Token token) {
    debugEvent("InvalidTypeArguments");
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
  void endFunctionType(Token functionToken, Token questionMark) {
    debugEvent("FunctionType");
    discard(1);
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    debugEvent("FunctionTypeAlias");

    if (equals == null) pop(); // endToken
    Object name = pop();
    Token metadata = pop();
    checkEmpty(typedefKeyword.charOffset);
    if (name is ParserRecovery) return;

    Declaration typedefBuilder = lookupBuilder(typedefKeyword, null, name);
    parseMetadata(typedefBuilder, metadata, typedefBuilder.target);
    if (typedefBuilder is KernelTypeAliasBuilder) {
      KernelTypeBuilder type = typedefBuilder.type;
      if (type is KernelFunctionTypeBuilder) {
        List<FormalParameterBuilder<TypeBuilder>> formals = type.formals;
        if (formals != null) {
          for (int i = 0; i < formals.length; ++i) {
            KernelFormalParameterBuilder formal = formals[i];
            List<MetadataBuilder> metadata = formal.metadata;
            if (metadata != null && metadata.length > 0) {
              // [parseMetadata] is using [Parser.parseMetadataStar] under the
              // hood, so we only need the offset of the first annotation.
              Token metadataToken = tokenForOffset(
                  typedefKeyword, endToken, metadata[0].charOffset);
              List<Expression> annotations =
                  parseMetadata(typedefBuilder, metadataToken, null);
              if (formal.isPositional) {
                VariableDeclaration parameter =
                    typedefBuilder.target.positionalParameters[i];
                for (Expression annotation in annotations) {
                  parameter.addAnnotation(annotation);
                }
              } else {
                for (VariableDeclaration named
                    in typedefBuilder.target.namedParameters) {
                  if (named.name == formal.name) {
                    for (Expression annotation in annotations) {
                      named.addAnnotation(annotation);
                    }
                  }
                }
              }
            }
          }
        }
      }
    } else if (typedefBuilder != null) {
      unhandled("${typedefBuilder.fullNameForErrors}", "endFunctionTypeAlias",
          typedefKeyword.charOffset, uri);
    }

    checkEmpty(typedefKeyword.charOffset);
  }

  @override
  void endFields(Token staticToken, Token covariantToken, Token lateToken,
      Token varFinalOrConst, int count, Token beginToken, Token endToken) {
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
    Object name = pop();
    Token metadata = pop();
    checkEmpty(beginToken.charOffset);
    if (name is ParserRecovery) return;

    final StackListener listener =
        createFunctionListener(lookupBuilder(beginToken, getOrSet, name));
    buildFunctionBody(listener, bodyToken, metadata, MemberKind.TopLevelMethod);
  }

  @override
  void handleNoFunctionBody(Token token) {
    debugEvent("NoFunctionBody");
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
    Object suffix = pop();
    Object prefix = pop();
    if (prefix is ParserRecovery) {
      push(prefix);
    } else if (suffix is ParserRecovery) {
      push(suffix);
    } else {
      assert(identical(suffix, period.next.lexeme));
      push(new QualifiedName(prefix, period.next));
    }
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    debugEvent("endLibraryName");
    pop(); // name

    Token metadata = pop();
    parseMetadata(library, metadata, library.target);
  }

  @override
  void beginLiteralString(Token token) {
    debugEvent("beginLiteralString");
  }

  @override
  void handleStringPart(Token token) {
    debugEvent("StringPart");
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    debugEvent("endLiteralString");
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
  void handleDottedName(int count, Token firstIdentifier) {
    debugEvent("DottedName");
    discard(count);
  }

  @override
  void endConditionalUri(Token ifKeyword, Token leftParen, Token equalSign) {
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
  void handleInvalidOperatorName(Token operatorKeyword, Token token) {
    debugEvent("InvalidOperatorName");
    push('invalid');
  }

  @override
  void handleIdentifierList(int count) {
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
  void handleImportPrefix(Token deferredKeyword, Token asKeyword) {
    debugEvent("ImportPrefix");
    pushIfNull(asKeyword, NullValue.Prefix);
  }

  @override
  void endImport(Token importKeyword, Token semicolon) {
    debugEvent("Import");
    Object name = pop(NullValue.Prefix);

    Token metadata = pop();
    checkEmpty(importKeyword.charOffset);
    if (name is ParserRecovery) return;

    // Native imports must be skipped because they aren't assigned corresponding
    // LibraryDependency nodes.
    Token importUriToken = importKeyword.next;
    String importUri =
        unescapeString(importUriToken.lexeme, importUriToken, this);
    if (importUri.startsWith("dart-ext:")) return;

    Library libraryNode = library.target;
    LibraryDependency dependency =
        libraryNode.dependencies[importExportDirectiveIndex++];
    parseMetadata(library, metadata, dependency);
  }

  @override
  void handleRecoverImport(Token semicolon) {
    pop(NullValue.Prefix);
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    debugEvent("Export");

    Token metadata = pop();
    Library libraryNode = library.target;
    LibraryDependency dependency =
        libraryNode.dependencies[importExportDirectiveIndex++];
    parseMetadata(library, metadata, dependency);
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    debugEvent("Part");

    Token metadata = pop();
    Library libraryNode = library.target;
    LibraryPart part = libraryNode.parts[partDirectiveIndex++];
    parseMetadata(library, metadata, part);
  }

  @override
  void beginTypeVariable(Token token) {
    debugEvent("beginTypeVariable");
    discard(2); // Name and metadata.
  }

  @override
  void endTypeVariable(Token token, int index, Token extendsOrSuper) {
    debugEvent("endTypeVariable");
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    debugEvent("TypeVariables");
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
    Object name = pop();
    Token metadata = pop();
    checkEmpty(beginToken.charOffset);
    if (name is ParserRecovery || currentClassIsParserRecovery) return;

    ProcedureBuilder builder = lookupConstructor(beginToken, name);
    if (bodyToken == null || optional("=", bodyToken.endGroup.next)) {
      parseMetadata(builder, metadata, builder.target);
      buildRedirectingFactoryMethod(
          bodyToken, builder, MemberKind.Factory, metadata);
    } else {
      buildFunctionBody(createFunctionListener(builder), bodyToken, metadata,
          MemberKind.Factory);
    }
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
      super.handleRecoverableError(
          messageExpectedBlockToSkip, nativeToken, nativeToken);
    }
  }

  @override
  void endMethod(
      Token getOrSet, Token beginToken, Token beginParam, Token endToken) {
    debugEvent("Method");
    // TODO(danrubel): Consider removing the beginParam parameter
    // and using bodyToken, but pushing a NullValue on the stack
    // in handleNoFormalParameters rather than the supplied token.
    pop(); // bodyToken
    Object name = pop();
    Token metadata = pop();
    checkEmpty(beginToken.charOffset);
    if (name is ParserRecovery || currentClassIsParserRecovery) return;
    ProcedureBuilder builder;
    if (name is QualifiedName ||
        (getOrSet == null && name == currentClass.name)) {
      builder = lookupConstructor(beginToken, name);
    } else {
      builder = lookupBuilder(beginToken, getOrSet, name);
    }
    buildFunctionBody(
        createFunctionListener(builder),
        beginParam,
        metadata,
        builder.isStatic
            ? MemberKind.StaticMethod
            : MemberKind.NonStaticMethod);
  }

  StackListener createListener(
      ModifierBuilder builder, Scope memberScope, bool isInstanceMember,
      [Scope formalParameterScope]) {
    // Note: we set thisType regardless of whether we are building a static
    // member, since that provides better error recovery.
    InterfaceType thisType = currentClass?.target?.thisType;
    var typeInferrer =
        typeInferenceEngine?.createLocalTypeInferrer(uri, thisType, library);
    ConstantContext constantContext = builder.isConstructor && builder.isConst
        ? ConstantContext.inferred
        : ConstantContext.none;
    return new KernelBodyBuilder(
        library,
        builder,
        memberScope,
        formalParameterScope,
        hierarchy,
        coreTypes,
        currentClass,
        isInstanceMember,
        uri,
        typeInferrer)
      ..constantContext = constantContext;
  }

  StackListener createFunctionListener(ProcedureBuilder builder) {
    final Scope typeParameterScope =
        builder.computeTypeParameterScope(memberScope);
    final Scope formalParameterScope =
        builder.computeFormalParameterScope(typeParameterScope);
    assert(typeParameterScope != null);
    assert(formalParameterScope != null);
    return createListener(builder, typeParameterScope, builder.isInstanceMember,
        formalParameterScope);
  }

  void buildRedirectingFactoryMethod(
      Token token, ProcedureBuilder builder, MemberKind kind, Token metadata) {
    final StackListener listener = createFunctionListener(builder);
    try {
      Parser parser = new Parser(listener);
      if (metadata != null) {
        parser.parseMetadataStar(parser.syntheticPreviousToken(metadata));
        listener.pop(); // Pops metadata constants.
      }

      token = parser.parseFormalParametersOpt(
          parser.syntheticPreviousToken(token), MemberKind.Factory);
      listener.pop(); // Pops formal parameters.
      listener.checkEmpty(token.next.charOffset);
    } on DebugAbort {
      rethrow;
    } catch (e, s) {
      throw new Crash(uri, token.charOffset, e, s);
    }
  }

  void buildFields(int count, Token token, bool isTopLevel) {
    List<String> names = const FixedNullableList<String>().pop(stack, count);
    Token metadata = pop();
    checkEmpty(token.charOffset);
    if (names == null || currentClassIsParserRecovery) return;

    Declaration declaration = lookupBuilder(token, null, names.first);
    // TODO(paulberry): don't re-parse the field if we've already parsed it
    // for type inference.
    parseFields(
        createListener(declaration, memberScope, declaration.isInstanceMember),
        token,
        metadata,
        isTopLevel);
    checkEmpty(token.charOffset);
  }

  @override
  void handleInvalidMember(Token endToken) {
    debugEvent("InvalidMember");
    pop(); // metadata star
  }

  @override
  void endMember() {
    debugEvent("Member");
    checkEmpty(-1);
  }

  @override
  void endAssert(Token assertKeyword, Assert kind, Token leftParenthesis,
      Token commaToken, Token semicolonToken) {
    debugEvent("Assert");
    // Do nothing
  }

  @override
  void beginMixinDeclaration(Token mixinKeyword, Token name) {
    debugEvent("beginMixinDeclaration");
    push(mixinKeyword);
  }

  @override
  void beginClassDeclaration(Token begin, Token abstractToken, Token name) {
    debugEvent("beginClassDeclaration");
    push(begin);
  }

  @override
  void beginClassOrMixinBody(Token token) {
    debugEvent("beginClassOrMixinBody");
    Token beginToken = pop();
    Object name = pop();
    Token metadata = pop();
    assert(currentClass == null);
    assert(memberScope == library.scope);
    if (name is ParserRecovery) {
      currentClassIsParserRecovery = true;
      return;
    }

    Declaration classBuilder = lookupBuilder(beginToken, null, name);
    parseMetadata(classBuilder, metadata, classBuilder.target);

    currentClass = classBuilder;
    memberScope = currentClass.scope;
  }

  @override
  void endClassOrMixinBody(int memberCount, Token beginToken, Token endToken) {
    debugEvent("ClassOrMixinBody");
    currentClass = null;
    currentClassIsParserRecovery = false;
    memberScope = library.scope;
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    debugEvent("ClassDeclaration");
    checkEmpty(beginToken.charOffset);
  }

  @override
  void endMixinDeclaration(Token mixinKeyword, Token endToken) {
    debugEvent("MixinDeclaration");
    checkEmpty(mixinKeyword.charOffset);
  }

  @override
  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    debugEvent("Enum");
    List<Object> metadataAndValues =
        const FixedNullableList<Object>().pop(stack, count * 2);
    Object name = pop();
    Token metadata = pop();
    checkEmpty(enumKeyword.charOffset);
    if (name is ParserRecovery) return;

    ClassBuilder enumBuilder = lookupBuilder(enumKeyword, null, name);
    parseMetadata(enumBuilder, metadata, enumBuilder.target);
    if (metadataAndValues != null) {
      for (int i = 0; i < metadataAndValues.length; i += 2) {
        Token metadata = metadataAndValues[i];
        String valueName = metadataAndValues[i + 1];
        Declaration declaration = enumBuilder.scope.local[valueName];
        if (metadata != null) {
          parseMetadata(declaration, metadata, declaration.target);
        }
      }
    }

    checkEmpty(enumKeyword.charOffset);
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equals, Token implementsKeyword, Token endToken) {
    debugEvent("NamedMixinApplication");

    Object name = pop();
    Token metadata = pop();
    checkEmpty(beginToken.charOffset);
    if (name is ParserRecovery) return;

    Declaration classBuilder = library.scopeBuilder[name];
    if (classBuilder != null) {
      // TODO(ahe): We shouldn't have to check for null here. The problem is
      // that we don't create a named mixin application if the mixins or
      // supertype are missing. Could we create a class instead? The nested
      // declarations wouldn't match up.
      parseMetadata(classBuilder, metadata, classBuilder.target);
      checkEmpty(beginToken.charOffset);
    }
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

  void buildFunctionBody(StackListener listener, Token startToken,
      Token metadata, MemberKind kind) {
    Token token = startToken;
    try {
      Parser parser = new Parser(listener);
      List metadataConstants;
      if (metadata != null) {
        parser.parseMetadataStar(parser.syntheticPreviousToken(metadata));
        metadataConstants = listener.pop();
      }
      token = parser.parseFormalParametersOpt(
          parser.syntheticPreviousToken(token), kind);
      var formals = listener.pop();
      listener.checkEmpty(token.next.charOffset);
      token = parser.parseInitializersOpt(token);
      token = parser.parseAsyncModifierOpt(token);
      AsyncMarker asyncModifier = getAsyncMarker(listener) ?? AsyncMarker.Sync;
      bool isExpression = false;
      bool allowAbstract = asyncModifier == AsyncMarker.Sync;
      parser.parseFunctionBody(token, isExpression, allowAbstract);
      var body = listener.pop();
      listener.checkEmpty(token.charOffset);
      listenerFinishFunction(listener, startToken, metadata, kind,
          metadataConstants, formals, asyncModifier, body);
    } on DebugAbort {
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
      token = parser.parseTopLevelMember(metadata ?? token);
    } else {
      token = parser.parseClassOrMixinMember(metadata ?? token).next;
    }
    listenerFinishFields(listener, startToken, metadata, isTopLevel);
    listener.checkEmpty(token.charOffset);
  }

  Declaration lookupBuilder(Token token, Token getOrSet, String name) {
    // TODO(ahe): Can I move this to Scope or ScopeBuilder?
    Declaration declaration;
    if (currentClass != null) {
      if (uri != currentClass.fileUri) {
        unexpected("$uri", "${currentClass.fileUri}", currentClass.charOffset,
            currentClass.fileUri);
      }

      if (getOrSet != null && optional("set", getOrSet)) {
        declaration = currentClass.scope.setters[name];
      } else {
        declaration = currentClass.scope.local[name];
      }
    } else if (getOrSet != null && optional("set", getOrSet)) {
      declaration = library.scope.setters[name];
    } else {
      declaration = library.scopeBuilder[name];
    }
    declaration = handleDuplicatedName(declaration, token);
    checkBuilder(token, declaration, name);
    return declaration;
  }

  Declaration lookupConstructor(Token token, Object nameOrQualified) {
    assert(currentClass != null);
    Declaration declaration;
    String suffix;
    if (nameOrQualified is QualifiedName) {
      suffix = nameOrQualified.name;
    } else {
      suffix = nameOrQualified == currentClass.name ? "" : nameOrQualified;
    }
    declaration = currentClass.constructors.local[suffix];
    declaration = handleDuplicatedName(declaration, token);
    checkBuilder(token, declaration, nameOrQualified);
    return declaration;
  }

  Declaration handleDuplicatedName(Declaration declaration, Token token) {
    int offset = token.charOffset;
    if (declaration?.next == null) {
      return declaration;
    } else {
      Declaration nearestDeclaration;
      int minDistance = -1;
      do {
        // Only look at declarations from this file (part).
        if (uri == declaration.fileUri) {
          // [distance] will always be non-negative as we ensure [token] is
          // always at the beginning of the declaration. The minimum distance
          // will often be larger than 0, for example, in a class declaration
          // where [token] will point to `abstract` or `class`, but the
          // declaration's offset points to the name of the class.
          int distance = declaration.charOffset - offset;
          if (distance >= 0) {
            if (minDistance == -1 || distance < minDistance) {
              minDistance = distance;
              nearestDeclaration = declaration;
            }
          }
        }
        declaration = declaration.next;
      } while (declaration != null);
      return nearestDeclaration;
    }
  }

  void checkBuilder(Token token, Declaration declaration, Object name) {
    if (declaration == null) {
      internalProblem(templateInternalProblemNotFound.withArguments("$name"),
          token.charOffset, uri);
    }
    if (uri != declaration.fileUri) {
      unexpected("$uri", "${declaration.fileUri}", declaration.charOffset,
          declaration.fileUri);
    }
  }

  @override
  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled: false, List<LocatedMessage> context}) {
    library.addProblem(message, charOffset, length, uri,
        wasHandled: wasHandled, context: context);
  }

  @override
  void debugEvent(String name) {
    // printEvent('DietListener: $name');
  }

  /// If the [metadata] is not `null`, return the parsed metadata [Expression]s.
  /// Otherwise, return `null`.
  List<Expression> parseMetadata(
      ModifierBuilder builder, Token metadata, TreeNode parent) {
    if (metadata != null) {
      var listener = createListener(builder, memberScope, false);
      var parser = new Parser(listener);
      parser.parseMetadataStar(parser.syntheticPreviousToken(metadata));
      return listener.finishMetadata(parent);
    }
    return null;
  }

  /// Returns [Token] found between [start] (inclusive) and [end]
  /// (non-inclusive) that has its [Token.charOffset] equal to [offset].  If
  /// there is no such token, null is returned.
  Token tokenForOffset(Token start, Token end, int offset) {
    if (offset < start.charOffset || offset >= end.charOffset) {
      return null;
    }
    while (start != end) {
      if (offset == start.charOffset) {
        return start;
      }
      start = start.next;
    }
    return null;
  }

  /// Returns list of [Token]s found between [start] (inclusive) and [end]
  /// (non-inclusive) that correspond to [offsets].  If there's no token between
  /// [start] and [end] for the given offset, the corresponding item in the
  /// resulting list is set to null.  [offsets] are assumed to be in ascending
  /// order.
  List<Token> tokensForOffsets(Token start, Token end, List<int> offsets) {
    List<Token> result =
        new List<Token>.filled(offsets.length, null, growable: false);
    for (int i = 0; start != end && i < offsets.length;) {
      int offset = offsets[i];
      if (offset < start.charOffset) {
        ++i;
      } else if (offset == start.charOffset) {
        result[i] = start;
        start = start.next;
      } else {
        start = start.next;
      }
    }
    return result;
  }

  @override
  bool isIgnoredError(Code code, Token token) {
    return isIgnoredParserError(code, token) ||
        super.isIgnoredError(code, token);
  }
}
