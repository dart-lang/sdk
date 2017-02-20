// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show
    exit,
    exitCode;

import 'package:front_end/src/fasta/ast_kind.dart' show
    AstKind;

import 'package:front_end/src/fasta/compiler_command_line.dart' show
    CompilerCommandLine;

import 'package:front_end/src/fasta/compiler_context.dart' show
    CompilerContext;

import 'package:front_end/src/fasta/outline.dart' show
    doCompile;

import 'package:front_end/src/fasta/errors.dart' show
    InputError;

import 'package:front_end/src/fasta/run.dart' show
    run;

import 'package:front_end/src/fasta/ticker.dart' show
    Ticker;

const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

main(List<String> arguments) async {
  Uri uri;
  for (int i = 0; i < iterations; i++) {
    await CompilerCommandLine.withGlobalOptions(
        "run", arguments, (CompilerContext c) async {
      if (i > 0) {
        print("\n");
      }
      try {
        uri = await doCompile(c, new Ticker(isVerbose: c.options.verbose),
            AstKind.Kernel);
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
