// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi' as ffi;
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
import 'package:analysis_server/src/services/completion/dart/completion_ranking.dart';
import 'package:analysis_server/src/services/completion/dart/uri_contributor.dart'
    show UriContributor;
import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/src/utilities/request_statistics.dart';
import 'package:analysis_server/starter.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/file_instrumentation.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:args/args.dart';
import 'package:cli_util/cli_util.dart';
import 'package:linter/src/rules.dart' as linter;
import 'package:path/path.dart' as path;
import 'package:telemetry/crash_reporting.dart';
import 'package:telemetry/telemetry.dart' as telemetry;

/// Commandline argument parser. (Copied from analyzer/lib/options.dart)
/// TODO(pquitslund): replaces with a simple [ArgParser] instance
/// when the args package supports ignoring unrecognized
/// options/flags (https://github.com/dart-lang/args/issues/9).
/// TODO(devoncarew): Consider removing the ability to support unrecognized
/// flags for the analysis server.
class CommandLineParser {
  final List<String> _knownFlags;
  final ArgParser _parser;

  /// Creates a new command line parser
  CommandLineParser()
      : _knownFlags = <String>[],
        _parser = ArgParser(allowTrailingOptions: true);

  ArgParser get parser => _parser;

  /// Defines a flag.
  /// See [ArgParser.addFlag()].
  void addFlag(String name,
      {String abbr,
      String help,
      bool defaultsTo = false,
      bool negatable = true,
      void Function(bool value) callback,
      bool hide = false}) {
    _knownFlags.add(name);
    _parser.addFlag(name,
        abbr: abbr,
        help: help,
        defaultsTo: defaultsTo,
        negatable: negatable,
        callback: callback,
        hide: hide);
  }

  /// Defines an option that takes multiple values.
  /// See [ArgParser.addMultiOption].
  void addMultiOption(String name,
      {String abbr,
      String help,
      String valueHelp,
      Iterable<String> allowed,
      Map<String, String> allowedHelp,
      Iterable<String> defaultsTo,
      void Function(List<String> values) callback,
      bool splitCommas = true,
      bool hide = false}) {
    _knownFlags.add(name);
    _parser.addMultiOption(name,
        abbr: abbr,
        help: help,
        valueHelp: valueHelp,
        allowed: allowed,
        allowedHelp: allowedHelp,
        defaultsTo: defaultsTo,
        callback: callback,
        splitCommas: splitCommas,
        hide: hide);
  }

  /// Defines a value-taking option.
  /// See [ArgParser.addOption()].
  void addOption(String name,
      {String abbr,
      String help,
      List<String> allowed,
      Map<String, String> allowedHelp,
      String defaultsTo,
      void Function(Object) callback}) {
    _knownFlags.add(name);
    _parser.addOption(name,
        abbr: abbr,
        help: help,
        allowed: allowed,
        allowedHelp: allowedHelp,
        defaultsTo: defaultsTo,
        callback: callback);
  }

  /// Generates a string displaying usage information for the defined options.
  /// See [ArgParser.usage].
  String getUsage() => _parser.usage;

  /// Parses [args], a list of command-line arguments, matches them against the
  /// flags and options defined by this parser, and returns the result. The
  /// values of any defined variables are captured in the given map.
  /// See [ArgParser].
  ArgResults parse(List<String> args, Map<String, String> definedVariables) =>
      _parser.parse(
          _filterUnknowns(parseDefinedVariables(args, definedVariables)));

  List<String> parseDefinedVariables(
      List<String> args, Map<String, String> definedVariables) {
    var count = args.length;
    var remainingArgs = <String>[];
    for (var i = 0; i < count; i++) {
      var arg = args[i];
      if (arg == '--') {
        while (i < count) {
          remainingArgs.add(args[i++]);
        }
      } else if (arg.startsWith('-D')) {
        definedVariables[arg.substring(2)] = args[++i];
      } else {
        remainingArgs.add(arg);
      }
    }
    return remainingArgs;
  }

  List<String> _filterUnknowns(List<String> args) {
    // TODO(devoncarew): Consider dropping support for the
    // --ignore-unrecognized-flags option.

    // Only filter args if the ignore flag is specified.
    if (args.contains('--ignore-unrecognized-flags')) {
      // Filter all unrecognized flags and options.
      var filtered = <String>[];
      for (var i = 0; i < args.length; ++i) {
        var arg = args[i];
        if (arg.startsWith('--') && arg.length > 2) {
          var option = arg.substring(2);
          // remove any leading 'no-'
          if (option.startsWith('no-')) {
            option = option.substring(3);
          }
          // strip the last '=value'
          var equalsOffset = option.lastIndexOf('=');
          if (equalsOffset != -1) {
            option = option.substring(0, equalsOffset);
          }
          // check the option
          if (!_knownFlags.contains(option)) {
            //"eat" params by advancing to the next flag/option
            i = _getNextFlagIndex(args, i);
          } else {
            filtered.add(arg);
          }
        } else {
          filtered.add(arg);
        }
      }

      return filtered;
    } else {
      return args;
    }
  }

  int _getNextFlagIndex(List<String> args, int i) {
    for (; i < args.length; ++i) {
      if (args[i].startsWith('--')) {
        return i;
      }
    }
    return i;
  }
}

/// The [Driver] class represents a single running instance of the analysis
/// server application.  It is responsible for parsing command line options
/// and starting the HTTP and/or stdio servers.
class Driver implements ServerStarter {
  /// The name of the application that is used to start a server.
  static const BINARY_NAME = 'server';

  /// The name of the option used to set the identifier for the client.
  static const String CLIENT_ID = 'client-id';

  /// The name of the option used to set the version for the client.
  static const String CLIENT_VERSION = 'client-version';

  /// The name of the option used to enable DartPad specific functionality.
  static const String DARTPAD_OPTION = 'dartpad';

  /// The name of the option used to disable exception handling.
  static const String DISABLE_SERVER_EXCEPTION_HANDLING =
      'disable-server-exception-handling';

  /// The name of the option to disable the completion feature.
  static const String DISABLE_SERVER_FEATURE_COMPLETION =
      'disable-server-feature-completion';

  /// The name of the option to disable the search feature.
  static const String DISABLE_SERVER_FEATURE_SEARCH =
      'disable-server-feature-search';

  /// The name of the option used to enable experiments.
  static const String ENABLE_EXPERIMENT_OPTION = 'enable-experiment';

  /// The name of the option used to enable instrumentation.
  static const String ENABLE_INSTRUMENTATION_OPTION = 'enable-instrumentation';

  /// The name of the option used to set the file read mode.
  static const String FILE_READ_MODE = 'file-read-mode';

  /// The name of the option used to print usage information.
  static const String HELP_OPTION = 'help';

  /// The name of the flag used to configure reporting analytics.
  static const String ANALYTICS_FLAG = 'analytics';

  /// Suppress analytics for this session.
  static const String SUPPRESS_ANALYTICS_FLAG = 'suppress-analytics';

  /// The name of the option used to cause instrumentation to also be written to
  /// a local file.
  static const String INSTRUMENTATION_LOG_FILE = 'instrumentation-log-file';

  /// The name of the option used to specify if [print] should print to the
  /// console instead of being intercepted.
  static const String INTERNAL_PRINT_TO_CONSOLE = 'internal-print-to-console';

  /// The name of the option used to describe the new analysis driver logger.
  static const String NEW_ANALYSIS_DRIVER_LOG = 'new-analysis-driver-log';

  /// The name of the flag used to enable version 2 of semantic highlight
  /// notification.
  static const String USE_ANALYSIS_HIGHLIGHT2 = 'useAnalysisHighlight2';

  /// The option for specifying the http diagnostic port.
  /// If specified, users can review server status and performance information
  /// by opening a web browser on http://localhost:<port>
  static const String PORT_OPTION = 'port';

  /// The path to the SDK.
  static const String SDK_OPTION = 'sdk';

  /// The path to the data cache.
  static const String CACHE_FOLDER = 'cache';

  /// Whether to enable parsing via the Fasta parser.
  static const String USE_FASTA_PARSER = 'use-fasta-parser';

  /// The name of the flag to use the Language Server Protocol (LSP).
  static const String USE_LSP = 'lsp';

  /// Whether or not to enable ML ranking for code completion.
  static const String ENABLE_COMPLETION_MODEL = 'enable-completion-model';

  /// The path on disk to a directory containing language model files for smart
  /// code completion.
  static const String COMPLETION_MODEL_FOLDER = 'completion-model';

  /// A directory to analyze in order to train an analysis server snapshot.
  static const String TRAIN_USING = 'train-using';

  /// A flag indicating that the new code completion relevance computation
  /// should be used to compute relevance scores.
  static const String USE_NEW_RELEVANCE = 'use-new-relevance';

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
    var results = parser.parse(arguments, <String, String>{});

    var analysisServerOptions = AnalysisServerOptions();
    analysisServerOptions.useAnalysisHighlight2 =
        results[USE_ANALYSIS_HIGHLIGHT2];
    analysisServerOptions.fileReadMode = results[FILE_READ_MODE];
    analysisServerOptions.newAnalysisDriverLog =
        results[NEW_ANALYSIS_DRIVER_LOG];
    analysisServerOptions.clientId = results[CLIENT_ID];
    analysisServerOptions.clientVersion = results[CLIENT_VERSION];
    analysisServerOptions.cacheFolder = results[CACHE_FOLDER];
    if (results.wasParsed(ENABLE_EXPERIMENT_OPTION)) {
      analysisServerOptions.enabledExperiments =
          (results[ENABLE_EXPERIMENT_OPTION] as List).cast<String>().toList();
    }
    analysisServerOptions.useFastaParser = results[USE_FASTA_PARSER];
    analysisServerOptions.useLanguageServerProtocol = results[USE_LSP];
    analysisServerOptions.useNewRelevance = results[USE_NEW_RELEVANCE];

    // Read in any per-SDK overrides specified in <sdk>/config/settings.json.
    var sdkConfig = SdkConfiguration.readFromSdk();
    analysisServerOptions.configurationOverrides = sdkConfig;

    // ML model configuration.
    final bool enableCompletionModel = results[ENABLE_COMPLETION_MODEL];
    analysisServerOptions.completionModelFolder =
        results[COMPLETION_MODEL_FOLDER];
    if (results.wasParsed(ENABLE_COMPLETION_MODEL) && !enableCompletionModel) {
      // This is the case where the user has explicitly turned off model-based
      // code completion.
      analysisServerOptions.completionModelFolder = null;
    }
    // TODO(devoncarew): Simplify this logic and use the value from sdkConfig.
    if (enableCompletionModel &&
        analysisServerOptions.completionModelFolder == null) {
      // The user has enabled ML code completion without explicitly setting a
      // model for us to choose, so use the default one. We need to walk over
      // from $SDK/bin/snapshots/analysis_server.dart.snapshot to
      // $SDK/bin/model/lexeme.
      analysisServerOptions.completionModelFolder = path.join(
        File.fromUri(Platform.script).parent.path,
        '..',
        'model',
        'lexeme',
      );
    }

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
    analytics.setSessionValue(
        'aiid', analysisServerOptions.clientId ?? 'not-set');
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
    // TODO(mfairhurst): send these to prod or disable.
    final crashReportSenderAngular = CrashReportSender.staging(
        'Dart_angular_analysis_plugin', shouldSendCallback);

    if (telemetry.SHOW_ANALYTICS_UI) {
      if (results.wasParsed(ANALYTICS_FLAG)) {
        analytics.enabled = results[ANALYTICS_FLAG];
        print(telemetry.createAnalyticsStatusMessage(analytics.enabled));
        return null;
      }
    }

    if (results[DARTPAD_OPTION]) {
      UriContributor.suggestFilePaths = false;
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
      _printUsage(parser.parser, analytics, fromHelp: true);
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
    String logFilePath = results[INSTRUMENTATION_LOG_FILE];
    var allInstrumentationServices = instrumentationService == null
        ? <InstrumentationService>[]
        : [instrumentationService];
    if (logFilePath != null) {
      _rollLogFiles(logFilePath, 5);
      allInstrumentationServices.add(
          InstrumentationLogAdapter(FileInstrumentationLogger(logFilePath)));
    }

    var errorNotifier = ErrorNotifier();
    allInstrumentationServices.add(CrashReportingInstrumentation(
        crashReportSender, crashReportSenderAngular));
    instrumentationService =
        MulticastInstrumentationService(allInstrumentationServices);

    instrumentationService.logVersion(
        results[TRAIN_USING] != null
            ? 'training-0'
            : _readUuid(instrumentationService),
        analysisServerOptions.clientId,
        analysisServerOptions.clientVersion,
        PROTOCOL_VERSION,
        defaultSdk.sdkVersion);
    AnalysisEngine.instance.instrumentationService = instrumentationService;

    int diagnosticServerPort;
    if (results[PORT_OPTION] != null) {
      try {
        diagnosticServerPort = int.parse(results[PORT_OPTION]);
      } on FormatException {
        print('Invalid port number: ${results[PORT_OPTION]}');
        print('');
        _printUsage(parser.parser, analytics);
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
    CommandLineParser parser,
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
        startCompletionRanking(socketServer, null, analysisServerOptions);
      },
          print: results[INTERNAL_PRINT_TO_CONSOLE]
              ? null
              : httpServer.recordPrint);
    }
  }

  /// This will be invoked after createAnalysisServer has been called on the
  /// socket server. At that point, we'll be able to send a server.error
  /// notification in case model startup fails.
  void startCompletionRanking(
      SocketServer socketServer,
      LspSocketServer lspSocketServer,
      AnalysisServerOptions analysisServerOptions) {
    // If ML completion is not enabled, or we're on a 32-bit machine, don't try
    // and start the completion model.
    if (analysisServerOptions.completionModelFolder == null ||
        ffi.sizeOf<ffi.IntPtr>() == 4) {
      return;
    }

    // Start completion model isolate if this is a 64 bit system and analysis
    // server was configured to load a language model on disk.
    CompletionRanking.instance =
        CompletionRanking(analysisServerOptions.completionModelFolder);
    CompletionRanking.instance.start().catchError((exception, stackTrace) {
      // Disable smart ranking if model startup fails.
      analysisServerOptions.completionModelFolder = null;
      // TODO(brianwilkerson) Shutdown the isolates that have already been
      //  started.
      CompletionRanking.instance = null;
      AnalysisEngine.instance.instrumentationService.logException(
          CaughtException.withMessage(
              'Failed to start ranking model isolate', exception, stackTrace));
    });
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
      startCompletionRanking(null, socketServer, analysisServerOptions);
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
  CommandLineParser _createArgParser() {
    var parser = CommandLineParser();
    parser.addOption(CLIENT_ID,
        help: 'an identifier used to identify the client');
    parser.addOption(CLIENT_VERSION, help: 'the version of the client');
    parser.addFlag(DARTPAD_OPTION,
        help: 'enable DartPad specific functionality',
        defaultsTo: false,
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
    parser.addMultiOption(ENABLE_EXPERIMENT_OPTION,
        help: 'Enable one or more experimental features. If multiple features '
            'are being added, they should be comma separated.',
        hide: true,
        splitCommas: true);
    parser.addFlag(ENABLE_INSTRUMENTATION_OPTION,
        help: 'enable sending instrumentation information to a server',
        defaultsTo: false,
        negatable: false);
    parser.addFlag(HELP_OPTION,
        help: 'print this help message without starting a server',
        abbr: 'h',
        defaultsTo: false,
        negatable: false);
    parser.addOption(INSTRUMENTATION_LOG_FILE,
        help: 'write instrumentation data to the given file');
    parser.addFlag(INTERNAL_PRINT_TO_CONSOLE,
        help: 'enable sending `print` output to the console',
        defaultsTo: false,
        negatable: false);
    parser.addOption(NEW_ANALYSIS_DRIVER_LOG,
        help: "set a destination for the new analysis driver's log");
    parser.addFlag(ANALYTICS_FLAG,
        help: 'enable or disable sending analytics information to Google',
        hide: !telemetry.SHOW_ANALYTICS_UI);
    parser.addFlag(SUPPRESS_ANALYTICS_FLAG,
        negatable: false,
        help: 'suppress analytics for this session',
        hide: !telemetry.SHOW_ANALYTICS_UI);
    parser.addOption(PORT_OPTION,
        help: 'the http diagnostic port on which the server provides'
            ' status and performance information');
    parser.addOption(SDK_OPTION, help: '[path] the path to the sdk');
    parser.addFlag(USE_ANALYSIS_HIGHLIGHT2,
        help: 'enable version 2 of semantic highlight',
        defaultsTo: false,
        negatable: false);
    parser.addOption(FILE_READ_MODE,
        help: 'an option for reading files (some clients normalize eol '
            'characters, which make the file offset and range information '
            'incorrect)',
        allowed: ['as-is', 'normalize-eol-always'],
        allowedHelp: {
          'as-is': 'file contents are read as-is',
          'normalize-eol-always':
              r"eol characters normalized to the single character new line ('\n')"
        },
        defaultsTo: 'as-is');
    parser.addOption(CACHE_FOLDER,
        help: '[path] path to the location where to cache data');
    parser.addFlag('preview-dart-2',
        help: 'Enable the Dart 2.0 preview (deprecated)', hide: true);
    parser.addFlag(USE_FASTA_PARSER,
        defaultsTo: true,
        help: 'Whether to enable parsing via the Fasta parser');
    parser.addFlag(USE_LSP,
        defaultsTo: false, help: 'Whether to use the Language Server Protocol');
    parser.addFlag(ENABLE_COMPLETION_MODEL,
        help: 'Whether or not to turn on ML ranking for code completion');
    parser.addOption(COMPLETION_MODEL_FOLDER,
        help: '[path] path to the location of a code completion model');
    parser.addOption(TRAIN_USING,
        help: 'Pass in a directory to analyze for purposes of training an '
            'analysis server snapshot.');
    //
    // Temporary flags.
    //
    parser.addFlag(USE_NEW_RELEVANCE,
        help: 'Use the new relevance computation for code completion.');

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
    if (args[SDK_OPTION] != null) {
      return args[SDK_OPTION];
    } else {
      return getSdkPath();
    }
  }

  /// Print information about how to use the server.
  void _printUsage(ArgParser parser, telemetry.Analytics analytics,
      {bool fromHelp = false}) {
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
