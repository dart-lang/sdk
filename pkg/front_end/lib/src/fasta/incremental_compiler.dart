// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.incremental_compiler;

import 'dart:async' show Future;

import 'package:kernel/kernel.dart'
    show Library, Program, Source, loadProgramFromBytes;

import '../api_prototype/incremental_kernel_generator.dart'
    show IncrementalKernelGenerator;

import 'builder/builder.dart' show LibraryBuilder;

import 'dill/dill_target.dart' show DillTarget;

import 'kernel/kernel_target.dart' show KernelTarget;

import 'source/source_graph.dart' show SourceGraph;

import 'source/source_library_builder.dart' show SourceLibraryBuilder;

import 'compiler_context.dart' show CompilerContext;

import 'ticker.dart' show Ticker;

import 'uri_translator.dart' show UriTranslator;

class IncrementalCompiler implements IncrementalKernelGenerator {
  final CompilerContext context;

  final Ticker ticker;

  List<Uri> invalidatedUris = <Uri>[];

  DillTarget platform;

  KernelTarget userCode;

  IncrementalCompiler(this.context) : ticker = context.options.ticker;

  @override
  Future<Program> computeDelta({Uri entryPoint}) async {
    ticker.reset();
    entryPoint ??= context.options.inputs.single;
    return context.runInContext<Future<Program>>((CompilerContext c) async {
      if (platform == null) {
        UriTranslator uriTranslator = await c.options.getUriTranslator();
        ticker.logMs("Read packages file");

        platform = new DillTarget(ticker, uriTranslator, c.options.target);
        List<int> bytes = await c.options.loadSdkSummaryBytes();
        if (bytes != null) {
          ticker.logMs("Read ${c.options.sdkSummary}");
          Program program = loadProgramFromBytes(bytes);
          ticker.logMs("Deserialized ${c.options.sdkSummary}");
          platform.loader.appendLibraries(program, byteCount: bytes.length);
          ticker.logMs("Appended libraries");
        }
        await platform.buildOutlines();
      }

      List<Uri> invalidatedUris = this.invalidatedUris.toList();
      this.invalidatedUris.clear();

      List<LibraryBuilder> reusedLibraries =
          computeReusedLibraries(invalidatedUris);
      if (userCode != null) {
        ticker.logMs("Decided to reuse ${reusedLibraries.length}"
            " of ${userCode.loader.builders.length} libraries");
      }

      platform.loader.builders.forEach((Uri uri, LibraryBuilder builder) {
        reusedLibraries.add(builder);
      });
      userCode = new KernelTarget(
          c.fileSystem, false, platform, platform.uriTranslator,
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

      // This is the incremental program.
      return new Program(
          libraries: new List<Library>.from(userCode.loader.libraries),
          uriToSource: new Map<Uri, Source>.from(userCode.uriToSource))
        ..mainMethod = programWithDill?.mainMethod;
    });
  }

  List<LibraryBuilder> computeReusedLibraries(Iterable<Uri> invalidatedUris) {
    if (userCode == null) return <LibraryBuilder>[];

    // [invalidatedUris] converted to a set.
    Set<Uri> invalidatedFileUris = invalidatedUris.toSet();

    // Maps all non-platform LibraryBuilders from their import URI.
    Map<Uri, LibraryBuilder> builders = <Uri, LibraryBuilder>{};

    // Invalidated URIs translated back to their import URI (package:, dart:,
    // etc.).
    List<Uri> invalidatedImportUris = <Uri>[];

    // Compute [builders] and [invalidatedImportUris].
    addBuilderAndInvalidateUris(Uri uri, LibraryBuilder libraryBuilder) {
      if (libraryBuilder.loader != platform.loader) {
        assert(libraryBuilder is SourceLibraryBuilder);
        SourceLibraryBuilder library = libraryBuilder;
        builders[uri] = library;
        if (invalidatedFileUris.contains(uri) ||
            (uri != library.fileUri &&
                invalidatedFileUris.contains(library.fileUri))) {
          invalidatedImportUris.add(uri);
        }
        for (var part in library.parts) {
          addBuilderAndInvalidateUris(part.uri, part);
        }
      }
    }

    userCode.loader.builders.forEach(addBuilderAndInvalidateUris);

    SourceGraph graph = new SourceGraph(builders);

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
