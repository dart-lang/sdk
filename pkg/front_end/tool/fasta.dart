// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../test/utils/io_utils.dart' show computeRepoDir;

final String repoDir = computeRepoDir();

final String toolDir = '$repoDir/pkg/front_end/tool/_fasta';

final String kernelBin = '$repoDir/pkg/kernel/bin';

String get dartVm =>
    Platform.isWindows ? '$repoDir/sdk/bin/dart.bat' : '$repoDir/sdk/bin/dart';

main(List<String> args) async {
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

  switch (command) {
    case 'abcompile':
      script = '${toolDir}/abcompile.dart';
      break;
    case 'compile':
      script = '${toolDir}/compile.dart';
      break;
    case 'compile-platform':
      script = '${toolDir}/compile_platform.dart';
      break;
    case 'log':
      script = '${toolDir}/log_analyzer.dart';
      break;
    case 'logd':
      script = '${toolDir}/log_collector.dart';
      break;
    case 'outline':
      script = '${toolDir}/outline.dart';
      break;
    case 'parser':
      script = '${toolDir}/parser.dart';
      break;
    case 'scanner':
      script = '${toolDir}/scanner.dart';
      break;
    case 'dump-ir':
      script = '${kernelBin}/dump.dart';
      if (remainingArguments.isEmpty || remainingArguments.length > 2) {
        stop("Usage: $command dillfile [output]");
      }
      break;
    case 'testing':
      script = '${repoDir}/pkg/testing/bin/testing.dart';
      scriptArguments.add('--config=${repoDir}/pkg/front_end/testing.json');
      break;
    case 'generate-messages':
      script = '${toolDir}/generate_messages.dart';
      break;
    case 'generate-experimental-flags':
      script = '${toolDir}/generate_experimental_flags.dart';
      break;
    default:
      stop("'$command' isn't a valid subcommand.");
  }

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
}

void stop(String message) {
  stderr.write(message);
  exit(2);
}
