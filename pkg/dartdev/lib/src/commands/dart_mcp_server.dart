// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:dart_mcp_server/arg_parser.dart' as dart_mcp_server;
import 'package:dartdev/src/utils.dart';

import '../core.dart';
import '../sdk.dart';
import '../vm_interop_handler.dart';

class DartMCPServerCommand extends DartdevCommand {
  static const String cmdName = 'mcp-server';

  static const String cmdDescription = '''
A stdio based Model Context Protocol (MCP) server to aid in Dart and Flutter development.''';

  static const _experimentFlag = 'experimental-mcp-server';

  @override
  ArgParser createArgParser() => dart_mcp_server.createArgParser(
      usageLineLength: dartdevUsageLineLength, includeHelp: false);

  DartMCPServerCommand({bool verbose = false})
      : super(cmdName, cmdDescription, verbose, hidden: true) {
    argParser.addFlag(_experimentFlag,
        // This flag is no longer required but we are leaving it in for
        // backwards compatibility.
        hide: true,
        defaultsTo: false,
        help: 'A required flag in order to use this command. Passing this '
            'flag is an acknowledgement that you understand it is an '
            'experimental feature with no stability guarantees.');
  }

  @override
  CommandCategory get commandCategory => CommandCategory.tools;

  @override
  Future<int> run() async {
    final parsedArgs = argResults!;

    // Strip out the experiment flag before forwarding on the args, this flag
    // isn't supported by the actual binary.
    final forwardedArgs = argResults!.arguments.toList();
    if (parsedArgs.wasParsed(_experimentFlag)) {
      forwardedArgs.removeWhere((arg) => arg.endsWith(_experimentFlag));
    }
    try {
      VmInteropHandler.run(
        sdk.dartAotRuntime,
        [
          sdk.dartMCPServerAotSnapshot,
          ...forwardedArgs,
        ],
        useExecProcess: true,
      );
      return 0;
    } catch (e, st) {
      log.stderr('Error: launching Dart MCP server failed');
      log.stderr(e.toString());
      if (verbose) {
        log.stderr(st.toString());
      }
      return 255;
    }
  }
}
