// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:dds/devtools_server.dart';
import 'package:path/path.dart' as path;

import '../core.dart';
import '../sdk.dart';
import '../utils.dart';

class DevToolsCommand extends DartdevCommand {
  DevToolsCommand({
    this.customDevToolsPath,
    bool verbose = false,
  })  : argParser = DevToolsServer.buildArgParser(
          verbose: verbose,
          includeHelpOption: false,
          usageLineLength: dartdevUsageLineLength,
        ),
        super(
          'devtools',
          DevToolsServer.commandDescription,
          verbose,
        );

  final String? customDevToolsPath;

  @override
  final ArgParser argParser;

  @override
  String get name => 'devtools';

  @override
  String get description => DevToolsServer.commandDescription;

  @override
  String get invocation => '${super.invocation} [service protocol uri]';

  @override
  Future<int> run() async {
    final args = argResults!;

    final sdkDir = path.dirname(sdk.dart);
    final fullSdk = sdkDir.endsWith('bin');
    final devToolsBinaries =
        fullSdk ? sdk.devToolsBinaries : path.absolute(sdkDir, 'devtools');

    final server = await DevToolsServer().serveDevToolsWithArgs(
      args.arguments,
      customDevToolsPath: devToolsBinaries,
    );
    return server == null ? -1 : 0;
  }
}
