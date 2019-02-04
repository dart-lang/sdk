// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper to run fasta with the right target configuration to build dart2js
/// applications using the dart2js platform libraries.
// TODO(sigmund): delete this file once we can configure fasta directly on the
// command line.
library compiler.tool.generate_kernel;

import 'dart:io';

import 'package:args/args.dart';
import 'package:compiler/src/kernel/dart2js_target.dart';
import 'package:compiler/src/filenames.dart';
import 'package:front_end/src/api_unstable/dart2js.dart'
    show
        CompilerOptions,
        computePlatformBinariesLocation,
        kernelForProgram,
        relativizeUri;
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';

main(List<String> args) async {
  ArgResults flags = _argParser.parse(args);
  var options = new CompilerOptions()
    ..target = new Dart2jsTarget("dart2js", new TargetFlags(legacyMode: true))
    ..packagesFileUri = Uri.base.resolve('.packages')
    ..setExitCodeOnProblem = true
    ..linkedDependencies = [
      Uri.base.resolve(nativeToUriPath(flags['platform']))
    ];

  if (flags.rest.isEmpty) {
    var script = relativizeUri(Platform.script);
    var platform =
        relativizeUri(Uri.base.resolve(nativeToUriPath(flags['platform'])));
    print('usage: ${Platform.executable} $script '
        '[--platform=$platform] [--out=out.dill] program.dart');
    exit(1);
  }

  Uri entry = Uri.base.resolve(nativeToUriPath(flags.rest.first));
  var component = await kernelForProgram(entry, options);
  await writeComponentToBinary(component, flags['out']);
}

ArgParser _argParser = new ArgParser()
  ..addOption('platform',
      help: 'location of the precompiled dart2js sdk',
      defaultsTo: _defaultPlatform)
  ..addOption('out',
      abbr: 'o', help: 'output location', defaultsTo: 'out.dill');

String _defaultPlatform = computePlatformBinariesLocation()
    .resolve('dart2js_platform.dill')
    .toFilePath();
