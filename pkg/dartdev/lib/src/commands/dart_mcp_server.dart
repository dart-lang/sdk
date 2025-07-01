// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../core.dart';
import '../sdk.dart';
import '../vm_interop_handler.dart';

class DartMCPServerCommand extends DartdevCommand {
  static const String cmdName = 'mcp-server';

  static const String cmdDescription = '''
A stdio based Model Context Protocol (MCP) server to aid in Dart and Flutter development.''';

  static const _forceRootsFallbackFlag = 'force-roots-fallback';
  static const _experimentFlag = 'experimental-mcp-server';

  DartMCPServerCommand({bool verbose = false})
      : super(cmdName, cmdDescription, verbose, hidden: true) {
    argParser
      ..addFlag(
        _forceRootsFallbackFlag,
        negatable: true,
        defaultsTo: false,
        help:
            'Forces a behavior for project roots which uses MCP tools instead '
            'of the native MCP roots. This can be helpful for clients like '
            'Cursor which claim to have roots support but do not actually '
            'support it.',
      )
      ..addFlag(_experimentFlag,
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
    final args = argResults!;
    try {
      VmInteropHandler.run(
        sdk.dartAotRuntime,
        [
          sdk.dartMCPServerAotSnapshot,
          if (args.flag(_forceRootsFallbackFlag)) '--$_forceRootsFallbackFlag'
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
