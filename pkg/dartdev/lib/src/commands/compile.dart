// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dart2native/generate.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../core.dart';
import '../events.dart';
import '../sdk.dart';
import '../vm_interop_handler.dart';

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
This can be an absolute or relative path.
''',
  ),
};

bool checkFile(String sourcePath) {
  if (!FileSystemEntity.isFileSync(sourcePath)) {
    stderr.writeln('"$sourcePath" file not found.');
    stderr.flush();
    return false;
  }
  return true;
}

class CompileJSCommand extends CompileSubcommandCommand {
  static const String cmdName = 'js';

  CompileJSCommand() : super(cmdName, 'Compile Dart to JavaScript.') {
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
  FutureOr<int> runImpl() async {
    if (!Sdk.checkArtifactExists(sdk.dart2jsSnapshot)) {
      return 255;
    }
    final String librariesPath = path.absolute(
      sdk.sdkPath,
      'lib',
      'libraries.json',
    );

    if (!Sdk.checkArtifactExists(librariesPath)) {
      return 255;
    }

    // We expect a single rest argument; the dart entry point.
    if (argResults.rest.length != 1) {
      // This throws.
      usageException('Missing Dart entry point.');
    }

    final String sourcePath = argResults.rest[0];
    if (!checkFile(sourcePath)) {
      return 1;
    }

    VmInteropHandler.run(sdk.dart2jsSnapshot, [
      '--libraries-spec=$librariesPath',
      ...argResults.arguments,
    ]);

    return 0;
  }
}

class CompileSnapshotCommand extends CompileSubcommandCommand {
  static const String jitSnapshotCmdName = 'jit-snapshot';
  static const String kernelCmdName = 'kernel';

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
  FutureOr<int> runImpl() async {
    // We expect a single rest argument; the dart entry point.
    if (argResults.rest.length != 1) {
      // This throws.
      usageException('Missing Dart entry point.');
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
    // TODO(bkonyi): perform compilation in same process.
    final process = await startDartProcess(sdk, args);
    routeToStdout(process);
    return process.exitCode;
  }
}

class CompileNativeCommand extends CompileSubcommandCommand {
  static const String exeCmdName = 'exe';
  static const String aotSnapshotCmdName = 'aot-snapshot';

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
Define an environment declaration. To specify multiple declarations, use multiple options or use commas to separate key-value pairs.
For example: dart compile $commandName -Da=1,b=2 main.dart''')
      ..addFlag('enable-asserts',
          negatable: false, help: 'Enable assert statements.')
      ..addOption('packages',
          abbr: 'p',
          valueHelp: 'path',
          help:
              '''Get package locations from the specified file instead of .packages.
<path> can be relative or absolute.
For example: dart compile $commandName --packages=/tmp/pkgs main.dart''')
      ..addOption('save-debugging-info', abbr: 'S', valueHelp: 'path', help: '''
Remove debugging information from the output and save it separately to the specified file.
<path> can be relative or absolute.''');
  }

  @override
  String get invocation => '${super.invocation} <dart entry point>';

  @override
  FutureOr<int> runImpl() async {
    if (!Sdk.checkArtifactExists(genKernel) ||
        !Sdk.checkArtifactExists(genSnapshot)) {
      return 255;
    }
    // We expect a single rest argument; the dart entry point.
    if (argResults.rest.length != 1) {
      // This throws.
      usageException('Missing Dart entry point.');
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

abstract class CompileSubcommandCommand extends DartdevCommand {
  CompileSubcommandCommand(String name, String description,
      {bool hidden = false})
      : super(name, description, hidden: hidden);

  @override
  UsageEvent createUsageEvent(int exitCode) => CompileUsageEvent(
        usagePath,
        exitCode: exitCode,
        args: argResults.arguments,
      );
}

class CompileCommand extends DartdevCommand {
  static const String cmdName = 'compile';

  CompileCommand() : super(cmdName, 'Compile Dart to various formats.') {
    addSubcommand(CompileJSCommand());
    addSubcommand(CompileSnapshotCommand(
      commandName: CompileSnapshotCommand.jitSnapshotCmdName,
      help: 'to a JIT snapshot.',
      fileExt: 'jit',
      formatName: 'app-jit',
    ));
    addSubcommand(CompileSnapshotCommand(
      commandName: CompileSnapshotCommand.kernelCmdName,
      help: 'to a kernel snapshot.',
      fileExt: 'dill',
      formatName: 'kernel',
    ));
    addSubcommand(CompileNativeCommand(
      commandName: CompileNativeCommand.exeCmdName,
      help: 'to a self-contained executable.',
      format: 'exe',
    ));
    addSubcommand(CompileNativeCommand(
      commandName: CompileNativeCommand.aotSnapshotCmdName,
      help: 'to an AOT snapshot.',
      format: 'aot',
    ));
  }

  @override
  UsageEvent createUsageEvent(int exitCode) => null;

  @override
  FutureOr<int> runImpl() {
    // do nothing, this command is never run
    return 0;
  }
}

/// The [UsageEvent] for all compile commands, we could have each compile
/// event be its own class instance, but for the time being [usagePath] takes
/// care of the only difference.
class CompileUsageEvent extends UsageEvent {
  CompileUsageEvent(String usagePath,
      {String label, @required int exitCode, @required List<String> args})
      : super(CompileCommand.cmdName, usagePath,
            label: label, exitCode: exitCode, args: args);
}
