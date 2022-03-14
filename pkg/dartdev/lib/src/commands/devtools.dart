// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:dds/devtools_server.dart';
import 'package:dds/src/devtools/utils.dart';
import 'package:path/path.dart' as path;

import '../core.dart';
import '../sdk.dart';

class DevToolsCommand extends DartdevCommand {
  DevToolsCommand({
    this.customDevToolsPath,
    bool verbose = false,
  })  : _argParser = DevToolsServer.buildArgParser(
          verbose: verbose,
          includeHelpOption: false,
        ),
        super(
          'devtools',
          DevToolsServer.commandDescription,
          verbose,
        );

  final String? customDevToolsPath;

  @override
  ArgParser get argParser => _argParser;
  late final ArgParser _argParser;

  @override
  String get name => 'devtools';

  @override
  String get description => DevToolsServer.commandDescription;

  @override
  String get invocation => '${super.invocation} [service protocol uri]';

  @override
  Future<int> run() async {
    final args = argResults!;
    final bool version = args[DevToolsServer.argVersion];
    final bool machineMode = args[DevToolsServer.argMachine];
    // launchBrowser defaults based on machine-mode if not explicitly supplied.
    final bool launchBrowser = args.wasParsed(DevToolsServer.argLaunchBrowser)
        ? args[DevToolsServer.argLaunchBrowser]
        : !machineMode;
    final bool enableNotifications =
        args[DevToolsServer.argEnableNotifications];
    final bool allowEmbedding = args.wasParsed(DevToolsServer.argAllowEmbedding)
        ? args[DevToolsServer.argAllowEmbedding]
        : true;

    final port = args[DevToolsServer.argPort] != null
        ? int.tryParse(args[DevToolsServer.argPort]) ?? 0
        : 0;

    final bool headlessMode = args[DevToolsServer.argHeadlessMode];
    final bool debugMode = args[DevToolsServer.argDebugMode];

    final numPortsToTry = args[DevToolsServer.argTryPorts] != null
        ? int.tryParse(args[DevToolsServer.argTryPorts]) ?? 0
        : DevToolsServer.defaultTryPorts;

    final bool verboseMode = args[DevToolsServer.argVerbose];
    final String? hostname = args[DevToolsServer.argHost];
    final String? appSizeBase = args[DevToolsServer.argAppSizeBase];
    final String? appSizeTest = args[DevToolsServer.argAppSizeTest];

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
      return 0;
    }

    // Prefer getting the VM URI from the rest args; fall back on the 'vm-url'
    // option otherwise.
    String? serviceProtocolUri;
    if (args.rest.isNotEmpty) {
      serviceProtocolUri = args.rest.first;
    } else if (args.wasParsed(DevToolsServer.argVmUri)) {
      serviceProtocolUri = args[DevToolsServer.argVmUri];
    }

    // Support collecting profile data.
    String? profileFilename;
    if (args.wasParsed(DevToolsServer.argProfileMemory)) {
      profileFilename = args[DevToolsServer.argProfileMemory];
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
