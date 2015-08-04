#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Runs io.js with dev_compiler's generated code.
library dev_compiler.bin.devrun;

import 'dart:io';

import 'package:dev_compiler/src/compiler.dart' show validateOptions, compile;
import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/runner/runtime_utils.dart'
    show listOutputFiles, getMainModuleName;
import 'package:dev_compiler/src/runner/v8_runner.dart' show V8Runner;

import 'package:path/path.dart';

void _showUsageAndExit() {
  print('usage: dartdevrun [<options>] <file.dart>\n');
  print('<file.dart> is a single Dart file to run.\n');
  print('<options> include:\n');
  print(argParser.usage);
  exit(1);
}

main(List<String> args) async {
  args = []
    ..add('--arrow-fn-bind-this')
    ..addAll(args);

  CompilerOptions options = validateOptions(args, forceOutDir: true);
  if (options == null || options.help) {
    _showUsageAndExit();
  }
  if (options.inputs.length != 1) {
    stderr.writeln("Please only specify one input to run");
    _showUsageAndExit();
  }
  var runner = new V8Runner(options);

  if (!compile(options)) exit(1);

  var files = await listOutputFiles(options);
  var startStatement = 'dart_library.start("${getMainModuleName(options)}");';

  // TODO(ochafik): Only generate the html when some flag is set.
  await _writeHtmlRunner(options, files, startStatement);

  // Give our soul (and streams) away to iojs.
  Process process = await runner.start(files, startStatement);
  stdin.pipe(process.stdin);
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
  exit(await process.exitCode);
}

/// Generates an HTML file that can be used to run the output with Chrome Dev.
_writeHtmlRunner(
    CompilerOptions options, List<File> files, String startStatement) async {
  String outputDir = options.codegenOptions.outputDir;
  String htmlOutput = join(outputDir, "run.html");
  await new File(htmlOutput).writeAsString('''
    <html><head></head><body>
    ${files.map((f) =>
        '<script src="${relative(f.path, from: outputDir)}"></script>')
            .join("\n")}
    <script>$startStatement</script>
    </body></html>
  ''');

  stderr.writeln(
      'Wrote $htmlOutput. It can be opened in Chrome Dev with the following flags:\n'
      '--js-flags="--harmony-arrow-functions '
      '--harmony-classes '
      '--harmony-computed-property-names '
      '--harmony-spreadcalls"'
      '\n');
}
