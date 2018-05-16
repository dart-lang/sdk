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
import 'package:compiler/src/elements/entities.dart'
    show LibraryEntity, MemberEntity;
import 'package:compiler/src/enqueue.dart' show ResolutionEnqueuer;
import 'package:compiler/src/null_compiler_output.dart' show NullCompilerOutput;
import 'package:compiler/src/library_loader.dart'
    show LoadedLibraries, KernelLibraryLoaderTask;
import 'package:compiler/src/options.dart' show CompilerOptions;

import 'package:front_end/src/api_unstable/dart2js.dart' as fe;
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'memory_source_file_helper.dart';

export 'output_collector.dart';
export 'package:compiler/compiler_new.dart' show CompilationResult;
export 'diagnostic_helper.dart';

class MultiDiagnostics implements CompilerDiagnostics {
  final List<CompilerDiagnostics> diagnosticsList;

  const MultiDiagnostics([this.diagnosticsList = const []]);

  @override
  void report(covariant Message message, Uri uri, int begin, int end,
      String text, Diagnostic kind) {
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
      handler = new FormattingDiagnosticHandler(provider)
        ..verbose = verbose
        ..autoReadFileUri = true;
    } else {
      var formattingHandler = new FormattingDiagnosticHandler(provider)
        ..verbose = verbose
        ..autoReadFileUri = true;
      handler = new MultiDiagnostics([diagnostics, formattingHandler]);
    }
  } else if (diagnostics == null) {
    handler = new MultiDiagnostics();
  }
  return handler;
}

Expando<MemorySourceFileProvider> expando =
    new Expando<MemorySourceFileProvider>();

// Cached kernel state for non-strong mode.
fe.InitializedCompilerState kernelInitializedCompilerState;

// Cached kernel state for strong mode.
fe.InitializedCompilerState strongKernelInitializedCompilerState;

/// memorySourceFiles can contain a map of string filename to string file
/// contents or string file name to binary file contents (hence the `dynamic`
/// type for the second parameter).
Future<CompilationResult> runCompiler(
    {Map<String, dynamic> memorySourceFiles: const <String, dynamic>{},
    Uri entryPoint,
    List<Uri> entryPoints,
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
  fe.InitializedCompilerState compilerState;
  bool isSuccess = await compiler.run(entryPoint);
  if (compiler.libraryLoader is KernelLibraryLoaderTask) {
    KernelLibraryLoaderTask loader = compiler.libraryLoader;
    if (compiler.options.strongMode) {
      compilerState = strongKernelInitializedCompilerState =
          loader.initializedCompilerState;
    } else {
      compilerState =
          kernelInitializedCompilerState = loader.initializedCompilerState;
    }
  }
  return new CompilationResult(compiler,
      isSuccess: isSuccess, kernelInitializedCompilerState: compilerState);
}

CompilerImpl compilerFor(
    {Uri entryPoint,
    Map<String, dynamic> memorySourceFiles: const <String, dynamic>{},
    CompilerDiagnostics diagnosticHandler,
    CompilerOutput outputProvider,
    List<String> options: const <String>[],
    CompilerImpl cachedCompiler,
    bool showDiagnostics: true,
    Uri packageRoot,
    Uri packageConfig,
    PackagesDiscoveryProvider packagesDiscoveryProvider}) {
  Uri libraryRoot = Uri.base.resolve('sdk/');
  Uri platformBinaries = computePlatformBinariesLocation();

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

  CompilerOptions compilerOptions = CompilerOptions.parse(options,
      libraryRoot: libraryRoot, platformBinaries: platformBinaries)
    ..entryPoint = entryPoint
    ..packageRoot = packageRoot
    ..environment = {}
    ..packageConfig = packageConfig
    ..packagesDiscoveryProvider = packagesDiscoveryProvider;
  if (compilerOptions.strongMode) {
    compilerOptions.kernelInitializedCompilerState =
        strongKernelInitializedCompilerState;
  } else {
    compilerOptions.kernelInitializedCompilerState =
        kernelInitializedCompilerState;
  }
  CompilerImpl compiler = new CompilerImpl(
      provider, outputProvider, diagnosticHandler, compilerOptions);

  if (cachedCompiler != null) {
    Map copiedLibraries = {};
    cachedCompiler.libraryLoader.libraries.forEach((dynamic library) {
      if (library.isPlatformLibrary) {
        dynamic libraryLoader = compiler.libraryLoader;
        libraryLoader.mapLibrary(library);
        copiedLibraries[library.canonicalUri] = library;
      }
    });
    compiler.processLoadedLibraries(new MemoryLoadedLibraries(copiedLibraries));
    ResolutionEnqueuer resolutionEnqueuer = compiler.startResolution();

    Iterable<MemberEntity> cachedTreeElements =
        cachedCompiler.enqueuer.resolution.processedEntities;
    cachedTreeElements.forEach((MemberEntity element) {
      if (element.library.canonicalUri.scheme == 'dart') {
        resolutionEnqueuer.registerProcessedElementInternal(element);
      }
    });

    dynamic frontendStrategy = compiler.frontendStrategy;
    frontendStrategy.nativeBasicDataBuilder.reopenForTesting();

    // One potential problem that can occur when reusing elements is that there
    // is a stale reference to an old compiler object.  By nulling out the old
    // compiler's fields, such stale references are easier to identify.
    cachedCompiler.libraryLoader = null;
    cachedCompiler.globalInference = null;
    cachedCompiler.backend = null;
    // Don't null out the enqueuer as it prevents us from using cachedCompiler
    // more than once.
    cachedCompiler.deferredLoadTask = null;
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
  void forEachImportChain(f, {callback}) {
    throw new UnimplementedError();
  }

  @override
  void forEachLibrary(void f(LibraryEntity l)) =>
      copiedLibraries.values.forEach((l) => f(l));

  @override
  getLibrary(Uri uri) => copiedLibraries[uri];

  @override
  LibraryEntity get rootLibrary => copiedLibraries.values.first;
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

main() {
  runCompiler(memorySourceFiles: {'main.dart': 'main() {}'});
}
