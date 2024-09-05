// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.library_builder;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:kernel/ast.dart' show Class, Library, Version;
import 'package:kernel/reference_from_index.dart';

import '../api_prototype/experimental_flags.dart';
import '../base/combinator.dart' show CombinatorBuilder;
import '../base/export.dart' show Export;
import '../base/loader.dart' show Loader;
import '../base/messages.dart'
    show
        FormattedMessage,
        LocatedMessage,
        Message,
        ProblemReporting,
        noLength,
        templateInternalProblemConstructorNotFound,
        templateInternalProblemNotFoundIn,
        templateInternalProblemPrivateConstructorAccess;
import '../base/name_space.dart';
import '../base/problems.dart' show internalProblem;
import '../base/scope.dart';
import '../base/uri_offset.dart';
import '../source/offset_map.dart';
import '../source/outline_builder.dart';
import '../source/source_class_builder.dart';
import '../source/source_library_builder.dart';
import '../source/source_loader.dart';
import 'builder.dart';
import 'declaration_builders.dart';
import 'member_builder.dart';
import 'metadata_builder.dart';
import 'modifier_builder.dart';
import 'name_iterator.dart';
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

  List<Export> get exporters;

  void addExporter(CompilationUnit exporter,
      List<CombinatorBuilder>? combinators, int charOffset);

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
  OutlineBuilder createOutlineBuilder();

  /// Creates a [SourceLibraryBuilder] for with this [SourceCompilationUnit] as
  /// the main compilation unit.
  SourceLibraryBuilder createLibrary();

  @override
  SourceLoader get loader;

  OffsetMap get offsetMap;

  /// The language version of this compilation unit as defined by the language
  /// version of the package it belongs to, if present, or the current language
  /// version otherwise.
  ///
  /// This language version will be used as the language version for the
  /// compilation unit if the compilation unit does not contain an explicit
  /// `@dart=` annotation.
  LanguageVersion get packageLanguageVersion;

  /// Set the language version to an explicit major and minor version.
  ///
  /// The default language version specified by the `package_config.json` file
  /// is passed to the constructor, but the library can have source code that
  /// specifies another one which should be supported.
  ///
  /// Only the first registered language version is used.
  ///
  /// [offset] and [length] refers to the offset and length of the source code
  /// specifying the language version.
  void registerExplicitLanguageVersion(Version version,
      {int offset = 0, int length = noLength});

  // TODO(johnniwinther): Remove this.
  bool get forAugmentationLibrary;

  // TODO(johnniwinther): Remove this.
  bool get forPatchLibrary;

  /// If this is an compilation unit for an augmentation library, returns the
  /// import uri for the origin library. Otherwise the [importUri] for the
  /// compilation unit itself.
  Uri get originImportUri;

  LibraryFeatures get libraryFeatures;

  /// Returns `true` if the compilation unit is part of a `dart:` library.
  bool get isDartLibrary;

  LanguageVersion get languageVersion;

  String? get name;

  int finishNativeMethods();

  String? get partOfName;

  Uri? get partOfUri;

  List<MetadataBuilder>? get metadata;

  void takeMixinApplications(
      Map<SourceClassBuilder, TypeBuilder> mixinApplications);

  void addDependencies(Library library, Set<SourceCompilationUnit> seen);

  void includeParts(SourceLibraryBuilder libraryBuilder,
      List<SourceCompilationUnit> includedParts, Set<Uri> usedParts);

  void validatePart(SourceLibraryBuilder library, Set<Uri>? usedParts);

  /// Reports that [feature] is not enabled, using [charOffset] and
  /// [length] for the location of the message.
  ///
  /// Return the primary message.
  Message reportFeatureNotEnabled(
      LibraryFeature feature, Uri fileUri, int charOffset, int length);

  /// Reports [message] on all compilation units that access this compilation
  /// unit.
  void addProblemAtAccessors(Message message);

  Iterable<LibraryAccess> get accessors;

  /// Non-null if this library causes an error upon access, that is, there was
  /// an error reading its source.
  abstract Message? accessProblem;

  /// Add a problem that might not be reported immediately.
  ///
  /// Problems will be issued after source information has been added.
  /// Once the problems has been issued, adding a new "postponed" problem will
  /// be issued immediately.
  void addPostponedProblem(
      Message message, int charOffset, int length, Uri fileUri);

  void issuePostponedProblems();

  void markLanguageVersionFinal();

  /// Index of the library we use references for.
  IndexedLibrary? get indexedLibrary;

  void addSyntheticImport(
      {required String uri,
      required String? prefix,
      required List<CombinatorBuilder>? combinators,
      required bool deferred});

  void addToScope(String name, Builder member, int charOffset, bool isImport);

  void addImportsToScope();

  void buildOutlineNode(Library library);

  int finishDeferredLoadTearOffs(Library library);

  void forEachExtensionInScope(void Function(ExtensionBuilder) f);

  void clearExtensionsInScopeCache();

  /// This method instantiates type parameters to their bounds in some cases
  /// where they were omitted by the programmer and not provided by the type
  /// inference.  The method returns the number of distinct type variables
  /// that were instantiated in this library.
  int computeDefaultTypes(TypeBuilder dynamicType, TypeBuilder nullType,
      TypeBuilder bottomType, ClassBuilder objectClass);

  /// Computes variances of type parameters on typedefs.
  ///
  /// The variance property of type parameters on typedefs is computed from the
  /// use of the parameters in the right-hand side of the typedef definition.
  int computeVariances();

  /// Adds all unbound nominal variables to [nominalVariables] and unbound
  /// structural variables to [structuralVariables], mapping them to
  /// [libraryBuilder].
  ///
  /// This is used to compute the bounds of type variable while taking the
  /// bound dependencies, which might span multiple libraries, into account.
  void collectUnboundTypeVariables(
      SourceLibraryBuilder libraryBuilder,
      Map<NominalVariableBuilder, SourceLibraryBuilder> nominalVariables,
      Map<StructuralVariableBuilder, SourceLibraryBuilder> structuralVariables);

  // TODO(johnniwinther): Remove this.
  Builder addBuilder(String name, Builder declaration, int charOffset);

  int resolveTypes(ProblemReporting problemReporting);
}

abstract class LibraryBuilder implements Builder, ProblemReporting {
  LookupScope get scope;

  NameSpace get nameSpace;

  NameSpace get exportNameSpace;

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

  /// Returns the language [Version] used for this library.
  Version get languageVersion;

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

  /// Returns true if the export scope was modified.
  bool addToExportScope(String name, Builder member,
      {required UriOffset uriOffset});

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
  final Uri fileUri;

  @override
  bool mayImplementRestrictedTypes = false;

  LibraryBuilderImpl(this.fileUri) : super(null, -1);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthetic => false;

  @override
  // Coverage-ignore(suite): Not run.
  Builder? get parent => null;

  @override
  bool get isPart => false;

  @override
  String get debugName => "$runtimeType";

  @override
  Loader get loader;

  @override
  // Coverage-ignore(suite): Not run.
  int get modifiers => 0;

  @override
  Uri get importUri;

  @override
  Iterator<Builder> get localMembersIterator {
    return nameSpace.filteredIterator(
        parent: this, includeDuplicates: true, includeAugmentations: true);
  }

  @override
  Iterator<T> localMembersIteratorOfType<T extends Builder>() {
    return nameSpace.filteredIterator<T>(
        parent: this, includeDuplicates: true, includeAugmentations: true);
  }

  @override
  NameIterator<Builder> get localMembersNameIterator {
    return nameSpace.filteredNameIterator(
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
  bool addToExportScope(String name, Builder member,
      {required UriOffset uriOffset}) {
    if (name.startsWith("_")) return false;
    if (member is PrefixBuilder) return false;
    Builder? existing =
        exportNameSpace.lookupLocalMember(name, setter: member.isSetter);
    if (existing == member) {
      return false;
    } else {
      if (existing != null) {
        Builder result = computeAmbiguousDeclarationForScope(
            this, nameSpace, name, existing, member,
            uriOffset: uriOffset, isExport: true);
        exportNameSpace.addLocalMember(name, result, setter: member.isSetter);
        return result != existing;
      } else {
        exportNameSpace.addLocalMember(name, member, setter: member.isSetter);
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
    Builder? cls = (bypassLibraryPrivacy ? nameSpace : exportNameSpace)
        .lookupLocalMember(className, setter: false);
    if (cls is TypeAliasBuilder) {
      // Coverage-ignore-block(suite): Not run.
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
      }
      // Coverage-ignore(suite): Not run.
      else if (constructor.isFactory) {
        return constructor;
      }
    }
    // Coverage-ignore-block(suite): Not run.
    throw internalProblem(
        templateInternalProblemConstructorNotFound.withArguments(
            "$className.$constructorName", importUri),
        -1,
        null);
  }

  @override
  Builder? lookupLocalMember(String name, {bool required = false}) {
    Builder? builder = nameSpace.lookupLocalMember(name, setter: false);
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
  // Coverage-ignore(suite): Not run.
  StringBuffer printOn(StringBuffer buffer) {
    return buffer..write(isPart || isAugmenting ? fileUri : importUri);
  }
}
