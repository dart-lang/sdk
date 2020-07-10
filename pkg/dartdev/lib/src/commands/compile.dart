// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart2native/generate.dart';
import 'package:path/path.dart' as path;

import '../core.dart';
import '../sdk.dart';

const int compileErrorExitCode = 64;

class Option {
  final String flag;
  final String help;
  final String abbr;

  Option({this.flag, this.help, this.abbr});
}

final Map<String, Option> commonOptions = {
  'outputFile': Option(
    flag: 'output',
    abbr: 'o',
    help: '''
Write the output to <file name>.
This can be an absolute or reletive path.
''',
  ),
};

bool checkFile(String sourcePath) {
  if (!FileSystemEntity.isFileSync(sourcePath)) {
    stderr.writeln(
        '"$sourcePath" is not a file. See \'--help\' for more information.');
    stderr.flush();
    return false;
  }

  return true;
}

class CompileJSCommand extends DartdevCommand<int> {
  CompileJSCommand() : super('js', 'Compile Dart to JavaScript') {
    argParser
      ..addOption(
        commonOptions['outputFile'].flag,
        help: commonOptions['outputFile'].help,
        abbr: commonOptions['outputFile'].abbr,
      )
      ..addFlag(
        'minified',
        help: 'Generate minified output.',
        abbr: 'm',
        negatable: false,
      );
  }

  @override
  String get invocation => '${super.invocation} <dart entry point>';

  @override
  FutureOr<int> run() async {
    // We expect a single rest argument; the dart entry point.
    if (argResults.rest.length != 1) {
      log.stderr('Missing Dart entry point.');
      printUsage();
      return compileErrorExitCode;
    }
    final String sourcePath = argResults.rest[0];
    if (!checkFile(sourcePath)) {
      return -1;
    }

    final process = await startProcess(sdk.dart2js, argResults.arguments);
    routeToStdout(process);
    return process.exitCode;
  }
}

class CompileSnapshotCommand extends DartdevCommand<int> {
  final String commandName;
  final String help;
  final String fileExt;
  final String formatName;

  CompileSnapshotCommand({
    this.commandName,
    this.help,
    this.fileExt,
    this.formatName,
  }) : super(commandName, 'Compile Dart $help') {
    argParser
      ..addOption(
        commonOptions['outputFile'].flag,
        help: commonOptions['outputFile'].help,
        abbr: commonOptions['outputFile'].abbr,
      );
  }

  @override
  String get invocation => '${super.invocation} <dart entry point>';

  @override
  FutureOr<int> run() async {
    // We expect a single rest argument; the dart entry point.
    if (argResults.rest.length != 1) {
      log.stderr('Missing Dart entry point.');
      printUsage();
      return compileErrorExitCode;
    }
    final String sourcePath = argResults.rest[0];
    if (!checkFile(sourcePath)) {
      return -1;
    }

    // Determine output file name.
    String outputFile = argResults[commonOptions['outputFile'].flag];
    if (outputFile == null) {
      final inputWithoutDart = sourcePath.replaceFirst(RegExp(r'\.dart$'), '');
      outputFile = '$inputWithoutDart.$fileExt';
    }

    // Build arguments.
    List<String> args = [];
    args.add('--snapshot-kind=$formatName');
    args.add('--snapshot=${path.canonicalize(outputFile)}');
    if (verbose) {
      args.add('-v');
    }
    args.add(path.canonicalize(sourcePath));

    log.stdout('Compiling $sourcePath to $commandName file $outputFile.');
    final process = await startProcess(sdk.dart, args);
    routeToStdout(process);
    return process.exitCode;
  }
}

class CompileNativeCommand extends DartdevCommand<int> {
  final String commandName;
  final String format;
  final String help;

  CompileNativeCommand({
    this.commandName,
    this.format,
    this.help,
  }) : super(commandName, 'Compile Dart $help') {
    argParser
      ..addOption(
        commonOptions['outputFile'].flag,
        help: commonOptions['outputFile'].help,
        abbr: commonOptions['outputFile'].abbr,
      )
      ..addMultiOption('define', abbr: 'D', valueHelp: 'key=value', help: '''
Set values of environment variables. To specify multiple variables, use multiple options or use commas to separate key-value pairs.
E.g.: dart2native -Da=1,b=2 main.dart''')
      ..addFlag('enable-asserts',
          negatable: false, help: 'Enable assert statements.')
      ..addOption('packages', abbr: 'p', valueHelp: 'path', help: '''
Get package locations from the specified file instead of .packages. <path> can be relative or absolute.
E.g.: dart2native --packages=/tmp/pkgs main.dart
''')
      ..addOption('save-debugging-info', abbr: 'S', valueHelp: 'path', help: '''
Remove debugging information from the output and save it separately to the specified file. <path> can be relative or absolute.
''');
  }

  @override
  String get invocation => '${super.invocation} <dart entry point>';

  @override
  FutureOr<int> run() async {
    // We expect a single rest argument; the dart entry point.
    if (argResults.rest.length != 1) {
      log.stderr('Missing Dart entry point.');
      printUsage();
      return compileErrorExitCode;
    }
    final String sourcePath = argResults.rest[0];
    if (!checkFile(sourcePath)) {
      return -1;
    }

    try {
      await generateNative(
        kind: format,
        sourceFile: sourcePath,
        outputFile: argResults['output'],
        defines: argResults['define'],
        packages: argResults['packages'],
        enableAsserts: argResults['enable-asserts'],
        debugFile: argResults['save-debugging-info'],
        verbose: verbose,
      );
      return 0;
    } catch (e) {
      log.stderr('Error: AOT compilation failed');
      log.stderr(e.toString());
      return compileErrorExitCode;
    }
  }
}

class CompileCommand extends Command {
  @override
  String get description => 'Compile Dart to various formats.';

  @override
  String get name => 'compile';

  CompileCommand() {
    addSubcommand(CompileJSCommand());
    addSubcommand(CompileSnapshotCommand(
      commandName: 'jit-snapshot',
      help: 'to a JIT snapshot',
      fileExt: 'jit',
      formatName: 'app-jit',
    ));
    addSubcommand(CompileNativeCommand(
      commandName: 'exe',
      help: 'to a self-contained executable',
      format: 'exe',
    ));
    addSubcommand(CompileNativeCommand(
      commandName: 'aot-snapshot',
      help: 'to an AOT snapshot',
      format: 'aot',
    ));
  }
}
