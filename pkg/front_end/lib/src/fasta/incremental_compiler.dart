// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.incremental_compiler;

import 'dart:async' show Future;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:kernel/kernel.dart'
    show Component, Library, LibraryPart, Procedure, Source;

import '../api_prototype/file_system.dart' show FileSystemEntity;

import '../api_prototype/incremental_kernel_generator.dart'
    show IncrementalKernelGenerator;

import 'builder/builder.dart' show LibraryBuilder;

import 'builder_graph.dart' show BuilderGraph;

import 'compiler_context.dart' show CompilerContext;

import 'dill/dill_library_builder.dart' show DillLibraryBuilder;

import 'dill/dill_target.dart' show DillTarget;

import 'kernel/kernel_incremental_target.dart'
    show KernelIncrementalTarget, KernelIncrementalTargetErroneousComponent;

import 'library_graph.dart' show LibraryGraph;

import 'source/source_library_builder.dart' show SourceLibraryBuilder;

import 'ticker.dart' show Ticker;

import 'uri_translator.dart' show UriTranslator;

class IncrementalCompiler implements IncrementalKernelGenerator {
  final CompilerContext context;

  final Ticker ticker;

  List<Uri> invalidatedUris = <Uri>[];

  DillTarget dillLoadedData;
  List<LibraryBuilder> platformBuilders;
  Map<Uri, LibraryBuilder> userBuilders;
  final Uri initializeFromDillUri;
  bool initializedFromDill = false;

  KernelIncrementalTarget userCode;

  IncrementalCompiler(this.context, [this.initializeFromDillUri])
      : ticker = context.options.ticker;

  @override
  Future<Component> computeDelta(
      {Uri entryPoint, bool fullComponent: false}) async {
    ticker.reset();
    entryPoint ??= context.options.inputs.single;
    return context.runInContext<Future<Component>>((CompilerContext c) async {
      IncrementalCompilerData data = new IncrementalCompilerData();
      if (dillLoadedData == null) {
        UriTranslator uriTranslator = await c.options.getUriTranslator();
        ticker.logMs("Read packages file");

        List<int> summaryBytes = await c.options.loadSdkSummaryBytes();
        int bytesLength = prepareSummary(summaryBytes, uriTranslator, c, data);
        if (initializeFromDillUri != null) {
          try {
            bytesLength += await initializeFromDill(summaryBytes, c, data);
          } catch (e) {
            // We might have loaded x out of y libraries into the component.
            // To avoid any unforeseen problems start over.
            bytesLength = prepareSummary(summaryBytes, uriTranslator, c, data);
          }
        }
        appendLibraries(data, bytesLength, uriTranslator);

        try {
          await dillLoadedData.buildOutlines();
        } catch (e) {
          if (!initializedFromDill) rethrow;

          // Retry without initializing from dill.
          initializedFromDill = false;
          data.reset();
          bytesLength = prepareSummary(summaryBytes, uriTranslator, c, data);
          appendLibraries(data, bytesLength, uriTranslator);
          await dillLoadedData.buildOutlines();
        }
        summaryBytes = null;
        userBuilders = <Uri, LibraryBuilder>{};
        platformBuilders = <LibraryBuilder>[];
        dillLoadedData.loader.builders.forEach((uri, builder) {
          if (builder.fileUri.scheme == "dart") {
            platformBuilders.add(builder);
          } else {
            userBuilders[uri] = builder;
          }
        });
        if (userBuilders.isEmpty) userBuilders = null;
      }

      List<Uri> invalidatedUris = this.invalidatedUris.toList();
      this.invalidatedUris.clear();
      if (fullComponent) {
        invalidatedUris.add(entryPoint);
      }

      List<LibraryBuilder> reusedLibraries =
          computeReusedLibraries(invalidatedUris);
      Set<Uri> reusedLibraryUris =
          new Set<Uri>.from(reusedLibraries.map((b) => b.uri));
      for (Uri uri in new Set<Uri>.from(dillLoadedData.loader.builders.keys)
        ..removeAll(reusedLibraryUris)) {
        dillLoadedData.loader.builders.remove(uri);
      }

      if (userCode != null) {
        ticker.logMs("Decided to reuse ${reusedLibraries.length}"
            " of ${userCode.loader.builders.length} libraries");
      }
      reusedLibraries.addAll(platformBuilders);

      KernelIncrementalTarget userCodeOld = userCode;
      userCode = new KernelIncrementalTarget(
          c.fileSystem, false, dillLoadedData, dillLoadedData.uriTranslator,
          uriToSource: c.uriToSource);

      for (LibraryBuilder library in reusedLibraries) {
        userCode.loader.builders[library.uri] = library;
        if (library.uri.scheme == "dart" && library.uri.path == "core") {
          userCode.loader.coreLibrary = library;
        }
      }

      Component componentWithDill;
      try {
        userCode.read(entryPoint);
        await userCode.buildOutlines();

        // This is not the full component. It is the component including all
        // libraries loaded from .dill files.
        componentWithDill =
            await userCode.buildComponent(verify: c.options.verify);
      } on KernelIncrementalTargetErroneousComponent {
        List<Library> librariesWithSdk = userCode.component.libraries;
        List<Library> compiledLibraries = <Library>[];
        for (Library lib in librariesWithSdk) {
          if (lib.fileUri.scheme == "dart") continue;
          compiledLibraries.add(lib);
          break;
        }
        userCode.loader.builders.clear();
        userCode = userCodeOld;
        return new Component(
            libraries: compiledLibraries, uriToSource: data.uriToSource);
      }
      userCodeOld?.loader?.builders?.clear();
      userCodeOld = null;

      List<Library> compiledLibraries =
          new List<Library>.from(userCode.loader.libraries);
      data.uriToSource.addAll(userCode.uriToSource);
      Procedure mainMethod = componentWithDill == null
          ? data.userLoadedUriMain
          : componentWithDill.mainMethod;

      List<Library> outputLibraries;
      if (data.includeUserLoadedLibraries || fullComponent) {
        outputLibraries = computeTransitiveClosure(
            compiledLibraries, mainMethod, reusedLibraries, data);
      } else {
        outputLibraries = compiledLibraries;
      }

      // Clean up.
      userCode.loader.releaseAncillaryResources();

      // This is the incremental component.
      return new Component(
          libraries: outputLibraries, uriToSource: data.uriToSource)
        ..mainMethod = mainMethod;
    });
  }

  List<Library> computeTransitiveClosure(
      List<Library> inputLibraries,
      Procedure mainMethod,
      List<LibraryBuilder> reusedLibraries,
      IncrementalCompilerData data) {
    List<Library> result = new List<Library>.from(inputLibraries);
    Map<Uri, Library> libraryMap = <Uri, Library>{};
    for (Library library in inputLibraries) {
      libraryMap[library.fileUri] = library;
    }
    List<Uri> worklist = new List<Uri>.from(libraryMap.keys);
    worklist.add(mainMethod?.enclosingLibrary?.fileUri);

    Map<Uri, Library> potentiallyReferencedLibraries = <Uri, Library>{};
    for (LibraryBuilder library in reusedLibraries) {
      if (library.fileUri.scheme == "dart") continue;
      Library lib = library.target;
      potentiallyReferencedLibraries[library.fileUri] = lib;
      libraryMap[library.fileUri] = lib;
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
    for (Uri uri in potentiallyReferencedLibraries.keys) {
      userCode.loader.builders.remove(uri);
    }

    // For now ensure original order of libraries to produce bit-perfect
    // output.
    result.sort((a, b) {
      int aOrder = data.importUriToOrder[a.importUri];
      int bOrder = data.importUriToOrder[b.importUri];
      if (aOrder != null && bOrder != null) return aOrder - bOrder;
      if (aOrder != null) return -1;
      if (bOrder != null) return 1;
      return 0;
    });

    return result;
  }

  int prepareSummary(List<int> summaryBytes, UriTranslator uriTranslator,
      CompilerContext c, IncrementalCompilerData data) {
    dillLoadedData = new DillTarget(ticker, uriTranslator, c.options.target);
    int bytesLength = 0;

    if (summaryBytes != null) {
      ticker.logMs("Read ${c.options.sdkSummary}");
      data.component = new Component();
      new BinaryBuilder(summaryBytes, disableLazyReading: false)
          .readComponent(data.component);
      ticker.logMs("Deserialized ${c.options.sdkSummary}");
      bytesLength += summaryBytes.length;
    }

    return bytesLength;
  }

  // This procedure will try to load the dill file and will crash if it cannot.
  Future<int> initializeFromDill(List<int> summaryBytes, CompilerContext c,
      IncrementalCompilerData data) async {
    int bytesLength = 0;
    FileSystemEntity entity =
        c.options.fileSystem.entityForUri(initializeFromDillUri);
    if (await entity.exists()) {
      List<int> initializationBytes = await entity.readAsBytes();
      if (initializationBytes != null) {
        Set<Uri> prevLibraryUris = new Set<Uri>.from(
            data.component.libraries.map((Library lib) => lib.importUri));
        ticker.logMs("Read $initializeFromDillUri");

        Set<Uri> sdkUris = data.component.uriToSource.keys.toSet();

        // We're going to output all we read here so lazy loading it
        // doesn't make sense.
        new BinaryBuilder(initializationBytes, disableLazyReading: true)
            .readComponent(data.component);

        initializedFromDill = true;
        bytesLength += initializationBytes.length;
        for (Library lib in data.component.libraries) {
          if (prevLibraryUris.contains(lib.importUri)) continue;
          data.importUriToOrder[lib.importUri] = data.importUriToOrder.length;
        }
        data.userLoadedUriMain = data.component.mainMethod;
        data.includeUserLoadedLibraries = true;
        for (Uri uri in data.component.uriToSource.keys) {
          if (sdkUris.contains(uri)) continue;
          data.uriToSource[uri] = data.component.uriToSource[uri];
        }
      }
    }
    return bytesLength;
  }

  void appendLibraries(IncrementalCompilerData data, int bytesLength,
      UriTranslator uriTranslator) {
    if (data.component != null) {
      List<Library> keepLibraries = <Library>[];
      for (Library lib in data.component.libraries) {
        if (lib.importUri.scheme != "package" ||
            uriTranslator.translate(lib.importUri, false) == lib.fileUri) {
          keepLibraries.add(lib);
        }
      }
      data.component.libraries
        ..clear()
        ..addAll(keepLibraries);

      dillLoadedData.loader
          .appendLibraries(data.component, byteCount: bytesLength);
    }
    ticker.logMs("Appended libraries");
  }

  List<LibraryBuilder> computeReusedLibraries(Iterable<Uri> invalidatedUris) {
    if (userCode == null && userBuilders == null) {
      return <LibraryBuilder>[];
    }

    // [invalidatedUris] converted to a set.
    Set<Uri> invalidatedFileUris = invalidatedUris.toSet();

    // Maps all non-platform LibraryBuilders from their import URI.
    Map<Uri, LibraryBuilder> builders = <Uri, LibraryBuilder>{};

    // Invalidated URIs translated back to their import URI (package:, dart:,
    // etc.).
    List<Uri> invalidatedImportUris = <Uri>[];

    // Compute [builders] and [invalidatedImportUris].
    addBuilderAndInvalidateUris(Uri uri, LibraryBuilder library,
        [bool recursive = true]) {
      builders[uri] = library;
      if (invalidatedFileUris.contains(uri) ||
          (uri != library.fileUri &&
              invalidatedFileUris.contains(library.fileUri)) ||
          (library is DillLibraryBuilder &&
              uri != library.library.fileUri &&
              invalidatedFileUris.contains(library.library.fileUri))) {
        invalidatedImportUris.add(uri);
      }
      if (!recursive) return;
      if (library is SourceLibraryBuilder) {
        for (LibraryBuilder part in library.parts) {
          addBuilderAndInvalidateUris(part.uri, part, false);
        }
      } else if (library is DillLibraryBuilder) {
        for (LibraryPart part in library.library.parts) {
          addBuilderAndInvalidateUris(part.fileUri, library, false);
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
      }
    }

    // Builders contain mappings from part uri to builder, meaning the same
    // builder can exist multiple times in the values list.
    Set<Uri> seenUris = new Set<Uri>();
    List<LibraryBuilder> result = <LibraryBuilder>[];
    for (LibraryBuilder builder in builders.values) {
      if (builder.isPart) continue;
      if (!seenUris.add(builder.fileUri)) continue;
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

class IncrementalCompilerData {
  bool includeUserLoadedLibraries;
  Map<Uri, Source> uriToSource;
  Map<Uri, int> importUriToOrder;
  Procedure userLoadedUriMain;
  Component component;

  IncrementalCompilerData() {
    reset();
  }

  reset() {
    includeUserLoadedLibraries = false;
    uriToSource = <Uri, Source>{};
    importUriToOrder = <Uri, int>{};
    userLoadedUriMain = null;
    component = null;
  }
}
