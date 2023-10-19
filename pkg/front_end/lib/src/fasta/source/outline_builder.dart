// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.outline_builder;

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show
        Assert,
        ConstructorReferenceContext,
        DeclarationHeaderKind,
        DeclarationKind,
        FormalParameterKind,
        IdentifierContext,
        MemberKind,
        lengthOfSpan,
        optional;
import 'package:_fe_analyzer_shared/src/parser/quote.dart' show unescapeString;
import 'package:_fe_analyzer_shared/src/parser/stack_listener.dart'
    show FixedNullableList, NullValues, ParserRecovery;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:_fe_analyzer_shared/src/util/link.dart';
import 'package:_fe_analyzer_shared/src/util/value_kind.dart';
import 'package:kernel/ast.dart'
    show
        AsyncMarker,
        InvalidType,
        Nullability,
        ProcedureKind,
        TreeNode,
        Variance;

import '../../api_prototype/experimental_flags.dart';
import '../../api_prototype/lowering_predicates.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/fixed_type_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/invalid_type_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/mixin_application_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/record_type_builder.dart';
import '../builder/type_builder.dart';
import '../combinator.dart' show CombinatorBuilder;
import '../configuration.dart' show Configuration;
import '../fasta_codes.dart';
import '../identifiers.dart'
    show Identifier, OperatorIdentifier, SimpleIdentifier, flattenName;
import '../ignored_parser_errors.dart' show isIgnoredParserError;
import '../kernel/type_algorithms.dart';
import '../kernel/utils.dart';
import '../modifier.dart'
    show
        Augment,
        Const,
        Covariant,
        External,
        Final,
        Modifier,
        Static,
        Var,
        abstractMask,
        augmentMask,
        constMask,
        covariantMask,
        externalMask,
        finalMask,
        lateMask,
        mixinDeclarationMask,
        requiredMask,
        staticMask;
import '../operator.dart' show Operator;
import '../problems.dart' show unhandled;
import 'source_enum_builder.dart';
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

/// Enum for the context in which declarations occur.
///
/// This is used to determine whether instance type variables access is allowed.
enum DeclarationContext {
  /// In the context of the enclosing library.
  ///
  /// This is used for library, import, export, part, and part of declarations
  /// in libraries and parts, as well as annotations on top level declarations.
  Library,

  /// In a typedef declaration
  ///
  /// This excludes annotations on the typedef declaration itself, which are
  /// seen in the [Library] context.
  Typedef,

  /// In an enum declaration
  ///
  /// This excludes annotations on the enum declaration itself, which are seen
  /// in the [Library] context.
  Enum,

  /// In a top level method declaration.
  ///
  /// This includes return type of the declaration but excludes annotations on
  /// the method declaration itself, which are seen in the [Library] context.
  TopLevelMethod,

  /// In a top level field declaration.
  ///
  /// This includes  type of the declaration but excludes annotations on the
  /// field declaration itself, which are seen in the [Library] context.
  TopLevelField,

  /// In a `class Name<TypeParams>` or `mixin Name<TypeParams>` prefix of a
  /// class declaration `class Name<TypeParams> ... { ... }`, mixin declaration
  /// `mixin Name<TypeParams> ... { ... }` or named mixin application
  /// `class Name<TypeParams> = ...;`.
  ///
  /// This is replaced by [Class], [Mixin] or [NamedMixinApplication] after the
  /// type parameters have been parsed.
  ClassOrMixinOrNamedMixinApplication,

  /// In a named mixin application.
  ///
  /// This excludes type parameters declared on the named mixin application,
  /// which are seen in the [ClassOrMixinOrNamedMixinApplication] context,
  /// and annotations on the named mixin application itself, which are seen in
  /// the [Library] context.
  NamedMixinApplication,

  /// In a class declaration before the class body.
  ///
  /// This excludes type parameters declared on the class declaration, which are
  /// seen in the [ClassOrMixinOrNamedMixinApplication] context, and annotations
  /// on the class declaration itself, which are seen in the [Library] context.
  Class,

  /// In a class declaration body.
  ///
  /// This includes annotations on class member declarations.
  ClassBody,

  /// In a generative constructor declaration inside a class declaration.
  ///
  /// This  excludes annotations on the constructor declaration itself, which
  /// are seen in the [ClassBody] context.
  ClassConstructor,

  /// In a factory constructor declaration inside a class declaration.
  ///
  /// This excludes annotations on the constructor declaration itself, which
  /// are seen in the [ClassBody] context.
  ClassFactory,

  /// In an instance method declaration inside a class declaration.
  ///
  /// This includes return type of the declaration but excludes annotations on
  /// the method declaration itself, which are seen in the [ClassBody] context.
  ClassInstanceMethod,

  /// In an instance field declaration inside a class declaration.
  ///
  /// This includes type of the declaration but excludes annotations on the
  /// field declaration itself, which are seen in the [ClassBody] context.
  ClassInstanceField,

  /// In a static method declaration inside a class declaration.
  ///
  /// This includes return type of the declaration but excludes annotations on
  /// the method declaration itself, which are seen in the [ClassBody] context.
  ClassStaticMethod,

  /// In a static field declaration inside a class declaration.
  ///
  /// This includes type of the declaration but excludes annotations on the
  /// field declaration itself, which are seen in the [ClassBody] context.
  ClassStaticField,

  /// In a mixin declaration before the mixin body.
  ///
  /// This excludes type parameters declared on the mixin declaration, which are
  /// seen in the [ClassOrMixinOrNamedMixinApplication] context, and annotations
  /// on the mixin declaration itself, which are seen in the [Library] context.
  Mixin,

  /// In a mixin declaration body.
  ///
  /// This includes annotations on mixin member declarations.
  MixinBody,

  /// In a generative constructor declaration inside a mixin declaration. This
  /// is an error case.
  ///
  /// This excludes annotations on the constructor declaration itself, which
  /// are seen in the [MixinBody] context.
  MixinConstructor,

  /// In a factory constructor declaration inside a mixin declaration. This is
  /// an error case.
  ///
  /// This excludes annotations on the constructor declaration itself, which
  /// are seen in the [MixinBody] context.
  MixinFactory,

  /// In an instance method declaration inside a mixin declaration.
  ///
  /// This includes return type of the declaration but excludes annotations on
  /// the method declaration itself, which are seen in the [MixinBody] context.
  MixinInstanceMethod,

  /// In an instance field declaration inside a mixin declaration.
  ///
  /// This includes type of the declaration but excludes annotations on the
  /// field declaration itself, which are seen in the [MixinBody] context.
  MixinInstanceField,

  /// In a static method declaration inside a mixin declaration.
  ///
  /// This includes return type of the declaration but excludes annotations on
  /// the method declaration itself, which are seen in the [MixinBody] context.
  MixinStaticMethod,

  /// In a static field declaration inside a mixin declaration.
  ///
  /// This includes type of the declaration but excludes annotations on the
  /// field declaration itself, which are seen in the [MixinBody] context.
  MixinStaticField,

  /// In an extension declaration before the extension body.
  ///
  /// This includes type parameters declared on the extension declaration but
  /// excludes annotations on the extension declaration itself, which are seen
  /// in the [Library] context.
  ExtensionOrExtensionType,

  /// In an extension declaration before the extension body.
  ///
  /// This includes type parameters declared on the extension declaration but
  /// excludes annotations on the extension declaration itself, which are seen
  /// in the [Library] context.
  Extension,

  /// In a extension declaration body.
  ///
  /// This includes annotations on extension member declarations.
  ExtensionBody,

  /// In a generative constructor declaration inside an extension declaration.
  /// This is an error case.
  ///
  /// This excludes annotations on the constructor declaration itself, which
  /// are seen in the [ExtensionBody] context.
  ExtensionConstructor,

  /// In a factory constructor declaration inside an extension declaration. This
  /// is an error case.
  ///
  /// This excludes annotations on the constructor declaration itself, which
  /// are seen in the [ExtensionBody] context.
  ExtensionFactory,

  /// In an instance method declaration inside an extension declaration.
  ///
  /// This includes return type of the declaration but excludes annotations on
  /// the method declaration itself, which are seen in the [ExtensionBody]
  /// context.
  ExtensionInstanceMethod,

  /// In a non-external instance field declaration inside an extension
  /// declaration. This is an error case.
  ///
  /// This includes type of the declaration but excludes annotations on the
  /// field declaration itself, which are seen in the [ExtensionBody] context.
  ExtensionInstanceField,

  /// In an external instance field declaration inside an extension declaration.
  ///
  /// This includes type of the declaration but excludes annotations on the
  /// field declaration itself, which are seen in the [ExtensionBody] context.
  ExtensionExternalInstanceField,

  /// In a static method declaration inside an extension declaration.
  ///
  /// This includes return type of the declaration but excludes annotations on
  /// the method declaration itself, which are seen in the [ExtensionBody]
  /// context.
  ExtensionStaticMethod,

  /// In a static field declaration inside an extension declaration.
  ///
  /// This includes type of the declaration but excludes annotations on the
  /// field declaration itself, which are seen in the [ExtensionBody] context.
  ExtensionStaticField,

  /// In an extension type declaration before the extension type body.
  ///
  /// This includes type parameters declared on the extension type declaration
  /// but excludes annotations on the extension type declaration itself, which
  /// are seen in the [Library] context.
  ExtensionType,

  /// In a extension type declaration body.
  ///
  /// This includes annotations on extension type member declarations.
  ExtensionTypeBody,

  /// In a generative constructor declaration inside an extension type
  /// declaration.
  ///
  /// This excludes annotations on the constructor declaration itself, which
  /// are seen in the [ExtensionTypeBody] context.
  ExtensionTypeConstructor,

  /// In a factory constructor declaration inside an extension type declaration.
  ///
  /// This excludes annotations on the constructor declaration itself, which
  /// are seen in the [ExtensionTypeBody] context.
  ExtensionTypeFactory,

  /// In an instance method declaration inside an extension type declaration.
  ///
  /// This includes return type of the declaration but excludes annotations on
  /// the method declaration itself, which are seen in the [ExtensionTypeBody]
  /// context.
  ExtensionTypeInstanceMethod,

  /// In an instance field declaration inside an extension type declaration.
  /// This is an error case.
  ///
  /// This includes type of the declaration but excludes annotations on the
  /// field declaration itself, which are seen in the [ExtensionTypeBody]
  /// context.
  ExtensionTypeInstanceField,

  /// In a static method declaration inside an extension type declaration.
  ///
  /// This includes return type of the declaration but excludes annotations on
  /// the method declaration itself, which are seen in the [ExtensionTypeBody]
  /// context.
  ExtensionTypeStaticMethod,

  /// In a static field declaration inside an extension type declaration.
  ///
  /// This includes type of the declaration but excludes annotations on the
  /// field declaration itself, which are seen in the [ExtensionTypeBody]
  /// context.
  ExtensionTypeStaticField,

  /// In a generative constructor declaration inside an enum declaration.
  EnumConstructor,

  /// In a static method declaration inside an enum declaration.
  EnumStaticMethod,

  /// In a static field declaration inside an enum declaration.
  EnumStaticField,

  /// In an instance method declaration inside an enum declaration.
  EnumInstanceMethod,

  /// In an instance field declaration inside an enum declaration.
  EnumInstanceField,

  /// In a factory constructor declaration inside an enum declaration. This
  /// is an error case.
  ///
  /// This excludes annotations on the constructor declaration itself, which
  /// are seen in the [EnumBody] context.
  EnumFactory,

  /// In an enum declaration body.
  ///
  /// This includes annotations on extension member declarations.
  EnumBody,
}

extension on DeclarationContext {
  InstanceTypeVariableAccessState get instanceTypeVariableAccessState {
    switch (this) {
      case DeclarationContext.Library:
      case DeclarationContext.Typedef:
      case DeclarationContext.TopLevelMethod:
      case DeclarationContext.TopLevelField:
        return InstanceTypeVariableAccessState.Unexpected;
      case DeclarationContext.ClassOrMixinOrNamedMixinApplication:
      case DeclarationContext.NamedMixinApplication:
      case DeclarationContext.Class:
      case DeclarationContext.ClassConstructor:
      case DeclarationContext.ClassFactory:
      case DeclarationContext.ClassInstanceMethod:
      case DeclarationContext.ClassInstanceField:
      case DeclarationContext.Enum:
      case DeclarationContext.EnumConstructor:
      case DeclarationContext.EnumInstanceField:
      case DeclarationContext.EnumInstanceMethod:
      case DeclarationContext.Mixin:
      case DeclarationContext.MixinInstanceMethod:
      case DeclarationContext.MixinInstanceField:
      case DeclarationContext.ExtensionOrExtensionType:
      case DeclarationContext.Extension:
      case DeclarationContext.ExtensionInstanceMethod:
      case DeclarationContext.ExtensionExternalInstanceField:
      case DeclarationContext.ExtensionType:
      case DeclarationContext.ExtensionTypeConstructor:
      case DeclarationContext.ExtensionTypeFactory:
      case DeclarationContext.ExtensionTypeInstanceMethod:
      case DeclarationContext.ExtensionTypeInstanceField:
        return InstanceTypeVariableAccessState.Allowed;
      case DeclarationContext.ClassBody:
      case DeclarationContext.ClassStaticMethod:
      case DeclarationContext.ClassStaticField:
      case DeclarationContext.EnumStaticField:
      case DeclarationContext.EnumStaticMethod:
      case DeclarationContext.EnumBody:
      case DeclarationContext.MixinBody:
      case DeclarationContext.MixinStaticMethod:
      case DeclarationContext.MixinStaticField:
      case DeclarationContext.ExtensionBody:
      case DeclarationContext.ExtensionStaticMethod:
      case DeclarationContext.ExtensionStaticField:
      case DeclarationContext.ExtensionTypeBody:
      case DeclarationContext.ExtensionTypeStaticMethod:
      case DeclarationContext.ExtensionTypeStaticField:
        return InstanceTypeVariableAccessState.Disallowed;
      case DeclarationContext.MixinConstructor:
      case DeclarationContext.MixinFactory:
      case DeclarationContext.ExtensionConstructor:
      case DeclarationContext.ExtensionFactory:
      case DeclarationContext.ExtensionInstanceField:
      case DeclarationContext.EnumFactory:
        return InstanceTypeVariableAccessState.Invalid;
    }
  }

  /// Returns the kind of type variable created in the current context.
  TypeVariableKind get typeVariableKind {
    switch (this) {
      case DeclarationContext.Class:
      case DeclarationContext.ClassOrMixinOrNamedMixinApplication:
      case DeclarationContext.Mixin:
      case DeclarationContext.NamedMixinApplication:
        return TypeVariableKind.classMixinOrEnum;
      case DeclarationContext.ExtensionOrExtensionType:
      case DeclarationContext.Extension:
      case DeclarationContext.ExtensionBody:
      case DeclarationContext.ExtensionType:
      case DeclarationContext.ExtensionTypeBody:
        return TypeVariableKind.extensionOrExtensionType;
      case DeclarationContext.ClassBody:
      case DeclarationContext.ClassConstructor:
      case DeclarationContext.ClassFactory:
      case DeclarationContext.ClassInstanceField:
      case DeclarationContext.ClassInstanceMethod:
      case DeclarationContext.ClassStaticField:
      case DeclarationContext.ClassStaticMethod:
      case DeclarationContext.Enum:
      case DeclarationContext.EnumBody:
      case DeclarationContext.EnumConstructor:
      case DeclarationContext.EnumFactory:
      case DeclarationContext.EnumInstanceField:
      case DeclarationContext.EnumInstanceMethod:
      case DeclarationContext.EnumStaticField:
      case DeclarationContext.EnumStaticMethod:
      case DeclarationContext.ExtensionConstructor:
      case DeclarationContext.ExtensionExternalInstanceField:
      case DeclarationContext.ExtensionFactory:
      case DeclarationContext.ExtensionInstanceField:
      case DeclarationContext.ExtensionInstanceMethod:
      case DeclarationContext.ExtensionStaticField:
      case DeclarationContext.ExtensionStaticMethod:
      case DeclarationContext.ExtensionTypeConstructor:
      case DeclarationContext.ExtensionTypeFactory:
      case DeclarationContext.ExtensionTypeInstanceField:
      case DeclarationContext.ExtensionTypeInstanceMethod:
      case DeclarationContext.ExtensionTypeStaticField:
      case DeclarationContext.ExtensionTypeStaticMethod:
      case DeclarationContext.Library:
      case DeclarationContext.MixinBody:
      case DeclarationContext.MixinConstructor:
      case DeclarationContext.MixinFactory:
      case DeclarationContext.MixinInstanceField:
      case DeclarationContext.MixinInstanceMethod:
      case DeclarationContext.MixinStaticField:
      case DeclarationContext.MixinStaticMethod:
      case DeclarationContext.TopLevelField:
      case DeclarationContext.TopLevelMethod:
      case DeclarationContext.Typedef:
        return TypeVariableKind.function;
    }
  }
}

class OutlineBuilder extends StackListenerImpl {
  @override
  final SourceLibraryBuilder libraryBuilder;

  final bool enableNative;
  final bool stringExpectedAfterNative;
  bool inAbstractOrSealedClass = false;
  bool inConstructor = false;
  bool inConstructorName = false;
  int importIndex = 0;

  String? nativeMethodName;

  Link<DeclarationContext> _declarationContext = const Link();

  /// Level of nesting of function-type type parameters
  ///
  /// For instance, `X` is at nesting level 1, and `Y` is at nesting level 2 in
  /// the following:
  ///
  ///    method() {
  ///      Function<X>(Function<Y extends X>(Y))? f;
  ///    }
  ///
  /// For simplicity, non-generic functions are considered generic functions
  /// with 0 type parameters.
  int _structuralParameterDepthLevel = 0;

  /// True if a type of a formal parameter is currently compiled
  ///
  /// This variable is needed to distinguish between the type of a formal
  /// parameter and its initializer because in those two regions of code the
  /// type variables should be interpreted differently: as structural and
  /// nominal correspondingly.
  bool _insideOfFormalParameterType = false;

  bool get inFunctionType =>
      _structuralParameterDepthLevel > 0 || _insideOfFormalParameterType;

  OutlineBuilder(SourceLibraryBuilder library)
      : libraryBuilder = library,
        enableNative =
            library.loader.target.backendTarget.enableNative(library.importUri),
        stringExpectedAfterNative =
            library.loader.target.backendTarget.nativeExtensionExpectsString;

  DeclarationContext get declarationContext => _declarationContext.head;

  void pushDeclarationContext(DeclarationContext value) {
    _declarationContext = _declarationContext.prepend(value);
  }

  void popDeclarationContext([DeclarationContext? expectedContext]) {
    assert(
        expectedContext == null || expectedContext == declarationContext,
        "Unexpected declaration context: "
        "Expected $expectedContext, actual $declarationContext.");
    _declarationContext = _declarationContext.tail!;
  }

  @override
  Uri get uri => libraryBuilder.fileUri;

  int popCharOffset() => pop() as int;

  List<String>? popIdentifierList(int count) {
    assert(checkState(
        null, repeatedKind(ValueKinds.IdentifierOrParserRecovery, count)));
    if (count == 0) return null;
    List<String> list = new List<String>.filled(count, /* dummyValue = */ '');
    bool isParserRecovery = false;
    for (int i = count - 1; i >= 0; i--) {
      Object? identifier = pop();
      if (identifier is ParserRecovery) {
        isParserRecovery = true;
      } else {
        list[i] = (identifier as Identifier).name;
      }
    }
    return isParserRecovery ? null : list;
  }

  @override
  void beginCompilationUnit(Token token) {
    pushDeclarationContext(DeclarationContext.Library);
  }

  @override
  void endCompilationUnit(int count, Token token) {
    popDeclarationContext(DeclarationContext.Library);
  }

  @override
  void endMetadata(Token beginToken, Token? periodBeforeName, Token endToken) {
    debugEvent("endMetadata");
    assert(checkState(beginToken, [
      /* arguments */ ValueKinds.ArgumentsTokenOrNull,
      if (periodBeforeName != null) /* constructor name */
        ValueKinds.IdentifierOrParserRecovery,
      /* type arguments */ ValueKinds.TypeArgumentsOrNull,
      /* prefix or constructor */ ValueKinds.IdentifierOrParserRecovery,
    ]));

    pop(NullValues.Arguments); // arguments
    if (periodBeforeName != null) {
      pop(); // constructor name
    }
    pop(NullValues.TypeArguments); // type arguments
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
        NullValues.Metadata);
  }

  @override
  void handleInvalidTopLevelDeclaration(Token endToken) {
    debugEvent("InvalidTopLevelDeclaration");
    pop(); // metadata star
  }

  @override
  void endHide(Token hideKeyword) {
    debugEvent("endHide");
    assert(checkState(hideKeyword, [
      ValueKinds.NameListOrParserRecovery,
    ]));

    Object? names = pop();
    if (names is ParserRecovery) {
      push(names);
    } else {
      push(new CombinatorBuilder.hide(names as Iterable<String>,
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
      push(new CombinatorBuilder.show(names as Iterable<String>,
          showKeyword.charOffset, libraryBuilder.fileUri));
    }
  }

  @override
  void endCombinators(int count) {
    debugEvent("Combinators");
    push(const FixedNullableList<CombinatorBuilder>()
            .popNonNullable(stack, count, dummyCombinator) ??
        NullValues.Combinators);
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    debugEvent("endExport");
    assert(checkState(exportKeyword, [
      /* show / hide combinators */ ValueKinds.CombinatorListOrNull,
      /* configurations */ ValueKinds.ConfigurationListOrNull,
      /* uri offset */ ValueKinds.Integer,
      /* uri */ ValueKinds.Name,
      /* metadata */ ValueKinds.MetadataListOrNull,
    ]));

    List<CombinatorBuilder>? combinators =
        pop(NullValues.Combinators) as List<CombinatorBuilder>?;
    List<Configuration>? configurations =
        pop(NullValues.ConditionalUris) as List<Configuration>?;
    int uriOffset = popCharOffset();
    String uri = pop() as String;
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    libraryBuilder.addExport(metadata, uri, configurations, combinators,
        exportKeyword.charOffset, uriOffset);
    checkEmpty(exportKeyword.charOffset);
  }

  @override
  void handleImportPrefix(Token? deferredKeyword, Token? asKeyword) {
    debugEvent("handleImportPrefix");
    if (asKeyword == null) {
      // If asKeyword is null, then no prefix has been pushed on the stack.
      // Push a placeholder indicating that there is no prefix.
      push(NullValues.Prefix);
    }
    push(deferredKeyword != null);
  }

  @override
  void endImport(Token importKeyword, Token? augmentToken, Token? semicolon) {
    debugEvent("endImport");
    assert(checkState(importKeyword, [
      /* show / hide combinators */ ValueKinds.CombinatorListOrNull,
      /* is deferred */ ValueKinds.Bool,
      /* prefix */ ValueKinds.PrefixOrParserRecoveryOrNull,
      /* configurations */ ValueKinds.ConfigurationListOrNull,
      /* uri offset */ ValueKinds.Integer,
      /* uri */ ValueKinds.Name,
      /* metadata */ ValueKinds.MetadataListOrNull,
    ]));

    List<CombinatorBuilder>? combinators =
        pop(NullValues.Combinators) as List<CombinatorBuilder>?;
    bool isDeferred = pop() as bool;
    Object? prefix = pop(NullValues.Prefix);
    List<Configuration>? configurations =
        pop(NullValues.ConditionalUris) as List<Configuration>?;
    int uriOffset = popCharOffset();
    String uri =
        pop() as String; // For a conditional import, this is the default URI.
    List<MetadataBuilder>? metadata =
        pop(NullValues.Metadata) as List<MetadataBuilder>?;
    checkEmpty(importKeyword.charOffset);
    if (prefix is! Identifier?) {
      assert(prefix is ParserRecovery,
          "Unexpected prefix $prefix (${prefix.runtimeType}).");
      return;
    }

    if (augmentToken != null) {
      if (reportIfNotEnabled(libraryFeatures.macros, augmentToken.charOffset,
          augmentToken.length)) {
        augmentToken = null;
      }
    }
    bool isAugmentationImport = augmentToken != null;
    libraryBuilder.addImport(
        metadata: metadata,
        isAugmentationImport: isAugmentationImport,
        uri: uri,
        configurations: configurations,
        prefix: prefix?.name,
        combinators: combinators,
        deferred: isDeferred,
        charOffset: importKeyword.charOffset,
        prefixCharOffset: prefix?.nameOffset ?? TreeNode.noOffset,
        uriOffset: uriOffset,
        importIndex: importIndex++);
  }

  @override
  void endConditionalUris(int count) {
    debugEvent("endConditionalUris");
    push(const FixedNullableList<Configuration>()
            .popNonNullable(stack, count, dummyConfiguration) ??
        NullValues.ConditionalUris);
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
    assert(checkState(firstIdentifier,
        repeatedKind(ValueKinds.IdentifierOrParserRecovery, count)));

    List<String>? names = popIdentifierList(count);
    if (names == null) {
      push(new ParserRecovery(firstIdentifier.charOffset));
    } else {
      push(names.join('.'));
    }
  }

  @override
  void handleRecoverImport(Token? semicolon) {
    debugEvent("handleRecoverImport");
    assert(checkState(semicolon, [
      /* show / hide combinators */ ValueKinds.CombinatorListOrNull,
      /* is deferred */ ValueKinds.Bool,
      /* prefix */ ValueKinds.PrefixOrParserRecoveryOrNull,
      /* configurations */ ValueKinds.ConfigurationListOrNull,
    ]));

    pop(NullValues.Combinators); // combinators
    pop(NullValues.Deferred); // deferredKeyword
    pop(NullValues.Prefix); // prefix
    pop(NullValues.ConditionalUris); // conditionalUris
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    debugEvent("endPart");
    assert(checkState(partKeyword, [
      /* offset */ ValueKinds.Integer,
      /* uri string */ ValueKinds.String,
      /* metadata */ ValueKinds.MetadataListOrNull,
    ]));

    int charOffset = popCharOffset();
    String uri = pop() as String;
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    libraryBuilder.addPart(metadata, uri, charOffset);
    checkEmpty(partKeyword.charOffset);
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    debugEvent("handleOperatorName");
    push(new OperatorIdentifier(token));
  }

  @override
  void handleInvalidOperatorName(Token operatorKeyword, Token token) {
    debugEvent("handleInvalidOperatorName");
    push(new SimpleIdentifier(token));
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    debugEvent("handleIdentifier");
    if (context == IdentifierContext.enumValueDeclaration) {
      List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
      if (token.isSynthetic) {
        push(new ParserRecovery(token.charOffset));
      } else {
        push(new EnumConstantInfo(metadata, token.lexeme, token.charOffset));
      }
    } else {
      if (!token.isSynthetic) {
        push(new SimpleIdentifier(token));
      } else {
        // This comes from a synthetic token which is inserted by the parser in
        // an attempt to recover.  This almost always means that the parser has
        // gotten very confused and we need to ignore the results.
        push(new ParserRecovery(token.charOffset));
      }
    }
    if (inConstructor && context == IdentifierContext.methodDeclaration) {
      inConstructorName = true;
    }
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
    assert(checkState(
        null, repeatedKind(ValueKinds.IdentifierOrParserRecovery, count)));
    push(popIdentifierList(count) ??
        (count == 0 ? NullValues.IdentifierList : new ParserRecovery(-1)));
  }

  @override
  void handleQualified(Token period) {
    assert(checkState(period, [
      /*suffix*/ ValueKinds.IdentifierOrParserRecovery,
      /*prefix*/ ValueKinds.IdentifierOrParserRecovery,
    ]));
    debugEvent("handleQualified");
    Object? suffix = pop();
    Object prefix = pop()!;
    if (prefix is! Identifier) {
      assert(prefix is ParserRecovery,
          "Unexpected prefix $prefix (${prefix.runtimeType})");
      push(prefix);
    } else if (suffix is! Identifier) {
      assert(suffix is ParserRecovery,
          "Unexpected suffix $suffix (${suffix.runtimeType})");
      push(suffix);
    } else {
      push(suffix.withQualifier(prefix));
    }
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon, bool hasName) {
    debugEvent("endLibraryName");
    assert(checkState(libraryKeyword, [
      if (hasName) ValueKinds.IdentifierOrParserRecovery,
      ValueKinds.MetadataListOrNull,
    ]));
    Object? name = null;
    if (hasName) {
      name = pop();
    }
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    if (name != null && name is! ParserRecovery) {
      libraryBuilder.name =
          flattenName(name, offsetForToken(libraryKeyword), uri);
    } else {
      reportIfNotEnabled(
          libraryFeatures.unnamedLibraries, semicolon.charOffset, noLength);
    }
    libraryBuilder.metadata = metadata;
  }

  @override
  void beginClassOrMixinOrNamedMixinApplicationPrelude(Token token) {
    debugEvent("beginClassOrNamedMixinApplicationPrelude");
    pushDeclarationContext(
        DeclarationContext.ClassOrMixinOrNamedMixinApplication);
    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.classOrNamedMixinApplication,
        "class or mixin application");
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
    popDeclarationContext(
        DeclarationContext.ClassOrMixinOrNamedMixinApplication);
    pushDeclarationContext(DeclarationContext.Class);
    List<NominalVariableBuilder>? typeVariables =
        pop() as List<NominalVariableBuilder>?;
    push(typeVariables ?? NullValues.NominalVariables);
    if (macroToken != null) {
      if (reportIfNotEnabled(
          libraryFeatures.macros, macroToken.charOffset, macroToken.length)) {
        macroToken = null;
      }
    }
    if (sealedToken != null) {
      if (reportIfNotEnabled(libraryFeatures.sealedClass,
          sealedToken.charOffset, sealedToken.length)) {
        sealedToken = null;
      }
    }
    if (baseToken != null) {
      if (reportIfNotEnabled(libraryFeatures.classModifiers,
          baseToken.charOffset, baseToken.length)) {
        baseToken = null;
      }
    }
    if (interfaceToken != null) {
      if (reportIfNotEnabled(libraryFeatures.classModifiers,
          interfaceToken.charOffset, interfaceToken.length)) {
        interfaceToken = null;
      }
    }
    if (finalToken != null) {
      if (reportIfNotEnabled(libraryFeatures.classModifiers,
          finalToken.charOffset, finalToken.length)) {
        finalToken = null;
      }
    }
    if (mixinToken != null) {
      if (reportIfNotEnabled(libraryFeatures.classModifiers,
          mixinToken.charOffset, mixinToken.length)) {
        mixinToken = null;
      }
    }
    libraryBuilder.currentTypeParameterScopeBuilder
        .markAsClassDeclaration(name.lexeme, name.charOffset, typeVariables);
    libraryBuilder.beginIndexedContainer(name.lexeme,
        isExtensionTypeDeclaration: false);
    inAbstractOrSealedClass = abstractToken != null || sealedToken != null;
    push(abstractToken != null ? abstractMask : 0);
    push(macroToken ?? NullValues.Token);
    push(sealedToken ?? NullValues.Token);
    push(baseToken ?? NullValues.Token);
    push(interfaceToken ?? NullValues.Token);
    push(finalToken ?? NullValues.Token);
    push(augmentToken ?? NullValues.Token);
    push(mixinToken ?? NullValues.Token);
  }

  @override
  void beginMixinDeclaration(Token beginToken, Token? augmentToken,
      Token? baseToken, Token mixinKeyword, Token name) {
    debugEvent("beginMixinDeclaration");
    popDeclarationContext(
        DeclarationContext.ClassOrMixinOrNamedMixinApplication);
    pushDeclarationContext(DeclarationContext.Mixin);
    List<NominalVariableBuilder>? typeVariables =
        pop() as List<NominalVariableBuilder>?;
    if (baseToken != null) {
      if (reportIfNotEnabled(libraryFeatures.classModifiers,
          baseToken.charOffset, baseToken.length)) {
        baseToken = null;
      }
    }
    push(augmentToken ?? NullValues.Token);
    push(baseToken ?? NullValues.Token);
    push(typeVariables ?? NullValues.NominalVariables);
    libraryBuilder.currentTypeParameterScopeBuilder
        .markAsMixinDeclaration(name.lexeme, name.charOffset, typeVariables);
    libraryBuilder.beginIndexedContainer(name.lexeme,
        isExtensionTypeDeclaration: false);
  }

  @override
  void beginClassOrMixinOrExtensionBody(DeclarationKind kind, Token token) {
    DeclarationContext declarationContext;
    switch (kind) {
      case DeclarationKind.TopLevel:
        throw new UnsupportedError('Unexpected top level body.');
      case DeclarationKind.Class:
        declarationContext = DeclarationContext.ClassBody;
        break;
      case DeclarationKind.Mixin:
        declarationContext = DeclarationContext.MixinBody;
        break;
      case DeclarationKind.Extension:
        declarationContext = DeclarationContext.ExtensionBody;
        break;
      case DeclarationKind.ExtensionType:
        declarationContext = DeclarationContext.ExtensionTypeBody;
        break;
      case DeclarationKind.Enum:
        declarationContext = DeclarationContext.Enum;
        break;
    }
    pushDeclarationContext(declarationContext);
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
    libraryBuilder.currentTypeParameterScopeBuilder.resolveNamedTypes(
        libraryBuilder.currentTypeParameterScopeBuilder.typeVariables,
        libraryBuilder);
  }

  @override
  void beginNamedMixinApplication(
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
    debugEvent("beginNamedMixinApplication");
    popDeclarationContext(
        DeclarationContext.ClassOrMixinOrNamedMixinApplication);
    pushDeclarationContext(DeclarationContext.NamedMixinApplication);
    List<NominalVariableBuilder>? typeVariables =
        pop() as List<NominalVariableBuilder>?;
    push(typeVariables ?? NullValues.NominalVariables);
    libraryBuilder.currentTypeParameterScopeBuilder.markAsNamedMixinApplication(
        name.lexeme, name.charOffset, typeVariables);
    push(abstractToken != null ? abstractMask : 0);
    if (macroToken != null) {
      if (reportIfNotEnabled(
          libraryFeatures.macros, macroToken.charOffset, macroToken.length)) {
        macroToken = null;
      }
    }
    if (sealedToken != null) {
      if (reportIfNotEnabled(libraryFeatures.sealedClass,
          sealedToken.charOffset, sealedToken.length)) {
        sealedToken = null;
      }
    }
    if (baseToken != null) {
      if (reportIfNotEnabled(libraryFeatures.classModifiers,
          baseToken.charOffset, baseToken.length)) {
        baseToken = null;
      }
    }
    if (interfaceToken != null) {
      if (reportIfNotEnabled(libraryFeatures.classModifiers,
          interfaceToken.charOffset, interfaceToken.length)) {
        interfaceToken = null;
      }
    }
    if (finalToken != null) {
      if (reportIfNotEnabled(libraryFeatures.classModifiers,
          finalToken.charOffset, finalToken.length)) {
        finalToken = null;
      }
    }
    if (mixinToken != null) {
      if (reportIfNotEnabled(libraryFeatures.classModifiers,
          mixinToken.charOffset, mixinToken.length)) {
        mixinToken = null;
      }
    }
    push(macroToken ?? NullValues.Token);
    push(sealedToken ?? NullValues.Token);
    push(baseToken ?? NullValues.Token);
    push(interfaceToken ?? NullValues.Token);
    push(finalToken ?? NullValues.Token);
    push(augmentToken ?? NullValues.Token);
    push(mixinToken ?? NullValues.Token);
  }

  @override
  void handleImplements(Token? implementsKeyword, int interfacesCount) {
    debugEvent("Implements");
    push(const FixedNullableList<TypeBuilder>()
            .popNonNullable(stack, interfacesCount, dummyTypeBuilder) ??
        NullValues.TypeBuilderList);

    if (implementsKeyword != null &&
        declarationContext == DeclarationContext.Enum) {
      reportIfNotEnabled(libraryFeatures.enhancedEnums,
          implementsKeyword.charOffset, implementsKeyword.length);
    }
  }

  @override
  void handleRecoverDeclarationHeader(DeclarationHeaderKind kind) {
    debugEvent("handleRecoverClassHeader");
    assert(checkState(null, [
      /* interfaces */ ValueKinds.TypeBuilderListOrNull,
      /* mixins */ unionOfKinds([
        ValueKinds.MixinApplicationBuilderOrNull,
        ValueKinds.ParserRecovery,
      ]),
      /* supertype offset */ ValueKinds.Integer,
      /* supertype */ unionOfKinds([
        ValueKinds.TypeBuilderOrNull,
        ValueKinds.ParserRecovery,
      ]),
    ]));
    // TODO(jensj): Possibly use these instead... E.g. "class A extend B {}"
    // will get here (because it's 'extends' with an 's') and discard the B...
    // Also Analyzer actually merges the information meaning that the two could
    // give different errors (if, say, one later assigns
    // A to a variable of type B).
    pop(NullValues.TypeBuilderList); // Interfaces.
    pop(NullValues.MixinApplicationBuilder); // Mixin applications.
    pop(); // Supertype offset.
    pop(NullValues.TypeBuilder); // Supertype.
  }

  @override
  void handleRecoverMixinHeader() {
    debugEvent("handleRecoverMixinHeader");
    // TODO(jensj): Possibly use these instead...
    // See also handleRecoverClassHeader
    pop(NullValues.TypeBuilderList); // Interfaces.
    pop(NullValues.TypeBuilderList); // Supertype constraints.
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
    assert(checkState(beginToken, [
      /* interfaces */ ValueKinds.TypeBuilderListOrNull,
      /* mixins */ unionOfKinds([
        ValueKinds.MixinApplicationBuilderOrNull,
        ValueKinds.ParserRecovery,
      ]),
      /* supertype offset */ ValueKinds.Integer,
      /* supertype */ unionOfKinds([
        ValueKinds.TypeBuilderOrNull,
        ValueKinds.ParserRecovery,
      ]),
      /* mixin token */ ValueKinds.TokenOrNull,
      /* augment token */ ValueKinds.TokenOrNull,
      /* final token */ ValueKinds.TokenOrNull,
      /* interface token */ ValueKinds.TokenOrNull,
      /* base token */ ValueKinds.TokenOrNull,
      /* sealed token */ ValueKinds.TokenOrNull,
      /* macro token */ ValueKinds.TokenOrNull,
      /* modifiers */ ValueKinds.Integer,
      /* type variables */ ValueKinds.NominalVariableListOrNull,
      /* name */ ValueKinds.IdentifierOrParserRecovery,
      /* metadata */ ValueKinds.MetadataListOrNull,
    ]));

    List<TypeBuilder>? interfaces =
        pop(NullValues.TypeBuilderList) as List<TypeBuilder>?;
    MixinApplicationBuilder? mixinApplication =
        nullIfParserRecovery(pop(NullValues.MixinApplicationBuilder))
            as MixinApplicationBuilder?;
    int supertypeOffset = popCharOffset();
    TypeBuilder? supertype = nullIfParserRecovery(pop()) as TypeBuilder?;
    Token? mixinToken = pop(NullValues.Token) as Token?;
    Token? augmentToken = pop(NullValues.Token) as Token?;
    Token? finalToken = pop(NullValues.Token) as Token?;
    Token? interfaceToken = pop(NullValues.Token) as Token?;
    Token? baseToken = pop(NullValues.Token) as Token?;
    Token? sealedToken = pop(NullValues.Token) as Token?;
    Token? macroToken = pop(NullValues.Token) as Token?;
    int modifiers = pop() as int;
    List<NominalVariableBuilder>? typeVariables =
        pop() as List<NominalVariableBuilder>?;
    Object? name = pop();
    if (typeVariables != null && mixinApplication != null) {
      mixinApplication.typeVariables = typeVariables;
    }
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    inAbstractOrSealedClass = false;
    checkEmpty(beginToken.charOffset);
    if (name is ParserRecovery) {
      libraryBuilder
          .endNestedDeclaration(
              TypeParameterScopeKind.classDeclaration, "<syntax-error>")
          .resolveNamedTypes(typeVariables, libraryBuilder);
    } else {
      Identifier identifier = name as Identifier;
      final int startCharOffset =
          metadata == null ? beginToken.charOffset : metadata.first.charOffset;

      if (libraryBuilder.isNonNullableByDefault) {
        String classNameForErrors = identifier.name;
        if (supertype != null) {
          if (supertype.nullabilityBuilder.build(libraryBuilder) ==
              Nullability.nullable) {
            libraryBuilder.addProblem(
                templateNullableSuperclassError
                    .withArguments(supertype.fullNameForErrors),
                identifier.nameOffset,
                classNameForErrors.length,
                uri);
          }
        }
        if (mixinApplication != null) {
          List<TypeBuilder>? mixins = mixinApplication.mixins;
          for (TypeBuilder mixin in mixins) {
            if (mixin.nullabilityBuilder.build(libraryBuilder) ==
                Nullability.nullable) {
              libraryBuilder.addProblem(
                  templateNullableMixinError
                      .withArguments(mixin.fullNameForErrors),
                  identifier.nameOffset,
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
                  identifier.nameOffset,
                  classNameForErrors.length,
                  uri);
            }
          }
        }
      }
      if (sealedToken != null) {
        modifiers |= abstractMask;
      }
      libraryBuilder.addClass(
          metadata,
          modifiers,
          identifier.name,
          typeVariables,
          supertype,
          mixinApplication,
          interfaces,
          startCharOffset,
          identifier.nameOffset,
          endToken.charOffset,
          supertypeOffset,
          isMacro: macroToken != null,
          isSealed: sealedToken != null,
          isBase: baseToken != null,
          isInterface: interfaceToken != null,
          isFinal: finalToken != null,
          isAugmentation: augmentToken != null,
          isMixinClass: mixinToken != null);
    }
    libraryBuilder.endIndexedContainer();
    popDeclarationContext(DeclarationContext.Class);
  }

  Object? nullIfParserRecovery(Object? node) {
    return node is ParserRecovery ? null : node;
  }

  @override
  void endMixinDeclaration(Token beginToken, Token endToken) {
    debugEvent("endMixinDeclaration");
    assert(checkState(beginToken, [
      /* interfaces */ ValueKinds.TypeBuilderListOrNull,
      /* supertypeConstraints */ unionOfKinds([
        ValueKinds.TypeBuilderListOrNull,
        ValueKinds.ParserRecovery,
      ]),
      /* type variables */ ValueKinds.NominalVariableListOrNull,
      /* base token */ ValueKinds.TokenOrNull,
      /* augment token */ ValueKinds.TokenOrNull,
      /* name */ ValueKinds.IdentifierOrParserRecovery,
      /* metadata */ ValueKinds.MetadataListOrNull,
    ]));

    List<TypeBuilder>? interfaces =
        pop(NullValues.TypeBuilderList) as List<TypeBuilder>?;
    List<TypeBuilder>? supertypeConstraints =
        nullIfParserRecovery(pop()) as List<TypeBuilder>?;
    List<NominalVariableBuilder>? typeVariables =
        pop(NullValues.NominalVariables) as List<NominalVariableBuilder>?;
    Token? baseToken = pop(NullValues.Token) as Token?;
    Token? augmentToken = pop(NullValues.Token) as Token?;
    Object? name = pop();
    List<MetadataBuilder>? metadata =
        pop(NullValues.Metadata) as List<MetadataBuilder>?;
    checkEmpty(beginToken.charOffset);
    if (name is ParserRecovery) {
      libraryBuilder
          .endNestedDeclaration(
              TypeParameterScopeKind.mixinDeclaration, "<syntax-error>")
          .resolveNamedTypes(typeVariables, libraryBuilder);
    } else {
      Identifier identifier = name as Identifier;
      int startOffset =
          metadata == null ? beginToken.charOffset : metadata.first.charOffset;
      if (libraryBuilder.isNonNullableByDefault) {
        String classNameForErrors = identifier.name;
        if (supertypeConstraints != null) {
          for (TypeBuilder supertype in supertypeConstraints) {
            if (supertype.nullabilityBuilder.build(libraryBuilder) ==
                Nullability.nullable) {
              libraryBuilder.addProblem(
                  templateNullableSuperclassError
                      .withArguments(supertype.fullNameForErrors),
                  identifier.nameOffset,
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
                  identifier.nameOffset,
                  classNameForErrors.length,
                  uri);
            }
          }
        }
      }

      libraryBuilder.addMixinDeclaration(
          metadata,
          mixinDeclarationMask,
          identifier.name,
          typeVariables,
          supertypeConstraints,
          interfaces,
          startOffset,
          identifier.nameOffset,
          endToken.charOffset,
          -1,
          isBase: baseToken != null,
          isAugmentation: augmentToken != null);
    }
    libraryBuilder.endIndexedContainer();
    popDeclarationContext(DeclarationContext.Mixin);
  }

  @override
  void beginExtensionDeclarationPrelude(Token extensionKeyword) {
    assert(checkState(extensionKeyword, [ValueKinds.MetadataListOrNull]));
    debugEvent("beginExtensionDeclaration");
    pushDeclarationContext(DeclarationContext.ExtensionOrExtensionType);
    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.extensionOrExtensionTypeDeclaration,
        "extension");
  }

  @override
  void beginExtensionDeclaration(Token extensionKeyword, Token? nameToken) {
    assert(checkState(extensionKeyword,
        [ValueKinds.NominalVariableListOrNull, ValueKinds.MetadataListOrNull]));
    debugEvent("beginExtensionDeclaration");
    popDeclarationContext(DeclarationContext.ExtensionOrExtensionType);
    pushDeclarationContext(DeclarationContext.Extension);
    List<NominalVariableBuilder>? typeVariables =
        pop() as List<NominalVariableBuilder>?;
    int offset = nameToken?.charOffset ?? extensionKeyword.charOffset;
    push(nameToken?.lexeme ?? NullValues.Name);
    push(offset);
    push(typeVariables ?? NullValues.NominalVariables);
    libraryBuilder.currentTypeParameterScopeBuilder
        .markAsExtensionDeclaration(nameToken?.lexeme, offset, typeVariables);
  }

  @override
  void endExtensionDeclaration(Token beginToken, Token extensionKeyword,
      Token onKeyword, Token endToken) {
    assert(checkState(extensionKeyword, [
      unionOfKinds([ValueKinds.ParserRecovery, ValueKinds.TypeBuilder]),
      ValueKinds.NominalVariableListOrNull,
      ValueKinds.Integer,
      ValueKinds.NameOrNull,
      ValueKinds.MetadataListOrNull
    ]));
    debugEvent("endExtensionDeclaration");

    Object? onType = pop();
    if (onType is ParserRecovery) {
      ParserRecovery parserRecovery = onType;
      onType = new FixedTypeBuilderImpl(
          const InvalidType(), uri, parserRecovery.charOffset);
    }
    List<NominalVariableBuilder>? typeVariables =
        pop(NullValues.NominalVariables) as List<NominalVariableBuilder>?;
    int nameOffset = popCharOffset();
    String? name = pop(NullValues.Name) as String?;
    if (name == null) {
      nameOffset = extensionKeyword.charOffset;
    }
    List<MetadataBuilder>? metadata =
        pop(NullValues.Metadata) as List<MetadataBuilder>?;
    checkEmpty(extensionKeyword.charOffset);
    int startOffset = metadata == null
        ? extensionKeyword.charOffset
        : metadata.first.charOffset;
    libraryBuilder.addExtensionDeclaration(
        metadata,
        // TODO(johnniwinther): Support modifiers on extensions?
        0,
        name,
        typeVariables,
        onType as TypeBuilder,
        startOffset,
        nameOffset,
        endToken.charOffset);
    popDeclarationContext(DeclarationContext.Extension);
  }

  @override
  void beginExtensionTypeDeclaration(Token extensionKeyword, Token nameToken) {
    assert(checkState(extensionKeyword,
        [ValueKinds.NominalVariableListOrNull, ValueKinds.MetadataListOrNull]));
    debugEvent("beginExtensionTypeDeclaration");
    popDeclarationContext(DeclarationContext.ExtensionOrExtensionType);
    pushDeclarationContext(DeclarationContext.ExtensionType);
    List<NominalVariableBuilder>? typeVariables =
        pop() as List<NominalVariableBuilder>?;
    String name = nameToken.lexeme;
    int offset = nameToken.charOffset;
    push(name);
    push(offset);
    push(typeVariables ?? NullValues.NominalVariables);
    libraryBuilder.currentTypeParameterScopeBuilder
        .markAsExtensionTypeDeclaration(name, offset, typeVariables);
    libraryBuilder.beginIndexedContainer(name,
        isExtensionTypeDeclaration: true);
  }

  @override
  void endExtensionTypeDeclaration(Token beginToken, Token extensionKeyword,
      Token typeKeyword, Token endToken) {
    assert(checkState(extensionKeyword, [
      ValueKinds.TypeBuilderListOrNull,
      ValueKinds.NominalVariableListOrNull,
      ValueKinds.Integer,
      ValueKinds.Name,
      ValueKinds.MetadataListOrNull,
    ]));
    reportIfNotEnabled(libraryFeatures.inlineClass, typeKeyword.charOffset,
        typeKeyword.length);

    List<TypeBuilder>? interfaces =
        pop(NullValues.TypeBuilderList) as List<TypeBuilder>?;
    List<NominalVariableBuilder>? typeVariables =
        pop(NullValues.NominalVariables) as List<NominalVariableBuilder>?;
    int nameOffset = popCharOffset();
    String name = pop() as String;
    List<MetadataBuilder>? metadata =
        pop(NullValues.Metadata) as List<MetadataBuilder>?;
    checkEmpty(extensionKeyword.charOffset);

    reportIfNotEnabled(libraryFeatures.inlineClass,
        extensionKeyword.next!.charOffset, extensionKeyword.next!.length);
    int startOffset = metadata == null
        ? extensionKeyword.charOffset
        : metadata.first.charOffset;
    libraryBuilder.addExtensionTypeDeclaration(
        metadata,
        // TODO(johnniwinther): Support modifiers on extension types?
        0,
        name,
        typeVariables,
        interfaces,
        startOffset,
        nameOffset,
        endToken.charOffset);

    libraryBuilder.endIndexedContainer();
    popDeclarationContext(DeclarationContext.ExtensionType);
  }

  @override
  void beginPrimaryConstructor(Token beginToken) {}

  @override
  void endPrimaryConstructor(
      Token beginToken, Token? constKeyword, bool hasConstructorName) {
    assert(checkState(beginToken, [
      ValueKinds.FormalListOrNull,
      /* formals offset */ ValueKinds.Integer,
      if (hasConstructorName) ValueKinds.IdentifierOrParserRecovery,
    ]));
    List<FormalParameterBuilder>? formals =
        pop(NullValues.FormalParameters) as List<FormalParameterBuilder>?;
    int charOffset = pop() as int; // Pop formals char offset
    String constructorName = '';
    if (hasConstructorName) {
      // TODO(johnniwinther): Handle [ParserRecovery].
      Identifier identifier = pop() as Identifier;
      charOffset = identifier.nameOffset;
      constructorName = identifier.name;
    }
    bool inExtensionType =
        declarationContext == DeclarationContext.ExtensionType;
    if (formals != null) {
      if (inExtensionType && formals.isEmpty) {
        libraryBuilder.addProblem(
            messageExpectedRepresentationField, charOffset, 1, uri);
      }
      if (inExtensionType && formals.length > 1) {
        libraryBuilder.addProblem(
            messageMultipleRepresentationFields, charOffset, 1, uri);
      }
      for (int i = 0; i < formals.length; i++) {
        FormalParameterBuilder formal = formals[i];
        if (inExtensionType && formal.type is ImplicitTypeBuilder) {
          libraryBuilder.addProblem(messageExpectedRepresentationType,
              formal.charOffset, formal.name.length, formal.fileUri);
        }
        if (inExtensionType &&
            Modifier.maskContainsActualModifiers(formal.modifiers)) {
          libraryBuilder.addProblem(messageRepresentationFieldModifier,
              formal.charOffset, formal.name.length, formal.fileUri);
        }
        libraryBuilder.addPrimaryConstructorField(
            // TODO(johnniwinther): Support annotations on annotations on fields
            // defined through a primary constructor. This is not needed for
            // extension types where the field is not part of the AST but will
            // be needed when primary constructors are generally supported.
            metadata: null,
            type: formal.type,
            name: formal.name,
            charOffset: formal.charOffset);
        formals[i] = formal.forPrimaryConstructor(libraryBuilder);
      }
    }

    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.constructor, "#method",
        hasMembers: false);
    TypeParameterScopeBuilder scopeBuilder = libraryBuilder
        .endNestedDeclaration(TypeParameterScopeKind.constructor, "#method");
    var (
      List<NominalVariableBuilder>? typeVariables,
      _
    ) = _createSyntheticTypeVariables(
        libraryBuilder.currentTypeParameterScopeBuilder, scopeBuilder, null);
    scopeBuilder.resolveNamedTypes(typeVariables, libraryBuilder);

    libraryBuilder.addPrimaryConstructor(
        constructorName: constructorName == "new" ? "" : constructorName,
        charOffset: charOffset,
        formals: formals,
        typeVariables: typeVariables,
        isConst: constKeyword != null);
  }

  ProcedureKind computeProcedureKind(Token? token) {
    if (token == null) return ProcedureKind.Method;
    if (optional("get", token)) return ProcedureKind.Getter;
    if (optional("set", token)) return ProcedureKind.Setter;
    return unhandled(
        token.lexeme, "computeProcedureKind", token.charOffset, uri);
  }

  @override
  void beginTopLevelMethod(
      Token lastConsumed, Token? augmentToken, Token? externalToken) {
    pushDeclarationContext(DeclarationContext.TopLevelMethod);
    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.topLevelMethod, "#method",
        hasMembers: false);
    int modifiers = 0;
    if (augmentToken != null) {
      modifiers |= augmentMask;
    }
    if (externalToken != null) {
      modifiers |= externalMask;
    }
    push(modifiers);
  }

  @override
  void endTopLevelMethod(Token beginToken, Token? getOrSet, Token endToken) {
    debugEvent("endTopLevelMethod");
    assert(checkState(beginToken, [
      ValueKinds.MethodBody,
      ValueKinds.AsyncMarker,
      ValueKinds.FormalListOrNull,
      /* formalsOffset */ ValueKinds.Integer,
      ValueKinds.NominalVariableListOrNull,
      ValueKinds.IdentifierOrParserRecovery,
      ValueKinds.TypeBuilderOrNull,
      /* modifiers */ ValueKinds.Integer,
      ValueKinds.MetadataListOrNull,
    ]));

    MethodBody kind = pop() as MethodBody;
    AsyncMarker asyncModifier = pop() as AsyncMarker;
    List<FormalParameterBuilder>? formals =
        pop() as List<FormalParameterBuilder>?;
    int formalsOffset = popCharOffset();
    List<NominalVariableBuilder>? typeVariables =
        pop() as List<NominalVariableBuilder>?;
    Object? identifier = pop();
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
        .resolveNamedTypes(typeVariables, libraryBuilder);
    if (identifier is Identifier) {
      final int startCharOffset =
          metadata == null ? beginToken.charOffset : metadata.first.charOffset;
      libraryBuilder.addProcedure(
          metadata,
          modifiers,
          returnType,
          identifier.name,
          typeVariables,
          formals,
          computeProcedureKind(getOrSet),
          startCharOffset,
          identifier.nameOffset,
          formalsOffset,
          endToken.charOffset,
          nativeMethodName,
          asyncModifier,
          isInstanceMember: false,
          isExtensionMember: false,
          isExtensionTypeMember: false);
      nativeMethodName = null;
    }
    popDeclarationContext(DeclarationContext.TopLevelMethod);
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
      DeclarationKind declarationKind,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? varFinalOrConst,
      Token? getOrSet,
      Token name) {
    inConstructor =
        name.lexeme == libraryBuilder.currentTypeParameterScopeBuilder.name &&
            getOrSet == null;
    DeclarationContext declarationContext;
    switch (declarationKind) {
      case DeclarationKind.TopLevel:
        assert(
            false,
            "Expected top level method to be handled by "
            "`beginTopLevelMethod`.");
        declarationContext = DeclarationContext.TopLevelMethod;
        break;
      case DeclarationKind.Class:
        if (inConstructor) {
          declarationContext = DeclarationContext.ClassConstructor;
        } else if (staticToken != null) {
          declarationContext = DeclarationContext.ClassStaticMethod;
        } else {
          declarationContext = DeclarationContext.ClassInstanceMethod;
        }
        break;
      case DeclarationKind.Mixin:
        if (inConstructor) {
          declarationContext = DeclarationContext.MixinConstructor;
        } else if (staticToken != null) {
          declarationContext = DeclarationContext.MixinStaticMethod;
        } else {
          declarationContext = DeclarationContext.MixinInstanceMethod;
        }
        break;
      case DeclarationKind.Extension:
        if (inConstructor) {
          declarationContext = DeclarationContext.ExtensionConstructor;
        } else if (staticToken != null) {
          declarationContext = DeclarationContext.ExtensionStaticMethod;
        } else {
          declarationContext = DeclarationContext.ExtensionInstanceMethod;
        }
        break;
      case DeclarationKind.ExtensionType:
        if (inConstructor) {
          declarationContext = DeclarationContext.ExtensionTypeConstructor;
        } else if (staticToken != null) {
          declarationContext = DeclarationContext.ExtensionTypeStaticMethod;
        } else {
          declarationContext = DeclarationContext.ExtensionTypeInstanceMethod;
        }
        break;
      case DeclarationKind.Enum:
        if (inConstructor) {
          declarationContext = DeclarationContext.EnumConstructor;
        } else if (staticToken != null) {
          declarationContext = DeclarationContext.EnumStaticMethod;
        } else {
          declarationContext = DeclarationContext.EnumInstanceMethod;
        }
    }
    pushDeclarationContext(declarationContext);

    List<Modifier>? modifiers;
    if (augmentToken != null) {
      modifiers ??= <Modifier>[];
      modifiers.add(Augment);
    }
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
    push(modifiers ?? NullValues.Modifiers);
    TypeParameterScopeKind kind;
    if (inConstructor) {
      kind = TypeParameterScopeKind.constructor;
    } else if (staticToken != null) {
      kind = TypeParameterScopeKind.staticMethod;
    } else {
      kind = TypeParameterScopeKind.instanceMethod;
    }
    libraryBuilder.beginNestedDeclaration(kind, "#method", hasMembers: false);
  }

  @override
  void endClassMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    debugEvent("endClassMethod");
    _endClassMethod(getOrSet, beginToken, beginParam, beginInitializers,
        endToken, _MethodKind.classMethod);
  }

  @override
  void endClassConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    debugEvent("endClassConstructor");
    _endClassMethod(getOrSet, beginToken, beginParam, beginInitializers,
        endToken, _MethodKind.classConstructor);
  }

  @override
  void endMixinMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    debugEvent("endMixinMethod");
    _endClassMethod(getOrSet, beginToken, beginParam, beginInitializers,
        endToken, _MethodKind.mixinMethod);
  }

  @override
  void endExtensionMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    debugEvent("endExtensionMethod");
    _endClassMethod(getOrSet, beginToken, beginParam, beginInitializers,
        endToken, _MethodKind.extensionMethod);
  }

  @override
  void endExtensionTypeMethod(Token? getOrSet, Token beginToken,
      Token beginParam, Token? beginInitializers, Token endToken) {
    debugEvent("endExtensionTypeMethod");
    _endClassMethod(getOrSet, beginToken, beginParam, beginInitializers,
        endToken, _MethodKind.extensionTypeMethod);
  }

  @override
  void endMixinConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    debugEvent("endMixinConstructor");
    _endClassMethod(getOrSet, beginToken, beginParam, beginInitializers,
        endToken, _MethodKind.mixinConstructor);
  }

  @override
  void endExtensionConstructor(Token? getOrSet, Token beginToken,
      Token beginParam, Token? beginInitializers, Token endToken) {
    debugEvent("endExtensionConstructor");
    _endClassMethod(getOrSet, beginToken, beginParam, beginInitializers,
        endToken, _MethodKind.extensionConstructor);
  }

  @override
  void endExtensionTypeConstructor(Token? getOrSet, Token beginToken,
      Token beginParam, Token? beginInitializers, Token endToken) {
    debugEvent("endExtensionTypeConstructor");
    _endClassMethod(getOrSet, beginToken, beginParam, beginInitializers,
        endToken, _MethodKind.extensionTypeConstructor);
  }

  (List<NominalVariableBuilder>?, Map<NominalVariableBuilder, TypeBuilder>?)
      _createSyntheticTypeVariables(
          TypeParameterScopeBuilder enclosingDeclarationScopeBuilder,
          TypeParameterScopeBuilder memberScopeBuilder,
          List<NominalVariableBuilder>? typeVariables) {
    Map<NominalVariableBuilder, TypeBuilder>? substitution;
    if (enclosingDeclarationScopeBuilder.typeVariables != null) {
      // We synthesize the names of the generated [TypeParameter]s, i.e.
      // rename 'T' to '#T'. We cannot do it on the builders because their
      // names are used to create the scope.
      List<NominalVariableBuilder> synthesizedTypeVariables =
          libraryBuilder.copyTypeVariables(
              enclosingDeclarationScopeBuilder.typeVariables!,
              memberScopeBuilder,
              kind: TypeVariableKind.extensionSynthesized);
      substitution = {};
      for (int i = 0; i < synthesizedTypeVariables.length; i++) {
        substitution[enclosingDeclarationScopeBuilder.typeVariables![i]] =
            new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
                synthesizedTypeVariables[i], const NullabilityBuilder.omitted(),
                instanceTypeVariableAccess:
                    declarationContext.instanceTypeVariableAccessState);
      }
      if (typeVariables != null) {
        typeVariables = synthesizedTypeVariables..addAll(typeVariables);
      } else {
        typeVariables = synthesizedTypeVariables;
      }
    }
    return (typeVariables, substitution);
  }

  void _endClassMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken, _MethodKind methodKind) {
    assert(checkState(beginToken, [ValueKinds.MethodBody]));
    MethodBody bodyKind = pop() as MethodBody;
    if (bodyKind == MethodBody.RedirectingFactoryBody) {
      // This will cause an error later.
      pop();
    }
    assert(checkState(beginToken, [
      ValueKinds.AsyncModifier,
      ValueKinds.FormalListOrNull,
      ValueKinds.Integer, // formals offset
      ValueKinds.NominalVariableListOrNull,
      ValueKinds.IdentifierOrParserRecovery,
      ValueKinds.TypeBuilderOrNull,
      ValueKinds.ModifiersOrNull,
      ValueKinds.Integer, // var/final/const offset
      ValueKinds.MetadataListOrNull,
    ]));

    AsyncMarker asyncModifier = pop() as AsyncMarker;
    List<FormalParameterBuilder>? formals =
        pop() as List<FormalParameterBuilder>?;
    int formalsOffset = popCharOffset();
    List<NominalVariableBuilder>? typeVariables =
        pop() as List<NominalVariableBuilder>?;
    Object? identifier = pop();
    TypeBuilder? returnType = pop() as TypeBuilder?;
    int modifiers = Modifier.toMask(pop() as List<Modifier>?);
    int varFinalOrConstOffset = popCharOffset();
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;

    TypeParameterScopeKind scopeKind;
    if (inConstructor) {
      scopeKind = TypeParameterScopeKind.constructor;
    } else if ((modifiers & staticMask) != 0) {
      scopeKind = TypeParameterScopeKind.staticMethod;
    } else {
      scopeKind = TypeParameterScopeKind.instanceMethod;
    }
    TypeParameterScopeBuilder declarationBuilder =
        libraryBuilder.endNestedDeclaration(scopeKind, "#method");

    if (identifier is! Identifier) {
      assert(identifier is ParserRecovery,
          "Unexpected identifier $identifier (${identifier.runtimeType})");
      nativeMethodName = null;
      inConstructor = false;
      declarationBuilder.resolveNamedTypes(typeVariables, libraryBuilder);
      popDeclarationContext();
      return;
    }

    Operator? operator = identifier.operator;
    // TODO(johnniwinther): Find a uniform way to compute this.
    bool hasNoFormals = formals == null;
    if (Operator.subtract == operator && hasNoFormals) {
      operator = Operator.unaryMinus;
    }
    String name;
    ProcedureKind kind;
    int charOffset = identifier.qualifierOffset;
    if (operator != null) {
      name = operator.text;
      kind = ProcedureKind.Operator;
      int requiredArgumentCount = operator.requiredArgumentCount;
      if ((formals?.length ?? 0) != requiredArgumentCount) {
        Template<Message Function(String name)> template;
        switch (requiredArgumentCount) {
          case 0:
            template = templateOperatorParameterMismatch0;
            break;

          case 1:
            if (Operator.subtract == operator) {
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
                identifier.nameOffset, uri);
        }
        addProblem(template.withArguments(name), charOffset, name.length);
      } else {
        if (formals != null) {
          for (FormalParameterBuilder formal in formals) {
            if (!formal.isRequiredPositional) {
              addProblem(messageOperatorWithOptionalFormals, formal.charOffset,
                  formal.name.length);
            }
          }
        }
      }
      if (typeVariables != null) {
        NominalVariableBuilder typeVariableBuilder = typeVariables.first;
        addProblem(messageOperatorWithTypeParameters,
            typeVariableBuilder.charOffset, typeVariableBuilder.name.length);
      }
    } else {
      name = identifier.name;
      kind = computeProcedureKind(getOrSet);
    }
    bool isAbstract = bodyKind == MethodBody.Abstract;
    if (isAbstract) {
      // An error has been reported if this wasn't already sync.
      asyncModifier = AsyncMarker.Sync;
    }
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
    if (operator == Operator.indexSet &&
        returnType != null &&
        !returnType.isVoidType) {
      addProblem(messageNonVoidReturnOperator,
          returnType.charOffset ?? beginToken.offset, noLength);
      // Use implicit void as recovery.
      returnType = null;
    }

    modifiers = Modifier.addAbstractMask(modifiers, isAbstract: isAbstract);
    if (nativeMethodName != null) {
      modifiers |= externalMask;
    }
    bool isConst = (modifiers & constMask) != 0;

    String? constructorName;
    switch (methodKind) {
      case _MethodKind.classConstructor:
      case _MethodKind.mixinConstructor:
      case _MethodKind.extensionConstructor:
      case _MethodKind.extensionTypeConstructor:
      case _MethodKind.enumConstructor:
        constructorName =
            libraryBuilder.computeAndValidateConstructorName(identifier) ??
                name;
        break;
      case _MethodKind.classMethod:
      case _MethodKind.mixinMethod:
      case _MethodKind.extensionMethod:
      case _MethodKind.extensionTypeMethod:
      case _MethodKind.enumMethod:
        break;
    }
    bool isStatic = (modifiers & staticMask) != 0;
    bool isConstructor = constructorName != null;
    if (!isStatic &&
        (libraryBuilder.currentTypeParameterScopeBuilder.kind ==
                TypeParameterScopeKind.extensionDeclaration ||
            libraryBuilder.currentTypeParameterScopeBuilder.kind ==
                TypeParameterScopeKind.inlineClassDeclaration ||
            libraryBuilder.currentTypeParameterScopeBuilder.kind ==
                TypeParameterScopeKind.extensionTypeDeclaration)) {
      TypeParameterScopeBuilder declaration =
          libraryBuilder.currentTypeParameterScopeBuilder;
      Map<NominalVariableBuilder, TypeBuilder>? substitution;
      (typeVariables, substitution) = _createSyntheticTypeVariables(
          declaration, declarationBuilder, typeVariables);
      if (!isConstructor) {
        List<FormalParameterBuilder> synthesizedFormals = [];
        TypeBuilder thisType;
        if (declaration.kind == TypeParameterScopeKind.extensionDeclaration) {
          thisType = declaration.extensionThisType;
        } else {
          thisType = libraryBuilder.addNamedType(
              new SyntheticTypeName(declaration.name, charOffset),
              const NullabilityBuilder.omitted(),
              declaration.typeVariables != null
                  ? new List<TypeBuilder>.generate(
                      declaration.typeVariables!.length,
                      (int index) =>
                          new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
                              typeVariables![index],
                              const NullabilityBuilder.omitted(),
                              instanceTypeVariableAccess:
                                  InstanceTypeVariableAccessState.Allowed))
                  : null,
              charOffset,
              instanceTypeVariableAccess:
                  InstanceTypeVariableAccessState.Allowed);
        }
        if (substitution != null) {
          List<NamedTypeBuilder> unboundTypes = [];
          List<StructuralVariableBuilder> unboundTypeVariables = [];
          thisType = substitute(thisType, substitution,
              unboundTypes: unboundTypes,
              unboundTypeVariables: unboundTypeVariables);
          for (NamedTypeBuilder unboundType in unboundTypes) {
            declaration.registerUnresolvedNamedType(unboundType);
          }
          libraryBuilder.unboundStructuralVariables
              .addAll(unboundTypeVariables);
        }
        synthesizedFormals.add(new FormalParameterBuilder(
            FormalParameterKind.requiredPositional,
            finalMask,
            thisType,
            syntheticThisName,
            null,
            charOffset,
            fileUri: uri,
            isExtensionThis: true,
            hasImmediatelyDeclaredInitializer: false));
        if (formals != null) {
          synthesizedFormals.addAll(formals);
        }
        formals = synthesizedFormals;
      }
    }

    declarationBuilder.resolveNamedTypes(typeVariables, libraryBuilder);
    if (constructorName != null) {
      if (isConst &&
          bodyKind != MethodBody.Abstract &&
          !libraryFeatures.constFunctions.isEnabled) {
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
          forAbstractClassOrMixin: inAbstractOrSealedClass ||
              methodKind == _MethodKind.mixinConstructor);
    } else {
      if (isConst) {
        // TODO(danrubel): consider removing this
        // because it is an error to have a const method.
        modifiers &= ~constMask;
      }
      final int startCharOffset =
          metadata == null ? beginToken.charOffset : metadata.first.charOffset;
      bool isExtensionMember = methodKind == _MethodKind.extensionMethod;
      bool isExtensionTypeMember =
          methodKind == _MethodKind.extensionTypeMethod;
      libraryBuilder.addProcedure(
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
          asyncModifier,
          isInstanceMember: !isStatic,
          isExtensionMember: isExtensionMember,
          isExtensionTypeMember: isExtensionTypeMember);
    }
    nativeMethodName = null;
    inConstructor = false;
    popDeclarationContext();
  }

  @override
  void handleNamedMixinApplicationWithClause(Token withKeyword) {
    debugEvent("NamedMixinApplicationWithClause");
    assert(checkState(withKeyword, [
      /* mixins */ unionOfKinds([
        ValueKinds.ParserRecovery,
        ValueKinds.TypeBuilderListOrNull,
      ]),
      /* supertype */ unionOfKinds([
        ValueKinds.ParserRecovery,
        ValueKinds.TypeBuilder,
      ]),
    ]));
    Object? mixins = pop();
    if (mixins is ParserRecovery) {
      push(mixins);
    } else {
      push(libraryBuilder.addMixinApplication(
          mixins as List<TypeBuilder>, withKeyword.charOffset));
    }
    assert(checkState(withKeyword, [
      /* mixin application */ unionOfKinds([
        ValueKinds.ParserRecovery,
        ValueKinds.MixinApplicationBuilder,
      ]),
      /* supertype */ unionOfKinds([
        ValueKinds.ParserRecovery,
        ValueKinds.TypeBuilder,
      ]),
    ]));
  }

  @override
  void handleNamedArgument(Token colon) {
    debugEvent("handleNamedArgument");
    assert(checkState(colon, [
      ValueKinds.IdentifierOrParserRecovery,
    ]));

    pop(); // Named argument name.
  }

  @override
  void handleNamedRecordField(Token colon) {
    debugEvent("handleNamedRecordField");
    assert(checkState(colon, [
      ValueKinds.IdentifierOrParserRecovery,
    ]));

    pop(); // Named record field name.
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equals, Token? implementsKeyword, Token endToken) {
    debugEvent("endNamedMixinApplication");
    assert(checkState(beginToken, [
      if (implementsKeyword != null)
        /* interfaces */ unionOfKinds([
          ValueKinds.ParserRecovery,
          ValueKinds.TypeBuilderListOrNull,
        ]),
      /* mixin application */ unionOfKinds([
        ValueKinds.ParserRecovery,
        ValueKinds.MixinApplicationBuilder,
      ]),
      /* supertype */ unionOfKinds([
        ValueKinds.ParserRecovery,
        ValueKinds.TypeBuilder,
      ]),
      /* mixin token */ ValueKinds.TokenOrNull,
      /* augment token */ ValueKinds.TokenOrNull,
      /* final token */ ValueKinds.TokenOrNull,
      /* interface token */ ValueKinds.TokenOrNull,
      /* base token */ ValueKinds.TokenOrNull,
      /* sealed token */ ValueKinds.TokenOrNull,
      /* macro token */ ValueKinds.TokenOrNull,
      /* modifiers */ ValueKinds.Integer,
      /* type variables */ ValueKinds.NominalVariableListOrNull,
      /* name */ ValueKinds.IdentifierOrParserRecovery,
      /* metadata */ ValueKinds.MetadataListOrNull,
    ]));

    List<TypeBuilder>? interfaces =
        nullIfParserRecovery(popIfNotNull(implementsKeyword))
            as List<TypeBuilder>?;
    Object? mixinApplication = pop();
    Object? supertype = pop();
    Token? mixinToken = pop(NullValues.Token) as Token?;
    Token? augmentToken = pop(NullValues.Token) as Token?;
    Token? finalToken = pop(NullValues.Token) as Token?;
    Token? interfaceToken = pop(NullValues.Token) as Token?;
    Token? baseToken = pop(NullValues.Token) as Token?;
    Token? sealedToken = pop(NullValues.Token) as Token?;
    Token? macroToken = pop(NullValues.Token) as Token?;
    int modifiers = pop() as int;
    List<NominalVariableBuilder>? typeVariables =
        pop() as List<NominalVariableBuilder>?;
    Object? name = pop();
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    checkEmpty(beginToken.charOffset);
    if (name is ParserRecovery ||
        supertype is ParserRecovery ||
        mixinApplication is ParserRecovery) {
      libraryBuilder
          .endNestedDeclaration(
              TypeParameterScopeKind.namedMixinApplication, "<syntax-error>")
          .resolveNamedTypes(typeVariables, libraryBuilder);
    } else {
      Identifier identifier = name as Identifier;
      if (libraryBuilder.isNonNullableByDefault) {
        String classNameForErrors = identifier.name;
        MixinApplicationBuilder mixinApplicationBuilder =
            mixinApplication as MixinApplicationBuilder;
        List<TypeBuilder> mixins = mixinApplicationBuilder.mixins;
        if (supertype is TypeBuilder && supertype is! MixinApplicationBuilder) {
          if (supertype.nullabilityBuilder.build(libraryBuilder) ==
              Nullability.nullable) {
            libraryBuilder.addProblem(
                templateNullableSuperclassError
                    .withArguments(supertype.fullNameForErrors),
                identifier.nameOffset,
                classNameForErrors.length,
                uri);
          }
        }
        for (TypeBuilder mixin in mixins) {
          if (mixin.nullabilityBuilder.build(libraryBuilder) ==
              Nullability.nullable) {
            libraryBuilder.addProblem(
                templateNullableMixinError
                    .withArguments(mixin.fullNameForErrors),
                identifier.nameOffset,
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
                  identifier.nameOffset,
                  classNameForErrors.length,
                  uri);
            }
          }
        }
      }
      if (sealedToken != null) {
        modifiers |= abstractMask;
      }

      int startCharOffset = beginToken.charOffset;
      int charEndOffset = endToken.charOffset;
      libraryBuilder.addNamedMixinApplication(
          metadata,
          identifier.name,
          typeVariables,
          modifiers,
          supertype as TypeBuilder?,
          mixinApplication as MixinApplicationBuilder,
          interfaces,
          startCharOffset,
          identifier.nameOffset,
          charEndOffset,
          isMacro: macroToken != null,
          isSealed: sealedToken != null,
          isBase: baseToken != null,
          isInterface: interfaceToken != null,
          isFinal: finalToken != null,
          isAugmentation: augmentToken != null,
          isMixinClass: mixinToken != null);
    }
    popDeclarationContext(DeclarationContext.NamedMixinApplication);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("endTypeArguments");
    push(const FixedNullableList<TypeBuilder>()
            .popNonNullable(stack, count, dummyTypeBuilder) ??
        NullValues.TypeArguments);
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    debugEvent("endArguments");
    push(beginToken);
  }

  @override
  void handleInvalidTypeArguments(Token token) {
    debugEvent("handleInvalidTypeArguments");
    pop(NullValues.TypeArguments);
  }

  @override
  void handleScript(Token token) {
    debugEvent("handleScript");
    libraryBuilder.addScriptToken(token.charOffset);
  }

  @override
  void handleNonNullAssertExpression(Token bang) {
    if (!libraryBuilder.isNonNullableByDefault) {
      reportNonNullAssertExpressionNotEnabled(bang);
    }
  }

  @override
  void handleType(Token beginToken, Token? questionMark) {
    debugEvent("handleType");
    assert(checkState(beginToken, [
      /* type arguments = */ ValueKinds.TypeArgumentsOrNull,
      /* identifier */ ValueKinds.IdentifierOrParserRecovery,
    ]));
    if (!libraryBuilder.isNonNullableByDefault) {
      reportErrorIfNullableType(questionMark);
    }
    bool isMarkedAsNullable = questionMark != null;
    List<TypeBuilder>? arguments = pop() as List<TypeBuilder>?;
    Object name = pop()!;
    if (name is ParserRecovery) {
      push(name);
    } else {
      Identifier identifier = name as Identifier;
      push(libraryBuilder.addNamedType(
          identifier.typeName,
          libraryBuilder.nullableBuilderIfTrue(isMarkedAsNullable),
          arguments,
          identifier.qualifierOffset,
          instanceTypeVariableAccess:
              declarationContext.instanceTypeVariableAccessState));
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
  void handleNoArguments(Token token) {
    debugEvent("NoArguments");
    push(NullValues.Arguments);
  }

  @override
  void handleNoTypeVariables(Token token) {
    super.handleNoTypeVariables(token);
    inConstructorName = false;
  }

  @override
  void handleNoTypeArguments(Token token) {
    debugEvent("NoTypeArguments");
    push(NullValues.TypeArguments);
  }

  @override
  void handleNoTypeNameInConstructorReference(Token token) {
    debugEvent("NoTypeNameInConstructorReference");
    push(NullValues.Identifier);
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
    _insideOfFormalParameterType = true;
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
      Token? superKeyword,
      Token? periodAfterThisOrSuper,
      Token nameToken,
      Token? initializerStart,
      Token? initializerEnd,
      FormalParameterKind kind,
      MemberKind memberKind) {
    debugEvent("endFormalParameter");
    assert(checkState(nameToken, [
      ValueKinds.IdentifierOrParserRecoveryOrNull,
      unionOfKinds([
        ValueKinds.TypeBuilderOrNull,
        ValueKinds.ParserRecovery,
      ]),
      /* modifiers */ ValueKinds.Integer,
      ValueKinds.MetadataListOrNull,
    ]));

    _insideOfFormalParameterType = false;

    if (superKeyword != null) {
      reportIfNotEnabled(libraryFeatures.superParameters,
          superKeyword.charOffset, superKeyword.length);
    }

    Object? name = pop(NullValues.Identifier);
    TypeBuilder? type = nullIfParserRecovery(pop()) as TypeBuilder?;
    int modifiers = pop() as int;
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    if (name is ParserRecovery) {
      push(name);
    } else {
      Identifier? identifier = name as Identifier?;
      push(libraryBuilder.addFormalParameter(
          metadata,
          kind,
          modifiers,
          type ??
              (memberKind.isParameterInferable
                  ? libraryBuilder.addInferableType()
                  : const ImplicitTypeBuilder()),
          identifier == null
              ? FormalParameterBuilder.noNameSentinel
              : identifier.name,
          thisKeyword != null,
          superKeyword != null,
          identifier?.nameOffset ?? nameToken.charOffset,
          initializerStart));
    }
  }

  @override
  void beginFormalParameterDefaultValueExpression() {
    _insideOfFormalParameterType = false;
  }

  @override
  void endFormalParameterDefaultValueExpression() {
    debugEvent("endFormalParameterDefaultValueExpression");
    // Ignored for now.
  }

  @override
  void handleValuedFormalParameter(
      Token equals, Token token, FormalParameterKind kind) {
    debugEvent("handleValuedFormalParameter");
    // Ignored for now.
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    debugEvent("handleFormalParameterWithoutValue");
    // Ignored for now.
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    debugEvent("endOptionalFormalParameters");
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
    if (formals == null &&
        declarationContext == DeclarationContext.ExtensionType &&
        kind == MemberKind.PrimaryConstructor) {
      // In case of primary constructors of extension types, an error is
      // reported by the parser if the formals together with the parentheses
      // around them are missing. To distinguish that case from the case of the
      // formal parameters present, but lacking the representation field, we
      // pass the empty list further along instead of `null`.
      formals = const [];
    }
    push(beginToken.charOffset);
    push(formals ?? NullValues.FormalParameters);
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
  void beginEnum(Token enumKeyword) {
    assert(checkState(enumKeyword, [
      ValueKinds.IdentifierOrParserRecovery,
    ]));
    Object? identifier = peek();

    String declarationName;
    if (identifier is Identifier) {
      declarationName = identifier.name;
    } else {
      declarationName = '#enum';
    }
    libraryBuilder.beginIndexedContainer(declarationName,
        isExtensionTypeDeclaration: false);
    pushDeclarationContext(DeclarationContext.Enum);
    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.enumDeclaration, declarationName);
  }

  @override
  void handleEnumElement(Token beginToken) {
    debugEvent("handleEnumElement");
    assert(checkState(beginToken, [
      /* argumentsBeginToken */ ValueKinds.ArgumentsTokenOrNull,
      ValueKinds.ConstructorReferenceBuilderOrNull,
      ValueKinds.EnumConstantInfoOrParserRecovery,
    ]));

    Token? argumentsBeginToken = pop() as Token?;

    ConstructorReferenceBuilder? constructorReferenceBuilder =
        pop() as ConstructorReferenceBuilder?;
    Object? enumConstantInfo = pop();
    if (enumConstantInfo is EnumConstantInfo) {
      push(enumConstantInfo
        ..constructorReferenceBuilder = constructorReferenceBuilder
        ..argumentsBeginToken = argumentsBeginToken);
    } else {
      assert(enumConstantInfo is ParserRecovery);
      push(NullValues.EnumConstantInfo);
    }
  }

  @override
  void handleEnumHeader(Token enumKeyword, Token leftBrace) {
    assert(checkState(enumKeyword, [
      /* interfaces */ ValueKinds.TypeBuilderListOrNull,
      /* mixins */ unionOfKinds([
        ValueKinds.MixinApplicationBuilderOrNull,
        ValueKinds.ParserRecovery,
      ]),
      /* type variables */ ValueKinds.NominalVariableListOrNull,
      /* name */ ValueKinds.IdentifierOrParserRecovery,
    ]));
    debugEvent("EnumHeader");

    // We pop more values than needed to reach typeVariables, offset and name.
    List<TypeBuilder>? interfaces =
        pop(NullValues.TypeBuilderList) as List<TypeBuilder>?;
    Object? mixins = pop(NullValues.MixinApplicationBuilder);
    List<NominalVariableBuilder>? typeVariables =
        pop() as List<NominalVariableBuilder>?;

    Object? identifier = peek();
    if (identifier is Identifier) {
      libraryBuilder.currentTypeParameterScopeBuilder.markAsEnumDeclaration(
          identifier.name, identifier.nameOffset, typeVariables);
    } else {
      identifier as ParserRecovery;
      libraryBuilder.currentTypeParameterScopeBuilder.markAsEnumDeclaration(
          "<syntax-error>", identifier.charOffset, typeVariables);
    }

    push(typeVariables ?? NullValues.NominalVariables);
    push(mixins ?? NullValues.MixinApplicationBuilder);
    push(interfaces ?? NullValues.TypeBuilderList);

    push(enumKeyword.charOffset); // start char offset.
    push(leftBrace.endGroup!.charOffset); // end char offset.
  }

  @override
  void handleEnumElements(Token elementsEndToken, int elementsCount) {
    debugEvent("handleEnumElements");
    push(elementsCount);
  }

  @override
  void endEnum(Token beginToken, Token enumKeyword, Token leftBrace,
      int memberCount, Token endToken) {
    assert(checkState(beginToken, [
      /* element count */ ValueKinds.Integer,
    ]));
    debugEvent("endEnum");

    int elementsCount = pop() as int;

    assert(checkState(beginToken, [
      /* enum constants */ ...repeatedKind(
          ValueKinds.EnumConstantInfoOrNull, elementsCount),
      /* endCharOffset */ ValueKinds.Integer,
      /* startCharOffset */ ValueKinds.Integer,
      /* interfaces */ ValueKinds.TypeBuilderListOrNull,
      /* mixins */ unionOfKinds([
        ValueKinds.MixinApplicationBuilderOrNull,
        ValueKinds.ParserRecovery,
      ]),
      /* type variables */ ValueKinds.NominalVariableListOrNull,
      /* name */ ValueKinds.IdentifierOrParserRecovery,
      /* metadata */ ValueKinds.MetadataListOrNull,
    ]));

    List<EnumConstantInfo?>? enumConstantInfos =
        const FixedNullableList<EnumConstantInfo>().pop(stack, elementsCount);

    if (enumConstantInfos != null) {
      List<EnumConstantInfo?>? parsedEnumConstantInfos;
      for (int index = 0; index < enumConstantInfos.length; index++) {
        EnumConstantInfo? info = enumConstantInfos[index];
        if (info == null) {
          parsedEnumConstantInfos = enumConstantInfos.take(index).toList();
        } else if (parsedEnumConstantInfos != null) {
          parsedEnumConstantInfos.add(info);
        }
      }
      if (parsedEnumConstantInfos != null) {
        if (parsedEnumConstantInfos.isEmpty) {
          enumConstantInfos = null;
        } else {
          enumConstantInfos = parsedEnumConstantInfos;
        }
      }
    }

    int endCharOffset = popCharOffset();
    int startCharOffset = popCharOffset();
    List<TypeBuilder>? interfaces =
        nullIfParserRecovery(pop()) as List<TypeBuilder>?;
    MixinApplicationBuilder? mixinBuilder =
        nullIfParserRecovery(pop()) as MixinApplicationBuilder?;
    List<NominalVariableBuilder>? typeVariables =
        pop() as List<NominalVariableBuilder>?;
    Object? identifier = pop();
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    checkEmpty(startCharOffset);

    if (identifier is Identifier) {
      if (interfaces != null) {
        for (TypeBuilder interface in interfaces) {
          if (interface.nullabilityBuilder.build(libraryBuilder) ==
              Nullability.nullable) {
            libraryBuilder.addProblem(
                templateNullableInterfaceError
                    .withArguments(interface.fullNameForErrors),
                interface.charOffset ?? startCharOffset,
                identifier.name.length,
                uri);
          }
        }
      }

      libraryBuilder.addEnum(
          metadata,
          identifier.name,
          typeVariables,
          mixinBuilder,
          interfaces,
          enumConstantInfos,
          startCharOffset,
          identifier.nameOffset,
          endCharOffset);
    } else {
      libraryBuilder
          .endNestedDeclaration(
              TypeParameterScopeKind.enumDeclaration, "<syntax-error>")
          .resolveNamedTypes(typeVariables, libraryBuilder);
    }

    libraryBuilder.endIndexedContainer();
    checkEmpty(enumKeyword.charOffset);
    popDeclarationContext(DeclarationContext.Enum);
  }

  @override
  void beginTypedef(Token token) {
    pushDeclarationContext(DeclarationContext.Typedef);
    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.typedef, "#typedef",
        hasMembers: false);
  }

  @override
  void beginFunctionType(Token beginToken) {
    debugEvent("beginFunctionType");
    _structuralParameterDepthLevel++;
    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.functionType, "#function_type",
        hasMembers: false);
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    debugEvent("beginFunctionTypedFormalParameter");
    _insideOfFormalParameterType = false;
    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.functionType, "#function_type",
        hasMembers: false);
  }

  @override
  void endRecordType(
      Token leftBracket, Token? questionMark, int count, bool hasNamedFields) {
    debugEvent("RecordType");
    assert(checkState(leftBracket, [
      if (hasNamedFields) ValueKinds.RecordTypeFieldBuilderListOrNull,
      ...repeatedKind(ValueKinds.RecordTypeFieldBuilder,
          hasNamedFields ? count - 1 : count),
    ]));

    if (!libraryFeatures.records.isEnabled) {
      addProblem(
          templateExperimentNotEnabledOffByDefault
              .withArguments(ExperimentalFlag.records.name),
          leftBracket.offset,
          noLength);
    }

    if (!libraryBuilder.isNonNullableByDefault) {
      reportErrorIfNullableType(questionMark);
    }

    List<RecordTypeFieldBuilder>? namedFields;
    if (hasNamedFields) {
      namedFields =
          pop(NullValues.RecordTypeFieldList) as List<RecordTypeFieldBuilder>?;
    }
    List<RecordTypeFieldBuilder>? positionalFields =
        const FixedNullableList<RecordTypeFieldBuilder>().popNonNullable(stack,
            hasNamedFields ? count - 1 : count, dummyRecordTypeFieldBuilder);

    push(new RecordTypeBuilderImpl(
      positionalFields,
      namedFields,
      questionMark != null
          ? libraryBuilder.nullableBuilder
          : libraryBuilder.nonNullableBuilder,
      uri,
      leftBracket.charOffset,
    ));
  }

  @override
  void endRecordTypeEntry() {
    debugEvent("endRecordTypeEntry");
    assert(checkState(null, [
      ValueKinds.IdentifierOrParserRecoveryOrNull,
      unionOfKinds([
        ValueKinds.TypeBuilder,
        ValueKinds.ParserRecovery,
      ]),
      ValueKinds.MetadataListOrNull,
    ]));

    // Offset of name of field (or next token if there's no name).
    Object? identifier = pop(NullValues.Identifier);
    Object? type = pop();
    List<MetadataBuilder>? metadata =
        pop(NullValues.Metadata) as List<MetadataBuilder>?;
    push(new RecordTypeFieldBuilder(
        metadata,
        type is ParserRecovery
            ? new InvalidTypeBuilderImpl(uri, type.charOffset)
            : type as TypeBuilder,
        identifier is Identifier ? identifier.name : null,
        identifier is Identifier ? identifier.nameOffset : -1));
  }

  @override
  void endRecordTypeNamedFields(int count, Token leftBracket) {
    assert(checkState(leftBracket, [
      ...repeatedKind(ValueKinds.RecordTypeFieldBuilder, count),
    ]));
    List<RecordTypeFieldBuilder>? fields =
        const FixedNullableList<RecordTypeFieldBuilder>()
            .popNonNullable(stack, count, dummyRecordTypeFieldBuilder);
    push(fields ?? NullValues.RecordTypeFieldList);
  }

  @override
  void endFunctionType(Token functionToken, Token? questionMark) {
    debugEvent("FunctionType");
    _structuralParameterDepthLevel--;
    if (!libraryBuilder.isNonNullableByDefault) {
      reportErrorIfNullableType(questionMark);
    }
    List<FormalParameterBuilder>? formals =
        pop() as List<FormalParameterBuilder>?;
    pop(); // formals offset
    TypeBuilder? returnType = pop() as TypeBuilder?;
    List<StructuralVariableBuilder>? typeVariables =
        pop() as List<StructuralVariableBuilder>?;
    push(libraryBuilder.addFunctionType(
        returnType ?? const ImplicitTypeBuilder(),
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
    List<StructuralVariableBuilder>? typeVariables =
        pop() as List<StructuralVariableBuilder>?;
    if (!libraryBuilder.isNonNullableByDefault) {
      reportErrorIfNullableType(question);
    }
    push(libraryBuilder.addFunctionType(
        returnType ?? const ImplicitTypeBuilder(),
        typeVariables,
        formals,
        libraryBuilder.nullableBuilderIfTrue(question != null),
        uri,
        formalsOffset));
  }

  @override
  void endTypedef(Token typedefKeyword, Token? equals, Token endToken) {
    debugEvent("endTypedef");
    assert(checkState(
        typedefKeyword,
        equals == null
            ? [
                /* formals */ ValueKinds.FormalListOrNull,
                /* formals offset */ ValueKinds.Integer,
                /* type variables */ ValueKinds.NominalVariableListOrNull,
                /* name */ ValueKinds.IdentifierOrParserRecovery,
                /* return type */ ValueKinds.TypeBuilderOrNull,
                /* metadata */ ValueKinds.MetadataListOrNull,
              ]
            : [
                /* type */ unionOfKinds([
                  ValueKinds.TypeBuilderOrNull,
                  ValueKinds.ParserRecovery,
                ]),
                /* type variables */ ValueKinds.NominalVariableListOrNull,
                /* name */ ValueKinds.IdentifierOrParserRecovery,
                /* metadata */ ValueKinds.MetadataListOrNull,
              ]));

    List<NominalVariableBuilder>? typeVariables;
    Object? name;
    Identifier identifier;
    TypeBuilder aliasedType;
    if (equals == null) {
      List<FormalParameterBuilder>? formals =
          pop(NullValues.FormalParameters) as List<FormalParameterBuilder>?;
      pop(); // formals offset
      typeVariables =
          pop(NullValues.NominalVariables) as List<NominalVariableBuilder>?;
      name = pop();
      TypeBuilder? returnType = pop(NullValues.TypeBuilder) as TypeBuilder?;
      // Create a nested declaration that is ended below by
      // `library.addFunctionType`.
      if (name is ParserRecovery) {
        pop(NullValues.Metadata); // Metadata.
        libraryBuilder
            .endNestedDeclaration(
                TypeParameterScopeKind.typedef, "<syntax-error>")
            .resolveNamedTypes(typeVariables, libraryBuilder);
        popDeclarationContext(DeclarationContext.Typedef);
        return;
      }
      identifier = name as Identifier;
      libraryBuilder.beginNestedDeclaration(
          TypeParameterScopeKind.functionType, "#function_type",
          hasMembers: false);
      // TODO(cstefantsova): Make sure that RHS of typedefs can't have '?'.
      aliasedType = libraryBuilder.addFunctionType(
          returnType ?? const ImplicitTypeBuilder(),
          null,
          formals,
          const NullabilityBuilder.omitted(),
          uri,
          identifier.nameOffset);
    } else {
      Object? type = pop(NullValues.TypeBuilder);
      typeVariables =
          pop(NullValues.NominalVariables) as List<NominalVariableBuilder>?;
      name = pop();
      if (name is ParserRecovery) {
        pop(NullValues.Metadata); // Metadata.
        libraryBuilder
            .endNestedDeclaration(
                TypeParameterScopeKind.functionType, "<syntax-error>")
            .resolveNamedTypes(typeVariables, libraryBuilder);
        popDeclarationContext(DeclarationContext.Typedef);
        return;
      }
      identifier = name as Identifier;
      if (type is FunctionTypeBuilder &&
          !libraryFeatures.nonfunctionTypeAliases.isEnabled) {
        if (type.nullabilityBuilder.build(libraryBuilder) ==
                Nullability.nullable &&
            libraryBuilder.isNonNullableByDefault) {
          // The error is reported when the non-nullable experiment is enabled.
          // Otherwise, the attempt to use a nullable type will be reported
          // elsewhere.
          addProblem(
              messageTypedefNullableType, equals.charOffset, equals.length);
          aliasedType = new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
              new InvalidTypeDeclarationBuilder(
                  identifier.name,
                  messageTypedefNullableType.withLocation(
                      uri, equals.charOffset, equals.length)),
              const NullabilityBuilder.omitted(),
              instanceTypeVariableAccess:
                  InstanceTypeVariableAccessState.Allowed);
        } else {
          // TODO(ahe): We need to start a nested declaration when parsing the
          // formals and return type so we can correctly bind
          // `type.typeVariables`. A typedef can have type variables, and a new
          // function type can also have type variables (representing the type
          // of a generic function).
          aliasedType = type;
        }
      } else if (libraryFeatures.nonfunctionTypeAliases.isEnabled) {
        if (type is TypeBuilder) {
          aliasedType = type;
        } else {
          addProblem(messageTypedefNotType, equals.charOffset, equals.length);
          aliasedType = new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
              new InvalidTypeDeclarationBuilder(
                  "${name}",
                  messageTypedefNotType.withLocation(
                      uri, equals.charOffset, equals.length)),
              const NullabilityBuilder.omitted(),
              instanceTypeVariableAccess:
                  InstanceTypeVariableAccessState.Allowed);
        }
      } else {
        assert(type is! FunctionTypeBuilder);
        // TODO(ahe): Improve this error message.
        if (type is TypeBuilder) {
          addProblem(
              messageTypedefNotFunction, equals.charOffset, equals.length);
          aliasedType = new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
              new InvalidTypeDeclarationBuilder(
                  identifier.name,
                  messageTypedefNotFunction.withLocation(
                      uri, equals.charOffset, equals.length)),
              const NullabilityBuilder.omitted(),
              instanceTypeVariableAccess:
                  InstanceTypeVariableAccessState.Allowed);
        } else {
          addProblem(messageTypedefNotType, equals.charOffset, equals.length);
          aliasedType = new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
              new InvalidTypeDeclarationBuilder(
                  identifier.name,
                  messageTypedefNotType.withLocation(
                      uri, equals.charOffset, equals.length)),
              const NullabilityBuilder.omitted(),
              instanceTypeVariableAccess:
                  InstanceTypeVariableAccessState.Allowed);
        }
      }
    }
    List<MetadataBuilder>? metadata =
        pop(NullValues.Metadata) as List<MetadataBuilder>?;
    checkEmpty(typedefKeyword.charOffset);
    libraryBuilder.addFunctionTypeAlias(metadata, identifier.name,
        typeVariables, aliasedType, identifier.nameOffset);
    popDeclarationContext(DeclarationContext.Typedef);
  }

  @override
  void beginFields(
      DeclarationKind declarationKind,
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      Token lastConsumed) {
    DeclarationContext declarationContext;
    switch (declarationKind) {
      case DeclarationKind.TopLevel:
        declarationContext = DeclarationContext.TopLevelField;
        break;
      case DeclarationKind.Class:
        if (staticToken != null) {
          declarationContext = DeclarationContext.ClassStaticField;
        } else {
          declarationContext = DeclarationContext.ClassInstanceField;
        }
        break;
      case DeclarationKind.Mixin:
        if (staticToken != null) {
          declarationContext = DeclarationContext.MixinStaticField;
        } else {
          declarationContext = DeclarationContext.MixinInstanceField;
        }
        break;
      case DeclarationKind.Extension:
        if (staticToken != null) {
          declarationContext = DeclarationContext.ExtensionStaticField;
        } else if (externalToken != null) {
          declarationContext =
              DeclarationContext.ExtensionExternalInstanceField;
        } else {
          declarationContext = DeclarationContext.ExtensionInstanceField;
        }
        break;
      case DeclarationKind.ExtensionType:
        if (staticToken != null) {
          declarationContext = DeclarationContext.ExtensionTypeStaticField;
        } else {
          declarationContext = DeclarationContext.ExtensionTypeInstanceField;
        }
        break;
      case DeclarationKind.Enum:
        if (staticToken != null) {
          declarationContext = DeclarationContext.EnumStaticMethod;
        } else {
          declarationContext = DeclarationContext.EnumInstanceMethod;
        }
    }
    pushDeclarationContext(declarationContext);
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
    assert(checkState(beginToken, [
      ...repeatedKinds([
        /* charEndOffset = */ ValueKinds.Integer,
        /* beforeLast = */ ValueKinds.FieldInitializerTokenOrNull,
        /* initializerTokenForInference = */ ValueKinds
            .FieldInitializerTokenOrNull,
        /* name = */ ValueKinds.IdentifierOrParserRecovery,
      ], count),
      /* type = */ unionOfKinds([
        ValueKinds.TypeBuilderOrNull,
        ValueKinds.ParserRecovery,
      ]),
      /* metadata = */ ValueKinds.MetadataListOrNull,
    ]));
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
    if (fieldInfos != null) {
      libraryBuilder.addFields(
          metadata, modifiers, /* isTopLevel = */ true, type, fieldInfos);
    }
    popDeclarationContext();
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
    assert(checkState(beginToken, [
      ...repeatedKinds([
        /* charEndOffset = */ ValueKinds.Integer,
        /* beforeLast = */ ValueKinds.FieldInitializerTokenOrNull,
        /* initializerTokenForInference = */ ValueKinds
            .FieldInitializerTokenOrNull,
        /* name = */ ValueKinds.IdentifierOrParserRecovery,
      ], count),
      /* type = */ ValueKinds.TypeBuilderOrNull,
      /* metadata = */ ValueKinds.MetadataListOrNull,
    ]));
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
        (augmentToken != null ? augmentMask : 0) |
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
    if (fieldInfos != null) {
      libraryBuilder.addFields(
          metadata, modifiers, /* isTopLevel = */ false, type, fieldInfos);
    }
    popDeclarationContext();
  }

  List<FieldInfo>? popFieldInfos(int count) {
    assert(checkState(
        null,
        repeatedKinds([
          /* charEndOffset = */ ValueKinds.Integer,
          /* beforeLast = */ ValueKinds.FieldInitializerTokenOrNull,
          /* initializerTokenForInference = */ ValueKinds
              .FieldInitializerTokenOrNull,
          /* name = */ ValueKinds.IdentifierOrParserRecovery,
        ], count)));
    if (count == 0) return null;
    List<FieldInfo> fieldInfos =
        new List<FieldInfo>.filled(count, dummyFieldInfo);
    bool isParserRecovery = false;
    for (int i = count - 1; i != -1; i--) {
      int charEndOffset = popCharOffset();
      Token? beforeLast = pop(NullValues.FieldInitializer) as Token?;
      Token? initializerTokenForInference =
          pop(NullValues.FieldInitializer) as Token?;
      Object? name = pop(NullValues.Identifier);
      if (name is ParserRecovery) {
        isParserRecovery = true;
      } else {
        fieldInfos[i] = new FieldInfo(name as Identifier,
            initializerTokenForInference, beforeLast, charEndOffset);
      }
    }
    return isParserRecovery ? null : fieldInfos;
  }

  @override
  void beginTypeVariable(Token token) {
    assert(checkState(token, [
      ValueKinds.IdentifierOrParserRecovery,
      ValueKinds.MetadataListOrNull,
    ]));
    debugEvent("beginTypeVariable");
    Object? name = pop();
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    if (name is ParserRecovery) {
      push(name);
    } else {
      Identifier identifier = name as Identifier;
      if (inFunctionType) {
        push(libraryBuilder.addStructuralTypeVariable(
            metadata, identifier.name, null, identifier.nameOffset, uri));
      } else {
        push(libraryBuilder.addNominalTypeVariable(
            metadata, identifier.name, null, identifier.nameOffset, uri,
            kind: declarationContext.typeVariableKind));
      }
    }
  }

  @override
  void handleTypeVariablesDefined(Token token, int count) {
    debugEvent("TypeVariablesDefined");
    assert(count > 0);
    if (inFunctionType) {
      push(const FixedNullableList<StructuralVariableBuilder>()
              .popNonNullable(stack, count, dummyStructuralVariableBuilder) ??
          NullValues.StructuralVariables);
    } else {
      push(const FixedNullableList<NominalVariableBuilder>()
              .popNonNullable(stack, count, dummyNominalVariableBuilder) ??
          NullValues.NominalVariables);
    }
  }

  @override
  void endTypeVariable(
      Token token, int index, Token? extendsOrSuper, Token? variance) {
    debugEvent("endTypeVariable");
    TypeBuilder? bound = nullIfParserRecovery(pop()) as TypeBuilder?;
    // Peek to leave type parameters on top of stack.
    List<TypeVariableBuilderBase>? typeParameters =
        peek() as List<TypeVariableBuilderBase>?;
    if (typeParameters != null) {
      typeParameters[index].bound = bound;
      if (variance != null) {
        if (!libraryFeatures.variance.isEnabled) {
          reportVarianceModifierNotEnabled(variance);
        }
        typeParameters[index].variance = Variance.fromString(variance.lexeme);
      }
    }
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    debugEvent("endTypeVariables");

    if (declarationContext == DeclarationContext.Enum) {
      reportIfNotEnabled(
          libraryFeatures.enhancedEnums, beginToken.charOffset, noLength);
    }

    // Peek to leave type parameters on top of stack.
    List<TypeVariableBuilderBase>? typeParameters =
        peek() as List<TypeVariableBuilderBase>?;

    Map<String, TypeVariableBuilderBase>? typeVariablesByName;
    if (typeParameters != null) {
      for (TypeVariableBuilderBase builder in typeParameters) {
        if (builder.bound != null) {
          typeVariablesByName ??= <String, TypeVariableBuilderBase>{
            for (TypeVariableBuilderBase builder in typeParameters)
              builder.name: builder
          };

          // Find cycle: If there's no cycle we can at most step through all
          // `typeParameters` (at which point the last builders bound will be
          // null).
          // If there is a cycle with `builder` 'inside' the steps to get back
          // to it will also be bound by `typeParameters.length`.
          // If there is a cycle without `builder` 'inside' we will just ignore
          // it for now. It will be reported when processing one of the
          // `builder`s that is in fact `inside` the cycle. This matches the
          // cyclic class hierarchy error.
          TypeVariableBuilderBase? bound = builder;
          for (int steps = 0;
              bound!.bound != null && steps < typeParameters.length;
              ++steps) {
            TypeName? typeName = bound.bound!.typeName;
            bound = typeVariablesByName[typeName?.name];
            if (bound == null || bound == builder) break;
          }
          if (bound == builder && bound!.bound != null) {
            // Write out cycle.
            List<String> via = <String>[];
            TypeName? typeName = bound.bound!.typeName;
            bound = typeVariablesByName[typeName?.name];
            while (bound != builder) {
              via.add(bound!.name);
              TypeName? typeName = bound.bound!.typeName;
              bound = typeVariablesByName[typeName?.name];
            }
            Message message = via.isEmpty
                ? templateDirectCycleInTypeVariables.withArguments(builder.name)
                : templateCycleInTypeVariables.withArguments(
                    builder.name, via.join("', '"));
            addProblem(message, builder.charOffset, builder.name.length);
            builder.bound = new NamedTypeBuilderImpl(
                new SyntheticTypeName(builder.name, builder.charOffset),
                const NullabilityBuilder.omitted(),
                fileUri: uri,
                charOffset: builder.charOffset,
                instanceTypeVariableAccess:
                    //InstanceTypeVariableAccessState.Unexpected
                    declarationContext.instanceTypeVariableAccessState)
              ..bind(
                  libraryBuilder,
                  new InvalidTypeDeclarationBuilder(
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
    assert(checkState(
        partKeyword,
        hasName
            ? [
                /* library name */ ValueKinds.Identifier,
                /* metadata */ ValueKinds.MetadataListOrNull,
              ]
            : [
                /* offset */ ValueKinds.Integer,
                /* uri string */ ValueKinds.String,
                /* metadata */ ValueKinds.MetadataListOrNull,
              ]));

    if (hasName) {
      Identifier containingLibrary = pop() as Identifier;
      List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
      libraryBuilder.addPartOf(
          metadata,
          flattenName(containingLibrary, containingLibrary.firstOffset, uri),
          null,
          containingLibrary.firstOffset);
    } else {
      int charOffset = popCharOffset();
      String uriString = pop() as String;
      List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
      libraryBuilder.addPartOf(metadata, null, uriString, charOffset);
    }
  }

  @override
  void endConstructorReference(Token start, Token? periodBeforeName,
      Token endToken, ConstructorReferenceContext constructorReferenceContext) {
    debugEvent("ConstructorReference");
    assert(checkState(start, [
      if (periodBeforeName != null) /* suffix */ ValueKinds.Identifier,
      ValueKinds.TypeArgumentsOrNull,
      /* prefix */ ValueKinds.IdentifierOrParserRecoveryOrNull,
    ]));

    Identifier? suffix = popIfNotNull(periodBeforeName) as Identifier?;
    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;
    int charOffset = start.charOffset;
    Object? name = pop();
    if (name is ParserRecovery) {
      push(name);
    } else if (name is Identifier) {
      push(libraryBuilder.addConstructorReference(
          name.typeName, typeArguments, suffix?.name, name.qualifierOffset));
    } else {
      assert(name == null);
      // At the moment, the name of the type in a constructor reference can be
      // omitted only within an enum element declaration.
      if (libraryBuilder.currentTypeParameterScopeBuilder.kind ==
          TypeParameterScopeKind.enumDeclaration) {
        if (libraryFeatures.enhancedEnums.isEnabled) {
          int constructorNameOffset = suffix?.nameOffset ?? charOffset;
          push(libraryBuilder.addConstructorReference(
              new SyntheticTypeName(
                  libraryBuilder.currentTypeParameterScopeBuilder.name,
                  constructorNameOffset),
              typeArguments,
              suffix?.name,
              constructorNameOffset));
        } else {
          // For entries that consist of their name only, all of the elements
          // of the constructor reference should be null.
          if (typeArguments != null || suffix != null) {
            libraryBuilder.reportFeatureNotEnabled(
                libraryFeatures.enhancedEnums, uri, charOffset, noLength);
          }
          push(NullValues.ConstructorReference);
        }
      } else {
        internalProblem(
            messageInternalProblemOmittedTypeNameInConstructorReference,
            charOffset,
            uri);
      }
    }
  }

  @override
  void beginFactoryMethod(DeclarationKind declarationKind, Token lastConsumed,
      Token? externalToken, Token? constToken) {
    DeclarationContext declarationContext;
    switch (declarationKind) {
      case DeclarationKind.TopLevel:
        throw new UnsupportedError("Unexpected top level factory method.");
      case DeclarationKind.Class:
        declarationContext = DeclarationContext.ClassFactory;
        break;
      case DeclarationKind.Mixin:
        declarationContext = DeclarationContext.MixinFactory;
        break;
      case DeclarationKind.Extension:
        declarationContext = DeclarationContext.ExtensionFactory;
        break;
      case DeclarationKind.ExtensionType:
        declarationContext = DeclarationContext.ExtensionTypeFactory;
        break;
      case DeclarationKind.Enum:
        declarationContext = DeclarationContext.EnumFactory;
        break;
    }

    pushDeclarationContext(declarationContext);
    inConstructor = true;
    libraryBuilder.beginNestedDeclaration(
        TypeParameterScopeKind.factoryMethod, "#factory_method",
        hasMembers: false);
    push((externalToken != null ? externalMask : 0) |
        (constToken != null ? constMask : 0));
  }

  void _endFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    assert(checkState(beginToken, [
      ValueKinds.MethodBody,
    ]));

    MethodBody kind = pop() as MethodBody;

    assert(checkState(beginToken, [
      if (kind == MethodBody.RedirectingFactoryBody)
        unionOfKinds([
          ValueKinds.ConstructorReferenceBuilderOrNull,
          ValueKinds.ParserRecovery,
        ]),
      ValueKinds.AsyncMarker,
      ValueKinds.FormalListOrNull,
      /* formals offset */ ValueKinds.Integer,
      ValueKinds.NominalVariableListOrNull,
      ValueKinds.IdentifierOrParserRecovery,
      /* modifiers */ ValueKinds.Integer,
      ValueKinds.MetadataListOrNull,
    ]));

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
    Object name = pop()!;
    int modifiers = pop() as int;
    if (nativeMethodName != null) {
      modifiers |= externalMask;
    }
    List<MetadataBuilder>? metadata = pop() as List<MetadataBuilder>?;
    if (name is! Identifier) {
      assert(name is ParserRecovery,
          "Unexpected name $name (${name.runtimeType}).");
      libraryBuilder.endNestedDeclaration(
          TypeParameterScopeKind.factoryMethod, "<syntax-error>");
    } else {
      libraryBuilder.addFactoryMethod(
        metadata,
        modifiers,
        name,
        formals,
        redirectionTarget,
        beginToken.charOffset,
        name.qualifierOffset,
        formalsOffset,
        endToken.charOffset,
        nativeMethodName,
        asyncModifier,
      );
    }
    nativeMethodName = null;
    inConstructor = false;
    popDeclarationContext();
  }

  @override
  void endClassFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    debugEvent("endClassFactoryMethod");

    _endFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
  void endMixinFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    debugEvent("endMixinFactoryMethod");

    _endFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
  void endExtensionFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    debugEvent("endExtensionFactoryMethod");

    _endFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
  void endEnumFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    debugEvent("endEnumFactoryMethod");

    reportIfNotEnabled(
        libraryFeatures.enhancedEnums, beginToken.charOffset, noLength);

    _endFactoryMethod(beginToken, factoryKeyword, endToken);
  }

  @override
  void endEnumMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    debugEvent("endEnumMethod");

    reportIfNotEnabled(
        libraryFeatures.enhancedEnums, beginToken.charOffset, noLength);

    _endClassMethod(getOrSet, beginToken, beginParam, beginInitializers,
        endToken, _MethodKind.enumMethod);
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
    reportIfNotEnabled(
        libraryFeatures.enhancedEnums, beginToken.charOffset, noLength);

    endClassFields(
        abstractToken,
        augmentToken,
        externalToken,
        staticToken,
        covariantToken,
        lateToken,
        varFinalOrConst,
        count,
        beginToken,
        endToken);
  }

  @override
  void endEnumConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    debugEvent("endEnumConstructor");

    reportIfNotEnabled(
        libraryFeatures.enhancedEnums, beginToken.charOffset, noLength);

    _endClassMethod(getOrSet, beginToken, beginParam, beginInitializers,
        endToken, _MethodKind.enumConstructor);
  }

  @override
  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    debugEvent("RedirectingFactoryBody");
    push(MethodBody.RedirectingFactoryBody);
  }

  @override
  void handleConstFactory(Token constKeyword) {
    debugEvent("ConstFactory");
    if (!libraryFeatures.constFunctions.isEnabled) {
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
    debugEvent("handleNoFieldInitializer");
    push(NullValues.FieldInitializer);
    push(NullValues.FieldInitializer);
    push(token.charOffset);
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    debugEvent("endInitializers");
    // Ignored for now.
  }

  @override
  void handleNoInitializers() {
    debugEvent("handleNoInitializers");
    // This is a constructor initializer and it's ignored for now.
  }

  @override
  void handleInvalidMember(Token endToken) {
    debugEvent("handleInvalidMember");
    pop(); // metadata star
  }

  @override
  void endMember() {
    debugEvent("endMember");
    assert(nativeMethodName == null);
  }

  @override
  void handleClassWithClause(Token withKeyword) {
    debugEvent("ClassWithClause");
    assert(checkState(withKeyword, [
      /* mixins */ unionOfKinds([
        ValueKinds.TypeBuilderList,
        ValueKinds.ParserRecovery,
      ]),
      /* supertype offset */ ValueKinds.Integer,
      /* supertype */ unionOfKinds([
        ValueKinds.TypeBuilderOrNull,
        ValueKinds.ParserRecovery,
      ]),
    ]));

    Object? mixins = pop();
    int extendsOffset = popCharOffset();
    Object? supertype = peek();
    push(extendsOffset);
    if (supertype is ParserRecovery || mixins is ParserRecovery) {
      push(new ParserRecovery(withKeyword.charOffset));
    } else {
      push(libraryBuilder.addMixinApplication(
          mixins as List<TypeBuilder>, withKeyword.charOffset));
    }
    assert(checkState(withKeyword, [
      /* mixins */ unionOfKinds([
        ValueKinds.MixinApplicationBuilderOrNull,
        ValueKinds.ParserRecovery,
      ]),
      /* supertype offset */ ValueKinds.Integer,
      /* supertype */ unionOfKinds([
        ValueKinds.TypeBuilderOrNull,
        ValueKinds.ParserRecovery,
      ]),
    ]));
  }

  @override
  void handleClassNoWithClause() {
    debugEvent("ClassNoWithClause");
    assert(checkState(null, [
      /* supertype offset */ ValueKinds.Integer,
      /* supertype */ unionOfKinds([
        ValueKinds.TypeBuilderOrNull,
        ValueKinds.ParserRecovery,
      ]),
    ]));
    push(NullValues.MixinApplicationBuilder);
    assert(checkState(null, [
      /* mixins */ ValueKinds.MixinApplicationBuilderOrNull,
      /* supertype offset */ ValueKinds.Integer,
      /* supertype */ unionOfKinds([
        ValueKinds.TypeBuilderOrNull,
        ValueKinds.ParserRecovery,
      ]),
    ]));
  }

  @override
  void handleEnumWithClause(Token withKeyword) {
    debugEvent("EnumWithClause");
    assert(checkState(withKeyword, [
      /* mixins */ unionOfKinds([
        ValueKinds.TypeBuilderListOrNull,
        ValueKinds.ParserRecovery,
      ]),
    ]));

    reportIfNotEnabled(libraryFeatures.enhancedEnums, withKeyword.charOffset,
        withKeyword.length);

    Object? mixins = pop();
    if (mixins is ParserRecovery) {
      push(new ParserRecovery(withKeyword.charOffset));
    } else {
      push(libraryBuilder.addMixinApplication(
          mixins as List<TypeBuilder>, withKeyword.charOffset));
    }
    assert(checkState(withKeyword, [
      /* mixins */ unionOfKinds([
        ValueKinds.MixinApplicationBuilderOrNull,
        ValueKinds.ParserRecovery,
      ]),
    ]));
  }

  @override
  void handleEnumNoWithClause() {
    debugEvent("EnumNoWithClause");
    push(NullValues.MixinApplicationBuilder);
  }

  @override
  void handleMixinWithClause(Token withKeyword) {
    debugEvent("MixinWithClause");
    assert(checkState(withKeyword, [
      /* mixins */ unionOfKinds([
        ValueKinds.TypeBuilderListOrNull,
        ValueKinds.ParserRecovery,
      ]),
    ]));

    // This is an error case where the parser has already given an error.
    // We just discard the data.
    pop();
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
  void endClassOrMixinOrExtensionBody(
      DeclarationKind kind, int memberCount, Token beginToken, Token endToken) {
    debugEvent("endClassOrMixinBody");
    popDeclarationContext();
  }

  @override
  void handleAsyncModifier(Token? asyncToken, Token? starToken) {
    debugEvent("AsyncModifier");
    push(asyncMarkerFromTokens(asyncToken, starToken));
  }

  @override
  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled = false, List<LocatedMessage>? context}) {
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
    reportIfNotEnabled(
        libraryFeatures.constructorTearoffs, token.charOffset, token.length);
  }
}

/// TODO(johnniwinther): Use [DeclarationContext] instead of [_MethodKind].
enum _MethodKind {
  classConstructor,
  classMethod,
  mixinConstructor,
  mixinMethod,
  extensionConstructor,
  extensionMethod,
  extensionTypeConstructor,
  extensionTypeMethod,
  enumConstructor,
  enumMethod,
}

extension on MemberKind {
  /// Returns `true` if a parameter occurring in this context can be inferred.
  bool get isParameterInferable {
    switch (this) {
      case MemberKind.Catch:
      case MemberKind.FunctionTypeAlias:
      case MemberKind.Factory:
      case MemberKind.FunctionTypedParameter:
      case MemberKind.GeneralizedFunctionType:
      case MemberKind.Local:
      case MemberKind.StaticMethod:
      case MemberKind.TopLevelMethod:
      case MemberKind.ExtensionNonStaticMethod:
      case MemberKind.ExtensionStaticMethod:
      case MemberKind.PrimaryConstructor:
        return false;
      case MemberKind.NonStaticMethod:
      // These can be inferred but cannot hold parameters so the cases are
      // dead code:
      case MemberKind.NonStaticField:
      case MemberKind.StaticField:
      case MemberKind.TopLevelField:
        return true;
    }
  }
}
