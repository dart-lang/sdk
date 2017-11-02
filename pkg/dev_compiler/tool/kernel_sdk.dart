#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:dev_compiler/src/kernel/target.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/kernel_generator.dart';
import 'package:kernel/kernel.dart';
import 'package:path/path.dart' as path;

Future main(List<String> args) async {
  Directory.current = path.dirname(path.dirname(path.fromUri(Platform.script)));

  var outputPath = path.absolute('lib/sdk/ddc_sdk.dill');
  if (args.isNotEmpty) {
    outputPath = args[0];
  }

  var target = new DevCompilerTarget();
  var options = new CompilerOptions()
    ..compileSdk = true
    ..chaseDependencies = true
    ..packagesFileUri = path.toUri(path.absolute('../../.packages'))
    ..sdkRoot = path.toUri(path.absolute('tool/input_sdk'))
    ..target = target;

  var inputs = target.extraRequiredLibraries.map(Uri.parse).toList();
  var program = await kernelForBuildUnit(inputs, options);

  // Useful for debugging:
  // writeProgramToText(program);
  await writeProgramToBinary(program, outputPath);
}
