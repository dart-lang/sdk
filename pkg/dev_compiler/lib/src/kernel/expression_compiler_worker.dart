// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart';
import 'package:_fe_analyzer_shared/src/messages/severity.dart';
import 'package:args/args.dart';
import 'package:build_integration/file_system/multi_root.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:kernel/ast.dart' show Component, Library;
import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:meta/meta.dart';
import 'package:vm/http_filesystem.dart';

import '../compiler/js_names.dart';
import '../compiler/shared_command.dart';
import 'command.dart';
import 'compiler.dart';
import 'expression_compiler.dart';
import 'target.dart';

/// A wrapper around asset server that redirects file read requests
/// to http get requests to the asset server.
class AssetFileSystem extends HttpAwareFileSystem {
  final String server;
  final String port;

  AssetFileSystem(FileSystem original, this.server, this.port)
      : super(original);

  Uri resourceUri(Uri uri) =>
      Uri.parse('http://$server:$port/getResource?uri=${uri.toString()}');

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (uri.scheme == 'file') {
      return super.entityForUri(uri);
    }

    // pass the uri to the asset server in the debugger
    return HttpFileSystemEntity(this, resourceUri(uri));
  }
}

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
///      to dartdevc for sending responces from the service to the debugger.
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

  final _libraryForUri = <Uri, Library>{};
  final _componentForLibrary = <Library, Component>{};
  final _componentForModuleName = <String, Component>{};
  final _componentModuleNames = <Component, String>{};
  final ProcessedOptions _processedOptions;
  final CompilerOptions _compilerOptions;
  final Component _sdkComponent;

  ExpressionCompilerWorker._(
    this._processedOptions,
    this._compilerOptions,
    this._sdkComponent,
    this.requestStream,
    this.sendResponse,
  );

  static Future<ExpressionCompilerWorker> createFromArgs(
    List<String> args, {
    Stream<Map<String, dynamic>> requestStream,
    void Function(Map<String, dynamic>) sendResponse,
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
    var assetServerAddress = parsedArgs['asset-server-address'] as String;
    if (assetServerAddress != null) {
      var assetServerPort = parsedArgs['asset-server-port'] as String;
      fileSystem = AssetFileSystem(
          fileSystem, assetServerAddress, assetServerPort ?? '8080');
    }
    var explicitExperimentalFlags = parseExperimentalFlags(
        parseExperimentalArguments(
            parsedArgs['enable-experiment'] as List<String>),
        onError: (e) => throw e);
    return create(
      librariesSpecificationUri:
          _argToUri(parsedArgs['libraries-file'] as String),
      packagesFile: _argToUri(parsedArgs['packages-file'] as String),
      sdkSummary: _argToUri(parsedArgs['dart-sdk-summary'] as String),
      fileSystem: fileSystem,
      environmentDefines: environmentDefines,
      explicitExperimentalFlags: explicitExperimentalFlags,
      sdkRoot: _argToUri(parsedArgs['sdk-root'] as String),
      trackWidgetCreation: parsedArgs['track-widget-creation'] as bool,
      soundNullSafety: parsedArgs['sound-null-safety'] as bool,
      verbose: parsedArgs['verbose'] as bool,
      requestStream: requestStream,
      sendResponse: sendResponse,
    );
  }

  static List<String> errors = <String>[];
  static List<String> warnings = <String>[];

  /// Create the worker and load the sdk outlines.
  static Future<ExpressionCompilerWorker> create({
    @required Uri librariesSpecificationUri,
    @required Uri sdkSummary,
    @required FileSystem fileSystem,
    Uri packagesFile,
    Map<String, String> environmentDefines = const {},
    Map<ExperimentalFlag, bool> explicitExperimentalFlags = const {},
    Uri sdkRoot,
    bool trackWidgetCreation = false,
    bool soundNullSafety = false,
    bool verbose = false,
    Stream<Map<String, dynamic>> requestStream, // Defaults to read from stdin
    void Function(Map<String, dynamic>)
        sendResponse, // Defaults to write to stdout
  }) async {
    var compilerOptions = CompilerOptions()
      ..compileSdk = false
      ..sdkRoot = sdkRoot
      ..sdkSummary = sdkSummary
      ..packagesFileUri = packagesFile
      ..librariesSpecificationUri = librariesSpecificationUri
      ..target = DevCompilerTarget(
          TargetFlags(trackWidgetCreation: trackWidgetCreation))
      ..fileSystem = fileSystem
      ..omitPlatform = true
      ..environmentDefines = environmentDefines
      ..explicitExperimentalFlags = explicitExperimentalFlags
      ..onDiagnostic = _onDiagnosticHandler(errors, warnings)
      ..nnbdMode = soundNullSafety ? NnbdMode.Strong : NnbdMode.Weak
      ..verbose = verbose;
    requestStream ??= stdin
        .transform(utf8.decoder.fuse(json.decoder))
        .cast<Map<String, dynamic>>();
    sendResponse ??= (Map<String, dynamic> response) =>
        stdout.writeln(json.encode(response));
    var processedOptions = ProcessedOptions(options: compilerOptions);

    var sdkComponent = await CompilerContext(processedOptions)
        .runInContext<Component>((CompilerContext c) async {
      return processedOptions.loadSdkSummary(null);
    });

    return ExpressionCompilerWorker._(processedOptions, compilerOptions,
        sdkComponent, requestStream, sendResponse)
      .._update(sdkComponent, dartSdkModule);
  }

  /// Starts listening and responding to commands.
  ///
  /// Completes when the [requestStream] closes and we finish handling the
  /// requests.
  Future<void> start() async {
    await for (var request in requestStream) {
      try {
        var command = request['command'] as String;
        if (command == 'Shutdown') break;
        switch (command) {
          case 'UpdateDeps':
            sendResponse(
                await _updateDeps(UpdateDepsRequest.fromJson(request)));
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
        sendResponse({
          'exception': '$e',
          'stackTrace': '$s',
          'succeeded': false,
        });
      }
    }
    _processedOptions.ticker.logMs('Stopped expression compiler worker.');
  }

  /// Handles a `CompileExpression` request.
  Future<Map<String, dynamic>> _compileExpression(
      CompileExpressionRequest request) async {
    var libraryUri = Uri.parse(request.libraryUri);
    if (libraryUri.scheme == 'dart') {
      // compiling expressions inside the SDK currently fails because
      // SDK kernel outlines do not contain information that is needed
      // to detect the scope for expression evaluation - such as local
      // symbols and source file line starts.
      throw Exception('Expression compilation inside SDK is not supported yet');
    }

    var originalComponent = _componentForModuleName[request.moduleName];
    if (originalComponent == null) {
      throw ArgumentError(
          'Unable to find library `$libraryUri`, it must be loaded first.');
    }
    _processedOptions.ticker.logMs(
        'Compiling expression to JavaScript in module ${request.moduleName}');
    var component = _sdkComponent;

    if (libraryUri.scheme != 'dart') {
      var libraries =
          _collectTransitiveDependencies(originalComponent, _sdkComponent);
      component = Component(
        libraries: libraries,
        nameRoot: originalComponent.root,
        uriToSource: originalComponent.uriToSource,
      );
    }
    _processedOptions.ticker.logMs('Collected dependencies for expression');

    errors.clear();
    warnings.clear();

    var incrementalCompiler = IncrementalCompiler.forExpressionCompilationOnly(
        CompilerContext(_processedOptions), component, /*resetTicker*/ false);

    var finalComponent =
        await incrementalCompiler.computeDelta(entryPoints: [libraryUri]);
    finalComponent.computeCanonicalNames();
    _processedOptions.ticker.logMs('Computed delta for expression');

    if (errors.isNotEmpty) {
      return {
        'errors': errors,
        'warnings': warnings,
        'compiledProcedure': null,
        'succeeded': errors.isEmpty,
      };
    }

    var compiler = ProgramCompiler(
      finalComponent,
      incrementalCompiler.getClassHierarchy(),
      SharedCompilerOptions(
          sourceMap: true,
          summarizeApi: false,
          moduleName: request.moduleName,
          // Disable asserts due to failures to load source and
          // locations on kernel loaded from dill files in DDC.
          // https://github.com/dart-lang/sdk/issues/43986
          enableAsserts: false),
      _componentForLibrary,
      _componentModuleNames,
      coreTypes: incrementalCompiler.getCoreTypes(),
    );

    compiler.emitModule(finalComponent);
    _processedOptions.ticker.logMs('Emitted module for expression');

    var expressionCompiler = ExpressionCompiler(
      _compilerOptions,
      errors,
      incrementalCompiler,
      compiler,
      finalComponent,
    );

    var compiledProcedure = await expressionCompiler.compileExpressionToJs(
        request.libraryUri,
        request.line,
        request.column,
        request.jsScope,
        request.expression);

    _processedOptions.ticker.logMs('Compiled expression to JavaScript');

    return {
      'errors': errors,
      'warnings': warnings,
      'compiledProcedure': compiledProcedure,
      'succeeded': errors.isEmpty,
    };
  }

  List<Library> _collectTransitiveDependencies(
      Component component, Component sdk) {
    var libraries = <Library>{};
    libraries.addAll(sdk.libraries);

    var toVisit = <Library>[];
    toVisit.addAll(component.libraries);

    while (toVisit.isNotEmpty) {
      var lib = toVisit.removeLast();
      if (!libraries.contains(lib)) {
        libraries.add(lib);

        for (var dep in lib.dependencies) {
          var uri = dep.importedLibraryReference.asLibrary.importUri;
          var library = _libraryForUri[uri];
          assert(library == dep.importedLibraryReference.asLibrary);
          toVisit.add(library);
        }
      }
    }

    return libraries.toList();
  }

  /// Loads in the specified dill files and invalidates any existing ones.
  Future<Map<String, dynamic>> _updateDeps(UpdateDepsRequest request) async {
    _processedOptions.ticker
        .logMs('Updating dependencies for expression evaluation');

    for (var input in request.inputs) {
      var file =
          _processedOptions.fileSystem.entityForUri(Uri.parse(input.path));
      var bytes = await file.readAsBytes();
      var component = await _processedOptions.loadComponent(
          bytes, _sdkComponent.root,
          alwaysCreateNewNamedNodes: true);
      _update(component, input.moduleName);
    }

    _processedOptions.ticker
        .logMs('Updated dependencies for expression evaluation');
    return {'succeeded': true};
  }

  void _update(Component component, String moduleName) {
    // do not update dart sdk
    if (moduleName == dartSdkModule &&
        _componentForModuleName.containsKey(moduleName)) {
      return;
    }

    // cleanup old components and libraries
    if (_componentForModuleName.containsKey(moduleName)) {
      var oldComponent = _componentForModuleName[moduleName];
      for (var lib in oldComponent.libraries) {
        _componentForLibrary.remove(lib);
        _libraryForUri.remove(lib.importUri);
      }
      _componentModuleNames.remove(oldComponent);
      _componentForModuleName.remove(moduleName);
    }

    // add new components and libraries
    _componentModuleNames[component] = moduleName;
    _componentForModuleName[moduleName] = component;
    for (var lib in component.libraries) {
      _componentForLibrary[lib] = component;
      _libraryForUri[lib.importUri] = lib;
    }
  }
}

class CompileExpressionRequest {
  final int column;
  final String expression;
  final Map<String, String> jsModules;
  final Map<String, String> jsScope;
  final String libraryUri;
  final int line;
  final String moduleName;

  CompileExpressionRequest({
    @required this.expression,
    @required this.column,
    @required this.jsModules,
    @required this.jsScope,
    @required this.libraryUri,
    @required this.line,
    @required this.moduleName,
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

class UpdateDepsRequest {
  final List<InputDill> inputs;

  UpdateDepsRequest(this.inputs);

  factory UpdateDepsRequest.fromJson(Map<String, dynamic> json) =>
      UpdateDepsRequest([
        for (var input in json['inputs'] as List)
          InputDill(input['path'] as String, input['moduleName'] as String),
      ]);
}

class InputDill {
  final String moduleName;
  final String path;

  InputDill(this.path, this.moduleName);
}

void Function(DiagnosticMessage) _onDiagnosticHandler(
        List<String> errors, List<String> warnings) =>
    (DiagnosticMessage message) {
      switch (message.severity) {
        case Severity.error:
        case Severity.internalProblem:
          errors.add(message.plainTextFormatted.join('\n'));
          break;
        case Severity.warning:
          warnings.add(message.plainTextFormatted.join('\n'));
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
  ..addFlag('track-widget-creation', defaultsTo: false)
  ..addFlag('sound-null-safety', defaultsTo: false)
  ..addFlag('verbose', defaultsTo: false);

Uri _argToUri(String uriArg) =>
    uriArg == null ? null : Uri.base.resolve(uriArg.replaceAll('\\', '/'));
