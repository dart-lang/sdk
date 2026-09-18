// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:browser_launcher/browser_launcher.dart';
import 'package:dart_runtime_service/dart_runtime_service.dart' as drs;
import 'package:devtools_shared/devtools_extensions_io.dart';
import 'package:devtools_shared/devtools_shared.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf;
import 'package:vm_service/vm_service.dart' as vm;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'src/utils/console.dart';

final class DevToolsServer implements drs.DevToolsServer {
  static const protocolVersion = '1.2.0';
  static const defaultTryPorts = 10;
  static const defaultDdsHost = '127.0.0.1';
  static const defaultDdsPort = 0;
  static const commandDescription =
      'Open DevTools (optionally connecting to an existing application).';

  static const argHelp = 'help';
  static const argVmUri = 'vm-uri';
  static const argEnableNotifications = 'enable-notifications';
  static const argAllowEmbedding = 'allow-embedding';
  static const argAppSizeBase = 'app-size-base';
  static const argAppSizeTest = 'app-size-test';
  static const argHeadlessMode = 'headless';
  static const argDdsHost = 'dds-host';
  static const argDdsPort = 'dds-port';
  static const argDebugMode = 'debug';
  static const argDisableCors = 'disable-cors';
  static const argDtdUri = 'dtd-uri';
  static const argDtdExposedUri = 'dtd-exposed-uri';
  static const argPrintDtd = 'print-dtd';
  static const argLaunchBrowser = 'launch-browser';
  static const argMachine = 'machine';
  static const argHost = 'host';
  static const argPort = 'port';
  static const argProfileMemory = 'record-memory-profile';
  static const argTryPorts = 'try-ports';
  static const argVerbose = 'verbose';
  static const argVersion = 'version';
  static const launchDevToolsService = 'launchDevTools';

  String? _devToolsUrl;
  bool _machineMode = false;
  bool _headlessMode = false;

  drs.MachineModeCommandHandler? _machineModeCommandHandler;
  @override
  drs.DevToolsClientManager? clientManager;

  String? get devToolsUrl => _devToolsUrl;

  bool get headlessMode => _headlessMode;
  final bool _isChromeOS = File('/dev/.cros_milestone').existsSync();

  /// Builds an arg parser for the DevTools server.
  ///
  /// [includeHelpOption] should be set to false if this arg parser will be used
  /// in a Command subclass.
  static ArgParser buildArgParser({
    bool verbose = false,
    bool includeHelpOption = true,
    int? usageLineLength,
  }) {
    final argParser = ArgParser(usageLineLength: usageLineLength);

    if (includeHelpOption) {
      argParser.addFlag(
        argHelp,
        negatable: false,
        abbr: 'h',
        help: 'Prints help output.',
      );
    }
    argParser
      ..addFlag(
        argVersion,
        negatable: false,
        help: 'Prints the DevTools version.',
      )
      ..addFlag(
        argVerbose,
        negatable: false,
        abbr: 'v',
        help: 'Output more informational messages.',
      )
      ..addOption(
        argHost,
        valueHelp: 'host',
        help: 'Hostname to serve DevTools on (defaults to localhost).',
      )
      ..addOption(
        argPort,
        defaultsTo: '9100',
        valueHelp: 'port',
        help:
            'Port to serve DevTools on; specify 0 to automatically use any '
            'available port.',
      )
      ..addOption(
        argDtdUri,
        valueHelp: 'uri',
        help:
            'A URI pointing to a Dart Tooling Daemon that DevTools should '
            'interface with.',
      )
      ..addOption(
        argDtdExposedUri,
        valueHelp: 'uri',
        help:
            'An optional URI for the DartTooling Daemon (--dtd-uri) that has '
            'been exposed to the front-end to support environments split '
            'across machines such as a web-based editor.',
      )
      ..addFlag(
        argLaunchBrowser,
        help:
            'Launches DevTools in a browser immediately at start.\n'
            '(defaults to on unless in --machine mode)',
      )
      ..addFlag(
        argMachine,
        negatable: false,
        help: 'Sets output format to JSON for consumption in tools.',
      )
      ..addSeparator('Memory profiling options:')
      ..addOption(
        argProfileMemory,
        valueHelp: 'file',
        defaultsTo: 'memory_samples.json',
        help:
            'Start devtools headlessly and write memory profiling samples to '
            'the indicated file.',
      );

    argParser.addSeparator('App size options:');

    argParser
      ..addOption(
        argAppSizeBase,
        aliases: ['appSizeBase'],
        valueHelp: 'file',
        help: 'Path to the base app size file used for app size debugging.',
      )
      ..addOption(
        argAppSizeTest,
        aliases: ['appSizeTest'],
        valueHelp: 'file',
        help:
            'Path to the test app size file used for app size debugging.\nThis '
            'file should only be specified if --$argAppSizeBase is also '
            'specified.',
        hide: !verbose,
      );

    if (verbose) {
      argParser.addSeparator('Advanced options:');
    }

    // Args to show for verbose mode.
    argParser
      ..addOption(
        argTryPorts,
        defaultsTo: DevToolsServer.defaultTryPorts.toString(),
        valueHelp: 'count',
        help:
            'The number of ascending ports to try binding to before failing '
            'with an error.',
        hide: !verbose,
      )
      ..addOption(
        argDdsHost,
        defaultsTo: DevToolsServer.defaultDdsHost,
        valueHelp: 'bind-address',
        help:
            'The address the Dart Development Service (DDS) should attempt to '
            'bind to if a DDS instance isn\'t active and a VM service URI is '
            'provided.',
        hide: !verbose,
      )
      ..addOption(
        argDdsPort,
        defaultsTo: DevToolsServer.defaultDdsPort.toString(),
        valueHelp: 'port',
        help:
            'The address the Dart Development Service (DDS) should attempt to '
            'bind to if a DDS instance isn\'t active and a VM service URI is '
            'provided.',
        hide: !verbose,
      )
      ..addFlag(
        argEnableNotifications,
        negatable: false,
        help:
            'Requests notification permissions immediately when a client '
            'connects back to the server.',
        hide: !verbose,
      )
      ..addFlag(
        argAllowEmbedding,
        help: 'Allow embedding DevTools inside an iframe.',
        hide: !verbose,
      )
      ..addFlag(
        argDisableCors,
        help:
            'Disable CORS so that the DevTools server can communicate with the '
            'DevTools front end served on a different origin. Use caution when '
            'passing this flag since allowing access to the DevTools server '
            'from other origins may have security implications.',
        hide: verbose,
      )
      ..addFlag(
        argHeadlessMode,
        negatable: false,
        help:
            'Causes the server to spawn Chrome in headless mode for use in '
            'automated testing.',
        hide: !verbose,
      )
      ..addFlag(
        argPrintDtd,
        negatable: false,
        help:
            'Print the address of the Dart Tooling Daemon, if one is hosted '
            'by the DevTools server.',
        hide: !verbose,
      );

    // Deprecated and hidden args.
    // TODO: Remove this - prefer that clients use the rest arg.
    argParser
      ..addOption(
        argVmUri,
        defaultsTo: '',
        help: 'VM Service protocol URI.',
        hide: true,
      )
      // Development only args.
      ..addFlag(
        argDebugMode,
        negatable: false,
        help: 'Run a debug build of the DevTools web frontend.',
        hide: true,
      );

    return argParser;
  }

  /// Serves DevTools.
  ///
  /// `handler` is the [shelf.Handler] that the server will use for all
  /// requests. If null, [drs.defaultHandler] will be used. Defaults to null.
  ///
  /// `customDevToolsPath` is a path to a directory containing a pre-built
  /// DevTools application.
  ///
  // Note: this method is used by the Dart CLI and by package:dwds.
  Future<HttpServer?> serveDevTools({
    bool enableStdinCommands = true,
    bool machineMode = false,
    bool debugMode = false,
    bool launchBrowser = false,
    bool enableNotifications = false,
    bool allowEmbedding = true,
    bool disableCors = false,
    bool headlessMode = false,
    bool verboseMode = false,
    bool printDtdUri = false,
    String? hostname,
    String? customDevToolsPath,
    int port = 0,
    int numPortsToTry = defaultTryPorts,
    shelf.Handler? handler,
    String? serviceProtocolUri,
    String? profileFilename,
    String? appSizeBase,
    String? appSizeTest,
    DtdInfo? dtdInfo,
  }) async {
    hostname ??= 'localhost';
    _machineMode = machineMode;
    _headlessMode = headlessMode;

    // Collect profiling information.
    if (profileFilename != null && serviceProtocolUri != null) {
      final vmServiceUri = Uri.tryParse(serviceProtocolUri);
      if (vmServiceUri != null) {
        await _hookupMemoryProfiling(
          vmServiceUri,
          profileFilename,
          verboseMode,
        );
      }
      return null;
    }

    if (machineMode) {
      assert(
        enableStdinCommands,
        'machineMode only works with enableStdinCommands.',
      );
    }

    clientManager = drs.DevToolsClientManager(
      requestNotificationPermissions: enableNotifications,
    );

    dtdInfo ??= await drs.startDtd(
      machineMode: machineMode,
      printDtdUri: printDtdUri,
    );

    final buildDir = customDevToolsPath ?? _getDevToolsAssetPath().toFilePath();

    HttpServer? server;
    SocketException? ex;
    while (server == null && numPortsToTry >= 0) {
      // If we have tried [numPortsToTry] ports and still have not been able to
      // connect, try port 0 to find a random available port.
      if (numPortsToTry == 0) port = 0;

      try {
        server = await HttpMultiServer.bind(hostname, port);
      } on SocketException catch (e) {
        ex = e;
        numPortsToTry--;
        port++;
      }
    }

    // Re-throw the last exception if we failed to bind.
    if (server == null && ex != null) {
      throw ex;
    }

    // Type promote server.
    server!;

    // Built after binding so the Host and Origin checks in [drs.defaultHandler]
    // can accept this server's own address, which is only known once a port has
    // actually been assigned.
    final serverUri = Uri(scheme: 'http', host: hostname, port: server.port);

    handler ??= await drs.defaultHandler(
      buildDir: buildDir,
      clientManager: clientManager,
      dtd: dtdInfo,
      devtoolsExtensionsManager: ExtensionsManager(),
      serverUri: serverUri,
    );

    if (allowEmbedding) {
      server.defaultResponseHeaders.remove('x-frame-options', 'SAMEORIGIN');
      // The origin-agent-cluster header is required to support the embedding of
      // Dart DevTools in Chrome DevTools.
      server.defaultResponseHeaders.add('origin-agent-cluster', '?1');
    }

    // CORS restrictions may be disabled for the purposes of debugging or
    // testing when it is useful to allow connecting a debug instance of
    // DevTools app to a running DevTools server.
    if (disableCors) {
      server.defaultResponseHeaders.add(
        HttpHeaders.accessControlAllowOriginHeader,
        '*',
      );
    }

    // Ensure browsers don't cache older versions of the app.
    server.defaultResponseHeaders.add(
      HttpHeaders.cacheControlHeader,
      'no-store',
    );

    // Add the headers required to serve with wasm.
    server.defaultResponseHeaders
      ..add('Cross-Origin-Embedder-Policy', 'credentialless')
      ..add('Cross-Origin-Opener-Policy', 'same-origin')
      ..add('Cross-Origin-Resource-Policy', 'cross-origin');

    // Serve requests in an error zone to prevent failures
    // when running from another error zone.
    runZonedGuarded(
      () => shelf.serveRequests(server!, handler!),
      (e, _) => print('Error serving requests: $e'),
    );

    final devToolsUrl = 'http://${server.address.host}:${server.port}';
    _devToolsUrl = devToolsUrl;

    if (launchBrowser) {
      if (serviceProtocolUri != null) {
        serviceProtocolUri = normalizeVmServiceUri(
          serviceProtocolUri,
        ).toString();
      }

      final queryParameters = <String, String>{
        'uri': ?serviceProtocolUri,
        'appSizeBase': ?appSizeBase,
        'appSizeTest': ?appSizeTest,
      };
      final url = Uri.parse(
        devToolsUrl,
      ).replace(queryParameters: queryParameters).toString();

      // If app size parameters are present, open to the standalone `app-size`
      // page, regardless if there is a vm service uri specified. We only check
      // for the presence of [appSizeBase] here because [appSizeTest] may or
      // may not be specified (it should only be present for diffs). If
      // [appSizeTest] is present without [appSizeBase], we will ignore the
      // parameter.
      if (appSizeBase != null) {
        final startQueryParamIndex = url.indexOf('?');
        if (startQueryParamIndex != -1) {
          final pageUrl =
              '${url.substring(0, startQueryParamIndex)}'
              '/#/app-size'
              '${url.substring(startQueryParamIndex)}';
          try {
            await Chrome.start([pageUrl]);
          } catch (e) {
            print('Unable to launch Chrome: $e\n');
          }
          return server;
        }
      }

      try {
        await Chrome.start([url]);
      } catch (e) {
        print('Unable to launch Chrome: $e\n');
      }
    }

    if (enableStdinCommands) {
      var message = '''Serving DevTools at $devToolsUrl.

          Hit ctrl-c to terminate the server.''';
      if (!machineMode && debugMode) {
        // Add bold to help find the correct url to open.
        message = ConsoleUtils.bold('$message\n');
      }

      drs.DevToolsUtils.printOutput(message, <String, Object?>{
        'event': 'server.started',
        // TODO(dantup): Remove this `method` field when we're sure VS Code
        // users are all on a newer version that uses `event`. We incorrectly
        // used `method` for the original releases.
        'method': 'server.started',
        'params': <String, Object?>{
          'host': server.address.host,
          'pid': pid,
          'port': server.port,
          'protocolVersion': protocolVersion,
        },
      }, machineMode: machineMode);

      if (machineMode) {
        _machineModeCommandHandler = drs.MachineModeCommandHandler(
          this,
          machineMode: machineMode,
        );
        stdin
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(_machineModeCommandHandler!.handle);
      }
    }

    return server;
  }

  void _printUsage(ArgParser argParser) {
    print(commandDescription);
    print('\nUsage: devtools [arguments] [service protocol uri]');
    print(argParser.usage);
  }

  /// Wraps [serveDevTools] `arguments` parsed, as from the command line.
  ///
  /// For more information on `handler`, see [serveDevTools].
  // Note: this method is used in google3 as well as by DevTools' main method.
  Future<HttpServer?> serveDevToolsWithArgs(
    List<String> arguments, {
    shelf.Handler? handler,
    String? customDevToolsPath,
  }) async {
    ArgResults args;
    final verbose = arguments.contains('-v') || arguments.contains('--verbose');
    final argParser = buildArgParser(verbose: verbose);
    try {
      args = argParser.parse(arguments);
    } on FormatException catch (e) {
      print(e.message);
      print('');
      _printUsage(argParser);
      return null;
    }

    return await _serveDevToolsWithArgs(
      args,
      verbose,
      handler: handler,
      customDevToolsPath: customDevToolsPath,
    );
  }

  Future<HttpServer?> _serveDevToolsWithArgs(
    ArgResults args,
    bool verbose, {
    shelf.Handler? handler,
    String? customDevToolsPath,
  }) async {
    final help = args[argHelp] as bool;
    final version = args[argVersion] as bool;
    final machineMode = args[argMachine] as bool;
    // launchBrowser defaults based on machine-mode if not explicitly supplied.
    final launchBrowser = args.wasParsed(argLaunchBrowser)
        ? args[argLaunchBrowser] as bool
        : !machineMode;
    final enableNotifications = args[argEnableNotifications] as bool;
    final allowEmbedding = args.wasParsed(argAllowEmbedding)
        ? args[argAllowEmbedding] as bool
        : true;
    final disableCors = args.wasParsed(argDisableCors)
        ? args[argDisableCors] as bool
        : false;

    final port = switch (args[argPort]) {
      final String portStr => int.tryParse(portStr) ?? 0,
      _ => 0,
    };

    final headlessMode = args[argHeadlessMode] as bool;
    final debugMode = args[argDebugMode] as bool;

    final numPortsToTry = switch (args[argTryPorts]) {
      final String tryPortsStr => int.tryParse(tryPortsStr) ?? 0,
      _ => defaultTryPorts,
    };

    final verboseMode = args[argVerbose] as bool;
    final hostname = args[argHost] as String?;

    // A helper to print a message and usage information.
    void printUsage(String message) {
      print(message);
      print('');
      _printUsage(buildArgParser(verbose: verbose));
    }

    Uri? dtdUri;
    if (args.wasParsed(argDtdUri)) {
      dtdUri = Uri.tryParse(args[argDtdUri] as String);
      if (dtdUri == null || !dtdUri.hasScheme) {
        printUsage('--dtd-uri must be a valid URI');
        return null;
      }
    }

    Uri? dtdExposedUri;
    if (args.wasParsed(argDtdExposedUri)) {
      if (dtdUri == null) {
        printUsage('--dtd-exposed-uri can only be supplied with --dtd-uri');
        return null;
      }

      dtdExposedUri = Uri.tryParse(args[argDtdExposedUri] as String);
      if (dtdExposedUri == null || !dtdExposedUri.hasScheme) {
        printUsage('--dtd-exposed-uri must be a valid URI');
        return null;
      }
    }

    final printDtdUri = args.wasParsed(argPrintDtd);

    if (help) {
      final versionStr = await drs.DevToolsUtils.getVersion(
        customDevToolsPath ?? '',
      );
      printUsage('Dart DevTools version $versionStr');
      return null;
    }

    if (version) {
      final versionStr = await drs.DevToolsUtils.getVersion(
        customDevToolsPath ?? '',
      );
      drs.DevToolsUtils.printOutput('Dart DevTools version $versionStr', {
        'version': versionStr,
      }, machineMode: machineMode);
      return null;
    }

    // Prefer getting the VM URI from the rest args; fall back on the 'vm-url'
    // option otherwise.
    String? serviceProtocolUri;
    if (args.rest.isNotEmpty) {
      serviceProtocolUri = args.rest.first;
    } else if (args.wasParsed(argVmUri)) {
      serviceProtocolUri = args[argVmUri] as String?;
    }

    // Support collecting profile data.
    String? profileFilename;
    if (args.wasParsed(argProfileMemory)) {
      profileFilename = args[argProfileMemory] as String?;
    }
    if (profileFilename != null && !path.isAbsolute(profileFilename)) {
      profileFilename = path.absolute(profileFilename);
    }

    // App size info.
    var appSizeBase = args[argAppSizeBase] as String?;
    if (appSizeBase != null && !path.isAbsolute(appSizeBase)) {
      appSizeBase = path.absolute(appSizeBase);
    }
    var appSizeTest = args[argAppSizeTest] as String?;
    if (appSizeTest != null && !path.isAbsolute(appSizeTest)) {
      appSizeTest = path.absolute(appSizeTest);
    }

    return serveDevTools(
      machineMode: machineMode,
      debugMode: debugMode,
      launchBrowser: launchBrowser,
      enableNotifications: enableNotifications,
      allowEmbedding: allowEmbedding,
      disableCors: disableCors,
      port: port,
      headlessMode: headlessMode,
      numPortsToTry: numPortsToTry,
      handler: handler,
      customDevToolsPath: customDevToolsPath,
      serviceProtocolUri: serviceProtocolUri,
      profileFilename: profileFilename,
      verboseMode: verboseMode,
      hostname: hostname,
      appSizeBase: appSizeBase,
      appSizeTest: appSizeTest,
      dtdInfo: dtdUri != null
          ? DtdInfo(dtdUri, exposedUri: dtdExposedUri)
          : null,
      printDtdUri: printDtdUri,
    );
  }

  @override
  Future<void> launchDevToolsInBrowser({
    required Uri vmServiceUri,
    String? page,
  }) async {
    if (_devToolsUrl == null) {
      throw StateError('DevTools server is not running.');
    }
    await launchDevTools(
      <String, Object?>{'page': ?page},
      vmServiceUri,
      _devToolsUrl!,
      _headlessMode,
      _machineMode,
    );
  }

  @override
  Future<Map<String, Object?>> launchDevTools(
    Map<String, Object?> params,
    Uri vmServiceUri,
    String devToolsUrl,
    bool headlessMode,
    bool machineMode,
  ) async {
    // First see if we have an existing DevTools client open that we can
    // reuse.
    final canReuse = params['reuseWindows'] == true;
    final shouldNotify = params['notify'] == true;
    final page = params['page'] as String?;
    if (canReuse &&
        await _tryReuseExistingDevToolsInstance(
          vmServiceUri,
          page,
          shouldNotify,
        )) {
      _emitLaunchEvent(
        machineMode: machineMode,
        notified: shouldNotify,
        pid: null,
        reused: true,
      );
      return <String, Object?>{'notified': shouldNotify, 'reused': true};
    }

    final uriParams = <String, Object?>{
      if (params['queryParams'] case final Map<dynamic, dynamic> queryParams)
        for (final MapEntry(:key, :value) in queryParams.entries) '$key': value,
      'uri': vmServiceUri.toString(),
    };

    final devToolsUri = Uri.parse(devToolsUrl);
    final uriToLaunch = buildUriToLaunch(devToolsUri, page, uriParams);
    print(
      'DevToolsServer.launchDevTools launching Chrome with uriToLaunch: '
      '$uriToLaunch',
    );

    // TODO(dantup): When ChromeOS has support for tunneling all ports we can
    // change this to always use the native browser for ChromeOS and may wish to
    // handle this inside `browser_launcher`; https://crbug.com/848063.
    final useNativeBrowser =
        _isChromeOS &&
        _isAccessibleToChromeOSNativeBrowser(devToolsUri) &&
        _isAccessibleToChromeOSNativeBrowser(vmServiceUri);
    int? browserPid;
    if (useNativeBrowser) {
      await Process.start('x-www-browser', [uriToLaunch.toString()]);
    } else {
      final args = <String>[
        '--no-proxy-server',
        '--no-first-run',
        '--no-default-browser-check',
        if (headlessMode) ...[
          '--headless',
          // When running headless, Chrome will quit immediately after
          // loading the page unless we have the debug port open.
          '--remote-debugging-port=0',
          '--disable-gpu',
          '--no-sandbox',
          '--disable-background-timer-throttling',
          '--disable-renderer-backgrounding',
          // When running on MacOS, Chrome may open system dialogs
          // requesting credentials. This uses a mock keychain to avoid that
          // dialog from blocking.
          '--use-mock-keychain',
        ],
      ];
      final proc = await Chrome.start([uriToLaunch.toString()], args: args);
      browserPid = proc.pid;
    }
    _emitLaunchEvent(
      machineMode: machineMode,
      notified: false,
      pid: browserPid!,
      reused: false,
    );
    return <String, Object?>{
      'notified': false,
      'pid': browserPid,
      'reused': false,
    };
  }

  Future<void> _hookupMemoryProfiling(
    Uri observatoryUri,
    String profileFile, [
    bool verboseMode = false,
  ]) async {
    final service = await _connectToVmService(observatoryUri);
    if (service == null) {
      return;
    }

    final memoryProfiler = drs.MemoryProfile(service, profileFile, verboseMode);
    memoryProfiler.startPolling();

    print('Writing memory profile samples to $profileFile...');
  }

  /// Tries to reuse an existing DevTools instance.
  ///
  /// Because SSE connections have timeouts that prevent us knowing if a client
  /// has really gone away for up to 30s, this method will attempt to ping
  /// candidate first to see if it is still responsive.
  Future<bool> _tryReuseExistingDevToolsInstance(
    Uri vmServiceUri,
    String? page,
    bool notifyUser,
  ) async {
    // First try to find a client that's already connected to this VM service,
    // and just send the user a notification for that one.
    final existingClient = await clientManager
        ?.findExistingConnectedReusableClient(vmServiceUri);
    if (existingClient != null) {
      try {
        if (page != null) {
          existingClient.showPage(page);
        }
        if (notifyUser) {
          existingClient.notify();
        }
        return true;
      } catch (e) {
        print('Failed to reuse existing connected DevTools client');
        print(e);
      }
    }

    final reusableClient = await clientManager?.findReusableClient();
    if (reusableClient != null) {
      try {
        reusableClient.connectToVmService(vmServiceUri, notifyUser);
        return true;
      } catch (e) {
        print('Failed to reuse existing DevTools client');
        print(e);
      }
    }
    return false;
  }

  static String buildUriToLaunch(
    Uri devToolsUri,
    String? page,
    Map<String, dynamic>? params,
  ) {
    page ??= '';
    final pathSep = devToolsUri.path.endsWith('/') ? '' : '/';
    final newPath = '${devToolsUri.path}$pathSep$page';
    final newParams = <String, Object?>{
      ...devToolsUri.queryParameters,
      ...?params,
    };
    return devToolsUri
        .replace(
          path: newPath,
          queryParameters: newParams.isNotEmpty
              ? newParams.cast<String, String>()
              : null,
        )
        .toString();
  }

  /// Prints a launch event to stdout so consumers of the DevTools server
  /// can see when clients are being launched/reused.
  void _emitLaunchEvent({
    required bool machineMode,
    required bool notified,
    required int? pid,
    required bool reused,
  }) {
    drs.DevToolsUtils.printOutput(null, <String, Object?>{
      'event': 'client.launch',
      'params': <String, Object?>{
        'notified': notified,
        'pid': pid,
        'reused': reused,
      },
    }, machineMode: machineMode);
  }

  bool _isAccessibleToChromeOSNativeBrowser(Uri uri) {
    const tunneledPorts = <int>{
      8000,
      8008,
      8080,
      8085,
      8888,
      9005,
      3000,
      4200,
      5000,
    };
    return uri.hasPort && tunneledPorts.contains(uri.port);
  }

  Future<vm.VmService?> _connectToVmService(Uri theUri) async {
    try {
      final wsUri = _convertToWebSocketUri(theUri);
      final channel = WebSocketChannel.connect(wsUri);
      final service = vm.VmService(
        channel.stream.cast<String>(),
        (String message) => channel.sink.add(message),
      );
      return service;
    } catch (e) {
      return null;
    }
  }

  Uri _convertToWebSocketUri(Uri uri) {
    final scheme = switch (uri.scheme) {
      'http' => 'ws',
      'https' => 'wss',
      _ => uri.scheme,
    };
    final path = switch (uri.path) {
      final p when p.endsWith('/ws') => p,
      final p when p.endsWith('/') => '${p}ws',
      final p => '$p/ws',
    };
    return uri.replace(scheme: scheme, path: path);
  }

  static Uri _getDevToolsAssetPath() {
    final dartDir = File(Platform.resolvedExecutable).parent.path;
    final fullSdk = dartDir.endsWith('bin');
    return Uri.file(
      fullSdk
          ? path.absolute(dartDir, 'resources', 'devtools')
          : path.absolute(dartDir, 'devtools'),
    );
  }
}
