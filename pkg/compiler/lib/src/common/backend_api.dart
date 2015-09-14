// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.backend_api;

import 'dart:async' show Future;

import '../compiler.dart' show
    Compiler;
import '../compile_time_constants.dart' show
    BackendConstantEnvironment,
    ConstantCompilerTask;
import '../constants/constant_system.dart' show
    ConstantSystem;
import '../constants/values.dart' show
    ConstantValue;
import '../dart_types.dart' show
    DartType,
    InterfaceType;
import '../diagnostics/spannable.dart' show
    Spannable,
    SpannableAssertionFailure;
import '../elements/elements.dart' show
    ClassElement,
    ConstructorElement,
    Element,
    FunctionElement,
    LibraryElement,
    MetadataAnnotation;
import '../enqueue.dart' show
    Enqueuer,
    CodegenEnqueuer,
    ResolutionEnqueuer,
    WorldImpact;
import '../io/code_output.dart' show
    CodeBuffer;
import '../io/source_information.dart' show
    SourceInformationStrategy;
import '../js_backend/js_backend.dart' as js_backend show
    JavaScriptBackend;
import '../library_loader.dart' show
    LibraryLoader,
    LoadedLibraries;
import '../native/native.dart' as native show
    NativeEnqueuer;
import '../patch_parser.dart' show
    checkNativeAnnotation;
import '../resolution/tree_elements.dart' show
    TreeElements;

import 'codegen.dart' show
    CodegenWorkItem;
import 'registry.dart' show
    Registry;
import 'resolution.dart' show
    ResolutionCallbacks;
import 'tasks.dart' show
    CompilerTask;
import 'work.dart' show
    ItemCompilationContext;


abstract class Backend {
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

  /// Backend callback methods for the resolution phase.
  ResolutionCallbacks get resolutionCallbacks;

  /// The strategy used for collecting and emitting source information.
  SourceInformationStrategy get sourceInformationStrategy {
    return const SourceInformationStrategy();
  }

  // TODO(johnniwinther): Move this to the JavaScriptBackend.
  String get patchVersion => null;

  /// Set of classes that need to be considered for reflection although not
  /// otherwise visible during resolution.
  Iterable<ClassElement> classesRequiredForReflection = const [];

  // Given a [FunctionElement], return a buffer with the code generated for it
  // or null if no code was generated.
  CodeBuffer codeOf(Element element) => null;

  void initializeHelperClasses() {}

  void enqueueHelpers(ResolutionEnqueuer world, Registry registry);
  WorldImpact codegen(CodegenWorkItem work);

  // The backend determines the native resolution enqueuer, with a no-op
  // default, so tools like dart2dart can ignore the native classes.
  native.NativeEnqueuer nativeResolutionEnqueuer(world) {
    return new native.NativeEnqueuer();
  }
  native.NativeEnqueuer nativeCodegenEnqueuer(world) {
    return new native.NativeEnqueuer();
  }

  /// Generates the output and returns the total size of the generated code.
  int assembleProgram();

  List<CompilerTask> get tasks;

  void onResolutionComplete() {}
  void onTypeInferenceComplete() {}

  ItemCompilationContext createItemCompilationContext() {
    return new ItemCompilationContext();
  }

  bool classNeedsRti(ClassElement cls);
  bool methodNeedsRti(FunctionElement function);

  /// Enable compilation of code with compile time errors. Returns `true` if
  /// supported by the backend.
  bool enableCodegenWithErrorsIfSupported(Spannable node);

  /// Enable deferred loading. Returns `true` if the backend supports deferred
  /// loading.
  bool enableDeferredLoadingIfSupported(Spannable node, Registry registry);

  /// Called during codegen when [constant] has been used.
  void registerCompileTimeConstant(ConstantValue constant, Registry registry) {}

  /// Called during resolution when a constant value for [metadata] on
  /// [annotatedElement] has been evaluated.
  void registerMetadataConstant(MetadataAnnotation metadata,
                                Element annotatedElement,
                                Registry registry) {}

  /// Called to notify to the backend that a class is being instantiated.
  // TODO(johnniwinther): Remove this. It's only called once for each [cls] and
  // only with [Compiler.globalDependencies] as [registry].
  void registerInstantiatedClass(ClassElement cls,
                                 Enqueuer enqueuer,
                                 Registry registry) {}

  /// Called to notify to the backend that an interface type has been
  /// instantiated.
  void registerInstantiatedType(InterfaceType type, Registry registry) {}

  /// Register an is check to the backend.
  void registerIsCheckForCodegen(DartType type,
                                 Enqueuer enqueuer,
                                 Registry registry) {}

  /// Register a runtime type variable bound tests between [typeArgument] and
  /// [bound].
  void registerTypeVariableBoundsSubtypeCheck(DartType typeArgument,
                                              DartType bound) {}

  /// Returns `true` if [element] represent the assert function.
  bool isAssertMethod(Element element) => false;

  /**
   * Call this to register that an instantiated generic class has a call
   * method.
   */
  void registerCallMethodWithFreeTypeVariables(
      Element callMethod,
      Enqueuer enqueuer,
      Registry registry) {}

  /**
   * Call this to register that a getter exists for a function on an
   * instantiated generic class.
   */
  void registerClosureWithFreeTypeVariables(
      Element closure,
      Enqueuer enqueuer,
      Registry registry) {}

  /// Call this to register that a member has been closurized.
  void registerBoundClosure(Enqueuer enqueuer) {}

  /// Call this to register that a static function has been closurized.
  void registerGetOfStaticFunction(Enqueuer enqueuer) {}

  /**
   * Call this to register that the [:runtimeType:] property has been accessed.
   */
  void registerRuntimeType(Enqueuer enqueuer, Registry registry) {}

  /// Call this to register a `noSuchMethod` implementation.
  void registerNoSuchMethod(FunctionElement noSuchMethodElement) {}

  /// Call this method to enable support for `noSuchMethod`.
  void enableNoSuchMethod(Enqueuer enqueuer) {}

  /// Returns whether or not `noSuchMethod` support has been enabled.
  bool get enabledNoSuchMethod => false;

  /// Call this method to enable support for isolates.
  void enableIsolateSupport(Enqueuer enqueuer) {}

  void registerRequiredType(DartType type, Element enclosingElement) {}
  void registerClassUsingVariableExpression(ClassElement cls) {}

  void registerConstSymbol(String name, Registry registry) {}
  void registerNewSymbol(Registry registry) {}

  bool isNullImplementation(ClassElement cls) {
    return cls == compiler.nullClass;
  }

  ClassElement get intImplementation => compiler.intClass;
  ClassElement get doubleImplementation => compiler.doubleClass;
  ClassElement get numImplementation => compiler.numClass;
  ClassElement get stringImplementation => compiler.stringClass;
  ClassElement get listImplementation => compiler.listClass;
  ClassElement get growableListImplementation => compiler.listClass;
  ClassElement get fixedListImplementation => compiler.listClass;
  ClassElement get constListImplementation => compiler.listClass;
  ClassElement get mapImplementation => compiler.mapClass;
  ClassElement get constMapImplementation => compiler.mapClass;
  ClassElement get functionImplementation => compiler.functionClass;
  ClassElement get typeImplementation => compiler.typeClass;
  ClassElement get boolImplementation => compiler.boolClass;
  ClassElement get nullImplementation => compiler.nullClass;
  ClassElement get uint32Implementation => compiler.intClass;
  ClassElement get uint31Implementation => compiler.intClass;
  ClassElement get positiveIntImplementation => compiler.intClass;

  ClassElement defaultSuperclass(ClassElement element) => compiler.objectClass;

  bool isInterceptorClass(ClassElement element) => false;

  /// Returns `true` if [element] is a foreign element, that is, that the
  /// backend has specialized handling for the element.
  bool isForeign(Element element) => false;

  /// Processes [element] for resolution and returns the [FunctionElement] that
  /// defines the implementation of [element].
  FunctionElement resolveExternalFunction(FunctionElement element) => element;

  /// Returns `true` if [library] is a backend specific library whose members
  /// have special treatment, such as being allowed to extends blacklisted
  /// classes or member being eagerly resolved.
  bool isBackendLibrary(LibraryElement library) {
    // TODO(johnniwinther): Remove this when patching is only done by the
    // JavaScript backend.
    Uri canonicalUri = library.canonicalUri;
    if (canonicalUri == js_backend.JavaScriptBackend.DART_JS_HELPER ||
        canonicalUri == js_backend.JavaScriptBackend.DART_INTERCEPTORS) {
      return true;
    }
    return false;
  }

  void registerStaticUse(Element element, Enqueuer enqueuer) {}

  /// This method is called immediately after the [LibraryElement] [library] has
  /// been created.
  void onLibraryCreated(LibraryElement library) {}

  /// This method is called immediately after the [library] and its parts have
  /// been scanned.
  Future onLibraryScanned(LibraryElement library, LibraryLoader loader) {
    if (library.canUseNative) {
      library.forEachLocalMember((Element element) {
        if (element.isClass) {
          checkNativeAnnotation(compiler, element);
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
  void registerMirrorUsage(Set<String> symbols,
                           Set<Element> targets,
                           Set<Element> metaTargets) {}

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
  bool onQueueEmpty(Enqueuer enqueuer, Iterable<ClassElement> recentClasses) {
    return true;
  }

  /// Called after the queue is closed. [onQueueEmpty] may be called multiple
  /// times, but [onQueueClosed] is only called once.
  void onQueueClosed() {}

  /// Called when the compiler starts running the codegen enqueuer.
  void onCodegenStart() {}

  /// Called after [element] has been resolved.
  // TODO(johnniwinther): Change [TreeElements] to [Registry] or a dependency
  // node. [elements] is currently unused by the implementation.
  void onElementResolved(Element element, TreeElements elements) {}

  // Does this element belong in the output
  bool shouldOutput(Element element) => true;

  FunctionElement helperForBadMain() => null;

  FunctionElement helperForMissingMain() => null;

  FunctionElement helperForMainArity() => null;

  void forgetElement(Element element) {}

  void registerMainHasArguments(Enqueuer enqueuer) {}

  void registerAsyncMarker(FunctionElement element,
                           Enqueuer enqueuer,
                           Registry registry) {}
}

