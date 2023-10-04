// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.diet_listener;

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show
        Assert,
        ConstructorReferenceContext,
        DeclarationKind,
        IdentifierContext,
        MemberKind,
        Parser,
        optional;
import 'package:_fe_analyzer_shared/src/parser/quote.dart' show unescapeString;
import 'package:_fe_analyzer_shared/src/parser/stack_listener.dart'
    show FixedNullableList, NullValues, ParserRecovery;
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:_fe_analyzer_shared/src/util/value_kind.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;

import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/modifier_builder.dart';
import '../builder/type_builder.dart';
import '../constant_context.dart' show ConstantContext;
import '../crash.dart' show Crash;
import '../fasta_codes.dart'
    show
        Code,
        LocatedMessage,
        Message,
        messageExpectedBlockToSkip,
        templateInternalProblemNotFound;
import '../identifiers.dart'
    show Identifier, OperatorIdentifier, QualifiedName, SimpleIdentifier;
import '../ignored_parser_errors.dart' show isIgnoredParserError;
import '../kernel/benchmarker.dart' show BenchmarkSubdivides, Benchmarker;
import '../kernel/body_builder.dart' show BodyBuilder, FormalParameters;
import '../kernel/body_builder_context.dart';
import '../operator.dart';
import '../problems.dart'
    show DebugAbort, internalProblem, unexpected, unhandled;
import '../scope.dart';
import '../source/value_kinds.dart';
import '../type_inference/type_inference_engine.dart'
    show InferenceDataForTesting, TypeInferenceEngine;
import '../type_inference/type_inferrer.dart' show TypeInferrer;
import 'diet_parser.dart';
import 'source_class_builder.dart';
import 'source_constructor_builder.dart';
import 'source_enum_builder.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_field_builder.dart';
import 'source_function_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_type_alias_builder.dart';
import 'stack_listener_impl.dart';

class DietListener extends StackListenerImpl {
  @override
  final SourceLibraryBuilder libraryBuilder;

  final ClassHierarchy hierarchy;

  final CoreTypes coreTypes;

  final bool enableNative;

  final bool stringExpectedAfterNative;

  final TypeInferenceEngine typeInferenceEngine;

  int importExportDirectiveIndex = 0;
  int partDirectiveIndex = 0;

  DeclarationBuilder? _currentDeclaration;
  ClassBuilder? _currentClass;
  bool _inRedirectingFactory = false;

  bool currentClassIsParserRecovery = false;

  /// For top-level declarations, this is the library scope. For class members,
  /// this is the instance scope of [currentDeclaration].
  Scope memberScope;

  @override
  Uri uri;

  final Benchmarker? _benchmarker;

  DietListener(SourceLibraryBuilder library, this.hierarchy, this.coreTypes,
      this.typeInferenceEngine)
      : libraryBuilder = library,
        uri = library.fileUri,
        memberScope = library.scope,
        enableNative =
            library.loader.target.backendTarget.enableNative(library.importUri),
        stringExpectedAfterNative =
            library.loader.target.backendTarget.nativeExtensionExpectsString,
        _benchmarker = library.loader.target.benchmarker;

  DeclarationBuilder? get currentDeclaration => _currentDeclaration;

  void set currentDeclaration(DeclarationBuilder? builder) {
    if (builder == null) {
      _currentClass = _currentDeclaration = null;
    } else {
      _currentDeclaration = builder;
      _currentClass = builder is ClassBuilder ? builder : null;
    }
  }

  ClassBuilder? get currentClass => _currentClass;

  @override
  void endMetadataStar(int count) {
    assert(checkState(null, repeatedKind(ValueKinds.Token, count)));
    debugEvent("MetadataStar");
    if (count > 0) {
      discard(count - 1);
      push(pop(NullValues.Token) ?? NullValues.Token);
    } else {
      push(NullValues.Token);
    }
  }

  @override
  void endMetadata(Token beginToken, Token? periodBeforeName, Token endToken) {
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
  void handleNoTypeNameInConstructorReference(Token token) {
    debugEvent("NoTypeNameInConstructorReference");
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
  void handleType(Token beginToken, Token? questionMark) {
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
  void handleNamedArgument(Token colon) {
    debugEvent("NamedArgument");
    pop(); // Named argument name.
  }

  @override
  void handleNamedRecordField(Token colon) {
    debugEvent("NamedRecordField");
    pop(); // Named record field name.
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
  void handleEnumWithClause(Token withKeyword) {
    debugEvent("EnumWithClause");
  }

  @override
  void handleEnumNoWithClause() {
    debugEvent("EnumNoWithClause");
  }

  @override
  void handleMixinWithClause(Token withKeyword) {
    debugEvent("MixinWithClause");
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    debugEvent("Arguments");
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
  void endRecordType(
      Token leftBracket, Token? questionMark, int count, bool hasNamedFields) {
    // TODO: Implement record type.
    debugEvent("RecordType");
  }

  @override
  void endRecordTypeNamedFields(int count, Token leftBracket) {
    // TODO: Implement record type named fields.
    debugEvent("RecordTypeNamedFields");
  }

  @override
  void endRecordTypeEntry() {
    // TODO: Implement record type entry.
    debugEvent("RecordTypeEntry");

    pop(); // String - name of field - or null.
    pop(); // Token - start of metadata (@) - or null.
  }

  @override
  void endFunctionType(Token functionToken, Token? questionMark) {
    debugEvent("FunctionType");
    discard(1);
  }

  @override
  void endTypedef(Token typedefKeyword, Token? equals, Token endToken) {
    assert(checkState(typedefKeyword, [
      if (equals == null) ValueKinds.Token,
      /* name */ ValueKinds.IdentifierOrParserRecovery,
      /* metadata token */ ValueKinds.TokenOrNull,
    ]));
    debugEvent("FunctionTypeAlias");

    if (equals == null) pop(); // endToken
    Object? name = pop();
    // Metadata is handled in [SourceTypeAliasBuilder.buildOutlineExpressions].
    pop(); // metadata
    checkEmpty(typedefKeyword.charOffset);
    if (name is ParserRecovery) return;

    Identifier identifier = name as Identifier;
    Builder? typedefBuilder = lookupBuilder(
        /*getOrSet*/ null, identifier.name, identifier.nameOffset);
    if (typedefBuilder is SourceTypeAliasBuilder) {
      TypeBuilder? type = typedefBuilder.type;
      if (type is FunctionTypeBuilder) {
        List<ParameterBuilder>? formals = type.formals;
        if (formals != null) {
          for (int i = 0; i < formals.length; ++i) {
            ParameterBuilder formal = formals[i];
            List<MetadataBuilder>? metadata = formal.metadata;
            if (metadata != null && metadata.length > 0) {
              // [parseMetadata] is using [Parser.parseMetadataStar] under the
              // hood, so we only need the offset of the first annotation.
              Token metadataToken = tokenForOffset(
                  typedefKeyword, endToken, metadata[0].charOffset)!;
              parseMetadata(typedefBuilder.bodyBuilderContext, typedefBuilder,
                  metadataToken, null)!;
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
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    debugEvent("Fields");
    buildFields(count, beginToken, false);
  }

  @override
  void handleAsyncModifier(Token? asyncToken, Token? starToken) {
    debugEvent("AsyncModifier");
  }

  @override
  void endTopLevelMethod(Token beginToken, Token? getOrSet, Token endToken) {
    assert(checkState(beginToken, [
      /* bodyToken */ ValueKinds.Token,
      /* name */ ValueKinds.IdentifierOrParserRecovery,
      /* metadata token */ ValueKinds.TokenOrNull,
    ]));
    debugEvent("TopLevelMethod");
    Token bodyToken = pop() as Token;
    Object? name = pop();
    Token? metadata = pop() as Token?;
    checkEmpty(beginToken.charOffset);
    if (name is ParserRecovery) return;

    Identifier identifier = name as Identifier;
    final BodyBuilder listener = createFunctionListener(
        lookupBuilder(getOrSet, identifier.name, identifier.nameOffset)
            as SourceFunctionBuilderImpl);
    buildFunctionBody(listener, bodyToken, metadata, MemberKind.TopLevelMethod);
  }

  @override
  void handleNoFunctionBody(Token token) {
    debugEvent("NoFunctionBody");
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
  void handleIdentifier(Token token, IdentifierContext context) {
    debugEvent("handleIdentifier");
    if (!token.isSynthetic) {
      push(new SimpleIdentifier(token));
    } else {
      // This comes from a synthetic token which is inserted by the parser in
      // an attempt to recover.  This almost always means that the parser has
      // gotten very confused and we need to ignore the results.
      push(new ParserRecovery(token.charOffset));
    }
  }

  @override
  void handleQualified(Token period) {
    assert(checkState(period, [
      /*suffix*/ ValueKinds.IdentifierOrParserRecovery,
      /*prefix*/ ValueKinds.IdentifierOrParserRecovery,
    ]));
    debugEvent("handleQualified");
    Object? suffix = pop();
    Object? prefix = pop();
    if (prefix is ParserRecovery) {
      push(prefix);
    } else if (suffix is ParserRecovery) {
      push(suffix);
    } else {
      Identifier prefixIdentifier = prefix as Identifier;
      Identifier suffixIdentifier = suffix as Identifier;
      push(new QualifiedName(prefixIdentifier, suffixIdentifier.token));
    }
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon, bool hasName) {
    debugEvent("endLibraryName");
    if (hasName) {
      pop(); // Name.
    }
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
  void endConditionalUri(Token ifKeyword, Token leftParen, Token? equalSign) {
    debugEvent("ConditionalUri");
  }

  @override
  void endConditionalUris(int count) {
    debugEvent("ConditionalUris");
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    debugEvent("OperatorName");
    push(new OperatorIdentifier(token));
  }

  @override
  void handleInvalidOperatorName(Token operatorKeyword, Token token) {
    debugEvent("InvalidOperatorName");
    push(new SimpleIdentifier(token));
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
  void handleImportPrefix(Token? deferredKeyword, Token? asKeyword) {
    debugEvent("ImportPrefix");
    pushIfNull(asKeyword, NullValues.Prefix);
  }

  @override
  void endImport(Token importKeyword, Token? augmentToken, Token? semicolon) {
    debugEvent("Import");
    Object? name = pop(NullValues.Prefix);

    Token? metadata = pop() as Token?;
    checkEmpty(importKeyword.charOffset);
    if (name is ParserRecovery) return;

    // Native imports must be skipped because they aren't assigned corresponding
    // LibraryDependency nodes.
    Token importUriToken = augmentToken?.next ?? importKeyword.next!;
    String importUri =
        unescapeString(importUriToken.lexeme, importUriToken, this);
    if (importUri.startsWith("dart-ext:")) return;

    Library libraryNode = libraryBuilder.library;
    LibraryDependency dependency =
        libraryNode.dependencies[importExportDirectiveIndex++];
    parseMetadata(libraryBuilder.bodyBuilderContext, libraryBuilder, metadata,
        dependency);
  }

  @override
  void handleRecoverImport(Token? semicolon) {
    pop(NullValues.Prefix);
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    debugEvent("Export");

    Token? metadata = pop() as Token?;
    Library libraryNode = libraryBuilder.library;
    LibraryDependency dependency =
        libraryNode.dependencies[importExportDirectiveIndex++];
    parseMetadata(libraryBuilder.bodyBuilderContext, libraryBuilder, metadata,
        dependency);
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    debugEvent("Part");

    Token? metadata = pop() as Token?;
    Library libraryNode = libraryBuilder.library;
    if (libraryNode.parts.length > partDirectiveIndex) {
      // If partDirectiveIndex >= libraryNode.parts.length we are in a case of
      // on part having other parts. An error has already been issued.
      // Don't try to parse metadata into other parts that have nothing to do
      // with the one this keyword is talking about.
      LibraryPart part = libraryNode.parts[partDirectiveIndex++];
      parseMetadata(
          libraryBuilder.bodyBuilderContext, libraryBuilder, metadata, part);
    }
  }

  @override
  void beginTypeVariable(Token token) {
    debugEvent("beginTypeVariable");
    discard(2); // Name and metadata.
  }

  @override
  void endTypeVariable(
      Token token, int index, Token? extendsOrSuper, Token? variance) {
    debugEvent("endTypeVariable");
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    debugEvent("TypeVariables");
  }

  @override
  void endConstructorReference(Token start, Token? periodBeforeName,
      Token endToken, ConstructorReferenceContext constructorReferenceContext) {
    debugEvent("ConstructorReference");
    popIfNotNull(periodBeforeName);
  }

  @override
  void endClassFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    assert(checkState(beginToken, [
      /* bodyToken */ ValueKinds.Token,
      /* name */ ValueKinds.IdentifierOrQualifiedNameOrOperatorOrParserRecovery,
      /* metadata token */ ValueKinds.TokenOrNull,
    ]));
    debugEvent("ClassFactoryMethod");
    Token bodyToken = pop() as Token;
    Object? name = pop();
    Token? metadata = pop() as Token?;
    checkEmpty(beginToken.charOffset);
    if (name is ParserRecovery || currentClassIsParserRecovery) return;

    Identifier identifier = name as Identifier;
    SourceFunctionBuilderImpl builder = lookupConstructor(
            _getConstructorName(identifier), identifier.qualifierOffset)
        as SourceFunctionBuilderImpl;
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
  void endExtensionConstructor(Token? getOrSet, Token beginToken,
      Token beginParam, Token? beginInitializers, Token endToken) {
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
  void handleConstFactory(Token constKeyword) {
    debugEvent("ConstFactory");
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
  void endClassMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken, false);
  }

  @override
  void endClassConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken, true);
  }

  @override
  void endMixinMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken, false);
  }

  @override
  void endExtensionMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken, false);
  }

  @override
  void endMixinConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken, true);
  }

  void _endClassMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken, bool isConstructor) {
    debugEvent("Method");
    assert(checkState(beginToken, [
      /* bodyToken */ ValueKinds.Token,
      /* name */ ValueKinds.IdentifierOrParserRecovery,
      /* metadata token */ ValueKinds.TokenOrNull,
    ]));
    // TODO(danrubel): Consider removing the beginParam parameter
    // and using bodyToken, but pushing a NullValue on the stack
    // in handleNoFormalParameters rather than the supplied token.
    pop(); // bodyToken
    Object? name = pop();
    Token? metadata = pop() as Token?;
    checkEmpty(beginToken.charOffset);
    if (name is ParserRecovery || currentClassIsParserRecovery) return;
    Identifier identifier = name as Identifier;

    SourceFunctionBuilder builder;
    if (isConstructor) {
      builder = lookupConstructor(
              _getConstructorName(identifier), identifier.qualifierOffset)
          as SourceFunctionBuilder;
    } else {
      String name = identifier.name;
      // TODO(johnniwinther): Find a uniform way to compute this.
      bool hasNoFormals = identical(beginParam.next, beginParam.endGroup);
      if (Operator.subtract == identifier.operator && hasNoFormals) {
        name = Operator.unaryMinus.text;
      }
      Builder? memberBuilder =
          lookupBuilder(getOrSet, name, identifier.nameOffset);
      if (currentClass?.isEnum == true &&
          memberBuilder is SourceFieldBuilder &&
          memberBuilder.name == "values") {
        // This is the case of a method with the name 'values' declared in an
        // Enum. In that case the method is replaced with the synthesized field
        // in the outline building phase, and the error is reported there. At
        // this point we skip the member.
        return;
      }
      builder = memberBuilder as SourceFunctionBuilder;
    }
    buildFunctionBody(
        createFunctionListener(builder),
        beginParam,
        metadata,
        builder.isStatic
            ? MemberKind.StaticMethod
            : MemberKind.NonStaticMethod);
  }

  BodyBuilder createListener(BodyBuilderContext bodyBuilderContext,
      ModifierBuilder builder, Scope memberScope,
      {VariableDeclaration? thisVariable,
      List<TypeParameter>? thisTypeParameters,
      Scope? formalParameterScope,
      InferenceDataForTesting? inferenceDataForTesting}) {
    _benchmarker
        ?.beginSubdivide(BenchmarkSubdivides.diet_listener_createListener);
    // Note: we set thisType regardless of whether we are building a static
    // member, since that provides better error recovery.
    // TODO(johnniwinther): Provide a dummy this on static extension methods
    // for better error recovery?
    InterfaceType? thisType =
        thisVariable == null ? currentDeclaration?.thisType : null;
    TypeInferrer typeInferrer = typeInferenceEngine.createLocalTypeInferrer(
        uri, thisType, libraryBuilder, inferenceDataForTesting);
    ConstantContext constantContext = bodyBuilderContext.constantContext;
    BodyBuilder result = createListenerInternal(
        bodyBuilderContext,
        memberScope,
        formalParameterScope,
        thisVariable,
        thisTypeParameters,
        typeInferrer,
        constantContext);
    _benchmarker?.endSubdivide();
    return result;
  }

  BodyBuilder createListenerInternal(
      BodyBuilderContext bodyBuilderContext,
      Scope memberScope,
      Scope? formalParameterScope,
      VariableDeclaration? thisVariable,
      List<TypeParameter>? thisTypeParameters,
      TypeInferrer typeInferrer,
      ConstantContext constantContext) {
    return new BodyBuilder(
        libraryBuilder: libraryBuilder,
        context: bodyBuilderContext,
        enclosingScope: memberScope,
        formalParameterScope: formalParameterScope,
        hierarchy: hierarchy,
        coreTypes: coreTypes,
        thisVariable: thisVariable,
        thisTypeParameters: thisTypeParameters,
        uri: uri,
        typeInferrer: typeInferrer)
      ..constantContext = constantContext;
  }

  BodyBuilder createFunctionListener(SourceFunctionBuilder builder) {
    final Scope typeParameterScope =
        builder.computeTypeParameterScope(memberScope);
    final Scope formalParameterScope =
        builder.computeFormalParameterScope(typeParameterScope);
    return createListener(
        builder.bodyBuilderContext, builder, typeParameterScope,
        thisVariable: builder.thisVariable,
        thisTypeParameters: builder.thisTypeParameters,
        formalParameterScope: formalParameterScope,
        inferenceDataForTesting: builder.dataForTesting?.inferenceData);
  }

  void buildRedirectingFactoryMethod(Token token,
      SourceFunctionBuilderImpl builder, MemberKind kind, Token? metadata) {
    _benchmarker?.beginSubdivide(
        BenchmarkSubdivides.diet_listener_buildRedirectingFactoryMethod);
    final BodyBuilder listener = createFunctionListener(builder);
    try {
      Parser parser = new Parser(listener,
          useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
          allowPatterns: libraryFeatures.patterns.isEnabled);
      if (metadata != null) {
        parser.parseMetadataStar(parser.syntheticPreviousToken(metadata));
        listener.pop(); // Pops metadata constants.
      }

      token = parser.parseFormalParametersOpt(
          parser.syntheticPreviousToken(token), MemberKind.Factory);
      listener.pop(); // Pops formal parameters.
      listener.finishRedirectingFactoryBody();
      listener.checkEmpty(token.next!.charOffset);
    } on DebugAbort {
      rethrow;
    } catch (e, s) {
      throw new Crash(uri, token.charOffset, e, s);
    }
    _benchmarker?.endSubdivide();
  }

  void buildFields(int count, Token token, bool isTopLevel) {
    assert(checkState(
        token, repeatedKind(ValueKinds.IdentifierOrParserRecovery, count)));

    _benchmarker?.beginSubdivide(BenchmarkSubdivides.diet_listener_buildFields);
    List<Identifier?>? names =
        const FixedNullableList<Identifier>().pop(stack, count);
    Token? metadata = pop() as Token?;
    checkEmpty(token.charOffset);
    if (names == null || currentClassIsParserRecovery) return;

    Identifier first = names.first!;
    SourceFieldBuilder declaration =
        lookupBuilder(/*getOrSet*/ null, first.name, first.nameOffset)
            as SourceFieldBuilder;
    // TODO(paulberry): don't re-parse the field if we've already parsed it
    // for type inference.
    _parseFields(
        createListener(declaration.bodyBuilderContext, declaration, memberScope,
            inferenceDataForTesting: declaration.dataForTesting?.inferenceData),
        token,
        metadata,
        isTopLevel);
    checkEmpty(token.charOffset);
    _benchmarker?.endSubdivide();
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
      Token? commaToken, Token semicolonToken) {
    debugEvent("Assert");
    // Do nothing
  }

  @override
  void beginClassOrMixinOrExtensionBody(DeclarationKind kind, Token token) {
    assert(checkState(token, [
      ValueKinds.Token,
      ValueKinds.IdentifierOrParserRecoveryOrNull,
      ValueKinds.TokenOrNull
    ]));
    debugEvent("beginClassOrMixinBody");
    Token beginToken = pop() as Token;
    Object? name = pop();
    pop(); // Annotation begin token.
    assert(currentDeclaration == null);
    assert(memberScope == libraryBuilder.scope);
    if (name is ParserRecovery) {
      currentClassIsParserRecovery = true;
      return;
    }
    if (name is Identifier) {
      currentDeclaration =
          lookupBuilder(/*getOrSet*/ null, name.name, name.nameOffset)
              as DeclarationBuilder;
    } else {
      currentDeclaration = lookupUnnamedExtensionBuilder(beginToken);
    }
    memberScope = currentDeclaration!.scope;
  }

  @override
  void endClassOrMixinOrExtensionBody(
      DeclarationKind kind, int memberCount, Token beginToken, Token endToken) {
    debugEvent("ClassOrMixinBody");
    currentDeclaration = null;
    currentClassIsParserRecovery = false;
    memberScope = libraryBuilder.scope;
  }

  @override
  void beginClassDeclaration(
      Token begin,
      Token? abstractToken,
      Token? macroToken,
      Token? sealedToken,
      Token? baseToken,
      Token? interfaceToken,
      Token? finalToken,
      Token? augmentToken,
      Token? mixinToken,
      Token name) {
    debugEvent("beginClassDeclaration");
    push(begin);
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    debugEvent("endClassDeclaration");
    checkEmpty(beginToken.charOffset);
  }

  @override
  void beginMixinDeclaration(Token beginToken, Token? augmentToken,
      Token? baseToken, Token mixinKeyword, Token name) {
    debugEvent("beginMixinDeclaration");
    push(mixinKeyword);
  }

  @override
  void endMixinDeclaration(Token beginToken, Token endToken) {
    debugEvent("endMixinDeclaration");
    checkEmpty(beginToken.charOffset);
  }

  @override
  void beginExtensionDeclaration(Token extensionKeyword, Token? nameToken) {
    debugEvent("beginExtensionDeclaration");
    push(nameToken != null
        ? new SimpleIdentifier(nameToken)
        : NullValues.Identifier);
    push(extensionKeyword);
  }

  @override
  void endExtensionDeclaration(Token beginToken, Token extensionKeyword,
      Token onKeyword, Token endToken) {
    debugEvent("endExtensionDeclaration");
    checkEmpty(extensionKeyword.charOffset);
  }

  @override
  void beginExtensionTypeDeclaration(Token extensionKeyword, Token nameToken) {
    debugEvent("beginExtensionTypeDeclaration");
    push(new SimpleIdentifier(nameToken));
    push(extensionKeyword);

    // The current declaration is set in [beginClassOrMixinOrExtensionBody] but
    // for primary constructors we need it before the body so we set it here.
    // TODO(johnniwinther): Normalize the setting of the current declaration.
    assert(currentDeclaration == null);
    assert(memberScope == libraryBuilder.scope);

    currentDeclaration =
        lookupBuilder(/*getOrSet*/ null, nameToken.lexeme, nameToken.charOffset)
            as DeclarationBuilder;
    memberScope = currentDeclaration!.scope;
  }

  @override
  void beginPrimaryConstructor(Token beginToken) {
    debugEvent("beginPrimaryConstructor");
  }

  @override
  void endPrimaryConstructor(
      Token beginToken, Token? constKeyword, bool hasConstructorName) {
    assert(checkState(beginToken, [
      /* formals begin token */ ValueKinds.Token,
      if (hasConstructorName) ValueKinds.IdentifierOrParserRecovery,
    ]));
    debugEvent("endPrimaryConstructor");
    Token formalsToken = pop() as Token; // Pop formals begin token.
    int charOffset = formalsToken.charOffset;
    String constructorName = '';
    if (hasConstructorName) {
      // TODO(johnniwinther): Handle [ParserRecovery].
      Identifier identifier = pop() as Identifier;
      constructorName = identifier.name;
      charOffset = identifier.nameOffset;
    }
    SourceFunctionBuilder builder =
        lookupConstructor(constructorName, charOffset) as SourceFunctionBuilder;
    buildPrimaryConstructor(createFunctionListener(builder), formalsToken);

    // The current declaration is set in [beginClassOrMixinOrExtensionBody],
    // assuming that it is currently `null`, so we reset it here.
    // TODO(johnniwinther): Normalize the setting of the current declaration.
    currentDeclaration = null;
    memberScope = libraryBuilder.scope;
  }

  @override
  void handleNoPrimaryConstructor(Token token, Token? constKeyword) {
    // The current declaration is set in [beginClassOrMixinOrExtensionBody],
    // assuming that it is currently `null`, so we reset it here.
    // TODO(johnniwinther): Normalize the setting of the current declaration.
    currentDeclaration = null;
    memberScope = libraryBuilder.scope;
  }

  @override
  void endExtensionTypeDeclaration(Token beginToken, Token extensionKeyword,
      Token typeKeyword, Token endToken) {
    debugEvent("endExtensionTypeDeclaration");
    checkEmpty(extensionKeyword.charOffset);
  }

  @override
  void beginEnum(Token enumKeyword) {
    assert(checkState(enumKeyword, [ValueKinds.IdentifierOrParserRecovery]));
    debugEvent("Enum");
    Object? name = pop();

    assert(currentDeclaration == null);
    assert(memberScope == libraryBuilder.scope);

    if (name is ParserRecovery) {
      currentClassIsParserRecovery = true;
      return;
    }

    Identifier identifier = name as Identifier;
    currentDeclaration =
        lookupBuilder(/*getOrSet*/ null, identifier.name, identifier.nameOffset)
            as DeclarationBuilder;
    memberScope = currentDeclaration!.scope;
  }

  @override
  void endEnum(Token beginToken, Token enumKeyword, Token leftBrace,
      int memberCount, Token endToken) {
    debugEvent("Enum");
    checkEmpty(enumKeyword.charOffset);

    SourceEnumBuilder? enumBuilder = currentClass as SourceEnumBuilder?;
    if (enumBuilder != null) {
      DeclaredSourceConstructorBuilder? defaultConstructorBuilder =
          enumBuilder.synthesizedDefaultConstructorBuilder;
      if (defaultConstructorBuilder != null) {
        BodyBuilder bodyBuilder =
            createFunctionListener(defaultConstructorBuilder);
        bodyBuilder.finishConstructor(AsyncMarker.Sync, new EmptyStatement(),
            superParametersAsArguments: null);
      }
    }

    currentDeclaration = null;
    memberScope = libraryBuilder.scope;
  }

  @override
  void handleEnumElement(Token beginKeyword) {
    debugEvent("EnumElement");
  }

  @override
  void handleEnumElements(Token elementsEndToken, int elementsCount) {
    debugEvent("EnumElements");
    const FixedNullableList<Object>().pop(stack, elementsCount * 2);
    pop(); // Annotations begin token.
    checkEmpty(elementsEndToken.charOffset);
  }

  @override
  void handleEnumHeader(Token enumKeyword, Token leftBrace) {
    debugEvent("EnumHeader");
  }

  @override
  void endEnumConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken, true);
  }

  @override
  void endEnumMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _endClassMethod(
        getOrSet, beginToken, beginParam, beginInitializers, endToken, false);
  }

  @override
  void endEnumFields(
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    debugEvent("Fields");
    buildFields(count, beginToken, false);
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equals, Token? implementsKeyword, Token endToken) {
    debugEvent("NamedMixinApplication");

    pop(); // Name.
    pop(); // Annotations begin token.
    checkEmpty(beginToken.charOffset);
  }

  AsyncMarker? getAsyncMarker(StackListenerImpl listener) =>
      listener.pop() as AsyncMarker?;

  void buildPrimaryConstructor(BodyBuilder bodyBuilder, Token startToken) {
    _benchmarker?.beginSubdivide(
        BenchmarkSubdivides.diet_listener_buildPrimaryConstructor);
    Token token = startToken;
    try {
      Parser parser = new Parser(bodyBuilder,
          useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
          allowPatterns: libraryFeatures.patterns.isEnabled);
      token = parser.parseFormalParametersOpt(
          parser.syntheticPreviousToken(token), MemberKind.PrimaryConstructor);
      FormalParameters? formals = bodyBuilder.pop() as FormalParameters?;
      bodyBuilder.checkEmpty(token.next!.charOffset);
      bodyBuilder.handleNoInitializers();
      bodyBuilder.checkEmpty(token.charOffset);
      bodyBuilder.finishFunction(formals, AsyncMarker.Sync, null);
      _benchmarker?.endSubdivide();
    } on DebugAbort {
      rethrow;
    } catch (e, s) {
      throw new Crash(uri, token.charOffset, e, s);
    }
  }

  void buildFunctionBody(BodyBuilder bodyBuilder, Token startToken,
      Token? metadata, MemberKind kind) {
    _benchmarker
        ?.beginSubdivide(BenchmarkSubdivides.diet_listener_buildFunctionBody);
    Token token = startToken;
    try {
      Parser parser = new Parser(bodyBuilder,
          useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
          allowPatterns: libraryFeatures.patterns.isEnabled);
      if (metadata != null) {
        parser.parseMetadataStar(parser.syntheticPreviousToken(metadata));
        bodyBuilder.pop(); // Annotations.
      }
      token = parser.parseFormalParametersOpt(
          parser.syntheticPreviousToken(token), kind);
      FormalParameters? formals = bodyBuilder.pop() as FormalParameters?;
      bodyBuilder.checkEmpty(token.next!.charOffset);
      token = parser.parseInitializersOpt(token);
      token = parser.parseAsyncModifierOpt(token);
      AsyncMarker asyncModifier =
          getAsyncMarker(bodyBuilder) ?? AsyncMarker.Sync;
      if (kind == MemberKind.Factory && asyncModifier != AsyncMarker.Sync) {
        // Factories has to be sync. The parser issued an error.
        // Recover to sync.
        asyncModifier = AsyncMarker.Sync;
      }
      bool isExpression = false;
      bool allowAbstract = asyncModifier == AsyncMarker.Sync;

      _benchmarker?.beginSubdivide(BenchmarkSubdivides
          .diet_listener_buildFunctionBody_parseFunctionBody);
      parser.parseFunctionBody(token, isExpression, allowAbstract);
      Statement? body = bodyBuilder.pop() as Statement?;
      _benchmarker?.endSubdivide();
      bodyBuilder.checkEmpty(token.charOffset);
      bodyBuilder.finishFunction(formals, asyncModifier, body);
      _benchmarker?.endSubdivide();
    } on DebugAbort {
      rethrow;
    } catch (e, s) {
      throw new Crash(uri, token.charOffset, e, s);
    }
  }

  void _parseFields(BodyBuilder bodyBuilder, Token startToken, Token? metadata,
      bool isTopLevel) {
    Token token = startToken;
    Parser parser = new Parser(bodyBuilder,
        useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
        allowPatterns: libraryFeatures.patterns.isEnabled);
    if (isTopLevel) {
      token = parser.parseTopLevelMember(metadata ?? token);
    } else {
      // TODO(danrubel): disambiguate between class/mixin/extension members
      token = parser.parseClassMember(metadata ?? token, null).next!;
    }
    bodyBuilder.finishFields();

    bodyBuilder.checkEmpty(token.charOffset);
  }

  Builder? lookupBuilder(Token? getOrSet, String name, int charOffset) {
    // TODO(ahe): Can I move this to Scope or ScopeBuilder?
    Builder? declaration;
    DeclarationBuilder? currentDeclaration = this.currentDeclaration;
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
      declaration = libraryBuilder.scope.lookupLocalMember(name, setter: false);
    }
    declaration = handleDuplicatedName(declaration, charOffset);
    checkBuilder(declaration, name, charOffset);
    return declaration;
  }

  ExtensionBuilder? lookupUnnamedExtensionBuilder(Token extensionToken) {
    return libraryBuilder.scope
        .lookupLocalUnnamedExtension(uri, extensionToken.charOffset);
  }

  String _getConstructorName(Identifier nameOrQualified) {
    String suffix;
    if (nameOrQualified is QualifiedName) {
      suffix = nameOrQualified.name;
    } else {
      suffix = nameOrQualified.name == currentDeclaration!.name
          ? ""
          : nameOrQualified.name;
    }
    return suffix;
  }

  Builder? lookupConstructor(String constructorName, int charOffset) {
    assert(currentDeclaration != null);
    assert(currentDeclaration is SourceClassBuilder ||
        currentDeclaration is SourceExtensionTypeDeclarationBuilder);
    Builder? declaration;
    if (libraryFeatures.constructorTearoffs.isEnabled) {
      constructorName = constructorName == "new" ? "" : constructorName;
    }
    declaration =
        currentDeclaration!.constructorScope.lookupLocalMember(constructorName);
    declaration = handleDuplicatedName(declaration, charOffset);
    checkBuilder(
        declaration,
        constructorName.isEmpty
            ? currentDeclaration!.name
            : '${currentDeclaration!.name}.$constructorName',
        charOffset);
    return declaration;
  }

  Builder? handleDuplicatedName(Builder? declaration, int charOffset) {
    if (declaration == null) {
      return null;
    } else {
      Builder? originalDeclaration = declaration;
      while (declaration != null) {
        if (declaration.charOffset == charOffset &&
            declaration.fileUri == uri) {
          return declaration;
        }
        declaration = declaration.next;
      }
      assert(false, () {
        StringBuffer sb = new StringBuffer();
        sb.write("Unable to find declaration for ");
        sb.write(originalDeclaration);
        sb.write(" @ ");
        sb.write(charOffset);
        sb.write(" in {");
        String comma = '';
        Builder? current = originalDeclaration;
        while (current != null) {
          sb.write(comma);
          sb.write(current.charOffset);
          current = current.next;
          comma = ', ';
        }
        sb.write("}.");
        return sb.toString();
      }());
      return originalDeclaration;
    }
  }

  void checkBuilder(Builder? declaration, String name, int charOffset) {
    if (declaration == null) {
      internalProblem(
          templateInternalProblemNotFound.withArguments(name), charOffset, uri);
    }
    if (uri != declaration.fileUri) {
      unexpected("$uri", "${declaration.fileUri}", declaration.charOffset,
          declaration.fileUri);
    }
  }

  @override
  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled = false, List<LocatedMessage>? context}) {
    libraryBuilder.addProblem(message, charOffset, length, uri,
        wasHandled: wasHandled, context: context);
  }

  @override
  void debugEvent(String name) {
    // printEvent('DietListener: $name');
  }

  /// If the [metadata] is not `null`, return the parsed metadata [Expression]s.
  /// Otherwise, return `null`.
  List<Expression>? parseMetadata(BodyBuilderContext bodyBuilderContext,
      ModifierBuilder builder, Token? metadata, Annotatable? parent) {
    if (metadata != null) {
      StackListenerImpl listener =
          createListener(bodyBuilderContext, builder, memberScope);
      Parser parser = new Parser(listener,
          useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
          allowPatterns: libraryFeatures.patterns.isEnabled);
      parser.parseMetadataStar(parser.syntheticPreviousToken(metadata));
      return listener.finishMetadata(parent);
    }
    return null;
  }

  /// Returns [Token] found between [start] (inclusive) and [end]
  /// (non-inclusive) that has its [Token.charOffset] equal to [offset].  If
  /// there is no such token, null is returned.
  Token? tokenForOffset(Token start, Token end, int offset) {
    if (offset < start.charOffset || offset >= end.charOffset) {
      return null;
    }
    while (start != end) {
      if (offset == start.charOffset) {
        return start;
      }
      start = start.next!;
    }
    return null;
  }

  /// Returns list of [Token]s found between [start] (inclusive) and [end]
  /// (non-inclusive) that correspond to [offsets].  If there's no token between
  /// [start] and [end] for the given offset, the corresponding item in the
  /// resulting list is set to null.  [offsets] are assumed to be in ascending
  /// order.
  List<Token?> tokensForOffsets(Token start, Token end, List<int> offsets) {
    List<Token?> result =
        new List<Token?>.filled(offsets.length, null, growable: false);
    for (int i = 0; start != end && i < offsets.length;) {
      int offset = offsets[i];
      if (offset < start.charOffset) {
        ++i;
      } else if (offset == start.charOffset) {
        result[i] = start;
        start = start.next!;
      } else {
        start = start.next!;
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
