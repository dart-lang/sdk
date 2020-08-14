// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.diet_listener;

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show Assert, DeclarationKind, MemberKind, Parser, optional;

import 'package:_fe_analyzer_shared/src/parser/quote.dart' show unescapeString;

import 'package:_fe_analyzer_shared/src/parser/stack_listener.dart'
    show FixedNullableList, NullValue, ParserRecovery;

import 'package:_fe_analyzer_shared/src/parser/value_kind.dart';

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import 'package:kernel/ast.dart'
    show
        AsyncMarker,
        Expression,
        InterfaceType,
        Library,
        LibraryDependency,
        LibraryPart,
        TreeNode,
        TypeParameter,
        VariableDeclaration;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/declaration_builder.dart';
import '../builder/field_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_builder.dart';
import '../builder/function_type_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/modifier_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';

import '../identifiers.dart' show QualifiedName;

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

import '../kernel/body_builder.dart' show BodyBuilder;

import '../problems.dart'
    show DebugAbort, internalProblem, unexpected, unhandled;

import '../scope.dart';

import '../source/value_kinds.dart';

import '../type_inference/type_inference_engine.dart'
    show InferenceDataForTesting, TypeInferenceEngine;

import '../type_inference/type_inferrer.dart' show TypeInferrer;

import 'source_library_builder.dart' show SourceLibraryBuilder;

import 'stack_listener_impl.dart';

class DietListener extends StackListenerImpl {
  final SourceLibraryBuilder libraryBuilder;

  final ClassHierarchy hierarchy;

  final CoreTypes coreTypes;

  final bool enableNative;

  final bool stringExpectedAfterNative;

  final TypeInferenceEngine typeInferenceEngine;

  int importExportDirectiveIndex = 0;
  int partDirectiveIndex = 0;

  DeclarationBuilder _currentDeclaration;
  ClassBuilder _currentClass;
  bool _inRedirectingFactory = false;

  bool currentClassIsParserRecovery = false;

  /// Counter used for naming unnamed extension declarations.
  int unnamedExtensionCounter = 0;

  /// For top-level declarations, this is the library scope. For class members,
  /// this is the instance scope of [currentDeclaration].
  Scope memberScope;

  @override
  Uri uri;

  DietListener(SourceLibraryBuilder library, this.hierarchy, this.coreTypes,
      this.typeInferenceEngine)
      : libraryBuilder = library,
        uri = library.fileUri,
        memberScope = library.scope,
        enableNative =
            library.loader.target.backendTarget.enableNative(library.importUri),
        stringExpectedAfterNative =
            library.loader.target.backendTarget.nativeExtensionExpectsString;

  DeclarationBuilder get currentDeclaration => _currentDeclaration;

  void set currentDeclaration(TypeDeclarationBuilder builder) {
    if (builder == null) {
      _currentClass = _currentDeclaration = null;
    } else {
      _currentDeclaration = builder;
      _currentClass = builder is ClassBuilder ? builder : null;
    }
  }

  ClassBuilder get currentClass => _currentClass;

  @override
  void endMetadataStar(int count) {
    assert(checkState(null, repeatedKinds(ValueKinds.Token, count)));
    debugEvent("MetadataStar");
    if (count > 0) {
      discard(count - 1);
      push(pop(NullValue.Token) ?? NullValue.Token);
    } else {
      push(NullValue.Token);
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

    TypeAliasBuilder typedefBuilder = lookupBuilder(typedefKeyword, null, name);
    parseMetadata(typedefBuilder, metadata, typedefBuilder.typedef);
    if (typedefBuilder is TypeAliasBuilder) {
      TypeBuilder type = typedefBuilder.type;
      if (type is FunctionTypeBuilder) {
        List<FormalParameterBuilder> formals = type.formals;
        if (formals != null) {
          for (int i = 0; i < formals.length; ++i) {
            FormalParameterBuilder formal = formals[i];
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
                    typedefBuilder.typedef.positionalParameters[i];
                for (Expression annotation in annotations) {
                  parameter.addAnnotation(annotation);
                }
              } else {
                for (VariableDeclaration named
                    in typedefBuilder.typedef.namedParameters) {
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
  void endClassFields(
      Token abstractToken,
      Token externalToken,
      Token staticToken,
      Token covariantToken,
      Token lateToken,
      Token varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
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

    final StackListenerImpl listener =
        createFunctionListener(lookupBuilder(beginToken, getOrSet, name));
    buildFunctionBody(listener, bodyToken, metadata, MemberKind.TopLevelMethod);
  }

  @override
  void handleNoFunctionBody(Token token) {
    debugEvent("NoFunctionBody");
  }

  @override
  void endTopLevelFields(
      Token externalToken,
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
  void handleVoidKeywordWithTypeArguments(Token token) {
    debugEvent("VoidKeywordWithTypeArguments");
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
    assert(checkState(period, [
      /*suffix*/ ValueKinds.NameOrParserRecovery,
      /*prefix*/ unionOfKinds([
        ValueKinds.Name,
        ValueKinds.Generator,
        ValueKinds.ParserRecovery,
        ValueKinds.QualifiedName,
      ]),
    ]));
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
    pop(); // Name.
    pop(); // Annotations.
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
  void handleStringJuxtaposition(Token startToken, int literalCount) {
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

    Library libraryNode = libraryBuilder.library;
    LibraryDependency dependency =
        libraryNode.dependencies[importExportDirectiveIndex++];
    parseMetadata(libraryBuilder, metadata, dependency);
  }

  @override
  void handleRecoverImport(Token semicolon) {
    pop(NullValue.Prefix);
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    debugEvent("Export");

    Token metadata = pop();
    Library libraryNode = libraryBuilder.library;
    LibraryDependency dependency =
        libraryNode.dependencies[importExportDirectiveIndex++];
    parseMetadata(libraryBuilder, metadata, dependency);
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    debugEvent("Part");

    Token metadata = pop();
    Library libraryNode = libraryBuilder.library;
    if (libraryNode.parts.length > partDirectiveIndex) {
      // If partDirectiveIndex >= libraryNode.parts.length we are in a case of
      // on part having other parts. An error has already been issued.
      // Don't try to parse metadata into other parts that have nothing to do
      // with the one this keyword is talking about.
      LibraryPart part = libraryNode.parts[partDirectiveIndex++];
      parseMetadata(libraryBuilder, metadata, part);
    }
  }

  @override
  void beginTypeVariable(Token token) {
    debugEvent("beginTypeVariable");
    discard(2); // Name and metadata.
  }

  @override
  void endTypeVariable(
      Token token, int index, Token extendsOrSuper, Token variance) {
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
  void endClassFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    debugEvent("ClassFactoryMethod");
    Token bodyToken = pop();
    Object name = pop();
    Token metadata = pop();
    checkEmpty(beginToken.charOffset);
    if (name is ParserRecovery || currentClassIsParserRecovery) return;

    FunctionBuilder builder = lookupConstructor(beginToken, name);
    if (_inRedirectingFactory) {
      buildRedirectingFactoryMethod(
          bodyToken, builder, MemberKind.Factory, metadata);
    } else {
      buildFunctionBody(createFunctionListener(builder), bodyToken, metadata,
          MemberKind.Factory);
    }
  }

  @override
  void endExtensionFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    debugEvent("ExtensionFactoryMethod");
    pop(); // bodyToken
    pop(); // name
    pop(); // metadata
    checkEmpty(beginToken.charOffset);
    // Skip the declaration. An error as already been produced by the parser.
  }

  @override
  void endExtensionConstructor(Token getOrSet, Token beginToken,
      Token beginParam, Token beginInitializers, Token endToken) {
    debugEvent("ExtensionConstructor");
    pop(); // bodyToken
    pop(); // name
    pop(); // metadata
    checkEmpty(beginToken.charOffset);
    // Skip the declaration. An error as already been produced by the parser.
  }

  @override
  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    debugEvent("RedirectingFactoryBody");
    discard(1); // ConstructorReference.
    _inRedirectingFactory = true;
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
  void endClassMethod(Token getOrSet, Token beginToken, Token beginParam,
      Token beginInitializers, Token endToken) {
    _endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken, false);
  }

  @override
  void endClassConstructor(Token getOrSet, Token beginToken, Token beginParam,
      Token beginInitializers, Token endToken) {
    _endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken, true);
  }

  @override
  void endMixinMethod(Token getOrSet, Token beginToken, Token beginParam,
      Token beginInitializers, Token endToken) {
    _endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken, false);
  }

  @override
  void endExtensionMethod(Token getOrSet, Token beginToken, Token beginParam,
      Token beginInitializers, Token endToken) {
    _endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken, false);
  }

  @override
  void endMixinConstructor(Token getOrSet, Token beginToken, Token beginParam,
      Token beginInitializers, Token endToken) {
    _endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken, true);
  }

  void _endClassMethod(Token getOrSet, Token beginToken, Token beginParam,
      Token beginInitializers, Token endToken, bool isConstructor) {
    debugEvent("Method");
    // TODO(danrubel): Consider removing the beginParam parameter
    // and using bodyToken, but pushing a NullValue on the stack
    // in handleNoFormalParameters rather than the supplied token.
    pop(); // bodyToken
    Object name = pop();
    Token metadata = pop();
    checkEmpty(beginToken.charOffset);
    if (name is ParserRecovery || currentClassIsParserRecovery) return;
    FunctionBuilder builder;
    if (isConstructor) {
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

  StackListenerImpl createListener(ModifierBuilder builder, Scope memberScope,
      {bool isDeclarationInstanceMember,
      VariableDeclaration extensionThis,
      List<TypeParameter> extensionTypeParameters,
      Scope formalParameterScope,
      InferenceDataForTesting inferenceDataForTesting}) {
    // Note: we set thisType regardless of whether we are building a static
    // member, since that provides better error recovery.
    // TODO(johnniwinther): Provide a dummy this on static extension methods
    // for better error recovery?
    InterfaceType thisType =
        extensionThis == null ? currentDeclaration?.thisType : null;
    TypeInferrer typeInferrer = typeInferenceEngine?.createLocalTypeInferrer(
        uri, thisType, libraryBuilder, inferenceDataForTesting);
    ConstantContext constantContext = builder.isConstructor && builder.isConst
        ? ConstantContext.inferred
        : ConstantContext.none;
    return createListenerInternal(
        builder,
        memberScope,
        formalParameterScope,
        isDeclarationInstanceMember,
        extensionThis,
        extensionTypeParameters,
        typeInferrer,
        constantContext);
  }

  StackListenerImpl createListenerInternal(
      ModifierBuilder builder,
      Scope memberScope,
      Scope formalParameterScope,
      bool isDeclarationInstanceMember,
      VariableDeclaration extensionThis,
      List<TypeParameter> extensionTypeParameters,
      TypeInferrer typeInferrer,
      ConstantContext constantContext) {
    return new BodyBuilder(
        libraryBuilder: libraryBuilder,
        member: builder,
        enclosingScope: memberScope,
        formalParameterScope: formalParameterScope,
        hierarchy: hierarchy,
        coreTypes: coreTypes,
        declarationBuilder: currentDeclaration,
        isDeclarationInstanceMember: isDeclarationInstanceMember,
        extensionThis: extensionThis,
        extensionTypeParameters: extensionTypeParameters,
        uri: uri,
        typeInferrer: typeInferrer)
      ..constantContext = constantContext;
  }

  StackListenerImpl createFunctionListener(FunctionBuilderImpl builder) {
    final Scope typeParameterScope =
        builder.computeTypeParameterScope(memberScope);
    final Scope formalParameterScope =
        builder.computeFormalParameterScope(typeParameterScope);
    assert(typeParameterScope != null);
    assert(formalParameterScope != null);
    return createListener(builder, typeParameterScope,
        isDeclarationInstanceMember: builder.isDeclarationInstanceMember,
        extensionThis: builder.extensionThis,
        extensionTypeParameters: builder.extensionTypeParameters,
        formalParameterScope: formalParameterScope,
        inferenceDataForTesting: builder.dataForTesting?.inferenceData);
  }

  void buildRedirectingFactoryMethod(
      Token token, FunctionBuilder builder, MemberKind kind, Token metadata) {
    final StackListenerImpl listener = createFunctionListener(builder);
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

    SourceFieldBuilder declaration = lookupBuilder(token, null, names.first);
    // TODO(paulberry): don't re-parse the field if we've already parsed it
    // for type inference.
    parseFields(
        createListener(declaration, memberScope,
            isDeclarationInstanceMember:
                declaration.isDeclarationInstanceMember,
            inferenceDataForTesting: declaration.dataForTesting?.inferenceData),
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
    _inRedirectingFactory = false;
  }

  @override
  void endAssert(Token assertKeyword, Assert kind, Token leftParenthesis,
      Token commaToken, Token semicolonToken) {
    debugEvent("Assert");
    // Do nothing
  }

  @override
  void beginClassOrMixinBody(DeclarationKind kind, Token token) {
    assert(checkState(token, [
      ValueKinds.Token,
      ValueKinds.NameOrParserRecovery,
      ValueKinds.TokenOrNull
    ]));
    debugEvent("beginClassOrMixinBody");
    Token beginToken = pop();
    Object name = pop();
    pop(); // Annotation begin token.
    assert(currentDeclaration == null);
    assert(memberScope == libraryBuilder.scope);
    if (name is ParserRecovery) {
      currentClassIsParserRecovery = true;
      return;
    }
    currentDeclaration = lookupBuilder(beginToken, null, name);
    memberScope = currentDeclaration.scope;
  }

  @override
  void endClassOrMixinBody(
      DeclarationKind kind, int memberCount, Token beginToken, Token endToken) {
    debugEvent("ClassOrMixinBody");
    currentDeclaration = null;
    currentClassIsParserRecovery = false;
    memberScope = libraryBuilder.scope;
  }

  @override
  void beginClassDeclaration(Token begin, Token abstractToken, Token name) {
    debugEvent("beginClassDeclaration");
    push(begin);
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    debugEvent("endClassDeclaration");
    checkEmpty(beginToken.charOffset);
  }

  @override
  void beginMixinDeclaration(Token mixinKeyword, Token name) {
    debugEvent("beginMixinDeclaration");
    push(mixinKeyword);
  }

  @override
  void endMixinDeclaration(Token mixinKeyword, Token endToken) {
    debugEvent("endMixinDeclaration");
    checkEmpty(mixinKeyword.charOffset);
  }

  @override
  void beginExtensionDeclaration(Token extensionKeyword, Token nameToken) {
    debugEvent("beginExtensionDeclaration");
    String name = nameToken?.lexeme ??
        // Synthesized name used internally.
        '_extension#${unnamedExtensionCounter++}';
    push(name);
    push(extensionKeyword);
  }

  @override
  void endExtensionDeclaration(
      Token extensionKeyword, Token onKeyword, Token endToken) {
    debugEvent("endExtensionDeclaration");
    checkEmpty(extensionKeyword.charOffset);
  }

  @override
  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    debugEvent("Enum");
    const FixedNullableList<Object>().pop(stack, count * 2);
    pop(); // Name.
    pop(); // Annotations begin token.
    checkEmpty(enumKeyword.charOffset);
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equals, Token implementsKeyword, Token endToken) {
    debugEvent("NamedMixinApplication");

    pop(); // Name.
    pop(); // Annotations begin token.
    checkEmpty(beginToken.charOffset);
  }

  AsyncMarker getAsyncMarker(StackListenerImpl listener) => listener.pop();

  /// Invokes the listener's [finishFunction] method.
  ///
  /// This is a separate method so that it may be overridden by a derived class
  /// if more computation must be done before finishing the function.
  void listenerFinishFunction(
      StackListenerImpl listener,
      Token token,
      MemberKind kind,
      dynamic formals,
      AsyncMarker asyncModifier,
      dynamic body) {
    listener.finishFunction(formals, asyncModifier, body);
  }

  /// Invokes the listener's [finishFields] method.
  ///
  /// This is a separate method so that it may be overridden by a derived class
  /// if more computation must be done before finishing the function.
  void listenerFinishFields(StackListenerImpl listener, Token startToken,
      Token metadata, bool isTopLevel) {
    listener.finishFields();
  }

  void buildFunctionBody(StackListenerImpl listener, Token startToken,
      Token metadata, MemberKind kind) {
    Token token = startToken;
    try {
      Parser parser = new Parser(listener);
      if (metadata != null) {
        parser.parseMetadataStar(parser.syntheticPreviousToken(metadata));
        listener.pop(); // Annotations.
      }
      token = parser.parseFormalParametersOpt(
          parser.syntheticPreviousToken(token), kind);
      Object formals = listener.pop();
      listener.checkEmpty(token.next.charOffset);
      token = parser.parseInitializersOpt(token);
      token = parser.parseAsyncModifierOpt(token);
      AsyncMarker asyncModifier = getAsyncMarker(listener) ?? AsyncMarker.Sync;
      if (kind == MemberKind.Factory && asyncModifier != AsyncMarker.Sync) {
        // Factories has to be sync. The parser issued an error.
        // Recover to sync.
        asyncModifier = AsyncMarker.Sync;
      }
      bool isExpression = false;
      bool allowAbstract = asyncModifier == AsyncMarker.Sync;
      parser.parseFunctionBody(token, isExpression, allowAbstract);
      Object body = listener.pop();
      listener.checkEmpty(token.charOffset);
      listenerFinishFunction(
          listener, startToken, kind, formals, asyncModifier, body);
    } on DebugAbort {
      rethrow;
    } catch (e, s) {
      throw new Crash(uri, token.charOffset, e, s);
    }
  }

  void parseFields(StackListenerImpl listener, Token startToken, Token metadata,
      bool isTopLevel) {
    Token token = startToken;
    Parser parser = new Parser(listener);
    if (isTopLevel) {
      token = parser.parseTopLevelMember(metadata ?? token);
    } else {
      // TODO(danrubel): disambiguate between class/mixin/extension members
      token = parser.parseClassMember(metadata ?? token, null).next;
    }
    listenerFinishFields(listener, startToken, metadata, isTopLevel);
    listener.checkEmpty(token.charOffset);
  }

  Builder lookupBuilder(Token token, Token getOrSet, String name) {
    // TODO(ahe): Can I move this to Scope or ScopeBuilder?
    Builder declaration;
    if (currentDeclaration != null) {
      if (uri != currentDeclaration.fileUri) {
        unexpected("$uri", "${currentDeclaration.fileUri}",
            currentDeclaration.charOffset, currentDeclaration.fileUri);
      }

      if (getOrSet != null && optional("set", getOrSet)) {
        declaration =
            currentDeclaration.scope.lookupLocalMember(name, setter: true);
      } else {
        declaration =
            currentDeclaration.scope.lookupLocalMember(name, setter: false);
      }
    } else if (getOrSet != null && optional("set", getOrSet)) {
      declaration = libraryBuilder.scope.lookupLocalMember(name, setter: true);
    } else {
      declaration = libraryBuilder.scopeBuilder[name];
    }
    declaration = handleDuplicatedName(declaration, token);
    checkBuilder(token, declaration, name);
    return declaration;
  }

  Builder lookupConstructor(Token token, Object nameOrQualified) {
    assert(currentClass != null);
    Builder declaration;
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

  Builder handleDuplicatedName(Builder declaration, Token token) {
    int offset = token.charOffset;
    if (declaration?.next == null) {
      return declaration;
    } else {
      Builder nearestDeclaration;
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

  void checkBuilder(Token token, Builder declaration, Object name) {
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
    libraryBuilder.addProblem(message, charOffset, length, uri,
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
      StackListenerImpl listener = createListener(builder, memberScope,
          isDeclarationInstanceMember: false);
      Parser parser = new Parser(listener);
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
  bool isIgnoredError(Code<dynamic> code, Token token) {
    return isIgnoredParserError(code, token) ||
        super.isIgnoredError(code, token);
  }
}
