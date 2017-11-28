// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:io' show Directory, File, Platform;

import 'package:async_helper/async_helper.dart' show asyncEnd, asyncStart;
import 'package:testing/testing.dart' show StdioProcess;

final Uri compiler = Uri.base.resolve('pkg/front_end/tool/_fasta/compile.dart');

final Uri transform = Uri.base.resolve('pkg/kernel/bin/transform.dart');
final Uri dump = Uri.base.resolve('pkg/kernel/bin/dump.dart');

final Uri packagesFile = Uri.base.resolve('.packages');

final Uri dartVm = Uri.base.resolve(Platform.resolvedExecutable);

Future main() async {
  asyncStart();
  final Directory tmp = await Directory.systemTemp.createTemp('whole_program');
  final Uri dartFile = tmp.uri.resolve('hello.dart');
  final Uri dillFile = tmp.uri.resolve('hello.dart.dill');
  final Uri constantsDillFile = tmp.uri.resolve('hello.dart.constants.dill');
  final Uri constantsDillTxtFile =
      tmp.uri.resolve('hello.dart.constants.dill.txt');

  // Write the hello world file.
  await new File(dartFile.toFilePath()).writeAsString('''
        // Ensure we import a big program!
        import 'package:compiler/src/dart2js.dart';
        import 'package:front_end/src/fasta/kernel/kernel_target.dart';

        void main() => print('hello world!');
      ''');

  try {
    await runCompiler(dartFile, dillFile);
    await transformDillFile(dillFile, constantsDillFile);
    await dumpDillFile(constantsDillFile, constantsDillTxtFile);
    await runHelloWorld(constantsDillFile);
  } finally {
    await tmp.delete(recursive: true);
  }
  asyncEnd();
}

Future runCompiler(Uri input, Uri output) async {
  final buildDir = Uri.base.resolve(Platform.resolvedExecutable).resolve(".");
  final platformDill = buildDir.resolve("vm_platform.dill").toFilePath();

  final List<String> arguments = <String>[
    '--packages=${packagesFile.toFilePath()}',
    '-c',
    compiler.toFilePath(),
    '--platform=$platformDill',
    '--output=${output.toFilePath()}',
    '--packages=${packagesFile.toFilePath()}',
    '--verify',
    input.toFilePath(),
  ];
  await run('Compilation of hello.dart', arguments);
}

Future transformDillFile(Uri from, Uri to) async {
  final List<String> arguments = <String>[
    transform.toFilePath(),
    '-f',
    'bin',
    '-t',
    'constants',
    '-o',
    to.toFilePath(),
    from.toFilePath(),
  ];
  await run('Transforming $from --to--> $to', arguments);
}

Future dumpDillFile(Uri dillFile, Uri txtFile) async {
  final List<String> arguments = <String>[
    dump.toFilePath(),
    dillFile.toFilePath(),
    txtFile.toFilePath(),
  ];
  await run('Dumping $dillFile --to--> $txtFile', arguments);
}

Future runHelloWorld(Uri dillFile) async {
  final List<String> arguments = <String>['-c', dillFile.toFilePath()];
  await run('Running hello.dart', arguments, 'hello world!\n');
}

Future run(String message, List<String> arguments,
    [String expectedOutput]) async {
  final Stopwatch sw = new Stopwatch()..start();
  print('Running:\n    ${dartVm.toFilePath()} ${arguments.join(' ')}');
  StdioProcess result = await StdioProcess.run(dartVm.toFilePath(), arguments,
      timeout: const Duration(seconds: 120));
  print('Output:\n    ${result.output.replaceAll('\n', '    \n')}');
  print('ExitCode: ${result.exitCode}');
  print('Took:     ${sw.elapsed}\n\n');

  if ((expectedOutput != null && result.output != expectedOutput) ||
      result.exitCode != 0) {
    throw '$message failed.';
  }
}
