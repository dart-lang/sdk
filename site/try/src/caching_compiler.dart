// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.caching_compiler;

import 'dart:profiler' show
    UserTag;

import 'package:compiler/compiler.dart' show
    CompilerInputProvider,
    CompilerOutputProvider,
    Diagnostic,
    DiagnosticHandler;

import 'package:compiler/implementation/apiimpl.dart' show
    Compiler;

import 'package:compiler/implementation/dart2jslib.dart' show
    LibraryLoaderTask, // TODO(ahe): Remove this import.
    NullSink;

import 'package:compiler/implementation/js_backend/js_backend.dart' show
    JavaScriptBackend;

import 'package:compiler/implementation/elements/elements.dart' show
    LibraryElement;

void clearLibraryLoader(LibraryLoaderTask libraryLoader) {
  // TODO(ahe): Move this method to [LibraryLoader].
  libraryLoader
      ..libraryResourceUriMap.clear()
      ..libraryNames.clear();
}

void reuseLibrary(
    LibraryLoaderTask libraryLoader,
    LibraryElement library) {
  // TODO(ahe): Move this method to [LibraryLoader].
  String name = library.getLibraryOrScriptName();
  Uri resourceUri = library.entryCompilationUnit.script.resourceUri;
  libraryLoader
      ..libraryResourceUriMap[resourceUri] = library
      ..libraryNames[name] = library;
}

Compiler reuseCompiler(
    {DiagnosticHandler diagnosticHandler,
     CompilerInputProvider inputProvider,
     CompilerOutputProvider outputProvider,
     List<String> options: const [],
     Compiler cachedCompiler,
     Uri libraryRoot,
     Uri packageRoot,
     bool packagesAreImmutable: false}) {
  UserTag oldTag = new UserTag('reuseCompiler').makeCurrent();
  if (libraryRoot == null) {
    throw 'Missing libraryRoot';
  }
  if (inputProvider == null) {
    throw 'Missing inputProvider';
  }
  if (diagnosticHandler == null) {
    throw 'Missing diagnosticHandler';
  }
  if (outputProvider == null) {
    outputProvider = NullSink.outputProvider;
  }
  Compiler compiler = cachedCompiler;
  if (compiler == null ||
      compiler.libraryRoot != libraryRoot ||
      !compiler.hasIncrementalSupport ||
      compiler.hasCrashed ||
      compiler.compilerWasCancelled ||
      compiler.enqueuer.resolution.hasEnqueuedEverything ||
      compiler.deferredLoadTask.splitProgram) {
    if (compiler != null && compiler.hasIncrementalSupport) {
      print('***FLUSH***');
      if (compiler.hasCrashed) {
        print('Unable to reuse compiler due to crash.');
      } else if (compiler.compilerWasCancelled) {
        print('Unable to reuse compiler due to cancel.');
      } else if (compiler.enqueuer.resolution.hasEnqueuedEverything) {
        print('Unable to reuse compiler due to dart:mirrors.');
      } else if (compiler.deferredLoadTask.splitProgram) {
        print('Unable to reuse compiler due to deferred loading.');
      } else {
        print('Unable to reuse compiler.');
      }
    }
    compiler = new Compiler(
        inputProvider,
        outputProvider,
        diagnosticHandler,
        libraryRoot,
        packageRoot,
        options,
        {});
  } else {
    compiler
        ..outputProvider = outputProvider
        ..provider = inputProvider
        ..handler = diagnosticHandler
        ..enqueuer.resolution.queueIsClosed = false
        ..enqueuer.resolution.hasEnqueuedEverything = false
        ..enqueuer.resolution.hasEnqueuedReflectiveStaticFields = false
        ..enqueuer.codegen.queueIsClosed = false
        ..enqueuer.codegen.hasEnqueuedEverything = false
        ..enqueuer.codegen.hasEnqueuedReflectiveStaticFields = false
        ..assembledCode = null
        ..compilationFailed = false;
    JavaScriptBackend backend = compiler.backend;

    backend.emitter.cachedElements.addAll(backend.generatedCode.keys);

    compiler.enqueuer.codegen.newlyEnqueuedElements.clear();

    backend.emitter.containerBuilder
        ..staticGetters.clear()
        ..methodClosures.clear();

    backend.emitter.nsmEmitter
        ..trivialNsmHandlers.clear();

    backend.emitter.typeTestEmitter
        ..checkedClasses = null
        ..checkedFunctionTypes = null
        ..checkedGenericFunctionTypes.clear()
        ..checkedNonGenericFunctionTypes.clear()
        ..rtiNeededClasses.clear()
        ..cachedClassesUsingTypeVariableTests = null;

    backend.emitter.interceptorEmitter
        ..interceptorInvocationNames.clear();

    backend.emitter.metadataEmitter
        ..globalMetadata.clear()
        ..globalMetadataMap.clear();

    backend.emitter.nativeEmitter
        ..nativeBuffer.clear()
        ..nativeClasses.clear()
        ..nativeMethods.clear();

    backend.emitter
        ..outputBuffers.clear()
        ..deferredConstants.clear()
        ..isolateProperties = null
        ..classesCollector = null
        ..neededClasses.clear()
        ..outputClassLists.clear()
        ..nativeClasses.clear()
        ..mangledFieldNames.clear()
        ..mangledGlobalFieldNames.clear()
        ..recordedMangledNames.clear()
        ..additionalProperties.clear()
        ..readTypeVariables.clear()
        ..instantiatedClasses = null
        ..precompiledFunction.clear()
        ..precompiledConstructorNames.clear()
        ..hasMakeConstantList = false
        ..elementDescriptors.clear();

    backend
        ..preMirrorsMethodCount = 0;

    Map libraries = new Map.from(compiler.libraries);
    compiler.libraries.clear();
    clearLibraryLoader(compiler.libraryLoader);
    libraries.forEach((String uri, LibraryElement library) {
      if (library.isPlatformLibrary ||
          (packagesAreImmutable && library.isPackageLibrary)) {
        compiler.libraries[uri] = library;
        reuseLibrary(compiler.libraryLoader, library);
      }
    });
  }
  oldTag.makeCurrent();
  return compiler;
}
