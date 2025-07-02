// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonEncode;

import 'package:_fe_analyzer_shared/src/field_promotability.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis_operations.dart';
import 'package:kernel/ast.dart' hide Combinator, MapLiteralEntry;
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClassHierarchyBase, ClassHierarchyMembers;
import 'package:kernel/clone.dart' show CloneVisitorNotMembers;
import 'package:kernel/reference_from_index.dart' show IndexedLibrary;
import 'package:kernel/src/bounds_checks.dart'
    show
        TypeArgumentIssue,
        findTypeArgumentIssues,
        findTypeArgumentIssuesForInvocation,
        getGenericTypeName,
        hasGenericFunctionTypeAsTypeArgument;
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart' show TypeEnvironment;

import '../api_prototype/experimental_flags.dart';
import '../base/export.dart' show Export;
import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/name_space.dart';
import '../base/problems.dart' show unexpected, unhandled;
import '../base/scope.dart';
import '../base/uri_offset.dart';
import '../builder/builder.dart';
import '../builder/compilation_unit.dart';
import '../builder/declaration_builders.dart';
import '../builder/dynamic_type_declaration_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/never_type_declaration_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/property_builder.dart';
import '../builder/type_builder.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/internal_ast.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/load_library_builder.dart';
import '../kernel/utils.dart'
    show
        compareProcedures,
        exportDynamicSentinel,
        exportNeverSentinel,
        unserializableExportName;
import 'name_scheme.dart';
import 'name_space_builder.dart';
import 'source_class_builder.dart' show SourceClassBuilder;
import 'source_declaration_builder.dart';
import 'source_extension_builder.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_factory_builder.dart';
import 'source_loader.dart'
    show CompilationPhaseForProblemReporting, SourceLoader;
import 'source_member_builder.dart';
import 'source_property_builder.dart';
import 'source_type_alias_builder.dart';
import 'source_type_parameter_builder.dart';
import 'type_parameter_factory.dart';

/// Enum that define what state a source library is in, in terms of how far
/// in the compilation it has progressed. This is used to document and assert
/// the requirements of individual methods within the [SourceLibraryBuilder].
enum SourceLibraryBuilderState {
  /// The builder is in its initial state.
  ///
  /// The builder is known to be a library and not a part in this state.
  initial,

  /// The name space has been built for the library.
  nameSpaceBuilt,

  /// Scopes have been built for the library.
  scopesBuilt,

  /// Initial export scope derived from the name space has been built.
  initialExportScopesBuilt,

  /// Full export scope has been built.
  exportScopesBuilt,

  /// Type in the outline have been resolved.
  resolvedTypes,

  /// Default types of type parameters have been computed.
  defaultTypesComputed,

  /// Type parameters have been collected to be checked for cyclic dependencies
  /// and their nullability to be computed.
  unboundTypeParametersCollected,

  /// The AST nodes for the outline have been built.
  outlineNodesBuilt,
  ;

  bool operator <(SourceLibraryBuilderState other) => index < other.index;

  // Coverage-ignore(suite): Not run.
  bool operator <=(SourceLibraryBuilderState other) => index <= other.index;

  // Coverage-ignore(suite): Not run.
  bool operator >(SourceLibraryBuilderState other) => index > other.index;

  bool operator >=(SourceLibraryBuilderState other) => index >= other.index;
}

class SourceLibraryBuilder extends LibraryBuilderImpl {
  SourceLibraryBuilderState _state = SourceLibraryBuilderState.initial;

  final SourceCompilationUnit compilationUnit;

  final LibraryNameSpaceBuilder _libraryNameSpaceBuilder;

  MutableNameSpace? _libraryNameSpace;
  late final List<NamedBuilder> _memberBuilders;

  final ComputedMutableNameSpace _exportNameSpace;

  final LookupScope? _parentScope;

  @override
  final SourceLoader loader;

  final List<SourceCompilationUnit> _parts = [];

  @override
  final Uri fileUri;

  final Uri? _packageUri;

  // Coverage-ignore(suite): Not run.
  Uri? get packageUriForTesting => _packageUri;

  @override
  LibraryBuilder? get partOfLibrary => compilationUnit.partOfLibrary;

  @override
  final Library library;

  @override
  final LibraryName libraryName;

  final List<PendingBoundsCheck> _pendingBoundsChecks = [];
  final List<GenericFunctionTypeCheck> _pendingGenericFunctionTypeChecks = [];

  // A list of alternating forwarders and the procedures they were generated
  // for.  Note that it may not include a forwarder-origin pair in cases when
  // the former does not need to be updated after the body of the latter was
  // built.
  final List<Procedure> forwardersOrigins = <Procedure>[];

  // A library to use for Names generated when compiling code in this library.
  // This allows code generated in one library to use the private namespace of
  // another, for example during expression compilation (debugging).
  Library get nameOrigin =>
      _nameOrigin
          // Coverage-ignore(suite): Not run.
          ?.library ??
      library;

  @override
  LibraryBuilder get nameOriginBuilder => _nameOrigin ?? this;
  final LibraryBuilder? _nameOrigin;

  /// Index of the library we use references for.
  IndexedLibrary? get indexedLibrary => compilationUnit.indexedLibrary;

  /// Exports that can't be serialized.
  ///
  /// The key is the name of the exported member.
  ///
  /// If the name is `dynamic` or `Never`, this library reexports the
  /// corresponding type from `dart:core`, and the value is the sentinel values
  /// [exportDynamicSentinel] or [exportNeverSentinel], respectively.
  ///
  /// Otherwise, this represents an error (an ambiguous export). In this case,
  /// the error message is the corresponding value in the map.
  Map<String, String>? unserializableExports;

  /// If `null`, [SourceLoader.computeFieldPromotability] hasn't been called
  /// yet, or field promotion is disabled for this library.  If not `null`,
  /// Information about which fields are promotable in this library, or `null`
  /// if [SourceLoader.computeFieldPromotability] hasn't been called.
  FieldNonPromotabilityInfo? fieldNonPromotabilityInfo;

  /// Redirecting factory builders defined in the library. They should be
  /// collected as they are built, so that we can build the outline expressions
  /// in the right order.
  ///
  /// See [SourceLoader.buildOutlineExpressions] for details.
  List<SourceFactoryBuilder>? redirectingFactoryBuilders;

  factory SourceLibraryBuilder(
      {required SourceCompilationUnit compilationUnit,
      required Uri importUri,
      required Uri fileUri,
      Uri? packageUri,
      required Uri originImportUri,
      required LanguageVersion packageLanguageVersion,
      required SourceLoader loader,
      LookupScope? parentScope,
      Library? target,
      LibraryBuilder? nameOrigin,
      IndexedLibrary? indexedLibrary,
      bool? referenceIsPartOwner,
      required bool isUnsupported,
      required bool isAugmentation,
      required bool isPatch,
      required NameSpace importNameSpace,
      required LibraryNameSpaceBuilder libraryNameSpaceBuilder}) {
    Library library = target ??
        new Library(importUri,
            fileUri: fileUri,
            reference: referenceIsPartOwner == true
                ? null
                : indexedLibrary?.library.reference)
      ..setLanguageVersion(packageLanguageVersion.version);
    LibraryName libraryName = new LibraryName(library.reference);
    ComputedMutableNameSpace exportNameSpace = new ComputedMutableNameSpace();
    return new SourceLibraryBuilder._(
        compilationUnit: compilationUnit,
        loader: loader,
        importUri: importUri,
        fileUri: fileUri,
        packageUri: packageUri,
        originImportUri: originImportUri,
        packageLanguageVersion: packageLanguageVersion,
        libraryNameSpaceBuilder: libraryNameSpaceBuilder,
        exportNameSpace: exportNameSpace,
        parentScope: parentScope,
        library: library,
        libraryName: libraryName,
        nameOrigin: nameOrigin,
        indexedLibrary: indexedLibrary,
        isUnsupported: isUnsupported,
        isAugmentation: isAugmentation,
        isPatch: isPatch);
  }

  SourceLibraryBuilder._(
      {required this.loader,
      required this.compilationUnit,
      required this.importUri,
      required this.fileUri,
      required Uri? packageUri,
      required Uri originImportUri,
      required LanguageVersion packageLanguageVersion,
      required LibraryNameSpaceBuilder libraryNameSpaceBuilder,
      required ComputedMutableNameSpace exportNameSpace,
      required LookupScope? parentScope,
      required this.library,
      required this.libraryName,
      required LibraryBuilder? nameOrigin,
      required IndexedLibrary? indexedLibrary,
      required bool isUnsupported,
      required bool isAugmentation,
      required bool isPatch})
      : _packageUri = packageUri,
        _nameOrigin = nameOrigin,
        _libraryNameSpaceBuilder = libraryNameSpaceBuilder,
        _exportNameSpace = exportNameSpace,
        _parentScope = parentScope,
        super(fileUri) {
    assert(
        _packageUri == null ||
            !importUri.isScheme('package') ||
            // Coverage-ignore(suite): Not run.
            importUri.path.startsWith(_packageUri.path),
        "Foreign package uri '$_packageUri' set on library with import uri "
        "'${importUri}'.");
    assert(
        !importUri.isScheme('dart') || _packageUri == null,
        "Package uri '$_packageUri' set on dart: library with import uri "
        "'${importUri}'.");
  }

  SourceLibraryBuilderState get state => _state;

  void set state(SourceLibraryBuilderState value) {
    assert(_state < value,
        "State $value has already been reached at $_state in $this.");
    assert(
        _state.index + 1 == value.index,
        _state.index + 1 < SourceLibraryBuilderState.values.length
            ? "Expected state "
                "${SourceLibraryBuilderState.values[_state.index + 1]} "
                "to follow from $_state, trying to set next state to $value "
                "in $this."
            : "No more states expected to follow from $_state, trying to set "
                "next state to $value in $this.");
    _state = value;
  }

  bool checkState(
      {List<SourceLibraryBuilderState>? required,
      List<SourceLibraryBuilderState>? pending}) {
    if (required != null) {
      for (SourceLibraryBuilderState requiredState in required) {
        assert(state >= requiredState,
            "State $requiredState required, but found $state in $this.");
      }
    }
    if (pending != null) {
      for (SourceLibraryBuilderState pendingState in pending) {
        assert(
            state < pendingState,
            "State $pendingState must not have been reached, "
            "but found $state in $this.");
      }
    }
    return true;
  }

  @override
  bool get mayImplementRestrictedTypes =>
      compilationUnit.mayImplementRestrictedTypes;

  // Coverage-ignore(suite): Not run.
  /// `true` if this is an augmentation library.
  bool get isAugmentationLibrary => compilationUnit.forAugmentationLibrary;

  // Coverage-ignore(suite): Not run.
  /// `true` if this is a patch library.
  bool get isPatchLibrary => compilationUnit.forPatchLibrary;

  @override
  bool get isUnsupported => compilationUnit.isUnsupported;

  /// Returns the state of the experimental features within this library.
  LibraryFeatures get libraryFeatures => compilationUnit.libraryFeatures;

  /// Reports that [feature] is not enabled, using [charOffset] and
  /// [length] for the location of the message.
  ///
  /// Return the primary message.
  Message reportFeatureNotEnabled(
      LibraryFeature feature, Uri fileUri, int charOffset, int length) {
    return compilationUnit.reportFeatureNotEnabled(
        feature, fileUri, charOffset, length);
  }

  LookupScope? get parentScope => _parentScope;

  @override
  NameSpace get libraryNameSpace {
    assert(_libraryNameSpace != null,
        "Name space has not being computed for $this.");
    return _libraryNameSpace!;
  }

  @override
  ComputedNameSpace get exportNameSpace => _exportNameSpace;

  /// Returns true if the export scope was modified.
  bool addToExportScope(String name, NamedBuilder member,
      {required UriOffset uriOffset}) {
    if (name.startsWith("_")) return false;
    if (member is PrefixBuilder) return false;
    bool isSetter = isMappedAsSetter(member);
    LookupResult? result = exportNameSpace.lookupLocalMember(name);
    NamedBuilder? existing = isSetter ? result?.setable : result?.getable;
    if (existing == member) {
      return false;
    } else {
      if (existing != null) {
        NamedBuilder result = _computeAmbiguousDeclarationForExport(
            name, existing, member,
            uriOffset: uriOffset);
        _exportNameSpace.replaceLocalMember(name, result, setter: isSetter);
        return result != existing;
      } else {
        _exportNameSpace.addLocalMember(name, member, setter: isSetter);
        return true;
      }
    }
  }

  /// Computes a builder for the export collision between [declaration] and
  /// [other]. If [declaration] is declared in [libraryNameSpace] then this is
  /// returned instead of reporting a collision.
  NamedBuilder _computeAmbiguousDeclarationForExport(
      String name, NamedBuilder declaration, NamedBuilder other,
      {required UriOffsetLength uriOffset}) {
    // Prefix builders and load library builders are not part of an export
    // scope.
    assert(declaration is! PrefixBuilder,
        "Unexpected prefix builder $declaration.");
    assert(other is! PrefixBuilder, "Unexpected prefix builder $other.");
    assert(declaration is! LoadLibraryBuilder,
        "Unexpected load library builder $declaration.");
    assert(other is! LoadLibraryBuilder,
        "Unexpected load library builder $other.");

    if (declaration == other) return declaration;
    if (declaration is InvalidTypeDeclarationBuilder) return declaration;
    if (other is InvalidTypeDeclarationBuilder) return other;
    NamedBuilder? preferred;
    Uri? uri;
    Uri? otherUri;
    if (libraryNameSpace.lookupLocalMember(name)?.getable == declaration) {
      return declaration;
    } else {
      uri = computeLibraryUri(declaration);
      otherUri = computeLibraryUri(other);
      if (otherUri.isScheme("dart") && !uri.isScheme("dart")) {
        preferred = declaration;
      } else if (uri.isScheme("dart") && !otherUri.isScheme("dart")) {
        preferred = other;
      }
    }
    if (preferred != null) {
      return preferred;
    }

    Uri firstUri = uri;
    Uri secondUri = otherUri;
    if (firstUri.toString().compareTo(secondUri.toString()) > 0) {
      firstUri = secondUri;
      secondUri = uri;
    }

    // TODO(ahe): We should probably use a context object here
    // instead of including URIs in this message.
    Message message =
        templateDuplicatedExport.withArguments(name, firstUri, secondUri);
    addProblem(message, uriOffset.fileOffset, noLength, uriOffset.fileUri);
    // We report the error lazily (setting suppressMessage to false) because the
    // spec 18.1 states that 'It is not an error if N is introduced by two or
    // more imports but never referred to.'
    return new InvalidTypeDeclarationBuilder(
        name,
        message.withLocation(
            uriOffset.fileUri, uriOffset.fileOffset, name.length),
        suppressMessage: false);
  }

  Iterable<SourceCompilationUnit> get parts => _parts;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isPart => compilationUnit.isPart;

  @override
  List<Export> get exporters => compilationUnit.exporters;

  @override
  Iterator<T> filteredMembersIterator<T extends NamedBuilder>(
          {required bool includeDuplicates}) =>
      new FilteredIterator<T>(_memberBuilders.iterator,
          includeDuplicates: includeDuplicates);

  /// Returns an iterator of all members (typedefs, classes and members)
  /// declared in this library, including duplicate declarations.
  Iterator<NamedBuilder> get unfilteredMembersIterator {
    return _memberBuilders.iterator;
  }

  @override
  bool get isSynthetic => compilationUnit.isSynthetic;

  bool get isInferenceUpdate1Enabled =>
      libraryFeatures.inferenceUpdate1.isSupported &&
      _languageVersion.version >=
          libraryFeatures.inferenceUpdate1.enabledVersion;

  @override
  Version get languageVersion => _languageVersion.version;

  LanguageVersion get _languageVersion => compilationUnit.languageVersion;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Uri> get dependencies sync* {
    yield* compilationUnit.dependencies;
    for (SourceCompilationUnit part in parts) {
      yield part.importUri;
      yield* part.dependencies;
    }
  }

  void computeSupertypes() {
    assert(checkState(required: [SourceLibraryBuilderState.nameSpaceBuilt]));
    List<SourceClassBuilder> sourceClasses =
        filteredMembersIterator<SourceClassBuilder>(includeDuplicates: true)
            .toList();
    for (SourceClassBuilder sourceClassBuilder in sourceClasses) {
      _computeSupertypeBuilderForClass(sourceClassBuilder);
    }
  }

  /// Builds the core AST structure of this library as needed for the outline.
  Library buildOutlineNodes(LibraryBuilder coreLibrary) {
    assert(checkState(
        required: [SourceLibraryBuilderState.unboundTypeParametersCollected]));
    library.setLanguageVersion(_languageVersion.version);
    compilationUnit.buildOutlineNode(library);
    for (SourceCompilationUnit part in parts) {
      part.buildOutlineNode(library);
    }

    Iterator<Builder> iterator = unfilteredMembersIterator;
    while (iterator.moveNext()) {
      _buildOutlineNodes(iterator.current, coreLibrary);
    }
    state = SourceLibraryBuilderState.outlineNodesBuilt;

    library.isSynthetic = isSynthetic;
    library.isUnsupported = isUnsupported;
    addDependencies(library, new Set<SourceCompilationUnit>());

    library.name = compilationUnit.name;
    library.procedures.sort(compareProcedures);

    if (unserializableExports != null) {
      Name fieldName = new Name(unserializableExportName, library);
      Reference? fieldReference = indexedLibrary
          // Coverage-ignore(suite): Not run.
          ?.lookupFieldReference(fieldName);
      Reference? getterReference = indexedLibrary
          // Coverage-ignore(suite): Not run.
          ?.lookupGetterReference(fieldName);
      library.addField(new Field.immutable(fieldName,
          initializer: new StringLiteral(jsonEncode(unserializableExports)),
          isStatic: true,
          isConst: true,
          fieldReference: fieldReference,
          getterReference: getterReference,
          fileUri: library.fileUri));
    }

    return library;
  }

  void includeParts(Set<Uri> usedParts) {
    compilationUnit.includeParts(_parts, usedParts);
  }

  void buildInitialScopes() {
    assert(checkState(required: [SourceLibraryBuilderState.scopesBuilt]));

    Iterator<NamedBuilder> iterator =
        filteredMembersIterator(includeDuplicates: false);
    UriOffset uriOffset = new UriOffset(fileUri, TreeNode.noOffset);
    while (iterator.moveNext()) {
      NamedBuilder builder = iterator.current;
      addToExportScope(builder.name, builder, uriOffset: uriOffset);
    }

    state = SourceLibraryBuilderState.initialExportScopesBuilt;
  }

  void addImportsToScope() {
    assert(checkState(
        required: [SourceLibraryBuilderState.initialExportScopesBuilt]));

    compilationUnit.addImportsToScope();
    for (SourceCompilationUnit part in parts) {
      part.addImportsToScope();
    }

    Iterator<NamedBuilder> iterator = _exportNameSpace.filteredIterator();
    while (iterator.moveNext()) {
      NamedBuilder builder = iterator.current;
      String name = builder.name;
      if (builder.parent != this) {
        if (builder is TypeDeclarationBuilder) {
          switch (builder) {
            case ClassBuilder():
              library.additionalExports.add(builder.cls.reference);
            case TypeAliasBuilder():
              library.additionalExports.add(builder.reference);
            case ExtensionBuilder():
              library.additionalExports.add(builder.reference);
            case ExtensionTypeDeclarationBuilder():
              library.additionalExports
                  .add(builder.extensionTypeDeclaration.reference);
            case InvalidTypeDeclarationBuilder():
              (unserializableExports ??= {})[name] =
                  builder.message.problemMessage;
            case BuiltinTypeDeclarationBuilder():
              if (builder is DynamicTypeDeclarationBuilder) {
                assert(name == 'dynamic',
                    "Unexpected export name for 'dynamic': '$name'");
                (unserializableExports ??= {})[name] = exportDynamicSentinel;
              } else if (builder is NeverTypeDeclarationBuilder) {
                assert(name == 'Never',
                    "Unexpected export name for 'Never': '$name'");
                (unserializableExports ??= // Coverage-ignore(suite): Not run.
                    {})[name] = exportNeverSentinel;
              }
            // Coverage-ignore(suite): Not run.
            case NominalParameterBuilder():
            case StructuralParameterBuilder():
              unhandled(
                  'member', 'exportScope', builder.fileOffset, builder.fileUri);
          }
        } else if (builder is MemberBuilder) {
          library.additionalExports.addAll(builder.exportedMemberReferences);
        } else {
          unhandled(
              'member', 'exportScope', builder.fileOffset, builder.fileUri);
        }
      }
    }

    state = SourceLibraryBuilderState.exportScopesBuilt;
  }

  void buildNameSpace() {
    assert(checkState(required: [SourceLibraryBuilderState.initial]));

    assert(_libraryNameSpace == null,
        "Name space has already being computed for $this.");

    assert(
        _mixinApplications != null, "Late registration of mixin application.");

    _memberBuilders = [];
    _libraryNameSpace = _libraryNameSpaceBuilder.toNameSpace(
        problemReporting: this,
        enclosingLibraryBuilder: this,
        mixinApplications: _mixinApplications!,
        typeParameterFactory: typeParameterFactory,
        indexedLibrary: indexedLibrary,
        memberBuilders: _memberBuilders);

    state = SourceLibraryBuilderState.nameSpaceBuilt;
  }

  void _computeSupertypeBuilderForClass(SourceClassBuilder classBuilder) {
    assert(checkState(required: [SourceLibraryBuilderState.nameSpaceBuilt]));
    assert(
        _mixinApplications != null, "Late registration of mixin application.");
    classBuilder.computeSupertypeBuilder(
        loader: loader,
        problemReporting: this,
        typeParameterFactory: typeParameterFactory,
        indexedLibrary: indexedLibrary,
        mixinApplications: _mixinApplications!,
        addAnonymousMixinClassBuilder: (SourceClassBuilder classBuilder) {
          _memberBuilders.add(classBuilder);
          _computeSupertypeBuilderForClass(classBuilder);
        });
  }

  void buildScopes(LibraryBuilder coreLibrary) {
    assert(checkState(required: [SourceLibraryBuilderState.nameSpaceBuilt]));

    Iterator<Builder> iterator = unfilteredMembersIterator;
    while (iterator.moveNext()) {
      Builder builder = iterator.current;
      if (builder is SourceDeclarationBuilder) {
        builder.buildScopes(coreLibrary);
      }
    }

    state = SourceLibraryBuilderState.scopesBuilt;
  }

  /// Resolves all unresolved types in [unresolvedNamedTypes]. The list of types
  /// is cleared when done.
  int resolveTypes() {
    assert(checkState(required: [SourceLibraryBuilderState.exportScopesBuilt]));
    int typeCount = 0;

    typeCount += compilationUnit.resolveTypes(this);
    for (SourceCompilationUnit part in parts) {
      typeCount += part.resolveTypes(this);
    }

    state = SourceLibraryBuilderState.resolvedTypes;
    return typeCount;
  }

  void installDefaultSupertypes(
      ClassBuilder objectClassBuilder, Class objectClass) {
    Iterator<SourceClassBuilder> iterator =
        filteredMembersIterator(includeDuplicates: true);
    while (iterator.moveNext()) {
      SourceClassBuilder declaration = iterator.current;
      declaration.installDefaultSupertypes(objectClassBuilder, objectClass);
    }
  }

  void collectSourceClassesAndExtensionTypes(
      List<SourceClassBuilder> sourceClasses,
      List<SourceExtensionTypeDeclarationBuilder> sourceExtensionTypes) {
    Iterator<Builder> iterator = unfilteredMembersIterator;
    while (iterator.moveNext()) {
      Builder member = iterator.current;
      if (member is SourceClassBuilder) {
        sourceClasses.add(member);
      } else if (member is SourceExtensionTypeDeclarationBuilder) {
        sourceExtensionTypes.add(member);
      }
    }
  }

  /// Resolve constructors (lookup names in scope) recorded in this builder and
  /// return the number of constructors resolved.
  int resolveConstructors() {
    int count = 0;
    Iterator<SourceDeclarationBuilder> iterator =
        filteredMembersIterator(includeDuplicates: true);
    while (iterator.moveNext()) {
      SourceDeclarationBuilder builder = iterator.current;
      count += builder.resolveConstructors(this);
    }
    return count;
  }

  /// Sets [fieldNonPromotabilityInfo] based on the contents of this library.
  void computeFieldPromotability() {
    _FieldPromotability fieldPromotability = new _FieldPromotability();
    Map<Member, PropertyNonPromotabilityReason> individualPropertyReasons = {};

    // Iterate through all the classes, enums, and mixins in the library,
    // recording the non-synthetic instance fields and getters of each.
    Iterator<SourceClassBuilder> classIterator =
        filteredMembersIterator(includeDuplicates: true);
    while (classIterator.moveNext()) {
      SourceClassBuilder classBuilder = classIterator.current;
      ClassInfo<Class> classInfo = fieldPromotability.addClass(classBuilder.cls,
          isAbstract: classBuilder.isAbstract);
      Iterator<SourcePropertyBuilder> memberIterator =
          classBuilder.filteredMembersIterator(includeDuplicates: false);
      while (memberIterator.moveNext()) {
        SourcePropertyBuilder member = memberIterator.current;
        if (member.isStatic) continue;
        if (member.hasField) {
          if (member.isSynthesized) continue;
          PropertyNonPromotabilityReason? reason = fieldPromotability.addField(
              classInfo, member, member.name,
              isFinal: member.isFinal,
              isAbstract: member.hasAbstractField,
              isExternal: member.hasExternalField);
          if (reason != null) {
            individualPropertyReasons[member.readTarget!] = reason;
          }
        } else if (member.hasGetter) {
          if (member.isSynthetic) continue;
          PropertyNonPromotabilityReason? reason = fieldPromotability.addGetter(
              classInfo, member, member.name,
              isAbstract: member.hasAbstractGetter);
          if (reason != null) {
            individualPropertyReasons[member.readTarget!] = reason;
          }
        }
      }
    }

    // And for each getter in an extension or extension type, make a note of why
    // it's not promotable.
    Iterator<SourceExtensionBuilder> extensionIterator =
        filteredMembersIterator(includeDuplicates: true);
    while (extensionIterator.moveNext()) {
      SourceExtensionBuilder extension_ = extensionIterator.current;
      Iterator<SourcePropertyBuilder> iterator =
          extension_.filteredMembersIterator(includeDuplicates: false);
      while (iterator.moveNext()) {
        SourcePropertyBuilder member = iterator.current;
        if (!member.isStatic && member.hasExplicitGetter) {
          individualPropertyReasons[member.readTarget!] =
              member.memberName.isPrivate
                  ? PropertyNonPromotabilityReason.isNotField
                  : PropertyNonPromotabilityReason.isNotPrivate;
        }
      }
    }
    Iterator<SourceExtensionTypeDeclarationBuilder> extensionTypeIterator =
        filteredMembersIterator(includeDuplicates: true);
    while (extensionTypeIterator.moveNext()) {
      SourceExtensionTypeDeclarationBuilder extensionType =
          extensionTypeIterator.current;
      Member? representationGetter =
          extensionType.representationFieldBuilder?.readTarget;
      if (representationGetter != null &&
          !representationGetter.name.isPrivate) {
        individualPropertyReasons[representationGetter] =
            PropertyNonPromotabilityReason.isNotPrivate;
      }
      Iterator<SourcePropertyBuilder> iterator =
          extensionType.filteredMembersIterator(includeDuplicates: false);
      while (iterator.moveNext()) {
        SourcePropertyBuilder member = iterator.current;
        if (!member.isStatic && member.hasExplicitGetter) {
          individualPropertyReasons[member.readTarget!] =
              member.memberName.isPrivate
                  ? PropertyNonPromotabilityReason.isNotField
                  : PropertyNonPromotabilityReason.isNotPrivate;
        }
      }
    }

    // Compute information about field non-promotability.
    fieldNonPromotabilityInfo = new FieldNonPromotabilityInfo(
        fieldNameInfo: fieldPromotability.computeNonPromotabilityInfo(),
        individualPropertyReasons: individualPropertyReasons);
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors {
    // TODO(ahe): Consider if we should use relativizeUri here. The downside to
    // doing that is that this URI may be used in an error message. Ideally, we
    // should create a class that represents qualified names that we can
    // relativize when printing a message, but still store the full URI in
    // .dill files.
    return compilationUnit.name ?? "<library '$fileUri'>";
  }

  @override
  final Uri importUri;

  @override
  // Coverage-ignore(suite): Not run.
  void becomeCoreLibrary() {
    assert(checkState(required: [SourceLibraryBuilderState.nameSpaceBuilt]));

    if (libraryNameSpace.lookupLocalMember("dynamic")?.getable == null) {
      NamedBuilder builder =
          new DynamicTypeDeclarationBuilder(const DynamicType(), this, -1);
      _libraryNameSpace!.addLocalMember("dynamic", builder, setter: false);
      _memberBuilders.add(builder);
    }
    if (libraryNameSpace.lookupLocalMember("Never")?.getable == null) {
      NamedBuilder builder = new NeverTypeDeclarationBuilder(
          const NeverType.nonNullable(), this, -1);
      _libraryNameSpace!.addLocalMember("Never", builder, setter: false);
      _memberBuilders.add(builder);
    }
    assert(libraryNameSpace.lookupLocalMember("Null")?.getable != null,
        "No class 'Null' found in dart:core.");
  }

  @override
  FormattedMessage? addProblem(
      Message message, int charOffset, int length, Uri? fileUri,
      {bool wasHandled = false,
      List<LocatedMessage>? context,
      Severity? severity,
      bool problemOnLibrary = false}) {
    FormattedMessage? formattedMessage = super.addProblem(
        message, charOffset, length, fileUri,
        wasHandled: wasHandled,
        context: context,
        severity: severity,
        problemOnLibrary: true);
    if (formattedMessage != null) {
      library.problemsAsJson ??= <String>[];
      library.problemsAsJson!.add(formattedMessage.toJsonString());
    }
    return formattedMessage;
  }

  void checkGetterSetterTypes(TypeEnvironment typeEnvironment,
      {required DartType getterType,
      required String getterName,
      required UriOffsetLength getterUriOffset,
      required DartType setterType,
      required String setterName,
      required UriOffsetLength setterUriOffset}) {
    if (libraryFeatures.getterSetterError.isEnabled ||
        getterType is InvalidType ||
        setterType is InvalidType) {
      // Don't report a problem because the it isn't considered a problem in the
      // current Dart version or because something else is wrong that has
      // already been reported.
    } else {
      bool isValid = typeEnvironment.isSubtypeOf(getterType, setterType);
      if (!isValid) {
        addProblem2(
            templateInvalidGetterSetterType.withArguments(
                getterType, getterName, setterType, setterName),
            getterUriOffset,
            context: [
              templateInvalidGetterSetterTypeSetterContext
                  .withArguments(setterName)
                  .withLocation2(setterUriOffset)
            ]);
      }
    }
  }

  /// Map from mixin application classes to their mixin types.
  ///
  /// This is used to check that super access in mixin declarations have a
  /// concrete target.
  Map<SourceClassBuilder, TypeBuilder>? _mixinApplications = {};

  void takeMixinApplications(
      Map<SourceClassBuilder, TypeBuilder> mixinApplications) {
    assert(_mixinApplications != null,
        "Mixin applications have already been processed.");
    mixinApplications.addAll(_mixinApplications!);
    _mixinApplications = null;
  }

  BodyBuilderContext createBodyBuilderContext() {
    return new LibraryBodyBuilderContext(this);
  }

  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    compilationUnit.buildOutlineExpressions(
        annotatable: library,
        annotatableFileUri: library.fileUri,
        bodyBuilderContext: createBodyBuilderContext());

    Iterator<Builder> iterator = unfilteredMembersIterator;
    while (iterator.moveNext()) {
      Builder declaration = iterator.current;
      if (declaration is SourceClassBuilder) {
        declaration.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      } else if (declaration is SourceExtensionBuilder) {
        declaration.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      } else if (declaration is SourceExtensionTypeDeclarationBuilder) {
        declaration.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      } else if (declaration is SourceMemberBuilder) {
        declaration.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      } else if (declaration is SourceTypeAliasBuilder) {
        declaration.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      } else {
        // Coverage-ignore-block(suite): Not run.
        assert(
            declaration is PrefixBuilder ||
                declaration is DynamicTypeDeclarationBuilder ||
                declaration is NeverTypeDeclarationBuilder,
            "Unexpected builder in library: ${declaration} "
            "(${declaration.runtimeType}");
      }
    }
  }

  /// Builds the core AST structures for [declaration] needed for the outline.
  void _buildOutlineNodes(Builder declaration, LibraryBuilder coreLibrary) {
    if (declaration is SourceClassBuilder) {
      Class cls = declaration.build(coreLibrary);
      if (!declaration.isAugmentation) {
        if (declaration.isDuplicate) {
          cls.name = '${cls.name}'
              '#${declaration.duplicateIndex}';
        }
      } else {
        // The following is a recovery to prevent cascading errors.
        int nameIndex = 0;
        String baseName = cls.name;
        String? nameOfErroneousAugmentation;
        while (nameOfErroneousAugmentation == null) {
          nameOfErroneousAugmentation =
              "_#${baseName}#augmentationWithoutOrigin${nameIndex}";
          for (Class class_ in library.classes) {
            if (class_.name == nameOfErroneousAugmentation) {
              nameOfErroneousAugmentation = null;
              break;
            }
          }
          nameIndex++;
        }
        cls.name = nameOfErroneousAugmentation;
      }
      library.addClass(cls);
    } else if (declaration is SourceExtensionBuilder) {
      Extension extension = declaration.build(coreLibrary,
          addMembersToLibrary: !declaration.isDuplicate);
      if (!declaration.isDuplicate) {
        if (declaration.isUnnamedExtension) {
          declaration.extensionName.name =
              '${NameScheme.unnamedExtensionNamePrefix}'
              '${library.extensions.length}';
        }
        library.addExtension(extension);
      }
    } else if (declaration is SourceExtensionTypeDeclarationBuilder) {
      ExtensionTypeDeclaration extensionTypeDeclaration = declaration
          .build(coreLibrary, addMembersToLibrary: !declaration.isDuplicate);
      if (!declaration.isDuplicate) {
        library.addExtensionTypeDeclaration(extensionTypeDeclaration);
      } else if (declaration.isDuplicate) {
        // Set parent so an `enclosingLibrary` call won't crash.
        extensionTypeDeclaration.parent = library;
      }
    } else if (declaration is SourceMemberBuilder) {
      declaration.buildOutlineNodes((
          {required Member member,
          Member? tearOff,
          required BuiltMemberKind kind}) {
        _addMemberToLibrary(declaration, member);
        if (tearOff != null) {
          // Coverage-ignore-block(suite): Not run.
          _addMemberToLibrary(declaration, tearOff);
        }
      });
    } else if (declaration is SourceTypeAliasBuilder) {
      Typedef typedef = declaration.build();
      if (!declaration.isDuplicate) {
        library.addTypedef(typedef);
      }
    }
    // Coverage-ignore(suite): Not run.
    else if (declaration is PrefixBuilder) {
      // Ignored. Kernel doesn't represent prefixes.
      return;
    } else if (declaration is BuiltinTypeDeclarationBuilder) {
      // Nothing needed.
      return;
    } else {
      unhandled("${declaration.runtimeType}", "buildBuilder",
          declaration.fileOffset, declaration.fileUri);
    }
  }

  void _addMemberToLibrary(SourceMemberBuilder declaration, Member member) {
    if (member is Field) {
      member.isStatic = true;
      if (!declaration.isDuplicate) {
        library.addField(member);
      }
    } else if (member is Procedure) {
      member.isStatic = true;
      if (!declaration.isDuplicate) {
        library.addProcedure(member);
      }
    } else {
      unhandled("${member.runtimeType}", "_buildMember", declaration.fileOffset,
          declaration.fileUri);
    }
  }

  void addDependencies(Library library, Set<SourceCompilationUnit> seen) {
    assert(checkState(required: [SourceLibraryBuilderState.outlineNodesBuilt]));
    compilationUnit.addDependencies(library, seen);
    for (SourceCompilationUnit part in parts) {
      part.addDependencies(library, seen);
    }
  }

  int finishDeferredLoadTearOffs() {
    int total = compilationUnit.finishDeferredLoadTearOffs(library);
    for (SourceCompilationUnit part in parts) {
      total += part.finishDeferredLoadTearOffs(library);
    }
    return total;
  }

  int finishForwarders() {
    int count = 0;
    CloneVisitorNotMembers cloner = new CloneVisitorNotMembers();
    for (int i = 0; i < forwardersOrigins.length; i += 2) {
      Procedure forwarder = forwardersOrigins[i];
      Procedure origin = forwardersOrigins[i + 1];

      int positionalCount = origin.function.positionalParameters.length;
      if (forwarder.function.positionalParameters.length != positionalCount) {
        return unexpected(
            "$positionalCount",
            "${forwarder.function.positionalParameters.length}",
            origin.fileOffset,
            origin.fileUri);
      }
      for (int j = 0; j < positionalCount; ++j) {
        VariableDeclaration forwarderParameter =
            forwarder.function.positionalParameters[j];
        VariableDeclaration originParameter =
            origin.function.positionalParameters[j];
        if (originParameter.initializer != null) {
          forwarderParameter.initializer =
              cloner.clone(originParameter.initializer!);
          forwarderParameter.initializer!.parent = forwarderParameter;
        }
      }

      Map<String, VariableDeclaration> originNamedMap =
          <String, VariableDeclaration>{};
      for (VariableDeclaration originNamed in origin.function.namedParameters) {
        originNamedMap[originNamed.name!] = originNamed;
      }
      for (VariableDeclaration forwarderNamed
          in forwarder.function.namedParameters) {
        VariableDeclaration? originNamed = originNamedMap[forwarderNamed.name];
        if (originNamed == null) {
          return unhandled(
              "null", forwarder.name.text, origin.fileOffset, origin.fileUri);
        }
        if (originNamed.initializer == null) continue;
        forwarderNamed.initializer = cloner.clone(originNamed.initializer!);
        forwarderNamed.initializer!.parent = forwarderNamed;
      }

      ++count;
    }
    forwardersOrigins.clear();
    return count;
  }

  int finishNativeMethods(SourceLoader loader) {
    int count = compilationUnit.finishNativeMethods(loader);
    for (SourceCompilationUnit part in parts) {
      count += part.finishNativeMethods(loader);
    }

    return count;
  }

  final TypeParameterFactory typeParameterFactory = new TypeParameterFactory();

  /// Adds all unbound nominal parameters to [nominalParameters] and unbound
  /// structural parameters to [structuralParameters], mapping them to this
  /// library.
  ///
  /// This is used to compute the bounds of type parameter while taking the
  /// bound dependencies, which might span multiple libraries, into account.
  void collectUnboundTypeParameters(
      Map<TypeParameterBuilder, SourceLibraryBuilder> typeParameterBuilders) {
    for (TypeParameterBuilder builder
        in compilationUnit.collectUnboundTypeParameters()) {
      typeParameterBuilders[builder] = this;
    }
    for (SourceCompilationUnit part in parts) {
      for (TypeParameterBuilder builder
          in part.collectUnboundTypeParameters()) {
        // Coverage-ignore-block(suite): Not run.
        typeParameterBuilders[builder] = this;
      }
    }
    for (TypeParameterBuilder builder
        in typeParameterFactory.collectTypeParameters()) {
      typeParameterBuilders[builder] = this;
    }

    state = SourceLibraryBuilderState.unboundTypeParametersCollected;
  }

  /// Computes variances of type parameters on typedefs.
  ///
  /// The variance property of type parameters on typedefs is computed from the
  /// use of the parameters in the right-hand side of the typedef definition.
  int computeVariances() {
    int count = compilationUnit.computeVariances();
    return count;
  }

  /// This method instantiates type parameters to their bounds in some cases
  /// where they were omitted by the programmer and not provided by the type
  /// inference.  The method returns the number of distinct type parameters
  /// that were instantiated in this library.
  int computeDefaultTypes(TypeBuilder dynamicType, TypeBuilder nullType,
      TypeBuilder bottomType, ClassBuilder objectClass) {
    assert(checkState(
        required: [SourceLibraryBuilderState.resolvedTypes],
        pending: [SourceLibraryBuilderState.unboundTypeParametersCollected]));
    int count = compilationUnit.computeDefaultTypes(
        dynamicType, nullType, bottomType, objectClass);
    state = SourceLibraryBuilderState.defaultTypesComputed;
    return count;
  }

  /// Builds the AST nodes needed for the full compilation.
  ///
  /// This includes augmenting member bodies and adding augmented members.
  int buildBodyNodes() {
    int count = 0;
    Iterator<Builder> iterator = unfilteredMembersIterator;
    while (iterator.moveNext()) {
      Builder builder = iterator.current;
      if (builder is SourceMemberBuilder) {
        count += builder.buildBodyNodes(
            // Coverage-ignore(suite): Not run.
            (
                {required Member member,
                Member? tearOff,
                required BuiltMemberKind kind}) {
          _addMemberToLibrary(builder, member);
          if (tearOff != null) {
            _addMemberToLibrary(builder, tearOff);
          }
        });
      } else if (builder is SourceClassBuilder) {
        count += builder.buildBodyNodes();
      } else if (builder is SourceExtensionBuilder) {
        count +=
            builder.buildBodyNodes(addMembersToLibrary: !builder.isDuplicate);
      } else if (builder is SourceExtensionTypeDeclarationBuilder) {
        count +=
            builder.buildBodyNodes(addMembersToLibrary: !builder.isDuplicate);
      } else if (builder is SourceClassBuilder) {
        // Coverage-ignore-block(suite): Not run.
        count += builder.buildBodyNodes();
      } else if (builder is SourceTypeAliasBuilder) {
        // Do nothing.
      }
      // Coverage-ignore(suite): Not run.
      else if (builder is PrefixBuilder) {
        // Ignored. Kernel doesn't represent prefixes.
      } else if (builder is BuiltinTypeDeclarationBuilder) {
        // Nothing needed.
      } else {
        unhandled("${builder.runtimeType}", "buildBodyNodes",
            builder.fileOffset, builder.fileUri);
      }
    }
    return count;
  }

  void _reportTypeArgumentIssues(
      Iterable<TypeArgumentIssue> issues, Uri fileUri, int offset,
      {bool? inferred,
      TypeArgumentsInfo? typeArgumentsInfo,
      DartType? targetReceiver,
      String? targetName}) {
    for (TypeArgumentIssue issue in issues) {
      DartType argument = issue.argument;
      TypeParameter? typeParameter = issue.typeParameter;

      Message message;
      bool issueInferred =
          inferred ?? typeArgumentsInfo?.isInferred(issue.index) ?? false;
      offset =
          typeArgumentsInfo?.getOffsetForIndex(issue.index, offset) ?? offset;
      if (issue.isGenericTypeAsArgumentIssue) {
        if (issueInferred) {
          message = templateGenericFunctionTypeInferredAsActualTypeArgument
              .withArguments(argument);
        } else {
          message = messageGenericFunctionTypeUsedAsActualTypeArgument;
        }
        typeParameter = null;
      } else {
        if (issue.enclosingType == null && targetReceiver != null) {
          if (targetName != null) {
            if (issueInferred) {
              message =
                  templateIncorrectTypeArgumentQualifiedInferred.withArguments(
                      argument,
                      typeParameter.bound,
                      typeParameter.name!,
                      targetReceiver,
                      targetName);
            } else {
              message = templateIncorrectTypeArgumentQualified.withArguments(
                  argument,
                  typeParameter.bound,
                  typeParameter.name!,
                  targetReceiver,
                  targetName);
            }
          } else {
            if (issueInferred) {
              // Coverage-ignore-block(suite): Not run.
              message = templateIncorrectTypeArgumentInstantiationInferred
                  .withArguments(argument, typeParameter.bound,
                      typeParameter.name!, targetReceiver);
            } else {
              message =
                  templateIncorrectTypeArgumentInstantiation.withArguments(
                      argument,
                      typeParameter.bound,
                      typeParameter.name!,
                      targetReceiver);
            }
          }
        } else {
          String enclosingName = issue.enclosingType == null
              ? targetName!
              : getGenericTypeName(issue.enclosingType!);
          if (issueInferred) {
            message = templateIncorrectTypeArgumentInferred.withArguments(
                argument,
                typeParameter.bound,
                typeParameter.name!,
                enclosingName);
          } else {
            message = templateIncorrectTypeArgument.withArguments(argument,
                typeParameter.bound, typeParameter.name!, enclosingName);
          }
        }
      }

      // Don't show the hint about an attempted super-bounded type if the issue
      // with the argument is that it's generic.
      reportTypeArgumentIssueForStructuralParameter(message, fileUri, offset,
          typeParameter: typeParameter,
          superBoundedAttempt:
              issue.isGenericTypeAsArgumentIssue ? null : issue.enclosingType,
          superBoundedAttemptInverted:
              issue.isGenericTypeAsArgumentIssue ? null : issue.invertedType);
    }
  }

  void reportTypeArgumentIssue(Message message, Uri fileUri, int fileOffset,
      {TypeParameter? typeParameter,
      DartType? superBoundedAttempt,
      DartType? superBoundedAttemptInverted}) {
    List<LocatedMessage>? context;
    // Skip reporting location for function-type type parameters as it's a
    // limitation of Kernel.
    if (typeParameter != null &&
        typeParameter.fileOffset != -1 &&
        typeParameter.location?.file != null) {
      // It looks like when parameters come from augmentation libraries, they
      // don't have a reportable location.
      (context ??= <LocatedMessage>[]).add(
          messageIncorrectTypeArgumentVariable.withLocation(
              typeParameter.location!.file,
              typeParameter.fileOffset,
              noLength));
    }
    if (superBoundedAttemptInverted != null && superBoundedAttempt != null) {
      // Coverage-ignore-block(suite): Not run.
      (context ??= <LocatedMessage>[]).add(templateSuperBoundedHint
          .withArguments(superBoundedAttempt, superBoundedAttemptInverted)
          .withLocation(fileUri, fileOffset, noLength));
    }
    addProblem(message, fileOffset, noLength, fileUri, context: context);
  }

  void reportTypeArgumentIssueForStructuralParameter(
      Message message, Uri fileUri, int fileOffset,
      {TypeParameter? typeParameter,
      DartType? superBoundedAttempt,
      DartType? superBoundedAttemptInverted}) {
    List<LocatedMessage>? context;
    // Skip reporting location for function-type type parameters as it's a
    // limitation of Kernel.
    if (typeParameter != null && typeParameter.location != null) {
      // It looks like when parameters come from augmentation libraries, they
      // don't have a reportable location.
      (context ??= <LocatedMessage>[]).add(
          messageIncorrectTypeArgumentVariable.withLocation(
              typeParameter.location!.file,
              typeParameter.fileOffset,
              noLength));
    }
    if (superBoundedAttemptInverted != null && superBoundedAttempt != null) {
      (context ??= // Coverage-ignore(suite): Not run.
              <LocatedMessage>[])
          .add(templateSuperBoundedHint
              .withArguments(superBoundedAttempt, superBoundedAttemptInverted)
              .withLocation(fileUri, fileOffset, noLength));
    }
    addProblem(message, fileOffset, noLength, fileUri, context: context);
  }

  void checkTypesInField(TypeEnvironment typeEnvironment,
      {required bool isInstanceMember,
      required bool isLate,
      required bool isExternal,
      required bool hasInitializer,
      required DartType fieldType,
      required String name,
      required int nameLength,
      required int nameOffset,
      required Uri fileUri}) {
    // Check that the field has an initializer if its type is potentially
    // non-nullable.

    // Only static and top-level fields are checked here.  Instance fields are
    // checked elsewhere.
    if (!isInstanceMember &&
        !isLate &&
        !isExternal &&
        fieldType is! InvalidType &&
        fieldType.isPotentiallyNonNullable &&
        !hasInitializer) {
      addProblem(
          templateFieldNonNullableWithoutInitializerError.withArguments(
              name, fieldType),
          nameOffset,
          nameLength,
          fileUri);
    }
  }

  /// Checks that non-nullable optional parameters have a default value.
  void checkInitializersInFormals(
      List<FormalParameterBuilder>? formals, TypeEnvironment typeEnvironment,
      {required bool isAbstract, required bool isExternal}) {
    if (formals != null && !(isAbstract || isExternal)) {
      for (FormalParameterBuilder formal in formals) {
        bool isOptionalPositional =
            formal.isOptionalPositional && formal.isPositional;
        bool isOptionalNamed = !formal.isRequiredNamed && formal.isNamed;
        bool isOptional = isOptionalPositional || isOptionalNamed;
        if (isOptional &&
            formal.variable!.type.isPotentiallyNonNullable &&
            !formal.hasDeclaredInitializer) {
          addProblem(
              templateOptionalNonNullableWithoutInitializerError.withArguments(
                  formal.name, formal.variable!.type),
              formal.fileOffset,
              formal.name.length,
              formal.fileUri);
          formal.variable?.isErroneouslyInitialized = true;
        }
      }
    }
  }

  void checkBoundsInType(
      DartType type, TypeEnvironment typeEnvironment, Uri fileUri, int offset,
      {bool? inferred, bool allowSuperBounded = true}) {
    List<TypeArgumentIssue> issues = findTypeArgumentIssues(
        type, typeEnvironment,
        allowSuperBounded: allowSuperBounded,
        areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled);
    _reportTypeArgumentIssues(issues, fileUri, offset, inferred: inferred);
  }

  void checkBoundsInConstructorInvocation(
      ConstructorInvocation node, TypeEnvironment typeEnvironment, Uri fileUri,
      {bool inferred = false}) {
    if (node.arguments.types.isEmpty) return;
    Constructor constructor = node.target;
    Class klass = constructor.enclosingClass;
    DartType constructedType = new InterfaceType(
        klass, klass.enclosingLibrary.nonNullable, node.arguments.types);
    checkBoundsInType(
        constructedType, typeEnvironment, fileUri, node.fileOffset,
        inferred: inferred, allowSuperBounded: false);
  }

  void checkBoundsInFactoryInvocation(
      StaticInvocation node, TypeEnvironment typeEnvironment, Uri fileUri,
      {bool inferred = false}) {
    if (node.arguments.types.isEmpty) return;
    Procedure factory = node.target;
    assert(factory.isFactory || factory.isExtensionTypeMember);
    DartType constructedType = Substitution.fromPairs(
            node.target.function.typeParameters, node.arguments.types)
        .substituteType(node.target.function.returnType);
    checkBoundsInType(
        constructedType, typeEnvironment, fileUri, node.fileOffset,
        inferred: inferred, allowSuperBounded: false);
  }

  void checkBoundsInStaticInvocation(
      StaticInvocation node,
      TypeEnvironment typeEnvironment,
      Uri fileUri,
      TypeArgumentsInfo typeArgumentsInfo) {
    // TODO(johnniwinther): Handle partially inferred type arguments in
    // extension method calls. Currently all are considered inferred in the
    // error messages.
    if (node.arguments.types.isEmpty) return;
    Class? klass = node.target.enclosingClass;
    List<TypeParameter> parameters = node.target.function.typeParameters;
    List<DartType> arguments = node.arguments.types;
    if (parameters.length != arguments.length) {
      assert(loader.assertProblemReportedElsewhere(
          "SourceLibraryBuilder.checkBoundsInStaticInvocation: "
          "the numbers of type parameters and type arguments don't match.",
          expectedPhase: CompilationPhaseForProblemReporting.outline));
      return;
    }

    final DartType bottomType = const NeverType.nonNullable();
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
        parameters, arguments, typeEnvironment, bottomType,
        areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled);
    if (issues.isNotEmpty) {
      DartType? targetReceiver;
      if (klass != null) {
        // Coverage-ignore-block(suite): Not run.
        targetReceiver =
            new InterfaceType(klass, klass.enclosingLibrary.nonNullable);
      }
      String targetName = node.target.name.text;
      _reportTypeArgumentIssues(issues, fileUri, node.fileOffset,
          typeArgumentsInfo: typeArgumentsInfo,
          targetReceiver: targetReceiver,
          targetName: targetName);
    }
  }

  void checkBoundsInMethodInvocation(
      DartType receiverType,
      TypeEnvironment typeEnvironment,
      ClassHierarchyBase classHierarchy,
      ClassHierarchyMembers membersHierarchy,
      Name name,
      Member? interfaceTarget,
      Arguments arguments,
      Uri fileUri,
      int offset) {
    if (arguments.types.isEmpty) return;
    Class klass;
    List<DartType> receiverTypeArguments;
    Map<TypeParameter, DartType> substitutionMap = <TypeParameter, DartType>{};
    if (receiverType is InterfaceType) {
      klass = receiverType.classNode;
      receiverTypeArguments = receiverType.typeArguments;
      for (int i = 0; i < receiverTypeArguments.length; ++i) {
        substitutionMap[klass.typeParameters[i]] = receiverTypeArguments[i];
      }
    } else {
      return;
    }
    // TODO(cstefantsova): Find a better way than relying on [interfaceTarget].
    Member? method =
        membersHierarchy.getDispatchTarget(klass, name) ?? interfaceTarget;
    if (method == null || method is! Procedure) {
      return;
    }
    if (klass != method.enclosingClass) {
      Supertype parent =
          classHierarchy.getClassAsInstanceOf(klass, method.enclosingClass!)!;
      klass = method.enclosingClass!;
      receiverTypeArguments = parent.typeArguments;
      Map<TypeParameter, DartType> instanceSubstitutionMap = substitutionMap;
      substitutionMap = <TypeParameter, DartType>{};
      for (int i = 0; i < receiverTypeArguments.length; ++i) {
        substitutionMap[klass.typeParameters[i]] =
            substitute(receiverTypeArguments[i], instanceSubstitutionMap);
      }
    }
    List<TypeParameter> methodParameters = method.function.typeParameters;
    if (methodParameters.length != arguments.types.length) {
      assert(loader.assertProblemReportedElsewhere(
          "SourceLibraryBuilder.checkBoundsInMethodInvocation: "
          "the numbers of type parameters and type arguments don't match.",
          expectedPhase: CompilationPhaseForProblemReporting.outline));
      return;
    }
    List<TypeParameter> methodTypeParametersOfInstantiated =
        getFreshTypeParameters(methodParameters).freshTypeParameters;
    for (TypeParameter typeParameter in methodTypeParametersOfInstantiated) {
      typeParameter.bound = substitute(typeParameter.bound, substitutionMap);
      typeParameter.defaultType =
          substitute(typeParameter.defaultType, substitutionMap);
    }

    final DartType bottomType = const NeverType.nonNullable();
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
        methodTypeParametersOfInstantiated,
        arguments.types,
        typeEnvironment,
        bottomType,
        areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled);
    _reportTypeArgumentIssues(issues, fileUri, offset,
        typeArgumentsInfo: getTypeArgumentsInfo(arguments),
        targetReceiver: receiverType,
        targetName: name.text);
  }

  void checkBoundsInFunctionInvocation(
      TypeEnvironment typeEnvironment,
      FunctionType functionType,
      String? localName,
      Arguments arguments,
      Uri fileUri,
      int offset) {
    if (arguments.types.isEmpty) return;

    if (functionType.typeParameters.length != arguments.types.length) {
      assert(loader.assertProblemReportedElsewhere(
          "SourceLibraryBuilder.checkBoundsInFunctionInvocation: "
          "the numbers of type parameters and type arguments don't match.",
          expectedPhase: CompilationPhaseForProblemReporting.outline));
      return;
    }
    final DartType bottomType = const NeverType.nonNullable();
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
        getFreshTypeParametersFromStructuralParameters(
                functionType.typeParameters)
            .freshTypeParameters,
        arguments.types,
        typeEnvironment,
        bottomType,
        areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled);
    _reportTypeArgumentIssues(issues, fileUri, offset,
        typeArgumentsInfo: getTypeArgumentsInfo(arguments),
        // TODO(johnniwinther): Special-case messaging on function type
        //  invocation to avoid reference to 'call' and use the function type
        //  instead.
        targetName: localName ?? 'call');
  }

  void checkBoundsInInstantiation(
      TypeEnvironment typeEnvironment,
      FunctionType functionType,
      List<DartType> typeArguments,
      Uri fileUri,
      int offset,
      {required bool inferred}) {
    if (typeArguments.isEmpty) return;

    if (functionType.typeParameters.length != typeArguments.length) {
      // Coverage-ignore-block(suite): Not run.
      assert(loader.assertProblemReportedElsewhere(
          "SourceLibraryBuilder.checkBoundsInInstantiation: "
          "the numbers of type parameters and type arguments don't match.",
          expectedPhase: CompilationPhaseForProblemReporting.outline));
      return;
    }
    final DartType bottomType = const NeverType.nonNullable();
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
        getFreshTypeParametersFromStructuralParameters(
                functionType.typeParameters)
            .freshTypeParameters,
        typeArguments,
        typeEnvironment,
        bottomType,
        areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled);
    _reportTypeArgumentIssues(issues, fileUri, offset,
        targetReceiver: functionType,
        typeArgumentsInfo: inferred
            ? const AllInferredTypeArgumentsInfo()
            : const NoneInferredTypeArgumentsInfo());
  }

  void checkTypesInOutline(TypeEnvironment typeEnvironment) {
    Iterator<Builder> iterator = unfilteredMembersIterator;
    while (iterator.moveNext()) {
      Builder declaration = iterator.current;
      if (declaration is SourceMemberBuilder) {
        declaration.checkTypes(this, libraryNameSpace, typeEnvironment);
      } else if (declaration is SourceClassBuilder) {
        List<SourceNominalParameterBuilder>? typeParameters =
            declaration.typeParameters;
        if (typeParameters != null && typeParameters.isNotEmpty) {
          checkTypeParameterDependencies(this, typeParameters);
        }
        declaration.checkTypesInOutline(typeEnvironment);
      } else if (declaration is SourceExtensionBuilder) {
        List<SourceNominalParameterBuilder>? typeParameters =
            declaration.typeParameters;
        if (typeParameters != null && typeParameters.isNotEmpty) {
          checkTypeParameterDependencies(this, typeParameters);
        }
        declaration.checkTypesInOutline(typeEnvironment);
      } else if (declaration is SourceExtensionTypeDeclarationBuilder) {
        List<SourceNominalParameterBuilder>? typeParameters =
            declaration.typeParameters;
        if (typeParameters != null && typeParameters.isNotEmpty) {
          checkTypeParameterDependencies(this, typeParameters);
        }
        declaration.checkTypesInOutline(typeEnvironment);
      } else if (declaration is SourceTypeAliasBuilder) {
        List<SourceNominalParameterBuilder>? typeParameters =
            declaration.typeParameters;
        if (typeParameters != null && typeParameters.isNotEmpty) {
          checkTypeParameterDependencies(this, typeParameters);
        }
      } else {
        // Coverage-ignore-block(suite): Not run.
        assert(
            declaration is! TypeDeclarationBuilder ||
                declaration is BuiltinTypeDeclarationBuilder,
            "Unexpected declaration ${declaration.runtimeType}");
      }
    }
    checkPendingBoundsChecks(typeEnvironment);
  }

  void registerBoundsCheck(
      DartType type, Uri fileUri, int charOffset, TypeUse typeUse,
      {required bool inferred}) {
    _pendingBoundsChecks.add(new PendingBoundsCheck(
        type, fileUri, charOffset, typeUse,
        inferred: inferred));
  }

  void registerGenericFunctionTypeCheck(
      TypedefType type, Uri fileUri, int charOffset) {
    _pendingGenericFunctionTypeChecks
        .add(new GenericFunctionTypeCheck(type, fileUri, charOffset));
  }

  /// Performs delayed bounds checks.
  void checkPendingBoundsChecks(TypeEnvironment typeEnvironment) {
    for (PendingBoundsCheck pendingBoundsCheck in _pendingBoundsChecks) {
      switch (pendingBoundsCheck.typeUse) {
        case TypeUse.literalTypeArgument:
        case TypeUse.variableType:
        case TypeUse.typeParameterBound:
        case TypeUse.parameterType:
        case TypeUse.recordEntryType:
        case TypeUse.fieldType:
        case TypeUse.returnType:
        case TypeUse.isType:
        case TypeUse.asType:
        case TypeUse.objectPatternType:
        case TypeUse.catchType:
        case TypeUse.constructorTypeArgument:
        case TypeUse.redirectionTypeArgument:
        case TypeUse.tearOffTypeArgument:
        case TypeUse.invocationTypeArgument:
        case TypeUse.typeLiteral:
        case TypeUse.extensionOnType:
        case TypeUse.extensionTypeRepresentationType:
        case TypeUse.typeArgument:
          checkBoundsInType(pendingBoundsCheck.type, typeEnvironment,
              pendingBoundsCheck.fileUri, pendingBoundsCheck.charOffset,
              inferred: pendingBoundsCheck.inferred, allowSuperBounded: true);
          break;
        case TypeUse.typedefAlias:
        case TypeUse.classExtendsType:
        case TypeUse.classImplementsType:
        // TODO(johnniwinther): Is this a correct handling wrt well-boundedness
        //  for mixin on clause?
        case TypeUse.mixinOnType:
        case TypeUse.extensionTypeImplementsType:
        case TypeUse.classWithType:
          checkBoundsInType(pendingBoundsCheck.type, typeEnvironment,
              pendingBoundsCheck.fileUri, pendingBoundsCheck.charOffset,
              inferred: pendingBoundsCheck.inferred, allowSuperBounded: false);
          break;
        case TypeUse.instantiation:
          // TODO(johnniwinther): Should we allow super bounded tear offs of
          // non-proper renames?
          checkBoundsInType(pendingBoundsCheck.type, typeEnvironment,
              pendingBoundsCheck.fileUri, pendingBoundsCheck.charOffset,
              inferred: pendingBoundsCheck.inferred, allowSuperBounded: true);
          break;
        case TypeUse.enumSelfType:
          // TODO(johnniwinther): Check/create this type as regular bounded i2b.
          /*
            checkBoundsInType(pendingBoundsCheck.type, typeEnvironment,
                pendingBoundsCheck.fileUri, pendingBoundsCheck.charOffset,
                inferred: pendingBoundsCheck.inferred,
                allowSuperBounded: false);
          */
          break;
        case TypeUse.typeParameterDefaultType:
        case TypeUse.defaultTypeAsTypeArgument:
        // Coverage-ignore(suite): Not run.
        case TypeUse.deferredTypeError:
          break;
      }
    }
    _pendingBoundsChecks.clear();

    for (GenericFunctionTypeCheck genericFunctionTypeCheck
        in _pendingGenericFunctionTypeChecks) {
      checkGenericFunctionTypeAsTypeArgumentThroughTypedef(
          genericFunctionTypeCheck.type,
          genericFunctionTypeCheck.fileUri,
          genericFunctionTypeCheck.charOffset);
    }
    _pendingGenericFunctionTypeChecks.clear();
  }

  /// Reports an error if [type] contains is a generic function type used as
  /// a type argument through its alias.
  ///
  /// For instance
  ///
  ///   typedef A = B<void Function<T>(T)>;
  ///
  /// here `A` doesn't use a generic function as type argument directly, but
  /// its unaliased value `B<void Function<T>(T)>` does.
  ///
  /// This is used for reporting generic function types used as a type argument,
  /// which was disallowed before the 'generic-metadata' feature was enabled.
  void checkGenericFunctionTypeAsTypeArgumentThroughTypedef(
      TypedefType type, Uri fileUri, int fileOffset) {
    assert(!libraryFeatures.genericMetadata.isEnabled);
    if (!hasGenericFunctionTypeAsTypeArgument(type)) {
      DartType unaliased = type.unalias;
      if (hasGenericFunctionTypeAsTypeArgument(unaliased)) {
        addProblem(
            templateGenericFunctionTypeAsTypeArgumentThroughTypedef
                .withArguments(unaliased, type),
            fileOffset,
            noLength,
            fileUri);
      }
    }
  }

  List<DelayedDefaultValueCloner>? installTypedefTearOffs() {
    List<DelayedDefaultValueCloner>? delayedDefaultValueCloners;
    Iterator<SourceTypeAliasBuilder> iterator =
        filteredMembersIterator(includeDuplicates: true);
    while (iterator.moveNext()) {
      SourceTypeAliasBuilder declaration = iterator.current;
      DelayedDefaultValueCloner? delayedDefaultValueCloner =
          declaration.buildTypedefTearOffs(this, (Procedure procedure) {
        procedure.isStatic = true;
        if (!declaration.isDuplicate) {
          library.addProcedure(procedure);
        }
      });
      if (delayedDefaultValueCloner != null) {
        (delayedDefaultValueCloners ??= []).add(delayedDefaultValueCloner);
      }
    }

    return delayedDefaultValueCloners;
  }
}

/// This class examines all the [Class]es in a library and determines which
/// fields are promotable within that library.
class _FieldPromotability extends FieldPromotability<Class, SourceMemberBuilder,
    SourceMemberBuilder> {
  @override
  Iterable<Class> getSuperclasses(Class class_,
      {required bool ignoreImplements}) {
    List<Class> result = [];
    Class? superclass = class_.superclass;
    if (superclass != null) {
      result.add(superclass);
    }
    Class? mixedInClass = class_.mixedInClass;
    if (mixedInClass != null) {
      result.add(mixedInClass);
    }
    if (!ignoreImplements) {
      for (Supertype interface in class_.implementedTypes) {
        result.add(interface.classNode);
      }
      if (class_.isMixinDeclaration) {
        for (Supertype supertype in class_.onClause) {
          result.add(supertype.classNode);
        }
      }
    }
    return result;
  }
}

/// Information about which fields are promotable in a given library.
class FieldNonPromotabilityInfo {
  /// Map whose keys are private field names for which promotion is blocked, and
  /// whose values are [FieldNameNonPromotabilityInfo] objects containing
  /// information about why promotion is blocked for the given name.
  ///
  /// This map is the final arbiter on whether a given property access is
  /// considered promotable, but since it is keyed on the field name, it doesn't
  /// always provide the most specific information about *why* a given property
  /// isn't promotable; for more detailed information about a specific property,
  /// see [individualPropertyReasons].
  final Map<
      String,
      FieldNameNonPromotabilityInfo<Class, SourceMemberBuilder,
          SourceMemberBuilder>> fieldNameInfo;

  /// Map whose keys are the members that a property get might resolve to, and
  /// whose values are the reasons why the given property couldn't be promoted.
  final Map<Member, PropertyNonPromotabilityReason> individualPropertyReasons;

  FieldNonPromotabilityInfo(
      {required this.fieldNameInfo, required this.individualPropertyReasons});
}

Uri computeLibraryUri(Builder declaration) {
  Builder? current = declaration;
  while (current != null) {
    if (current is LibraryBuilder) return current.importUri;
    current = current.parent;
  }
  return unhandled("no library parent", "${declaration.runtimeType}",
      declaration.fileOffset, declaration.fileUri);
}

class PostponedProblem {
  final Message message;
  final int charOffset;
  final int length;
  final Uri fileUri;

  PostponedProblem(this.message, this.charOffset, this.length, this.fileUri);
}

class LanguageVersion {
  final Version version;
  final Uri? fileUri;
  final int charOffset;
  final int charCount;
  bool isFinal = false;

  LanguageVersion(this.version, this.fileUri, this.charOffset, this.charCount);

  bool get isExplicit => true;

  // Coverage-ignore(suite): Not run.
  bool get valid => true;

  @override
  int get hashCode => version.hashCode * 13 + isExplicit.hashCode * 19;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageVersion &&
        version == other.version &&
        isExplicit == other.isExplicit;
  }

  @override
  String toString() {
    return 'LanguageVersion(version=$version,isExplicit=$isExplicit,'
        'fileUri=$fileUri,charOffset=$charOffset,charCount=$charCount)';
  }
}

class InvalidLanguageVersion implements LanguageVersion {
  @override
  final Uri fileUri;
  @override
  final int charOffset;
  @override
  final int charCount;
  @override
  final Version version;
  @override
  final bool isExplicit;
  @override
  bool isFinal = false;

  InvalidLanguageVersion(this.fileUri, this.charOffset, this.charCount,
      this.version, this.isExplicit);

  @override
  // Coverage-ignore(suite): Not run.
  bool get valid => false;

  @override
  int get hashCode => isExplicit.hashCode * 19;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvalidLanguageVersion && isExplicit == other.isExplicit;
  }

  @override
  String toString() {
    return 'InvalidLanguageVersion(isExplicit=$isExplicit,'
        'fileUri=$fileUri,charOffset=$charOffset,charCount=$charCount)';
  }
}

class ImplicitLanguageVersion implements LanguageVersion {
  @override
  final Version version;
  @override
  bool isFinal = false;

  ImplicitLanguageVersion(this.version);

  @override
  // Coverage-ignore(suite): Not run.
  bool get valid => true;

  @override
  // Coverage-ignore(suite): Not run.
  Uri? get fileUri => null;

  @override
  // Coverage-ignore(suite): Not run.
  int get charOffset => -1;

  @override
  // Coverage-ignore(suite): Not run.
  int get charCount => noLength;

  @override
  bool get isExplicit => false;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImplicitLanguageVersion && version == other.version;
  }

  @override
  String toString() {
    return 'ImplicitLanguageVersion(version=$version)';
  }
}

class PendingBoundsCheck {
  final DartType type;
  final Uri fileUri;
  final int charOffset;
  final TypeUse typeUse;
  final bool inferred;

  PendingBoundsCheck(this.type, this.fileUri, this.charOffset, this.typeUse,
      {required this.inferred});
}

class GenericFunctionTypeCheck {
  final TypedefType type;
  final Uri fileUri;
  final int charOffset;

  GenericFunctionTypeCheck(this.type, this.fileUri, this.charOffset);
}

class LibraryAccess {
  final CompilationUnit accessor;
  final Uri fileUri;
  final int charOffset;
  final int length;

  LibraryAccess(this.accessor, this.fileUri, this.charOffset, this.length);
}

class Part {
  final Uri fileUri;
  final int fileOffset;
  final CompilationUnit compilationUnit;

  Part(
      {required this.fileUri,
      required this.fileOffset,
      required this.compilationUnit});
}
