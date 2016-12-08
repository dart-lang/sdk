// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.memory_compiler;

import 'dart:async';

import 'package:compiler/compiler.dart' show DiagnosticHandler;
import 'package:compiler/compiler_new.dart'
    show
        CompilationResult,
        CompilerDiagnostics,
        CompilerOutput,
        Diagnostic,
        PackagesDiscoveryProvider;
import 'package:compiler/src/diagnostics/messages.dart' show Message;
import 'package:compiler/src/null_compiler_output.dart' show NullCompilerOutput;
import 'package:compiler/src/library_loader.dart' show LoadedLibraries;
import 'package:compiler/src/options.dart' show CompilerOptions;

import 'memory_source_file_helper.dart';

export 'output_collector.dart';
export 'package:compiler/compiler_new.dart' show CompilationResult;
export 'diagnostic_helper.dart';

class MultiDiagnostics implements CompilerDiagnostics {
  final List<CompilerDiagnostics> diagnosticsList;

  const MultiDiagnostics([this.diagnosticsList = const []]);

  @override
  void report(Message message, Uri uri, int begin, int end, String text,
      Diagnostic kind) {
    for (CompilerDiagnostics diagnostics in diagnosticsList) {
      diagnostics.report(message, uri, begin, end, text, kind);
    }
  }
}

CompilerDiagnostics createCompilerDiagnostics(
    CompilerDiagnostics diagnostics, SourceFileProvider provider,
    {bool showDiagnostics: true, bool verbose: false}) {
  CompilerDiagnostics handler = diagnostics;
  if (showDiagnostics) {
    if (diagnostics == null) {
      handler = new FormattingDiagnosticHandler(provider)..verbose = verbose;
    } else {
      var formattingHandler = new FormattingDiagnosticHandler(provider)
        ..verbose = verbose;
      handler = new MultiDiagnostics([diagnostics, formattingHandler]);
    }
  } else if (diagnostics == null) {
    handler = new MultiDiagnostics();
  }
  return handler;
}

Expando<MemorySourceFileProvider> expando =
    new Expando<MemorySourceFileProvider>();

Future<CompilationResult> runCompiler(
    {Map<String, String> memorySourceFiles: const <String, String>{},
    Uri entryPoint,
    List<Uri> entryPoints,
    List<Uri> resolutionInputs,
    CompilerDiagnostics diagnosticHandler,
    CompilerOutput outputProvider,
    List<String> options: const <String>[],
    CompilerImpl cachedCompiler,
    bool showDiagnostics: true,
    Uri packageRoot,
    Uri packageConfig,
    PackagesDiscoveryProvider packagesDiscoveryProvider,
    void beforeRun(CompilerImpl compiler)}) async {
  if (entryPoint == null) {
    entryPoint = Uri.parse('memory:main.dart');
  }
  CompilerImpl compiler = compilerFor(
      entryPoint: entryPoint,
      resolutionInputs: resolutionInputs,
      memorySourceFiles: memorySourceFiles,
      diagnosticHandler: diagnosticHandler,
      outputProvider: outputProvider,
      options: options,
      cachedCompiler: cachedCompiler,
      showDiagnostics: showDiagnostics,
      packageRoot: packageRoot,
      packageConfig: packageConfig,
      packagesDiscoveryProvider: packagesDiscoveryProvider);
  compiler.librariesToAnalyzeWhenRun = entryPoints;
  if (beforeRun != null) {
    beforeRun(compiler);
  }
  bool isSuccess = await compiler.run(entryPoint);
  return new CompilationResult(compiler, isSuccess: isSuccess);
}

CompilerImpl compilerFor(
    {Uri entryPoint,
    List<Uri> resolutionInputs,
    Map<String, String> memorySourceFiles: const <String, String>{},
    CompilerDiagnostics diagnosticHandler,
    CompilerOutput outputProvider,
    List<String> options: const <String>[],
    CompilerImpl cachedCompiler,
    bool showDiagnostics: true,
    Uri packageRoot,
    Uri packageConfig,
    PackagesDiscoveryProvider packagesDiscoveryProvider}) {
  Uri libraryRoot = Uri.base.resolve('sdk/');
  if (packageRoot == null &&
      packageConfig == null &&
      packagesDiscoveryProvider == null) {
    if (Platform.packageRoot != null) {
      packageRoot = Uri.base.resolve(Platform.packageRoot);
    } else if (Platform.packageConfig != null) {
      packageConfig = Uri.base.resolve(Platform.packageConfig);
    } else {
      // The tests are run with the base directory as the SDK root
      // so just use the .packages file there.
      packageConfig = Uri.base.resolve('.packages');
    }
  }

  MemorySourceFileProvider provider;
  if (cachedCompiler == null) {
    provider = new MemorySourceFileProvider(memorySourceFiles);
    // Saving the provider in case we need it later for a cached compiler.
    expando[provider] = provider;
  } else {
    // When using a cached compiler, it has read a number of files from disk
    // already (and will not attempt to read them again due to caching). These
    // files must be available to the new diagnostic handler.
    provider = expando[cachedCompiler.provider];
    provider.memorySourceFiles = memorySourceFiles;
  }
  diagnosticHandler = createCompilerDiagnostics(diagnosticHandler, provider,
      showDiagnostics: showDiagnostics,
      verbose: options.contains('-v') || options.contains('--verbose'));

  if (outputProvider == null) {
    outputProvider = const NullCompilerOutput();
  }

  CompilerImpl compiler = new CompilerImpl(
      provider,
      outputProvider,
      diagnosticHandler,
      new CompilerOptions.parse(
          entryPoint: entryPoint,
          resolutionInputs: resolutionInputs,
          libraryRoot: libraryRoot,
          packageRoot: packageRoot,
          options: options,
          environment: {},
          packageConfig: packageConfig,
          packagesDiscoveryProvider: packagesDiscoveryProvider));

  if (cachedCompiler != null) {
    compiler.types = cachedCompiler.types.copy(compiler.resolution);
    Map copiedLibraries = {};
    cachedCompiler.libraryLoader.libraries.forEach((library) {
      if (library.isPlatformLibrary) {
        var libraryLoader = compiler.libraryLoader;
        libraryLoader.mapLibrary(library);
        compiler.onLibraryCreated(library);
        compiler.onLibraryScanned(library, null);
        if (library.isPatched) {
          var patchLibrary = library.patch;
          compiler.onLibraryCreated(patchLibrary);
          compiler.onLibraryScanned(patchLibrary, null);
        }
        copiedLibraries[library.canonicalUri] = library;
      }
    });
    // TODO(johnniwinther): Assert that no libraries are loaded lazily from
    // this call.
    compiler.onLibrariesLoaded(new MemoryLoadedLibraries(copiedLibraries));

    compiler.backend.constantCompilerTask
        .copyConstantValues(cachedCompiler.backend.constantCompilerTask);

    Iterable cachedTreeElements =
        cachedCompiler.enqueuer.resolution.processedEntities;
    cachedTreeElements.forEach((element) {
      if (element.library.isPlatformLibrary) {
        compiler.enqueuer.resolution.registerProcessedElementInternal(element);
      }
    });

    // One potential problem that can occur when reusing elements is that there
    // is a stale reference to an old compiler object.  By nulling out the old
    // compiler's fields, such stale references are easier to identify.
    cachedCompiler.scanner = null;
    cachedCompiler.dietParser = null;
    cachedCompiler.parser = null;
    cachedCompiler.patchParser = null;
    cachedCompiler.libraryLoader = null;
    cachedCompiler.resolver = null;
    cachedCompiler.closureToClassMapper = null;
    cachedCompiler.checker = null;
    cachedCompiler.globalInference = null;
    cachedCompiler.backend = null;
    // Don't null out the enqueuer as it prevents us from using cachedCompiler
    // more than once.
    cachedCompiler.deferredLoadTask = null;
    cachedCompiler.mirrorUsageAnalyzerTask = null;
    cachedCompiler.dumpInfoTask = null;
  }
  return compiler;
}

class MemoryLoadedLibraries implements LoadedLibraries {
  final Map copiedLibraries;

  MemoryLoadedLibraries(this.copiedLibraries);

  @override
  bool containsLibrary(Uri uri) => copiedLibraries.containsKey(uri);

  @override
  void forEachImportChain(f, {callback}) {}

  @override
  void forEachLibrary(f) {}

  @override
  getLibrary(Uri uri) => copiedLibraries[uri];

  @override
  Uri get rootUri => null;
}

DiagnosticHandler createDiagnosticHandler(DiagnosticHandler diagnosticHandler,
    SourceFileProvider provider, bool showDiagnostics) {
  var handler = diagnosticHandler;
  if (showDiagnostics) {
    if (diagnosticHandler == null) {
      handler = new FormattingDiagnosticHandler(provider);
    } else {
      var formattingHandler = new FormattingDiagnosticHandler(provider);
      handler = (Uri uri, int begin, int end, String message, Diagnostic kind) {
        diagnosticHandler(uri, begin, end, message, kind);
        formattingHandler(uri, begin, end, message, kind);
      };
    }
  } else if (diagnosticHandler == null) {
    handler = (Uri uri, int begin, int end, String message, Diagnostic kind) {};
  }
  return handler;
}
