// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library driver;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/plugin/linter_plugin.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_plugin.dart';
import 'package:analysis_server/src/server/http_server.dart';
import 'package:analysis_server/src/server/stdio_server.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/starter.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/file_instrumentation.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/incremental_logger.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:args/args.dart';
import 'package:linter/src/plugin/linter_plugin.dart';
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';

/**
 * Initializes incremental logger.
 *
 * Supports following formats of [spec]:
 *
 *     "console" - log to the console;
 *     "file:/some/file/name" - log to the file, overwritten on start.
 */
void _initIncrementalLogger(String spec) {
  logger = NULL_LOGGER;
  if (spec == null) {
    return;
  }
  // create logger
  if (spec == 'console') {
    logger = new StringSinkLogger(stdout);
  } else if (spec == 'stderr') {
    logger = new StringSinkLogger(stderr);
  } else if (spec.startsWith('file:')) {
    String fileName = spec.substring('file:'.length);
    File file = new File(fileName);
    IOSink sink = file.openWrite();
    logger = new StringSinkLogger(sink);
  }
}

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
   * The name of the option used to enable incremental resolution of API
   * changes.
   */
  static const String ENABLE_INCREMENTAL_RESOLUTION_API =
      "enable-incremental-resolution-api";

  /**
   * The name of the option used to enable instrumentation.
   */
  static const String ENABLE_INSTRUMENTATION_OPTION = "enable-instrumentation";

  /**
   * The name of the option used to set the file read mode.
   */
  static const String FILE_READ_MODE = "file-read-mode";

  /**
   * The name of the option used to print usage information.
   */
  static const String HELP_OPTION = "help";

  /**
   * The name of the option used to describe the incremental resolution logger.
   */
  static const String INCREMENTAL_RESOLUTION_LOG = "incremental-resolution-log";

  /**
   * The name of the option used to enable validation of incremental resolution
   * results.
   */
  static const String INCREMENTAL_RESOLUTION_VALIDATION =
      "incremental-resolution-validation";

  /**
   * The name of the option used to enable using pub summary manager.
   */
  static const String ENABLE_NEW_ANALYSIS_DRIVER = 'enable-new-analysis-driver';

  /**
   * The name of the option used to enable using pub summary manager.
   */
  static const String ENABLE_PUB_SUMMARY_MANAGER = 'enable-pub-summary-manager';

  /**
   * The name of the option used to enable fined grained invalidation.
   */
  static const String FINER_GRAINED_INVALIDATION = 'finer-grained-invalidation';

  /**
   * The name of the option used to cause instrumentation to also be written to
   * a local file.
   */
  static const String INSTRUMENTATION_LOG_FILE = "instrumentation-log-file";

  /**
   * The name of the option used to specify if [print] should print to the
   * console instead of being intercepted.
   */
  static const String INTERNAL_DELAY_FREQUENCY = 'internal-delay-frequency';

  /**
   * The name of the option used to specify if [print] should print to the
   * console instead of being intercepted.
   */
  static const String INTERNAL_PRINT_TO_CONSOLE = "internal-print-to-console";

  /**
   * The name of the flag used to disable error notifications.
   */
  static const String NO_ERROR_NOTIFICATION = "no-error-notification";

  /**
   * The name of the flag used to disable the index.
   */
  static const String NO_INDEX = "no-index";

  /**
   * The name of the flag used to enable version 2 of semantic highlight
   * notification.
   */
  static const String USE_ANALISYS_HIGHLIGHT2 = "useAnalysisHighlight2";

  /**
   * The option for specifying the http diagnostic port.
   * If specified, users can review server status and performance information
   * by opening a web browser on http://localhost:<port>
   */
  static const String PORT_OPTION = "port";

  /**
   * The path to the SDK.
   * TODO(paulberry): get rid of this once the 'analysis.updateSdks' request is
   * operational.
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
   * If this flag is `true`, then single analysis context should be used for
   * analysis of multiple analysis roots, special files that could otherwise
   * cause creating additional contexts, such as `pubspec.yaml`, or `.packages`,
   * or analysis options are ignored.
   */
  bool useSingleContextManager = false;

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
   */
  void start(List<String> arguments) {
    CommandLineParser parser = _createArgParser();
    ArgResults results = parser.parse(arguments, <String, String>{});
    if (results[HELP_OPTION]) {
      _printUsage(parser.parser);
      return;
    }

    // TODO (danrubel) Remove this workaround
    // once the underlying VM and dart:io issue has been fixed.
    if (results[INTERNAL_DELAY_FREQUENCY] != null) {
      AnalysisServer.performOperationDelayFrequency =
          int.parse(results[INTERNAL_DELAY_FREQUENCY], onError: (_) => 0);
    }

    int port;
    bool serve_http = false;
    if (results[PORT_OPTION] != null) {
      serve_http = true;
      try {
        port = int.parse(results[PORT_OPTION]);
      } on FormatException {
        print('Invalid port number: ${results[PORT_OPTION]}');
        print('');
        _printUsage(parser.parser);
        exitCode = 1;
        return;
      }
    }

    AnalysisServerOptions analysisServerOptions = new AnalysisServerOptions();
    analysisServerOptions.enableIncrementalResolutionApi =
        results[ENABLE_INCREMENTAL_RESOLUTION_API];
    analysisServerOptions.enableIncrementalResolutionValidation =
        results[INCREMENTAL_RESOLUTION_VALIDATION];
    analysisServerOptions.enableNewAnalysisDriver =
      results[ENABLE_NEW_ANALYSIS_DRIVER];
    analysisServerOptions.enablePubSummaryManager =
        results[ENABLE_PUB_SUMMARY_MANAGER];
    analysisServerOptions.finerGrainedInvalidation =
        true /*results[FINER_GRAINED_INVALIDATION]*/;
    analysisServerOptions.noErrorNotification = results[NO_ERROR_NOTIFICATION];
    analysisServerOptions.noIndex = results[NO_INDEX];
    analysisServerOptions.useAnalysisHighlight2 =
        results[USE_ANALISYS_HIGHLIGHT2];
    analysisServerOptions.fileReadMode = results[FILE_READ_MODE];

    _initIncrementalLogger(results[INCREMENTAL_RESOLUTION_LOG]);

    //
    // Process all of the plugins so that extensions are registered.
    //
    ServerPlugin serverPlugin = new ServerPlugin();
    List<Plugin> plugins = <Plugin>[];
    plugins.addAll(AnalysisEngine.instance.requiredPlugins);
    plugins.add(AnalysisEngine.instance.commandLinePlugin);
    plugins.add(AnalysisEngine.instance.optionsPlugin);
    plugins.add(serverPlugin);
    plugins.add(linterPlugin);
    plugins.add(linterServerPlugin);
    plugins.add(dartCompletionPlugin);
    plugins.addAll(_userDefinedPlugins);
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(plugins);

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
    bool useSummaries = analysisServerOptions.fileReadMode == 'as-is';
    // TODO(brianwilkerson) It would be nice to avoid creating an SDK that
    // cannot be re-used, but the SDK is needed to create a package map provider
    // in the case where we need to run `pub` in order to get the package map.
    DartSdk defaultSdk = _createDefaultSdk(defaultSdkPath, useSummaries);
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
    InstrumentationService service =
        new InstrumentationService(instrumentationServer);
    service.logVersion(_readUuid(service), results[CLIENT_ID],
        results[CLIENT_VERSION], AnalysisServer.VERSION, defaultSdk.sdkVersion);
    AnalysisEngine.instance.instrumentationService = service;
    //
    // Create the sockets and start listening for requests.
    //
    socketServer = new SocketServer(
        analysisServerOptions,
        new DartSdkManager(defaultSdkPath, useSummaries),
        defaultSdk,
        service,
        serverPlugin,
        fileResolverProvider,
        packageResolverProvider,
        useSingleContextManager);
    httpServer = new HttpAnalysisServer(socketServer);
    stdioServer = new StdioAnalysisServer(socketServer);
    socketServer.userDefinedPlugins = _userDefinedPlugins;

    if (serve_http) {
      httpServer.serveHttp(port);
    }

    _captureExceptions(service, () {
      stdioServer.serveStdio().then((_) async {
        if (serve_http) {
          httpServer.close();
        }
        await service.shutdown();
        exit(0);
      });
    },
        print:
            results[INTERNAL_PRINT_TO_CONSOLE] ? null : httpServer.recordPrint);
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
    parser.addFlag(ENABLE_INCREMENTAL_RESOLUTION_API,
        help: "enable using incremental resolution for API changes",
        defaultsTo: false,
        negatable: false);
    parser.addFlag(ENABLE_INSTRUMENTATION_OPTION,
        help: "enable sending instrumentation information to a server",
        defaultsTo: false,
        negatable: false);
    parser.addFlag(HELP_OPTION,
        help: "print this help message without starting a server",
        defaultsTo: false,
        negatable: false);
    parser.addOption(INCREMENTAL_RESOLUTION_LOG,
        help: "set a destination for the incremental resolver's log");
    parser.addFlag(INCREMENTAL_RESOLUTION_VALIDATION,
        help: "enable validation of incremental resolution results (slow)",
        defaultsTo: false,
        negatable: false);
    parser.addFlag(ENABLE_NEW_ANALYSIS_DRIVER,
        help: "enable using new analysis driver",
        defaultsTo: false,
        negatable: false);
    parser.addFlag(ENABLE_PUB_SUMMARY_MANAGER,
        help: "enable using summaries for pub cache packages",
        defaultsTo: false,
        negatable: false);
    parser.addFlag(FINER_GRAINED_INVALIDATION,
        help: "enable finer grained invalidation",
        defaultsTo: false,
        negatable: false);
    parser.addOption(INSTRUMENTATION_LOG_FILE,
        help:
            "the path of the file to which instrumentation data will be written");
    parser.addFlag(INTERNAL_PRINT_TO_CONSOLE,
        help: "enable sending `print` output to the console",
        defaultsTo: false,
        negatable: false);
    parser.addOption(PORT_OPTION,
        help: "the http diagnostic port on which the server provides"
            " status and performance information");
    parser.addOption(INTERNAL_DELAY_FREQUENCY);
    parser.addOption(SDK_OPTION, help: "[path] the path to the sdk");
    parser.addFlag(NO_ERROR_NOTIFICATION,
        help: "disable sending all analysis error notifications to the server",
        defaultsTo: false,
        negatable: false);
    parser.addFlag(NO_INDEX,
        help: "disable indexing sources", defaultsTo: false, negatable: false);
    parser.addFlag(USE_ANALISYS_HIGHLIGHT2,
        help: "enable version 2 of semantic highlight",
        defaultsTo: false,
        negatable: false);
    parser.addOption(FILE_READ_MODE,
        help: "an option of the ways files can be read from disk, " +
            "some clients normalize end of line characters which would make " +
            "the file offset and range information incorrect.",
        allowed: ["as-is", "normalize-eol-always"],
        allowedHelp: {
          "as-is": "file contents are read as-is, no file changes occur",
          "normalize-eol-always":
              r'file contents normalize the end of line characters to the single character new line `\n`'
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
  void _printUsage(ArgParser parser) {
    print('Usage: $BINARY_NAME [flags]');
    print('');
    print('Supported flags are:');
    print(parser.usage);
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
