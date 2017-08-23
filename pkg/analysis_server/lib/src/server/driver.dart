// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/server/diagnostic_server.dart';
import 'package:analysis_server/src/server/http_server.dart';
import 'package:analysis_server/src/server/stdio_server.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/starter.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/file_instrumentation.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:args/args.dart';
import 'package:linter/src/rules.dart' as linter;
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';
import 'package:telemetry/crash_reporting.dart';
import 'package:telemetry/telemetry.dart' as telemetry;

/// Commandline argument parser. (Copied from analyzer/lib/options.dart)
/// TODO(pquitslund): replaces with a simple [ArgParser] instance
/// when the args package supports ignoring unrecognized
/// options/flags (https://github.com/dart-lang/args/issues/9).
class CommandLineParser {
  final List<String> _knownFlags;
  final bool _alwaysIgnoreUnrecognized;
  final ArgParser _parser;

  /// Creates a new command line parser
  CommandLineParser({bool alwaysIgnoreUnrecognized: false})
      : _knownFlags = <String>[],
        _alwaysIgnoreUnrecognized = alwaysIgnoreUnrecognized,
        _parser = new ArgParser(allowTrailingOptions: true);

  ArgParser get parser => _parser;

  /// Defines a flag.
  /// See [ArgParser.addFlag()].
  void addFlag(String name,
      {String abbr,
      String help,
      bool defaultsTo: false,
      bool negatable: true,
      void callback(bool value),
      bool hide: false}) {
    _knownFlags.add(name);
    _parser.addFlag(name,
        abbr: abbr,
        help: help,
        defaultsTo: defaultsTo,
        negatable: negatable,
        callback: callback,
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
      void callback(value),
      bool allowMultiple: false}) {
    _knownFlags.add(name);
    _parser.addOption(name,
        abbr: abbr,
        help: help,
        allowed: allowed,
        allowedHelp: allowedHelp,
        defaultsTo: defaultsTo,
        callback: callback,
        allowMultiple: allowMultiple);
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
    int count = args.length;
    List<String> remainingArgs = <String>[];
    for (int i = 0; i < count; i++) {
      String arg = args[i];
      if (arg == '--') {
        while (i < count) {
          remainingArgs.add(args[i++]);
        }
      } else if (arg.startsWith("-D")) {
        definedVariables[arg.substring(2)] = args[++i];
      } else {
        remainingArgs.add(arg);
      }
    }
    return remainingArgs;
  }

  List<String> _filterUnknowns(List<String> args) {
    // Only filter args if the ignore flag is specified, or if
    // _alwaysIgnoreUnrecognized was set to true
    if (_alwaysIgnoreUnrecognized ||
        args.contains('--ignore-unrecognized-flags')) {
      // Filter all unrecognized flags and options.
      List<String> filtered = <String>[];
      for (int i = 0; i < args.length; ++i) {
        String arg = args[i];
        if (arg.startsWith('--') && arg.length > 2) {
          String option = arg.substring(2);
          // remove any leading 'no-'
          if (option.startsWith('no-')) {
            option = option.substring(3);
          }
          // strip the last '=value'
          int equalsOffset = option.lastIndexOf('=');
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

  _getNextFlagIndex(args, i) {
    for (; i < args.length; ++i) {
      if (args[i].startsWith('--')) {
        return i;
      }
    }
    return i;
  }
}

/**
 * The [Driver] class represents a single running instance of the analysis
 * server application.  It is responsible for parsing command line options
 * and starting the HTTP and/or stdio servers.
 */
class Driver implements ServerStarter {
  /**
   * The name of the application that is used to start a server.
   */
  static const BINARY_NAME = "server";

  /**
   * The name of the option used to set the identifier for the client.
   */
  static const String CLIENT_ID = "client-id";

  /**
   * The name of the option used to set the version for the client.
   */
  static const String CLIENT_VERSION = "client-version";

  /**
   * The name of the option used to enable instrumentation.
   */
  static const String ENABLE_INSTRUMENTATION_OPTION = "enable-instrumentation";

  /**
   * The name of the option used to set the file read mode.
   */
  static const String FILE_READ_MODE = "file-read-mode";

  /**
   * The name of the flag used when analyzing the flutter repository.
   * See comments in source for `flutter analyze --watch`.
   */
  static const FLUTTER_REPO = "flutter-repo";

  /**
   * The name of the option used to print usage information.
   */
  static const String HELP_OPTION = "help";

  /**
   * The name of the flag used to configure reporting analytics.
   */
  static const String ANALYTICS_FLAG = "analytics";

  /**
   * Suppress analytics for this session.
   */
  static const String SUPPRESS_ANALYTICS_FLAG = "suppress-analytics";

  /**
   * The name of the option used to cause instrumentation to also be written to
   * a local file.
   */
  static const String INSTRUMENTATION_LOG_FILE = "instrumentation-log-file";

  /**
   * The name of the option used to specify if [print] should print to the
   * console instead of being intercepted.
   */
  static const String INTERNAL_PRINT_TO_CONSOLE = "internal-print-to-console";

  /**
   * The name of the option used to describe the new analysis driver logger.
   */
  static const String NEW_ANALYSIS_DRIVER_LOG = 'new-analysis-driver-log';

  /**
   * The name of the flag used to enable version 2 of semantic highlight
   * notification.
   */
  static const String USE_ANALYSIS_HIGHLIGHT2 = "useAnalysisHighlight2";

  /**
   * The option for specifying the http diagnostic port.
   * If specified, users can review server status and performance information
   * by opening a web browser on http://localhost:<port>
   */
  static const String PORT_OPTION = "port";

  /**
   * The path to the SDK.
   */
  static const String SDK_OPTION = "sdk";

  /**
   * The instrumentation server that is to be used by the analysis server.
   */
  InstrumentationServer instrumentationServer;

  /**
   * The file resolver provider used to override the way file URI's are
   * resolved in some contexts.
   */
  ResolverProvider fileResolverProvider;

  /**
   * The package resolver provider used to override the way package URI's are
   * resolved in some contexts.
   */
  ResolverProvider packageResolverProvider;

  /**
   * The plugins that are defined outside the analysis_server package.
   */
  List<Plugin> _userDefinedPlugins = <Plugin>[];

  SocketServer socketServer;

  HttpAnalysisServer httpServer;

  StdioAnalysisServer stdioServer;

  Driver();

  /**
   * Set the [plugins] that are defined outside the analysis_server package.
   */
  void set userDefinedPlugins(List<Plugin> plugins) {
    _userDefinedPlugins = plugins ?? <Plugin>[];
  }

  /**
   * Use the given command-line [arguments] to start this server.
   *
   * At least temporarily returns AnalysisServer so that consumers of the
   * starter API can then use the server, this is done as a stopgap for the
   * angular plugin until the official plugin API is finished.
   */
  AnalysisServer start(List<String> arguments) {
    CommandLineParser parser = _createArgParser();
    ArgResults results = parser.parse(arguments, <String, String>{});

    AnalysisServerOptions analysisServerOptions = new AnalysisServerOptions();
    analysisServerOptions.useAnalysisHighlight2 =
        results[USE_ANALYSIS_HIGHLIGHT2];
    analysisServerOptions.fileReadMode = results[FILE_READ_MODE];
    analysisServerOptions.newAnalysisDriverLog =
        results[NEW_ANALYSIS_DRIVER_LOG];
    analysisServerOptions.clientId = results[CLIENT_ID];
    analysisServerOptions.clientVersion = results[CLIENT_VERSION];

    ContextBuilderOptions.flutterRepo = results[FLUTTER_REPO];

    telemetry.Analytics analytics = telemetry.createAnalyticsInstance(
        'UA-26406144-29', 'analysis-server',
        disableForSession: results[SUPPRESS_ANALYTICS_FLAG]);
    analysisServerOptions.analytics = analytics;

    if (analysisServerOptions.clientId != null) {
      // Record the client name as the application installer ID.
      analytics.setSessionValue('aiid', analysisServerOptions.clientId);
    }
    if (analysisServerOptions.clientVersion != null) {
      analytics.setSessionValue('cd1', analysisServerOptions.clientVersion);
    }

    // TODO(devoncarew): Replace with the real crash product ID.
    analysisServerOptions.crashReportSender =
        new CrashReportSender('Dart_analysis_server', analytics);

    if (results.wasParsed(ANALYTICS_FLAG)) {
      analytics.enabled = results[ANALYTICS_FLAG];
      print(telemetry.createAnalyticsStatusMessage(analytics.enabled));
      return null;
    }

    if (results[HELP_OPTION]) {
      _printUsage(parser.parser, analytics, fromHelp: true);
      return null;
    }

    int port;
    bool serve_http = false;
    if (results[PORT_OPTION] != null) {
      try {
        port = int.parse(results[PORT_OPTION]);
        serve_http = true;
      } on FormatException {
        print('Invalid port number: ${results[PORT_OPTION]}');
        print('');
        _printUsage(parser.parser, analytics);
        exitCode = 1;
        return null;
      }
    }

    //
    // Process all of the plugins so that extensions are registered.
    //
    List<Plugin> plugins = <Plugin>[];
    plugins.addAll(AnalysisEngine.instance.requiredPlugins);
    plugins.addAll(_userDefinedPlugins);
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(plugins);
    linter.registerLintRules();

    String defaultSdkPath;
    if (results[SDK_OPTION] != null) {
      defaultSdkPath = results[SDK_OPTION];
    } else {
      // No path to the SDK was provided.
      // Use DirectoryBasedDartSdk.defaultSdkDirectory, which will make a guess.
      defaultSdkPath = FolderBasedDartSdk
          .defaultSdkDirectory(PhysicalResourceProvider.INSTANCE)
          .path;
    }
    // TODO(brianwilkerson) It would be nice to avoid creating an SDK that
    // cannot be re-used, but the SDK is needed to create a package map provider
    // in the case where we need to run `pub` in order to get the package map.
    DartSdk defaultSdk = _createDefaultSdk(defaultSdkPath, true);
    //
    // Initialize the instrumentation service.
    //
    String logFilePath = results[INSTRUMENTATION_LOG_FILE];
    if (logFilePath != null) {
      _rollLogFiles(logFilePath, 5);
      FileInstrumentationServer fileBasedServer =
          new FileInstrumentationServer(logFilePath);
      instrumentationServer = instrumentationServer != null
          ? new MulticastInstrumentationServer(
              [instrumentationServer, fileBasedServer])
          : fileBasedServer;
    }
    InstrumentationService instrumentationService =
        new InstrumentationService(instrumentationServer);
    instrumentationService.logVersion(
        _readUuid(instrumentationService),
        analysisServerOptions.clientId,
        analysisServerOptions.clientVersion,
        AnalysisServer.VERSION,
        defaultSdk.sdkVersion);
    AnalysisEngine.instance.instrumentationService = instrumentationService;

    _DiagnosticServerImpl diagnosticServer = new _DiagnosticServerImpl();

    // Ping analytics with our initial call.
    analytics.sendScreenView('home');

    //
    // Create the sockets and start listening for requests.
    //
    socketServer = new SocketServer(
        analysisServerOptions,
        new DartSdkManager(defaultSdkPath, true),
        defaultSdk,
        instrumentationService,
        diagnosticServer,
        fileResolverProvider,
        packageResolverProvider);
    httpServer = new HttpAnalysisServer(socketServer);
    stdioServer = new StdioAnalysisServer(socketServer);
    socketServer.userDefinedPlugins = _userDefinedPlugins;

    diagnosticServer.httpServer = httpServer;
    if (serve_http) {
      diagnosticServer.startOnPort(port);
    }

    _captureExceptions(instrumentationService, () {
      stdioServer.serveStdio().then((_) async {
        if (serve_http) {
          httpServer.close();
        }
        await instrumentationService.shutdown();
        exit(0);
      });
    },
        print:
            results[INTERNAL_PRINT_TO_CONSOLE] ? null : httpServer.recordPrint);

    return socketServer.analysisServer;
  }

  /**
   * Execute the given [callback] within a zone that will capture any unhandled
   * exceptions and both report them to the client and send them to the given
   * instrumentation [service]. If a [print] function is provided, then also
   * capture any data printed by the callback and redirect it to the function.
   */
  dynamic _captureExceptions(InstrumentationService service, dynamic callback(),
      {void print(String line)}) {
    var errorFunction = (Zone self, ZoneDelegate parent, Zone zone,
        dynamic exception, StackTrace stackTrace) {
      service.logPriorityException(exception, stackTrace);
      AnalysisServer analysisServer = socketServer.analysisServer;
      analysisServer.sendServerErrorNotification(
          'Captured exception', exception, stackTrace);
      throw exception;
    };
    var printFunction = print == null
        ? null
        : (Zone self, ZoneDelegate parent, Zone zone, String line) {
            // Note: we don't pass the line on to stdout, because that is
            // reserved for communication to the client.
            print(line);
          };
    ZoneSpecification zoneSpecification = new ZoneSpecification(
        handleUncaughtError: errorFunction, print: printFunction);
    return runZoned(callback, zoneSpecification: zoneSpecification);
  }

  /**
   * Create and return the parser used to parse the command-line arguments.
   */
  CommandLineParser _createArgParser() {
    CommandLineParser parser =
        new CommandLineParser(alwaysIgnoreUnrecognized: true);
    parser.addOption(CLIENT_ID,
        help: "an identifier used to identify the client");
    parser.addOption(CLIENT_VERSION, help: "the version of the client");
    parser.addFlag(ENABLE_INSTRUMENTATION_OPTION,
        help: "enable sending instrumentation information to a server",
        defaultsTo: false,
        negatable: false);
    parser.addFlag(FLUTTER_REPO,
        help: 'used by "flutter analyze" to enable specific lints'
            ' when analyzing the flutter repository',
        hide: false);
    parser.addFlag(HELP_OPTION,
        help: "print this help message without starting a server",
        abbr: 'h',
        defaultsTo: false,
        negatable: false);
    parser.addOption(INSTRUMENTATION_LOG_FILE,
        help: "write instrumentation data to the given file");
    parser.addFlag(INTERNAL_PRINT_TO_CONSOLE,
        help: "enable sending `print` output to the console",
        defaultsTo: false,
        negatable: false);
    parser.addOption(NEW_ANALYSIS_DRIVER_LOG,
        help: "set a destination for the new analysis driver's log");
    parser.addFlag(ANALYTICS_FLAG,
        help: 'enable or disable sending analytics information to Google');
    parser.addFlag(SUPPRESS_ANALYTICS_FLAG,
        negatable: false, help: 'suppress analytics for this session');
    parser.addOption(PORT_OPTION,
        help: "the http diagnostic port on which the server provides"
            " status and performance information");
    parser.addOption(SDK_OPTION, help: "[path] the path to the sdk");
    parser.addFlag(USE_ANALYSIS_HIGHLIGHT2,
        help: "enable version 2 of semantic highlight",
        defaultsTo: false,
        negatable: false);
    parser.addOption(FILE_READ_MODE,
        help: "an option for reading files (some clients normalize eol "
            "characters, which make the file offset and range information "
            "incorrect)",
        allowed: ["as-is", "normalize-eol-always"],
        allowedHelp: {
          "as-is": "file contents are read as-is",
          "normalize-eol-always":
              r"eol characters normalized to the single character new line ('\n')"
        },
        defaultsTo: "as-is");

    return parser;
  }

  DartSdk _createDefaultSdk(String defaultSdkPath, bool useSummaries) {
    PhysicalResourceProvider resourceProvider =
        PhysicalResourceProvider.INSTANCE;
    FolderBasedDartSdk sdk = new FolderBasedDartSdk(
        resourceProvider, resourceProvider.getFolder(defaultSdkPath));
    sdk.useSummary = useSummaries;
    return sdk;
  }

  /**
   * Print information about how to use the server.
   */
  void _printUsage(ArgParser parser, telemetry.Analytics analytics,
      {bool fromHelp: false}) {
    print('Usage: $BINARY_NAME [flags]');
    print('');
    print('Supported flags are:');
    print(parser.usage);

    // Print analytics status and information.
    if (fromHelp) {
      print('');
      print(telemetry.analyticsNotice);
    }
    print('');
    print(telemetry.createAnalyticsStatusMessage(analytics.enabled,
        command: ANALYTICS_FLAG));
  }

  /**
   * Read the UUID from disk, generating and storing a new one if necessary.
   */
  String _readUuid(InstrumentationService service) {
    File uuidFile = new File(PhysicalResourceProvider.INSTANCE
        .getStateLocation('.instrumentation')
        .getChild('uuid.txt')
        .path);
    try {
      if (uuidFile.existsSync()) {
        String uuid = uuidFile.readAsStringSync();
        if (uuid != null && uuid.length > 5) {
          return uuid;
        }
      }
    } catch (exception, stackTrace) {
      service.logPriorityException(exception, stackTrace);
    }
    int millisecondsSinceEpoch = new DateTime.now().millisecondsSinceEpoch;
    int random = new Random().nextInt(0x3fffffff);
    String uuid = '$millisecondsSinceEpoch$random';
    try {
      uuidFile.parent.createSync(recursive: true);
      uuidFile.writeAsStringSync(uuid);
    } catch (exception, stackTrace) {
      service.logPriorityException(exception, stackTrace);
      // Slightly alter the uuid to indicate it was not persisted
      uuid = 'temp-$uuid';
    }
    return uuid;
  }

  /**
   * Perform log files rolling.
   *
   * Rename existing files with names `[path].(x)` to `[path].(x+1)`.
   * Keep at most [numOld] files.
   * Rename the file with the given [path] to `[path].1`.
   */
  static void _rollLogFiles(String path, int numOld) {
    for (int i = numOld - 1; i >= 0; i--) {
      try {
        String oldPath = i == 0 ? path : '$path.$i';
        new File(oldPath).renameSync('$path.${i+1}');
      } catch (e) {}
    }
  }
}

/**
 * Implements the [DiagnosticServer] class by wrapping an [HttpAnalysisServer].
 */
class _DiagnosticServerImpl extends DiagnosticServer {
  HttpAnalysisServer httpServer;

  _DiagnosticServerImpl();

  @override
  Future<int> getServerPort() => httpServer.serveHttp();

  Future startOnPort(int port) {
    return httpServer.serveHttp(port);
  }
}
