// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.memory_compiler;

import 'package:expect/expect.dart';
import 'memory_source_file_helper.dart';

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
       show NullSink;

import '../../../sdk/lib/_internal/compiler/compiler.dart'
       show DiagnosticHandler;

import 'dart:async';

import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/dart2js_mirror.dart';

Compiler compilerFor(Map<String,String> memorySourceFiles,
                     {DiagnosticHandler diagnosticHandler,
                      List<String> options: const [],
                      Compiler cachedCompiler}) {
  Uri script = currentDirectory.resolve(nativeToUriPath(Platform.script));
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  MemorySourceFileProvider.MEMORY_SOURCE_FILES = memorySourceFiles;
  var provider = new MemorySourceFileProvider();
  if (diagnosticHandler == null) {
    diagnosticHandler = new FormattingDiagnosticHandler(provider);
  }

  EventSink<String> outputProvider(String name, String extension) {
    if (name != '') throw 'Attempt to output file "$name.$extension"';
    return new NullSink('$name.$extension');
  }

  Compiler compiler = new Compiler(provider.readStringFromUri,
                                   outputProvider,
                                   diagnosticHandler,
                                   libraryRoot,
                                   packageRoot,
                                   options);
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
                                      List<String> options: const []}) {
  Uri script = currentDirectory.resolve(nativeToUriPath(Platform.script));
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  MemorySourceFileProvider.MEMORY_SOURCE_FILES = memorySourceFiles;
  var provider = new MemorySourceFileProvider();
  if (diagnosticHandler == null) {
    diagnosticHandler = new FormattingDiagnosticHandler(provider);
  }

  List<Uri> libraries = <Uri>[];
  memorySourceFiles.forEach((String path, _) {
    libraries.add(new Uri(scheme: 'memory', path: path));
  });

  return analyze(libraries, libraryRoot, packageRoot,
                 provider, diagnosticHandler, options);
}
