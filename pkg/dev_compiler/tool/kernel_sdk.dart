#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:dev_compiler/src/kernel/target.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/fasta/ticker.dart';
import 'package:path/path.dart' as path;

Future main(List<String> args) {
  Directory.current = path.dirname(path.dirname(path.fromUri(Platform.script)));
  var target = new DevCompilerTarget();
  var options = new ProcessedOptions(
      new CompilerOptions()
        ..compileSdk = true
        ..packagesFileUri = path.toUri(path.absolute('../../.packages'))
        ..sdkRoot = path.toUri(path.absolute('tool/input_sdk'))
        ..target = target,
      false,
      target.extraRequiredLibraries.map(Uri.parse).toList(),
      path.toUri(path.absolute('lib/sdk/ddc_sdk.dill')));

  return CompilerContext.runWithOptions(options, (c) async {
    var ticker = new Ticker(isVerbose: false);
    var uriTranslator = await c.options.getUriTranslator();
    var dillTarget = new DillTarget(ticker, uriTranslator, c.options.target);
    var kernelTarget = new KernelTarget(
        c.fileSystem, false, dillTarget, uriTranslator,
        uriToSource: c.uriToSource);
    for (var input in c.options.inputs) {
      kernelTarget.read(input);
    }
    await dillTarget.buildOutlines();
    await kernelTarget.buildOutlines();
    if (exitCode != 0) return;
    var program = await kernelTarget.buildProgram();
    // Useful for debugging:
    // printProgramText(program);
    await writeProgramToFile(program, c.options.output);
  });
}
