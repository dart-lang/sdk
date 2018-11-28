// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.incremental_compiler;

import 'dart:async' show Future;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:kernel/binary/ast_from_binary.dart'
    show BinaryBuilder, CanonicalNameError, InvalidKernelVersionError;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

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
        TreeNode,
        TypeParameter;

import 'package:kernel/kernel.dart' as kernel show Combinator;

import '../api_prototype/file_system.dart' show FileSystemEntity;

import '../api_prototype/incremental_kernel_generator.dart'
    show IncrementalKernelGenerator, isLegalIdentifier;

import '../api_prototype/memory_file_system.dart' show MemoryFileSystem;

import 'builder/builder.dart' show LibraryBuilder;

import 'builder_graph.dart' show BuilderGraph;

import 'combinator.dart' show Combinator;

import 'compiler_context.dart' show CompilerContext;

import 'dill/dill_library_builder.dart' show DillLibraryBuilder;

import 'dill/dill_target.dart' show DillTarget;

import 'fasta_codes.dart'
    show
        templateInitializeFromDillNotSelfContained,
        templateInitializeFromDillUnknownProblem;

import 'hybrid_file_system.dart' show HybridFileSystem;

import 'kernel/kernel_library_builder.dart' show KernelLibraryBuilder;

import 'kernel/kernel_shadow_ast.dart' show VariableDeclarationJudgment;

import 'kernel/kernel_target.dart' show KernelTarget;

import 'library_graph.dart' show LibraryGraph;

import 'source/source_library_builder.dart' show SourceLibraryBuilder;

import 'ticker.dart' show Ticker;

import 'uri_translator.dart' show UriTranslator;

class IncrementalCompiler implements IncrementalKernelGenerator {
  final CompilerContext context;

  final Ticker ticker;

  Set<Uri> invalidatedUris = new Set<Uri>();

  DillTarget dillLoadedData;
  List<LibraryBuilder> platformBuilders;
  Map<Uri, LibraryBuilder> userBuilders;
  final Uri initializeFromDillUri;
  Component componentToInitializeFrom;
  bool initializedFromDill = false;
  bool hasToCheckPackageUris = false;

  KernelTarget userCode;

  IncrementalCompiler.fromComponent(
      this.context, Component this.componentToInitializeFrom)
      : ticker = context.options.ticker,
        initializeFromDillUri = null;

  IncrementalCompiler(this.context, [this.initializeFromDillUri])
      : ticker = context.options.ticker,
        componentToInitializeFrom = null;

  @override
  Future<Component> computeDelta(
      {Uri entryPoint, bool fullComponent: false}) async {
    ticker.reset();
    entryPoint ??= context.options.inputs.single;
    return context.runInContext<Component>((CompilerContext c) async {
      IncrementalCompilerData data = new IncrementalCompilerData();

      bool bypassCache = false;
      if (this.invalidatedUris.contains(c.options.packagesUri)) {
        bypassCache = true;
      }
      hasToCheckPackageUris = hasToCheckPackageUris || bypassCache;
      UriTranslator uriTranslator =
          await c.options.getUriTranslator(bypassCache: bypassCache);
      ticker.logMs("Read packages file");

      if (dillLoadedData == null) {
        List<int> summaryBytes = await c.options.loadSdkSummaryBytes();
        int bytesLength = prepareSummary(summaryBytes, uriTranslator, c, data);
        if (initializeFromDillUri != null) {
          try {
            bytesLength +=
                await initializeFromDill(summaryBytes, uriTranslator, c, data);
          } catch (e) {
            // We might have loaded x out of y libraries into the component.
            // To avoid any unforeseen problems start over.
            bytesLength = prepareSummary(summaryBytes, uriTranslator, c, data);

            if (e is InvalidKernelVersionError || e is PackageChangedError) {
              // Don't report any warning.
            } else if (e is CanonicalNameError) {
              dillLoadedData.loader.addProblem(
                  templateInitializeFromDillNotSelfContained
                      .withArguments(initializeFromDillUri.toString()),
                  TreeNode.noOffset,
                  1,
                  null);
            } else {
              // Unknown error: Report problem as such.
              dillLoadedData.loader.addProblem(
                  templateInitializeFromDillUnknownProblem.withArguments(
                      initializeFromDillUri.toString(), "$e"),
                  TreeNode.noOffset,
                  1,
                  null);
            }
          }
        } else if (componentToInitializeFrom != null) {
          initializeFromComponent(summaryBytes, uriTranslator, c, data);
        }
        appendLibraries(data, bytesLength);

        try {
          await dillLoadedData.buildOutlines();
        } catch (e) {
          if (!initializedFromDill) rethrow;

          // Retry without initializing from dill.
          initializedFromDill = false;
          data.reset();
          bytesLength = prepareSummary(summaryBytes, uriTranslator, c, data);
          appendLibraries(data, bytesLength);
          await dillLoadedData.buildOutlines();
        }
        summaryBytes = null;
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

      Set<Uri> invalidatedUris = this.invalidatedUris.toSet();
      if ((data.includeUserLoadedLibraries &&
              componentToInitializeFrom ==
                  null) // when loading state from component no need to invalidate anything
          ||
          fullComponent) {
        invalidatedUris.add(entryPoint);
      }
      if (componentToInitializeFrom != null) {
        // Once compiler was initialized from component, no need to skip logic
        // above that adds entryPoint to invalidatedUris for successive
        // [computeDelta] calls.
        componentToInitializeFrom = null;
      }

      ClassHierarchy hierarchy = userCode?.loader?.hierarchy;
      Set<LibraryBuilder> notReusedLibraries;
      if (hierarchy != null) {
        notReusedLibraries = new Set<LibraryBuilder>();
      }
      List<LibraryBuilder> reusedLibraries = computeReusedLibraries(
          invalidatedUris, uriTranslator,
          notReused: notReusedLibraries);
      Set<Uri> reusedLibraryUris =
          new Set<Uri>.from(reusedLibraries.map((b) => b.uri));
      for (Uri uri in new Set<Uri>.from(dillLoadedData.loader.builders.keys)
        ..removeAll(reusedLibraryUris)) {
        dillLoadedData.loader.builders.remove(uri);
        userBuilders?.remove(uri);
      }

      if (hierarchy != null) {
        List<Library> removedLibraries = new List<Library>();
        for (LibraryBuilder builder in notReusedLibraries) {
          Library lib = builder.target;
          removedLibraries.add(lib);
        }
        hierarchy.applyTreeChanges(removedLibraries, const []);
      }

      if (userCode != null) {
        ticker.logMs("Decided to reuse ${reusedLibraries.length}"
            " of ${userCode.loader.builders.length} libraries");
      }

      reusedLibraries.addAll(platformBuilders);

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

      for (LibraryBuilder library in reusedLibraries) {
        userCode.loader.builders[library.uri] = library;
        if (entryPoint == library.uri) {
          userCode.loader.first = library;
        }
        if (library.uri.scheme == "dart" && library.uri.path == "core") {
          userCode.loader.coreLibrary = library;
        }
      }

      userCode.setEntryPoints(<Uri>[entryPoint]);
      await userCode.buildOutlines();

      // This is not the full component. It is the component including all
      // libraries loaded from .dill files.
      Component componentWithDill =
          await userCode.buildComponent(verify: c.options.verify);
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
      if (data.includeUserLoadedLibraries || fullComponent) {
        outputLibraries = computeTransitiveClosure(compiledLibraries,
            mainMethod, entryPoint, reusedLibraries, data, hierarchy);
      } else {
        computeTransitiveClosure(compiledLibraries, mainMethod, entryPoint,
            reusedLibraries, data, hierarchy);
        outputLibraries = compiledLibraries;
      }

      if (componentWithDill == null) {
        userCode.loader.builders.clear();
        userCode = userCodeOld;
      }

      // This is the incremental component.
      return context.options.target.configureComponent(new Component(
          libraries: outputLibraries,
          uriToSource: componentWithDill.uriToSource))
        ..mainMethod = mainMethod;
    });
  }

  List<Library> computeTransitiveClosure(
      List<Library> inputLibraries,
      Procedure mainMethod,
      Uri entry,
      List<LibraryBuilder> reusedLibraries,
      IncrementalCompilerData data,
      ClassHierarchy hierarchy) {
    List<Library> result = new List<Library>.from(inputLibraries);
    Map<Uri, Library> libraryMap = <Uri, Library>{};
    for (Library library in inputLibraries) {
      libraryMap[library.importUri] = library;
    }
    List<Uri> worklist = new List<Uri>.from(libraryMap.keys);
    worklist.add(mainMethod?.enclosingLibrary?.importUri);
    if (entry != null) {
      worklist.add(entry);
    }

    Map<Uri, Library> potentiallyReferencedLibraries = <Uri, Library>{};
    for (LibraryBuilder library in reusedLibraries) {
      if (library.uri.scheme == "dart") continue;
      Library lib = library.target;
      potentiallyReferencedLibraries[library.uri] = lib;
      libraryMap[library.uri] = lib;
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
        }
      }
    }

    List<Library> removedLibraries = new List<Library>();
    for (Uri uri in potentiallyReferencedLibraries.keys) {
      if (uri.scheme == "package") continue;
      LibraryBuilder builder = userCode.loader.builders.remove(uri);
      if (builder != null) {
        Library lib = builder.target;
        removedLibraries.add(lib);
        dillLoadedData.loader.builders.remove(uri);
        userBuilders?.remove(uri);
      }
    }
    hierarchy?.applyTreeChanges(removedLibraries, const []);

    return result;
  }

  int prepareSummary(List<int> summaryBytes, UriTranslator uriTranslator,
      CompilerContext c, IncrementalCompilerData data) {
    dillLoadedData = new DillTarget(ticker, uriTranslator, c.options.target);
    int bytesLength = 0;

    if (summaryBytes != null) {
      ticker.logMs("Read ${c.options.sdkSummary}");
      data.component = c.options.target.configureComponent(new Component());
      new BinaryBuilder(summaryBytes, disableLazyReading: false)
          .readComponent(data.component);
      ticker.logMs("Deserialized ${c.options.sdkSummary}");
      bytesLength += summaryBytes.length;
    }

    return bytesLength;
  }

  // This procedure will try to load the dill file and will crash if it cannot.
  Future<int> initializeFromDill(
      List<int> summaryBytes,
      UriTranslator uriTranslator,
      CompilerContext c,
      IncrementalCompilerData data) async {
    int bytesLength = 0;
    FileSystemEntity entity =
        c.options.fileSystem.entityForUri(initializeFromDillUri);
    if (await entity.exists()) {
      List<int> initializationBytes = await entity.readAsBytes();
      if (initializationBytes != null) {
        ticker.logMs("Read $initializeFromDillUri");

        // We're going to output all we read here so lazy loading it
        // doesn't make sense.
        new BinaryBuilder(initializationBytes, disableLazyReading: true)
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
        data.includeUserLoadedLibraries = true;
      }
    }
    return bytesLength;
  }

  // This procedure will set up compiler from [componentToInitializeFrom].
  void initializeFromComponent(
      List<int> summaryBytes,
      UriTranslator uriTranslator,
      CompilerContext c,
      IncrementalCompilerData data) {
    ticker.logMs("Read initializeFromComponent");

    // [libraries] and [uriToSource] from [componentToInitializeFrom] take
    // precedence over what was already read into [data.component]. Assumption
    // is that [data.component] is initialized with standard prebuilt various
    // platform libraries.
    List<Library> combinedLibs = <Library>[];
    Set<Uri> readLibs =
        componentToInitializeFrom.libraries.map((lib) => lib.fileUri).toSet();
    combinedLibs.addAll(componentToInitializeFrom.libraries);
    for (Library lib in data.component.libraries) {
      if (!readLibs.contains(lib.fileUri)) {
        combinedLibs.add(lib);
      }
    }
    Map<Uri, Source> combinedMaps = new Map<Uri, Source>();
    combinedMaps.addAll(componentToInitializeFrom.uriToSource);
    Set<Uri> uris = combinedMaps.keys.toSet();
    for (MapEntry<Uri, Source> entry in data.component.uriToSource.entries) {
      if (!uris.contains(entry.key)) {
        combinedMaps[entry.key] = entry.value;
      }
    }

    data.component =
        new Component(libraries: combinedLibs, uriToSource: combinedMaps)
          ..mainMethod = componentToInitializeFrom.mainMethod;
    data.userLoadedUriMain = data.component.mainMethod;
    data.includeUserLoadedLibraries = true;
  }

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
      LibraryBuilder library =
          userCode.loader.read(libraryUri, -1, accessor: userCode.loader.first);

      Class kernelClass;
      if (className != null) {
        kernelClass = library.scopeBuilder[className]?.target;
        if (kernelClass == null) return null;
      }

      userCode.loader.seenMessages.clear();

      for (TypeParameter typeParam in typeDefinitions) {
        if (!isLegalIdentifier(typeParam.name)) return null;
      }
      for (String name in definitions.keys) {
        if (!isLegalIdentifier(name)) return null;
      }

      Uri debugExprUri = new Uri(
          scheme: "org-dartlang-debug", path: "synthetic_debug_expression");

      KernelLibraryBuilder debugLibrary = new KernelLibraryBuilder(
          libraryUri,
          debugExprUri,
          userCode.loader,
          null,
          library.scope.createNestedScope("expression"),
          library.target);

      if (library is DillLibraryBuilder) {
        for (LibraryDependency dependency in library.target.dependencies) {
          if (!dependency.isImport) continue;

          List<Combinator> combinators;

          for (kernel.Combinator combinator in dependency.combinators) {
            combinators ??= <Combinator>[];

            combinators.add(combinator.isShow
                ? new Combinator.show(
                    combinator.names, combinator.fileOffset, library.fileUri)
                : new Combinator.hide(
                    combinator.names, combinator.fileOffset, library.fileUri));
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
              .map((name) => new VariableDeclarationJudgment(name, 0))
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
      procedure.parent = className != null ? kernelClass : library.target;

      userCode.uriToSource.remove(debugExprUri);
      userCode.loader.sourceBytes.remove(debugExprUri);

      userCode.runProcedureTransformations(procedure);

      return procedure;
    });
  }

  List<LibraryBuilder> computeReusedLibraries(
      Set<Uri> invalidatedUris, UriTranslator uriTranslator,
      {Set<LibraryBuilder> notReused}) {
    if (userCode == null && userBuilders == null) {
      return <LibraryBuilder>[];
    }

    List<LibraryBuilder> result = <LibraryBuilder>[];

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
      if (hasToCheckPackageUris &&
          importUri.scheme == "package" &&
          uriTranslator.translate(importUri, false) != fileUri) {
        return true;
      }
      if (builders[importUri]?.isSynthetic ?? false) return true;
      return false;
    }

    addBuilderAndInvalidateUris(Uri uri, LibraryBuilder library) {
      if (uri.scheme == "dart") {
        result.add(library);
        return;
      }
      builders[uri] = library;
      if (isInvalidated(uri, library.target.fileUri)) {
        invalidatedImportUris.add(uri);
      }
      if (library is SourceLibraryBuilder) {
        for (LibraryBuilder part in library.parts) {
          if (isInvalidated(part.uri, part.fileUri)) {
            invalidatedImportUris.add(part.uri);
            builders[part.uri] = part;
          }
        }
      } else if (library is DillLibraryBuilder) {
        for (LibraryPart part in library.target.parts) {
          Uri partUri = library.uri.resolve(part.partUri);
          Uri fileUri = library.library.fileUri.resolve(part.partUri);
          if (fileUri.scheme == "package") {
            // Part was specified via package URI and the resolve above thus
            // did not go as expected. Translate the package URI to get the
            // actual file URI.
            fileUri = uriTranslator.translate(partUri, false);
          }
          if (isInvalidated(partUri, fileUri)) {
            invalidatedImportUris.add(partUri);
            builders[partUri] = library;
          }
        }
      }
    }

    userBuilders?.forEach(addBuilderAndInvalidateUris);
    if (userCode != null) {
      userCode.loader.builders.forEach(addBuilderAndInvalidateUris);
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

  void recordInvalidatedImportUrisForTesting(List<Uri> uris) {}
}

class PackageChangedError {
  const PackageChangedError();
}

class IncrementalCompilerData {
  bool includeUserLoadedLibraries;
  Procedure userLoadedUriMain;
  Component component;

  IncrementalCompilerData() {
    reset();
  }

  reset() {
    includeUserLoadedLibraries = false;
    userLoadedUriMain = null;
    component = null;
  }
}
