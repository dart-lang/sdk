#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library dev_compiler.web.main;

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:js/js.dart';

import 'web_command.dart';

@JS(r'$setUpDartDevCompilerInBrowser')
external set setUpCompilerInBrowser(Function function);

Future main() async {
  var args = ['compile', '--repl-compile'];
  _runCommand(args);
}

/// Runs a single compile command, and returns an exit code.
Future<int> _runCommand(List<String> args,
    {MessageHandler messageHandler}) async {
  try {
    // TODO: Remove CommandRunner and args if possible. May run into issues
    // with ArgResults or ArgParsers.
    var runner = new CommandRunner('dartdevc', 'Dart Development Compiler');
    runner.addCommand(new WebCompileCommand(messageHandler: messageHandler));
    setUpCompilerInBrowser = allowInterop((await runner.run(args)) as Function);
  } catch (e, s) {
    return _handleError(e, s, args, messageHandler: messageHandler);
  }
  return 1;
}

/// Handles [error] in a uniform fashion. Returns the proper exit code and calls
/// [messageHandler] with messages.
int _handleError(dynamic error, dynamic stackTrace, List<String> args,
    {MessageHandler messageHandler}) {
  messageHandler ??= print;

  if (error is UsageException) {
    // Incorrect usage, input file not found, etc.
    messageHandler(error);
    return 64;
  } else if (error is CompileErrorException) {
    // Code has error(s) and failed to compile.
    messageHandler(error);
    return 1;
  } else {
    // Anything else is likely a compiler bug.
    //
    // --unsafe-force-compile is a bit of a grey area, but it's nice not to
    // crash while compiling
    // (of course, output code may crash, if it had errors).
    //
    messageHandler("");
    messageHandler("We're sorry, you've found a bug in our compiler.");
    messageHandler("You can report this bug at:");
    messageHandler(
        "    https://github.com/dart-lang/sdk/issues/labels/area-dev-compiler");
    messageHandler("");
    messageHandler(
        "Please include the information below in your report, along with");
    messageHandler(
        "any other information that may help us track it down. Thanks!");
    messageHandler("");
    messageHandler("    dartdevc arguments: " + args.join(' '));
    messageHandler("");
    messageHandler("```");
    messageHandler(error);
    messageHandler(stackTrace);
    messageHandler("```");
    return 70;
  }
}
