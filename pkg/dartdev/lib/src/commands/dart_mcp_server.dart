// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dartdev/src/commands/run.dart';

import '../core.dart';

/// This command is now just an alias for `dart run dart_mcp_server@`.
class DartMCPServerCommand extends DartdevCommand {
  static const String cmdName = 'mcp-server';

  static const String cmdDescription = '''
A stdio based Model Context Protocol (MCP) server to aid in Dart and Flutter development.''';

  static const _experimentFlag = 'experimental-mcp-server';

  DartMCPServerCommand({bool verbose = false})
    : super(cmdName, cmdDescription, verbose, hidden: true) {
    argParser.addFlag(
      _experimentFlag,
      // This flag is no longer required but we are leaving it in for
      // backwards compatibility.
      hide: true,
      defaultsTo: false,
      help:
          'A required flag in order to use this command. Passing this '
          'flag is an acknowledgement that you understand it is an '
          'experimental feature with no stability guarantees.',
    );
  }

  @override
  CommandCategory get commandCategory => CommandCategory.tools;

  @override
  Future<int> run() async {
    // We want the global arguments as we will be delegating back to the
    // command runner to run the new command.
    final forwardedArgs = globalResults!.arguments.toList();

    // Strip out the experiment flag before forwarding on the args, this flag
    // isn't supported by the actual package.
    //
    // Have to check the local arg results here, as this flag only exists on the
    // command arg parser and not the global one.
    if (argResults!.wasParsed(_experimentFlag)) {
      forwardedArgs.removeWhere((arg) => arg.endsWith(_experimentFlag));
    }

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
