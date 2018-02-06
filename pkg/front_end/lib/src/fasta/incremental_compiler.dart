// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.incremental_compiler;

import 'dart:async' show Future;

import 'package:kernel/kernel.dart'
    show loadProgramFromBytes, Library, Procedure, Program, Source;

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
  final Uri bootstrapDill;
  bool bootstrapSuccess = false;

  KernelTarget userCode;

  IncrementalCompiler(this.context, [this.bootstrapDill])
      : ticker = context.options.ticker;

  @override
  Future<Program> computeDelta({Uri entryPoint}) async {
    ticker.reset();
    entryPoint ??= context.options.inputs.single;
    return context.runInContext<Future<Program>>((CompilerContext c) async {
      bool includeUserLoadedLibraries = false;
      Map<Uri, Source> uriToSource = {};
      Map<Uri, int> importUriToOrder = {};
      Procedure userLoadedUriMain;
      bootstrapSuccess = false;
      if (dillLoadedData == null) {
        UriTranslator uriTranslator = await c.options.getUriTranslator();
        ticker.logMs("Read packages file");

        dillLoadedData =
            new DillTarget(ticker, uriTranslator, c.options.target);
        List<int> summaryBytes = await c.options.loadSdkSummaryBytes();
        int bytesLength = 0;
        Program program;
        if (summaryBytes != null) {
          ticker.logMs("Read ${c.options.sdkSummary}");
          program = loadProgramFromBytes(summaryBytes);
          ticker.logMs("Deserialized ${c.options.sdkSummary}");
          bytesLength += summaryBytes.length;
        }

        if (bootstrapDill != null) {
          FileSystemEntity entity =
              c.options.fileSystem.entityForUri(bootstrapDill);
          if (await entity.exists()) {
            List<int> bootstrapBytes = await entity.readAsBytes();
            if (bootstrapBytes != null) {
              Set<Uri> prevLibraryUris = new Set<Uri>.from(
                  program.libraries.map((Library lib) => lib.importUri));
              ticker.logMs("Read $bootstrapDill");
              bool bootstrapFailed = false;
              try {
                loadProgramFromBytes(bootstrapBytes, program);
              } catch (e) {
                bootstrapFailed = true;
                program = loadProgramFromBytes(summaryBytes);
              }
              if (!bootstrapFailed) {
                bootstrapSuccess = true;
                bytesLength += bootstrapBytes.length;
                for (Library lib in program.libraries) {
                  if (prevLibraryUris.contains(lib.importUri)) continue;
                  importUriToOrder[lib.importUri] = importUriToOrder.length;
                }
                userLoadedUriMain = program.mainMethod;
                includeUserLoadedLibraries = true;
                uriToSource.addAll(program.uriToSource);
              }
            }
          }
        }
        summaryBytes = null;
        if (program != null) {
          dillLoadedData.loader
              .appendLibraries(program, byteCount: bytesLength);
        }
        ticker.logMs("Appended libraries");
        await dillLoadedData.buildOutlines();
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
      uriToSource.addAll(userCode.uriToSource);
      if (includeUserLoadedLibraries) {
        for (LibraryBuilder library in reusedLibraries) {
          if (library.fileUri.scheme == "dart") continue;
          assert(library is DillLibraryBuilder);
          libraries.add((library as DillLibraryBuilder).library);
        }

        // For now ensure original order of libraries to produce bit-perfect
        // output.
        List<Library> librariesOriginalOrder =
            new List<Library>.filled(libraries.length, null, growable: true);
        int lastOpen = libraries.length;
        for (Library lib in libraries) {
          int order = importUriToOrder[lib.importUri];
          if (order != null) {
            librariesOriginalOrder[order] = lib;
          } else {
            librariesOriginalOrder[--lastOpen] = lib;
          }
        }
        libraries = librariesOriginalOrder;
      }

      // This is the incremental program.
      Procedure mainMethod = programWithDill == null
          ? userLoadedUriMain
          : programWithDill.mainMethod;
      return new Program(libraries: libraries, uriToSource: uriToSource)
        ..mainMethod = mainMethod;
    });
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
