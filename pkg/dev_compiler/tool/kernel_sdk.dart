#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'package:dev_compiler/src/compiler/module_builder.dart';
import 'package:dev_compiler/src/kernel/target.dart';
import 'package:dev_compiler/src/kernel/command.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/kernel_generator.dart';
import 'package:kernel/kernel.dart';
import 'package:path/path.dart' as path;
import 'patch_sdk.dart' as patch_sdk;

Future main(List<String> args) async {
  Directory.current = path.dirname(path.dirname(path.fromUri(Platform.script)));

  var outputPath =
      path.absolute(args.length > 0 ? args[0] : 'lib/sdk/ddc_sdk.dill');

  patch_sdk.main(['../..', 'tool/input_sdk', 'gen/patched_sdk']);

  var inputPath = path.absolute('gen/patched_sdk');
  var target = new DevCompilerTarget();
  var options = new CompilerOptions()
    ..compileSdk = true
    ..chaseDependencies = true
    ..packagesFileUri = path.toUri(path.absolute('../../.packages'))
    ..sdkRoot = path.toUri(inputPath)
    ..target = target;

  var inputs = target.extraRequiredLibraries.map(Uri.parse).toList();
  var program = await kernelForBuildUnit(inputs, options);

  // Useful for debugging:
  // writeProgramToText(program);
  await writeProgramToBinary(program, outputPath);

  bool generateJS = false;
  if (generateJS) {
    var jsModule = compileToJSModule(program, [], [], {});
    var jsPath = path.join(path.basename(outputPath), 'dart_sdk.kernel.js');
    new File(jsPath)
        .writeAsStringSync(jsProgramToString(jsModule, ModuleFormat.es6));
  }
}
