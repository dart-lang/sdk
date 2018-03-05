// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.incremental_compiler;

import 'dart:async' show Future;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:kernel/kernel.dart' show Library, Procedure, Program, Source;

import '../api_prototype/incremental_kernel_generator.dart'
    show IncrementalKernelGenerator;

import '../api_prototype/file_system.dart' show FileSystemEntity;

import 'builder/builder.dart' show LibraryBuilder;

import 'builder_graph.dart' show BuilderGraph;

import 'compiler_context.dart' show CompilerContext;

import 'dill/dill_library_builder.dart' show DillLibraryBuilder;

import 'dill/dill_target.dart' show DillTarget;

import 'kernel/kernel_target.dart' show KernelTarget;

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

  KernelTarget userCode;

  IncrementalCompiler(this.context, [this.initializeFromDillUri])
      : ticker = context.options.ticker;

  @override
  Future<Program> computeDelta({Uri entryPoint}) async {
    ticker.reset();
    entryPoint ??= context.options.inputs.single;
    return context.runInContext<Future<Program>>((CompilerContext c) async {
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
            // We might have loaded x out of y libraries into the program.
            // To avoid any unforeseen problems start over.
            bytesLength = prepareSummary(summaryBytes, uriTranslator, c, data);
          }
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
      userCode = new KernelTarget(
          c.fileSystem, false, dillLoadedData, dillLoadedData.uriTranslator,
          uriToSource: c.uriToSource);
      for (LibraryBuilder library in reusedLibraries) {
        userCode.loader.builders[library.uri] = library;
        if (library.uri.scheme == "dart" && library.uri.path == "core") {
          userCode.loader.coreLibrary = library;
        }
      }

      userCode.read(entryPoint);

      await userCode.buildOutlines();

      // This is not the full program. It is the program including all
      // libraries loaded from .dill files.
      Program programWithDill =
          await userCode.buildProgram(verify: c.options.verify);

      List<Library> libraries =
          new List<Library>.from(userCode.loader.libraries);
      data.uriToSource.addAll(userCode.uriToSource);
      if (data.includeUserLoadedLibraries) {
        for (LibraryBuilder library in reusedLibraries) {
          if (library.fileUri.scheme == "dart") continue;
          assert(library is DillLibraryBuilder);
          libraries.add((library as DillLibraryBuilder).library);
        }

        // For now ensure original order of libraries to produce bit-perfect
        // output.
        libraries.sort((a, b) {
          int aOrder = data.importUriToOrder[a.importUri];
          int bOrder = data.importUriToOrder[b.importUri];
          if (aOrder != null && bOrder != null) return aOrder - bOrder;
          if (aOrder != null) return -1;
          if (bOrder != null) return 1;
          return 0;
        });
      }

      // This is the incremental program.
      Procedure mainMethod = programWithDill == null
          ? data.userLoadedUriMain
          : programWithDill.mainMethod;
      return new Program(libraries: libraries, uriToSource: data.uriToSource)
        ..mainMethod = mainMethod;
    });
  }

  int prepareSummary(List<int> summaryBytes, UriTranslator uriTranslator,
      CompilerContext c, IncrementalCompilerData data) {
    dillLoadedData = new DillTarget(ticker, uriTranslator, c.options.target);
    int bytesLength = 0;

    if (summaryBytes != null) {
      ticker.logMs("Read ${c.options.sdkSummary}");
      data.program = new Program();
      new BinaryBuilder(summaryBytes, disableLazyReading: false)
          .readProgram(data.program);
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
            data.program.libraries.map((Library lib) => lib.importUri));
        ticker.logMs("Read $initializeFromDillUri");

        // We're going to output all we read here so lazy loading it
        // doesn't make sense.
        new BinaryBuilder(initializationBytes, disableLazyReading: true)
            .readProgram(data.program);

        initializedFromDill = true;
        bytesLength += initializationBytes.length;
        for (Library lib in data.program.libraries) {
          if (prevLibraryUris.contains(lib.importUri)) continue;
          data.importUriToOrder[lib.importUri] = data.importUriToOrder.length;
        }
        data.userLoadedUriMain = data.program.mainMethod;
        data.includeUserLoadedLibraries = true;
        data.uriToSource.addAll(data.program.uriToSource);
      }
    }
    return bytesLength;
  }

  void appendLibraries(IncrementalCompilerData data, int bytesLength) {
    if (data.program != null) {
      dillLoadedData.loader
          .appendLibraries(data.program, byteCount: bytesLength);
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
    addBuilderAndInvalidateUris(Uri uri, LibraryBuilder library) {
      builders[uri] = library;
      if (invalidatedFileUris.contains(uri) ||
          (uri != library.fileUri &&
              invalidatedFileUris.contains(library.fileUri)) ||
          (library is DillLibraryBuilder &&
              uri != library.library.fileUri &&
              invalidatedFileUris.contains(library.library.fileUri))) {
        invalidatedImportUris.add(uri);
      }
      if (library is SourceLibraryBuilder) {
        for (var part in library.parts) {
          addBuilderAndInvalidateUris(part.uri, part);
        }
      }
    }

    userBuilders?.forEach(addBuilderAndInvalidateUris);
    if (userCode != null) {
      userCode.loader.builders.forEach(addBuilderAndInvalidateUris);
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
      LibraryBuilder current = builders.remove(workList.removeLast());
      // [current] is null if the corresponding key (URI) has already been
      // removed.
      if (current != null) {
        Set<Uri> s = directDependencies[current.uri];
        if (s != null) {
          // [s] is null for leaves.
          for (Uri dependency in s) {
            workList.add(dependency);
          }
        }
      }
    }

    return builders.values.where((builder) => !builder.isPart).toList();
  }

  @override
  void invalidate(Uri uri) {
    invalidatedUris.add(uri);
  }
}

class IncrementalCompilerData {
  bool includeUserLoadedLibraries;
  Map<Uri, Source> uriToSource;
  Map<Uri, int> importUriToOrder;
  Procedure userLoadedUriMain;
  Program program;

  IncrementalCompilerData() {
    reset();
  }

  reset() {
    includeUserLoadedLibraries = false;
    uriToSource = <Uri, Source>{};
    importUriToOrder = <Uri, int>{};
    userLoadedUriMain = null;
    program = null;
  }
}
