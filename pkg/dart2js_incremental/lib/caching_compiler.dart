// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js_incremental;

/// Do not call this method directly. It will be made private.
// TODO(ahe): Make this method private.
Future<Compiler> reuseCompiler(
    {DiagnosticHandler diagnosticHandler,
     CompilerInputProvider inputProvider,
     CompilerOutputProvider outputProvider,
     List<String> options: const [],
     Compiler cachedCompiler,
     Uri libraryRoot,
     Uri packageRoot,
     bool packagesAreImmutable: false,
     Map<String, dynamic> environment,
     Future<bool> reuseLibrary(LibraryElement library)}) {
  UserTag oldTag = new UserTag('_reuseCompiler').makeCurrent();
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
  if (environment == null) {
    environment = {};
  }
  Compiler compiler = cachedCompiler;
  if (compiler == null ||
      compiler.libraryRoot != libraryRoot ||
      !compiler.hasIncrementalSupport ||
      compiler.hasCrashed ||
      compiler.enqueuer.resolution.hasEnqueuedReflectiveElements ||
      compiler.deferredLoadTask.isProgramSplit) {
    if (compiler != null && compiler.hasIncrementalSupport) {
      print('***FLUSH***');
      if (compiler.hasCrashed) {
        print('Unable to reuse compiler due to crash.');
      } else if (compiler.enqueuer.resolution.hasEnqueuedReflectiveElements) {
        print('Unable to reuse compiler due to dart:mirrors.');
      } else if (compiler.deferredLoadTask.isProgramSplit) {
        print('Unable to reuse compiler due to deferred loading.');
      } else {
        print('Unable to reuse compiler.');
      }
    }
    oldTag.makeCurrent();
    compiler = new Compiler(
        inputProvider,
        outputProvider,
        diagnosticHandler,
        libraryRoot,
        packageRoot,
        options,
        environment,
        null,
        null);
    JavaScriptBackend backend = compiler.backend;

    // Much like a scout, an incremental compiler is always prepared. For
    // mixins, classes, and lazy statics, at least.
    backend.emitter.oldEmitter
        ..needsClassSupport = true
        ..needsMixinSupport = true
        ..needsLazyInitializer = true
        ..needsStructuredMemberInfo = true;

    Uri core = Uri.parse("dart:core");
    return compiler.libraryLoader.loadLibrary(core).then((_) {
      // Likewise, always be prepared for runtimeType support.
      // TODO(johnniwinther): Add global switch to force RTI.
      compiler.enabledRuntimeType = true;
      backend.registerRuntimeType(
          compiler.enqueuer.resolution, compiler.globalDependencies);
      return compiler;
    });
  } else {
    for (final task in compiler.tasks) {
      if (task.watch != null) {
        task.watch.reset();
      }
    }
    compiler
        ..userOutputProvider = outputProvider
        ..provider = inputProvider
        ..handler = diagnosticHandler
        ..enqueuer.resolution.queueIsClosed = false
        ..enqueuer.resolution.hasEnqueuedReflectiveElements = false
        ..enqueuer.resolution.hasEnqueuedReflectiveStaticFields = false
        ..enqueuer.codegen.queueIsClosed = false
        ..enqueuer.codegen.hasEnqueuedReflectiveElements = false
        ..enqueuer.codegen.hasEnqueuedReflectiveStaticFields = false
        ..compilationFailed = false;
    JavaScriptBackend backend = compiler.backend;

    // TODO(ahe): Seems this cache only serves to tell
    // [OldEmitter.invalidateCaches] if it was invoked on a full compile (in
    // which case nothing should be invalidated), or if it is an incremental
    // compilation (in which case, holders/owners of newly compiled methods
    // must be invalidated).
    backend.emitter.oldEmitter.cachedElements.add(null);

    compiler.enqueuer.codegen
        ..newlyEnqueuedElements.clear()
        ..newlySeenSelectors.clear();

    backend.emitter.oldEmitter.nsmEmitter
        ..trivialNsmHandlers.clear();

    backend.emitter.typeTestRegistry
        ..checkedClasses = null
        ..checkedFunctionTypes = null
        ..rtiNeededClasses.clear()
        ..cachedClassesUsingTypeVariableTests = null;

    backend.emitter.oldEmitter.interceptorEmitter
        ..interceptorInvocationNames.clear();

    backend.emitter.nativeEmitter
        ..hasNativeClasses = false
        ..nativeMethods.clear();

    backend.emitter.readTypeVariables.clear();

    backend.emitter.oldEmitter
        ..outputBuffers.clear()
        ..classesCollector = null
        ..mangledFieldNames.clear()
        ..mangledGlobalFieldNames.clear()
        ..recordedMangledNames.clear()
        ..clearCspPrecompiledNodes()
        ..elementDescriptors.clear();

    backend.emitter
        ..nativeClassesAndSubclasses.clear()
        ..outputContainsConstantList = false
        ..neededClasses.clear()
        ..outputClassLists.clear()
        ..outputConstantLists.clear()
        ..outputStaticLists.clear()
        ..outputStaticNonFinalFieldLists.clear()
        ..outputLibraryLists.clear();

    backend
        ..preMirrorsMethodCount = 0;

    if (reuseLibrary == null) {
      reuseLibrary = (LibraryElement library) {
        return new Future.value(
            library.isPlatformLibrary ||
            (packagesAreImmutable && library.isPackageLibrary));
      };
    }
    return compiler.libraryLoader.resetAsync(reuseLibrary).then((_) {
      oldTag.makeCurrent();
      return compiler;
    });
  }
}

/// Helper class to collect sources.
class StringEventSink implements EventSink<String> {
  List<String> data = <String>[];

  final Function onClose;

  StringEventSink(this.onClose);

  void add(String event) {
    if (data == null) throw 'StringEventSink is closed.';
    data.add(event);
  }

  void addError(errorEvent, [StackTrace stackTrace]) {
    throw 'addError($errorEvent, $stackTrace)';
  }

  void close() {
    if (data != null) {
      onClose(data.join());
      data = null;
    }
  }
}

/// Output provider which collect output in [output].
class OutputProvider {
  final Map<String, String> output = new Map<String, String>();

  EventSink<String> call(String name, String extension) {
    return new StringEventSink((String data) {
      output['$name.$extension'] = data;
    });
  }

  String operator[] (String key) => output[key];
}
