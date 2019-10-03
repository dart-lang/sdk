// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.incremental_compiler;

import 'dart:async' show Future;

import 'package:front_end/src/fasta/dill/dill_class_builder.dart'
    show DillClassBuilder;

import 'package:kernel/binary/ast_from_binary.dart'
    show
        BinaryBuilderWithMetadata,
        CanonicalNameError,
        CanonicalNameSdkError,
        InvalidKernelVersionError;

import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClosedWorldClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/kernel.dart'
    show
        Class,
        Component,
        DartType,
        Expression,
        FunctionNode,
        Library,
        LibraryDependency,
        LibraryPart,
        Name,
        Procedure,
        ProcedureKind,
        ReturnStatement,
        Source,
        Supertype,
        TreeNode,
        TypeParameter;

import 'package:kernel/kernel.dart' as kernel show Combinator;

import '../api_prototype/file_system.dart' show FileSystemEntity;

import '../api_prototype/incremental_kernel_generator.dart'
    show IncrementalKernelGenerator, isLegalIdentifier;

import '../api_prototype/memory_file_system.dart' show MemoryFileSystem;

import 'builder/builder.dart' show Builder, ClassBuilder, LibraryBuilder;

import 'builder_graph.dart' show BuilderGraph;

import 'combinator.dart' show Combinator;

import 'compiler_context.dart' show CompilerContext;

import 'dill/dill_library_builder.dart' show DillLibraryBuilder;

import 'dill/dill_target.dart' show DillTarget;

import 'util/error_reporter_file_copier.dart' show saveAsGzip;

import 'fasta_codes.dart'
    show
        DiagnosticMessageFromJson,
        templateInitializeFromDillNotSelfContained,
        templateInitializeFromDillNotSelfContainedNoDump,
        templateInitializeFromDillUnknownProblem,
        templateInitializeFromDillUnknownProblemNoDump;

import 'hybrid_file_system.dart' show HybridFileSystem;

import 'kernel/kernel_builder.dart' show ClassHierarchyBuilder;

import 'kernel/kernel_shadow_ast.dart' show VariableDeclarationImpl;

import 'kernel/kernel_target.dart' show KernelTarget;

import 'library_graph.dart' show LibraryGraph;

import 'messages.dart' show Message;

import 'source/source_library_builder.dart' show SourceLibraryBuilder;

import 'ticker.dart' show Ticker;

import 'uri_translator.dart' show UriTranslator;

class IncrementalCompiler implements IncrementalKernelGenerator {
  final CompilerContext context;

  final Ticker ticker;

  final bool outlineOnly;
  bool trackNeededDillLibraries = false;
  Set<Library> neededDillLibraries;

  Set<Uri> invalidatedUris = new Set<Uri>();

  DillTarget dillLoadedData;
  List<LibraryBuilder> platformBuilders;
  Map<Uri, LibraryBuilder> userBuilders;
  final Uri initializeFromDillUri;
  final Component componentToInitializeFrom;
  bool initializedFromDill = false;
  Uri previousPackagesUri;
  Map<String, Uri> previousPackagesMap;
  Map<String, Uri> currentPackagesMap;
  bool hasToCheckPackageUris = false;
  Map<Uri, List<DiagnosticMessageFromJson>> remainingComponentProblems =
      new Map<Uri, List<DiagnosticMessageFromJson>>();
  List<Component> modulesToLoad;

  static final Uri debugExprUri =
      new Uri(scheme: "org-dartlang-debug", path: "synthetic_debug_expression");

  KernelTarget userCode;

  IncrementalCompiler.fromComponent(
      this.context, Component this.componentToInitializeFrom,
      [bool outlineOnly])
      : ticker = context.options.ticker,
        initializeFromDillUri = null,
        this.outlineOnly = outlineOnly ?? false;

  IncrementalCompiler(this.context,
      [this.initializeFromDillUri, bool outlineOnly])
      : ticker = context.options.ticker,
        componentToInitializeFrom = null,
        this.outlineOnly = outlineOnly ?? false;

  @override
  Future<Component> computeDelta(
      {List<Uri> entryPoints, bool fullComponent: false}) async {
    ticker.reset();
    entryPoints ??= context.options.inputs;
    return context.runInContext<Component>((CompilerContext c) async {
      IncrementalCompilerData data = new IncrementalCompilerData();

      bool bypassCache = false;
      if (!identical(previousPackagesUri, c.options.packagesUriRaw)) {
        previousPackagesUri = c.options.packagesUriRaw;
        bypassCache = true;
      } else if (this.invalidatedUris.contains(c.options.packagesUri)) {
        bypassCache = true;
      }
      hasToCheckPackageUris = hasToCheckPackageUris || bypassCache;
      UriTranslator uriTranslator =
          await c.options.getUriTranslator(bypassCache: bypassCache);
      previousPackagesMap = currentPackagesMap;
      currentPackagesMap = uriTranslator.packages.asMap();
      ticker.logMs("Read packages file");

      if (dillLoadedData == null) {
        int bytesLength = 0;
        if (componentToInitializeFrom != null) {
          // If initializing from a component it has to include the sdk,
          // so we explicitly don't load it here.
          initializeFromComponent(uriTranslator, c, data);
        } else {
          List<int> summaryBytes = await c.options.loadSdkSummaryBytes();
          bytesLength = prepareSummary(summaryBytes, uriTranslator, c, data);
          if (initializeFromDillUri != null) {
            try {
              bytesLength += await initializeFromDill(uriTranslator, c, data);
            } catch (e, st) {
              // We might have loaded x out of y libraries into the component.
              // To avoid any unforeseen problems start over.
              bytesLength =
                  prepareSummary(summaryBytes, uriTranslator, c, data);

              if (e is InvalidKernelVersionError ||
                  e is PackageChangedError ||
                  e is CanonicalNameSdkError) {
                // Don't report any warning.
              } else {
                Uri gzInitializedFrom;
                if (c.options.writeFileOnCrashReport) {
                  gzInitializedFrom = saveAsGzip(
                      data.initializationBytes, "initialize_from.dill");
                  recordTemporaryFileForTesting(gzInitializedFrom);
                }
                if (e is CanonicalNameError) {
                  Message message = gzInitializedFrom != null
                      ? templateInitializeFromDillNotSelfContained
                          .withArguments(initializeFromDillUri.toString(),
                              gzInitializedFrom)
                      : templateInitializeFromDillNotSelfContainedNoDump
                          .withArguments(initializeFromDillUri.toString());
                  dillLoadedData.loader
                      .addProblem(message, TreeNode.noOffset, 1, null);
                } else {
                  // Unknown error: Report problem as such.
                  Message message = gzInitializedFrom != null
                      ? templateInitializeFromDillUnknownProblem.withArguments(
                          initializeFromDillUri.toString(),
                          "$e",
                          "$st",
                          gzInitializedFrom)
                      : templateInitializeFromDillUnknownProblemNoDump
                          .withArguments(
                              initializeFromDillUri.toString(), "$e", "$st");
                  dillLoadedData.loader
                      .addProblem(message, TreeNode.noOffset, 1, null);
                }
              }
            }
          }
        }
        appendLibraries(data, bytesLength);

        await dillLoadedData.buildOutlines();
        userBuilders = <Uri, LibraryBuilder>{};
        platformBuilders = <LibraryBuilder>[];
        dillLoadedData.loader.builders.forEach((uri, builder) {
          if (builder.uri.scheme == "dart") {
            platformBuilders.add(builder);
          } else {
            userBuilders[uri] = builder;
          }
        });
        if (userBuilders.isEmpty) userBuilders = null;
      }
      data.initializationBytes = null;

      Set<Uri> invalidatedUris = this.invalidatedUris.toSet();

      invalidateNotKeptUserBuilders(invalidatedUris);

      ClassHierarchy hierarchy = userCode?.loader?.hierarchy;
      Set<LibraryBuilder> notReusedLibraries = new Set<LibraryBuilder>();
      List<LibraryBuilder> reusedLibraries = computeReusedLibraries(
          invalidatedUris, uriTranslator,
          notReused: notReusedLibraries);

      bool removedDillBuilders = false;
      for (LibraryBuilder builder in notReusedLibraries) {
        CompilerContext.current.uriToSource.remove(builder.fileUri);

        LibraryBuilder dillBuilder =
            dillLoadedData.loader.builders.remove(builder.uri);
        if (dillBuilder != null) {
          removedDillBuilders = true;
          userBuilders?.remove(builder.uri);
        }

        // Remove component problems for libraries we don't reuse.
        if (remainingComponentProblems.isNotEmpty) {
          Library lib = builder.library;
          removeLibraryFromRemainingComponentProblems(lib, uriTranslator);
        }
      }

      if (removedDillBuilders) {
        dillLoadedData.loader.libraries.clear();
        for (LibraryBuilder builder in dillLoadedData.loader.builders.values) {
          dillLoadedData.loader.libraries.add(builder.library);
        }
      }

      if (hasToCheckPackageUris) {
        // The package file was changed.
        // Make sure the dill loader is on the same page.
        DillTarget oldDillLoadedData = dillLoadedData;
        dillLoadedData =
            new DillTarget(ticker, uriTranslator, c.options.target);
        for (DillLibraryBuilder library
            in oldDillLoadedData.loader.builders.values) {
          library.loader = dillLoadedData.loader;
          dillLoadedData.loader.builders[library.uri] = library;
          if (library.uri.scheme == "dart" && library.uri.path == "core") {
            dillLoadedData.loader.coreLibrary = library;
          }
        }
        dillLoadedData.loader.first = oldDillLoadedData.loader.first;
        dillLoadedData.loader.libraries
            .addAll(oldDillLoadedData.loader.libraries);
      }

      if (hierarchy != null) {
        List<Library> removedLibraries = new List<Library>();
        for (LibraryBuilder builder in notReusedLibraries) {
          Library lib = builder.library;
          removedLibraries.add(lib);
        }
        hierarchy.applyTreeChanges(removedLibraries, const []);
      }
      notReusedLibraries = null;

      if (userCode != null) {
        ticker.logMs("Decided to reuse ${reusedLibraries.length}"
            " of ${userCode.loader.builders.length} libraries");
      }

      await loadEnsureLoadedComponents(reusedLibraries);

      KernelTarget userCodeOld = userCode;
      userCode = new KernelTarget(
          new HybridFileSystem(
              new MemoryFileSystem(
                  new Uri(scheme: "org-dartlang-debug", path: "/")),
              c.fileSystem),
          false,
          dillLoadedData,
          uriTranslator);
      userCode.loader.hierarchy = hierarchy;

      if (trackNeededDillLibraries) {
        // Reset dill loaders and kernel class hierarchy.
        for (LibraryBuilder builder in dillLoadedData.loader.builders.values) {
          if (builder is DillLibraryBuilder) {
            if (builder.isBuiltAndMarked) {
              // Clear cached calculations in classes which upon calculation can
              // mark things as needed.
              for (Builder builder in builder.scope.local.values) {
                if (builder is DillClassBuilder) {
                  builder.supertype = null;
                  builder.interfaces = null;
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

      for (LibraryBuilder library in reusedLibraries) {
        userCode.loader.builders[library.uri] = library;
        if (library.uri.scheme == "dart" && library.uri.path == "core") {
          userCode.loader.coreLibrary = library;
        }
      }

      entryPoints = userCode.setEntryPoints(entryPoints);
      if (userCode.loader.first == null &&
          userCode.loader.builders[entryPoints.first] != null) {
        userCode.loader.first = userCode.loader.builders[entryPoints.first];
      }
      Component componentWithDill = await userCode.buildOutlines();

      // This is not the full component. It is the component consisting of all
      // newly compiled libraries and all libraries loaded from .dill files or
      // directly from components.
      // Technically, it's the combination of userCode.loader.libraries and
      // dillLoadedData.loader.libraries.
      if (!outlineOnly) {
        componentWithDill =
            await userCode.buildComponent(verify: c.options.verify);
      }
      hierarchy ??= userCode.loader.hierarchy;

      recordNonFullComponentForTesting(componentWithDill);
      if (trackNeededDillLibraries) {
        // Which dill builders were built?
        neededDillLibraries = new Set<Library>();
        for (LibraryBuilder builder in dillLoadedData.loader.builders.values) {
          if (builder is DillLibraryBuilder) {
            if (builder.isBuiltAndMarked) {
              neededDillLibraries.add(builder.library);
            }
          }
        }

        updateNeededDillLibrariesWithHierarchy(
            hierarchy, userCode.loader.builderHierarchy);
      }

      if (componentWithDill != null) {
        this.invalidatedUris.clear();
        hasToCheckPackageUris = false;
        userCodeOld?.loader?.releaseAncillaryResources();
        userCodeOld?.loader?.builders?.clear();
        userCodeOld = null;
      }

      List<Library> compiledLibraries =
          new List<Library>.from(userCode.loader.libraries);
      Procedure mainMethod = componentWithDill == null
          ? data.userLoadedUriMain
          : componentWithDill.mainMethod;

      List<Library> outputLibraries;
      Set<Library> allLibraries;
      Map<Uri, Source> uriToSource = componentWithDill?.uriToSource;
      if (data.component != null || fullComponent) {
        outputLibraries = computeTransitiveClosure(
            compiledLibraries,
            entryPoints,
            reusedLibraries,
            hierarchy,
            uriTranslator,
            uriToSource);
        allLibraries = outputLibraries.toSet();
        if (!c.options.omitPlatform) {
          for (int i = 0; i < platformBuilders.length; i++) {
            Library lib = platformBuilders[i].library;
            outputLibraries.add(lib);
          }
        }
      } else {
        outputLibraries = new List<Library>();
        allLibraries = computeTransitiveClosure(
                compiledLibraries,
                entryPoints,
                reusedLibraries,
                hierarchy,
                uriTranslator,
                uriToSource,
                outputLibraries)
            .toSet();
      }

      List<String> problemsAsJson = reissueComponentProblems(componentWithDill);
      reissueLibraryProblems(allLibraries, compiledLibraries);

      if (componentWithDill == null) {
        userCode.loader.builders.clear();
        userCode = userCodeOld;
      }

      // This is the incremental component.
      return context.options.target.configureComponent(
          new Component(libraries: outputLibraries, uriToSource: uriToSource))
        ..mainMethod = mainMethod
        ..problemsAsJson = problemsAsJson;
    });
  }

  @override
  CoreTypes getCoreTypes() => userCode?.loader?.coreTypes;

  @override
  ClassHierarchy getClassHierarchy() => userCode?.loader?.hierarchy;

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
      ClassHierarchy hierarchy, ClassHierarchyBuilder builderHierarchy) {
    if (hierarchy is ClosedWorldClassHierarchy && !hierarchy.allBetsOff) {
      neededDillLibraries ??= new Set<Library>();
      Set<Class> classes = new Set<Class>();
      List<Class> worklist = new List<Class>();
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
          if (classes.add(c.mixedInType.classNode)) {
            worklist.add(c.mixedInType.classNode);
          }
        }
        if (c.supertype != null) {
          if (classes.add(c.supertype.classNode)) {
            worklist.add(c.supertype.classNode);
          }
        }
      }

      // Add any libraries that was used or was in the "parent-chain" of a
      // used class.
      for (Class c in classes) {
        Library library = c.enclosingLibrary;
        // Only add if loaded from a dill file.
        if (dillLoadedData.loader.builders.containsKey(library.importUri)) {
          neededDillLibraries.add(library);
        }
      }
    } else {
      // Cannot track in other kernel class hierarchies or
      // if all bets are off: Add everything.
      neededDillLibraries = new Set<Library>();
      for (LibraryBuilder builder in dillLoadedData.loader.builders.values) {
        if (builder is DillLibraryBuilder) {
          neededDillLibraries.add(builder.library);
        }
      }
    }
  }

  /// Internal method.
  void invalidateNotKeptUserBuilders(Set<Uri> invalidatedUris) {
    if (modulesToLoad != null && userBuilders != null) {
      Set<Library> loadedNotKept = new Set<Library>();
      for (LibraryBuilder builder in userBuilders.values) {
        loadedNotKept.add(builder.library);
      }
      for (Component module in modulesToLoad) {
        loadedNotKept.removeAll(module.libraries);
      }
      for (Library lib in loadedNotKept) {
        invalidatedUris.add(lib.importUri);
      }
    }
  }

  /// Internal method.
  Future<void> loadEnsureLoadedComponents(
      List<LibraryBuilder> reusedLibraries) async {
    if (modulesToLoad != null) {
      bool loadedAnything = false;
      for (Component module in modulesToLoad) {
        bool usedComponent = false;
        for (Library lib in module.libraries) {
          if (!dillLoadedData.loader.builders.containsKey(lib.importUri)) {
            dillLoadedData.loader.libraries.add(lib);
            dillLoadedData.addLibrary(lib);
            reusedLibraries.add(dillLoadedData.loader.read(lib.importUri, -1));
            usedComponent = true;
          }
        }
        if (usedComponent) {
          dillLoadedData.uriToSource.addAll(module.uriToSource);
          loadedAnything = true;
        }
      }
      if (loadedAnything) {
        await dillLoadedData.buildOutlines();
        userBuilders = <Uri, LibraryBuilder>{};
        platformBuilders = <LibraryBuilder>[];
        dillLoadedData.loader.builders.forEach((uri, builder) {
          if (builder.uri.scheme == "dart") {
            platformBuilders.add(builder);
          } else {
            userBuilders[uri] = builder;
          }
        });
        if (userBuilders.isEmpty) {
          userBuilders = null;
        }
      }
      modulesToLoad = null;
    }
  }

  /// Internal method.
  void reissueLibraryProblems(
      Set<Library> allLibraries, List<Library> compiledLibraries) {
    // The newly-compiled libraries have issued problems already. Re-issue
    // problems for the libraries that weren't re-compiled (ignore compile
    // expression problems)
    allLibraries.removeAll(compiledLibraries);
    for (Library library in allLibraries) {
      if (library.problemsAsJson?.isNotEmpty == true) {
        for (String jsonString in library.problemsAsJson) {
          DiagnosticMessageFromJson message =
              new DiagnosticMessageFromJson.fromJson(jsonString);
          if (message.uri == debugExprUri) {
            continue;
          }
          context.options.reportDiagnosticMessage(message);
        }
      }
    }
  }

  /// Internal method.
  /// Re-issue problems on the component and return the filtered list.
  List<String> reissueComponentProblems(Component componentWithDill) {
    // These problems have already been reported.
    Set<String> issuedProblems = new Set<String>();
    if (componentWithDill?.problemsAsJson != null) {
      issuedProblems.addAll(componentWithDill.problemsAsJson);
    }

    // Report old problems that wasn't reported again.
    for (List<DiagnosticMessageFromJson> messages
        in remainingComponentProblems.values) {
      for (int i = 0; i < messages.length; i++) {
        DiagnosticMessageFromJson message = messages[i];
        if (issuedProblems.add(message.toJsonString())) {
          context.options.reportDiagnosticMessage(message);
        }
      }
    }

    // Save any new component-problems.
    if (componentWithDill?.problemsAsJson != null) {
      for (String jsonString in componentWithDill.problemsAsJson) {
        DiagnosticMessageFromJson message =
            new DiagnosticMessageFromJson.fromJson(jsonString);
        List<DiagnosticMessageFromJson> messages =
            remainingComponentProblems[message.uri] ??=
                new List<DiagnosticMessageFromJson>();
        messages.add(message);
      }
    }
    return new List<String>.from(issuedProblems);
  }

  /// Internal method.
  Uri getPartFileUri(
      Uri parentFileUri, LibraryPart part, UriTranslator uriTranslator) {
    Uri fileUri = parentFileUri.resolve(part.partUri);
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
  List<Library> computeTransitiveClosure(
      List<Library> inputLibraries,
      List<Uri> entries,
      List<LibraryBuilder> reusedLibraries,
      ClassHierarchy hierarchy,
      UriTranslator uriTranslator,
      Map<Uri, Source> uriToSource,
      [List<Library> inputLibrariesFiltered]) {
    List<Library> result = new List<Library>();
    Map<Uri, Library> libraryMap = <Uri, Library>{};
    Map<Uri, Library> potentiallyReferencedLibraries = <Uri, Library>{};
    Map<Uri, Library> potentiallyReferencedInputLibraries = <Uri, Library>{};
    for (Library library in inputLibraries) {
      libraryMap[library.importUri] = library;
      if (library.importUri.scheme == "dart") {
        result.add(library);
        inputLibrariesFiltered?.add(library);
      } else {
        potentiallyReferencedLibraries[library.importUri] = library;
        potentiallyReferencedInputLibraries[library.importUri] = library;
      }
    }

    List<Uri> worklist = new List<Uri>();
    worklist.addAll(entries);
    for (LibraryBuilder libraryBuilder in reusedLibraries) {
      if (libraryBuilder.uri.scheme == "dart" && !libraryBuilder.isSynthetic) {
        continue;
      }
      Library lib = libraryBuilder.library;
      potentiallyReferencedLibraries[libraryBuilder.uri] = lib;
      libraryMap[libraryBuilder.uri] = lib;
    }

    LibraryGraph graph = new LibraryGraph(libraryMap);
    while (worklist.isNotEmpty && potentiallyReferencedLibraries.isNotEmpty) {
      Uri uri = worklist.removeLast();
      if (libraryMap.containsKey(uri)) {
        for (Uri neighbor in graph.neighborsOf(uri)) {
          worklist.add(neighbor);
        }
        libraryMap.remove(uri);
        Library library = potentiallyReferencedLibraries.remove(uri);
        if (library != null) {
          result.add(library);
          if (potentiallyReferencedInputLibraries.remove(uri) != null) {
            inputLibrariesFiltered?.add(library);
          }
        }
      }
    }

    List<Library> removedLibraries = new List<Library>();
    for (Uri uri in potentiallyReferencedLibraries.keys) {
      if (uri.scheme == "package") continue;
      LibraryBuilder builder = userCode.loader.builders.remove(uri);
      if (builder != null) {
        Library lib = builder.library;
        removedLibraries.add(lib);
        dillLoadedData.loader.builders.remove(uri);
        CompilerContext.current.uriToSource.remove(uri);
        uriToSource.remove(uri);
        userBuilders?.remove(uri);
        removeLibraryFromRemainingComponentProblems(lib, uriTranslator);
      }
    }
    hierarchy?.applyTreeChanges(removedLibraries, const []);

    return result;
  }

  /// Internal method.
  void removeLibraryFromRemainingComponentProblems(
      Library lib, UriTranslator uriTranslator) {
    remainingComponentProblems.remove(lib.fileUri);
    // Remove parts too.
    for (LibraryPart part in lib.parts) {
      Uri partFileUri = getPartFileUri(lib.fileUri, part, uriTranslator);
      remainingComponentProblems.remove(partFileUri);
    }
  }

  /// Internal method.
  int prepareSummary(List<int> summaryBytes, UriTranslator uriTranslator,
      CompilerContext c, IncrementalCompilerData data) {
    dillLoadedData = new DillTarget(ticker, uriTranslator, c.options.target);
    int bytesLength = 0;

    if (summaryBytes != null) {
      ticker.logMs("Read ${c.options.sdkSummary}");
      data.component = c.options.target.configureComponent(new Component());
      new BinaryBuilderWithMetadata(summaryBytes,
              disableLazyReading: false, disableLazyClassReading: true)
          .readComponent(data.component);
      ticker.logMs("Deserialized ${c.options.sdkSummary}");
      bytesLength += summaryBytes.length;
    }

    return bytesLength;
  }

  /// Internal method.
  // This procedure will try to load the dill file and will crash if it cannot.
  Future<int> initializeFromDill(UriTranslator uriTranslator, CompilerContext c,
      IncrementalCompilerData data) async {
    int bytesLength = 0;
    FileSystemEntity entity =
        c.options.fileSystem.entityForUri(initializeFromDillUri);
    if (await entity.exists()) {
      List<int> initializationBytes = await entity.readAsBytes();
      if (initializationBytes != null && initializationBytes.isNotEmpty) {
        ticker.logMs("Read $initializeFromDillUri");
        data.initializationBytes = initializationBytes;

        // We're going to output all we read here so lazy loading it
        // doesn't make sense.
        new BinaryBuilderWithMetadata(initializationBytes,
                disableLazyReading: true)
            .readComponent(data.component, checkCanonicalNames: true);

        // Check the any package-urls still point to the same file
        // (e.g. the package still exists and hasn't been updated).
        for (Library lib in data.component.libraries) {
          if (lib.importUri.scheme == "package" &&
              uriTranslator.translate(lib.importUri, false) != lib.fileUri) {
            // Package has been removed or updated.
            // This library should be thrown away.
            // Everything that depends on it should be thrown away.
            // TODO(jensj): Anything that doesn't depend on it can be kept.
            // For now just don't initialize from this dill.
            throw const PackageChangedError();
          }
        }

        initializedFromDill = true;
        bytesLength += initializationBytes.length;
        data.userLoadedUriMain = data.component.mainMethod;
        saveComponentProblems(data);
      }
    }
    return bytesLength;
  }

  /// Internal method.
  void saveComponentProblems(IncrementalCompilerData data) {
    if (data.component.problemsAsJson != null) {
      for (String jsonString in data.component.problemsAsJson) {
        DiagnosticMessageFromJson message =
            new DiagnosticMessageFromJson.fromJson(jsonString);
        List<DiagnosticMessageFromJson> messages =
            remainingComponentProblems[message.uri] ??=
                new List<DiagnosticMessageFromJson>();
        messages.add(message);
      }
    }
  }

  /// Internal method.
  // This procedure will set up compiler from [componentToInitializeFrom].
  void initializeFromComponent(UriTranslator uriTranslator, CompilerContext c,
      IncrementalCompilerData data) {
    ticker.logMs("About to initializeFromComponent");

    dillLoadedData = new DillTarget(ticker, uriTranslator, c.options.target);
    data.component = new Component(
        libraries: componentToInitializeFrom.libraries,
        uriToSource: componentToInitializeFrom.uriToSource)
      ..mainMethod = componentToInitializeFrom.mainMethod;
    data.userLoadedUriMain = componentToInitializeFrom.mainMethod;
    saveComponentProblems(data);

    bool foundDartCore = false;
    for (int i = 0; i < data.component.libraries.length; i++) {
      Library library = data.component.libraries[i];
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

    ticker.logMs("Ran initializeFromComponent");
  }

  /// Internal method.
  void appendLibraries(IncrementalCompilerData data, int bytesLength) {
    if (data.component != null) {
      dillLoadedData.loader
          .appendLibraries(data.component, byteCount: bytesLength);
    }
    ticker.logMs("Appended libraries");
  }

  @override
  Future<Procedure> compileExpression(
      String expression,
      Map<String, DartType> definitions,
      List<TypeParameter> typeDefinitions,
      String syntheticProcedureName,
      Uri libraryUri,
      [String className,
      bool isStatic = false]) async {
    assert(dillLoadedData != null && userCode != null);

    return await context.runInContext((_) async {
      LibraryBuilder libraryBuilder =
          userCode.loader.read(libraryUri, -1, accessor: userCode.loader.first);

      Class cls;
      if (className != null) {
        ClassBuilder classBuilder = libraryBuilder.scopeBuilder[className];
        cls = classBuilder?.cls;
        if (cls == null) return null;
      }

      userCode.loader.seenMessages.clear();

      for (TypeParameter typeParam in typeDefinitions) {
        if (!isLegalIdentifier(typeParam.name)) return null;
      }
      for (String name in definitions.keys) {
        if (!isLegalIdentifier(name)) return null;
      }

      SourceLibraryBuilder debugLibrary = new SourceLibraryBuilder(
        libraryUri,
        debugExprUri,
        userCode.loader,
        null,
        scope: libraryBuilder.scope.createNestedScope("expression"),
        nameOrigin: libraryBuilder.library,
      );
      debugLibrary.setLanguageVersion(
          libraryBuilder.library.languageVersionMajor,
          libraryBuilder.library.languageVersionMinor);

      if (libraryBuilder is DillLibraryBuilder) {
        for (LibraryDependency dependency
            in libraryBuilder.library.dependencies) {
          if (!dependency.isImport) continue;

          List<Combinator> combinators;

          for (kernel.Combinator combinator in dependency.combinators) {
            combinators ??= <Combinator>[];

            combinators.add(combinator.isShow
                ? new Combinator.show(combinator.names, combinator.fileOffset,
                    libraryBuilder.fileUri)
                : new Combinator.hide(combinator.names, combinator.fileOffset,
                    libraryBuilder.fileUri));
          }

          debugLibrary.addImport(
              null,
              dependency.importedLibraryReference.canonicalName.name,
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
      }

      HybridFileSystem hfs = userCode.fileSystem;
      MemoryFileSystem fs = hfs.memory;
      fs.entityForUri(debugExprUri).writeAsStringSync(expression);

      FunctionNode parameters = new FunctionNode(null,
          typeParameters: typeDefinitions,
          positionalParameters: definitions.keys
              .map((name) => new VariableDeclarationImpl(name, 0))
              .toList());

      debugLibrary.build(userCode.loader.coreLibrary, modifyTarget: false);
      Expression compiledExpression = await userCode.loader.buildExpression(
          debugLibrary, className, className != null && !isStatic, parameters);

      Procedure procedure = new Procedure(
          new Name(syntheticProcedureName), ProcedureKind.Method, parameters,
          isStatic: isStatic);

      parameters.body = new ReturnStatement(compiledExpression)
        ..parent = parameters;

      procedure.fileUri = debugLibrary.fileUri;
      procedure.parent = className != null ? cls : libraryBuilder.library;

      userCode.uriToSource.remove(debugExprUri);
      userCode.loader.sourceBytes.remove(debugExprUri);

      // Make sure the library has a canonical name.
      Component c = new Component(libraries: [debugLibrary.library]);
      c.computeCanonicalNames();

      userCode.runProcedureTransformations(procedure);

      return procedure;
    });
  }

  /// Internal method.
  List<LibraryBuilder> computeReusedLibraries(
      Set<Uri> invalidatedUris, UriTranslator uriTranslator,
      {Set<LibraryBuilder> notReused}) {
    List<LibraryBuilder> result = <LibraryBuilder>[];
    result.addAll(platformBuilders);
    if (userCode == null && userBuilders == null) {
      return result;
    }

    // Maps all non-platform LibraryBuilders from their import URI.
    Map<Uri, LibraryBuilder> builders = <Uri, LibraryBuilder>{};

    // Invalidated URIs translated back to their import URI (package:, dart:,
    // etc.).
    List<Uri> invalidatedImportUris = <Uri>[];

    bool isInvalidated(Uri importUri, Uri fileUri) {
      if (invalidatedUris.contains(importUri)) return true;
      if (importUri != fileUri && invalidatedUris.contains(fileUri)) {
        return true;
      }
      if (hasToCheckPackageUris && importUri.scheme == "package") {
        // Get package name, check if the base URI has changed for the package,
        // if it has, translate the URI again,
        // otherwise the URI cannot have changed.
        String path = importUri.path;
        int firstSlash = path.indexOf('/');
        String packageName = path.substring(0, firstSlash);
        if (previousPackagesMap == null ||
            (previousPackagesMap[packageName] !=
                currentPackagesMap[packageName])) {
          Uri newFileUri = uriTranslator.translate(importUri, false);
          if (newFileUri != fileUri) {
            return true;
          }
        }
      }
      if (builders[importUri]?.isSynthetic ?? false) return true;
      return false;
    }

    addBuilderAndInvalidateUris(Uri uri, LibraryBuilder libraryBuilder) {
      if (uri.scheme == "dart" && !libraryBuilder.isSynthetic) {
        result.add(libraryBuilder);
        return;
      }
      builders[uri] = libraryBuilder;
      if (isInvalidated(uri, libraryBuilder.library.fileUri)) {
        invalidatedImportUris.add(uri);
      }
      if (libraryBuilder is SourceLibraryBuilder) {
        for (LibraryBuilder part in libraryBuilder.parts) {
          if (isInvalidated(part.uri, part.fileUri)) {
            invalidatedImportUris.add(part.uri);
            builders[part.uri] = part;
          }
        }
      } else if (libraryBuilder is DillLibraryBuilder) {
        for (LibraryPart part in libraryBuilder.library.parts) {
          Uri partUri = libraryBuilder.uri.resolve(part.partUri);
          Uri fileUri = getPartFileUri(
              libraryBuilder.library.fileUri, part, uriTranslator);

          if (isInvalidated(partUri, fileUri)) {
            invalidatedImportUris.add(partUri);
            builders[partUri] = libraryBuilder;
          }
        }
      }
    }

    if (userCode != null) {
      // userCode already contains the builders from userBuilders.
      userCode.loader.builders.forEach(addBuilderAndInvalidateUris);
    } else {
      // userCode was null so we explicitly have to add the builders from
      // userBuilders (which cannot be null as we checked initially that one of
      // them was non-null).
      userBuilders.forEach(addBuilderAndInvalidateUris);
    }

    recordInvalidatedImportUrisForTesting(invalidatedImportUris);

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
      LibraryBuilder current = builders.remove(removed);
      // [current] is null if the corresponding key (URI) has already been
      // removed.
      if (current != null) {
        Set<Uri> s = directDependencies[current.uri];
        if (current.uri != removed) {
          if (s == null) {
            s = directDependencies[removed];
          } else {
            s.addAll(directDependencies[removed]);
          }
        }
        if (s != null) {
          // [s] is null for leaves.
          for (Uri dependency in s) {
            workList.add(dependency);
          }
        }
        notReused?.add(current);
      }
    }

    // Builders contain mappings from part uri to builder, meaning the same
    // builder can exist multiple times in the values list.
    Set<Uri> seenUris = new Set<Uri>();
    for (LibraryBuilder builder in builders.values) {
      if (builder.isPart) continue;
      // TODO(jensj/ahe): This line can probably go away once
      // https://dart-review.googlesource.com/47442 lands.
      if (builder.isPatch) continue;
      if (!seenUris.add(builder.uri)) continue;
      result.add(builder);
    }
    return result;
  }

  @override
  void invalidate(Uri uri) {
    invalidatedUris.add(uri);
  }

  @override
  void invalidateAllSources() {
    if (userCode != null) {
      Set<Uri> uris = new Set<Uri>.from(userCode.loader.builders.keys);
      uris.removeAll(dillLoadedData.loader.builders.keys);
      invalidatedUris.addAll(uris);
    }
  }

  @override
  void setModulesToLoadOnNextComputeDelta(List<Component> components) {
    modulesToLoad = components.toList();
  }

  /// Internal method.
  void recordNonFullComponentForTesting(Component component) {}

  /// Internal method.
  void recordInvalidatedImportUrisForTesting(List<Uri> uris) {}

  /// Internal method.
  void recordTemporaryFileForTesting(Uri uri) {}
}

class PackageChangedError {
  const PackageChangedError();
}

class InitializeFromComponentError {
  final String message;

  const InitializeFromComponentError(this.message);

  String toString() => message;
}

class IncrementalCompilerData {
  Procedure userLoadedUriMain = null;
  Component component = null;
  List<int> initializationBytes = null;
}
