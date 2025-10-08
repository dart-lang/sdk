// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/severity.dart'
    show CfeSeverity;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:kernel/ast.dart' show Annotatable, Library, Version;
import 'package:kernel/reference_from_index.dart';

import '../api_prototype/experimental_flags.dart';
import '../base/combinator.dart' show CombinatorBuilder;
import '../base/directives.dart';
import '../base/export.dart' show Export;
import '../base/extension_scope.dart';
import '../base/loader.dart' show Loader;
import '../base/messages.dart'
    show LocatedMessage, Message, ProblemReporting, noLength;
import '../base/name_space.dart';
import '../base/scope.dart';
import '../fragment/fragment.dart';
import '../kernel/body_builder_context.dart';
import '../source/name_space_builder.dart';
import '../source/offset_map.dart';
import '../source/source_library_builder.dart';
import '../source/source_loader.dart';
import 'builder.dart';
import 'declaration_builders.dart';
import 'library_builder.dart';
import 'metadata_builder.dart';
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
    CompilationUnit accessor,
    int charOffset,
    int length,
    Uri fileUri,
  );

  List<Export> get exporters;

  void addExporter(
    SourceCompilationUnit exporter,
    List<CombinatorBuilder>? combinators,
    int charOffset,
  );

  /// Add a problem with a severity determined by the severity of the message.
  ///
  /// If [fileUri] is null, it defaults to `this.fileUri`.
  ///
  /// See `Loader.addMessage` for an explanation of the
  /// arguments passed to this method.
  void addProblem(
    Message message,
    int charOffset,
    int length,
    Uri? fileUri, {
    bool wasHandled = false,
    List<LocatedMessage>? context,
    CfeSeverity? severity,
    bool problemOnLibrary = false,
  });
}

abstract class DillCompilationUnit implements CompilationUnit {}

abstract class SourceCompilationUnit
    implements CompilationUnit, LibraryFragment {
  void buildOutline(Token tokens);

  /// Creates a [SourceLibraryBuilder] for with this [SourceCompilationUnit] as
  /// the main compilation unit.
  SourceLibraryBuilder createLibrary([Library? library]);

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
  void registerExplicitLanguageVersion(
    Version version, {
    int offset = 0,
    int length = noLength,
  });

  // TODO(johnniwinther): Remove this.
  bool get forAugmentationLibrary;

  // TODO(johnniwinther): Remove this.
  bool get forPatchLibrary;

  /// If this is an compilation unit for an augmentation library, returns the
  /// import uri for the origin library. Otherwise the [importUri] for the
  /// compilation unit itself.
  Uri get originImportUri;

  @override
  SourceLibraryBuilder get libraryBuilder;

  /// The parent compilation unit.
  ///
  /// This is the compilation unit that included this compilation unit as a
  /// part or `null` if this is the root compilation unit of a library.
  SourceCompilationUnit? get parentCompilationUnit;

  LibraryFeatures get libraryFeatures;

  /// Returns `true` if the compilation unit is part of a `dart:` library.
  bool get isDartLibrary;

  LanguageVersion get languageVersion;

  LibraryDirective? get libraryDirective;

  int finishNativeMethods(SourceLoader loader);

  PartOf? get partOfDirective;

  List<MetadataBuilder>? get metadata;

  /// The scope of this compilation unit.
  ///
  /// This is the enclosing scope for all declarations within the compilation
  /// unit.
  LookupScope get compilationUnitScope;

  /// The prefix scope of this compilation unit.
  ///
  /// This contains all imports with prefixes declared in this compilation unit.
  LookupScope get prefixScope;

  ExtensionScope get prefixExtensionScope;

  /// The name space containing the prefixes declared in this compilation unit.
  NameSpace get prefixNameSpace;

  /// Returns the [PrefixBuilder] of the given [name] available in this
  /// compilation unit, if any.
  ///
  /// A prefix builder is available if it is declared in this compilation unit
  /// or if it is available in the parent compilation unit.
  PrefixBuilder? lookupPrefixBuilder(String name);

  bool get mayImplementRestrictedTypes;

  /// Adds [LibraryDependency] nodes for all imports and exports to [library].
  ///
  /// [seen] is use to track already handled compilation units in case for
  /// erroneous cases where a compilation unit is included more than once in
  /// the library.
  ///
  /// [deferredNames] maps the names of deferred imports to number of
  /// occurrences so far. With enhanced parts, different parts can use the same
  /// name for deferred imports. This map is used to create unique names in the
  /// encoding.
  void addDependencies({
    required Library library,
    required Set<SourceCompilationUnit> seen,
    required Map<String, int> deferredNames,
  });

  /// Runs through all part directives in this compilation unit and adds the
  /// compilation unit for the parts to the [libraryBuilder] by adding them
  /// to [includedParts]
  ///
  /// [usedParts] is used to ensure that a compilation unit is only included in
  /// one library. If the compilation unit is part of two libraries, it is only
  /// included in the first and reported as an error on the second.
  ///
  /// This should only be called on the main compilation unit for
  /// [libraryBuilder]. Inclusion of nested parts is from within this method,
  /// using [becomePart] for each individual subpart.
  void includeParts(
    List<SourceCompilationUnit> includedParts,
    Set<Uri> usedParts,
  );

  /// Includes this compilation unit as a part of [libraryBuilder] with
  /// [parentCompilationUnit] as the parent compilation unit.
  ///
  /// The parent compilation unit is used to define the compilation unit
  /// scope of this compilation unit.
  ///
  /// All fragment in this compilation unit will be added to
  /// [libraryNameSpaceBuilder].
  ///
  /// If parts with parts is supported (through the enhanced parts feature),
  /// the compilation units of the part directives in this compilation unit
  /// will be added [libraryBuilder] recursively.
  void becomePart(
    SourceLibraryBuilder libraryBuilder,
    LibraryNameSpaceBuilder libraryNameSpaceBuilder,
    SourceCompilationUnit parentCompilationUnit,
    List<SourceCompilationUnit> includedParts,
    Set<Uri> usedParts, {
    required bool allowPartInParts,
  });

  void buildOutlineExpressions({
    required Annotatable annotatable,
    required Uri annotatableFileUri,
    required BodyBuilderContext bodyBuilderContext,
  });

  /// Reports that [feature] is not enabled, using [charOffset] and
  /// [length] for the location of the message.
  ///
  /// Return the primary message.
  Message reportFeatureNotEnabled(
    LibraryFeature feature,
    Uri fileUri,
    int charOffset,
    int length,
  );

  /// Registers that [augmentation] is a part of the library for which this is
  /// the main compilation unit.
  void registerAugmentation(CompilationUnit augmentation);

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
    Message message,
    int charOffset,
    int length,
    Uri fileUri,
  );

  void issuePostponedProblems();

  void markLanguageVersionFinal();

  /// Index of the library we use references for.
  IndexedLibrary? get indexedLibrary;

  void addSyntheticImport({
    required Uri importUri,
    required String? prefix,
    required List<CombinatorBuilder>? combinators,
    required bool deferred,
  });

  void addImportedBuilderToScope({
    required String name,
    required NamedBuilder builder,
    required int charOffset,
  });

  void addImportsToScope();

  void buildOutlineNode(Library library);

  int finishDeferredLoadTearOffs(Library library);

  /// This method instantiates type parameters to their bounds in some cases
  /// where they were omitted by the programmer and not provided by the type
  /// inference.  The method returns the number of distinct type parameters
  /// that were instantiated in this library.
  int computeDefaultTypes(
    TypeBuilder dynamicType,
    TypeBuilder nullType,
    TypeBuilder bottomType,
    ClassBuilder objectClass,
  );

  /// Computes variances of type parameters on typedefs.
  ///
  /// The variance property of type parameters on typedefs is computed from the
  /// use of the parameters in the right-hand side of the typedef definition.
  int computeVariances();

  /// Adds all unbound nominal parameters to [nominalParameters] and unbound
  /// structural parameters to [structuralParameters], mapping them to
  /// [libraryBuilder].
  ///
  /// This is used to compute the bounds of type parameters while taking the
  /// bound dependencies, which might span multiple libraries, into account.
  List<TypeParameterBuilder> collectUnboundTypeParameters();

  /// Adds [prefixFragment] to library name space.
  ///
  /// Returns `true` if the prefix name was new to the name space. Otherwise the
  /// prefix was merged with an existing prefix of the same name.
  // TODO(johnniwinther): Remove this.
  bool addPrefixFragment(
    String name,
    PrefixFragment prefixFragment,
    int charOffset,
  );

  int resolveTypes(ProblemReporting problemReporting);
}
