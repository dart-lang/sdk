// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show stdin, stdout;
import 'dart:isolate';
import 'dart:typed_data' show BytesBuilder;

import 'package:args/args.dart';
import 'package:build_integration/file_system/multi_root.dart';
import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:kernel/ast.dart' show Component, Library;
import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/tool/find_referenced_libraries.dart'
    show duplicateLibrariesReachable;
import 'package:kernel/target/targets.dart' show TargetFlags;

import '../compiler/js_names.dart';
import '../compiler/module_builder.dart' show ModuleFormat, parseModuleFormat;
import '../compiler/shared_command.dart' show SharedCompilerOptions;
import 'asset_file_system.dart';
import 'command.dart';
import 'compiler.dart' show ProgramCompiler;
import 'expression_compiler.dart' show ExpressionCompiler;
import 'target.dart' show DevCompilerTarget;

/// The service that handles expression compilation requests from
/// the debugger.
///
/// See design documentation and discussion in
/// http://go/dart_expression_evaluation_webdev_google3
///
///
/// [ExpressionCompilerWorker] listens to input stream of compile expression
/// requests and outputs responses.
///
/// Debugger can run the service by running the dartdevc main in an isolate,
/// which sets up the request stream and response callback using send ports.
///
/// Debugger also can pass an asset server's host and port so the service
/// can read dill files from the [AssetFileSystem] that talks to the asset
/// server behind the scenes over http.
///
/// Protocol:
///
///  - debugger and dartdevc expression evaluation service perform the initial
///    handshake to establish two-way communication:
///
///    - debugger creates an isolate using dartdevc's main method with
///      '--experimental-expression-compiler' flag and passes a send port
///      to dartdevc for sending responses from the service to the debugger.
///
///    - dartdevc creates a new send port to receive requests on, and sends
///      it back to the debugger, for sending requests to the service.
///
///  - debugger can now send two types of requests to the dartdevc service.
///    The service handles the requests sequentially in a first come, first
///    serve order.
///
///    - [UpdateDepsRequest]:
///      This request is sent on (re-)build, making the dartdevc load all
///      newly built full kernel files for given modules.
///
///    - [CompileExpressionRequest]:
///      This request is sent any time an evaluateInFrame request is made to
///      the debugger's VM service at a breakpoint - for example, on typing
///      in an expression evaluation box, on hover over, evaluation of
///      conditional breakpoints, evaluation of expressions in a watch window.
///
///  - Debugger closes the requests stream on exit, which effectively stops
///    the service
class ExpressionCompilerWorker {
  final Stream<Map<String, dynamic>> requestStream;
  final void Function(Map<String, dynamic>) sendResponse;

  final Map<String, Uri> _fullModules = {};
  final ModuleCache _moduleCache = ModuleCache();

  final ProcessedOptions _processedOptions;
  final CompilerOptions _compilerOptions;
  final ModuleFormat _moduleFormat;
  final bool _canaryFeatures;
  final bool _enableAsserts;
  final Component _sdkComponent;

  void Function()? onDone;

  ExpressionCompilerWorker._(
    this._processedOptions,
    this._compilerOptions,
    this._moduleFormat,
    this._canaryFeatures,
    this._enableAsserts,
    this._sdkComponent,
    this.requestStream,
    this.sendResponse,
    this.onDone,
  );

  /// Create expression compiler worker from [args] and start it.
  ///
  /// If [sendPort] is provided, creates a `receivePort` and sends it to
  /// the consumer to establish communication. Otherwise, uses stdin/stdout
  /// for communication with the consumer.
  ///
  /// Details:
  ///
  /// Consumer uses (`consumerSendPort`, `consumerReceivePort`) pair to
  /// send requests and receive responses:
  ///
  /// `consumerReceivePort.sendport` = [sendPort]
  /// `consumerSendPort = receivePort.sendport`
  ///
  /// Worker uses the opposite ports connected to the consumer ports -
  /// (`receivePort`, [sendPort]) to receive requests and send responses.
  ///
  /// The worker stops on start failure or after the consumer closes its
  /// receive port corresponding to [sendPort].
  static Future<void> createAndStart(List<String> args,
      {SendPort? sendPort}) async {
    ExpressionCompilerWorker? worker;
    if (sendPort != null) {
      var receivePort = ReceivePort();
      sendPort.send(receivePort.sendPort);
      try {
        worker = await createFromArgs(args,
            requestStream: receivePort.cast<Map<String, dynamic>>(),
            sendResponse: sendPort.send);
        await worker.run();
      } catch (e, s) {
        sendPort
            .send({'exception': '$e', 'stackTrace': '$s', 'succeeded': false});
        rethrow;
      } finally {
        receivePort.close();
        worker?.close();
      }
    } else {
      try {
        worker = await createFromArgs(args);
        await worker.run();
      } finally {
        worker?.close();
      }
    }
  }

  /// Parse args and create the worker, hook cleanup code to run when done.
  static Future<ExpressionCompilerWorker> createFromArgs(
    List<String> args, {
    Stream<Map<String, dynamic>>? requestStream,
    void Function(Map<String, dynamic>)? sendResponse,
  }) {
    // We are destructive on `args`, so make a copy.
    args = args.toList();
    var environmentDefines = parseAndRemoveDeclaredVariables(args);
    var parsedArgs = argParser.parse(args);

    FileSystem fileSystem = StandardFileSystem.instance;
    var multiRoots = (parsedArgs['multi-root'] as Iterable<String>)
        .map(Uri.base.resolve)
        .toList();
    var multiRootScheme = parsedArgs['multi-root-scheme'] as String;
    if (multiRoots.isNotEmpty) {
      fileSystem = MultiRootFileSystem(multiRootScheme, multiRoots, fileSystem);
    }
    var assetServerAddress = parsedArgs['asset-server-address'] as String?;
    if (assetServerAddress != null) {
      var assetServerPort = parsedArgs['asset-server-port'] as String?;
      fileSystem = AssetFileSystem(
          fileSystem, assetServerAddress, assetServerPort ?? '8080');
    }
    var explicitExperimentalFlags = parseExperimentalFlags(
        parseExperimentalArguments(
            parsedArgs['enable-experiment'] as List<String>),
        onError: (e) => throw e);

    var moduleFormat = parseModuleFormat(parsedArgs['module-format'] as String);

    return create(
      librariesSpecificationUri:
          _argToUri(parsedArgs['libraries-file'] as String?),
      packagesFile: _argToUri(parsedArgs['packages-file'] as String?),
      sdkSummary: _argToUri(parsedArgs['dart-sdk-summary'] as String?),
      fileSystem: fileSystem,
      environmentDefines: environmentDefines,
      explicitExperimentalFlags: explicitExperimentalFlags,
      sdkRoot: _argToUri(parsedArgs['sdk-root'] as String?),
      trackWidgetCreation: parsedArgs['track-widget-creation'] as bool,
      soundNullSafety: parsedArgs['sound-null-safety'] as bool,
      moduleFormat: moduleFormat,
      canaryFeatures: parsedArgs['canary'] as bool,
      enableAsserts: parsedArgs['enable-asserts'] as bool,
      verbose: parsedArgs['verbose'] as bool,
      requestStream: requestStream,
      sendResponse: sendResponse,
      onDone: () {
        if (fileSystem is AssetFileSystem) fileSystem.close();
      },
    );
  }

  static List<String> errors = <String>[];
  static List<String> warnings = <String>[];
  static List<String> infos = <String>[];

  /// Create the worker and load the sdk outlines.
  static Future<ExpressionCompilerWorker> create({
    required Uri? librariesSpecificationUri,
    required Uri? sdkSummary,
    required FileSystem fileSystem,
    Uri? packagesFile,
    Map<String, String>? environmentDefines,
    Map<ExperimentalFlag, bool> explicitExperimentalFlags = const {},
    Uri? sdkRoot,
    bool trackWidgetCreation = false,
    bool soundNullSafety = false,
    ModuleFormat moduleFormat = ModuleFormat.amd,
    bool canaryFeatures = false,
    bool enableAsserts = true,
    bool verbose = false,
    Stream<Map<String, dynamic>>? requestStream, // Defaults to read from stdin
    void Function(Map<String, dynamic>)?
        sendResponse, // Defaults to write to stdout
    void Function()? onDone,
  }) async {
    var compilerOptions = CompilerOptions()
      ..compileSdk = false
      ..sdkRoot = sdkRoot
      ..sdkSummary = sdkSummary
      ..packagesFileUri = packagesFile
      ..librariesSpecificationUri = librariesSpecificationUri
      ..target = DevCompilerTarget(TargetFlags(
          trackWidgetCreation: trackWidgetCreation,
          soundNullSafety: soundNullSafety))
      ..fileSystem = fileSystem
      ..omitPlatform = true
      ..environmentDefines = addGeneratedVariables({
        if (environmentDefines != null) ...environmentDefines,
      }, enableAsserts: enableAsserts)
      ..explicitExperimentalFlags = explicitExperimentalFlags
      ..onDiagnostic = _onDiagnosticHandler(errors, warnings, infos)
      ..nnbdMode = soundNullSafety ? NnbdMode.Strong : NnbdMode.Weak
      ..verbose = verbose;
    requestStream ??= stdin
        .transform(utf8.decoder.fuse(json.decoder))
        .cast<Map<String, dynamic>>();
    sendResponse ??= (Map<String, dynamic> response) =>
        stdout.writeln(json.encode(response));
    var processedOptions = ProcessedOptions(options: compilerOptions);

    var sdkComponent = await CompilerContext(processedOptions)
        .runInContext<Component?>((CompilerContext c) async {
      return processedOptions.loadSdkSummary(null);
    });

    if (sdkComponent == null) {
      throw Exception('Could not load SDK component: $sdkSummary');
    }
    return ExpressionCompilerWorker._(
        processedOptions,
        compilerOptions,
        moduleFormat,
        canaryFeatures,
        enableAsserts,
        sdkComponent,
        requestStream,
        sendResponse,
        onDone)
      .._updateCache(sdkComponent, dartSdkModule, true);
  }

  /// Starts listening and responding to commands.
  ///
  /// Completes when the [requestStream] closes and we finish handling the
  /// requests.
  Future<void> run() async {
    await for (var request in requestStream) {
      try {
        var command = request['command'] as String?;
        if (command == 'Shutdown') break;
        switch (command) {
          case 'UpdateDeps':
            sendResponse(await _updateDependencies(
                UpdateDependenciesRequest.fromJson(request)));
            break;
          case 'CompileExpression':
            sendResponse(await _compileExpression(
                CompileExpressionRequest.fromJson(request)));
            break;
          default:
            throw ArgumentError(
                'Unrecognized command `$command`, full request was `$request`');
        }
      } catch (e, s) {
        var command = request['command'] as String?;
        _processedOptions.ticker
            .logMs('Expression compiler worker request $command failed: $e:$s');
        sendResponse({
          'exception': '$e',
          'stackTrace': '$s',
          'succeeded': false,
        });
      }
    }
    _processedOptions.ticker.logMs('Stopped expression compiler worker.');
  }

  void close() {
    var fullModules = _moduleCache.fullyLoadedModules.toList();
    for (var module in fullModules) {
      _clearCache(module);
    }
    onDone?.call();
  }

  /// Handles a `CompileExpression` request.
  Future<Map<String, dynamic>> _compileExpression(
      CompileExpressionRequest request) async {
    var libraryUri = Uri.parse(request.libraryUri);
    var moduleName = request.moduleName;

    if (libraryUri.isScheme('dart')) {
      // compiling expressions inside the SDK currently fails because
      // SDK kernel outlines do not contain information that is needed
      // to detect the scope for expression evaluation - such as local
      // symbols and source file line starts.
      throw Exception('Expression compilation inside SDK is not supported yet');
    }

    _processedOptions.ticker
        .logMs('Compiling expression to JavaScript in module $moduleName');

    // Reset linking of libraries to the original state,
    // so any newly loaded components are linked to the
    // libraries in the cache.
    _resetCacheLinks();

    if (!_fullModules.containsKey(moduleName)) {
      throw StateError('No full dill path available for $moduleName');
    }

    // Note that this doesn't actually re-load it if it's already fully loaded.
    if (!await _loadAndUpdateComponent(
        _fullModules[moduleName]!, moduleName, false)) {
      throw ArgumentError('Failed to load full dill for module $moduleName: '
          '${_fullModules[moduleName]}');
    }

    errors.clear();
    warnings.clear();
    infos.clear();

    var expressionCompiler =
        await _createExpressionCompiler(libraryUri, moduleName);

    // Failed to compile component, report compilation errors.
    if (expressionCompiler == null) {
      return {
        'errors': errors,
        'warnings': warnings,
        'infos': infos,
        'compiledProcedure': null,
        'succeeded': false,
      };
    }

    var compiledProcedure = await expressionCompiler.compileExpressionToJs(
        request.libraryUri,
        request.line,
        request.column,
        request.jsScope,
        request.expression);

    _processedOptions.ticker.logMs('Compiled expression to JavaScript');

    // Return result or expression compilation errors.
    return {
      'errors': errors,
      'warnings': warnings,
      'infos': infos,
      'compiledProcedure': compiledProcedure,
      'succeeded': errors.isEmpty,
    };
  }

  /// Creates or returns cached expression compiler for the module
  /// [moduleName].
  /// Returns `null` if the module's component compilation fails.
  Future<ExpressionCompiler?> _createExpressionCompiler(
      Uri libraryUri, String moduleName) async {
    var expressionCompiler = _moduleCache.expressionCompilers[moduleName];
    if (expressionCompiler != null) return expressionCompiler;

    _processedOptions.ticker
        .logMs('Creating expression compiler for $moduleName');

    var originalComponent = _moduleCache.componentForModuleName[moduleName];
    if (originalComponent == null) {
      throw StateError('No Component found for module named: $moduleName');
    }

    var component = _sdkComponent;
    if (!libraryUri.isScheme('dart')) {
      _processedOptions.ticker.logMs('Collecting libraries for $moduleName');

      var libraries =
          _collectTransitiveDependencies(originalComponent, _sdkComponent);

      assert(!duplicateLibrariesReachable(libraries));

      component = Component(
        libraries: libraries,
        nameRoot: originalComponent.root,
        uriToSource: originalComponent.uriToSource,
      )..setMainMethodAndMode(
          originalComponent.mainMethodName, true, originalComponent.mode);
      _processedOptions.ticker.logMs('Collected libraries for $moduleName');
    }

    var entryPoints = originalComponent.libraries
        .map((e) => e.importUri)
        .where((uri) => !uri.isScheme('dart'));
    var incrementalCompiler = IncrementalCompiler.forExpressionCompilationOnly(
        CompilerContext(_processedOptions), component, /*resetTicker*/ false);

    var incrementalCompilerResult = await incrementalCompiler.computeDelta(
        entryPoints: entryPoints.toList(), fullComponent: true);
    var finalComponent = incrementalCompilerResult.component;
    assert(!duplicateLibrariesReachable(finalComponent.libraries));
    assert(_canSerialize(finalComponent));

    _processedOptions.ticker.logMs('Computed delta for expression');

    // Return null to indicate a compilation error,
    // to be created by the caller.
    if (errors.isNotEmpty) return null;

    var coreTypes = incrementalCompilerResult.coreTypes;
    var hierarchy = incrementalCompilerResult.classHierarchy!;

    var kernel2jsCompiler = ProgramCompiler(
      finalComponent,
      hierarchy,
      SharedCompilerOptions(
        sourceMap: true,
        summarizeApi: false,
        moduleName: moduleName,
        soundNullSafety: _compilerOptions.nnbdMode == NnbdMode.Strong,
        canaryFeatures: _canaryFeatures,
        enableAsserts: _enableAsserts,
      ),
      _moduleCache.componentForLibrary,
      _moduleCache.moduleNameForComponent,
      coreTypes: coreTypes,
      ticker: _processedOptions.ticker,
    );

    assert(originalComponent.libraries.toSet().length ==
        originalComponent.libraries.length);

    // Pick the libraries from finalComponent that's also in originalComponent.
    // This is needed because originalComponent can contain unreachable things
    // (i.e. unreachable from the entry point used here).
    var names = originalComponent.libraries.map((e) => e.importUri).toSet();
    var librariesToEmit = finalComponent.libraries
        .where((e) => names.contains(e.importUri))
        .toList();
    assert(_librariesAreKnown(hierarchy, librariesToEmit));

    var componentToEmit = Component(
        libraries: librariesToEmit,
        nameRoot: finalComponent.root,
        uriToSource: finalComponent.uriToSource)
      ..setMainMethodAndMode(
          originalComponent.mainMethodName, true, originalComponent.mode);

    kernel2jsCompiler.emitModule(componentToEmit);
    _processedOptions.ticker.logMs('Emitted module for expression');

    expressionCompiler = ExpressionCompiler(
      _compilerOptions,
      _moduleFormat,
      errors,
      incrementalCompiler,
      kernel2jsCompiler,
      finalComponent,
    );
    _moduleCache.expressionCompilers[moduleName] = expressionCompiler;
    _processedOptions.ticker
        .logMs('Created expression compiler for $moduleName');
    return expressionCompiler;
  }

  /// Collect libraries reachable from component.
  List<Library> _collectTransitiveDependencies(
      Component component, Component sdk) {
    var visited = <Uri>{};
    var libraries = <Library>[];
    var toVisit = <Uri>[];

    toVisit.addAll(sdk.libraries.map((e) => e.importUri));
    toVisit.addAll(component.libraries.map((e) => e.importUri));

    while (toVisit.isNotEmpty) {
      var uri = toVisit.removeLast();
      if (!visited.contains(uri)) {
        visited.add(uri);
        if (_moduleCache.libraryForUri.containsKey(uri)) {
          var lib = _moduleCache.libraryForUri[uri]!;
          libraries.add(lib);
          for (var dep in lib.dependencies) {
            if (dep.importedLibraryReference.node != null) {
              toVisit.add(dep.importedLibraryReference.asLibrary.importUri);
            } else {
              _processedOptions.ticker.logMs(
                  'Missing link for ${dep.importedLibraryReference.canonicalName}'
                  ' in ${lib.importUri}');
            }
          }
        } else {
          _processedOptions.ticker.logMs('No summary found for library: $uri');
        }
      }
    }

    return libraries;
  }

  /// Loads in the specified dill files and invalidates any existing ones.
  Future<Map<String, dynamic>> _updateDependencies(
      UpdateDependenciesRequest request) async {
    _processedOptions.ticker
        .logMs('Updating dependencies for expression evaluation');

    for (var input in request.inputs) {
      _clearCache(input.moduleName);
    }

    // Reset linking of libraries to the original state,
    // so any newly loaded components are linked to the
    // libraries in the cache.
    _resetCacheLinks();

    // Load summaries and store paths for full kernel files.
    // Note that we intentionally ignore loading failures here
    // as not all of them are fatal. We report missing dependencies
    // instead on expression evaluation.
    // TODO(annagrin): throw on load failures when blaze build starts
    // producing all summaries.
    var futures = <Future>[];
    for (var input in request.inputs) {
      // Support older debugger versions that do not provide summary
      // path by loading full dill kernel instead.
      var hasSummary = input.summaryPath != null;
      if (!hasSummary) {
        _processedOptions.ticker
            .logMs('Summary path is not provided for ${input.moduleName}.'
                ' Loading full dill instead.');
      }
      var summaryPath = input.summaryPath ?? input.path;
      _fullModules[input.moduleName] = Uri.parse(input.path);
      futures.add(_loadAndUpdateComponent(
          Uri.parse(summaryPath), input.moduleName, hasSummary));
    }
    await Future.wait(futures);

    _processedOptions.ticker
        .logMs('Updated dependencies for expression evaluation');
    return {'succeeded': true};
  }

  /// Load component and update cache.
  Future<bool> _loadAndUpdateComponent(
      Uri uri, String moduleName, bool isSummary) async {
    if (isSummary && _moduleCache.isModuleLoaded(moduleName)) return true;
    if (!isSummary && _moduleCache.isModuleFullyLoaded(moduleName)) return true;
    var componentKind = isSummary ? 'summary' : 'full kernel';

    _processedOptions.ticker.logMs('Loading $componentKind for $moduleName');
    var component = await _loadComponent(uri);
    if (component == null) {
      _processedOptions.ticker
          .logMs('Failed to load $componentKind for $moduleName');
      return false;
    }
    _updateCache(component, moduleName, isSummary);
    return true;
  }

  Future<Component?> _loadComponent(Uri uri) async {
    var file = _processedOptions.fileSystem.entityForUri(uri);
    if (await file.existsAsyncIfPossible()) {
      var bytes = await file.readAsBytesAsyncIfPossible();
      var component = _processedOptions.loadComponent(bytes, _sdkComponent.root,
          alwaysCreateNewNamedNodes: true);
      return component;
    }
    _processedOptions.ticker.logMs('File for $uri does not exist.');
    return null;
  }

  void _updateCache(Component component, String moduleName, bool isSummary) {
    // Do not update dart sdk as we don't expect it to change.
    if (moduleName == dartSdkModule &&
        _moduleCache.isModuleLoaded(moduleName)) {
      return;
    }
    var componentKind = isSummary ? 'summary' : 'full kernel';
    _processedOptions.ticker.logMs('Updating $componentKind for $moduleName');
    _moduleCache.addModule(moduleName, component, isSummary);
  }

  void _clearCache(String moduleName) {
    // Do not remove dart sdk as we don't expect it to change.
    if (moduleName == dartSdkModule) return;
    _moduleCache.removeModule(moduleName);
  }

  /// Reset library links and canonical name trees.
  void _resetCacheLinks() {
    // Adopting children for the sdk and all already loaded components means
    // that the root knows about all of it so anything new that is loaded will
    // link correctly.
    _sdkComponent.adoptChildren();
    for (var component in _moduleCache.componentForModuleName.values) {
      component.adoptChildren();
    }
  }

  bool _librariesAreKnown(ClassHierarchy hierarchy, List<Library> libraries) {
    for (var library in libraries) {
      if (!hierarchy.knownLibraries.contains(library)) return false;
    }
    return true;
  }

  bool _canSerialize(Component component) {
    var byteSink = _ByteSink();
    var printer = BinaryPrinter(byteSink);
    printer.writeComponentFile(component);
    return true;
  }
}

/// Module cache used to load modules and look up loaded libraries.
///
/// After each build, the cache is updated with summaries for
/// new or updated modules. The summaries can be replaced by
/// full dill kernel during a later expression evaluation in
/// the corresponding module.
class ModuleCache {
  final Map<Uri, Library> libraryForUri = {};
  final Map<Library, Component> componentForLibrary = {};
  final Map<String, Component> componentForModuleName = {};
  final Map<Component, String> moduleNameForComponent = {};
  final Set<String> fullyLoadedModules = {};
  final Map<String, ExpressionCompiler> expressionCompilers = {};

  bool isModuleLoaded(String moduleName) =>
      componentForModuleName.containsKey(moduleName);

  bool isModuleFullyLoaded(String moduleName) =>
      fullyLoadedModules.contains(moduleName);

  bool isLibraryLoaded(Library library) =>
      componentForLibrary.containsKey(library);

  void addModule(String moduleName, Component component, bool isSummary) {
    moduleNameForComponent[component] = moduleName;
    componentForModuleName[moduleName] = component;
    if (!isSummary) fullyLoadedModules.add(moduleName);

    for (var lib in component.libraries) {
      if (isLibraryLoaded(lib)) {
        throw Exception('library ${lib.importUri} is already loaded in '
            '${moduleNameForComponent[componentForLibrary[lib]!]}');
      }
      componentForLibrary[lib] = component;
      libraryForUri[lib.importUri] = lib;
    }
  }

  void removeModule(String moduleName) {
    if (isModuleLoaded(moduleName)) {
      var oldComponent = componentForModuleName[moduleName]!;
      for (var lib in oldComponent.libraries) {
        componentForLibrary.remove(lib);
        libraryForUri.remove(lib.importUri);
      }

      moduleNameForComponent.remove(oldComponent);
      componentForModuleName.remove(moduleName);
      fullyLoadedModules.remove(moduleName);
      expressionCompilers.remove(moduleName);
    }
  }
}

/// Expression compilation request to the expression compilation worker.
class CompileExpressionRequest {
  final int column;
  final String expression;
  final Map<String, String> jsModules;
  final Map<String, String> jsScope;
  final String libraryUri;
  final int line;
  final String moduleName;

  CompileExpressionRequest({
    required this.expression,
    required this.column,
    required this.jsModules,
    required this.jsScope,
    required this.libraryUri,
    required this.line,
    required this.moduleName,
  });

  factory CompileExpressionRequest.fromJson(Map<String, dynamic> json) =>
      CompileExpressionRequest(
        expression: json['expression'] as String,
        line: json['line'] as int,
        column: json['column'] as int,
        jsModules: Map<String, String>.from(json['jsModules'] as Map),
        jsScope: Map<String, String>.from(json['jsScope'] as Map),
        libraryUri: json['libraryUri'] as String,
        moduleName: json['moduleName'] as String,
      );
}

/// Module update request to the expression compilation worker.
class UpdateDependenciesRequest {
  final List<InputDill> inputs;

  UpdateDependenciesRequest(this.inputs);

  factory UpdateDependenciesRequest.fromJson(Map<String, dynamic> json) =>
      UpdateDependenciesRequest([
        for (var input in json['inputs'] as List)
          InputDill(input['path'] as String, input['summaryPath'] as String,
              input['moduleName'] as String),
      ]);
}

class InputDill {
  final String moduleName;
  final String path;
  final String? summaryPath;

  InputDill(this.path, this.summaryPath, this.moduleName);
}

void Function(DiagnosticMessage) _onDiagnosticHandler(
        List<String> errors, List<String> warnings, List<String> infos) =>
    (DiagnosticMessage message) {
      switch (message.severity) {
        case Severity.error:
        case Severity.internalProblem:
          errors.add(message.plainTextFormatted.join('\n'));
          break;
        case Severity.warning:
          warnings.add(message.plainTextFormatted.join('\n'));
          break;
        case Severity.info:
          infos.add(message.plainTextFormatted.join('\n'));
          break;
        case Severity.context:
        case Severity.ignored:
          throw 'Unexpected severity: ${message.severity}';
      }
    };

final argParser = ArgParser()
  ..addOption('dart-sdk-summary')
  ..addMultiOption('enable-experiment',
      help: 'Enable a language experiment when invoking the CFE.')
  ..addOption('libraries-file')
  ..addMultiOption('multi-root')
  ..addOption('multi-root-scheme', defaultsTo: 'org-dartlang-app')
  ..addOption('packages-file')
  ..addOption('sdk-root')
  ..addOption('asset-server-address')
  ..addOption('asset-server-port')
  ..addOption('module-format', defaultsTo: 'amd')
  ..addFlag('track-widget-creation', defaultsTo: false)
  ..addFlag('sound-null-safety', negatable: true, defaultsTo: true)
  ..addFlag('canary', negatable: true, defaultsTo: false)
  // Disable asserts in compiled code by default, which is different
  // from the default value of the setting in DDC.
  //
  // TODO(annagrin) Change the default to `true` after the user code
  // is tested with enabled asserts.
  // Issue: https://github.com/dart-lang/sdk/issues/43986
  ..addFlag('enable-asserts', negatable: true, defaultsTo: false)
  ..addFlag('verbose', defaultsTo: false);

Uri? _argToUri(String? uriArg) =>
    uriArg == null ? null : Uri.base.resolve(uriArg.replaceAll('\\', '/'));

class _ByteSink implements Sink<List<int>> {
  final BytesBuilder builder = BytesBuilder();

  @override
  void add(List<int> data) {
    builder.add(data);
  }

  @override
  void close() {}
}
