#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:io';
import 'package:args/args.dart' show ArgParser;
import 'package:dev_compiler/src/compiler/module_builder.dart';
import 'package:dev_compiler/src/kernel/target.dart';
import 'package:dev_compiler/src/kernel/command.dart';
import 'package:dev_compiler/src/kernel/compiler.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/kernel_generator.dart';
import 'package:kernel/kernel.dart';
import 'package:path/path.dart' as path;
import 'patch_sdk.dart' as patch_sdk;

Future main(List<String> args) async {
  // Parse flags.
  var parser = new ArgParser();
  var parserOptions = parser.parse(args);
  var rest = parserOptions.rest;

  Directory.current = path.dirname(path.dirname(path.fromUri(Platform.script)));

  var outputPath =
      path.absolute(rest.length > 0 ? rest[0] : 'gen/sdk/kernel/ddc_sdk.dill');

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
  var component = await kernelForComponent(inputs, options);

  var outputDir = path.dirname(outputPath);
  await new Directory(outputDir).create(recursive: true);
  await writeComponentToBinary(component, outputPath);

  var jsModule = new ProgramCompiler(component, declaredVariables: {})
      .emitProgram(component, [], []);
  var moduleFormats = {
    'amd': ModuleFormat.amd,
    'common': ModuleFormat.common,
    'es6': ModuleFormat.es6,
    'legacy': ModuleFormat.legacy,
  };

  for (var name in moduleFormats.keys) {
    var format = moduleFormats[name];
    var jsDir = path.join(outputDir, name);
    var jsPath = path.join(jsDir, 'dart_sdk.js');
    await new Directory(jsDir).create();
    var jsCode = jsProgramToCode(jsModule, format);
    await new File(jsPath).writeAsString(jsCode.code);
    await new File('$jsPath.map').writeAsString(json.encode(jsCode.sourceMap));
  }
}
