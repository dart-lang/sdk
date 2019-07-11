#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:io';
import 'package:args/args.dart' show ArgParser;
import 'package:dev_compiler/src/compiler/module_builder.dart';
import 'package:dev_compiler/src/compiler/shared_command.dart'
    show SharedCompilerOptions;
import 'package:dev_compiler/src/kernel/target.dart';
import 'package:dev_compiler/src/kernel/command.dart';
import 'package:dev_compiler/src/kernel/compiler.dart';
import 'package:front_end/src/api_unstable/ddc.dart'
    show
        CompilerOptions,
        kernelForComponent,
        DiagnosticMessage,
        printDiagnosticMessage,
        Severity;
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:path/path.dart' as p;

Future main(List<String> args) async {
  var ddcPath = p.dirname(p.dirname(p.fromUri(Platform.script)));

  // Parse flags.
  var parser = ArgParser()
    ..addOption('output')
    ..addOption('libraries',
        defaultsTo: p.join(ddcPath, '../../sdk/lib/libraries.json'))
    ..addOption('packages', defaultsTo: p.join(ddcPath, '../../.packages'));
  var parserOptions = parser.parse(args);

  var outputPath = parserOptions['output'] as String;
  if (outputPath == null) {
    var sdkRoot = p.absolute(p.dirname(p.dirname(ddcPath)));
    var buildDir = p.join(sdkRoot, Platform.isMacOS ? 'xcodebuild' : 'out');
    var genDir = p.join(buildDir, 'ReleaseX64', 'gen', 'utils', 'dartdevc');
    outputPath = p.join(genDir, 'kernel', 'ddc_sdk.dill');
  }

  var librarySpecPath = parserOptions['libraries'] as String;
  var packagesPath = parserOptions['packages'] as String;

  var target = DevCompilerTarget(TargetFlags());
  void onDiagnostic(DiagnosticMessage message) {
    printDiagnosticMessage(message, print);
    if (message.severity == Severity.error ||
        message.severity == Severity.internalProblem) {
      exitCode = 1;
    }
  }

  var options = CompilerOptions()
    ..compileSdk = true
    // TODO(sigmund): remove these two unnecessary options when possible.
    ..sdkRoot = Uri.base
    ..packagesFileUri = Uri.base.resolveUri(Uri.file(packagesPath))
    ..librariesSpecificationUri = Uri.base.resolveUri(Uri.file(librarySpecPath))
    ..target = target
    ..onDiagnostic = onDiagnostic;

  var inputs = target.extraRequiredLibraries.map(Uri.parse).toList();
  var component = await kernelForComponent(inputs, options);

  var outputDir = p.dirname(outputPath);
  await Directory(outputDir).create(recursive: true);
  await writeComponentToBinary(component, outputPath);
  File(librarySpecPath)
      .copySync(p.join(p.dirname(outputDir), p.basename(librarySpecPath)));

  var jsModule = ProgramCompiler(
      component,
      target.hierarchy,
      SharedCompilerOptions(moduleName: 'dart_sdk'),
      {}).emitModule(component, [], [], {});
  var moduleFormats = {
    'amd': ModuleFormat.amd,
    'common': ModuleFormat.common,
    'es6': ModuleFormat.es6,
    'legacy': ModuleFormat.legacy,
  };

  for (var name in moduleFormats.keys) {
    var format = moduleFormats[name];
    var jsDir = p.join(outputDir, name);
    var jsPath = p.join(jsDir, 'dart_sdk.js');
    var mapPath = '$jsPath.map';
    await Directory(jsDir).create();
    var jsCode = jsProgramToCode(jsModule, format,
        jsUrl: jsPath, mapUrl: mapPath, buildSourceMap: true);
    await File(jsPath).writeAsString(jsCode.code);
    await File(mapPath).writeAsString(json.encode(jsCode.sourceMap));
  }
}
