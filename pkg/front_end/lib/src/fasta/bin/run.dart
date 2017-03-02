// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show exit, exitCode;

import '../compiler_command_line.dart' show CompilerCommandLine;

import '../compiler_context.dart' show CompilerContext;

import '../outline.dart' show CompileTask;

import '../errors.dart' show InputError;

import '../run.dart' show run;

import '../ticker.dart' show Ticker;

const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

main(List<String> arguments) async {
  Uri uri;
  for (int i = 0; i < iterations; i++) {
    await CompilerCommandLine.withGlobalOptions("run", arguments,
        (CompilerContext c) async {
      if (i > 0) {
        print("\n");
      }
      try {
        CompileTask task =
            new CompileTask(c, new Ticker(isVerbose: c.options.verbose));
        uri = await task.compile();
      } on InputError catch (e) {
        print(e.format());
        exit(1);
      }
      if (exitCode != 0) exit(exitCode);
      if (i + 1 == iterations) {
        exit(await run(uri, c));
      }
    });
  }
}
