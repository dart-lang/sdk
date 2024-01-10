// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:testing/src/run_tests.dart" as run_tests;
import 'package:kernel/src/tool/dump.dart' as dump;
import '../test/utils/io_utils.dart' show computeRepoDir;
import '_fasta/abcompile.dart' as abcompile;
import '_fasta/compile.dart' as compile;
import '_fasta/compile_platform.dart' as compile_platform;
import '_fasta/generate_experimental_flags.dart' as generate_experimental_flags;
import '_fasta/generate_messages.dart' as generate_messages;
import '_fasta/log_analyzer.dart' as log_analyzer;
import '_fasta/log_collector.dart' as log_collector;
import '_fasta/outline.dart' as outline;
import '_fasta/parser.dart' as parser;
import '_fasta/scanner.dart' as scanner;

final String repoDir = computeRepoDir();

final String toolDir = '$repoDir/pkg/front_end/tool/_fasta';

final String kernelBin = '$repoDir/pkg/kernel/bin';

String get dartVm =>
    Platform.isWindows ? '$repoDir/sdk/bin/dart.bat' : '$repoDir/sdk/bin/dart';

Future<void> main(List<String> args) async {
  List<String> extraVmArguments = [];
  String script;
  List<String> scriptArguments = [];

  int index = 0;
  for (; index < args.length; index++) {
    String arg = args[index];
    if (arg.startsWith('-')) {
      extraVmArguments.add(arg);
    } else {
      break;
    }
  }
  if (args.length == index) {
    stop("No command provided.");
  }
  String command = args[index++];
  List<String> remainingArguments = args.skip(index).toList();

  dynamic Function(List<String>) mainFunction;

  switch (command) {
    case 'abcompile':
      mainFunction = abcompile.main;
      script = '${toolDir}/abcompile.dart';
      break;
    case 'compile':
      mainFunction = compile.main;
      script = '${toolDir}/compile.dart';
      break;
    case 'compile-platform':
      mainFunction = compile_platform.main;
      script = '${toolDir}/compile_platform.dart';
      break;
    case 'log':
      mainFunction = log_analyzer.main;
      script = '${toolDir}/log_analyzer.dart';
      break;
    case 'logd':
      mainFunction = log_collector.main;
      script = '${toolDir}/log_collector.dart';
      break;
    case 'outline':
      mainFunction = outline.main;
      script = '${toolDir}/outline.dart';
      break;
    case 'parser':
      mainFunction = parser.main;
      script = '${toolDir}/parser.dart';
      break;
    case 'scanner':
      mainFunction = scanner.main;
      script = '${toolDir}/scanner.dart';
      break;
    case 'dump-ir':
      mainFunction = dump.main;
      script = '${kernelBin}/dump.dart';
      if (remainingArguments.isEmpty || remainingArguments.length > 2) {
        stop("Usage: $command dillFile [output]");
      }
      break;
    case 'testing':
      mainFunction = run_tests.main;
      script = '${repoDir}/pkg/testing/bin/testing.dart';
      scriptArguments.add('--config=${repoDir}/pkg/front_end/testing.json');
      break;
    case 'generate-messages':
      mainFunction = generate_messages.main;
      script = '${toolDir}/generate_messages.dart';
      break;
    case 'generate-experimental-flags':
      mainFunction = generate_experimental_flags.main;
      script = '${toolDir}/generate_experimental_flags.dart';
      break;
    default:
      stop("'$command' isn't a valid subcommand.");
  }

  if (extraVmArguments.isNotEmpty || !assertsEnabled) {
    List<String> arguments = [];
    arguments.addAll(extraVmArguments);
    arguments.add('--enable-asserts');
    arguments.add(script);
    arguments.addAll(remainingArguments);
    arguments.addAll(scriptArguments);

    print('Running: ${dartVm} ${arguments.join(' ')}');
    Process process = await Process.start(dartVm, arguments,
        mode: ProcessStartMode.inheritStdio);
    exitCode = await process.exitCode;
  } else {
    // Run within the same VM if no VM arguments are provided.
    List<String> arguments = [];
    arguments.addAll(remainingArguments);
    arguments.addAll(scriptArguments);

    print('Calling: ${script} ${arguments.join(' ')}');
    await mainFunction(arguments);
  }
}

Never stop(String message) {
  stderr.write(message);
  exit(2);
}

final bool assertsEnabled = () {
  try {
    assert(false);
    return false;
  } catch (_) {
    return true;
  }
}();
