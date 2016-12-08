// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.backend_api;

import 'dart:async' show Future;

import '../common.dart';
import '../common/codegen.dart' show CodegenImpact;
import '../common/resolution.dart' show ResolutionImpact, Frontend, Target;
import '../compile_time_constants.dart'
    show BackendConstantEnvironment, ConstantCompilerTask;
import '../compiler.dart' show Compiler;
import '../constants/constant_system.dart' show ConstantSystem;
import '../constants/expressions.dart' show ConstantExpression;
import '../constants/values.dart' show ConstantValue;
import '../dart_types.dart' show DartType, InterfaceType;
import '../elements/elements.dart'
    show ClassElement, Element, FunctionElement, MethodElement, LibraryElement;
import '../elements/entities.dart';
import '../enqueue.dart' show Enqueuer, EnqueueTask, ResolutionEnqueuer;
import '../io/code_output.dart' show CodeBuffer;
import '../io/source_information.dart' show SourceInformationStrategy;
import '../js_backend/backend_helpers.dart' as js_backend show BackendHelpers;
import '../js_backend/js_backend.dart' as js_backend;
import '../library_loader.dart' show LibraryLoader, LoadedLibraries;
import '../native/native.dart' as native show NativeEnqueuer, maybeEnableNative;
import '../patch_parser.dart'
    show checkNativeAnnotation, checkJsInteropAnnotation;
import '../serialization/serialization.dart'
    show DeserializerPlugin, SerializerPlugin;
import '../tree/tree.dart' show Node;
import '../universe/world_impact.dart'
    show ImpactStrategy, WorldImpact, WorldImpactBuilder;
import 'codegen.dart' show CodegenWorkItem;
import 'tasks.dart' show CompilerTask;

abstract class Backend extends Target {
  final Compiler compiler;

  Backend(this.compiler);

  /// Returns true if the backend supports reflection.
  bool get supportsReflection;

  /// The [ConstantSystem] used to interpret compile-time constants for this
  /// backend.
  ConstantSystem get constantSystem;

  /// The constant environment for the backend interpretation of compile-time
  /// constants.
  BackendConstantEnvironment get constants;

  /// The compiler task responsible for the compilation of constants for both
  /// the frontend and the backend.
  ConstantCompilerTask get constantCompilerTask;

  /// Backend transformation methods for the world impacts.
  ImpactTransformer get impactTransformer;

  /// The strategy used for collecting and emitting source information.
  SourceInformationStrategy get sourceInformationStrategy {
    return const SourceInformationStrategy();
  }

  /// Common classes used by the backend.
  BackendClasses get backendClasses;

  /// Interface for serialization of backend specific data.
  BackendSerialization get serialization => const BackendSerialization();

  // TODO(johnniwinther): Move this to the JavaScriptBackend.
  String get patchVersion => null;

  /// Set of classes that need to be considered for reflection although not
  /// otherwise visible during resolution.
  Iterable<ClassElement> classesRequiredForReflection = const [];

  // Given a [FunctionElement], return a buffer with the code generated for it
  // or null if no code was generated.
  CodeBuffer codeOf(Element element) => null;

  void initializeHelperClasses() {}

  /// Compute the [WorldImpact] for backend helper methods.
  WorldImpact computeHelpersImpact();

  /// Creates an [Enqueuer] for code generation specific to this backend.
  Enqueuer createCodegenEnqueuer(CompilerTask task, Compiler compiler);

  WorldImpact codegen(CodegenWorkItem work);

  // The backend determines the native resolution enqueuer, with a no-op
  // default, so tools like dart2dart can ignore the native classes.
  native.NativeEnqueuer nativeResolutionEnqueuer() {
    return new native.NativeEnqueuer();
  }

  native.NativeEnqueuer nativeCodegenEnqueuer() {
    return new native.NativeEnqueuer();
  }

  /// Generates the output and returns the total size of the generated code.
  int assembleProgram();

  List<CompilerTask> get tasks;

  void onResolutionComplete() {}
  void onTypeInferenceComplete() {}

  bool classNeedsRti(ClassElement cls);
  bool methodNeedsRti(FunctionElement function);

  /// Enable compilation of code with compile time errors. Returns `true` if
  /// supported by the backend.
  bool enableCodegenWithErrorsIfSupported(Spannable node);

  /// Enable deferred loading. Returns `true` if the backend supports deferred
  /// loading.
  bool enableDeferredLoadingIfSupported(Spannable node);

  /// Returns the [WorldImpact] of enabling deferred loading.
  WorldImpact computeDeferredLoadingImpact() => const WorldImpact();

  /// Called during codegen when [constant] has been used.
  void computeImpactForCompileTimeConstant(ConstantValue constant,
      WorldImpactBuilder impactBuilder, bool isForResolution) {}

  /// Called to notify to the backend that a class is being instantiated. Any
  /// backend specific [WorldImpact] of this is returned.
  WorldImpact registerInstantiatedClass(ClassElement cls,
          {bool forResolution}) =>
      const WorldImpact();

  /// Called to notify to the backend that a class is implemented by an
  /// instantiated class. Any backend specific [WorldImpact] of this is
  /// returned.
  WorldImpact registerImplementedClass(ClassElement cls,
          {bool forResolution}) =>
      const WorldImpact();

  /// Called to instruct to the backend register [type] as instantiated on
  /// [enqueuer].
  void registerInstantiatedType(InterfaceType type) {}

  /// Register a runtime type variable bound tests between [typeArgument] and
  /// [bound].
  void registerTypeVariableBoundsSubtypeCheck(
      DartType typeArgument, DartType bound) {}

  /// Called to register that an instantiated generic class has a call method.
  /// Any backend specific [WorldImpact] of this is returned.
  ///
  /// Note: The [callMethod] is registered even thought it doesn't reference
  /// the type variables.
  WorldImpact registerCallMethodWithFreeTypeVariables(Element callMethod,
          {bool forResolution}) =>
      const WorldImpact();

  /// Called to instruct the backend to register that a closure exists for a
  /// function on an instantiated generic class. Any backend specific
  /// [WorldImpact] of this is returned.
  WorldImpact registerClosureWithFreeTypeVariables(Element closure,
          {bool forResolution}) =>
      const WorldImpact();

  /// Called to register that a member has been closurized. Any backend specific
  /// [WorldImpact] of this is returned.
  WorldImpact registerBoundClosure() => const WorldImpact();

  /// Called to register that a static function has been closurized. Any backend
  /// specific [WorldImpact] of this is returned.
  WorldImpact registerGetOfStaticFunction() => const WorldImpact();

  /// Called to enable support for `noSuchMethod`. Any backend specific
  /// [WorldImpact] of this is returned.
  WorldImpact enableNoSuchMethod() => const WorldImpact();

  /// Returns whether or not `noSuchMethod` support has been enabled.
  bool get enabledNoSuchMethod => false;

  /// Called to enable support for isolates. Any backend specific [WorldImpact]
  /// of this is returned.
  WorldImpact enableIsolateSupport({bool forResolution});

  void registerConstSymbol(String name) {}

  ClassElement defaultSuperclass(ClassElement element) {
    return compiler.coreClasses.objectClass;
  }

  bool isInterceptorClass(ClassElement element) => false;

  /// Returns `true` if [element] is implemented via typed JavaScript interop.
  // TODO(johnniwinther): Move this to [JavaScriptBackend].
  bool isJsInterop(Element element) => false;

  /// Returns `true` if the `native` pseudo keyword is supported for [library].
  bool canLibraryUseNative(LibraryElement library) {
    // TODO(johnniwinther): Move this to [JavaScriptBackend].
    return native.maybeEnableNative(compiler, library);
  }

  @override
  bool isTargetSpecificLibrary(LibraryElement library) {
    // TODO(johnniwinther): Remove this when patching is only done by the
    // JavaScript backend.
    Uri canonicalUri = library.canonicalUri;
    if (canonicalUri == js_backend.BackendHelpers.DART_JS_HELPER ||
        canonicalUri == js_backend.BackendHelpers.DART_INTERCEPTORS) {
      return true;
    }
    return false;
  }

  /// Called to register that [element] is statically known to be used. Any
  /// backend specific [WorldImpact] of this is returned.
  WorldImpact registerUsedElement(Element element, {bool forResolution}) =>
      const WorldImpact();

  /// This method is called immediately after the [LibraryElement] [library] has
  /// been created.
  void onLibraryCreated(LibraryElement library) {}

  /// This method is called immediately after the [library] and its parts have
  /// been scanned.
  Future onLibraryScanned(LibraryElement library, LibraryLoader loader) {
    // TODO(johnniwinther): Move this to [JavaScriptBackend].
    if (!compiler.serialization.isDeserialized(library)) {
      if (canLibraryUseNative(library)) {
        library.forEachLocalMember((Element element) {
          if (element.isClass) {
            checkNativeAnnotation(compiler, element);
          }
        });
      }
      checkJsInteropAnnotation(compiler, library);
      library.forEachLocalMember((Element element) {
        checkJsInteropAnnotation(compiler, element);
        if (element.isClass && isJsInterop(element)) {
          ClassElement classElement = element;
          classElement.forEachMember((_, memberElement) {
            checkJsInteropAnnotation(compiler, memberElement);
          });
        }
      });
    }
    return new Future.value();
  }

  /// This method is called when all new libraries loaded through
  /// [LibraryLoader.loadLibrary] has been loaded and their imports/exports
  /// have been computed.
  Future onLibrariesLoaded(LoadedLibraries loadedLibraries) {
    return new Future.value();
  }

  /// Called by [MirrorUsageAnalyzerTask] after it has merged all @MirrorsUsed
  /// annotations. The arguments corresponds to the unions of the corresponding
  /// fields of the annotations.
  void registerMirrorUsage(
      Set<String> symbols, Set<Element> targets, Set<Element> metaTargets) {}

  /// Returns true if this element needs reflection information at runtime.
  bool isAccessibleByReflection(Element element) => true;

  /// Returns true if this element is covered by a mirrorsUsed annotation.
  ///
  /// Note that it might still be ok to tree shake the element away if no
  /// reflection is used in the program (and thus [isTreeShakingDisabled] is
  /// still false). Therefore _do not_ use this predicate to decide inclusion
  /// in the tree, use [requiredByMirrorSystem] instead.
  bool referencedFromMirrorSystem(Element element, [recursive]) => false;

  /// Returns true if this element has to be enqueued due to
  /// mirror usage. Might be a subset of [referencedFromMirrorSystem] if
  /// normal tree shaking is still active ([isTreeShakingDisabled] is false).
  bool requiredByMirrorSystem(Element element) => false;

  /// Returns true if global optimizations such as type inferencing
  /// can apply to this element. One category of elements that do not
  /// apply is runtime helpers that the backend calls, but the
  /// optimizations don't see those calls.
  bool canBeUsedForGlobalOptimizations(Element element) => true;

  /// Called when [enqueuer]'s queue is empty, but before it is closed.
  /// This is used, for example, by the JS backend to enqueue additional
  /// elements needed for reflection. [recentClasses] is a collection of
  /// all classes seen for the first time by the [enqueuer] since the last call
  /// to [onQueueEmpty].
  ///
  /// A return value of [:true:] indicates that [recentClasses] has been
  /// processed and its elements do not need to be seen in the next round. When
  /// [:false:] is returned, [onQueueEmpty] will be called again once the
  /// resolution queue has drained and [recentClasses] will be a superset of the
  /// current value.
  ///
  /// There is no guarantee that a class is only present once in
  /// [recentClasses], but every class seen by the [enqueuer] will be present in
  /// [recentClasses] at least once.
  bool onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses) {
    return true;
  }

  /// Called after the queue is closed. [onQueueEmpty] may be called multiple
  /// times, but [onQueueClosed] is only called once.
  void onQueueClosed() {}

  /// Called when the compiler starts running the codegen enqueuer. The
  /// [WorldImpact] of enabled backend features is returned.
  WorldImpact onCodegenStart() => const WorldImpact();

  // Does this element belong in the output
  bool shouldOutput(Element element) => true;

  FunctionElement helperForBadMain() => null;

  FunctionElement helperForMissingMain() => null;

  FunctionElement helperForMainArity() => null;

  void forgetElement(Element element) {}

  /// Computes the [WorldImpact] of calling [mainMethod] as the entry point.
  WorldImpact computeMainImpact(MethodElement mainMethod,
          {bool forResolution}) =>
      const WorldImpact();

  /// Returns the location of the patch-file associated with [libraryName]
  /// resolved from [plaformConfigUri].
  ///
  /// Returns null if there is none.
  Uri resolvePatchUri(String libraryName, Uri plaformConfigUri);

  /// Creates an impact strategy to use for compilation.
  ImpactStrategy createImpactStrategy(
      {bool supportDeferredLoad: true,
      bool supportDumpInfo: true,
      bool supportSerialization: true}) {
    return const ImpactStrategy();
  }

  /// Backend access to the front-end.
  Frontend get frontend => compiler.resolution;

  EnqueueTask makeEnqueuer() => new EnqueueTask(compiler);
}

/// Interface for resolving native data for a target specific element.
abstract class NativeRegistry {
  /// Registers [nativeData] as part of the resolution impact.
  void registerNativeData(dynamic nativeData);
}

/// Interface for resolving calls to foreign functions.
abstract class ForeignResolver {
  /// Returns the constant expression of [node], or `null` if [node] is not
  /// a constant expression.
  ConstantExpression getConstant(Node node);

  /// Registers [type] as instantiated.
  void registerInstantiatedType(InterfaceType type);

  /// Resolves [typeName] to a type in the context of [node].
  DartType resolveTypeFromString(Node node, String typeName);
}

/// Backend transformation methods for the world impacts.
class ImpactTransformer {
  /// Transform the [ResolutionImpact] into a [WorldImpact] adding the
  /// backend dependencies for features used in [worldImpact].
  WorldImpact transformResolutionImpact(
      ResolutionEnqueuer enqueuer, ResolutionImpact worldImpact) {
    return worldImpact;
  }

  /// Transform the [CodegenImpact] into a [WorldImpact] adding the
  /// backend dependencies for features used in [worldImpact].
  WorldImpact transformCodegenImpact(CodegenImpact worldImpact) {
    return worldImpact;
  }
}

/// Interface for serialization of backend specific data.
class BackendSerialization {
  const BackendSerialization();

  SerializerPlugin get serializer => const SerializerPlugin();
  DeserializerPlugin get deserializer => const DeserializerPlugin();
}

/// Interface providing access to core classes used by the backend.
abstract class BackendClasses {
  ClassElement get intImplementation;
  ClassElement get doubleImplementation;
  ClassElement get numImplementation;
  ClassElement get stringImplementation;
  ClassElement get listImplementation;
  ClassElement get growableListImplementation;
  ClassElement get fixedListImplementation;
  ClassElement get constListImplementation;
  ClassElement get mapImplementation;
  ClassElement get constMapImplementation;
  ClassElement get functionImplementation;
  ClassElement get typeImplementation;
  ClassElement get boolImplementation;
  ClassElement get nullImplementation;
  ClassElement get uint32Implementation;
  ClassElement get uint31Implementation;
  ClassElement get positiveIntImplementation;
  ClassElement get syncStarIterableImplementation;
  ClassElement get asyncFutureImplementation;
  ClassElement get asyncStarStreamImplementation;
}
