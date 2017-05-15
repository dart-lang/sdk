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

Future<Function> _setUpCompilerInBrowser;
main() {
  var args = ['compile', '--repl-compile'];

  // Avoid race condition when users try to call $setUpDartDevCompilerInBrowser
  // before it is ready by installing the method immediately and making the body
  // of the method async.
  setUpCompilerInBrowser = allowInterop((String sdkUrl,
      JSMap<String, String> summaryMap,
      Function onCompileReady,
      Function onError,
      [Function onProgress]) async {
    (await _setUpCompilerInBrowser)(
        sdkUrl, summaryMap, onCompileReady, onError, onProgress);
  });
  _runCommand(args);
}

/// Runs a single compile command, and returns an exit code.
_runCommand(List<String> args, {MessageHandler messageHandler}) {
  try {
    // TODO: Remove CommandRunner and args if possible. May run into issues
    // with ArgResults or ArgParsers.
    var runner = new CommandRunner('dartdevc', 'Dart Development Compiler');
    runner.addCommand(new WebCompileCommand(messageHandler: messageHandler));
    _setUpCompilerInBrowser = runner.run(args) as Future<Function>;
  } catch (e, s) {
    _handleError(e, s, args, messageHandler: messageHandler);
  }
}

/// Handles [error] in a uniform fashion. Calls [messageHandler] with messages.
_handleError(dynamic error, dynamic stackTrace, List<String> args,
    {MessageHandler messageHandler}) {
  messageHandler ??= print;

  if (error is UsageException) {
    // Incorrect usage, input file not found, etc.
    messageHandler(error);
  } else if (error is CompileErrorException) {
    // Code has error(s) and failed to compile.
    messageHandler(error);
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
  }
}
