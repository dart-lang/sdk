// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.library_builder;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show FormalParameterKind;
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:kernel/ast.dart'
    show AsyncMarker, Class, Library, ProcedureKind;

import '../../api_prototype/experimental_flags.dart';
import '../combinator.dart' show CombinatorBuilder;
import '../configuration.dart';
import '../export.dart' show Export;
import '../identifiers.dart';
import '../loader.dart' show Loader;
import '../messages.dart'
    show
        FormattedMessage,
        LocatedMessage,
        Message,
        templateInternalProblemConstructorNotFound,
        templateInternalProblemNotFoundIn,
        templateInternalProblemPrivateConstructorAccess;
import '../problems.dart' show internalProblem;
import '../scope.dart';
import '../source/name_scheme.dart';
import '../source/offset_map.dart';
import '../source/source_class_builder.dart';
import '../source/source_enum_builder.dart';
import '../source/source_function_builder.dart';
import '../source/source_library_builder.dart';
import '../source/source_loader.dart';
import 'builder.dart';
import 'constructor_reference_builder.dart';
import 'declaration_builders.dart';
import 'formal_parameter_builder.dart';
import 'inferable_type_builder.dart';
import 'member_builder.dart';
import 'metadata_builder.dart';
import 'mixin_application_builder.dart';
import 'modifier_builder.dart';
import 'name_iterator.dart';
import 'named_type_builder.dart';
import 'nullability_builder.dart';
import 'omitted_type_builder.dart';
import 'prefix_builder.dart';
import 'type_builder.dart';

sealed class CompilationUnit {
  /// Returns the import uri for the compilation unit.
  ///
  /// This is the canonical uri for the compilation unit, for instance
  /// 'dart:core'.
  Uri get importUri;
  Uri get fileUri;
  bool get isSynthetic;

  /// If true, the library is not supported through the 'dart.library.*' value
  /// used in conditional imports and `bool.fromEnvironment` constants.
  bool get isUnsupported;

  Loader get loader;

  /// The [LibraryBuilder] for the library that this compilation unit belongs
  /// to.
  ///
  /// This is only valid after `SourceLoader.resolveParts` has be called.
  LibraryBuilder get libraryBuilder;

  bool get isPart;

  bool get isAugmenting;

  LibraryBuilder? get partOfLibrary;

  /// Returns the [Uri]s for the libraries that this library depend upon, either
  /// through import or export.
  Iterable<Uri> get dependencies;

  void recordAccess(
      CompilationUnit accessor, int charOffset, int length, Uri fileUri);

  void addExporter(LibraryBuilder exporter,
      List<CombinatorBuilder>? combinators, int charOffset);

  /// Returns an iterator of all members (typedefs, classes and members)
  /// declared in this library, including duplicate declarations.
  ///
  /// Compared to [localMembersIterator] this also gives access to the name
  /// that the builders are mapped to.
  NameIterator<Builder> get localMembersNameIterator;

  /// Add a problem with a severity determined by the severity of the message.
  ///
  /// If [fileUri] is null, it defaults to `this.fileUri`.
  ///
  /// See `Loader.addMessage` for an explanation of the
  /// arguments passed to this method.
  void addProblem(Message message, int charOffset, int length, Uri? fileUri,
      {bool wasHandled = false,
      List<LocatedMessage>? context,
      Severity? severity,
      bool problemOnLibrary = false});
}

abstract class DillCompilationUnit implements CompilationUnit {}

abstract class SourceCompilationUnit implements CompilationUnit {
  SourceLibraryBuilder createLibrary();

  @override
  SourceLoader get loader;

  // TODO(johnniwinther): Remove this.
  SourceLibraryBuilder get sourceLibraryBuilder;

  abstract OffsetMap offsetMap;

  LibraryFeatures get libraryFeatures;

  /// The current declaration that is being built. When we start parsing a
  /// declaration (class, method, and so on), we don't have enough information
  /// to create a builder and this object records its members and types until,
  /// for example, [addClass] is called.
  TypeParameterScopeBuilder get currentTypeParameterScopeBuilder;

  void beginNestedDeclaration(TypeParameterScopeKind kind, String name,
      {bool hasMembers = true});

  TypeParameterScopeBuilder endNestedDeclaration(
      TypeParameterScopeKind kind, String? name);

  /// Call this when entering a class, mixin, enum, or extension type
  /// declaration.
  ///
  /// This is done to set up the current [_indexedContainer] used to lookup
  /// references of members from a previous incremental compilation.
  ///
  /// Called in `OutlineBuilder.beginClassDeclaration`,
  /// `OutlineBuilder.beginEnum`, `OutlineBuilder.beginMixinDeclaration` and
  /// `OutlineBuilder.beginExtensionTypeDeclaration`.
  void beginIndexedContainer(String name,
      {required bool isExtensionTypeDeclaration});

  /// Call this when leaving a class, mixin, enum, or extension type
  /// declaration.
  ///
  /// Called in `OutlineBuilder.endClassDeclaration`,
  /// `OutlineBuilder.endEnum`, `OutlineBuilder.endMixinDeclaration` and
  /// `OutlineBuilder.endExtensionTypeDeclaration`.
  void endIndexedContainer();

  String? computeAndValidateConstructorName(Identifier identifier,
      {isFactory = false});

  List<ConstructorReferenceBuilder> get constructorReferences;

  List<Export> get exporters;

  LanguageVersion get languageVersion;

  // TODO(johnniwinther): Remove this.
  Library get library;

  abstract String? name;

  // TODO(johnniwinther): Remove this?
  LibraryName get libraryName;

  List<NamedTypeBuilder> get unresolvedNamedTypes;

  List<SourceFunctionBuilder> get nativeMethods;

  void set partOfLibrary(LibraryBuilder? value);

  String? get partOfName;

  Uri? get partOfUri;

  Scope get scope;

  abstract List<MetadataBuilder>? metadata;

  List<NominalVariableBuilder> get unboundNominalVariables;

  List<StructuralVariableBuilder> get unboundStructuralVariables;

  void collectInferableTypes(List<InferableType> inferableTypes);

  void takeMixinApplications(
      Map<SourceClassBuilder, TypeBuilder> mixinApplications);

  void addDependencies(Library library, Set<SourceCompilationUnit> seen);

  void includeParts(SourceLibraryBuilder libraryBuilder,
      List<SourceCompilationUnit> includedParts, Set<Uri> usedParts);

  void validatePart(SourceLibraryBuilder? library, Set<Uri>? usedParts);

  void addScriptToken(int charOffset);

  void addPart(OffsetMap offsetMap, Token partKeyword,
      List<MetadataBuilder>? metadata, String uri, int charOffset);

  void addPartOf(List<MetadataBuilder>? metadata, String? name, String? uri,
      int uriOffset);

  void addImport(
      {OffsetMap? offsetMap,
      Token? importKeyword,
      required List<MetadataBuilder>? metadata,
      required bool isAugmentationImport,
      required String uri,
      required List<Configuration>? configurations,
      required String? prefix,
      required List<CombinatorBuilder>? combinators,
      required bool deferred,
      required int charOffset,
      required int prefixCharOffset,
      required int uriOffset,
      required int importIndex});

  void addExport(
      OffsetMap offsetMap,
      Token exportKeyword,
      List<MetadataBuilder>? metadata,
      String uri,
      List<Configuration>? configurations,
      List<CombinatorBuilder>? combinators,
      int charOffset,
      int uriOffset);

  void addClass(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      int modifiers,
      Identifier identifier,
      List<NominalVariableBuilder>? typeVariables,
      TypeBuilder? supertype,
      MixinApplicationBuilder? mixins,
      List<TypeBuilder>? interfaces,
      int startOffset,
      int nameOffset,
      int endOffset,
      int supertypeOffset,
      {required bool isMacro,
      required bool isSealed,
      required bool isBase,
      required bool isInterface,
      required bool isFinal,
      required bool isAugmentation,
      required bool isMixinClass});

  void addEnum(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      Identifier identifier,
      List<NominalVariableBuilder>? typeVariables,
      MixinApplicationBuilder? supertypeBuilder,
      List<TypeBuilder>? interfaceBuilders,
      List<EnumConstantInfo?>? enumConstantInfos,
      int startCharOffset,
      int charEndOffset);

  void addExtensionDeclaration(
      OffsetMap offsetMap,
      Token beginToken,
      List<MetadataBuilder>? metadata,
      int modifiers,
      Identifier? identifier,
      List<NominalVariableBuilder>? typeVariables,
      TypeBuilder type,
      int startOffset,
      int nameOffset,
      int endOffset);

  void addExtensionTypeDeclaration(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      int modifiers,
      Identifier identifier,
      List<NominalVariableBuilder>? typeVariables,
      List<TypeBuilder>? interfaces,
      int startOffset,
      int endOffset);

  void addMixinDeclaration(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      int modifiers,
      Identifier identifier,
      List<NominalVariableBuilder>? typeVariables,
      List<TypeBuilder>? supertypeConstraints,
      List<TypeBuilder>? interfaces,
      int startOffset,
      int nameOffset,
      int endOffset,
      int supertypeOffset,
      {required bool isBase,
      required bool isAugmentation});

  void addNamedMixinApplication(
      List<MetadataBuilder>? metadata,
      String name,
      List<NominalVariableBuilder>? typeVariables,
      int modifiers,
      TypeBuilder? supertype,
      MixinApplicationBuilder mixinApplication,
      List<TypeBuilder>? interfaces,
      int startCharOffset,
      int charOffset,
      int charEndOffset,
      {required bool isMacro,
      required bool isSealed,
      required bool isBase,
      required bool isInterface,
      required bool isFinal,
      required bool isAugmentation,
      required bool isMixinClass});

  MixinApplicationBuilder addMixinApplication(
      List<TypeBuilder> mixins, int charOffset);

  void addFunctionTypeAlias(
      List<MetadataBuilder>? metadata,
      String name,
      List<NominalVariableBuilder>? typeVariables,
      TypeBuilder type,
      int charOffset);

  void addConstructor(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      int modifiers,
      Identifier identifier,
      String constructorName,
      List<NominalVariableBuilder>? typeVariables,
      List<FormalParameterBuilder>? formals,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String? nativeMethodName,
      {Token? beginInitializers,
      required bool forAbstractClassOrMixin});

  void addPrimaryConstructor(
      {required OffsetMap offsetMap,
      required Token beginToken,
      required String constructorName,
      required List<NominalVariableBuilder>? typeVariables,
      required List<FormalParameterBuilder>? formals,
      required int charOffset,
      required bool isConst});

  void addPrimaryConstructorField(
      {required List<MetadataBuilder>? metadata,
      required TypeBuilder type,
      required String name,
      required int charOffset});

  void addFactoryMethod(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      int modifiers,
      Identifier identifier,
      List<FormalParameterBuilder>? formals,
      ConstructorReferenceBuilder? redirectionTarget,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String? nativeMethodName,
      AsyncMarker asyncModifier);

  void addProcedure(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      int modifiers,
      TypeBuilder? returnType,
      Identifier identifier,
      String name,
      List<NominalVariableBuilder>? typeVariables,
      List<FormalParameterBuilder>? formals,
      ProcedureKind kind,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String? nativeMethodName,
      AsyncMarker asyncModifier,
      {required bool isInstanceMember,
      required bool isExtensionMember,
      required bool isExtensionTypeMember});

  void addFields(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      int modifiers,
      bool isTopLevel,
      TypeBuilder? type,
      List<FieldInfo> fieldInfos);

  FormalParameterBuilder addFormalParameter(
      List<MetadataBuilder>? metadata,
      FormalParameterKind kind,
      int modifiers,
      TypeBuilder type,
      String name,
      bool hasThis,
      bool hasSuper,
      int charOffset,
      Token? initializerToken);

  ConstructorReferenceBuilder addConstructorReference(TypeName name,
      List<TypeBuilder>? typeArguments, String? suffix, int charOffset);

  TypeBuilder addNamedType(
      TypeName typeName,
      NullabilityBuilder nullabilityBuilder,
      List<TypeBuilder>? arguments,
      int charOffset,
      {required InstanceTypeVariableAccessState instanceTypeVariableAccess});

  FunctionTypeBuilder addFunctionType(
      TypeBuilder returnType,
      List<StructuralVariableBuilder>? structuralVariableBuilders,
      List<FormalParameterBuilder>? formals,
      NullabilityBuilder nullabilityBuilder,
      Uri fileUri,
      int charOffset,
      {required bool hasFunctionFormalParameterSyntax});

  TypeBuilder addVoidType(int charOffset);

  InferableTypeBuilder addInferableType();

  NominalVariableBuilder addNominalTypeVariable(List<MetadataBuilder>? metadata,
      String name, TypeBuilder? bound, int charOffset, Uri fileUri,
      {required TypeVariableKind kind});

  StructuralVariableBuilder addStructuralTypeVariable(
      List<MetadataBuilder>? metadata,
      String name,
      TypeBuilder? bound,
      int charOffset,
      Uri fileUri);

  /// Creates a copy of [original] into the scope of [declaration].
  ///
  /// This is used for adding copies of class type parameters to factory
  /// methods and unnamed mixin applications, and for adding copies of
  /// extension type parameters to extension instance methods.
  ///
  /// If [synthesizeTypeParameterNames] is `true` the names of the
  /// [TypeParameter] are prefix with '#' to indicate that their synthesized.
  List<NominalVariableBuilder> copyTypeVariables(
      List<NominalVariableBuilder> original,
      TypeParameterScopeBuilder declaration,
      {required TypeVariableKind kind});

  /// Reports that [feature] is not enabled, using [charOffset] and
  /// [length] for the location of the message.
  ///
  /// Return the primary message.
  Message reportFeatureNotEnabled(
      LibraryFeature feature, Uri fileUri, int charOffset, int length);

  void addImportsToScope();

  int finishDeferredLoadTearoffs();
}

abstract class LibraryBuilder implements Builder {
  Scope get scope;

  Scope get exportScope;

  List<Export> get exporters;

  @override
  LibraryBuilder get origin;

  LibraryBuilder? get partOfLibrary;

  LibraryBuilder get nameOriginBuilder;

  abstract bool mayImplementRestrictedTypes;

  bool get isPart;

  Loader get loader;

  /// Returns the [Library] built by this builder.
  Library get library;

  @override
  Uri get fileUri;

  /// Returns the [Uri]s for the libraries that this library depend upon, either
  /// through import or export.
  Iterable<Uri> get dependencies;

  /// Returns the import uri for the library.
  ///
  /// This is the canonical uri for the library, for instance 'dart:core'.
  Uri get importUri;

  /// If true, the library is not supported through the 'dart.library.*' value
  /// used in conditional imports and `bool.fromEnvironment` constants.
  bool get isUnsupported;

  /// Returns an iterator of all members (typedefs, classes and members)
  /// declared in this library, including duplicate declarations.
  // TODO(johnniwinther): Should the only exist on [SourceLibraryBuilder]?
  Iterator<Builder> get localMembersIterator;

  /// Returns an iterator of all members of specified type
  /// declared in this library, including duplicate declarations.
  // TODO(johnniwinther): Should the only exist on [SourceLibraryBuilder]?
  Iterator<T> localMembersIteratorOfType<T extends Builder>();

  /// Returns an iterator of all members (typedefs, classes and members)
  /// declared in this library, including duplicate declarations.
  ///
  /// Compared to [localMembersIterator] this also gives access to the name
  /// that the builders are mapped to.
  NameIterator<Builder> get localMembersNameIterator;

  /// [Iterator] for all declarations declared in this library or any of its
  /// augmentations.
  ///
  /// Duplicates and augmenting members are _not_ included.
  Iterator<T> fullMemberIterator<T extends Builder>();

  /// [NameIterator] for all declarations declared in this class or any of its
  /// augmentations.
  ///
  /// Duplicates and augmenting members are _not_ included.
  NameIterator<T> fullMemberNameIterator<T extends Builder>();

  /// Add a problem with a severity determined by the severity of the message.
  ///
  /// If [fileUri] is null, it defaults to `this.fileUri`.
  ///
  /// See `Loader.addMessage` for an explanation of the
  /// arguments passed to this method.
  FormattedMessage? addProblem(
      Message message, int charOffset, int length, Uri? fileUri,
      {bool wasHandled = false,
      List<LocatedMessage>? context,
      Severity? severity,
      bool problemOnLibrary = false});

  /// Returns true if the export scope was modified.
  bool addToExportScope(String name, Builder member, [int charOffset = -1]);

  Builder computeAmbiguousDeclaration(
      String name, Builder declaration, Builder other, int charOffset,
      {bool isExport = false, bool isImport = false});

  /// Looks up [constructorName] in the class named [className].
  ///
  /// The class is looked up in this library's export scope unless
  /// [bypassLibraryPrivacy] is true, in which case it is looked up in the
  /// library scope of this library.
  ///
  /// It is an error if no such class is found, or if the class doesn't have a
  /// matching constructor (or factory).
  ///
  /// If [constructorName] is null or the empty string, it's assumed to be an
  /// unnamed constructor. it's an error if [constructorName] starts with
  /// `"_"`, and [bypassLibraryPrivacy] is false.
  MemberBuilder getConstructor(String className,
      {String constructorName, bool bypassLibraryPrivacy = false});

  void becomeCoreLibrary();

  void addSyntheticDeclarationOfDynamic();

  void addSyntheticDeclarationOfNever();

  void addSyntheticDeclarationOfNull();

  /// Lookups the member [name] declared in this library.
  ///
  /// If [required] is `true` and no member is found an internal problem is
  /// reported.
  Builder? lookupLocalMember(String name, {bool required = false});

  void recordAccess(
      CompilationUnit accessor, int charOffset, int length, Uri fileUri);

  /// Returns `true` if [cls] is the 'Function' class defined in [coreLibrary].
  static bool isFunction(Class cls, LibraryBuilder coreLibrary) {
    return cls.name == 'Function' && _isCoreClass(cls, coreLibrary);
  }

  /// Returns `true` if [cls] is the 'Record' class defined in [coreLibrary].
  static bool isRecord(Class cls, LibraryBuilder coreLibrary) {
    return cls.name == 'Record' && _isCoreClass(cls, coreLibrary);
  }

  static bool _isCoreClass(Class cls, LibraryBuilder coreLibrary) {
    // We use `superclass.parent` here instead of
    // `superclass.enclosingLibrary` to handle platform compilation. If
    // we are currently compiling the platform, the enclosing library of
    // the core class has not yet been set, so the accessing
    // `enclosingLibrary` would result in a cast error. We assume that the
    // SDK does not contain this error, which we otherwise not find. If we
    // are _not_ compiling the platform, the `superclass.parent` has been
    // set, if it is a class from `dart:core`.
    if (cls.parent == coreLibrary.library) {
      return true;
    }
    return false;
  }
}

abstract class LibraryBuilderImpl extends ModifierBuilderImpl
    implements LibraryBuilder {
  @override
  final Scope scope;

  @override
  final Scope exportScope;

  @override
  final List<Export> exporters = <Export>[];

  @override
  final Uri fileUri;

  @override
  bool mayImplementRestrictedTypes = false;

  LibraryBuilderImpl(this.fileUri, this.scope, this.exportScope)
      : super(null, -1);

  @override
  bool get isSynthetic => false;

  @override
  Builder? get parent => null;

  @override
  bool get isPart => false;

  @override
  String get debugName => "$runtimeType";

  @override
  Loader get loader;

  @override
  int get modifiers => 0;

  @override
  Uri get importUri;

  @override
  Iterator<Builder> get localMembersIterator {
    return scope.filteredIterator(
        parent: this, includeDuplicates: true, includeAugmentations: true);
  }

  @override
  Iterator<T> localMembersIteratorOfType<T extends Builder>() {
    return scope.filteredIterator<T>(
        parent: this, includeDuplicates: true, includeAugmentations: true);
  }

  @override
  NameIterator<Builder> get localMembersNameIterator {
    return scope.filteredNameIterator(
        parent: this, includeDuplicates: true, includeAugmentations: true);
  }

  @override
  FormattedMessage? addProblem(
      Message message, int charOffset, int length, Uri? fileUri,
      {bool wasHandled = false,
      List<LocatedMessage>? context,
      Severity? severity,
      bool problemOnLibrary = false}) {
    fileUri ??= this.fileUri;

    return loader.addProblem(message, charOffset, length, fileUri,
        wasHandled: wasHandled,
        context: context,
        severity: severity,
        problemOnLibrary: true);
  }

  @override
  bool addToExportScope(String name, Builder member, [int charOffset = -1]) {
    if (name.startsWith("_")) return false;
    if (member is PrefixBuilder) return false;
    Builder? existing =
        exportScope.lookupLocalMember(name, setter: member.isSetter);
    if (existing == member) {
      return false;
    } else {
      if (existing != null) {
        Builder result = computeAmbiguousDeclaration(
            name, existing, member, charOffset,
            isExport: true);
        exportScope.addLocalMember(name, result, setter: member.isSetter);
        return result != existing;
      } else {
        exportScope.addLocalMember(name, member, setter: member.isSetter);
        return true;
      }
    }
  }

  @override
  MemberBuilder getConstructor(String className,
      {String? constructorName, bool bypassLibraryPrivacy = false}) {
    constructorName ??= "";
    if (constructorName.startsWith("_") && !bypassLibraryPrivacy) {
      return internalProblem(
          templateInternalProblemPrivateConstructorAccess
              .withArguments(constructorName),
          -1,
          null);
    }
    Builder? cls = (bypassLibraryPrivacy ? scope : exportScope)
        .lookup(className, -1, fileUri);
    if (cls is TypeAliasBuilder) {
      TypeAliasBuilder aliasBuilder = cls;
      // No type arguments are available, but this method is only called in
      // order to find constructors of specific non-generic classes (errors),
      // so we can pass the empty list.
      cls = aliasBuilder.unaliasDeclaration(const <TypeBuilder>[]);
    }
    if (cls is ClassBuilder) {
      // TODO(ahe): This code is similar to code in `endNewExpression` in
      // `body_builder.dart`, try to share it.
      MemberBuilder? constructor =
          cls.findConstructorOrFactory(constructorName, -1, fileUri, this);
      if (constructor == null) {
        // Fall-through to internal error below.
      } else if (constructor.isConstructor) {
        if (!cls.isAbstract) {
          return constructor;
        }
      } else if (constructor.isFactory) {
        return constructor;
      }
    }
    throw internalProblem(
        templateInternalProblemConstructorNotFound.withArguments(
            "$className.$constructorName", importUri),
        -1,
        null);
  }

  @override
  void becomeCoreLibrary() {
    if (scope.lookupLocalMember("dynamic", setter: false) == null) {
      addSyntheticDeclarationOfDynamic();
    }
    if (scope.lookupLocalMember("Never", setter: false) == null) {
      addSyntheticDeclarationOfNever();
    }
    if (scope.lookupLocalMember("Null", setter: false) == null) {
      addSyntheticDeclarationOfNull();
    }
  }

  @override
  Builder? lookupLocalMember(String name, {bool required = false}) {
    Builder? builder = scope.lookupLocalMember(name, setter: false);
    if (required && builder == null) {
      internalProblem(
          templateInternalProblemNotFoundIn.withArguments(
              name, fullNameForErrors),
          -1,
          null);
    }
    return builder;
  }

  @override
  void recordAccess(
      CompilationUnit accessor, int charOffset, int length, Uri fileUri) {}

  @override
  StringBuffer printOn(StringBuffer buffer) {
    return buffer..write(isPart || isAugmenting ? fileUri : importUri);
  }
}
