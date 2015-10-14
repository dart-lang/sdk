// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.compiler_base;

import 'dart:async' show
    EventSink,
    Future;

import '../compiler_new.dart' as api;
import 'cache_strategy.dart' show
    CacheStrategy;
import 'closure.dart' as closureMapping show
    ClosureTask;
import 'common.dart';
import 'common/backend_api.dart' show
    Backend;
import 'common/codegen.dart' show
    CodegenRegistry,
    CodegenWorkItem;
import 'common/names.dart' show
    Identifiers,
    Uris;
import 'common/registry.dart' show
    Registry;
import 'common/resolution.dart' show
    Parsing,
    Resolution,
    ResolutionWorkItem,
    ResolutionImpact;
import 'common/tasks.dart' show
    CompilerTask,
    GenericTask;
import 'common/work.dart' show
    WorkItem;
import 'compile_time_constants.dart';
import 'constants/values.dart';
import 'core_types.dart' show
    CoreTypes;
import 'dart_backend/dart_backend.dart' as dart_backend;
import 'dart_types.dart' show
    DartType,
    DynamicType,
    InterfaceType,
    Types;
import 'deferred_load.dart' show DeferredLoadTask, OutputUnit;
import 'diagnostics/code_location.dart';
import 'diagnostics/diagnostic_listener.dart' show
    DiagnosticOptions;
import 'diagnostics/invariant.dart' show
    REPORT_EXCESS_RESOLUTION;
import 'diagnostics/messages.dart' show
    Message,
    MessageTemplate;
import 'dump_info.dart' show
    DumpInfoTask;
import 'elements/elements.dart';
import 'elements/modelx.dart' show
    ErroneousElementX,
    ClassElementX,
    CompilationUnitElementX,
    DeferredLoaderGetterElementX,
    MethodElementX,
    LibraryElementX,
    PrefixElementX;
import 'enqueue.dart' show
    CodegenEnqueuer,
    Enqueuer,
    EnqueueTask,
    ResolutionEnqueuer,
    QueueFilter,
    WorldImpact;
import 'io/source_information.dart' show
    SourceInformation;
import 'js_backend/js_backend.dart' as js_backend show
    JavaScriptBackend;
import 'library_loader.dart' show
    LibraryLoader,
    LibraryLoaderTask,
    LoadedLibraries;
import 'mirrors_used.dart' show
    MirrorUsageAnalyzerTask;
import 'null_compiler_output.dart' show
    NullCompilerOutput,
    NullSink;
import 'parser/diet_parser_task.dart' show
    DietParserTask;
import 'parser/parser_task.dart' show
    ParserTask;
import 'patch_parser.dart' show
    PatchParserTask;
import 'resolution/registry.dart' show
    ResolutionRegistry;
import 'resolution/resolution.dart' show
    ResolverTask;
import 'resolution/tree_elements.dart' show
    TreeElementMapping;
import 'scanner/scanner_task.dart' show
    ScannerTask;
import 'serialization/task.dart' show
    SerializationTask;
import 'script.dart' show
    Script;
import 'ssa/ssa.dart' show
    HInstruction;
import 'tracer.dart' show
    Tracer;
import 'tokens/token.dart' show
    StringToken,
    Token,
    TokenPair;
import 'tokens/token_constants.dart' as Tokens show
    COMMENT_TOKEN,
    EOF_TOKEN;
import 'tokens/token_map.dart' show
    TokenMap;
import 'tree/tree.dart' show
    Node,
    TypeAnnotation;
import 'typechecker.dart' show
    TypeCheckerTask;
import 'types/types.dart' as ti;
import 'universe/call_structure.dart' show
    CallStructure;
import 'universe/selector.dart' show
    Selector;
import 'universe/universe.dart' show
    Universe;
import 'util/util.dart' show
    Link,
    Setlet;
import 'world.dart' show
    World;

abstract class Compiler {

  final Stopwatch totalCompileTime = new Stopwatch();
  int nextFreeClassId = 0;
  World world;
  Types types;
  _CompilerCoreTypes _coreTypes;
  _CompilerDiagnosticReporter _reporter;
  _CompilerResolution _resolution;
  _CompilerParsing _parsing;

  final CacheStrategy cacheStrategy;

  /**
   * Map from token to the first preceding comment token.
   */
  final TokenMap commentMap = new TokenMap();

  /**
   * Records global dependencies, that is, dependencies that don't
   * correspond to a particular element.
   *
   * We should get rid of this and ensure that all dependencies are
   * associated with a particular element.
   */
  GlobalDependencyRegistry globalDependencies;

  /**
   * Dependencies that are only included due to mirrors.
   *
   * We should get rid of this and ensure that all dependencies are
   * associated with a particular element.
   */
  // TODO(johnniwinther): This should not be a [ResolutionRegistry].
  final Registry mirrorDependencies =
      new ResolutionRegistry(null, new TreeElementMapping(null));

  final bool enableMinification;

  final bool useFrequencyNamer;

  /// When `true` emits URIs in the reflection metadata.
  final bool preserveUris;

  final bool enableTypeAssertions;
  final bool enableUserAssertions;
  final bool trustTypeAnnotations;
  final bool trustPrimitives;
  final bool disableTypeInferenceFlag;
  final Uri deferredMapUri;
  final bool dumpInfo;
  final bool useContentSecurityPolicy;
  final bool enableExperimentalMirrors;
  final bool enableAssertMessage;

  /**
   * The maximum size of a concrete type before it widens to dynamic during
   * concrete type inference.
   */
  final int maxConcreteTypeSize;
  final bool analyzeAllFlag;
  final bool analyzeOnly;

  /// If true, disable tree-shaking for the main script.
  final bool analyzeMain;

  /**
   * If true, skip analysis of method bodies and field initializers. Implies
   * [analyzeOnly].
   */
  final bool analyzeSignaturesOnly;
  final bool enableNativeLiveTypeAnalysis;

  /**
   * If true, stop compilation after type inference is complete. Used for
   * debugging and testing purposes only.
   */
  bool stopAfterTypeInference = false;

  /**
   * If [:true:], comment tokens are collected in [commentMap] during scanning.
   */
  final bool preserveComments;

  /// Use the new CPS based backend end.  This flag works for both the Dart and
  /// JavaScript backend.
  final bool useCpsIr;

  /**
   * Is the compiler in verbose mode.
   */
  final bool verbose;

  /**
   * URI of the main source map if the compiler is generating source
   * maps.
   */
  final Uri sourceMapUri;

  /**
   * URI of the main output if the compiler is generating source maps.
   */
  final Uri outputUri;

  /// If `true`, some values are cached for reuse in incremental compilation.
  /// Incremental compilation is basically calling [run] more than once.
  final bool hasIncrementalSupport;

  /// If `true` native extension syntax is supported by the frontend.
  final bool allowNativeExtensions;

  /// Output provider from user of Compiler API.
  api.CompilerOutput userOutputProvider;

  /// Generate output even when there are compile-time errors.
  final bool generateCodeWithCompileTimeErrors;

  /// The compiler is run from the build bot.
  final bool testMode;

  bool disableInlining = false;

  List<Uri> librariesToAnalyzeWhenRun;

  /// The set of platform libraries reported as unsupported.
  ///
  /// For instance when importing 'dart:io' without '--categories=Server'.
  Set<Uri> disallowedLibraryUris = new Setlet<Uri>();

  Tracer tracer;

  CompilerTask measuredTask;
  LibraryElement coreLibrary;
  LibraryElement asyncLibrary;

  LibraryElement mainApp;
  FunctionElement mainFunction;

  /// Initialized when dart:mirrors is loaded.
  LibraryElement mirrorsLibrary;

  /// Initialized when dart:typed_data is loaded.
  LibraryElement typedDataLibrary;

  ClassElement get objectClass => _coreTypes.objectClass;
  ClassElement get boolClass => _coreTypes.boolClass;
  ClassElement get numClass => _coreTypes.numClass;
  ClassElement get intClass => _coreTypes.intClass;
  ClassElement get doubleClass => _coreTypes.doubleClass;
  ClassElement get resourceClass => _coreTypes.resourceClass;
  ClassElement get stringClass => _coreTypes.stringClass;
  ClassElement get functionClass => _coreTypes.functionClass;
  ClassElement get nullClass => _coreTypes.nullClass;
  ClassElement get listClass => _coreTypes.listClass;
  ClassElement get typeClass => _coreTypes.typeClass;
  ClassElement get mapClass => _coreTypes.mapClass;
  ClassElement get symbolClass => _coreTypes.symbolClass;
  ClassElement get stackTraceClass => _coreTypes.stackTraceClass;
  ClassElement get futureClass => _coreTypes.futureClass;
  ClassElement get iterableClass => _coreTypes.iterableClass;
  ClassElement get streamClass => _coreTypes.streamClass;

  DiagnosticReporter get reporter => _reporter;
  CoreTypes get coreTypes => _coreTypes;
  Resolution get resolution => _resolution;
  Parsing get parsing => _parsing;

  ClassElement typedDataClass;

  /// The constant for the [proxy] variable defined in dart:core.
  ConstantValue proxyConstant;

  // TODO(johnniwinther): Move this to the JavaScriptBackend.
  /// The class for patch annotation defined in dart:_js_helper.
  ClassElement patchAnnotationClass;

  // TODO(johnniwinther): Move this to the JavaScriptBackend.
  ClassElement nativeAnnotationClass;

  // Initialized after symbolClass has been resolved.
  FunctionElement symbolConstructor;

  // Initialized when dart:mirrors is loaded.
  ClassElement mirrorSystemClass;

  // Initialized when dart:mirrors is loaded.
  ClassElement mirrorsUsedClass;

  // Initialized after mirrorSystemClass has been resolved.
  FunctionElement mirrorSystemGetNameFunction;

  // Initialized when dart:_internal is loaded.
  ClassElement symbolImplementationClass;

  // Initialized when symbolImplementationClass has been resolved.
  FunctionElement symbolValidatedConstructor;

  // Initialized when mirrorsUsedClass has been resolved.
  FunctionElement mirrorsUsedConstructor;

  // Initialized when dart:mirrors is loaded.
  ClassElement deferredLibraryClass;

  /// Document class from dart:mirrors.
  ClassElement documentClass;
  Element identicalFunction;
  Element loadLibraryFunction;
  Element functionApplyMethod;

  /// The [int.fromEnvironment] constructor.
  ConstructorElement intEnvironment;

  /// The [bool.fromEnvironment] constructor.
  ConstructorElement boolEnvironment;

  /// The [String.fromEnvironment] constructor.
  ConstructorElement stringEnvironment;

  /// Tracks elements with compile-time errors.
  final Set<Element> elementsWithCompileTimeErrors = new Set<Element>();

  fromEnvironment(String name) => null;

  Element get currentElement => _reporter.currentElement;

  List<CompilerTask> tasks;
  ScannerTask scanner;
  DietParserTask dietParser;
  ParserTask parser;
  PatchParserTask patchParser;
  LibraryLoaderTask libraryLoader;
  SerializationTask serialization;
  ResolverTask resolver;
  closureMapping.ClosureTask closureToClassMapper;
  TypeCheckerTask checker;
  ti.TypesTask typesTask;
  Backend backend;

  GenericTask reuseLibraryTask;

  /// The constant environment for the frontend interpretation of compile-time
  /// constants.
  ConstantEnvironment constants;

  EnqueueTask enqueuer;
  DeferredLoadTask deferredLoadTask;
  MirrorUsageAnalyzerTask mirrorUsageAnalyzerTask;
  DumpInfoTask dumpInfoTask;
  String buildId;

  /// A customizable filter that is applied to enqueued work items.
  QueueFilter enqueuerFilter = new QueueFilter();

  final Selector symbolValidatedConstructorSelector = new Selector.call(
      const PublicName('validated'), CallStructure.ONE_ARG);

  static const String CREATE_INVOCATION_MIRROR =
      'createInvocationMirror';

  static const String UNDETERMINED_BUILD_ID =
      "build number could not be determined";

  bool enabledRuntimeType = false;
  bool enabledFunctionApply = false;
  bool enabledInvokeOn = false;
  bool hasIsolateSupport = false;

  bool get hasCrashed => _reporter.hasCrashed;

  Stopwatch progress;

  bool get shouldPrintProgress {
    return verbose && progress.elapsedMilliseconds > 500;
  }

  static const int PHASE_SCANNING = 0;
  static const int PHASE_RESOLVING = 1;
  static const int PHASE_DONE_RESOLVING = 2;
  static const int PHASE_COMPILING = 3;
  int phase;

  bool compilationFailedInternal = false;

  bool get compilationFailed => compilationFailedInternal;

  void set compilationFailed(bool value) {
    if (value) {
      elementsWithCompileTimeErrors.add(currentElement);
    }
    compilationFailedInternal = value;
  }

  /// Set by the backend if real reflection is detected in use of dart:mirrors.
  bool disableTypeInferenceForMirrors = false;

  Compiler({this.enableTypeAssertions: false,
            this.enableUserAssertions: false,
            this.trustTypeAnnotations: false,
            this.trustPrimitives: false,
            bool disableTypeInferenceFlag: false,
            this.maxConcreteTypeSize: 5,
            this.enableMinification: false,
            this.preserveUris: false,
            this.enableNativeLiveTypeAnalysis: false,
            bool emitJavaScript: true,
            bool dart2dartMultiFile: false,
            bool generateSourceMap: true,
            bool analyzeAllFlag: false,
            bool analyzeOnly: false,
            this.analyzeMain: false,
            bool analyzeSignaturesOnly: false,
            this.preserveComments: false,
            this.useCpsIr: false,
            this.useFrequencyNamer: false,
            this.verbose: false,
            this.sourceMapUri: null,
            this.outputUri: null,
            this.buildId: UNDETERMINED_BUILD_ID,
            this.deferredMapUri: null,
            this.dumpInfo: false,
            bool useStartupEmitter: false,
            this.useContentSecurityPolicy: false,
            bool hasIncrementalSupport: false,
            this.enableExperimentalMirrors: false,
            this.enableAssertMessage: false,
            this.allowNativeExtensions: false,
            this.generateCodeWithCompileTimeErrors: false,
            this.testMode: false,
            DiagnosticOptions diagnosticOptions,
            api.CompilerOutput outputProvider,
            List<String> strips: const []})
      : this.disableTypeInferenceFlag =
          disableTypeInferenceFlag || !emitJavaScript,
        this.analyzeOnly =
            analyzeOnly || analyzeSignaturesOnly || analyzeAllFlag,
        this.analyzeSignaturesOnly = analyzeSignaturesOnly,
        this.analyzeAllFlag = analyzeAllFlag,
        this.hasIncrementalSupport = hasIncrementalSupport,
        cacheStrategy = new CacheStrategy(hasIncrementalSupport),
        this.userOutputProvider = outputProvider == null
            ? const NullCompilerOutput() : outputProvider {
    if (hasIncrementalSupport) {
      // TODO(ahe): This is too much. Any method from platform and package
      // libraries can be inlined.
      disableInlining = true;
    }
    world = new World(this);
    // TODO(johnniwinther): Initialize core types in [initializeCoreClasses] and
    // make its field final.
    _reporter = new _CompilerDiagnosticReporter(this, diagnosticOptions);
    _parsing = new _CompilerParsing(this);
    _resolution = new _CompilerResolution(this);
    _coreTypes = new _CompilerCoreTypes(_resolution);
    types = new Types(_resolution);
    tracer = new Tracer(this, this.outputProvider);

    if (verbose) {
      progress = new Stopwatch()..start();
    }

    // TODO(johnniwinther): Separate the dependency tracking from the enqueuing
    // for global dependencies.
    globalDependencies = new GlobalDependencyRegistry(this);

    if (emitJavaScript) {
      js_backend.JavaScriptBackend jsBackend =
          new js_backend.JavaScriptBackend(
              this, generateSourceMap: generateSourceMap,
              useStartupEmitter: useStartupEmitter);
      backend = jsBackend;
    } else {
      backend = new dart_backend.DartBackend(this, strips,
                                             multiFile: dart2dartMultiFile);
      if (dumpInfo) {
        throw new ArgumentError('--dump-info is not supported for dart2dart.');
      }
    }

    tasks = [
      libraryLoader = new LibraryLoaderTask(this),
      serialization = new SerializationTask(this),
      scanner = new ScannerTask(this),
      dietParser = new DietParserTask(this),
      parser = new ParserTask(this),
      patchParser = new PatchParserTask(this),
      resolver = new ResolverTask(this, backend.constantCompilerTask),
      closureToClassMapper = new closureMapping.ClosureTask(this),
      checker = new TypeCheckerTask(this),
      typesTask = new ti.TypesTask(this),
      constants = backend.constantCompilerTask,
      deferredLoadTask = new DeferredLoadTask(this),
      mirrorUsageAnalyzerTask = new MirrorUsageAnalyzerTask(this),
      enqueuer = new EnqueueTask(this),
      dumpInfoTask = new DumpInfoTask(this),
      reuseLibraryTask = new GenericTask('Reuse library', this),
    ];

    tasks.addAll(backend.tasks);
  }

  Universe get resolverWorld => enqueuer.resolution.universe;
  Universe get codegenWorld => enqueuer.codegen.universe;

  bool get hasBuildId => buildId != UNDETERMINED_BUILD_ID;

  bool get analyzeAll => analyzeAllFlag || compileAll;

  bool get compileAll => false;

  bool get disableTypeInference {
    return disableTypeInferenceFlag || compilationFailed;
  }

  int getNextFreeClassId() => nextFreeClassId++;

  void unimplemented(Spannable spannable, String methodName) {
    reporter.internalError(spannable, "$methodName not implemented.");
  }

  Future<bool> run(Uri uri) {
    totalCompileTime.start();

    return new Future.sync(() => runCompiler(uri))
        .catchError((error) => _reporter.onError(uri, error))
        .whenComplete(() {
      tracer.close();
      totalCompileTime.stop();
    }).then((_) {
      return !compilationFailed;
    });
  }

  /// This method is called immediately after the [LibraryElement] [library] has
  /// been created.
  ///
  /// Use this callback method to store references to specific libraries.
  /// Note that [library] has not been scanned yet, nor has its imports/exports
  /// been resolved.
  void onLibraryCreated(LibraryElement library) {
    Uri uri = library.canonicalUri;
    if (uri == Uris.dart_core) {
      coreLibrary = library;
    } else if (uri == Uris.dart__native_typed_data) {
      typedDataLibrary = library;
    } else if (uri == Uris.dart_mirrors) {
      mirrorsLibrary = library;
    }
    backend.onLibraryCreated(library);
  }

  /// This method is called immediately after the [library] and its parts have
  /// been scanned.
  ///
  /// Use this callback method to store references to specific member declared
  /// in certain libraries. Note that [library] has not been patched yet, nor
  /// has its imports/exports been resolved.
  ///
  /// Use [loader] to register the creation and scanning of a patch library
  /// for [library].
  Future onLibraryScanned(LibraryElement library, LibraryLoader loader) {
    Uri uri = library.canonicalUri;
    if (uri == Uris.dart_core) {
      initializeCoreClasses();
      identicalFunction = coreLibrary.find('identical');
    } else if (uri == Uris.dart__internal) {
      symbolImplementationClass = findRequiredElement(library, 'Symbol');
    } else if (uri == Uris.dart_mirrors) {
      mirrorSystemClass = findRequiredElement(library, 'MirrorSystem');
      mirrorsUsedClass = findRequiredElement(library, 'MirrorsUsed');
    } else if (uri == Uris.dart_async) {
      asyncLibrary = library;
      deferredLibraryClass = findRequiredElement(library, 'DeferredLibrary');
      _coreTypes.futureClass = findRequiredElement(library, 'Future');
      _coreTypes.streamClass = findRequiredElement(library, 'Stream');
    } else if (uri == Uris.dart__native_typed_data) {
      typedDataClass = findRequiredElement(library, 'NativeTypedData');
    } else if (uri == js_backend.JavaScriptBackend.DART_JS_HELPER) {
      patchAnnotationClass = findRequiredElement(library, '_Patch');
      nativeAnnotationClass = findRequiredElement(library, 'Native');
    }
    return backend.onLibraryScanned(library, loader);
  }

  /// Compute the set of distinct import chains to the library at [uri] within
  /// [loadedLibraries].
  ///
  /// The chains are strings of the form
  ///
  ///       <main-uri> => <intermediate-uri1> => <intermediate-uri2> => <uri>
  ///
  Set<String> computeImportChainsFor(LoadedLibraries loadedLibraries, Uri uri) {
    // TODO(johnniwinther): Move computation of dependencies to the library
    // loader.
    Uri rootUri = loadedLibraries.rootUri;
    Set<String> importChains = new Set<String>();
    // The maximum number of full imports chains to process.
    final int chainLimit = 10000;
    // The maximum number of imports chains to show.
    final int compactChainLimit = verbose ? 20 : 10;
    int chainCount = 0;
    loadedLibraries.forEachImportChain(uri,
        callback: (Link<Uri> importChainReversed) {
      Link<CodeLocation> compactImportChain = const Link<CodeLocation>();
      CodeLocation currentCodeLocation =
          new UriLocation(importChainReversed.head);
      compactImportChain = compactImportChain.prepend(currentCodeLocation);
      for (Link<Uri> link = importChainReversed.tail;
           !link.isEmpty;
           link = link.tail) {
        Uri uri = link.head;
        if (!currentCodeLocation.inSameLocation(uri)) {
          currentCodeLocation =
              verbose ? new UriLocation(uri) : new CodeLocation(uri);
          compactImportChain =
              compactImportChain.prepend(currentCodeLocation);
        }
      }
      String importChain =
          compactImportChain.map((CodeLocation codeLocation) {
            return codeLocation.relativize(rootUri);
          }).join(' => ');

      if (!importChains.contains(importChain)) {
        if (importChains.length > compactChainLimit) {
          importChains.add('...');
          return false;
        } else {
          importChains.add(importChain);
        }
      }

      chainCount++;
      if (chainCount > chainLimit) {
        // Assume there are more import chains.
        importChains.add('...');
        return false;
      }
      return true;
    });
    return importChains;
  }

  /// Register that [uri] was recognized but disallowed as a dependency.
  ///
  /// For instance import of 'dart:io' without '--categories=Server'.
  void registerDisallowedLibraryUse(Uri uri) {
    disallowedLibraryUris.add(uri);
  }

  /// This method is called when all new libraries loaded through
  /// [LibraryLoader.loadLibrary] has been loaded and their imports/exports
  /// have been computed.
  ///
  /// [loadedLibraries] contains the newly loaded libraries.
  ///
  /// The method returns a [Future] allowing for the loading of additional
  /// libraries.
  Future onLibrariesLoaded(LoadedLibraries loadedLibraries) {
    return new Future.sync(() {
      for (Uri uri in disallowedLibraryUris) {
        if (loadedLibraries.containsLibrary(uri)) {
          Set<String> importChains =
              computeImportChainsFor(loadedLibraries, Uri.parse('dart:io'));
          reporter.reportInfo(NO_LOCATION_SPANNABLE,
             MessageKind.DISALLOWED_LIBRARY_IMPORT,
              {'uri': uri,
               'importChain': importChains.join(
                   MessageTemplate.DISALLOWED_LIBRARY_IMPORT_PADDING)});
        }
      }

      if (!loadedLibraries.containsLibrary(Uris.dart_core)) {
        return null;
      }

      bool importsMirrorsLibrary =
          loadedLibraries.containsLibrary(Uris.dart_mirrors);
      if (importsMirrorsLibrary && !backend.supportsReflection) {
        Set<String> importChains =
            computeImportChainsFor(loadedLibraries, Uris.dart_mirrors);
        reporter.reportErrorMessage(
            NO_LOCATION_SPANNABLE,
            MessageKind.MIRRORS_LIBRARY_NOT_SUPPORT_BY_BACKEND,
            {'importChain': importChains.join(
                MessageTemplate.MIRRORS_NOT_SUPPORTED_BY_BACKEND_PADDING)});
      } else if (importsMirrorsLibrary && !enableExperimentalMirrors) {
        Set<String> importChains =
            computeImportChainsFor(loadedLibraries, Uris.dart_mirrors);
        reporter.reportWarningMessage(
            NO_LOCATION_SPANNABLE,
            MessageKind.IMPORT_EXPERIMENTAL_MIRRORS,
            {'importChain': importChains.join(
                 MessageTemplate.IMPORT_EXPERIMENTAL_MIRRORS_PADDING)});
      }

      functionClass.ensureResolved(resolution);
      functionApplyMethod = functionClass.lookupLocalMember('apply');

      if (preserveComments) {
        return libraryLoader.loadLibrary(Uris.dart_mirrors)
            .then((LibraryElement libraryElement) {
          documentClass = libraryElement.find('Comment');
        });
      }
    }).then((_) => backend.onLibrariesLoaded(loadedLibraries));
  }

  bool isProxyConstant(ConstantValue value) {
    FieldElement field = coreLibrary.find('proxy');
    if (field == null) return false;
    if (!resolution.hasBeenResolved(field)) return false;
    if (proxyConstant == null) {
      proxyConstant =
          constants.getConstantValue(
              resolver.constantCompiler.compileConstant(field));
    }
    return proxyConstant == value;
  }

  Element findRequiredElement(LibraryElement library, String name) {
    var element = library.find(name);
    if (element == null) {
      reporter.internalError(library,
          "The library '${library.canonicalUri}' does not contain required "
          "element: '$name'.");
    }
    return element;
  }

  // TODO(johnniwinther): Move this to [PatchParser] when it is moved to the
  // [JavaScriptBackend]. Currently needed for testing.
  String get patchVersion => backend.patchVersion;

  void onClassResolved(ClassElement cls) {
    if (mirrorSystemClass == cls) {
      mirrorSystemGetNameFunction =
        cls.lookupLocalMember('getName');
    } else if (symbolClass == cls) {
      symbolConstructor = cls.constructors.head;
    } else if (symbolImplementationClass == cls) {
      symbolValidatedConstructor = symbolImplementationClass.lookupConstructor(
          symbolValidatedConstructorSelector.name);
    } else if (mirrorsUsedClass == cls) {
      mirrorsUsedConstructor = cls.constructors.head;
    } else if (intClass == cls) {
      intEnvironment = intClass.lookupConstructor(Identifiers.fromEnvironment);
    } else if (stringClass == cls) {
      stringEnvironment =
          stringClass.lookupConstructor(Identifiers.fromEnvironment);
    } else if (boolClass == cls) {
      boolEnvironment =
          boolClass.lookupConstructor(Identifiers.fromEnvironment);
    }
  }

  void initializeCoreClasses() {
    final List missingCoreClasses = [];
    ClassElement lookupCoreClass(String name) {
      ClassElement result = coreLibrary.find(name);
      if (result == null) {
        missingCoreClasses.add(name);
      }
      return result;
    }
    _coreTypes.objectClass = lookupCoreClass('Object');
    _coreTypes.boolClass = lookupCoreClass('bool');
    _coreTypes.numClass = lookupCoreClass('num');
    _coreTypes.intClass = lookupCoreClass('int');
    _coreTypes.doubleClass = lookupCoreClass('double');
    _coreTypes.resourceClass = lookupCoreClass('Resource');
    _coreTypes.stringClass = lookupCoreClass('String');
    _coreTypes.functionClass = lookupCoreClass('Function');
    _coreTypes.listClass = lookupCoreClass('List');
    _coreTypes.typeClass = lookupCoreClass('Type');
    _coreTypes.mapClass = lookupCoreClass('Map');
    _coreTypes.nullClass = lookupCoreClass('Null');
    _coreTypes.stackTraceClass = lookupCoreClass('StackTrace');
    _coreTypes.iterableClass = lookupCoreClass('Iterable');
    _coreTypes.symbolClass = lookupCoreClass('Symbol');
    if (!missingCoreClasses.isEmpty) {
      reporter.internalError(
          coreLibrary,
          'dart:core library does not contain required classes: '
          '$missingCoreClasses');
    }
  }

  Element _unnamedListConstructor;
  Element get unnamedListConstructor {
    if (_unnamedListConstructor != null) return _unnamedListConstructor;
    return _unnamedListConstructor = listClass.lookupDefaultConstructor();
  }

  Element _filledListConstructor;
  Element get filledListConstructor {
    if (_filledListConstructor != null) return _filledListConstructor;
    return _filledListConstructor = listClass.lookupConstructor("filled");
  }

  /**
   * Get an [Uri] pointing to a patch for the dart: library with
   * the given path. Returns null if there is no patch.
   */
  Uri resolvePatchUri(String dartLibraryPath);

  Future runCompiler(Uri uri) {
    // TODO(ahe): This prevents memory leaks when invoking the compiler
    // multiple times. Implement a better mechanism where we can store
    // such caches in the compiler and get access to them through a
    // suitably maintained static reference to the current compiler.
    StringToken.canonicalizedSubstrings.clear();
    Selector.canonicalizedValues.clear();

    assert(uri != null || analyzeOnly || hasIncrementalSupport);
    return new Future.sync(() {
      if (librariesToAnalyzeWhenRun != null) {
        return Future.forEach(librariesToAnalyzeWhenRun, (libraryUri) {
          reporter.log('Analyzing $libraryUri ($buildId)');
          return libraryLoader.loadLibrary(libraryUri);
        });
      }
    }).then((_) {
      if (uri != null) {
        if (analyzeOnly) {
          reporter.log('Analyzing $uri ($buildId)');
        } else {
          reporter.log('Compiling $uri ($buildId)');
        }
        return libraryLoader.loadLibrary(uri).then((LibraryElement library) {
          mainApp = library;
        });
      }
    }).then((_) {
      compileLoadedLibraries();
    });
  }

  void computeMain() {
    if (mainApp == null) return;

    Element main = mainApp.findExported(Identifiers.main);
    ErroneousElement errorElement = null;
    if (main == null) {
      if (analyzeOnly) {
        if (!analyzeAll) {
          errorElement = new ErroneousElementX(
              MessageKind.CONSIDER_ANALYZE_ALL, {'main': Identifiers.main},
              Identifiers.main, mainApp);
        }
      } else {
        // Compilation requires a main method.
        errorElement = new ErroneousElementX(
            MessageKind.MISSING_MAIN, {'main': Identifiers.main},
            Identifiers.main, mainApp);
      }
      mainFunction = backend.helperForMissingMain();
    } else if (main.isErroneous && main.isSynthesized) {
      if (main is ErroneousElement) {
        errorElement = main;
      } else {
        reporter.internalError(main, 'Problem with ${Identifiers.main}.');
      }
      mainFunction = backend.helperForBadMain();
    } else if (!main.isFunction) {
      errorElement = new ErroneousElementX(
          MessageKind.MAIN_NOT_A_FUNCTION, {'main': Identifiers.main},
          Identifiers.main, main);
      mainFunction = backend.helperForBadMain();
    } else {
      mainFunction = main;
      mainFunction.computeType(resolution);
      FunctionSignature parameters = mainFunction.functionSignature;
      if (parameters.requiredParameterCount > 2) {
        int index = 0;
        parameters.orderedForEachParameter((Element parameter) {
          if (index++ < 2) return;
          errorElement = new ErroneousElementX(
              MessageKind.MAIN_WITH_EXTRA_PARAMETER, {'main': Identifiers.main},
              Identifiers.main,
              parameter);
          mainFunction = backend.helperForMainArity();
          // Don't warn about main not being used:
          enqueuer.resolution.registerStaticUse(main);
        });
      }
    }
    if (mainFunction == null) {
      if (errorElement == null && !analyzeOnly && !analyzeAll) {
        reporter.internalError(mainApp, "Problem with '${Identifiers.main}'.");
      } else {
        mainFunction = errorElement;
      }
    }
    if (errorElement != null &&
        errorElement.isSynthesized &&
        !mainApp.isSynthesized) {
      reporter.reportWarningMessage(
          errorElement, errorElement.messageKind,
          errorElement.messageArguments);
    }
  }

  /// Analyze all member of the library in [libraryUri].
  ///
  /// If [skipLibraryWithPartOfTag] is `true`, member analysis is skipped if the
  /// library has a `part of` tag, assuming it is a part and not a library.
  ///
  /// This operation assumes an unclosed resolution queue and is only supported
  /// when the '--analyze-main' option is used.
  Future<LibraryElement> analyzeUri(
      Uri libraryUri,
      {bool skipLibraryWithPartOfTag: true}) {
    assert(analyzeMain);
    reporter.log('Analyzing $libraryUri ($buildId)');
    return libraryLoader.loadLibrary(libraryUri).then((LibraryElement library) {
      var compilationUnit = library.compilationUnit;
      if (skipLibraryWithPartOfTag && compilationUnit.partTag != null) {
        return null;
      }
      fullyEnqueueLibrary(library, enqueuer.resolution);
      emptyQueue(enqueuer.resolution);
      enqueuer.resolution.logSummary(reporter.log);
      return library;
    });
  }

  /// Performs the compilation when all libraries have been loaded.
  void compileLoadedLibraries() {
    computeMain();

    mirrorUsageAnalyzerTask.analyzeUsage(mainApp);

    // In order to see if a library is deferred, we must compute the
    // compile-time constants that are metadata.  This means adding
    // something to the resolution queue.  So we cannot wait with
    // this until after the resolution queue is processed.
    deferredLoadTask.beforeResolution(this);

    phase = PHASE_RESOLVING;
    if (analyzeAll) {
      libraryLoader.libraries.forEach((LibraryElement library) {
      reporter.log('Enqueuing ${library.canonicalUri}');
        fullyEnqueueLibrary(library, enqueuer.resolution);
      });
    } else if (analyzeMain) {
      if (mainApp != null) {
        fullyEnqueueLibrary(mainApp, enqueuer.resolution);
      }
      if (librariesToAnalyzeWhenRun != null) {
        for (Uri libraryUri in librariesToAnalyzeWhenRun) {
          fullyEnqueueLibrary(libraryLoader.lookupLibrary(libraryUri),
              enqueuer.resolution);
        }
      }
    }
    // Elements required by enqueueHelpers are global dependencies
    // that are not pulled in by a particular element.
    backend.enqueueHelpers(enqueuer.resolution, globalDependencies);
    resolveLibraryMetadata();
    reporter.log('Resolving...');
    processQueue(enqueuer.resolution, mainFunction);
    enqueuer.resolution.logSummary(reporter.log);

    _reporter.reportSuppressedMessagesSummary();

    if (compilationFailed){
      if (!generateCodeWithCompileTimeErrors) return;
      if (!backend.enableCodegenWithErrorsIfSupported(NO_LOCATION_SPANNABLE)) {
        return;
      }
    }

    if (analyzeOnly) {
      if (!analyzeAll && !compilationFailed) {
        // No point in reporting unused code when [analyzeAll] is true: all
        // code is artificially used.
        // If compilation failed, it is possible that the error prevents the
        // compiler from analyzing all the code.
        // TODO(johnniwinther): Reenable this when the reporting is more
        // precise.
        //reportUnusedCode();
      }
      return;
    }
    assert(mainFunction != null);
    phase = PHASE_DONE_RESOLVING;

    world.populate();
    // Compute whole-program-knowledge that the backend needs. (This might
    // require the information computed in [world.populate].)
    backend.onResolutionComplete();

    deferredLoadTask.onResolutionComplete(mainFunction);

    reporter.log('Inferring types...');
    typesTask.onResolutionComplete(mainFunction);

    if (stopAfterTypeInference) return;

    backend.onTypeInferenceComplete();

    reporter.log('Compiling...');
    phase = PHASE_COMPILING;
    backend.onCodegenStart();
    // TODO(johnniwinther): Move these to [CodegenEnqueuer].
    if (hasIsolateSupport) {
      backend.enableIsolateSupport(enqueuer.codegen);
    }
    if (compileAll) {
      libraryLoader.libraries.forEach((LibraryElement library) {
        fullyEnqueueLibrary(library, enqueuer.codegen);
      });
    }
    processQueue(enqueuer.codegen, mainFunction);
    enqueuer.codegen.logSummary(reporter.log);

    int programSize = backend.assembleProgram();

    if (dumpInfo) {
      dumpInfoTask.reportSize(programSize);
      dumpInfoTask.dumpInfo();
    }

    checkQueues();
  }

  void fullyEnqueueLibrary(LibraryElement library, Enqueuer world) {
    void enqueueAll(Element element) {
      fullyEnqueueTopLevelElement(element, world);
    }
    library.implementation.forEachLocalMember(enqueueAll);
  }

  void fullyEnqueueTopLevelElement(Element element, Enqueuer world) {
    if (element.isClass) {
      ClassElement cls = element;
      cls.ensureResolved(resolution);
      cls.forEachLocalMember(enqueuer.resolution.addToWorkList);
      backend.registerInstantiatedType(
          cls.rawType, world, globalDependencies);
    } else {
      world.addToWorkList(element);
    }
  }

  // Resolves metadata on library elements.  This is necessary in order to
  // resolve metadata classes referenced only from metadata on library tags.
  // TODO(ahe): Figure out how to do this lazily.
  void resolveLibraryMetadata() {
    for (LibraryElement library in libraryLoader.libraries) {
      if (library.metadata != null) {
        for (MetadataAnnotation metadata in library.metadata) {
          metadata.ensureResolved(resolution);
        }
      }
    }
  }

  /**
   * Empty the [world] queue.
   */
  void emptyQueue(Enqueuer world) {
    world.forEach((WorkItem work) {
    reporter.withCurrentElement(work.element, () {
        world.applyImpact(work.element, work.run(this, world));
      });
    });
  }

  void processQueue(Enqueuer world, Element main) {
    world.nativeEnqueuer.processNativeClasses(libraryLoader.libraries);
    if (main != null && !main.isErroneous) {
      FunctionElement mainMethod = main;
      mainMethod.computeType(resolution);
      if (mainMethod.functionSignature.parameterCount != 0) {
        // The first argument could be a list of strings.
        backend.listImplementation.ensureResolved(resolution);
        backend.registerInstantiatedType(
            backend.listImplementation.rawType, world, globalDependencies);
        backend.stringImplementation.ensureResolved(resolution);
        backend.registerInstantiatedType(
            backend.stringImplementation.rawType, world, globalDependencies);

        backend.registerMainHasArguments(world);
      }
      world.addToWorkList(main);
    }
    if (verbose) {
      progress.reset();
    }
    emptyQueue(world);
    world.queueIsClosed = true;
    backend.onQueueClosed();
    assert(compilationFailed || world.checkNoEnqueuedInvokedInstanceMethods());
  }

  /**
   * Perform various checks of the queues. This includes checking that
   * the queues are empty (nothing was added after we stopped
   * processing the queues). Also compute the number of methods that
   * were resolved, but not compiled (aka excess resolution).
   */
  checkQueues() {
    for (Enqueuer world in [enqueuer.resolution, enqueuer.codegen]) {
      world.forEach((WorkItem work) {
        reporter.internalError(work.element, "Work list is not empty.");
      });
    }
    if (!REPORT_EXCESS_RESOLUTION) return;
    var resolved = new Set.from(enqueuer.resolution.processedElements);
    for (Element e in enqueuer.codegen.generatedCode.keys) {
      resolved.remove(e);
    }
    for (Element e in new Set.from(resolved)) {
      if (e.isClass ||
          e.isField ||
          e.isTypeVariable ||
          e.isTypedef ||
          identical(e.kind, ElementKind.ABSTRACT_FIELD)) {
        resolved.remove(e);
      }
      if (identical(e.kind, ElementKind.GENERATIVE_CONSTRUCTOR)) {
        resolved.remove(e);
      }
      if (backend.isBackendLibrary(e.library)) {
        resolved.remove(e);
      }
    }
    reporter.log('Excess resolution work: ${resolved.length}.');
    for (Element e in resolved) {
      reporter.reportWarningMessage(e,
          MessageKind.GENERIC,
          {'text': 'Warning: $e resolved but not compiled.'});
    }
  }

  WorldImpact analyzeElement(Element element) {
    assert(invariant(element,
           element.impliesType ||
           element.isField ||
           element.isFunction ||
           element.isGenerativeConstructor ||
           element.isGetter ||
           element.isSetter,
           message: 'Unexpected element kind: ${element.kind}'));
    assert(invariant(element, element is AnalyzableElement,
        message: 'Element $element is not analyzable.'));
    assert(invariant(element, element.isDeclaration));
    return resolution.computeWorldImpact(element);
  }

  WorldImpact analyze(ResolutionWorkItem work,
                      ResolutionEnqueuer world) {
    assert(invariant(work.element, identical(world, enqueuer.resolution)));
    assert(invariant(work.element, !work.isAnalyzed,
        message: 'Element ${work.element} has already been analyzed'));
    if (shouldPrintProgress) {
      // TODO(ahe): Add structured diagnostics to the compiler API and
      // use it to separate this from the --verbose option.
      if (phase == PHASE_RESOLVING) {
        reporter.log(
            'Resolved ${enqueuer.resolution.processedElements.length} '
            'elements.');
        progress.reset();
      }
    }
    AstElement element = work.element;
    if (world.hasBeenProcessed(element)) {
      return const WorldImpact();
    }
    WorldImpact worldImpact = analyzeElement(element);
    backend.onElementResolved(element, element.resolvedAst.elements);
    world.registerProcessedElement(element);
    return worldImpact;
  }

  WorldImpact codegen(CodegenWorkItem work, CodegenEnqueuer world) {
    assert(invariant(work.element, identical(world, enqueuer.codegen)));
    if (shouldPrintProgress) {
      // TODO(ahe): Add structured diagnostics to the compiler API and
      // use it to separate this from the --verbose option.
      reporter.log(
          'Compiled ${enqueuer.codegen.generatedCode.length} methods.');
      progress.reset();
    }
    return backend.codegen(work);
  }

  void reportDiagnostic(DiagnosticMessage message,
                        List<DiagnosticMessage> infos,
                        api.Diagnostic kind);

  void reportCrashInUserCode(String message, exception, stackTrace) {
    _reporter.onCrashInUserCode(message, exception, stackTrace);
  }

  /**
   * Translates the [resolvedUri] into a readable URI.
   *
   * The [importingLibrary] holds the library importing [resolvedUri] or
   * [:null:] if [resolvedUri] is loaded as the main library. The
   * [importingLibrary] is used to grant access to internal libraries from
   * platform libraries and patch libraries.
   *
   * If the [resolvedUri] is not accessible from [importingLibrary], this method
   * is responsible for reporting errors.
   *
   * See [LibraryLoader] for terminology on URIs.
   */
  Uri translateResolvedUri(LibraryElement importingLibrary,
                           Uri resolvedUri, Spannable spannable) {
    unimplemented(importingLibrary, 'Compiler.translateResolvedUri');
    return null;
  }

  /**
   * Reads the script specified by the [readableUri].
   *
   * See [LibraryLoader] for terminology on URIs.
   */
  Future<Script> readScript(Spannable node, Uri readableUri) {
    unimplemented(node, 'Compiler.readScript');
    return null;
  }

  /// Compatible with [readScript] and used by [LibraryLoader] to create
  /// synthetic scripts to recover from read errors and bad URIs.
  Future<Script> synthesizeScript(Spannable node, Uri readableUri) {
    unimplemented(node, 'Compiler.synthesizeScript');
    return null;
  }

  Element lookupElementIn(ScopeContainerElement container, String name) {
    Element element = container.localLookup(name);
    if (element == null) {
      throw 'Could not find $name in $container';
    }
    return element;
  }

  bool get isMockCompilation => false;

  Token processAndStripComments(Token currentToken) {
    Token firstToken = currentToken;
    Token prevToken;
    while (currentToken.kind != Tokens.EOF_TOKEN) {
      if (identical(currentToken.kind, Tokens.COMMENT_TOKEN)) {
        Token firstCommentToken = currentToken;
        while (identical(currentToken.kind, Tokens.COMMENT_TOKEN)) {
          currentToken = currentToken.next;
        }
        commentMap[currentToken] = firstCommentToken;
        if (prevToken == null) {
          firstToken = currentToken;
        } else {
          prevToken.next = currentToken;
        }
      }
      prevToken = currentToken;
      currentToken = currentToken.next;
    }
    return firstToken;
  }

  void reportUnusedCode() {
    void checkLive(member) {
      if (member.isErroneous) return;
      if (member.isFunction) {
        if (!enqueuer.resolution.hasBeenProcessed(member)) {
          reporter.reportHintMessage(
              member, MessageKind.UNUSED_METHOD, {'name': member.name});
        }
      } else if (member.isClass) {
        if (!member.isResolved) {
          reporter.reportHintMessage(
              member, MessageKind.UNUSED_CLASS, {'name': member.name});
        } else {
          member.forEachLocalMember(checkLive);
        }
      } else if (member.isTypedef) {
        if (!member.isResolved) {
          reporter.reportHintMessage(
              member, MessageKind.UNUSED_TYPEDEF, {'name': member.name});
        }
      }
    }
    libraryLoader.libraries.forEach((LibraryElement library) {
      // TODO(ahe): Implement better heuristics to discover entry points of
      // packages and use that to discover unused implementation details in
      // packages.
      if (library.isPlatformLibrary || library.isPackageLibrary) return;
      library.compilationUnits.forEach((unit) {
        unit.forEachLocalMember(checkLive);
      });
    });
  }

  /// Helper for determining whether the current element is declared within
  /// 'user code'.
  ///
  /// See [inUserCode] for what defines 'user code'.
  bool currentlyInUserCode() {
    return inUserCode(currentElement);
  }

  /// Helper for determining whether [element] is declared within 'user code'.
  ///
  /// What constitutes 'user code' is defined by the URI(s) provided by the
  /// entry point(s) of compilation or analysis:
  ///
  /// If an entrypoint URI uses the 'package' scheme then every library from
  /// that same package is considered to be in user code. For instance, if
  /// an entry point URI is 'package:foo/bar.dart' then every library whose
  /// canonical URI starts with 'package:foo/' is in user code.
  ///
  /// If an entrypoint URI uses another scheme than 'package' then every library
  /// with that scheme is in user code. For instance, an entry point URI is
  /// 'file:///foo.dart' then every library whose canonical URI scheme is
  /// 'file' is in user code.
  ///
  /// If [assumeInUserCode] is `true`, [element] is assumed to be in user code
  /// if no entrypoints have been set.
  bool inUserCode(Element element, {bool assumeInUserCode: false}) {
    if (element == null) return false;
    Iterable<CodeLocation> userCodeLocations =
        computeUserCodeLocations(assumeInUserCode: assumeInUserCode);
    Uri libraryUri = element.library.canonicalUri;
    return userCodeLocations.any(
        (CodeLocation codeLocation) => codeLocation.inSameLocation(libraryUri));
  }

  Iterable<CodeLocation> computeUserCodeLocations(
      {bool assumeInUserCode: false}) {
    List<CodeLocation> userCodeLocations = <CodeLocation>[];
    if (mainApp != null) {
      userCodeLocations.add(new CodeLocation(mainApp.canonicalUri));
    }
    if (librariesToAnalyzeWhenRun != null) {
      userCodeLocations.addAll(librariesToAnalyzeWhenRun.map(
          (Uri uri) => new CodeLocation(uri)));
    }
    if (userCodeLocations.isEmpty && assumeInUserCode) {
      // Assume in user code since [mainApp] has not been set yet.
      userCodeLocations.add(const AnyLocation());
    }
    return userCodeLocations;
  }

  /// Return a canonical URI for the source of [element].
  ///
  /// For a package library with canonical URI 'package:foo/bar/baz.dart' the
  /// return URI is 'package:foo'. For non-package libraries the returned URI is
  /// the canonical URI of the library itself.
  Uri getCanonicalUri(Element element) {
    if (element == null) return null;
    Uri libraryUri = element.library.canonicalUri;
    if (libraryUri.scheme == 'package') {
      int slashPos = libraryUri.path.indexOf('/');
      if (slashPos != -1) {
        String packageName = libraryUri.path.substring(0, slashPos);
        return new Uri(scheme: 'package', path: packageName);
      }
    }
    return libraryUri;
  }

  void diagnoseCrashInUserCode(String message, exception, stackTrace) {
    // Overridden by Compiler in apiimpl.dart.
  }

  void forgetElement(Element element) {
    enqueuer.forgetElement(element);
    if (element is MemberElement) {
      for (Element closure in element.nestedClosures) {
        // TODO(ahe): It would be nice to reuse names of nested closures.
        closureToClassMapper.forgetElement(closure);
      }
    }
    backend.forgetElement(element);
  }

  bool elementHasCompileTimeError(Element element) {
    return elementsWithCompileTimeErrors.contains(element);
  }

  EventSink<String> outputProvider(String name, String extension) {
    if (compilationFailed) {
      if (!generateCodeWithCompileTimeErrors || testMode) {
        // Disable output in test mode: The build bot currently uses the time
        // stamp of the generated file to determine whether the output is
        // up-to-date.
        return new NullSink('$name.$extension');
      }
    }
    return userOutputProvider.createEventSink(name, extension);
  }
}

/// Information about suppressed warnings and hints for a given library.
class SuppressionInfo {
  int warnings = 0;
  int hints = 0;
}

class _CompilerCoreTypes implements CoreTypes {
  final Resolution resolution;

  ClassElement objectClass;
  ClassElement boolClass;
  ClassElement numClass;
  ClassElement intClass;
  ClassElement doubleClass;
  ClassElement stringClass;
  ClassElement functionClass;
  ClassElement nullClass;
  ClassElement listClass;
  ClassElement typeClass;
  ClassElement mapClass;
  ClassElement symbolClass;
  ClassElement stackTraceClass;
  ClassElement futureClass;
  ClassElement iterableClass;
  ClassElement streamClass;
  ClassElement resourceClass;

  _CompilerCoreTypes(this.resolution);

  @override
  InterfaceType get objectType {
    objectClass.ensureResolved(resolution);
    return objectClass.rawType;
  }

  @override
  InterfaceType get boolType {
    boolClass.ensureResolved(resolution);
    return boolClass.rawType;
  }

  @override
  InterfaceType get doubleType {
    doubleClass.ensureResolved(resolution);
    return doubleClass.rawType;
  }

  @override
  InterfaceType get functionType {
    functionClass.ensureResolved(resolution);
    return functionClass.rawType;
  }

  @override
  InterfaceType get intType {
    intClass.ensureResolved(resolution);
    return intClass.rawType;
  }

  @override
  InterfaceType get resourceType {
    resourceClass.ensureResolved(resolution);
    return resourceClass.rawType;
  }

  @override
  InterfaceType listType([DartType elementType]) {
    listClass.ensureResolved(resolution);
    InterfaceType type = listClass.rawType;
    if (elementType == null) {
      return type;
    }
    return type.createInstantiation([elementType]);
  }

  @override
  InterfaceType mapType([DartType keyType,
                         DartType valueType]) {
    mapClass.ensureResolved(resolution);
    InterfaceType type = mapClass.rawType;
    if (keyType == null && valueType == null) {
      return type;
    } else if (keyType == null) {
      keyType = const DynamicType();
    } else if (valueType == null) {
      valueType = const DynamicType();
    }
    return type.createInstantiation([keyType, valueType]);
  }

  @override
  InterfaceType get nullType {
    nullClass.ensureResolved(resolution);
    return nullClass.rawType;
  }

  @override
  InterfaceType get numType {
    numClass.ensureResolved(resolution);
    return numClass.rawType;
  }

  @override
  InterfaceType get stringType {
    stringClass.ensureResolved(resolution);
    return stringClass.rawType;
  }

  @override
  InterfaceType get symbolType {
    symbolClass.ensureResolved(resolution);
    return symbolClass.rawType;
  }

  @override
  InterfaceType get typeType {
    typeClass.ensureResolved(resolution);
    return typeClass.rawType;
  }

  @override
  InterfaceType iterableType([DartType elementType]) {
    iterableClass.ensureResolved(resolution);
    InterfaceType type = iterableClass.rawType;
    if (elementType == null) {
      return type;
    }
    return type.createInstantiation([elementType]);
  }

  @override
  InterfaceType futureType([DartType elementType]) {
    futureClass.ensureResolved(resolution);
    InterfaceType type = futureClass.rawType;
    if (elementType == null) {
      return type;
    }
    return type.createInstantiation([elementType]);
  }

  @override
  InterfaceType streamType([DartType elementType]) {
    streamClass.ensureResolved(resolution);
    InterfaceType type = streamClass.rawType;
    if (elementType == null) {
      return type;
    }
    return type.createInstantiation([elementType]);
  }
}

class _CompilerDiagnosticReporter extends DiagnosticReporter {
  final Compiler compiler;
  final DiagnosticOptions options;

  Element _currentElement;
  bool hasCrashed = false;

  /// `true` if the last diagnostic was filtered, in which case the
  /// accompanying info message should be filtered as well.
  bool lastDiagnosticWasFiltered = false;

  /// Map containing information about the warnings and hints that have been
  /// suppressed for each library.
  Map<Uri, SuppressionInfo> suppressedWarnings = <Uri, SuppressionInfo>{};

  _CompilerDiagnosticReporter(this.compiler, this.options);

  Element get currentElement => _currentElement;

  DiagnosticMessage createMessage(
      Spannable spannable,
      MessageKind messageKind,
      [Map arguments = const {}]) {
    SourceSpan span = spanFromSpannable(spannable);
    MessageTemplate template = MessageTemplate.TEMPLATES[messageKind];
    Message message = template.message(arguments, options.terseDiagnostics);
    return new DiagnosticMessage(span, spannable, message);
  }

  void reportError(
      DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    reportDiagnosticInternal(message, infos, api.Diagnostic.ERROR);
  }

  void reportWarning(
      DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    reportDiagnosticInternal(message, infos, api.Diagnostic.WARNING);
  }

  void reportHint(
      DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    reportDiagnosticInternal(message, infos, api.Diagnostic.HINT);
  }

  @deprecated
  void reportInfo(Spannable node, MessageKind messageKind,
                  [Map arguments = const {}]) {
    reportDiagnosticInternal(
        createMessage(node, messageKind, arguments),
        const <DiagnosticMessage>[],
        api.Diagnostic.INFO);
  }

  void reportDiagnosticInternal(DiagnosticMessage message,
                                List<DiagnosticMessage> infos,
                                api.Diagnostic kind) {
    if (!options.showPackageWarnings &&
        message.spannable != NO_LOCATION_SPANNABLE) {
      switch (kind) {
      case api.Diagnostic.WARNING:
      case api.Diagnostic.HINT:
        Element element = elementFromSpannable(message.spannable);
        if (!compiler.inUserCode(element, assumeInUserCode: true)) {
          Uri uri = compiler.getCanonicalUri(element);
          SuppressionInfo info =
              suppressedWarnings.putIfAbsent(uri, () => new SuppressionInfo());
          if (kind == api.Diagnostic.WARNING) {
            info.warnings++;
          } else {
            info.hints++;
          }
          lastDiagnosticWasFiltered = true;
          return;
        }
        break;
      case api.Diagnostic.INFO:
        if (lastDiagnosticWasFiltered) {
          return;
        }
        break;
      }
    }
    lastDiagnosticWasFiltered = false;
    reportDiagnostic(message, infos, kind);
  }

  void reportDiagnostic(DiagnosticMessage message,
                        List<DiagnosticMessage> infos,
                        api.Diagnostic kind) {
    compiler.reportDiagnostic(message, infos, kind);
  }

  /**
   * Perform an operation, [f], returning the return value from [f].  If an
   * error occurs then report it as having occurred during compilation of
   * [element].  Can be nested.
   */
  withCurrentElement(Element element, f()) {
    Element old = currentElement;
    _currentElement = element;
    try {
      return f();
    } on SpannableAssertionFailure catch (ex) {
      if (!hasCrashed) {
        reportAssertionFailure(ex);
        pleaseReportCrash();
      }
      hasCrashed = true;
      rethrow;
    } on StackOverflowError {
      // We cannot report anything useful in this case, because we
      // do not have enough stack space.
      rethrow;
    } catch (ex) {
      if (hasCrashed) rethrow;
      try {
        unhandledExceptionOnElement(element);
      } catch (doubleFault) {
        // Ignoring exceptions in exception handling.
      }
      rethrow;
    } finally {
      _currentElement = old;
    }
  }

  void reportAssertionFailure(SpannableAssertionFailure ex) {
    String message = (ex.message != null) ? tryToString(ex.message)
                                          : tryToString(ex);
    reportDiagnosticInternal(
        createMessage(ex.node, MessageKind.GENERIC, {'text': message}),
        const <DiagnosticMessage>[],
        api.Diagnostic.CRASH);
  }

  SourceSpan spanFromTokens(Token begin, Token end, [Uri uri]) {
    if (begin == null || end == null) {
      // TODO(ahe): We can almost always do better. Often it is only
      // end that is null. Otherwise, we probably know the current
      // URI.
      throw 'Cannot find tokens to produce error message.';
    }
    if (uri == null && currentElement != null) {
      uri = currentElement.compilationUnit.script.resourceUri;
    }
    return new SourceSpan.fromTokens(uri, begin, end);
  }

  SourceSpan spanFromNode(Node node) {
    return spanFromTokens(node.getBeginToken(), node.getEndToken());
  }

  SourceSpan spanFromElement(Element element) {
    if (element != null && element.sourcePosition != null) {
      return element.sourcePosition;
    }
    while (element != null && element.isSynthesized) {
      element = element.enclosingElement;
    }
    if (element != null &&
        element.sourcePosition == null &&
        !element.isLibrary &&
        !element.isCompilationUnit) {
      // Sometimes, the backend fakes up elements that have no
      // position. So we use the enclosing element instead. It is
      // not a good error location, but cancel really is "internal
      // error" or "not implemented yet", so the vicinity is good
      // enough for now.
      element = element.enclosingElement;
      // TODO(ahe): I plan to overhaul this infrastructure anyways.
    }
    if (element == null) {
      element = currentElement;
    }
    if (element == null) {
      return null;
    }

    if (element.sourcePosition != null) {
      return element.sourcePosition;
    }
    Token position = element.position;
    Uri uri = element.compilationUnit.script.resourceUri;
    return (position == null)
        ? new SourceSpan(uri, 0, 0)
        : spanFromTokens(position, position, uri);
  }

  SourceSpan spanFromHInstruction(HInstruction instruction) {
    Element element = _elementFromHInstruction(instruction);
    if (element == null) element = currentElement;
    SourceInformation position = instruction.sourceInformation;
    if (position == null) return spanFromElement(element);
    return position.sourceSpan;
  }

  SourceSpan spanFromSpannable(Spannable node) {
    // TODO(johnniwinther): Disallow `node == null` ?
    if (node == null) return null;
    if (node == CURRENT_ELEMENT_SPANNABLE) {
      node = currentElement;
    } else if (node == NO_LOCATION_SPANNABLE) {
      if (currentElement == null) return null;
      node = currentElement;
    }
    if (node is SourceSpan) {
      return node;
    } else if (node is Node) {
      return spanFromNode(node);
    } else if (node is TokenPair) {
      return spanFromTokens(node.begin, node.end);
    } else if (node is Token) {
      return spanFromTokens(node, node);
    } else if (node is HInstruction) {
      return spanFromHInstruction(node);
    } else if (node is Element) {
      return spanFromElement(node);
    } else if (node is MetadataAnnotation) {
      Uri uri = node.annotatedElement.compilationUnit.script.resourceUri;
      return spanFromTokens(node.beginToken, node.endToken, uri);
    } else if (node is Local) {
      Local local = node;
      return spanFromElement(local.executableContext);
    } else {
      throw 'No error location.';
    }
  }

  Element _elementFromHInstruction(HInstruction instruction) {
    return instruction.sourceElement is Element
        ? instruction.sourceElement : null;
  }

  internalError(Spannable node, reason) {
    String message = tryToString(reason);
    reportDiagnosticInternal(
        createMessage(node, MessageKind.GENERIC, {'text': message}),
        const <DiagnosticMessage>[],
        api.Diagnostic.CRASH);
    throw 'Internal Error: $message';
  }

  void unhandledExceptionOnElement(Element element) {
    if (hasCrashed) return;
    hasCrashed = true;
    reportDiagnostic(
        createMessage(element, MessageKind.COMPILER_CRASHED),
        const <DiagnosticMessage>[],
        api.Diagnostic.CRASH);
    pleaseReportCrash();
  }

  void pleaseReportCrash() {
    print(
        MessageTemplate.TEMPLATES[MessageKind.PLEASE_REPORT_THE_CRASH]
            .message({'buildId': compiler.buildId}));
  }

  /// Finds the approximate [Element] for [node]. [currentElement] is used as
  /// the default value.
  Element elementFromSpannable(Spannable node) {
    Element element;
    if (node is Element) {
      element = node;
    } else if (node is HInstruction) {
      element = _elementFromHInstruction(node);
    } else if (node is MetadataAnnotation) {
      element = node.annotatedElement;
    }
    return element != null ? element : currentElement;
  }

  void log(message) {
    Message msg = MessageTemplate.TEMPLATES[MessageKind.GENERIC]
        .message({'text': '$message'});
    reportDiagnostic(
        new DiagnosticMessage(null, null, msg),
        const <DiagnosticMessage>[],
        api.Diagnostic.VERBOSE_INFO);
  }

  String tryToString(object) {
    try {
      return object.toString();
    } catch (_) {
      return '<exception in toString()>';
    }
  }

  onError(Uri uri, error) {
    try {
      if (!hasCrashed) {
        hasCrashed = true;
        if (error is SpannableAssertionFailure) {
          reportAssertionFailure(error);
        } else {
          reportDiagnostic(
              createMessage(
                  new SourceSpan(uri, 0, 0),
                  MessageKind.COMPILER_CRASHED),
              const <DiagnosticMessage>[],
              api.Diagnostic.CRASH);
        }
        pleaseReportCrash();
      }
    } catch (doubleFault) {
      // Ignoring exceptions in exception handling.
    }
    throw error;
  }

  void onCrashInUserCode(String message, exception, stackTrace) {
    hasCrashed = true;
    print('$message: ${tryToString(exception)}');
    print(tryToString(stackTrace));
  }

  void reportSuppressedMessagesSummary() {
    if (!options.showPackageWarnings && !options.suppressWarnings) {
      suppressedWarnings.forEach((Uri uri, SuppressionInfo info) {
        MessageKind kind = MessageKind.HIDDEN_WARNINGS_HINTS;
        if (info.warnings == 0) {
          kind = MessageKind.HIDDEN_HINTS;
        } else if (info.hints == 0) {
          kind = MessageKind.HIDDEN_WARNINGS;
        }
        MessageTemplate template = MessageTemplate.TEMPLATES[kind];
        Message message = template.message(
            {'warnings': info.warnings,
             'hints': info.hints,
             'uri': uri},
             options.terseDiagnostics);
        reportDiagnostic(
            new DiagnosticMessage(null, null, message),
            const <DiagnosticMessage>[],
            api.Diagnostic.HINT);
      });
    }
  }
}

// TODO(johnniwinther): Move [ResolverTask] here.
class _CompilerResolution implements Resolution {
  final Compiler compiler;
  final Map<Element, WorldImpact> _worldImpactCache = <Element, WorldImpact>{};

  _CompilerResolution(this.compiler);

  @override
  DiagnosticReporter get reporter => compiler.reporter;

  @override
  Parsing get parsing => compiler.parsing;

  @override
  CoreTypes get coreTypes => compiler.coreTypes;

  @override
  void registerClass(ClassElement cls) {
    compiler.world.registerClass(cls);
  }

  @override
  void resolveClass(ClassElement cls) {
    compiler.resolver.resolveClass(cls);
  }

  @override
  void resolveTypedef(TypedefElement typdef) {
    compiler.resolver.resolve(typdef);
  }

  @override
  void resolveMetadataAnnotation(MetadataAnnotation metadataAnnotation) {
    compiler.resolver.resolveMetadataAnnotation(metadataAnnotation);
  }

  @override
  FunctionSignature resolveSignature(FunctionElement function) {
    return compiler.resolver.resolveSignature(function);
  }

  @override
  DartType resolveTypeAnnotation(Element element, TypeAnnotation node) {
    return compiler.resolver.resolveTypeAnnotation(element, node);
  }

  @override
  WorldImpact getWorldImpact(Element element) {
    WorldImpact worldImpact = _worldImpactCache[element];
    assert(invariant(element, worldImpact != null,
        message: "WorldImpact not computed for $element."));
    return worldImpact;
  }

  @override
  WorldImpact computeWorldImpact(Element element) {
    return _worldImpactCache.putIfAbsent(element, () {
      assert(compiler.parser != null);
      Node tree = compiler.parser.parse(element);
      assert(invariant(element, !element.isSynthesized || tree == null));
      ResolutionImpact resolutionImpact =
          compiler.resolver.resolve(element);
      if (tree != null &&
          !compiler.analyzeSignaturesOnly &&
          !reporter.options.suppressWarnings) {
        // Only analyze nodes with a corresponding [TreeElements].
        compiler.checker.check(element);
      }
      WorldImpact worldImpact =
          compiler.backend.resolutionCallbacks.transformImpact(
              resolutionImpact);
      return worldImpact;
    });
  }

  @override
  bool hasBeenResolved(Element element) {
    return _worldImpactCache.containsKey(element);
  }
}

// TODO(johnniwinther): Move [ParserTask], [PatchParserTask], [DietParserTask]
// and [ScannerTask] here.
class _CompilerParsing implements Parsing {
  final Compiler compiler;

  _CompilerParsing(this.compiler);

  @override
  DiagnosticReporter get reporter => compiler.reporter;

  @override
  measure(f()) => compiler.parser.measure(f);

  @override
  void parsePatchClass(ClassElement cls) {
    compiler.patchParser.measure(() {
      if (cls.isPatch) {
        compiler.patchParser.parsePatchClassNode(cls);
      }
    });
  }
}

class GlobalDependencyRegistry extends CodegenRegistry {
  Setlet<Element> _otherDependencies;

  GlobalDependencyRegistry(Compiler compiler)
      : super(compiler, new TreeElementMapping(null));

  void registerDependency(Element element) {
    if (element == null) return;
    if (_otherDependencies == null) {
      _otherDependencies = new Setlet<Element>();
    }
    _otherDependencies.add(element.implementation);
  }

  Iterable<Element> get otherDependencies {
    return _otherDependencies != null ? _otherDependencies : const <Element>[];
  }
}