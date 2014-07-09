// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.memory_compiler;

import 'memory_source_file_helper.dart';

import 'package:compiler/implementation/dart2jslib.dart'
       show NullSink;

import 'package:compiler/compiler.dart'
       show Diagnostic, DiagnosticHandler, CompilerOutputProvider;

import 'dart:async';

import 'package:compiler/implementation/mirrors/source_mirrors.dart';
import 'package:compiler/implementation/mirrors/analyze.dart';

class DiagnosticMessage {
  final Uri uri;
  final int begin;
  final int end;
  final String message;
  final Diagnostic kind;

  DiagnosticMessage(this.uri, this.begin, this.end, this.message, this.kind);

  String toString() => '$uri:$begin:$end:$message:$kind';
}

class DiagnosticCollector {
  List<DiagnosticMessage> messages = <DiagnosticMessage>[];

  void call(Uri uri, int begin, int end, String message,
                         Diagnostic kind) {
    messages.add(new DiagnosticMessage(uri, begin, end, message, kind));
  }

  Iterable<DiagnosticMessage> filterMessagesByKind(Diagnostic kind) {
    return messages.where(
      (DiagnosticMessage message) => message.kind == kind);
  }

  Iterable<DiagnosticMessage> get errors {
    return filterMessagesByKind(Diagnostic.ERROR);
  }

  Iterable<DiagnosticMessage> get warnings {
    return filterMessagesByKind(Diagnostic.WARNING);
  }

  Iterable<DiagnosticMessage> get hints {
    return filterMessagesByKind(Diagnostic.HINT);
  }

  Iterable<DiagnosticMessage> get infos {
    return filterMessagesByKind(Diagnostic.INFO);
  }
}

class BufferedEventSink implements EventSink<String> {
  StringBuffer sb = new StringBuffer();
  String text;

  void add(String event) {
    sb.write(event);
  }

  void addError(errorEvent, [StackTrace stackTrace]) {
    // Do not support this.
  }

  void close() {
    text = sb.toString();
    sb = null;
  }
}

class OutputCollector {
  Map<String, Map<String, BufferedEventSink>> outputMap = {};

  EventSink<String> call(String name, String extension) {
    Map<String, BufferedEventSink> sinkMap =
        outputMap.putIfAbsent(extension, () => {});
    return sinkMap.putIfAbsent(name, () => new BufferedEventSink());
  }

  String getOutput(String name, String extension) {
    Map<String, BufferedEventSink> sinkMap = outputMap[extension];
    if (sinkMap == null) return null;
    BufferedEventSink sink = sinkMap[name];
    return sink != null ? sink.text : null;
  }
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

Expando<MemorySourceFileProvider> expando =
    new Expando<MemorySourceFileProvider>();

Compiler compilerFor(Map<String,String> memorySourceFiles,
                     {DiagnosticHandler diagnosticHandler,
                      CompilerOutputProvider outputProvider,
                      List<String> options: const [],
                      Compiler cachedCompiler,
                      bool showDiagnostics: true,
                      Uri packageRoot}) {
  Uri libraryRoot = Uri.base.resolve('sdk/');
  Uri script = Uri.base.resolveUri(Platform.script);
  if (packageRoot == null) {
    packageRoot = Uri.base.resolveUri(new Uri.file('${Platform.packageRoot}/'));
  }

  MemorySourceFileProvider provider;
  var readStringFromUri;
  if (cachedCompiler == null) {
    provider = new MemorySourceFileProvider(memorySourceFiles);
    readStringFromUri = provider.readStringFromUri;
    // Saving the provider in case we need it later for a cached compiler.
    expando[readStringFromUri] = provider;
  } else {
    // When using a cached compiler, it has read a number of files from disk
    // already (and will not attemp to read them again due to caching). These
    // files must be available to the new diagnostic handler.
    provider = expando[cachedCompiler.provider];
    readStringFromUri = cachedCompiler.provider;
    provider.memorySourceFiles = memorySourceFiles;
  }
  var handler =
      createDiagnosticHandler(diagnosticHandler, provider, showDiagnostics);

  EventSink<String> noOutputProvider(String name, String extension) {
    if (name != '') throw 'Attempt to output file "$name.$extension"';
    return new NullSink('$name.$extension');
  }
  if (outputProvider == null) {
    outputProvider = noOutputProvider;
  }

  Compiler compiler = new Compiler(readStringFromUri,
                                   outputProvider,
                                   handler,
                                   libraryRoot,
                                   packageRoot,
                                   options,
                                   {});
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
    compiler.onLibrariesLoaded(copiedLibraries);

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
    cachedCompiler.validator = null;
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

Future<MirrorSystem> mirrorSystemFor(Map<String,String> memorySourceFiles,
                                     {DiagnosticHandler diagnosticHandler,
                                      List<String> options: const [],
                                      bool showDiagnostics: true}) {
  Uri libraryRoot = Uri.base.resolve('sdk/');
  Uri packageRoot = Uri.base.resolveUri(
      new Uri.file('${Platform.packageRoot}/'));
  Uri script = Uri.base.resolveUri(Platform.script);

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
