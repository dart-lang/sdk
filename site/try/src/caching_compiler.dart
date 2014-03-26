// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.caching_compiler;

import 'package:compiler/compiler.dart' show
    CompilerOutputProvider,
    Diagnostic,
    DiagnosticHandler;

import 'package:compiler/implementation/apiimpl.dart' show
    Compiler;

// This file is copied from a dart2js test which uses dart:io. For now, mock up
// a bunch of interfaces to silence the analyzer. This file will serve as basis
// for incremental analysis.
abstract class SourceFileProvider {}
class FormattingDiagnosticHandler {
  FormattingDiagnosticHandler(a);
}
abstract class Platform {
  static var script;
  static var packageRoot;
}
class MemorySourceFileProvider extends SourceFileProvider {
  var readStringFromUri;
  var memorySourceFiles;
  MemorySourceFileProvider(a);
}
class NullSink extends EventSink {
  NullSink(a);
}
var expando;
abstract class EventSink<T> {}

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
