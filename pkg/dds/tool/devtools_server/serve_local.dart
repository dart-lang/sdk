// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:dds/devtools_server.dart';

const argDevToolsBuild = 'devtools-build';

void main(List<String> args) {
  final argParser = DevToolsServer.buildArgParser()
    ..addOption(
      argDevToolsBuild,
      help: 'The location of the DevTools build to serve from DevTools server '
          '(e.g. --devtools-build=absolute/path/to/devtools/build).',
      mandatory: true,
    );

  try {
    final ArgResults argResults = argParser.parse(args);
    unawaited(
      DevToolsServer().serveDevToolsWithArgs(
        _removeDevToolsBuildOption(args),
        customDevToolsPath: argResults[argDevToolsBuild],
      ),
    );
  } on FormatException catch (e) {
    print(e.message);
    print('');
    print(argParser.usage);
  }
}

/// Removes the --devtools-build option from [args].
List<String> _removeDevToolsBuildOption(List<String> args) {
  // Create a new list to mutate as the args list is fixed.
  args = args.toList();

  final option = '--$argDevToolsBuild';

  // serve_local.dart --devtools-build foo
  final index = args.indexOf(option);
  if (index != -1) {
    args.removeRange(index, index + 2);
  }

  // serve_local.dart --devtools-build=foo
  // serve_local.dart --devtools-build="foo"
  args.removeWhere((arg) => arg.startsWith('${option}='));

  return args;
}
