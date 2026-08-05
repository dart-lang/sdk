// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:dartdev/src/commands/run.dart';

import '../core.dart';
import '../sdk.dart';
import '../vm_interop_handler.dart';

/// This command is now just an alias for `dart run dart_mcp_server@`.
class DartMCPServerCommand extends DartdevCommand {
  static const String cmdName = 'mcp-server';

  static const String cmdDescription = '''
A stdio based Model Context Protocol (MCP) server to aid in Dart and Flutter development.''';

  static const _experimentFlag = 'experimental-mcp-server';

  DartMCPServerCommand({bool verbose = false})
    : super(cmdName, cmdDescription, verbose, hidden: true);

  /// Allow any arguments, they will be forwarded to the actual mcp server.
  @override
  ArgParser createArgParser() {
    return ArgParser.allowAnything();
  }

  @override
  void printUsage() {
    final executable = runner!.executableName;
    print('''
Usage: dart mcp-server [arguments]

Note: This command is a wrapper around the dart_mcp_server package.
To see the options, run "$executable $name --help".

Run "$executable help" to see global options.''');
  }

  @override
  CommandCategory get commandCategory => CommandCategory.tools;

  @override
  Future<int> run() async {
    // Internally we ship the MCP server as a snapshot, check for that
    // and launch it if present.
    if (checkArtifactExists(sdk.mcpServerSnapshot, logError: false)) {
      final args = argResults!.arguments;
      try {
        VmInteropHandler.run(
          sdk.mcpServerSnapshot,
          args,
          packageConfigOverride: null,
          useExecProcess: false,
        );
        return 0;
      } catch (e, st) {
        log.stderr('Error: launching mcp server failed');
        log.stderr(e.toString());
        if (verbose) {
          log.stderr(st.toString());
        }
        return 255;
      }
    }

    // We want the global arguments as we will be delegating back to the
    // command runner to run the new command.
    final forwardedArgs = globalResults!.arguments.toList();

    // Strip out the experiment flag before forwarding on the args, this flag
    // isn't supported by the actual package.
    forwardedArgs.removeWhere((arg) => arg.endsWith(_experimentFlag));

    // Find the index of the original command argument and replace it with
    // `run dart_mcp_server@`.
    final commandIndex = forwardedArgs.indexOf(cmdName);
    if (commandIndex == -1) {
      throw StateError(
        'Reached mcp-server command without `mcp-server` in arguments.',
      );
    }
    forwardedArgs.replaceRange(commandIndex, commandIndex + 1, [
      RunCommand.cmdName,
      'dart_mcp_server@',
    ]);

    // Finally, run the new command.
    return await runner!.run(forwardedArgs) ?? 0;
  }
}
