// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:front_end/src/api_prototype/front_end.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/kernel.dart' show Program;
import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:kernel/target/vm.dart' show VmTarget;
import 'package:vm/kernel_front_end.dart' show compileToKernel;

final ArgParser _argParser = new ArgParser(allowTrailingOptions: true)
  ..addOption('platform',
      help: 'Path to vm_platform_strong.dill file', defaultsTo: null)
  ..addOption('packages', help: 'Path to .packages file', defaultsTo: null)
  ..addOption('output',
      abbr: 'o', help: 'Path to resulting dill file', defaultsTo: null)
  ..addFlag('strong-mode', help: 'Enable strong mode', defaultsTo: true);

final String _usage = '''
Usage: dart pkg/vm/bin/precompiler_kernel_front_end.dart --platform vm_platform_strong.dill [options] input.dart
Compiles Dart sources to a kernel binary file for the Dart 2.0 AOT compiler.

Options:
${_argParser.usage}
''';

const int _badUsageExitCode = 1;
const int _compileTimeErrorExitCode = 250;

const _severityCaptions = const <Severity, String>{
  Severity.error: 'Error: ',
  Severity.internalProblem: 'Internal problem: ',
  Severity.nit: 'Nit: ',
  Severity.warning: 'Warning: ',
};

main(List<String> arguments) async {
  final ArgResults options = _argParser.parse(arguments);
  final String platformKernel = options['platform'];

  if ((options.rest.length != 1) || (platformKernel == null)) {
    print(_usage);
    exit(_badUsageExitCode);
  }

  final String filename = options.rest.single;
  final String kernelBinaryFilename = options['output'] ?? "$filename.dill";
  final String packages = options['packages'];
  final bool strongMode = options['strong-mode'];

  int errors = 0;

  final CompilerOptions compilerOptions = new CompilerOptions()
    ..strongMode = strongMode
    ..target = new VmTarget(new TargetFlags(strongMode: strongMode))
    ..linkedDependencies = <Uri>[Uri.base.resolve(platformKernel)]
    ..packagesFileUri = packages != null ? Uri.base.resolve(packages) : null
    ..reportMessages = true
    ..onError = (CompilationMessage message) {
      final severity = _severityCaptions[message.severity] ?? '';
      final text = message.span?.message(message.message) ?? message.message;
      final tip = message.tip != null ? "\n${message.tip}" : '';
      print("$severity$text$tip");

      if ((message.severity != Severity.nit) &&
          (message.severity != Severity.warning)) {
        ++errors;
      }
    };

  Program program = await compileToKernel(
      Uri.base.resolve(filename), compilerOptions,
      aot: true);

  if ((errors > 0) || (program == null)) {
    exit(_compileTimeErrorExitCode);
  }

  final IOSink sink = new File(kernelBinaryFilename).openWrite();
  final BinaryPrinter printer = new BinaryPrinter(sink);
  printer.writeProgramFile(program);
  await sink.close();
}
