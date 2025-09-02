// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File, Platform;
import 'dart:typed_data';

import 'package:expect/async_helper.dart' show asyncEnd, asyncStart;
import 'package:front_end/src/base/command_line_options.dart';
import 'package:kernel/ast.dart' show Component;
import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;
import 'package:kernel/text/ast_to_text.dart' show componentToString;
import 'package:testing/testing.dart' show StdioProcess;

Future main() async {
  asyncStart();
  Uri sourceCompiler = Uri.base.resolve("pkg/front_end/tool/compile.dart");
  Uri outline = Uri.base.resolve("pkg/front_end/tool/outline.dart");
  Directory tmp = await Directory.systemTemp.createTemp("cfe_bootstrap");
  Uri compiledOnceOutput = tmp.uri.resolve("cfe1.dill");
  Uri compiledTwiceOutput = tmp.uri.resolve("cfe2.dill");
  Uri outlineOutput = tmp.uri.resolve("outline.dill");
  try {
    await runCompiler(sourceCompiler, sourceCompiler, compiledOnceOutput);
    await runCompiler(compiledOnceOutput, sourceCompiler, compiledTwiceOutput);
    await compare(compiledOnceOutput, compiledTwiceOutput);
    await runCompiler(compiledTwiceOutput, outline, outlineOutput);
    try {
      // Test that compare actually works by comparing the compiled component
      // to the outline component (which are different, but similar).
      await compare(compiledOnceOutput, outlineOutput, silent: true);
      throw "Expected an error.";
    } on ComparisonFailed {
      // Expected.
    }
  } finally {
    await tmp.delete(recursive: true);
  }
  asyncEnd();
}

Future runCompiler(Uri compiler, Uri input, Uri output) async {
  Uri dartVm = Uri.base.resolveUri(new Uri.file(Platform.resolvedExecutable));
  String executable = dartVm.toFilePath();
  List<String> arguments = <String>[
    "-Dbenchmark=true",
    compiler.toFilePath(),
    "${Flags.compileSdk}=sdk/",
    "${Flags.output}=${output.toFilePath()}",
    Flags.verify,
    input.toFilePath(),
    "-Dbenchmark=true",
  ];
  print('Running: $executable ${arguments.join(' ')}');
  Stopwatch stopwatch = new Stopwatch()..start();
  StdioProcess result = await StdioProcess.run(
    executable,
    arguments,
    suppressOutput: false,
    timeout: const Duration(minutes: 2),
  );
  print(
    "Run finished with exit code ${result.exitCode}"
    " in ${stopwatch.elapsed}",
  );
  if (result.exitCode != 0) {
    throw "Compilation failed:\n${result.output}";
  }
}

Future compare(Uri a, Uri b, {bool silent = false}) async {
  Uint8List bytesA = await new File.fromUri(a).readAsBytes();
  Uint8List bytesB = await new File.fromUri(b).readAsBytes();
  if (bytesA.length == bytesB.length) {
    bool same = true;
    for (int i = 0; i < bytesA.length; i++) {
      if (bytesA[i] != bytesB[i]) {
        same = false;
        break;
      }
    }
    if (same) return;
  }
  if (!silent) {
    print("$a is different from $b");
  }
  Component componentA = new Component();
  Component componentB = new Component();
  new BinaryBuilder(bytesA, filename: a.toFilePath()).readComponent(componentA);
  new BinaryBuilder(bytesB, filename: b.toFilePath()).readComponent(componentB);
  RegExp splitLines = new RegExp('^', multiLine: true);
  List<String> linesA = componentToString(componentA).split(splitLines);
  List<String> linesB = componentToString(componentB).split(splitLines);
  for (int i = 0; i < linesA.length && i < linesB.length; i++) {
    String lineA = linesA[i].trimRight();
    String lineB = linesB[i].trimRight();
    if (lineA != lineB) {
      String diffHunk = "${i}c$i\n>$lineA\n---\n<$lineB";
      if (!silent) {
        print(diffHunk);
      }
    }
  }
  throw new ComparisonFailed(a, b);
}

class ComparisonFailed {
  final Uri a;
  final Uri b;

  ComparisonFailed(this.a, this.b);

  @override
  String toString() => "Error: $a is different from $b";
}
