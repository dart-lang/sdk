// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.memory_compiler;

import 'dart:async';

import 'package:compiler/compiler.dart' show
    DiagnosticHandler;
import 'package:compiler/compiler_new.dart' show
    CompilationResult,
    CompilerDiagnostics,
    CompilerOutput,
    Diagnostic,
    PackagesDiscoveryProvider;
import 'package:compiler/src/diagnostics/messages.dart' show
    Message;
import 'package:compiler/src/mirrors/source_mirrors.dart';
import 'package:compiler/src/mirrors/analyze.dart';
import 'package:compiler/src/null_compiler_output.dart' show
    NullCompilerOutput;
import 'package:compiler/src/library_loader.dart' show
    LoadedLibraries;

import 'memory_source_file_helper.dart';

export 'output_collector.dart';
export 'package:compiler/compiler_new.dart' show
    CompilationResult;

class DiagnosticMessage {
  final Message message;
  final Uri uri;
  final int begin;
  final int end;
  final String text;
  final Diagnostic kind;

  DiagnosticMessage(
      this.message, this.uri, this.begin, this.end, this.text, this.kind);

  String toString() => '$uri:$begin:$end:$text:$kind';
}

class DiagnosticCollector implements CompilerDiagnostics {
  List<DiagnosticMessage> messages = <DiagnosticMessage>[];

  void call(Uri uri, int begin, int end, String message, Diagnostic kind) {
    report(null, uri, begin, end, message, kind);
  }

  @override
  void report(Message message,
              Uri uri, int begin, int end, String text, Diagnostic kind) {
    messages.add(new DiagnosticMessage(message, uri, begin, end, text, kind));
  }

  Iterable<DiagnosticMessage> filterMessagesByKinds(List<Diagnostic> kinds) {
    return messages.where(
      (DiagnosticMessage message) => kinds.contains(message.kind));
  }

  Iterable<DiagnosticMessage> get errors {
    return filterMessagesByKinds([Diagnostic.ERROR]);
  }

  Iterable<DiagnosticMessage> get warnings {
    return filterMessagesByKinds([Diagnostic.WARNING]);
  }

  Iterable<DiagnosticMessage> get hints {
    return filterMessagesByKinds([Diagnostic.HINT]);
  }

  Iterable<DiagnosticMessage> get infos {
    return filterMessagesByKinds([Diagnostic.INFO]);
  }

  /// `true` if non-verbose messages has been collected.
  bool get hasRegularMessages {
    return messages.any((m) => m.kind != Diagnostic.VERBOSE_INFO);
  }
}

class MultiDiagnostics implements CompilerDiagnostics {
  final List<CompilerDiagnostics> diagnosticsList;

  const MultiDiagnostics([this.diagnosticsList = const []]);

  @override
  void report(Message message, Uri uri, int begin, int end,
              String text, Diagnostic kind) {
    for (CompilerDiagnostics diagnostics in diagnosticsList) {
      diagnostics.report(message, uri, begin, end, text, kind);
    }
  }
}

CompilerDiagnostics createCompilerDiagnostics(
    CompilerDiagnostics diagnostics,
    SourceFileProvider provider,
    bool showDiagnostics) {
  CompilerDiagnostics handler = diagnostics;
  if (showDiagnostics) {
    if (diagnostics == null) {
      handler = new FormattingDiagnosticHandler(provider);
    } else {
      var formattingHandler = new FormattingDiagnosticHandler(provider);
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
     CompilerDiagnostics diagnosticHandler,
     CompilerOutput outputProvider,
     List<String> options: const <String>[],
     Compiler cachedCompiler,
     bool showDiagnostics: true,
     Uri packageRoot,
     Uri packageConfig,
     PackagesDiscoveryProvider packagesDiscoveryProvider,
     void beforeRun(Compiler compiler)}) async {
  if (entryPoint == null) {
    entryPoint = Uri.parse('memory:main.dart');
  }
  Compiler compiler = compilerFor(
      memorySourceFiles,
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

Compiler compilerFor(
    Map<String, String> memorySourceFiles,
    {CompilerDiagnostics diagnosticHandler,
     CompilerOutput outputProvider,
     List<String> options: const <String>[],
     Compiler cachedCompiler,
     bool showDiagnostics: true,
     Uri packageRoot,
     Uri packageConfig,
     PackagesDiscoveryProvider packagesDiscoveryProvider}) {
  Uri libraryRoot = Uri.base.resolve('sdk/');
  if (packageRoot == null &&
      packageConfig == null &&
      packagesDiscoveryProvider == null) {
    packageRoot = Uri.base.resolveUri(new Uri.file('${Platform.packageRoot}/'));
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
  diagnosticHandler =
      createCompilerDiagnostics(diagnosticHandler, provider, showDiagnostics);

  if (outputProvider == null) {
    outputProvider = const NullCompilerOutput();
  }

  Compiler compiler = new Compiler(
      provider,
      outputProvider,
      diagnosticHandler,
      libraryRoot,
      packageRoot,
      options,
      {},
      packageConfig,
      packagesDiscoveryProvider);

  if (cachedCompiler != null) {
    compiler.coreLibrary =
        cachedCompiler.libraryLoader.lookupLibrary(Uri.parse('dart:core'));
    compiler.types = cachedCompiler.types.copy(compiler);
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

    compiler.backend.constantCompilerTask.copyConstantValues(
        cachedCompiler.backend.constantCompilerTask);
    compiler.symbolConstructor = cachedCompiler.symbolConstructor;
    compiler.mirrorSystemClass = cachedCompiler.mirrorSystemClass;
    compiler.mirrorsUsedClass = cachedCompiler.mirrorsUsedClass;
    compiler.mirrorSystemGetNameFunction =
        cachedCompiler.mirrorSystemGetNameFunction;
    compiler.symbolImplementationClass =
        cachedCompiler.symbolImplementationClass;
    compiler.symbolValidatedConstructor =
        cachedCompiler.symbolValidatedConstructor;
    compiler.mirrorsUsedConstructor = cachedCompiler.mirrorsUsedConstructor;
    compiler.deferredLibraryClass = cachedCompiler.deferredLibraryClass;

    Iterable cachedTreeElements =
        cachedCompiler.enqueuer.resolution.resolvedElements;
    cachedTreeElements.forEach((element) {
      if (element.library.isPlatformLibrary) {
        compiler.enqueuer.resolution.registerResolvedElement(element);
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
    cachedCompiler.irBuilder = null;
    cachedCompiler.typesTask = null;
    cachedCompiler.backend = null;
    // Don't null out the enqueuer as it prevents us from using cachedCompiler
    // more than once.
    cachedCompiler.deferredLoadTask = null;
    cachedCompiler.mirrorUsageAnalyzerTask = null;
    cachedCompiler.dumpInfoTask = null;
    cachedCompiler.buildId = null;
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
                                          SourceFileProvider provider,
                                          bool showDiagnostics) {
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

Future<MirrorSystem> mirrorSystemFor(Map<String,String> memorySourceFiles,
                                     {DiagnosticHandler diagnosticHandler,
                                      List<String> options: const [],
                                      bool showDiagnostics: true}) {
  Uri libraryRoot = Uri.base.resolve('sdk/');
  Uri packageRoot = Uri.base.resolveUri(
      new Uri.file('${Platform.packageRoot}/'));

  var provider = new MemorySourceFileProvider(memorySourceFiles);
  var handler =
      createDiagnosticHandler(diagnosticHandler, provider, showDiagnostics);

  List<Uri> libraries = <Uri>[];
  memorySourceFiles.forEach((String path, _) {
    libraries.add(new Uri(scheme: 'memory', path: path));
  });

  return analyze(libraries, libraryRoot, packageRoot,
                 provider, handler, options);
}
