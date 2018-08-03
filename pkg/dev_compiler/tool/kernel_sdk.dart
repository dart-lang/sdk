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

Future main(List<String> args) async {
  // Parse flags.
  var parser = ArgParser();
  var parserOptions = parser.parse(args);
  var rest = parserOptions.rest;

  var ddcPath = path.dirname(path.dirname(path.fromUri(Platform.script)));
  Directory.current = ddcPath;

  String outputPath;
  if (rest.isNotEmpty) {
    outputPath = path.absolute(rest[0]);
  } else {
    var sdkRoot = path.absolute(path.dirname(path.dirname(ddcPath)));
    var buildDir = path.join(sdkRoot, Platform.isMacOS ? 'xcodebuild' : 'out');
    var genDir = path.join(buildDir, 'ReleaseX64', 'gen', 'utils', 'dartdevc');
    outputPath = path.join(genDir, 'kernel', 'ddc_sdk.dill');
  }

  var inputPath = path.absolute('tool/input_sdk');
  var target = DevCompilerTarget();
  var options = CompilerOptions()
    ..compileSdk = true
    ..packagesFileUri = path.toUri(path.absolute('../../.packages'))
    ..sdkRoot = path.toUri(inputPath)
    ..target = target;

  var inputs = target.extraRequiredLibraries.map(Uri.parse).toList();
  var component = await kernelForComponent(inputs, options);

  var outputDir = path.dirname(outputPath);
  await Directory(outputDir).create(recursive: true);
  await writeComponentToBinary(component, outputPath);

  var jsModule = ProgramCompiler(component, declaredVariables: {})
      .emitModule(component, [], []);
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
    await Directory(jsDir).create();
    var jsCode = jsProgramToCode(jsModule, format);
    await File(jsPath).writeAsString(jsCode.code);
    await File('$jsPath.map').writeAsString(json.encode(jsCode.sourceMap));
  }
}
