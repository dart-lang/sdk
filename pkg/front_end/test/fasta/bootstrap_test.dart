// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'dart:io' show Directory, File, Platform;

import 'package:async_helper/async_helper.dart' show asyncEnd, asyncStart;

import 'package:testing/testing.dart' show StdioProcess;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:kernel/ast.dart' show Program;

import 'package:kernel/text/ast_to_text.dart' show programToString;

Future main() async {
  asyncStart();
  Uri sourceCompiler =
      Uri.base.resolve("pkg/front_end/tool/_fasta/compile.dart");
  Uri outline = Uri.base.resolve("pkg/front_end/tool/_fasta/outline.dart");
  Directory tmp = await Directory.systemTemp.createTemp("fasta_bootstrap");
  Uri compiledOnceOutput = tmp.uri.resolve("fasta1.dill");
  Uri compiledTwiceOutput = tmp.uri.resolve("fasta2.dill");
  Uri outlineOutput = tmp.uri.resolve("outline.dill");
  try {
    await runCompiler(sourceCompiler, sourceCompiler, compiledOnceOutput);
    await runCompiler(compiledOnceOutput, sourceCompiler, compiledTwiceOutput);
    await compare(compiledOnceOutput, compiledTwiceOutput);
    await runCompiler(compiledTwiceOutput, outline, outlineOutput);
    try {
      // Test that compare actually works by comparing the compile program to
      // the outline program (which are different, but similar).
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
  Uri dartVm = Uri.base.resolve(Platform.resolvedExecutable);
  StdioProcess result = await StdioProcess.run(dartVm.toFilePath(), <String>[
    "-c",
    compiler.toFilePath(),
    "--compile-sdk=sdk/",
    "--output=${output.toFilePath()}",
    "--verify",
    input.toFilePath(),
  ]);
  if (result.output.isNotEmpty) {
    print(result.output);
  }
  if (result.exitCode != 0) {
    throw "Compilation failed.";
  }
}

Future compare(Uri a, Uri b, {bool silent: false}) async {
  List<int> bytesA = await new File.fromUri(a).readAsBytes();
  List<int> bytesB = await new File.fromUri(b).readAsBytes();
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
  Program programA = new Program();
  Program programB = new Program();
  new BinaryBuilder(bytesA, a.toFilePath()).readProgram(programA);
  new BinaryBuilder(bytesB, b.toFilePath()).readProgram(programB);
  RegExp splitLines = new RegExp('^', multiLine: true);
  List<String> linesA = programToString(programA).split(splitLines);
  List<String> linesB = programToString(programB).split(splitLines);
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

  toString() => "Error: $a is different from $b";
}
