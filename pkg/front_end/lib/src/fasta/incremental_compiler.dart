// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.incremental_compiler;

import 'dart:async' show Completer;

import 'package:_fe_analyzer_shared/src/scanner/abstract_scanner.dart'
    show ScannerConfiguration;

import 'package:kernel/binary/ast_from_binary.dart'
    show
        BinaryBuilderWithMetadata,
        CompilationModeError,
        InvalidKernelSdkVersionError,
        InvalidKernelVersionError,
        SubComponentView,
        mergeCompilationModeOrThrow;

import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClosedWorldClassHierarchy;

import 'package:kernel/kernel.dart'
    show
        Class,
        Component,
        DartType,
        Expression,
        Extension,
        FunctionNode,
        Library,
        LibraryDependency,
        LibraryPart,
        Name,
        NamedNode,
        NonNullableByDefaultCompiledMode,
        Procedure,
        ProcedureKind,
        Reference,
        ReturnStatement,
        Source,
        Supertype,
        TreeNode,
        TypeParameter,
        VariableDeclaration;

import 'package:kernel/canonical_name.dart'
    show CanonicalNameError, CanonicalNameSdkError;

import 'package:kernel/kernel.dart' as kernel show Combinator;

import 'package:kernel/target/changed_structure_notifier.dart'
    show ChangedStructureNotifier;

import 'package:package_config/package_config.dart' show Package, PackageConfig;

import '../api_prototype/experimental_flags.dart';

import '../api_prototype/file_system.dart' show FileSystem, FileSystemEntity;

import '../api_prototype/incremental_kernel_generator.dart'
    show
        IncrementalCompilerResult,
        IncrementalKernelGenerator,
        isLegalIdentifier;

import '../api_prototype/lowering_predicates.dart' show isExtensionThisName;

import '../api_prototype/memory_file_system.dart' show MemoryFileSystem;

import '../base/nnbd_mode.dart';

import 'builder/builder.dart' show Builder;

import 'builder/class_builder.dart' show ClassBuilder;

import 'builder/extension_builder.dart' show ExtensionBuilder;

import 'builder/field_builder.dart' show FieldBuilder;

import 'builder/library_builder.dart' show LibraryBuilder;

import 'builder/member_builder.dart' show MemberBuilder;

import 'builder/name_iterator.dart' show NameIterator;

import 'builder/type_builder.dart' show TypeBuilder;

import 'builder/type_declaration_builder.dart' show TypeDeclarationBuilder;

import 'builder_graph.dart' show BuilderGraph;

import 'combinator.dart' show CombinatorBuilder;

import 'compiler_context.dart' show CompilerContext;

import 'dill/dill_class_builder.dart' show DillClassBuilder;

import 'dill/dill_library_builder.dart' show DillLibraryBuilder;

import 'dill/dill_loader.dart' show DillLoader;
import 'dill/dill_target.dart' show DillTarget;

import 'export.dart' show Export;

import 'fasta_codes.dart';

import 'import.dart' show Import;

import 'incremental_serializer.dart' show IncrementalSerializer;

import 'scope.dart' show Scope;

import 'source/source_class_builder.dart' show SourceClassBuilder;

import 'util/error_reporter_file_copier.dart' show saveAsGzip;

import 'util/experiment_environment_getter.dart' show getExperimentEnvironment;

import 'util/textual_outline.dart' show textualOutline;

import 'hybrid_file_system.dart' show HybridFileSystem;

import 'kernel/class_hierarchy_builder.dart' show ClassHierarchyBuilder;

import 'kernel/internal_ast.dart' show VariableDeclarationImpl;

import 'kernel/kernel_target.dart' show KernelTarget;

import 'library_graph.dart' show LibraryGraph;

import 'source/source_library_builder.dart'
    show ImplicitLanguageVersion, SourceLibraryBuilder;

import 'source/source_loader.dart';

import 'ticker.dart' show Ticker;

import 'uri_translator.dart' show UriTranslator;

final Uri dartFfiUri = Uri.parse("dart:ffi");

class IncrementalCompiler implements IncrementalKernelGenerator {
  final CompilerContext context;

  final Ticker _ticker;
  final bool _resetTicker;
  final bool outlineOnly;
  bool trackNeededDillLibraries = false;
  Set<Library>? _neededDillLibraries;

  Set<Uri?> _invalidatedUris = new Set<Uri?>();

  DillTarget? _dillLoadedData;
  List<LibraryBuilder>? _platformBuilders;
  Map<Uri, LibraryBuilder>? _userBuilders;
  final Uri? _initializeFromDillUri;
  Component? _componentToInitializeFrom;
  bool _initializedFromDill = false;
  bool _initializedIncrementalSerializer = false;
  Uri? _previousPackagesUri;
  Map<String, Package>? _previousPackagesMap;
  Map<String, Package>? _currentPackagesMap;
  bool _hasToCheckPackageUris = false;
  final bool _initializedForExpressionCompilationOnly;
  bool _computeDeltaRunOnce = false;
  Map<Uri, List<DiagnosticMessageFromJson>> _remainingComponentProblems =
      new Map<Uri, List<DiagnosticMessageFromJson>>();
  List<Component>? _modulesToLoad;
  IncrementalSerializer? _incrementalSerializer;

  static final Uri debugExprUri =
      new Uri(scheme: "org-dartlang-debug", path: "synthetic_debug_expression");

  IncrementalKernelTarget? _userCode;
  Set<Library>? _previousSourceBuilders;

  /// Guard against multiple computeDelta calls at the same time (possibly
  /// caused by lacking awaits etc).
  Completer<dynamic>? _currentlyCompiling;

  IncrementalCompiler.fromComponent(
      this.context, this._componentToInitializeFrom,
      [bool? outlineOnly, this._incrementalSerializer])
      : _ticker = context.options.ticker,
        _resetTicker = true,
        _initializeFromDillUri = null,
        this.outlineOnly = outlineOnly ?? false,
        this._initializedForExpressionCompilationOnly = false {
    _enableExperimentsBasedOnEnvironment();
  }

  IncrementalCompiler(this.context,
      [this._initializeFromDillUri,
      bool? outlineOnly,
      this._incrementalSerializer])
      : _ticker = context.options.ticker,
        _resetTicker = true,
        _componentToInitializeFrom = null,
        this.outlineOnly = outlineOnly ?? false,
        this._initializedForExpressionCompilationOnly = false {
    _enableExperimentsBasedOnEnvironment();
  }

  IncrementalCompiler.forExpressionCompilationOnly(
      this.context, this._componentToInitializeFrom,
      [bool? resetTicker])
      : _ticker = context.options.ticker,
        this._resetTicker = resetTicker ?? true,
        _initializeFromDillUri = null,
        this.outlineOnly = false,
        this._incrementalSerializer = null,
        this._initializedForExpressionCompilationOnly = true {
    _enableExperimentsBasedOnEnvironment();
  }

  bool get initializedFromDill => _initializedFromDill;

  bool get initializedIncrementalSerializer =>
      _initializedIncrementalSerializer;

  Set<Library>? get neededDillLibraries => _neededDillLibraries;

  DillTarget? get dillTargetForTesting => _dillLoadedData;

  IncrementalKernelTarget? get kernelTargetForTesting => _userCode;

  /// Returns the [Package] used for the package [packageName] in the most
  /// recent compilation.
  Package? getPackageForPackageName(String packageName) =>
      _currentPackagesMap?[packageName];

  /// Returns the [Library] with the given [importUri] from the most recent
  /// compilation.
  Library? lookupLibrary(Uri importUri) =>
      _userCode?.loader.lookupLibraryBuilder(importUri)?.library;

  void _enableExperimentsBasedOnEnvironment({Set<String>? enabledExperiments}) {
    // Note that these are all experimental. Use at your own risk.
    enabledExperiments ??= getExperimentEnvironment();
    // Currently there's no live experiments.
  }

  @override
  void setExperimentalFeaturesForTesting(Set<String> features) {
    _enableExperimentsBasedOnEnvironment(enabledExperiments: features);
  }

  @override
  Future<IncrementalCompilerResult> computeDelta(
      {List<Uri>? entryPoints, bool fullComponent: false}) async {
    while (_currentlyCompiling != null) {
      await _currentlyCompiling!.future;
    }
    _currentlyCompiling = new Completer();
    if (_resetTicker) {
      _ticker.reset();
    }
    entryPoints ??= context.options.inputs;
    return context
        .runInContext<IncrementalCompilerResult>((CompilerContext c) async {
      if (_computeDeltaRunOnce && _initializedForExpressionCompilationOnly) {
        throw new StateError("Initialized for expression compilation: "
            "cannot do another general compile.");
      }
      _computeDeltaRunOnce = true;
      // Initial setup: Load platform, initialize from dill or component etc.
      UriTranslator uriTranslator = await _setupPackagesAndUriTranslator(c);
      IncrementalCompilerData data =
          await _ensurePlatformAndInitialize(uriTranslator, c);

      // Figure out what to keep and what to throw away.
      Set<Uri?> invalidatedUris = this._invalidatedUris.toSet();
      _invalidateNotKeptUserBuilders(invalidatedUris);
      ReusageResult? reusedResult =
          _computeReusedLibraries(invalidatedUris, uriTranslator, entryPoints!);

      // Use the reused libraries to re-write entry-points.
      if (reusedResult.arePartsUsedAsEntryPoints()) {
        for (int i = 0; i < entryPoints!.length; i++) {
          Uri entryPoint = entryPoints![i];
          Uri? redirect =
              reusedResult.getLibraryUriForPartUsedAsEntryPoint(entryPoint);
          if (redirect != null) {
            entryPoints![i] = redirect;
          }
        }
      }

      // Experimental invalidation initialization (e.g. figure out if we can).
      ExperimentalInvalidation? experimentalInvalidation =
          await _initializeExperimentalInvalidation(reusedResult, c);
      recordRebuildBodiesCountForTesting(
          experimentalInvalidation?.missingSources.length ?? 0);

      // Cleanup: After (potentially) removing builders we have stuff to cleanup
      // to not leak, and we might need to re-create the dill target.
      _cleanupRemovedBuilders(reusedResult, uriTranslator);
      _recreateDillTargetIfPackageWasUpdated(uriTranslator, c);
      ClassHierarchy? hierarchy = _userCode?.loader.hierarchy;
      _cleanupHierarchy(hierarchy, experimentalInvalidation, reusedResult);
      List<LibraryBuilder> reusedLibraries = reusedResult.reusedLibraries;
      reusedResult = null;

      // TODO(jensj): Given the code below, [userCode] is assumed always to be
      // non-null.
      if (_userCode != null) {
        _ticker.logMs("Decided to reuse ${reusedLibraries.length}"
            " of ${_userCode!.loader.libraryBuilders.length} libraries");
      }

      // For modular compilation we can be asked to load components and track
      // which libraries we actually use for the compilation. Set that up now.
      _loadEnsureLoadedComponents(reusedLibraries);
      _resetTrackingOfUsedLibraries(hierarchy);

      // For each computeDelta call we create a new userCode object which needs
      // to be setup, and in the case of experimental invalidation some of the
      // builders needs to be patched up.
      IncrementalKernelTarget? userCodeOld = _userCode;
      _setupNewUserCode(c, uriTranslator, hierarchy, reusedLibraries,
          experimentalInvalidation, entryPoints!.first);
      Map<LibraryBuilder, List<LibraryBuilder>>? rebuildBodiesMap =
          _experimentalInvalidationCreateRebuildBodiesBuilders(
              experimentalInvalidation, uriTranslator);
      entryPoints = _userCode!.setEntryPoints(entryPoints!);
      await _userCode!.loader.buildOutlines();
      _experimentalInvalidationPatchUpScopes(
          experimentalInvalidation, rebuildBodiesMap);
      rebuildBodiesMap = null;

      // Checkpoint: Build the actual outline.
      // Note that the [Component] is not the "full" component.
      // It is a component consisting of all newly compiled libraries and all
      // libraries loaded from .dill files or directly from components.
      // Technically, it's the combination of userCode.loader.libraries and
      // dillLoadedData.loader.libraries.
      Component? componentWithDill = await _userCode!.buildOutlines();

      if (!outlineOnly) {
        // Checkpoint: Build the actual bodies.
        componentWithDill =
            await _userCode!.buildComponent(verify: c.options.verify);
      }
      hierarchy ??= _userCode!.loader.hierarchy;
      // ignore: unnecessary_null_comparison
      if (hierarchy != null) {
        if (_userCode!.classHierarchyChanges != null) {
          hierarchy.applyTreeChanges([], [], _userCode!.classHierarchyChanges!);
        }
        if (_userCode!.classMemberChanges != null) {
          hierarchy.applyMemberChanges(_userCode!.classMemberChanges!,
              findDescendants: true);
        }
      }
      recordNonFullComponentForTesting(componentWithDill!);

      // Perform actual dill usage tracking.
      _performDillUsageTracking(hierarchy);

      // If we actually got a result we can throw away the old userCode and the
      // list of invalidated uris.
      // ignore: unnecessary_null_comparison
      if (componentWithDill != null) {
        this._invalidatedUris.clear();
        _hasToCheckPackageUris = false;
        userCodeOld?.loader.releaseAncillaryResources();
        userCodeOld = null;
      }

      // Compute which libraries to output and which (previous) errors/warnings
      // we have to reissue. In the process do some cleanup too.
      List<Library> compiledLibraries =
          new List<Library>.from(_userCode!.loader.libraries);
      Map<Uri, Source> uriToSource = componentWithDill.uriToSource;
      _experimentalCompilationPostCompilePatchup(
          experimentalInvalidation, compiledLibraries, uriToSource);
      List<Library> outputLibraries =
          _calculateOutputLibrariesAndIssueLibraryProblems(
              data.component != null || fullComponent,
              compiledLibraries,
              entryPoints!,
              reusedLibraries,
              hierarchy,
              uriTranslator,
              uriToSource,
              c);
      List<String> problemsAsJson =
          _reissueComponentProblems(componentWithDill);

      // If we didn't get a result, go back to the previous one so expression
      // calculation has the potential to work.
      // ignore: unnecessary_null_comparison
      if (componentWithDill == null) {
        _userCode!.loader.clearLibraryBuilders();
        _userCode = userCodeOld;
        _dillLoadedData!.loader.currentSourceLoader = _userCode!.loader;
      } else {
        _previousSourceBuilders =
            _convertSourceLibraryBuildersToDill(experimentalInvalidation);
      }

      experimentalInvalidation = null;

      // Output result.
      // ignore: unnecessary_null_comparison
      Procedure? mainMethod = componentWithDill == null
          ? data.component?.mainMethod
          : componentWithDill.mainMethod;
      // ignore: unnecessary_null_comparison
      NonNullableByDefaultCompiledMode? compiledMode = componentWithDill == null
          ? data.component?.mode
          : componentWithDill.mode;
      Component result = context.options.target.configureComponent(
          new Component(libraries: outputLibraries, uriToSource: uriToSource))
        ..setMainMethodAndMode(mainMethod?.reference, true, compiledMode!)
        ..problemsAsJson = problemsAsJson;

      // We're now done. Allow any waiting compile to start.
      Completer<dynamic> currentlyCompilingLocal = _currentlyCompiling!;
      _currentlyCompiling = null;
      currentlyCompilingLocal.complete();

      return new IncrementalCompilerResult(result,
          classHierarchy: _userCode?.loader.hierarchy,
          coreTypes: _userCode?.loader.coreTypes);
    });
  }

  /// Convert every SourceLibraryBuilder to a DillLibraryBuilder.
  /// As we always do this, this will only be the new ones.
  ///
  /// If doing experimental invalidation that means that some of the old dill
  /// library builders might have links (via export scopes) to the
  /// source builders and they will thus be patched up here too.
  ///
  /// Returns the set of Libraries that now has new (dill) builders.
  Set<Library> _convertSourceLibraryBuildersToDill(
      ExperimentalInvalidation? experimentalInvalidation) {
    bool changed = false;
    Set<Library> newDillLibraryBuilders = new Set<Library>();
    _userBuilders ??= <Uri, LibraryBuilder>{};
    Map<LibraryBuilder, List<LibraryBuilder>>? convertedLibraries;
    for (LibraryBuilder builder in _userCode!.loader.libraryBuilders) {
      if (builder is SourceLibraryBuilder) {
        DillLibraryBuilder dillBuilder =
            _dillLoadedData!.loader.appendLibrary(builder.library);
        _userCode!.loader.registerLibraryBuilder(
            // TODO(johnniwinther): Why do we need to create
            //  [DillLibraryBuilder]s for the patch library file uris?
            dillBuilder,
            builder.isPatch ? builder.fileUri : null);
        _userBuilders![builder.importUri] = dillBuilder;
        newDillLibraryBuilders.add(builder.library);
        if (_userCode!.loader.first == builder) {
          _userCode!.loader.first = dillBuilder;
        }
        changed = true;
        if (experimentalInvalidation != null) {
          convertedLibraries ??=
              new Map<LibraryBuilder, List<LibraryBuilder>>();
          convertedLibraries[builder] = [dillBuilder];
        }
      }
    }
    if (changed) {
      // We suppress finalization errors because they have already been
      // reported.
      _dillLoadedData!.buildOutlines(suppressFinalizationErrors: true);
      assert(
          _checkEquivalentScopes(_userCode!.loader, _dillLoadedData!.loader));

      if (experimentalInvalidation != null) {
        /// If doing experimental invalidation that means that some of the old
        /// dill library builders might have links (via export scopes) to the
        /// source builders. Patch that up.

        // Maps from old library builder to map of new content.
        Map<LibraryBuilder, Map<String, Builder>>? replacementMap = {};

        // Maps from old library builder to map of new content.
        Map<LibraryBuilder, Map<String, Builder>>? replacementSettersMap = {};

        _experimentalInvalidationFillReplacementMaps(
            convertedLibraries!, replacementMap, replacementSettersMap);

        for (LibraryBuilder builder
            in experimentalInvalidation.originalNotReusedLibraries) {
          DillLibraryBuilder dillBuilder = builder as DillLibraryBuilder;
          if (dillBuilder.isBuilt) {
            dillBuilder.exportScope
                .patchUpScope(replacementMap, replacementSettersMap);

            // Clear cached calculations that points (potential) to now replaced
            // things.
            for (Builder builder in dillBuilder.scope.localMembers) {
              if (builder is DillClassBuilder) {
                builder.clearCachedValues();
              }
            }
          }
        }
        replacementMap = null;
        replacementSettersMap = null;
      }
    }
    _userCode!.loader.buildersCreatedWithReferences.clear();
    _userCode!.loader.builderHierarchy.clear();
    _userCode!.loader.referenceFromIndex = null;
    convertedLibraries = null;
    experimentalInvalidation = null;
    if (_userBuilders!.isEmpty) _userBuilders = null;
    return newDillLibraryBuilders;
  }

  bool _checkEquivalentScopes(
      SourceLoader sourceLoader, DillLoader dillLoader) {
    for (LibraryBuilder sourceLibraryBuilder in sourceLoader.libraryBuilders) {
      if (sourceLibraryBuilder is SourceLibraryBuilder) {
        Uri uri = sourceLibraryBuilder.importUri;
        DillLibraryBuilder dillLibraryBuilder =
            dillLoader.lookupLibraryBuilder(uri)!;
        assert(
            _hasEquivalentScopes(sourceLibraryBuilder, dillLibraryBuilder) ==
                null,
            _hasEquivalentScopes(sourceLibraryBuilder, dillLibraryBuilder));
      }
    }
    return true;
  }

  String? _hasEquivalentScopes(SourceLibraryBuilder sourceLibraryBuilder,
      DillLibraryBuilder dillLibraryBuilder) {
    bool isEquivalent = true;
    StringBuffer sb = new StringBuffer();
    sb.writeln('Mismatch on ${sourceLibraryBuilder.importUri}:');
    sourceLibraryBuilder.exportScope
        .forEachLocalMember((String name, Builder sourceBuilder) {
      Builder? dillBuilder =
          dillLibraryBuilder.exportScope.lookupLocalMember(name, setter: false);
      if (dillBuilder == null) {
        if ((name == 'dynamic' || name == 'Never') &&
            sourceLibraryBuilder.importUri == Uri.parse('dart:core')) {
          // The source library builder for dart:core has synthetically
          // injected builders for `dynamic` and `Never` which do not have
          // corresponding classes in the AST.
          return;
        }
        sb.writeln('No dill builder for ${name}: $sourceBuilder');
        isEquivalent = false;
      }
    });
    dillLibraryBuilder.exportScope
        .forEachLocalMember((String name, Builder dillBuilder) {
      Builder? sourceBuilder = sourceLibraryBuilder.exportScope
          .lookupLocalMember(name, setter: false);
      if (sourceBuilder == null) {
        sb.writeln('No source builder for ${name}: $dillBuilder');
        isEquivalent = false;
      }
    });
    sourceLibraryBuilder.exportScope
        .forEachLocalSetter((String name, Builder sourceBuilder) {
      Builder? dillBuilder =
          dillLibraryBuilder.exportScope.lookupLocalMember(name, setter: true);
      if (dillBuilder == null) {
        sb.writeln('No dill builder for ${name}=: $sourceBuilder');
        isEquivalent = false;
      }
    });
    dillLibraryBuilder.exportScope
        .forEachLocalSetter((String name, Builder dillBuilder) {
      Builder? sourceBuilder = sourceLibraryBuilder.exportScope
          .lookupLocalMember(name, setter: true);
      if (sourceBuilder == null) {
        sourceBuilder = sourceLibraryBuilder.exportScope
            .lookupLocalMember(name, setter: false);
        if (sourceBuilder is FieldBuilder && sourceBuilder.isAssignable) {
          // Assignable fields can be lowered into a getter and setter.
          return;
        }
        sb.writeln('No source builder for ${name}=: $dillBuilder');
        isEquivalent = false;
      }
    });
    if (isEquivalent) {
      return null;
    }
    return sb.toString();
  }

  /// Compute which libraries to output and which (previous) errors/warnings we
  /// have to reissue. In the process do some cleanup too.
  List<Library> _calculateOutputLibrariesAndIssueLibraryProblems(
      bool fullComponent,
      List<Library> compiledLibraries,
      List<Uri> entryPoints,
      List<LibraryBuilder> reusedLibraries,
      ClassHierarchy hierarchy,
      UriTranslator uriTranslator,
      Map<Uri, Source> uriToSource,
      CompilerContext c) {
    List<Library> outputLibraries;
    Set<Library> allLibraries;
    if (fullComponent) {
      outputLibraries = _computeTransitiveClosure(compiledLibraries,
          entryPoints, reusedLibraries, hierarchy, uriTranslator, uriToSource);
      allLibraries = outputLibraries.toSet();
      if (!c.options.omitPlatform) {
        for (int i = 0; i < _platformBuilders!.length; i++) {
          Library lib = _platformBuilders![i].library;
          outputLibraries.add(lib);
        }
      }
    } else {
      outputLibraries = <Library>[];
      allLibraries = _computeTransitiveClosure(
              compiledLibraries,
              entryPoints,
              reusedLibraries,
              hierarchy,
              uriTranslator,
              uriToSource,
              outputLibraries)
          .toSet();
    }

    _reissueLibraryProblems(allLibraries, compiledLibraries);
    return outputLibraries;
  }

  /// If doing experimental compilation, make sure [compiledLibraries] and
  /// [uriToSource] looks as they would have if we hadn't done experimental
  /// compilation, i.e. before this call [compiledLibraries] might only contain
  /// the single Library we compiled again, but after this call, it will also
  /// contain all the libraries that would normally have been recompiled.
  /// This might be a temporary thing, but we need to figure out if the VM
  /// can (always) work with only getting the actually rebuild stuff.
  void _experimentalCompilationPostCompilePatchup(
      ExperimentalInvalidation? experimentalInvalidation,
      List<Library> compiledLibraries,
      Map<Uri, Source> uriToSource) {
    if (experimentalInvalidation != null) {
      // uriToSources are created in the outline stage which we skipped for
      // some of the libraries.
      for (Uri uri in experimentalInvalidation.missingSources) {
        // TODO(jensj): KernelTargets "link" takes some "excludeSource"
        // setting into account.
        uriToSource[uri] = CompilerContext.current.uriToSource[uri]!;
      }
    }
  }

  /// Perform dill usage tracking if asked. Use the marking on dill builders as
  /// well as the class hierarchy to figure out which dill libraries was
  /// actually used by the compilation.
  void _performDillUsageTracking(ClassHierarchy hierarchy) {
    if (trackNeededDillLibraries) {
      // Which dill builders were built?
      Set<Library> neededDillLibraries = _neededDillLibraries = {};

      // Propagate data from constant evaluator: Libraries used in the constant
      // evaluator - that comes from dill - are marked.
      Set<Library> librariesUsedByConstantEvaluator = _userCode!.librariesUsed;

      for (LibraryBuilder builder in _dillLoadedData!.loader.libraryBuilders) {
        if (builder is DillLibraryBuilder) {
          if (builder.isBuiltAndMarked ||
              librariesUsedByConstantEvaluator.contains(builder.library)) {
            neededDillLibraries.add(builder.library);
          }
        }
      }

      updateNeededDillLibrariesWithHierarchy(
          hierarchy, _userCode!.loader.builderHierarchy);
    }
  }

  /// Fill in the replacement maps that describe the replacements that need to
  /// happen because of experimental invalidation.
  void _experimentalInvalidationFillReplacementMaps(
      Map<LibraryBuilder, List<LibraryBuilder>> rebuildBodiesMap,
      Map<LibraryBuilder, Map<String, Builder>> replacementMap,
      Map<LibraryBuilder, Map<String, Builder>> replacementSettersMap) {
    for (MapEntry<LibraryBuilder, List<LibraryBuilder>> entry
        in rebuildBodiesMap.entries) {
      Map<String, Builder> childReplacementMap = {};
      Map<String, Builder> childReplacementSettersMap = {};
      List<LibraryBuilder> builders = rebuildBodiesMap[entry.key]!;
      replacementMap[entry.key] = childReplacementMap;
      replacementSettersMap[entry.key] = childReplacementSettersMap;
      for (LibraryBuilder builder in builders) {
        NameIterator iterator = builder.nameIterator;
        while (iterator.moveNext()) {
          Builder childBuilder = iterator.current;
          String name = iterator.name;
          Map<String, Builder> map;
          if (childBuilder.isSetter) {
            map = childReplacementSettersMap;
          } else {
            map = childReplacementMap;
          }
          assert(
              !map.containsKey(name),
              "Unexpected double-entry for $name in ${builder.importUri} "
              "(org from ${entry.key.importUri}): $childBuilder and "
              "${map[name]}");
          map[name] = childBuilder;
        }
      }
    }
  }

  /// When doing experimental invalidation, we have some builders that needs to
  /// be rebuild special, namely they have to be [userCode.loader.read] with
  /// references from the original [Library] for things to work.
  Map<LibraryBuilder, List<LibraryBuilder>>
      _experimentalInvalidationCreateRebuildBodiesBuilders(
          ExperimentalInvalidation? experimentalInvalidation,
          UriTranslator uriTranslator) {
    // Any builder(s) in [rebuildBodies] should be semi-reused: Create source
    // builders based on the underlying libraries.
    // Maps from old library builder to list of new library builder(s).
    Map<LibraryBuilder, List<LibraryBuilder>> rebuildBodiesMap =
        new Map<LibraryBuilder, List<LibraryBuilder>>.identity();
    if (experimentalInvalidation != null) {
      for (LibraryBuilder library in experimentalInvalidation.rebuildBodies) {
        LibraryBuilder newBuilder = _userCode!.loader.read(
            library.importUri, -1,
            accessor: _userCode!.loader.first,
            fileUri: library.fileUri,
            referencesFrom: library.library);
        List<LibraryBuilder> builders = [newBuilder];
        rebuildBodiesMap[library] = builders;
        for (LibraryPart part in library.library.parts) {
          // We need to pass the reference to make any class, procedure etc
          // overwrite correctly, but the library itself should  not be
          // over written as the library for parts are temporary "fake"
          // libraries.
          Uri partUri = getPartUri(library.importUri, part);
          Uri? fileUri =
              _getPartFileUri(library.library.fileUri, part, uriTranslator);
          LibraryBuilder newPartBuilder = _userCode!.loader.read(partUri, -1,
              accessor: library,
              fileUri: fileUri,
              referencesFrom: library.library,
              referenceIsPartOwner: true);
          builders.add(newPartBuilder);
        }
      }
    }
    return rebuildBodiesMap;
  }

  /// When doing experimental invalidation we have to patch up the scopes of the
  /// the libraries we're not recompiling but should have recompiled if we
  /// didn't do anything special.
  void _experimentalInvalidationPatchUpScopes(
      ExperimentalInvalidation? experimentalInvalidation,
      Map<LibraryBuilder, List<LibraryBuilder>> rebuildBodiesMap) {
    if (experimentalInvalidation != null) {
      // Maps from old library builder to map of new content.
      Map<LibraryBuilder, Map<String, Builder>> replacementMap = {};

      // Maps from old library builder to map of new content.
      Map<LibraryBuilder, Map<String, Builder>> replacementSettersMap = {};

      _experimentalInvalidationFillReplacementMaps(
          rebuildBodiesMap, replacementMap, replacementSettersMap);

      for (LibraryBuilder builder
          in experimentalInvalidation.originalNotReusedLibraries) {
        if (builder is SourceLibraryBuilder) {
          builder.clearExtensionsInScopeCache();
          for (Import import in builder.imports) {
            assert(import.importer == builder);
            List<LibraryBuilder>? replacements =
                rebuildBodiesMap[import.imported];
            if (replacements != null) {
              import.imported = replacements.first;
            }
            if (import.prefixBuilder?.exportScope != null) {
              Scope scope = import.prefixBuilder!.exportScope;
              scope.patchUpScope(replacementMap, replacementSettersMap);
            }
          }
          for (Export export in builder.exports) {
            assert(export.exporter == builder);
            List<LibraryBuilder>? replacements =
                rebuildBodiesMap[export.exported];

            if (replacements != null) {
              export.exported = replacements.first;
            }
          }
          builder.exportScope
              .patchUpScope(replacementMap, replacementSettersMap);
          builder.importScope
              .patchUpScope(replacementMap, replacementSettersMap);

          Iterator<Builder> iterator = builder.iterator;
          while (iterator.moveNext()) {
            Builder childBuilder = iterator.current;
            if (childBuilder is SourceClassBuilder) {
              TypeBuilder? typeBuilder = childBuilder.supertypeBuilder;
              _replaceTypeBuilder(
                  replacementMap, replacementSettersMap, typeBuilder);
              typeBuilder = childBuilder.mixedInTypeBuilder;
              _replaceTypeBuilder(
                  replacementMap, replacementSettersMap, typeBuilder);
              if (childBuilder.onTypes != null) {
                for (typeBuilder in childBuilder.onTypes!) {
                  _replaceTypeBuilder(
                      replacementMap, replacementSettersMap, typeBuilder);
                }
              }
              if (childBuilder.interfaceBuilders != null) {
                for (typeBuilder in childBuilder.interfaceBuilders!) {
                  _replaceTypeBuilder(
                      replacementMap, replacementSettersMap, typeBuilder);
                }
              }
            }
          }
        } else if (builder is DillLibraryBuilder) {
          DillLibraryBuilder dillBuilder = builder;
          // There's only something to patch up if it was build already.
          if (dillBuilder.isBuilt) {
            dillBuilder.exportScope
                .patchUpScope(replacementMap, replacementSettersMap);
          }
        } else {
          throw new StateError(
              "Unexpected builder: $builder (${builder.runtimeType})");
        }
      }
    }
  }

  IncrementalKernelTarget createIncrementalKernelTarget(
      FileSystem fileSystem,
      bool includeComments,
      DillTarget dillTarget,
      UriTranslator uriTranslator) {
    return new IncrementalKernelTarget(
        fileSystem, includeComments, dillTarget, uriTranslator);
  }

  /// Create a new [_userCode] object, and add the reused builders to it.
  void _setupNewUserCode(
      CompilerContext c,
      UriTranslator uriTranslator,
      ClassHierarchy? hierarchy,
      List<LibraryBuilder> reusedLibraries,
      ExperimentalInvalidation? experimentalInvalidation,
      Uri firstEntryPoint) {
    _userCode = createIncrementalKernelTarget(
        new HybridFileSystem(
            new MemoryFileSystem(
                new Uri(scheme: "org-dartlang-debug", path: "/")),
            c.fileSystem),
        false,
        _dillLoadedData!,
        uriTranslator);
    _userCode!.loader.hierarchy = hierarchy;
    _dillLoadedData!.loader.currentSourceLoader = _userCode!.loader;

    // Re-use the libraries we've deemed re-usable.
    List<bool> seenModes = [false, false, false, false];
    for (LibraryBuilder library in reusedLibraries) {
      seenModes[library.library.nonNullableByDefaultCompiledMode.index] = true;
      _userCode!.loader.registerLibraryBuilder(library);
    }
    // Check compilation mode up against what we've seen here and set
    // `hasInvalidNnbdModeLibrary` accordingly.
    if (c.options.isExperimentEnabledGlobally(ExperimentalFlag.nonNullable)) {
      switch (c.options.nnbdMode) {
        case NnbdMode.Weak:
          // Don't expect strong or invalid.
          if (seenModes[NonNullableByDefaultCompiledMode.Strong.index] ||
              seenModes[NonNullableByDefaultCompiledMode.Invalid.index]) {
            _userCode!.loader.hasInvalidNnbdModeLibrary = true;
          }
          break;
        case NnbdMode.Strong:
          // Don't expect weak or invalid.
          if (seenModes[NonNullableByDefaultCompiledMode.Weak.index] ||
              seenModes[NonNullableByDefaultCompiledMode.Invalid.index]) {
            _userCode!.loader.hasInvalidNnbdModeLibrary = true;
          }
          break;
        case NnbdMode.Agnostic:
          // Don't expect strong, weak or invalid.
          if (seenModes[NonNullableByDefaultCompiledMode.Strong.index] ||
              seenModes[NonNullableByDefaultCompiledMode.Weak.index] ||
              seenModes[NonNullableByDefaultCompiledMode.Invalid.index]) {
            _userCode!.loader.hasInvalidNnbdModeLibrary = true;
          }
          break;
      }
    } else {
      // Don't expect strong or invalid.
      if (seenModes[NonNullableByDefaultCompiledMode.Strong.index] ||
          seenModes[NonNullableByDefaultCompiledMode.Invalid.index]) {
        _userCode!.loader.hasInvalidNnbdModeLibrary = true;
      }
    }

    // The entry point(s) has to be set first for loader.first to be setup
    // correctly. If the first one is in the rebuildBodies, we have to add it
    // from there first.
    Uri firstEntryPointImportUri =
        _userCode!.getEntryPointUri(firstEntryPoint, issueProblem: false);
    bool wasFirstSet = false;
    if (experimentalInvalidation != null) {
      for (LibraryBuilder library in experimentalInvalidation.rebuildBodies) {
        if (library.importUri == firstEntryPointImportUri) {
          _userCode!.loader.read(library.importUri, -1,
              accessor: _userCode!.loader.first,
              fileUri: library.fileUri,
              referencesFrom: library.library);
          wasFirstSet = true;
          break;
        }
      }
    }
    if (!wasFirstSet) {
      _userCode!.loader.read(firstEntryPointImportUri, -1,
          accessor: _userCode!.loader.first,
          fileUri: firstEntryPointImportUri != firstEntryPoint
              ? firstEntryPoint
              : null);
    }
    if (_userCode!.loader.first == null) {
      LibraryBuilder? libraryBuilder =
          _userCode!.loader.lookupLibraryBuilder(firstEntryPointImportUri);
      if (libraryBuilder != null) {
        _userCode!.loader.first = libraryBuilder;
      }
    }
  }

  /// When tracking used libraries we mark them when we use them. To track
  /// correctly we have to unmark before the next iteration to not have too much
  /// marked and therefore incorrectly marked something as used when it is not.
  void _resetTrackingOfUsedLibraries(ClassHierarchy? hierarchy) {
    if (trackNeededDillLibraries) {
      // Reset dill loaders and kernel class hierarchy.
      for (LibraryBuilder builder in _dillLoadedData!.loader.libraryBuilders) {
        if (builder is DillLibraryBuilder) {
          if (builder.isBuiltAndMarked) {
            // Clear cached calculations in classes which upon calculation can
            // mark things as needed.
            for (Builder builder in builder.scope.localMembers) {
              if (builder is DillClassBuilder) {
                builder.clearCachedValues();
              }
            }
            builder.isBuiltAndMarked = false;
          }
        }
      }

      if (hierarchy is ClosedWorldClassHierarchy) {
        hierarchy.resetUsed();
      }
    }
  }

  /// Cleanup the hierarchy to no longer reference libraries that we are
  /// invalidating (or would normally have invalidated if we hadn't done any
  /// experimental invalidation).
  void _cleanupHierarchy(
      ClassHierarchy? hierarchy,
      ExperimentalInvalidation? experimentalInvalidation,
      ReusageResult reusedResult) {
    if (hierarchy != null) {
      List<Library> removedLibraries = <Library>[];
      // TODO(jensj): For now remove all the original from the class hierarchy
      // to avoid the class hierarchy getting confused.
      if (experimentalInvalidation != null) {
        for (LibraryBuilder builder
            in experimentalInvalidation.originalNotReusedLibraries) {
          Library lib = builder.library;
          removedLibraries.add(lib);
        }
      }
      for (LibraryBuilder builder in reusedResult.notReusedLibraries) {
        Library lib = builder.library;
        removedLibraries.add(lib);
      }
      hierarchy.applyTreeChanges(removedLibraries, const [], const []);
    }
  }

  /// If the package uris needs to be re-checked the uri translator has changed,
  /// and the [DillTarget] needs to get the new uri translator. We do that
  /// by creating a new one.
  void _recreateDillTargetIfPackageWasUpdated(
      UriTranslator uriTranslator, CompilerContext c) {
    if (_hasToCheckPackageUris) {
      // The package file was changed.
      // Make sure the dill loader is on the same page.
      DillTarget oldDillLoadedData = _dillLoadedData!;
      DillTarget newDillLoadedData = _dillLoadedData =
          new DillTarget(_ticker, uriTranslator, c.options.target);
      for (DillLibraryBuilder library
          in oldDillLoadedData.loader.libraryBuilders) {
        newDillLoadedData.loader.registerLibraryBuilder(library);
      }
      newDillLoadedData.loader.first = oldDillLoadedData.loader.first;
      newDillLoadedData.loader.libraries
          .addAll(oldDillLoadedData.loader.libraries);
    }
  }

  /// Builders we don't use again should be removed from places like
  /// uriToSource (used in places for dependency tracking), the incremental
  /// serializer (they are no longer kept up-to-date) and the DillTarget
  /// (to avoid leaks).
  /// We also have to remove any component problems beloning to any such
  /// no-longer-used library (to avoid re-issuing errors about no longer
  /// relevant stuff).
  void _cleanupRemovedBuilders(
      ReusageResult reusedResult, UriTranslator uriTranslator) {
    bool removedDillBuilders = false;
    for (LibraryBuilder builder in reusedResult.notReusedLibraries) {
      _cleanupSourcesForBuilder(reusedResult, builder, uriTranslator,
          CompilerContext.current.uriToSource);
      _incrementalSerializer?.invalidate(builder.fileUri);

      LibraryBuilder? dillBuilder =
          _dillLoadedData!.loader.deregisterLibraryBuilder(builder.importUri);
      if (dillBuilder != null) {
        removedDillBuilders = true;
        _userBuilders?.remove(builder.importUri);
      }

      // Remove component problems for libraries we don't reuse.
      if (_remainingComponentProblems.isNotEmpty) {
        Library lib = builder.library;
        _removeLibraryFromRemainingComponentProblems(lib, uriTranslator);
      }
    }

    if (removedDillBuilders) {
      _makeDillLoaderLibrariesUpToDateWithBuildersMap();
    }
  }

  bool _importsFfi() {
    if (_userBuilders == null) return false;
    final Uri dartFfiUri = Uri.parse("dart:ffi");
    for (LibraryBuilder builder in _userBuilders!.values) {
      Library lib = builder.library;
      for (LibraryDependency dependency in lib.dependencies) {
        if (dependency.targetLibrary.importUri == dartFfiUri) {
          return true;
        }
      }
    }
    return false;
  }

  /// Figure out if we can (and was asked to) do experimental invalidation.
  /// Note that this returns (future or) [null] if we're not doing experimental
  /// invalidation.
  Future<ExperimentalInvalidation?> _initializeExperimentalInvalidation(
      ReusageResult reusedResult, CompilerContext c) async {
    Set<LibraryBuilder>? rebuildBodies;
    Set<LibraryBuilder> originalNotReusedLibraries;
    Set<Uri>? missingSources;

    if (!context.options.isExperimentEnabledGlobally(
        ExperimentalFlag.alternativeInvalidationStrategy)) return null;
    if (_modulesToLoad != null) return null;
    if (reusedResult.directlyInvalidated.isEmpty) return null;
    if (reusedResult.invalidatedBecauseOfPackageUpdate) return null;

    // Figure out if the file(s) have changed outline, or we can just
    // rebuild the bodies.
    for (LibraryBuilder builder in reusedResult.directlyInvalidated) {
      if (builder.library.problemsAsJson != null) {
        assert(builder.library.problemsAsJson!.isNotEmpty);
        return null;
      }
      Iterator<Builder> iterator = builder.iterator;
      while (iterator.moveNext()) {
        Builder childBuilder = iterator.current;
        if (childBuilder.isDuplicate) {
          return null;
        }
      }

      List<int>? previousSource =
          CompilerContext.current.uriToSource[builder.fileUri]!.source;
      // ignore: unnecessary_null_comparison
      if (previousSource == null || previousSource.isEmpty) {
        return null;
      }
      ScannerConfiguration scannerConfiguration = new ScannerConfiguration(
          enableExtensionMethods: true /* can't be disabled */,
          enableNonNullable: builder
              .isNonNullableByDefault /* depends on language version etc */,
          enableTripleShift:
              /* should this be on the library? */
              /* this is effectively what the constant evaluator does */
              context.options
                  .isExperimentEnabledGlobally(ExperimentalFlag.tripleShift));
      String? before = textualOutline(previousSource, scannerConfiguration,
          performModelling: true);
      if (before == null) {
        return null;
      }
      String? now;
      FileSystemEntity entity =
          c.options.fileSystem.entityForUri(builder.fileUri);
      if (await entity.exists()) {
        now = textualOutline(await entity.readAsBytes(), scannerConfiguration,
            performModelling: true);
      }
      if (before != now) {
        return null;
      }
      // TODO(jensj): We should only do this when we're sure we're going to
      // do it!
      CompilerContext.current.uriToSource.remove(builder.fileUri);
      missingSources ??= new Set<Uri>();
      missingSources.add(builder.fileUri);
      LibraryBuilder? partOfLibrary = builder.partOfLibrary;
      rebuildBodies ??= new Set<LibraryBuilder>();
      if (partOfLibrary != null) {
        rebuildBodies.add(partOfLibrary);
      } else {
        rebuildBodies.add(builder);
      }
    }

    // Special case mixins: Because the VM mixin transformation inlines
    // procedures, if the changed file is used as a mixin anywhere else
    // we can't only recompile the changed file.
    // TODO(jensj): Check for mixins in a smarter and faster way.
    for (LibraryBuilder builder in reusedResult.notReusedLibraries) {
      if (missingSources!.contains(builder.fileUri)) {
        continue;
      }
      Library lib = builder.library;
      for (Class c in lib.classes) {
        if (!c.isAnonymousMixin && !c.isEliminatedMixin) {
          continue;
        }
        for (Supertype supertype in c.implementedTypes) {
          if (missingSources.contains(supertype.classNode.fileUri)) {
            // This is probably a mixin from one of the libraries we want
            // to rebuild only the body of.
            // TODO(jensj): We can probably add this to the rebuildBodies
            // list and just rebuild that library too.
            // print("Usage of mixin in ${lib.importUri}");
            return null;
          }
        }
      }
    }

    // Special case FFI: Because the VM ffi transformation inlines
    // size and position, if the changed file contains ffi structs
    // we can't only recompile the changed file.
    // TODO(jensj): Come up with something smarter for this. E.g. we might
    // check if the FFI-classes are used in other libraries, or as actual nested
    // structures in other FFI-classes etc.
    // Alternatively (https://github.com/dart-lang/sdk/issues/45899) we might
    // do something else entirely that doesn't require special handling.
    if (_importsFfi()) {
      for (LibraryBuilder builder in rebuildBodies!) {
        Library lib = builder.library;
        for (LibraryDependency dependency in lib.dependencies) {
          Library importLibrary = dependency.targetLibrary;
          if (importLibrary.importUri == dartFfiUri) {
            // Explicitly imports dart:ffi.
            return null;
          }
          for (Reference exportReference in importLibrary.additionalExports) {
            NamedNode? export = exportReference.node;
            if (export is Class) {
              Class c = export;
              if (c.enclosingLibrary.importUri == dartFfiUri) {
                // Implicitly imports a dart:ffi class.
                return null;
              }
            }
          }
        }
      }
    }

    originalNotReusedLibraries = new Set<LibraryBuilder>();
    Set<Uri> seenUris = new Set<Uri>();
    for (LibraryBuilder builder in reusedResult.notReusedLibraries) {
      if (builder.isPart) continue;
      if (builder.isPatch) continue;
      if (rebuildBodies!.contains(builder)) continue;
      if (!seenUris.add(builder.importUri)) continue;
      reusedResult.reusedLibraries.add(builder);
      originalNotReusedLibraries.add(builder);
    }
    reusedResult.notReusedLibraries.clear();
    reusedResult.notReusedLibraries.addAll(rebuildBodies!);

    return new ExperimentalInvalidation(
        rebuildBodies, originalNotReusedLibraries, missingSources!);
  }

  /// Get UriTranslator, and figure out if the packages file was (potentially)
  /// changed.
  Future<UriTranslator> _setupPackagesAndUriTranslator(
      CompilerContext c) async {
    bool bypassCache = false;
    if (!identical(_previousPackagesUri, c.options.packagesUriRaw)) {
      _previousPackagesUri = c.options.packagesUriRaw;
      bypassCache = true;
    } else if (this._invalidatedUris.contains(c.options.packagesUri)) {
      bypassCache = true;
    }
    UriTranslator uriTranslator =
        await c.options.getUriTranslator(bypassCache: bypassCache);
    _previousPackagesMap = _currentPackagesMap;
    _currentPackagesMap = _createPackagesMap(uriTranslator.packages);
    // TODO(jensj): We can probably (from the maps above) figure out if anything
    // changed and only set this to true if it did.
    _hasToCheckPackageUris = _hasToCheckPackageUris || bypassCache;
    _ticker.logMs("Read packages file");
    if (_initializedForExpressionCompilationOnly) {
      _hasToCheckPackageUris = false;
    }
    return uriTranslator;
  }

  Map<String, Package> _createPackagesMap(PackageConfig packages) {
    Map<String, Package> result = new Map<String, Package>();
    for (Package package in packages.packages) {
      result[package.name] = package;
    }
    return result;
  }

  /// Load platform and (potentially) initialize from dill,
  /// or initialize from component.
  Future<IncrementalCompilerData> _ensurePlatformAndInitialize(
      UriTranslator uriTranslator, CompilerContext c) async {
    IncrementalCompilerData data = new IncrementalCompilerData();
    if (_dillLoadedData == null) {
      int bytesLength = 0;
      if (_componentToInitializeFrom != null) {
        // If initializing from a component it has to include the sdk,
        // so we explicitly don't load it here.
        _initializeFromComponent(uriTranslator, c, data);
        assert(_dillLoadedData != null);
        _componentToInitializeFrom = null;
      } else {
        List<int>? summaryBytes = await c.options.loadSdkSummaryBytes();
        bytesLength = _prepareSummary(summaryBytes, uriTranslator, c, data);
        assert(_dillLoadedData != null);
        if (_initializeFromDillUri != null) {
          try {
            bytesLength += await _initializeFromDill(uriTranslator, c, data);
          } catch (e, st) {
            // We might have loaded x out of y libraries into the component.
            // To avoid any unforeseen problems start over.
            bytesLength = _prepareSummary(summaryBytes, uriTranslator, c, data);

            if (e is InvalidKernelVersionError ||
                e is InvalidKernelSdkVersionError ||
                e is PackageChangedError ||
                e is CanonicalNameSdkError ||
                e is CompilationModeError) {
              // Don't report any warning.
            } else {
              Uri? gzInitializedFrom;
              if (c.options.writeFileOnCrashReport) {
                gzInitializedFrom = saveAsGzip(
                    data.initializationBytes!, "initialize_from.dill");
                recordTemporaryFileForTesting(gzInitializedFrom);
              }
              if (e is CanonicalNameError) {
                Message message = gzInitializedFrom != null
                    ? templateInitializeFromDillNotSelfContained.withArguments(
                        _initializeFromDillUri.toString(), gzInitializedFrom)
                    : templateInitializeFromDillNotSelfContainedNoDump
                        .withArguments(_initializeFromDillUri.toString());
                _dillLoadedData!.loader
                    .addProblem(message, TreeNode.noOffset, 1, null);
              } else {
                // Unknown error: Report problem as such.
                Message message = gzInitializedFrom != null
                    ? templateInitializeFromDillUnknownProblem.withArguments(
                        _initializeFromDillUri.toString(),
                        "$e",
                        "$st",
                        gzInitializedFrom)
                    : templateInitializeFromDillUnknownProblemNoDump
                        .withArguments(
                            _initializeFromDillUri.toString(), "$e", "$st");
                _dillLoadedData!.loader
                    .addProblem(message, TreeNode.noOffset, 1, null);
              }
            }
          }
        }
      }
      _appendLibraries(data, bytesLength);

      // We suppress finalization errors because they will reported via
      // problemsAsJson fields (with better precision).
      _dillLoadedData!.buildOutlines(suppressFinalizationErrors: true);
      _userBuilders = <Uri, LibraryBuilder>{};
      _platformBuilders = <LibraryBuilder>[];
      for (DillLibraryBuilder builder
          in _dillLoadedData!.loader.libraryBuilders) {
        if (builder.importUri.scheme == "dart") {
          _platformBuilders!.add(builder);
        } else {
          _userBuilders![builder.importUri] = builder;
        }
      }
      if (_userBuilders!.isEmpty) _userBuilders = null;
    }
    data.initializationBytes = null;
    return data;
  }

  void _replaceTypeBuilder(
      Map<LibraryBuilder, Map<String, Builder>> replacementMap,
      Map<LibraryBuilder, Map<String, Builder>> replacementSettersMap,
      TypeBuilder? typeBuilder) {
    TypeDeclarationBuilder? declaration = typeBuilder?.declaration;
    Builder? parent = declaration?.parent;
    if (parent == null) return;
    Map<String, Builder>? childReplacementMap;
    if (declaration!.isSetter) {
      childReplacementMap = replacementSettersMap[parent];
    } else {
      childReplacementMap = replacementMap[parent];
    }

    if (childReplacementMap == null) return;
    Builder replacement = childReplacementMap[declaration.name]!;
    // ignore: unnecessary_null_comparison
    assert(replacement != null, "Didn't find the replacement for $typeBuilder");
    typeBuilder!.bind(replacement as TypeDeclarationBuilder);
  }

  /// Allows for updating the list of needed libraries.
  ///
  /// Useful if a class hierarchy has been used externally.
  /// Currently there are two different class hierarchies which is unfortunate.
  /// For now this method allows the 'ClassHierarchyBuilder' to be null.
  ///
  /// TODO(jensj,CFE in general): Eventually we should get to a point where we
  /// only have one class hierarchy.
  /// TODO(jensj): This could probably be a utility method somewhere instead
  /// (though handling of the case where all bets are off should probably still
  /// live locally).
  void updateNeededDillLibrariesWithHierarchy(
      ClassHierarchy hierarchy, ClassHierarchyBuilder? builderHierarchy) {
    if (hierarchy is ClosedWorldClassHierarchy && !hierarchy.allBetsOff) {
      Set<Library> neededDillLibraries = _neededDillLibraries ??= {};
      Set<Class> classes = new Set<Class>();
      List<Class> worklist = <Class>[];
      // Get all classes touched by kernel class hierarchy.
      List<Class> usedClasses = hierarchy.getUsedClasses();
      worklist.addAll(usedClasses);
      classes.addAll(usedClasses);

      // Get all classes touched by fasta class hierarchy.
      if (builderHierarchy != null) {
        for (Class c in builderHierarchy.nodes.keys) {
          if (classes.add(c)) worklist.add(c);
        }
      }

      // Get all supers etc.
      while (worklist.isNotEmpty) {
        Class c = worklist.removeLast();
        for (Supertype supertype in c.implementedTypes) {
          if (classes.add(supertype.classNode)) {
            worklist.add(supertype.classNode);
          }
        }
        if (c.mixedInType != null) {
          if (classes.add(c.mixedInType!.classNode)) {
            worklist.add(c.mixedInType!.classNode);
          }
        }
        if (c.supertype != null) {
          if (classes.add(c.supertype!.classNode)) {
            worklist.add(c.supertype!.classNode);
          }
        }
      }

      // Add any libraries that was used or was in the "parent-chain" of a
      // used class.
      for (Class c in classes) {
        Library library = c.enclosingLibrary;
        // Only add if loaded from a dill file (and wasn't a 'dill' that was
        // converted from source builders to dill builders).
        if (_dillLoadedData!.loader.containsLibraryBuilder(library.importUri) &&
            (_previousSourceBuilders == null ||
                !_previousSourceBuilders!.contains(library))) {
          neededDillLibraries.add(library);
        }
      }
    } else {
      // Cannot track in other kernel class hierarchies or
      // if all bets are off: Add everything (except for the libraries we just
      // converted from source builders to dill builders).
      Set<Library> neededDillLibraries = _neededDillLibraries = {};
      for (DillLibraryBuilder builder
          in _dillLoadedData!.loader.libraryBuilders) {
        if (_previousSourceBuilders == null ||
            !_previousSourceBuilders!.contains(builder.library)) {
          neededDillLibraries.add(builder.library);
        }
      }
    }
  }

  /// Internal method.
  void _invalidateNotKeptUserBuilders(Set<Uri?> invalidatedUris) {
    if (_modulesToLoad != null && _userBuilders != null) {
      Set<Library> loadedNotKept = new Set<Library>();
      for (LibraryBuilder builder in _userBuilders!.values) {
        loadedNotKept.add(builder.library);
      }
      for (Component module in _modulesToLoad!) {
        loadedNotKept.removeAll(module.libraries);
      }
      for (Library lib in loadedNotKept) {
        invalidatedUris.add(lib.importUri);
      }
    }
  }

  /// Internal method.
  void _loadEnsureLoadedComponents(List<LibraryBuilder> reusedLibraries) {
    if (_modulesToLoad != null) {
      bool loadedAnything = false;
      for (Component module in _modulesToLoad!) {
        bool usedComponent = false;
        for (Library lib in module.libraries) {
          if (!_dillLoadedData!.loader.containsLibraryBuilder(lib.importUri)) {
            _dillLoadedData!.loader.libraries.add(lib);
            _dillLoadedData!.loader.registerKnownLibrary(lib);
            reusedLibraries
                .add(_dillLoadedData!.loader.read(lib.importUri, -1));
            usedComponent = true;
          }
        }
        if (usedComponent) {
          _dillLoadedData!.uriToSource.addAll(module.uriToSource);
          loadedAnything = true;
        }
      }
      if (loadedAnything) {
        // We suppress finalization errors because they will reported via
        // problemsAsJson fields (with better precision).
        _dillLoadedData!.buildOutlines(suppressFinalizationErrors: true);
        _userBuilders = <Uri, LibraryBuilder>{};
        _platformBuilders = <LibraryBuilder>[];
        for (DillLibraryBuilder builder
            in _dillLoadedData!.loader.libraryBuilders) {
          if (builder.importUri.scheme == "dart") {
            _platformBuilders!.add(builder);
          } else {
            _userBuilders![builder.importUri] = builder;
          }
        }
        if (_userBuilders!.isEmpty) {
          _userBuilders = null;
        }
      }
      _modulesToLoad = null;
    }
  }

  bool dontReissueLibraryProblemsFor(Uri? uri) {
    return uri == debugExprUri;
  }

  /// Internal method.
  void _reissueLibraryProblems(
      Set<Library> allLibraries, List<Library> compiledLibraries) {
    // The newly-compiled libraries have issued problems already. Re-issue
    // problems for the libraries that weren't re-compiled (ignore compile
    // expression problems)
    allLibraries.removeAll(compiledLibraries);
    for (Library library in allLibraries) {
      if (library.problemsAsJson?.isNotEmpty == true) {
        for (String jsonString in library.problemsAsJson!) {
          DiagnosticMessageFromJson message =
              new DiagnosticMessageFromJson.fromJson(jsonString);
          if (dontReissueLibraryProblemsFor(message.uri)) {
            continue;
          }
          context.options.reportDiagnosticMessage(message);
        }
      }
    }
  }

  /// Internal method.
  /// Re-issue problems on the component and return the filtered list.
  List<String> _reissueComponentProblems(Component componentWithDill) {
    // These problems have already been reported.
    Set<String> issuedProblems = new Set<String>();
    if (componentWithDill.problemsAsJson != null) {
      issuedProblems.addAll(componentWithDill.problemsAsJson!);
    }

    // Report old problems that wasn't reported again.
    Set<Uri>? strongModeNNBDPackageOptOutUris;
    for (MapEntry<Uri, List<DiagnosticMessageFromJson>> entry
        in _remainingComponentProblems.entries) {
      List<DiagnosticMessageFromJson> messages = entry.value;
      for (int i = 0; i < messages.length; i++) {
        DiagnosticMessageFromJson message = messages[i];
        if (message.codeName == "StrongModeNNBDPackageOptOut") {
          // Special case this: Don't issue them here; instead collect them
          // to get their uris and re-issue a new error.
          strongModeNNBDPackageOptOutUris ??= {};
          strongModeNNBDPackageOptOutUris.add(entry.key);
          continue;
        }
        if (issuedProblems.add(message.toJsonString())) {
          context.options.reportDiagnosticMessage(message);
        }
      }
    }
    if (strongModeNNBDPackageOptOutUris != null) {
      // Get the builders for these uris; then call
      // `SourceLoader.giveCombinedErrorForNonStrongLibraries` on them to issue
      // a new error.
      Set<LibraryBuilder> builders = {};
      SourceLoader loader = _userCode!.loader;
      for (LibraryBuilder builder in loader.libraryBuilders) {
        if (strongModeNNBDPackageOptOutUris.contains(builder.fileUri)) {
          builders.add(builder);
        }
      }
      FormattedMessage message = loader.giveCombinedErrorForNonStrongLibraries(
          builders,
          emitNonPackageErrors: false)!;
      issuedProblems.add(message.toJsonString());
      // The problem was issued by the call so don't re-issue it here.
    }

    // Save any new component-problems.
    _addProblemsAsJsonToRemainingProblems(componentWithDill.problemsAsJson);
    return new List<String>.from(issuedProblems);
  }

  /// Internal method.
  Uri? _getPartFileUri(
      Uri parentFileUri, LibraryPart part, UriTranslator uriTranslator) {
    Uri? fileUri = getPartUri(parentFileUri, part);
    if (fileUri.scheme == "package") {
      // Part was specified via package URI and the resolve above thus
      // did not go as expected. Translate the package URI to get the
      // actual file URI.
      fileUri = uriTranslator.translate(fileUri, false);
    }
    return fileUri;
  }

  /// Internal method.
  /// Compute the transitive closure.
  ///
  /// As a side-effect, this also cleans-up now-unreferenced builders as well as
  /// any saved component problems for such builders.
  List<Library> _computeTransitiveClosure(
      List<Library> inputLibraries,
      List<Uri> entryPoints,
      List<LibraryBuilder> reusedLibraries,
      ClassHierarchy hierarchy,
      UriTranslator uriTranslator,
      Map<Uri, Source> uriToSource,
      [List<Library>? inputLibrariesFiltered]) {
    List<Library> result = <Library>[];
    Map<Uri, Uri> partUriToLibraryImportUri = <Uri, Uri>{};
    Map<Uri, Library> libraryMap = <Uri, Library>{};
    Map<Uri, Library> potentiallyReferencedLibraries = <Uri, Library>{};
    Map<Uri, Library> potentiallyReferencedInputLibraries = <Uri, Library>{};
    for (Library library in inputLibraries) {
      libraryMap[library.importUri] = library;
      if (library.parts.isNotEmpty) {
        for (int partIndex = 0; partIndex < library.parts.length; partIndex++) {
          LibraryPart part = library.parts[partIndex];
          Uri partUri = getPartUri(library.importUri, part);
          partUriToLibraryImportUri[partUri] = library.importUri;
        }
      }
      if (library.importUri.scheme == "dart") {
        result.add(library);
        inputLibrariesFiltered?.add(library);
      } else {
        potentiallyReferencedLibraries[library.importUri] = library;
        potentiallyReferencedInputLibraries[library.importUri] = library;
      }
    }
    for (LibraryBuilder libraryBuilder in reusedLibraries) {
      if (libraryBuilder.importUri.scheme == "dart" &&
          !libraryBuilder.isSynthetic) {
        continue;
      }
      Library lib = libraryBuilder.library;
      potentiallyReferencedLibraries[libraryBuilder.importUri] = lib;
      libraryMap[libraryBuilder.importUri] = lib;
    }

    List<Uri> worklist = <Uri>[];
    for (Uri entry in entryPoints) {
      if (libraryMap.containsKey(entry)) {
        worklist.add(entry);
      } else {
        // If the entry is a part redirect to the "main" entry.
        Uri? partTranslation = partUriToLibraryImportUri[entry];
        if (partTranslation != null) {
          worklist.add(partTranslation);
        }
      }
    }

    LibraryGraph graph = new LibraryGraph(libraryMap);
    Set<Uri?> partsUsed = new Set<Uri?>();
    while (worklist.isNotEmpty && potentiallyReferencedLibraries.isNotEmpty) {
      Uri uri = worklist.removeLast();
      if (libraryMap.containsKey(uri)) {
        for (Uri neighbor in graph.neighborsOf(uri)) {
          worklist.add(neighbor);
        }
        libraryMap.remove(uri);
        Library? library = potentiallyReferencedLibraries.remove(uri);
        if (library != null) {
          result.add(library);
          if (potentiallyReferencedInputLibraries.remove(uri) != null) {
            inputLibrariesFiltered?.add(library);
          }
          for (LibraryPart part in library.parts) {
            Uri? partFileUri =
                _getPartFileUri(library.fileUri, part, uriTranslator);
            partsUsed.add(partFileUri);
          }
        }
      }
    }

    List<Library> removedLibraries = <Library>[];
    bool removedDillBuilders = false;
    for (Uri uri in potentiallyReferencedLibraries.keys) {
      if (uri.scheme == "package") continue;
      LibraryBuilder? builder = _userCode!.loader.deregisterLibraryBuilder(uri);
      if (builder != null) {
        Library lib = builder.library;
        removedLibraries.add(lib);
        if (_dillLoadedData!.loader.deregisterLibraryBuilder(uri) != null) {
          removedDillBuilders = true;
        }
        _cleanupSourcesForBuilder(null, builder, uriTranslator,
            CompilerContext.current.uriToSource, uriToSource, partsUsed);
        _userBuilders?.remove(uri);
        _removeLibraryFromRemainingComponentProblems(
            lib, uriTranslator, partsUsed);

        // Technically this isn't necessary as the uri is not a package-uri.
        _incrementalSerializer?.invalidate(builder.fileUri);
      }
    }
    hierarchy.applyTreeChanges(removedLibraries, const [], const []);
    if (removedDillBuilders) {
      _makeDillLoaderLibrariesUpToDateWithBuildersMap();
    }

    return result;
  }

  /// If builders was removed from the [dillLoadedData.loader.builders] map
  /// the loaders [libraries] list has to be updated too, or those libraries
  /// will still hang around and be linked into the Component created internally
  /// in the compilation process.
  /// This method syncs the [libraries] list with the data in [builders].
  void _makeDillLoaderLibrariesUpToDateWithBuildersMap() {
    _dillLoadedData!.loader.libraries.clear();
    for (LibraryBuilder builder in _dillLoadedData!.loader.libraryBuilders) {
      _dillLoadedData!.loader.libraries.add(builder.library);
    }
  }

  /// Internal method.
  ///
  /// [partsUsed] indicates part uris that are used by (other/alive) libraries.
  /// Those parts will not be cleaned up. This is useful when a part has been
  /// "moved" to be part of another library.
  void _cleanupSourcesForBuilder(
      ReusageResult? reusedResult,
      LibraryBuilder builder,
      UriTranslator uriTranslator,
      Map<Uri, Source> uriToSource,
      [Map<Uri, Source>? uriToSourceExtra,
      Set<Uri?>? partsUsed]) {
    uriToSource.remove(builder.fileUri);
    uriToSourceExtra?.remove(builder.fileUri);
    Library lib = builder.library;
    for (LibraryPart part in lib.parts) {
      Uri? partFileUri = _getPartFileUri(lib.fileUri, part, uriTranslator);
      if (partsUsed != null && partsUsed.contains(partFileUri)) continue;

      // If the builders map contain the "parts" import uri, it's a real library
      // (erroneously) used as a part so we don't want to remove that.
      if (_userCode?.loader != null) {
        Uri? partImportUri = uriToSource[partFileUri]?.importUri;
        if (partImportUri != null &&
            _userCode!.loader.containsLibraryBuilder(partImportUri)) {
          continue;
        }
      } else if (reusedResult != null) {
        // We've just launched and don't have userCode yet. Search reusedResult
        // for a kept library with this uri.
        bool found = false;
        for (int i = 0; i < reusedResult.reusedLibraries.length; i++) {
          LibraryBuilder reusedLibrary = reusedResult.reusedLibraries[i];
          if (reusedLibrary.fileUri == partFileUri) {
            found = true;
            break;
          }
        }
        if (found) {
          continue;
        }
      }
      uriToSource.remove(partFileUri);
      uriToSourceExtra?.remove(partFileUri);
    }
  }

  /// Internal method.
  ///
  /// [partsUsed] indicates part uris that are used by (other/alive) libraries.
  /// Those parts will not be removed from the component problems.
  /// This is useful when a part has been "moved" to be part of another library.
  void _removeLibraryFromRemainingComponentProblems(
      Library lib, UriTranslator uriTranslator,
      [Set<Uri?>? partsUsed]) {
    _remainingComponentProblems.remove(lib.fileUri);
    // Remove parts too.
    for (LibraryPart part in lib.parts) {
      Uri? partFileUri = _getPartFileUri(lib.fileUri, part, uriTranslator);
      _remainingComponentProblems.remove(partFileUri);
    }
  }

  /// Internal method.
  int _prepareSummary(List<int>? summaryBytes, UriTranslator uriTranslator,
      CompilerContext c, IncrementalCompilerData data) {
    _dillLoadedData = new DillTarget(_ticker, uriTranslator, c.options.target);
    int bytesLength = 0;

    data.component = c.options.target.configureComponent(new Component());
    if (summaryBytes != null) {
      _ticker.logMs("Read ${c.options.sdkSummary}");
      new BinaryBuilderWithMetadata(summaryBytes,
              disableLazyReading: false, disableLazyClassReading: true)
          .readComponent(data.component!);
      _ticker.logMs("Deserialized ${c.options.sdkSummary}");
      bytesLength += summaryBytes.length;
    }

    return bytesLength;
  }

  /// Internal method.
  // This procedure will try to load the dill file and will crash if it cannot.
  Future<int> _initializeFromDill(UriTranslator uriTranslator,
      CompilerContext c, IncrementalCompilerData data) async {
    int bytesLength = 0;
    FileSystemEntity entity =
        c.options.fileSystem.entityForUri(_initializeFromDillUri!);
    if (await entity.exists()) {
      List<int> initializationBytes = await entity.readAsBytes();
      // ignore: unnecessary_null_comparison
      if (initializationBytes != null && initializationBytes.isNotEmpty) {
        _ticker.logMs("Read $_initializeFromDillUri");
        data.initializationBytes = initializationBytes;

        // We're going to output all we read here so lazy loading it
        // doesn't make sense.
        List<SubComponentView> views = new BinaryBuilderWithMetadata(
                initializationBytes,
                disableLazyReading: true)
            .readComponent(data.component!,
                checkCanonicalNames: true, createView: true)!;

        // Compute "output nnbd mode".
        NonNullableByDefaultCompiledMode compiledMode;
        if (c.options
            .isExperimentEnabledGlobally(ExperimentalFlag.nonNullable)) {
          switch (c.options.nnbdMode) {
            case NnbdMode.Weak:
              compiledMode = NonNullableByDefaultCompiledMode.Weak;
              break;
            case NnbdMode.Strong:
              compiledMode = NonNullableByDefaultCompiledMode.Strong;
              break;
            case NnbdMode.Agnostic:
              compiledMode = NonNullableByDefaultCompiledMode.Agnostic;
              break;
          }
        } else {
          compiledMode = NonNullableByDefaultCompiledMode.Weak;
        }

        // Check the any package-urls still point to the same file
        // (e.g. the package still exists and hasn't been updated).
        // Also verify NNBD settings.
        for (Library lib in data.component!.libraries) {
          if (lib.importUri.scheme == "package" &&
              uriTranslator.translate(lib.importUri, false) != lib.fileUri) {
            // Package has been removed or updated.
            // This library should be thrown away.
            // Everything that depends on it should be thrown away.
            // TODO(jensj): Anything that doesn't depend on it can be kept.
            // For now just don't initialize from this dill.
            throw const PackageChangedError();
          }
          // Note: If a library has a NonNullableByDefaultCompiledMode.invalid
          // we will throw and we won't initialize from it.
          // That's wanted behavior.
          if (compiledMode !=
              mergeCompilationModeOrThrow(
                  compiledMode, lib.nonNullableByDefaultCompiledMode)) {
            throw new CompilationModeError(
                "Can't compile to $compiledMode with library with mode "
                "${lib.nonNullableByDefaultCompiledMode}.");
          }
        }

        // Only initialize the incremental serializer when we know we'll
        // actually use the data loaded from dill.
        _initializedIncrementalSerializer =
            _incrementalSerializer?.initialize(initializationBytes, views) ??
                false;

        _initializedFromDill = true;
        bytesLength += initializationBytes.length;
        _saveComponentProblems(data);
      }
    }
    return bytesLength;
  }

  /// Internal method.
  void _saveComponentProblems(IncrementalCompilerData data) {
    List<String>? problemsAsJson = data.component!.problemsAsJson;
    _addProblemsAsJsonToRemainingProblems(problemsAsJson);
  }

  void _addProblemsAsJsonToRemainingProblems(List<String>? problemsAsJson) {
    if (problemsAsJson != null) {
      for (String jsonString in problemsAsJson) {
        DiagnosticMessageFromJson message =
            new DiagnosticMessageFromJson.fromJson(jsonString);
        assert(message.uri != null ||
            (message.involvedFiles != null &&
                message.involvedFiles!.isNotEmpty));
        if (message.uri != null) {
          List<DiagnosticMessageFromJson> messages =
              _remainingComponentProblems[message.uri!] ??=
                  <DiagnosticMessageFromJson>[];
          messages.add(message);
        }
        if (message.involvedFiles != null) {
          // This indexes the same message under several uris - this way it will
          // be issued as long as it's a problem. It will because of
          // deduplication when we re-issue these (in reissueComponentProblems)
          // only be reported once.
          for (Uri uri in message.involvedFiles!) {
            List<DiagnosticMessageFromJson> messages =
                _remainingComponentProblems[uri] ??=
                    <DiagnosticMessageFromJson>[];
            messages.add(message);
          }
        }
      }
    }
  }

  /// Internal method.
  // This procedure will set up compiler from [componentToInitializeFrom].
  void _initializeFromComponent(UriTranslator uriTranslator, CompilerContext c,
      IncrementalCompilerData data) {
    _ticker.logMs("About to initializeFromComponent");

    _dillLoadedData = new DillTarget(_ticker, uriTranslator, c.options.target);
    data.component = new Component(
        libraries: _componentToInitializeFrom!.libraries,
        uriToSource: _componentToInitializeFrom!.uriToSource)
      ..setMainMethodAndMode(_componentToInitializeFrom!.mainMethod?.reference,
          true, _componentToInitializeFrom!.mode);
    _saveComponentProblems(data);

    bool foundDartCore = false;
    for (int i = 0; i < data.component!.libraries.length; i++) {
      Library library = data.component!.libraries[i];
      if (library.importUri.scheme == "dart" &&
          library.importUri.path == "core") {
        foundDartCore = true;
        break;
      }
    }

    if (!foundDartCore) {
      throw const InitializeFromComponentError("Did not find dart:core when "
          "tried to initialize from component.");
    }

    _ticker.logMs("Ran initializeFromComponent");
  }

  /// Internal method.
  void _appendLibraries(IncrementalCompilerData data, int bytesLength) {
    if (data.component != null) {
      _dillLoadedData!.loader
          .appendLibraries(data.component!, byteCount: bytesLength);
    }
    _ticker.logMs("Appended libraries");
  }

  @override
  Future<Procedure?> compileExpression(
      String expression,
      Map<String, DartType> definitions,
      List<TypeParameter> typeDefinitions,
      String syntheticProcedureName,
      Uri libraryUri,
      {String? className,
      String? methodName,
      bool isStatic = false}) async {
    assert(_dillLoadedData != null && _userCode != null);

    return await context.runInContext((_) async {
      LibraryBuilder libraryBuilder = _userCode!.loader
          .read(libraryUri, -1, accessor: _userCode!.loader.first);
      _ticker.logMs("Loaded library $libraryUri");

      Class? cls;
      if (className != null) {
        ClassBuilder? classBuilder =
            libraryBuilder.scopeBuilder[className] as ClassBuilder?;
        cls = classBuilder?.cls;
        if (cls == null) return null;
      }
      Extension? extension;
      String? extensionName;
      if (methodName != null) {
        int indexOfDot = methodName.indexOf(".");
        if (indexOfDot >= 0) {
          String beforeDot = methodName.substring(0, indexOfDot);
          String afterDot = methodName.substring(indexOfDot + 1);
          Builder? builder = libraryBuilder.scopeBuilder[beforeDot];
          extensionName = beforeDot;
          if (builder is ExtensionBuilder) {
            extension = builder.extension;
            Builder? subBuilder = builder.scopeBuilder[afterDot];
            if (subBuilder is MemberBuilder) {
              if (subBuilder.isExtensionInstanceMember) {
                isStatic = false;
              }
            }
          }
        }
      }

      _userCode!.loader.resetSeenMessages();

      for (TypeParameter typeParam in typeDefinitions) {
        if (!isLegalIdentifier(typeParam.name!)) {
          _userCode!.loader.addProblem(
              templateIncrementalCompilerIllegalTypeParameter
                  .withArguments('$typeParam'),
              typeParam.fileOffset,
              0,
              libraryUri);
          return null;
        }
      }
      int index = 0;
      for (String name in definitions.keys) {
        index++;
        if (!(isLegalIdentifier(name) ||
            (extension != null &&
                !isStatic &&
                index == 1 &&
                isExtensionThisName(name)))) {
          _userCode!.loader.addProblem(
              templateIncrementalCompilerIllegalParameter.withArguments(name),
              // TODO: pass variable declarations instead of
              // parameter names for proper location detection.
              // https://github.com/dart-lang/sdk/issues/44158
              -1,
              -1,
              libraryUri);
          return null;
        }
      }

      SourceLibraryBuilder debugLibrary = new SourceLibraryBuilder(
        libraryUri,
        debugExprUri,
        /*packageUri*/ null,
        new ImplicitLanguageVersion(libraryBuilder.library.languageVersion),
        _userCode!.loader,
        null,
        scope: libraryBuilder.scope.createNestedScope("expression"),
        nameOrigin: libraryBuilder,
      );
      _ticker.logMs("Created debug library");

      if (libraryBuilder is DillLibraryBuilder) {
        for (LibraryDependency dependency
            in libraryBuilder.library.dependencies) {
          if (!dependency.isImport) continue;

          List<CombinatorBuilder>? combinators;

          for (kernel.Combinator combinator in dependency.combinators) {
            combinators ??= <CombinatorBuilder>[];

            combinators.add(combinator.isShow
                ? new CombinatorBuilder.show(combinator.names,
                    combinator.fileOffset, libraryBuilder.fileUri)
                : new CombinatorBuilder.hide(combinator.names,
                    combinator.fileOffset, libraryBuilder.fileUri));
          }

          debugLibrary.addImport(
              null,
              dependency.importedLibraryReference.canonicalName!.name,
              null,
              dependency.name,
              combinators,
              dependency.isDeferred,
              -1,
              -1,
              -1,
              -1);
        }

        debugLibrary.addImportsToScope();
        _ticker.logMs("Added imports");
      }

      HybridFileSystem hfs = _userCode!.fileSystem as HybridFileSystem;
      MemoryFileSystem fs = hfs.memory;
      fs.entityForUri(debugExprUri).writeAsStringSync(expression);

      // TODO: pass variable declarations instead of
      // parameter names for proper location detection.
      // https://github.com/dart-lang/sdk/issues/44158
      FunctionNode parameters = new FunctionNode(null,
          typeParameters: typeDefinitions,
          positionalParameters: definitions.keys
              .map((name) =>
                  new VariableDeclarationImpl(name, 0, type: definitions[name])
                    ..fileOffset = cls?.fileOffset ??
                        extension?.fileOffset ??
                        libraryBuilder.library.fileOffset)
              .toList());

      VariableDeclaration? extensionThis;
      if (extension != null &&
          !isStatic &&
          parameters.positionalParameters.isNotEmpty) {
        // We expect the first parameter to be called #this and be special.
        if (isExtensionThisName(parameters.positionalParameters.first.name)) {
          extensionThis = parameters.positionalParameters.first;
          extensionThis.isLowered = true;
        }
      }

      debugLibrary.build(_userCode!.loader.coreLibrary, modifyTarget: false);
      Expression compiledExpression = await _userCode!.loader.buildExpression(
          debugLibrary,
          className ?? extensionName,
          (className != null && !isStatic) || extensionThis != null,
          parameters,
          extensionThis);

      Procedure procedure = new Procedure(
          new Name(syntheticProcedureName), ProcedureKind.Method, parameters,
          isStatic: isStatic, fileUri: debugLibrary.fileUri)
        ..isNonNullableByDefault = debugLibrary.isNonNullableByDefault;

      parameters.body = new ReturnStatement(compiledExpression)
        ..parent = parameters;

      procedure.fileUri = debugLibrary.fileUri;
      procedure.parent = cls ?? libraryBuilder.library;

      _userCode!.uriToSource.remove(debugExprUri);
      _userCode!.loader.sourceBytes.remove(debugExprUri);

      // Make sure the library has a canonical name.
      Component c = new Component(libraries: [debugLibrary.library]);
      c.computeCanonicalNames();
      _ticker.logMs("Built debug library");

      _userCode!.runProcedureTransformations(procedure);

      return procedure;
    });
  }

  bool _packagesEqual(Package? a, Package? b) {
    if (a == null || b == null) return false;
    if (a.name != b.name) return false;
    if (a.root != b.root) return false;
    if (a.packageUriRoot != b.packageUriRoot) return false;
    if (a.languageVersion != b.languageVersion) return false;
    if (a.extraData != b.extraData) return false;
    return true;
  }

  /// Internal method.
  ReusageResult _computeReusedLibraries(Set<Uri?> invalidatedUris,
      UriTranslator uriTranslator, List<Uri> entryPoints) {
    Set<Uri> seenUris = new Set<Uri>();
    List<LibraryBuilder> reusedLibraries = <LibraryBuilder>[];
    for (int i = 0; i < _platformBuilders!.length; i++) {
      LibraryBuilder builder = _platformBuilders![i];
      if (!seenUris.add(builder.importUri)) continue;
      reusedLibraries.add(builder);
    }
    if (_userCode == null && _userBuilders == null) {
      return new ReusageResult.reusedLibrariesOnly(reusedLibraries);
    }
    bool invalidatedBecauseOfPackageUpdate = false;
    Set<LibraryBuilder> directlyInvalidated = new Set<LibraryBuilder>();
    Set<LibraryBuilder> notReusedLibraries = new Set<LibraryBuilder>();

    // Maps all non-platform LibraryBuilders from their import URI.
    Map<Uri, LibraryBuilder> builders = <Uri, LibraryBuilder>{};
    Map<Uri?, LibraryBuilder> partUriToParent = <Uri?, LibraryBuilder>{};

    // Invalidated URIs translated back to their import URI (package:, dart:,
    // etc.).
    List<Uri> invalidatedImportUris = <Uri>[];

    bool isInvalidated(Uri importUri, Uri? fileUri) {
      if (invalidatedUris.contains(importUri)) return true;
      if (importUri != fileUri && invalidatedUris.contains(fileUri)) {
        return true;
      }
      if (_hasToCheckPackageUris && importUri.scheme == "package") {
        // Get package name, check if the base URI has changed for the package,
        // if it has, translate the URI again,
        // otherwise the URI cannot have changed.
        String path = importUri.path;
        int firstSlash = path.indexOf('/');
        String packageName = path.substring(0, firstSlash);
        if (_previousPackagesMap == null ||
            !_packagesEqual(_previousPackagesMap![packageName],
                _currentPackagesMap![packageName])) {
          Uri? newFileUri = uriTranslator.translate(importUri, false);
          if (newFileUri != fileUri) {
            invalidatedBecauseOfPackageUpdate = true;
            return true;
          }
        }
      }
      if (builders[importUri]?.isSynthetic ?? false) return true;
      return false;
    }

    void addBuilderAndInvalidateUris(Uri uri, LibraryBuilder libraryBuilder) {
      if (uri.scheme == "dart" && !libraryBuilder.isSynthetic) {
        if (seenUris.add(libraryBuilder.importUri)) {
          reusedLibraries.add(libraryBuilder);
        }
        return;
      }
      builders[uri] = libraryBuilder;
      if (isInvalidated(uri, libraryBuilder.library.fileUri)) {
        invalidatedImportUris.add(uri);
      }
      if (libraryBuilder is SourceLibraryBuilder) {
        // TODO(jensj): This shouldn't be possible anymore.
        for (LibraryBuilder part in libraryBuilder.parts) {
          partUriToParent[part.importUri] = libraryBuilder;
          partUriToParent[part.fileUri] = libraryBuilder;
          if (isInvalidated(part.importUri, part.fileUri)) {
            invalidatedImportUris.add(part.importUri);
            builders[part.importUri] = part;
          }
        }
      } else if (libraryBuilder is DillLibraryBuilder) {
        for (LibraryPart part in libraryBuilder.library.parts) {
          Uri partUri = getPartUri(libraryBuilder.importUri, part);
          Uri? fileUri = _getPartFileUri(
              libraryBuilder.library.fileUri, part, uriTranslator);
          partUriToParent[partUri] = libraryBuilder;
          partUriToParent[fileUri] = libraryBuilder;

          if (isInvalidated(partUri, fileUri)) {
            invalidatedImportUris.add(partUri);
            if (builders[partUri] == null) {
              // Only add if entry doesn't already exist.
              // For good cases it shouldn't exist, but if one library claims
              // another library is a part (when it's not) we don't want to
              // overwrite the real library builder.
              builders[partUri] = libraryBuilder;
            }
          }
        }
      }
    }

    if (_userCode != null) {
      // userCode already contains the builders from userBuilders.
      for (LibraryBuilder libraryBuilder in _userCode!.loader.libraryBuilders) {
        addBuilderAndInvalidateUris(libraryBuilder.importUri, libraryBuilder);
      }
    } else {
      // userCode was null so we explicitly have to add the builders from
      // userBuilders (which cannot be null as we checked initially that one of
      // them was non-null).
      _userBuilders!.forEach(addBuilderAndInvalidateUris);
    }

    recordInvalidatedImportUrisForTesting(invalidatedImportUris);
    for (Uri uri in invalidatedImportUris) {
      directlyInvalidated.add(builders[uri]!);
    }

    BuilderGraph graph = new BuilderGraph(builders);

    // Compute direct dependencies for each import URI (the reverse of the
    // edges returned by `graph.neighborsOf`).
    Map<Uri, Set<Uri>> directDependencies = <Uri, Set<Uri>>{};
    for (Uri vertex in graph.vertices) {
      for (Uri neighbor in graph.neighborsOf(vertex)) {
        (directDependencies[neighbor] ??= new Set<Uri>()).add(vertex);
      }
    }

    // Remove all dependencies of [invalidatedImportUris] from builders.
    List<Uri> workList = invalidatedImportUris;
    while (workList.isNotEmpty) {
      Uri removed = workList.removeLast();
      LibraryBuilder? current = builders.remove(removed);
      // [current] is null if the corresponding key (URI) has already been
      // removed.
      if (current != null) {
        Set<Uri>? s = directDependencies[current.importUri];
        if (current.importUri != removed) {
          if (s == null) {
            s = directDependencies[removed];
          } else {
            s.addAll(directDependencies[removed]!);
          }
        }
        if (s != null) {
          // [s] is null for leaves.
          for (Uri dependency in s) {
            workList.add(dependency);
          }
        }
        notReusedLibraries.add(current);
      }
    }

    // Builders contain mappings from part uri to builder, meaning the same
    // builder can exist multiple times in the values list.
    for (LibraryBuilder builder in builders.values) {
      if (builder.isPart) continue;
      // TODO(jensj/ahe): This line can probably go away once
      // https://dart-review.googlesource.com/47442 lands.
      if (builder.isPatch) continue;
      if (!seenUris.add(builder.importUri)) continue;
      reusedLibraries.add(builder);
    }

    ReusageResult result = new ReusageResult(
        notReusedLibraries,
        directlyInvalidated,
        invalidatedBecauseOfPackageUpdate,
        reusedLibraries);

    for (Uri entryPoint in entryPoints) {
      LibraryBuilder? parent = partUriToParent[entryPoint];
      if (parent == null) continue;
      // TODO(jensj): .contains on a list is O(n).
      // It will only be done for each entry point that's a part though, i.e.
      // most likely very rarely.
      if (reusedLibraries.contains(parent)) {
        result.registerLibraryUriForPartUsedAsEntryPoint(
            entryPoint, parent.importUri);
      }
    }

    return result;
  }

  @override
  void invalidate(Uri? uri) {
    _invalidatedUris.add(uri);
  }

  @override
  void invalidateAllSources() {
    if (_userCode != null) {
      Set<Uri> uris = new Set<Uri>.from(_userCode!.loader.libraryImportUris);
      uris.removeAll(_dillLoadedData!.loader.libraryImportUris);
      if (_previousSourceBuilders != null) {
        for (Library library in _previousSourceBuilders!) {
          uris.add(library.importUri);
        }
      }
      _invalidatedUris.addAll(uris);
    }
  }

  @override
  void setModulesToLoadOnNextComputeDelta(List<Component> components) {
    _modulesToLoad = components.toList();
  }

  /// Internal method.
  void recordNonFullComponentForTesting(Component component) {}

  /// Internal method.
  void recordInvalidatedImportUrisForTesting(List<Uri> uris) {}

  /// Internal method.
  void recordRebuildBodiesCountForTesting(int count) {}

  /// Internal method.
  void recordTemporaryFileForTesting(Uri uri) {}
}

/// Translate a parts "partUri" to an actual uri with handling of invalid uris.
///
/// ```
/// DartDocTest(
///   getPartUri(
///     Uri.parse("file://path/to/parent.dart"),
///     new LibraryPart([], "simple.dart")
///   ),
///   Uri.parse("file://path/to/simple.dart")
/// )
/// DartDocTest(
///   getPartUri(
///     Uri.parse("file://path/to/parent.dart"),
///     new LibraryPart([], "dir/simple.dart")
///   ),
///   Uri.parse("file://path/to/dir/simple.dart")
/// )
/// DartDocTest(
///   getPartUri(
///     Uri.parse("file://path/to/parent.dart"),
///     new LibraryPart([], "../simple.dart")
///   ),
///   Uri.parse("file://path/simple.dart")
/// )
/// DartDocTest(
///   getPartUri(
///     Uri.parse("file://path/to/parent.dart"),
///     new LibraryPart([], "file:///my/path/absolute.dart")
///   ),
///   Uri.parse("file:///my/path/absolute.dart")
/// )
/// DartDocTest(
///   getPartUri(
///     Uri.parse("file://path/to/parent.dart"),
///     new LibraryPart([], "package:foo/hello.dart")
///   ),
///   Uri.parse("package:foo/hello.dart")
/// )
/// ```
/// And with invalid part uri:
/// ```
/// DartDocTest(
///   getPartUri(
///     Uri.parse("file://path/to/parent.dart"),
///     new LibraryPart([], ":hello")
///   ),
///   new Uri(scheme: SourceLibraryBuilder.MALFORMED_URI_SCHEME,
///     query: Uri.encodeQueryComponent(":hello"))
/// )
/// ```
Uri getPartUri(Uri parentUri, LibraryPart part) {
  try {
    return parentUri.resolve(part.partUri);
  } on FormatException {
    // This is also done in [SourceLibraryBuilder.resolve]
    return new Uri(
        scheme: SourceLibraryBuilder.MALFORMED_URI_SCHEME,
        query: Uri.encodeQueryComponent(part.partUri));
  }
}

class PackageChangedError {
  const PackageChangedError();
}

class InitializeFromComponentError {
  final String message;

  const InitializeFromComponentError(this.message);

  @override
  String toString() => message;
}

class IncrementalCompilerData {
  Component? component = null;
  List<int>? initializationBytes = null;
}

class ReusageResult {
  final Set<LibraryBuilder> notReusedLibraries;
  final Set<LibraryBuilder> directlyInvalidated;
  final bool invalidatedBecauseOfPackageUpdate;
  final List<LibraryBuilder> reusedLibraries;
  final Map<Uri, Uri> _reusedLibrariesPartsToParentForEntryPoints;

  ReusageResult.reusedLibrariesOnly(this.reusedLibraries)
      : notReusedLibraries = const {},
        directlyInvalidated = const {},
        invalidatedBecauseOfPackageUpdate = false,
        _reusedLibrariesPartsToParentForEntryPoints = const {};

  ReusageResult(this.notReusedLibraries, this.directlyInvalidated,
      this.invalidatedBecauseOfPackageUpdate, this.reusedLibraries)
      : _reusedLibrariesPartsToParentForEntryPoints = {},
        // ignore: unnecessary_null_comparison
        assert(notReusedLibraries != null),
        // ignore: unnecessary_null_comparison
        assert(directlyInvalidated != null),
        // ignore: unnecessary_null_comparison
        assert(invalidatedBecauseOfPackageUpdate != null),
        // ignore: unnecessary_null_comparison
        assert(reusedLibraries != null);

  void registerLibraryUriForPartUsedAsEntryPoint(
      Uri entryPoint, Uri importUri) {
    _reusedLibrariesPartsToParentForEntryPoints[entryPoint] = importUri;
  }

  bool arePartsUsedAsEntryPoints() =>
      _reusedLibrariesPartsToParentForEntryPoints.isNotEmpty;

  Uri? getLibraryUriForPartUsedAsEntryPoint(Uri entryPoint) =>
      _reusedLibrariesPartsToParentForEntryPoints[entryPoint];
}

class ExperimentalInvalidation {
  final Set<LibraryBuilder> rebuildBodies;
  final Set<LibraryBuilder> originalNotReusedLibraries;
  final Set<Uri> missingSources;

  ExperimentalInvalidation(
      this.rebuildBodies, this.originalNotReusedLibraries, this.missingSources)
      // ignore: unnecessary_null_comparison
      : assert(rebuildBodies != null),
        // ignore: unnecessary_null_comparison
        assert(originalNotReusedLibraries != null),
        // ignore: unnecessary_null_comparison
        assert(missingSources != null);
}

class IncrementalKernelTarget extends KernelTarget
    implements ChangedStructureNotifier {
  Set<Class>? classHierarchyChanges;
  Set<Class>? classMemberChanges;
  Set<Library> librariesUsed = {};

  IncrementalKernelTarget(FileSystem fileSystem, bool includeComments,
      DillTarget dillTarget, UriTranslator uriTranslator)
      : super(fileSystem, includeComments, dillTarget, uriTranslator);

  @override
  ChangedStructureNotifier get changedStructureNotifier => this;

  @override
  void registerClassMemberChange(Class c) {
    classMemberChanges ??= new Set<Class>();
    classMemberChanges!.add(c);
  }

  @override
  void registerClassHierarchyChange(Class cls) {
    classHierarchyChanges ??= <Class>{};
    classHierarchyChanges!.add(cls);
  }

  @override
  void markLibrariesUsed(Set<Library> visitedLibraries) {
    librariesUsed.addAll(visitedLibraries);
  }
}
