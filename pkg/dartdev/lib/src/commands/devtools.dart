// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds/devtools_server.dart';
import 'package:dds/src/devtools/utils.dart';
import 'package:path/path.dart' as path;

import '../core.dart';
import '../sdk.dart';

class DevToolsCommand extends DartdevCommand {
  static const commandDescription =
      'Open DevTools (optionally connecting to an existing application).';

  static const protocolVersion = '1.1.0';
  static const argHelp = 'help';
  static const argVmUri = 'vm-uri';
  static const argEnableNotifications = 'enable-notifications';
  static const argAllowEmbedding = 'allow-embedding';
  static const argAppSizeBase = 'appSizeBase';
  static const argAppSizeTest = 'appSizeTest';
  static const argHeadlessMode = 'headless';
  static const argDebugMode = 'debug';
  static const argLaunchBrowser = 'launch-browser';
  static const argMachine = 'machine';
  static const argHost = 'host';
  static const argPort = 'port';
  static const argProfileMemory = 'record-memory-profile';
  static const argTryPorts = 'try-ports';
  static const argVerbose = 'verbose';
  static const argVersion = 'version';
  static const launchDevToolsService = 'launchDevTools';

  DevToolsCommand({
    this.customDevToolsPath,
    bool verbose = false,
  }) : super(
          'devtools',
          commandDescription,
          verbose,
        ) {
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
        help: 'Port to serve DevTools on; specify 0 to automatically use any '
            'available port.',
      )
      ..addFlag(
        argLaunchBrowser,
        help:
            'Launches DevTools in a browser immediately at start.\n(defaults to on unless in --machine mode)',
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
            'Start devtools headlessly and write memory profiling samples to the '
            'indicated file.',
      );

    if (verbose) {
      argParser.addSeparator('App size options:');
    }

    // TODO(devoncarew): --appSizeBase and --appSizeTest should be renamed to
    // something like --app-size-base and --app-size-test; #3146.
    argParser
      ..addOption(
        argAppSizeBase,
        valueHelp: 'appSizeBase',
        help: 'Path to the base app size file used for app size debugging.',
        hide: !verbose,
      )
      ..addOption(
        argAppSizeTest,
        valueHelp: 'appSizeTest',
        help:
            'Path to the test app size file used for app size debugging.\nThis '
            'file should only be specified if --$argAppSizeBase is also specified.',
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
        help: 'The number of ascending ports to try binding to before failing '
            'with an error. ',
        hide: !verbose,
      )
      ..addFlag(
        argEnableNotifications,
        negatable: false,
        help: 'Requests notification permissions immediately when a client '
            'connects back to the server.',
        hide: !verbose,
      )
      ..addFlag(
        argAllowEmbedding,
        help: 'Allow embedding DevTools inside an iframe.',
        hide: !verbose,
      )
      ..addFlag(
        argHeadlessMode,
        negatable: false,
        help: 'Causes the server to spawn Chrome in headless mode for use in '
            'automated testing.',
        hide: !verbose,
      );

    // Deprecated and hidden argResults.
    // TODO: Remove this - prefer that clients use the rest arg.
    argParser
      ..addOption(
        argVmUri,
        defaultsTo: '',
        help: 'VM Service protocol URI.',
        hide: true,
      )

      // Development only argResults.
      ..addFlag(
        argDebugMode,
        negatable: false,
        help: 'Run a debug build of the DevTools web frontend.',
        hide: true,
      );
  }

  final String customDevToolsPath;

  @override
  String get name => 'devtools';

  @override
  String get description => commandDescription;

  @override
  String get invocation => '${super.invocation} [service protocol uri]';

  @override
  Future<int> run() async {
    final bool version = argResults[argVersion];
    final bool machineMode = argResults[argMachine];
    // launchBrowser defaults based on machine-mode if not explicitly supplied.
    final bool launchBrowser = argResults.wasParsed(argLaunchBrowser)
        ? argResults[argLaunchBrowser]
        : !machineMode;
    final bool enableNotifications = argResults[argEnableNotifications];
    final bool allowEmbedding = argResults.wasParsed(argAllowEmbedding)
        ? argResults[argAllowEmbedding]
        : true;

    final port = argResults[argPort] != null
        ? int.tryParse(argResults[argPort]) ?? 0
        : 0;

    final bool headlessMode = argResults[argHeadlessMode];
    final bool debugMode = argResults[argDebugMode];

    final numPortsToTry = argResults[argTryPorts] != null
        ? int.tryParse(argResults[argTryPorts]) ?? 0
        : DevToolsServer.defaultTryPorts;

    final bool verboseMode = argResults[argVerbose];
    final String hostname = argResults[argHost];
    final String appSizeBase = argResults[argAppSizeBase];
    final String appSizeTest = argResults[argAppSizeTest];

    final sdkDir = path.dirname(sdk.dart);
    final fullSdk = sdkDir.endsWith('bin');
    final devToolsBinaries =
        fullSdk ? sdk.devToolsBinaries : path.absolute(sdkDir, 'devtools');

    if (version) {
      final versionStr = await DevToolsUtils.getVersion(devToolsBinaries);
      DevToolsUtils.printOutput(
        'Dart DevTools version $versionStr',
        {
          'version': versionStr,
        },
        machineMode: machineMode,
      );
      return null;
    }

    // Prefer getting the VM URI from the rest argResults; fall back on the 'vm-url'
    // option otherwise.
    String serviceProtocolUri;
    if (argResults.rest.isNotEmpty) {
      serviceProtocolUri = argResults.rest.first;
    } else if (argResults.wasParsed(argVmUri)) {
      serviceProtocolUri = argResults[argVmUri];
    }

    // Support collecting profile data.
    String profileFilename;
    if (argResults.wasParsed(argProfileMemory)) {
      profileFilename = argResults[argProfileMemory];
    }
    if (profileFilename != null && !path.isAbsolute(profileFilename)) {
      profileFilename = path.absolute(profileFilename);
    }

    final server = await DevToolsServer().serveDevTools(
      machineMode: machineMode,
      debugMode: debugMode,
      launchBrowser: launchBrowser,
      enableNotifications: enableNotifications,
      allowEmbedding: allowEmbedding,
      port: port,
      headlessMode: headlessMode,
      numPortsToTry: numPortsToTry,
      customDevToolsPath: customDevToolsPath ?? devToolsBinaries,
      serviceProtocolUri: serviceProtocolUri,
      profileFilename: profileFilename,
      verboseMode: verboseMode,
      hostname: hostname,
      appSizeBase: appSizeBase,
      appSizeTest: appSizeTest,
    );

    return server == null ? -1 : 0;
  }
}
