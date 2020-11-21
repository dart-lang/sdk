// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:analysis_server/protocol/protocol_constants.dart'
    show PROTOCOL_VERSION;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/lsp_socket_server.dart';
import 'package:analysis_server/src/server/crash_reporting.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/server/detachable_filesystem_manager.dart';
import 'package:analysis_server/src/server/dev_server.dart';
import 'package:analysis_server/src/server/diagnostic_server.dart';
import 'package:analysis_server/src/server/error_notifier.dart';
import 'package:analysis_server/src/server/features.dart';
import 'package:analysis_server/src/server/http_server.dart';
import 'package:analysis_server/src/server/isolate_analysis_server.dart';
import 'package:analysis_server/src/server/lsp_stdio_server.dart';
import 'package:analysis_server/src/server/sdk_configuration.dart';
import 'package:analysis_server/src/server/stdio_server.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/src/utilities/request_statistics.dart';
import 'package:analysis_server/starter.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/file_instrumentation.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:args/args.dart';
import 'package:cli_util/cli_util.dart';
import 'package:linter/src/rules.dart' as linter;
import 'package:telemetry/crash_reporting.dart';
import 'package:telemetry/telemetry.dart' as telemetry;

/// The [Driver] class represents a single running instance of the analysis
/// server application.  It is responsible for parsing command line options
/// and starting the HTTP and/or stdio servers.
class Driver implements ServerStarter {
  /// The name of the application that is used to start a server.
  static const BINARY_NAME = 'analysis_server';

  /// The name of the option used to set the identifier for the client.
  static const String CLIENT_ID = 'client-id';

  /// The name of the option used to set the version for the client.
  static const String CLIENT_VERSION = 'client-version';

  /// The name of the option used to disable exception handling.
  static const String DISABLE_SERVER_EXCEPTION_HANDLING =
      'disable-server-exception-handling';

  /// The name of the option to disable the completion feature.
  static const String DISABLE_SERVER_FEATURE_COMPLETION =
      'disable-server-feature-completion';

  /// The name of the option to disable the search feature.
  static const String DISABLE_SERVER_FEATURE_SEARCH =
      'disable-server-feature-search';

  /// The name of the option used to print usage information.
  static const String HELP_OPTION = 'help';

  /// The name of the flag used to configure reporting analytics.
  static const String ANALYTICS_FLAG = 'analytics';

  /// Suppress analytics for this session.
  static const String SUPPRESS_ANALYTICS_FLAG = 'suppress-analytics';

  /// The name of the option used to cause instrumentation to also be written to
  /// a local file.
  static const String PROTOCOL_TRAFFIC_LOG = 'protocol-traffic-log';
  static const String PROTOCOL_TRAFFIC_LOG_ALIAS = 'instrumentation-log-file';

  /// The name of the option used to specify if [print] should print to the
  /// console instead of being intercepted.
  static const String INTERNAL_PRINT_TO_CONSOLE = 'internal-print-to-console';

  /// The name of the option used to describe the new analysis driver logger.
  static const String ANALYSIS_DRIVER_LOG = 'analysis-driver-log';
  static const String ANALYSIS_DRIVER_LOG_ALIAS = 'new-analysis-driver-log';

  /// The option for specifying the http diagnostic port.
  /// If specified, users can review server status and performance information
  /// by opening a web browser on http://localhost:<port>
  static const String DIAGNOSTIC_PORT = 'diagnostic-port';
  static const String DIAGNOSTIC_PORT_ALIAS = 'port';

  /// The path to the SDK.
  static const String DART_SDK = 'dart-sdk';
  static const String DART_SDK_ALIAS = 'sdk';

  /// The path to the data cache.
  static const String CACHE_FOLDER = 'cache';

  /// The name of the flag to use the Language Server Protocol (LSP).
  static const String USE_LSP = 'lsp';

  /// A directory to analyze in order to train an analysis server snapshot.
  static const String TRAIN_USING = 'train-using';

  /// The builder for attachments that should be included into crash reports.
  CrashReportingAttachmentsBuilder crashReportingAttachmentsBuilder =
      CrashReportingAttachmentsBuilder.empty;

  /// An optional manager to handle file systems which may not always be
  /// available.
  DetachableFileSystemManager detachableFileSystemManager;

  /// The instrumentation service that is to be used by the analysis server.
  InstrumentationService instrumentationService;

  HttpAnalysisServer httpServer;

  Driver();

  /// Use the given command-line [arguments] to start this server.
  ///
  /// If [sendPort] is not null, assumes this is launched in an isolate and will
  /// connect to the original isolate via an [IsolateChannel].
  @override
  void start(List<String> arguments, [SendPort sendPort]) {
    var parser = _createArgParser();
    var results = parser.parse(arguments);

    var analysisServerOptions = AnalysisServerOptions();
    analysisServerOptions.newAnalysisDriverLog =
        results[ANALYSIS_DRIVER_LOG] ?? results[ANALYSIS_DRIVER_LOG_ALIAS];
    analysisServerOptions.clientId = results[CLIENT_ID];
    analysisServerOptions.useLanguageServerProtocol = results[USE_LSP];
    // For clients that don't supply their own identifier, use a default based on
    // whether the server will run in LSP mode or not.
    analysisServerOptions.clientId ??=
        analysisServerOptions.useLanguageServerProtocol
            ? 'unknown.client.lsp'
            : 'unknown.client.classic';

    analysisServerOptions.clientVersion = results[CLIENT_VERSION];
    analysisServerOptions.cacheFolder = results[CACHE_FOLDER];

    // Read in any per-SDK overrides specified in <sdk>/config/settings.json.
    var sdkConfig = SdkConfiguration.readFromSdk();
    analysisServerOptions.configurationOverrides = sdkConfig;

    // Analytics
    bool disableAnalyticsForSession = results[SUPPRESS_ANALYTICS_FLAG];
    if (results.wasParsed(TRAIN_USING)) {
      disableAnalyticsForSession = true;
    }

    // Use sdkConfig to optionally override analytics settings.
    final analyticsId = sdkConfig.analyticsId ?? 'UA-26406144-29';
    final forceAnalyticsEnabled = sdkConfig.analyticsForceEnabled == true;
    var analytics = telemetry.createAnalyticsInstance(
      analyticsId,
      'analysis-server',
      disableForSession: disableAnalyticsForSession,
      forceEnabled: forceAnalyticsEnabled,
    );
    analysisServerOptions.analytics = analytics;

    // Record the client name as the application installer ID.
    analytics.setSessionValue('aiid', analysisServerOptions.clientId);
    if (analysisServerOptions.clientVersion != null) {
      analytics.setSessionValue('cd1', analysisServerOptions.clientVersion);
    }

    var shouldSendCallback = () {
      // Check sdkConfig to optionally force reporting on.
      if (sdkConfig.crashReportingForceEnabled == true) {
        return true;
      }

      // TODO(devoncarew): Replace with a real enablement check.
      return false;
    };

    // Crash reporting

    // Use sdkConfig to optionally override analytics settings.
    final crashProductId = sdkConfig.crashReportingId ?? 'Dart_analysis_server';
    final crashReportSender =
        CrashReportSender.prod(crashProductId, shouldSendCallback);

    if (telemetry.SHOW_ANALYTICS_UI) {
      if (results.wasParsed(ANALYTICS_FLAG)) {
        analytics.enabled = results[ANALYTICS_FLAG];
        print(telemetry.createAnalyticsStatusMessage(analytics.enabled));
        return null;
      }
    }

    {
      bool disableCompletion = results[DISABLE_SERVER_FEATURE_COMPLETION];
      bool disableSearch = results[DISABLE_SERVER_FEATURE_SEARCH];
      if (disableCompletion || disableSearch) {
        analysisServerOptions.featureSet = FeatureSet(
          completion: !disableCompletion,
          search: !disableSearch,
        );
      }
    }

    if (results[HELP_OPTION]) {
      _printUsage(parser, analytics, fromHelp: true);
      return null;
    }

    final defaultSdkPath = _getSdkPath(results);
    final dartSdkManager = DartSdkManager(defaultSdkPath);

    // TODO(brianwilkerson) It would be nice to avoid creating an SDK that
    // cannot be re-used, but the SDK is needed to create a package map provider
    // in the case where we need to run `pub` in order to get the package map.
    var defaultSdk = _createDefaultSdk(defaultSdkPath);
    //
    // Initialize the instrumentation service.
    //
    String logFilePath =
        results[PROTOCOL_TRAFFIC_LOG] ?? results[PROTOCOL_TRAFFIC_LOG_ALIAS];
    var allInstrumentationServices = instrumentationService == null
        ? <InstrumentationService>[]
        : [instrumentationService];
    if (logFilePath != null) {
      _rollLogFiles(logFilePath, 5);
      allInstrumentationServices.add(
          InstrumentationLogAdapter(FileInstrumentationLogger(logFilePath)));
    }

    var errorNotifier = ErrorNotifier();
    allInstrumentationServices
        .add(CrashReportingInstrumentation(crashReportSender));
    instrumentationService =
        MulticastInstrumentationService(allInstrumentationServices);

    instrumentationService.logVersion(
      results[TRAIN_USING] != null
          ? 'training-0'
          : _readUuid(instrumentationService),
      analysisServerOptions.clientId,
      analysisServerOptions.clientVersion,
      PROTOCOL_VERSION,
      defaultSdk.languageVersion.toString(),
    );
    AnalysisEngine.instance.instrumentationService = instrumentationService;

    int diagnosticServerPort;
    final String portValue =
        results[DIAGNOSTIC_PORT] ?? results[DIAGNOSTIC_PORT_ALIAS];
    if (portValue != null) {
      try {
        diagnosticServerPort = int.parse(portValue);
      } on FormatException {
        print('Invalid port number: $portValue');
        print('');
        _printUsage(parser, analytics);
        exitCode = 1;
        return null;
      }
    }

    if (analysisServerOptions.useLanguageServerProtocol) {
      if (sendPort != null) {
        throw UnimplementedError(
            'Isolate usage not implemented for LspAnalysisServer');
      }
      startLspServer(results, analysisServerOptions, dartSdkManager,
          instrumentationService, diagnosticServerPort, errorNotifier);
    } else {
      startAnalysisServer(
          results,
          analysisServerOptions,
          parser,
          dartSdkManager,
          crashReportingAttachmentsBuilder,
          instrumentationService,
          RequestStatisticsHelper(),
          analytics,
          diagnosticServerPort,
          errorNotifier,
          sendPort);
    }
  }

  void startAnalysisServer(
    ArgResults results,
    AnalysisServerOptions analysisServerOptions,
    ArgParser parser,
    DartSdkManager dartSdkManager,
    CrashReportingAttachmentsBuilder crashReportingAttachmentsBuilder,
    InstrumentationService instrumentationService,
    RequestStatisticsHelper requestStatistics,
    telemetry.Analytics analytics,
    int diagnosticServerPort,
    ErrorNotifier errorNotifier,
    SendPort sendPort,
  ) {
    var capture = results[DISABLE_SERVER_EXCEPTION_HANDLING]
        ? (_, Function f, {Function(String) print}) => f()
        : _captureExceptions;
    String trainDirectory = results[TRAIN_USING];
    if (trainDirectory != null) {
      if (!FileSystemEntity.isDirectorySync(trainDirectory)) {
        print("Training directory '$trainDirectory' not found.\n");
        exitCode = 1;
        return null;
      }
    }
    final serve_http = diagnosticServerPort != null;

    //
    // Register lint rules.
    //
    linter.registerLintRules();

    var diagnosticServer = _DiagnosticServerImpl();

    // Ping analytics with our initial call.
    analytics.sendScreenView('home');

    //
    // Create the sockets and start listening for requests.
    //
    final socketServer = SocketServer(
        analysisServerOptions,
        dartSdkManager,
        crashReportingAttachmentsBuilder,
        instrumentationService,
        requestStatistics,
        diagnosticServer,
        detachableFileSystemManager);
    httpServer = HttpAnalysisServer(socketServer);

    errorNotifier.server = socketServer.analysisServer;

    diagnosticServer.httpServer = httpServer;
    if (serve_http) {
      diagnosticServer.startOnPort(diagnosticServerPort);
    }

    if (trainDirectory != null) {
      if (sendPort != null) {
        throw UnimplementedError(
            'isolate usage not supported for DevAnalysisServer');
      }
      var tempDriverDir =
          Directory.systemTemp.createTempSync('analysis_server_');
      analysisServerOptions.cacheFolder = tempDriverDir.path;

      var devServer = DevAnalysisServer(socketServer);
      devServer.initServer();

      () async {
        // We first analyze code with an empty driver cache.
        print('Analyzing with an empty driver cache:');
        var exitCode = await devServer.processDirectories([trainDirectory]);
        if (exitCode != 0) exit(exitCode);

        print('');

        // Then again with a populated cache.
        print('Analyzing with a populated driver cache:');
        exitCode = await devServer.processDirectories([trainDirectory]);
        if (exitCode != 0) exit(exitCode);

        if (serve_http) {
          httpServer.close();
        }
        await instrumentationService.shutdown();

        socketServer.analysisServer.shutdown();

        try {
          tempDriverDir.deleteSync(recursive: true);
        } catch (_) {
          // ignore any exception
        }

        exit(exitCode);
      }();
    } else {
      capture(instrumentationService, () {
        Future serveResult;
        if (sendPort == null) {
          var stdioServer = StdioAnalysisServer(socketServer);
          serveResult = stdioServer.serveStdio();
        } else {
          var isolateAnalysisServer = IsolateAnalysisServer(socketServer);
          serveResult = isolateAnalysisServer.serveIsolate(sendPort);
        }
        serveResult.then((_) async {
          if (serve_http) {
            httpServer.close();
          }
          await instrumentationService.shutdown();
          socketServer.analysisServer.shutdown();
          if (sendPort == null) exit(0);
        });
      },
          print: results[INTERNAL_PRINT_TO_CONSOLE]
              ? null
              : httpServer.recordPrint);
    }
  }

  void startLspServer(
    ArgResults args,
    AnalysisServerOptions analysisServerOptions,
    DartSdkManager dartSdkManager,
    InstrumentationService instrumentationService,
    int diagnosticServerPort,
    ErrorNotifier errorNotifier,
  ) {
    var capture = args[DISABLE_SERVER_EXCEPTION_HANDLING]
        ? (_, Function f, {Function(String) print}) => f()
        : _captureExceptions;
    final serve_http = diagnosticServerPort != null;

    linter.registerLintRules();

    var diagnosticServer = _DiagnosticServerImpl();

    final socketServer = LspSocketServer(
      analysisServerOptions,
      diagnosticServer,
      dartSdkManager,
      instrumentationService,
    );
    errorNotifier.server = socketServer.analysisServer;

    httpServer = HttpAnalysisServer(socketServer);

    diagnosticServer.httpServer = httpServer;
    if (serve_http) {
      diagnosticServer.startOnPort(diagnosticServerPort);
    }

    capture(instrumentationService, () {
      var stdioServer = LspStdioAnalysisServer(socketServer);
      stdioServer.serveStdio().then((_) async {
        // Only shutdown the server and exit if the server is not already
        // handling the shutdown.
        if (!socketServer.analysisServer.willExit) {
          socketServer.analysisServer.shutdown();
          exit(0);
        }
      });
    });
  }

  /// Execute the given [callback] within a zone that will capture any unhandled
  /// exceptions and both report them to the client and send them to the given
  /// instrumentation [service]. If a [print] function is provided, then also
  /// capture any data printed by the callback and redirect it to the function.
  void _captureExceptions(
      InstrumentationService service, void Function() callback,
      {void Function(String line) print}) {
    void errorFunction(Zone self, ZoneDelegate parent, Zone zone,
        dynamic exception, StackTrace stackTrace) {
      service.logException(exception, stackTrace);
      throw exception;
    }

    var printFunction = print == null
        ? null
        : (Zone self, ZoneDelegate parent, Zone zone, String line) {
            // Note: we don't pass the line on to stdout, because that is
            // reserved for communication to the client.
            print(line);
          };
    var zoneSpecification = ZoneSpecification(
        handleUncaughtError: errorFunction, print: printFunction);
    return runZoned(callback, zoneSpecification: zoneSpecification);
  }

  /// Create and return the parser used to parse the command-line arguments.
  ArgParser _createArgParser() {
    var parser = ArgParser();
    parser.addFlag(HELP_OPTION,
        abbr: 'h', negatable: false, help: 'Print this usage information.');
    parser.addOption(CLIENT_ID,
        valueHelp: 'name',
        help: 'An identifier for the analysis server client.');
    parser.addOption(CLIENT_VERSION,
        valueHelp: 'version',
        help: 'The version of the analysis server client.');
    parser.addOption(DART_SDK,
        valueHelp: 'path', help: 'Override the Dart SDK to use for analysis.');
    parser.addOption(DART_SDK_ALIAS, hide: true);
    parser.addOption(CACHE_FOLDER,
        valueHelp: 'path',
        help: 'Override the location of the analysis server\'s cache.');
    parser.addFlag(USE_LSP,
        defaultsTo: false,
        negatable: false,
        help: 'Whether to use the Language Server Protocol (LSP).');

    parser.addSeparator('Server diagnostics:');

    parser.addOption(PROTOCOL_TRAFFIC_LOG,
        valueHelp: 'file path',
        help: 'Write server protocol traffic to the given file.');
    parser.addOption(PROTOCOL_TRAFFIC_LOG_ALIAS, hide: true);

    parser.addOption(ANALYSIS_DRIVER_LOG,
        valueHelp: 'file path',
        help: 'Write analysis driver diagnostic data to the given file.');
    parser.addOption(ANALYSIS_DRIVER_LOG_ALIAS, hide: true);

    parser.addOption(DIAGNOSTIC_PORT,
        valueHelp: 'port',
        help: 'Serve a web UI for status and performance data on the given '
            'port.');
    parser.addOption(DIAGNOSTIC_PORT_ALIAS, hide: true);

    //
    // Hidden; these have not yet been made public.
    //
    parser.addFlag(ANALYTICS_FLAG,
        help: 'enable or disable sending analytics information to Google',
        hide: !telemetry.SHOW_ANALYTICS_UI);
    parser.addFlag(SUPPRESS_ANALYTICS_FLAG,
        negatable: false,
        help: 'suppress analytics for this session',
        hide: !telemetry.SHOW_ANALYTICS_UI);

    //
    // Hidden; these are for internal development.
    //
    parser.addOption(TRAIN_USING,
        valueHelp: 'path',
        help: 'Pass in a directory to analyze for purposes of training an '
            'analysis server snapshot.',
        hide: true);
    parser.addFlag(DISABLE_SERVER_EXCEPTION_HANDLING,
        // TODO(jcollins-g): Pipeline option through and apply to all
        // exception-nullifying runZoned() calls.
        help: 'disable analyzer exception capture for interactive debugging '
            'of the server',
        defaultsTo: false,
        hide: true);
    parser.addFlag(DISABLE_SERVER_FEATURE_COMPLETION,
        help: 'disable all completion features', defaultsTo: false, hide: true);
    parser.addFlag(DISABLE_SERVER_FEATURE_SEARCH,
        help: 'disable all search features', defaultsTo: false, hide: true);
    parser.addFlag(INTERNAL_PRINT_TO_CONSOLE,
        help: 'enable sending `print` output to the console',
        defaultsTo: false,
        negatable: false,
        hide: true);

    //
    // Hidden; these are deprecated and no longer read from.
    //

    // Removed 11/15/2020.
    parser.addOption('completion-model', hide: true);
    // Removed 11/8/2020.
    parser.addFlag('dartpad', hide: true);
    // Removed 11/15/2020.
    parser.addFlag('enable-completion-model', hide: true);
    // Removed 10/30/2020.
    parser.addMultiOption('enable-experiment', hide: true);
    // Removed 9/23/2020.
    parser.addFlag('enable-instrumentation', hide: true);
    // Removed 11/12/2020.
    parser.addOption('file-read-mode', hide: true);
    // Removed 11/12/2020.
    parser.addFlag('ignore-unrecognized-flags', hide: true);
    // Removed 11/8/2020.
    parser.addFlag('preview-dart-2', hide: true);
    // Removed 11/12/2020.
    parser.addFlag('useAnalysisHighlight2', hide: true);
    // Removed 11/13/2020.
    parser.addFlag('use-new-relevance', hide: true);
    // Removed 9/23/2020.
    parser.addFlag('use-fasta-parser', hide: true);

    return parser;
  }

  DartSdk _createDefaultSdk(String defaultSdkPath) {
    var resourceProvider = PhysicalResourceProvider.INSTANCE;
    return FolderBasedDartSdk(
      resourceProvider,
      resourceProvider.getFolder(defaultSdkPath),
    );
  }

  /// Constructs a uuid combining the current date and a random integer.
  String _generateUuidString() {
    var millisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;
    var random = Random().nextInt(0x3fffffff);
    return '$millisecondsSinceEpoch$random';
  }

  String _getSdkPath(ArgResults args) {
    if (args[DART_SDK] != null) {
      return args[DART_SDK];
    } else if (args[DART_SDK_ALIAS] != null) {
      return args[DART_SDK_ALIAS];
    } else {
      return getSdkPath();
    }
  }

  /// Print information about how to use the server.
  void _printUsage(
    ArgParser parser,
    telemetry.Analytics analytics, {
    bool fromHelp = false,
  }) {
    print('Usage: $BINARY_NAME [flags]');
    print('');
    print('Supported flags are:');
    print(parser.usage);

    if (telemetry.SHOW_ANALYTICS_UI) {
      // Print analytics status and information.
      if (fromHelp) {
        print('');
        print(telemetry.analyticsNotice);
      }
      print('');
      print(telemetry.createAnalyticsStatusMessage(analytics.enabled,
          command: ANALYTICS_FLAG));
    }
  }

  /// Read the UUID from disk, generating and storing a new one if necessary.
  String _readUuid(InstrumentationService service) {
    final instrumentationLocation =
        PhysicalResourceProvider.INSTANCE.getStateLocation('.instrumentation');
    if (instrumentationLocation == null) {
      return _generateUuidString();
    }
    var uuidFile = File(instrumentationLocation.getChild('uuid.txt').path);
    try {
      if (uuidFile.existsSync()) {
        var uuid = uuidFile.readAsStringSync();
        if (uuid != null && uuid.length > 5) {
          return uuid;
        }
      }
    } catch (exception, stackTrace) {
      service.logException(exception, stackTrace);
    }
    var uuid = _generateUuidString();
    try {
      uuidFile.parent.createSync(recursive: true);
      uuidFile.writeAsStringSync(uuid);
    } catch (exception, stackTrace) {
      service.logException(exception, stackTrace);
      // Slightly alter the uuid to indicate it was not persisted
      uuid = 'temp-$uuid';
    }
    return uuid;
  }

  /// Perform log files rolling.
  ///
  /// Rename existing files with names `[path].(x)` to `[path].(x+1)`.
  /// Keep at most [numOld] files.
  /// Rename the file with the given [path] to `[path].1`.
  static void _rollLogFiles(String path, int numOld) {
    for (var i = numOld - 1; i >= 0; i--) {
      try {
        var oldPath = i == 0 ? path : '$path.$i';
        File(oldPath).renameSync('$path.${i + 1}');
      } catch (e) {
        // If a file can't be renamed, then leave it and attempt to rename the
        // remaining files.
      }
    }
  }
}

/// Implements the [DiagnosticServer] class by wrapping an [HttpAnalysisServer].
class _DiagnosticServerImpl extends DiagnosticServer {
  HttpAnalysisServer httpServer;

  _DiagnosticServerImpl();

  @override
  Future<int> getServerPort() => httpServer.serveHttp();

  Future startOnPort(int port) {
    return httpServer.serveHttp(port);
  }
}
