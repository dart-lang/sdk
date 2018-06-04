// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:front_end/src/api_prototype/front_end.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/src/tool/batch_util.dart' as batch_util;
import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:kernel/target/vm.dart' show VmTarget;
import 'package:kernel/text/ast_to_text.dart'
    show globalDebuggingNames, NameSystem;
import 'package:vm/bytecode/gen_bytecode.dart' show isKernelBytecodeEnabled;
import 'package:vm/kernel_front_end.dart'
    show compileToKernel, ErrorDetector, ErrorPrinter;

final ArgParser _argParser = new ArgParser(allowTrailingOptions: true)
  ..addOption('platform',
      help: 'Path to vm_platform_strong.dill file', defaultsTo: null)
  ..addOption('packages', help: 'Path to .packages file', defaultsTo: null)
  ..addOption('output',
      abbr: 'o', help: 'Path to resulting dill file', defaultsTo: null)
  ..addFlag('aot',
      help:
          'Produce kernel file for AOT compilation (enables global transformations).',
      defaultsTo: false)
  ..addFlag('strong-mode', help: 'Enable strong mode', defaultsTo: true)
  ..addFlag('sync-async',
      help: 'Start `async` functions synchronously', defaultsTo: true)
  ..addFlag('embed-sources',
      help: 'Embed source files in the generated kernel component',
      defaultsTo: true)
  ..addFlag('tfa',
      help:
          'Enable global type flow analysis and related transformations in AOT mode.',
      defaultsTo: true)
  ..addMultiOption('define',
      abbr: 'D',
      help: 'The values for the environment constants (e.g. -Dkey=value).')
  ..addFlag('enable-asserts',
      help: 'Whether asserts will be enabled.', defaultsTo: false)
  ..addFlag('enable-constant-evaluation',
      help: 'Whether kernel constant evaluation will be enabled.',
      defaultsTo: true)
  ..addMultiOption('entry-points',
      help: 'Path to JSON file with the list of entry points')
  ..addFlag('gen-bytecode',
      help: 'Generate bytecode', defaultsTo: isKernelBytecodeEnabled)
  ..addFlag('drop-ast',
      help: 'Drop AST for members with bytecode', defaultsTo: false);

final String _usage = '''
Usage: dart pkg/vm/bin/gen_kernel.dart --platform vm_platform_strong.dill [options] input.dart
Compiles Dart sources to a kernel binary file for Dart VM.

Options:
${_argParser.usage}
''';

const int _badUsageExitCode = 1;
const int _compileTimeErrorExitCode = 254;

main(List<String> arguments) async {
  if (arguments.isNotEmpty && arguments.last == '--batch') {
    await runBatchModeCompiler();
  } else {
    exit(await compile(arguments));
  }
}

Future<int> compile(List<String> arguments) async {
  final ArgResults options = _argParser.parse(arguments);
  final String platformKernel = options['platform'];

  if ((options.rest.length != 1) || (platformKernel == null)) {
    print(_usage);
    return _badUsageExitCode;
  }

  final String filename = options.rest.single;
  final String kernelBinaryFilename = options['output'] ?? "$filename.dill";
  final String packages = options['packages'];
  final bool strongMode = options['strong-mode'];
  final bool aot = options['aot'];
  final bool syncAsync = options['sync-async'];
  final bool tfa = options['tfa'];
  final bool genBytecode = options['gen-bytecode'];
  final bool dropAST = options['drop-ast'];
  final bool enableAsserts = options['enable-asserts'];
  final bool enableConstantEvaluation = options['enable-constant-evaluation'];
  final Map<String, String> environmentDefines = {};

  if (!_parseDefines(options['define'], environmentDefines)) {
    return _badUsageExitCode;
  }

  final List<String> entryPoints = options['entry-points'] ?? <String>[];
  if (entryPoints.isEmpty) {
    entryPoints.addAll([
      'pkg/vm/lib/transformations/type_flow/entry_points.json',
      'pkg/vm/lib/transformations/type_flow/entry_points_extra.json',
      'pkg/vm/lib/transformations/type_flow/entry_points_extra_standalone.json',
    ]);
  }

  final errorPrinter = new ErrorPrinter();
  final errorDetector = new ErrorDetector(previousErrorHandler: errorPrinter);

  final CompilerOptions compilerOptions = new CompilerOptions()
    ..strongMode = strongMode
    ..target = new VmTarget(
        new TargetFlags(strongMode: strongMode, syncAsync: syncAsync))
    ..linkedDependencies = <Uri>[
      Uri.base.resolveUri(new Uri.file(platformKernel))
    ]
    ..packagesFileUri =
        packages != null ? Uri.base.resolveUri(new Uri.file(packages)) : null
    ..reportMessages = true
    ..onProblem = errorDetector
    ..embedSourceText = options['embed-sources'];

  final inputUri = new Uri.file(filename);
  final component = await compileToKernel(
      Uri.base.resolveUri(inputUri), compilerOptions,
      aot: aot,
      useGlobalTypeFlowAnalysis: tfa,
      entryPoints: entryPoints,
      environmentDefines: environmentDefines,
      genBytecode: genBytecode,
      dropAST: dropAST,
      enableAsserts: enableAsserts,
      enableConstantEvaluation: enableConstantEvaluation);

  errorPrinter.printCompilationMessages(inputUri);

  if (errorDetector.hasCompilationErrors || (component == null)) {
    return _compileTimeErrorExitCode;
  }

  final IOSink sink = new File(kernelBinaryFilename).openWrite();
  final BinaryPrinter printer = new BinaryPrinter(sink);
  printer.writeComponentFile(component);
  await sink.close();

  return 0;
}

Future runBatchModeCompiler() async {
  await batch_util.runBatch((List<String> arguments) async {
    // TODO(kustermann): Once we know where the new IKG api is and how to use
    // it, we should take advantage of it.
    //
    // Important things to note:
    //
    //   * Our global transformations must never alter the AST structures which
    //     the statefull IKG generator keeps across compilations.
    //     => We need to make our own copy.
    //
    //   * We must ensure the stateful IKG generator keeps giving us all the
    //     compile-time errors, warnings, hints for every compilation and we
    //     report the compilation result accordingly.
    //
    final exitCode = await compile(arguments);

    // Re-create global NameSystem to avoid accumulating garbage.
    globalDebuggingNames = new NameSystem();

    switch (exitCode) {
      case 0:
        return batch_util.CompilerOutcome.Ok;
      case _compileTimeErrorExitCode:
      case _badUsageExitCode:
        return batch_util.CompilerOutcome.Fail;
      default:
        throw 'Could not obtain correct exit code from compiler.';
    }
  });
}

bool _parseDefines(
    List<String> dFlags, Map<String, String> environmentDefines) {
  for (final String dflag in dFlags) {
    final equalsSignIndex = dflag.indexOf('=');
    if (equalsSignIndex < 0) {
      environmentDefines[dflag] = '';
    } else if (equalsSignIndex > 0) {
      final key = dflag.substring(0, equalsSignIndex);
      final value = dflag.substring(equalsSignIndex + 1);
      environmentDefines[key] = value;
    } else {
      print('The environment constant options must have a key (was: "$dflag")');
      print(_usage);
      return false;
    }
  }
  return true;
}
