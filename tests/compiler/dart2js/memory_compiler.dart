// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.memory_compiler;

import 'memory_source_file_helper.dart';

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
       show NullSink;

import '../../../sdk/lib/_internal/compiler/compiler.dart'
       show Diagnostic, DiagnosticHandler;

import 'dart:async';

import '../../../sdk/lib/_internal/compiler/implementation/mirrors/source_mirrors.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/analyze.dart';

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
                      List<String> options: const [],
                      Compiler cachedCompiler,
                      bool showDiagnostics: true,
                      Uri packageRoot}) {
  Uri libraryRoot = Uri.base.resolve('sdk/');
  Uri script = Uri.base.resolveUri(Platform.script);
  if (packageRoot == null) {
    packageRoot = Uri.base.resolve('${Platform.packageRoot}/');
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

  EventSink<String> outputProvider(String name, String extension) {
    if (name != '') throw 'Attempt to output file "$name.$extension"';
    return new NullSink('$name.$extension');
  }

  Compiler compiler = new Compiler(readStringFromUri,
                                   outputProvider,
                                   handler,
                                   libraryRoot,
                                   packageRoot,
                                   options,
                                   {});
  if (cachedCompiler != null) {
    compiler.coreLibrary = cachedCompiler.libraries['dart:core'];
    compiler.types = cachedCompiler.types;
    cachedCompiler.libraries.forEach((String uri, library) {
      if (library.isPlatformLibrary) {
        compiler.libraries[uri] = library;
        compiler.onLibraryLoaded(library, library.canonicalUri);
      }
    });

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

    Map cachedTreeElements =
        cachedCompiler.enqueuer.resolution.resolvedElements;
    cachedTreeElements.forEach((element, treeElements) {
      if (element.getLibrary().isPlatformLibrary) {
        compiler.enqueuer.resolution.resolvedElements[element] =
            treeElements;
      }
    });
  }
  return compiler;
}

Future<MirrorSystem> mirrorSystemFor(Map<String,String> memorySourceFiles,
                                     {DiagnosticHandler diagnosticHandler,
                                      List<String> options: const [],
                                      bool showDiagnostics: true}) {
  Uri libraryRoot = Uri.base.resolve('sdk/');
  Uri packageRoot = Uri.base.resolve('${Platform.packageRoot}/');
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
