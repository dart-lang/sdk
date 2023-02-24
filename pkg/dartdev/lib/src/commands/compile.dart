// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart2native/generate.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show Verbosity;
import 'package:path/path.dart' as path;
import 'package:vm/target_os.dart'; // For possible --target-os values.

import '../core.dart';
import '../experiments.dart';
import '../sdk.dart';
import '../utils.dart';
import '../vm_interop_handler.dart';

const int compileErrorExitCode = 64;

class Option {
  final String flag;
  final String help;
  final String? abbr;
  final String? defaultsTo;
  final bool? flagDefaultsTo;
  final String? valueHelp;
  final List<String>? allowed;
  final Map<String, String>? allowedHelp;

  const Option({
    required this.flag,
    required this.help,
    this.abbr,
    this.defaultsTo,
    this.flagDefaultsTo,
    this.valueHelp,
    this.allowed,
    this.allowedHelp,
  });
}

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

  /// Accept all flags so we can delegate arg parsing to dart2js internally.
  @override
  final ArgParser argParser = ArgParser.allowAnything();

  CompileJSCommand({bool verbose = false})
      : super(cmdName, 'Compile Dart to JavaScript.', verbose);

  @override
  String get invocation => '${super.invocation} <dart entry point>';

  @override
  FutureOr<int> run() async {
    if (!Sdk.checkArtifactExists(sdk.dart2jsSnapshot)) return 255;

    final librariesPath = path.absolute(sdk.sdkPath, 'lib', 'libraries.json');

    if (!Sdk.checkArtifactExists(librariesPath)) return 255;

    VmInteropHandler.run(
      sdk.dart2jsSnapshot,
      [
        '--libraries-spec=$librariesPath',
        '--cfe-invocation-modes=compile',
        '--invoker=dart_cli',
        ...argResults!.arguments,
      ],
      packageConfigOverride: null,
    );

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
    required this.commandName,
    required this.help,
    required this.fileExt,
    required this.formatName,
    bool verbose = false,
  }) : super(commandName, 'Compile Dart $help', verbose) {
    argParser
      ..addOption(
        outputFileOption.flag,
        help: outputFileOption.help,
        abbr: outputFileOption.abbr,
      )
      ..addOption(
        verbosityOption.flag,
        help: verbosityOption.help,
        abbr: verbosityOption.abbr,
        defaultsTo: verbosityOption.defaultsTo,
        allowed: verbosityOption.allowed,
        allowedHelp: verbosityOption.allowedHelp,
      )
      ..addOption(
        packagesOption.flag,
        abbr: packagesOption.abbr,
        valueHelp: packagesOption.valueHelp,
        help: packagesOption.help,
      )
      ..addMultiOption(
        defineOption.flag,
        help: defineOption.help,
        abbr: defineOption.abbr,
        valueHelp: defineOption.valueHelp,
      )
      ..addFlag(soundNullSafetyOption.flag,
          help: soundNullSafetyOption.help,
          defaultsTo: soundNullSafetyOption.flagDefaultsTo,
          hide: true)
      ..addExperimentalFlags(verbose: verbose);
  }

  @override
  String get invocation {
    String msg = '${super.invocation} <dart entry point>';
    if (isJitSnapshot) {
      msg += ' [<training arguments>]';
    }
    return msg;
  }

  @override
  ArgParser createArgParser() {
    return ArgParser(
      // Don't parse the training arguments for JIT snapshots, but don't accept
      // flags after the script name for kernel snapshots.
      allowTrailingOptions: !isJitSnapshot,
      usageLineLength: dartdevUsageLineLength,
    );
  }

  bool get isJitSnapshot => commandName == jitSnapshotCmdName;

  @override
  FutureOr<int> run() async {
    final args = argResults!;
    if (args.rest.isEmpty) {
      // This throws.
      usageException('Missing Dart entry point.');
    } else if (!isJitSnapshot && args.rest.length > 1) {
      usageException('Unexpected arguments after Dart entry point.');
    }

    final String sourcePath = args.rest[0];
    if (!checkFile(sourcePath)) {
      return -1;
    }

    // Determine output file name.
    String? outputFile = args[outputFileOption.flag];
    if (outputFile == null) {
      final inputWithoutDart = sourcePath.endsWith('.dart')
          ? sourcePath.substring(0, sourcePath.length - 5)
          : sourcePath;
      outputFile = '$inputWithoutDart.$fileExt';
    }

    final enabledExperiments = args.enabledExperiments;
    final environmentVars = args['define'] ?? <String, String>{};

    // Build arguments.
    final buildArgs = <String>[];
    buildArgs.add('--snapshot-kind=$formatName');
    buildArgs.add('--snapshot=${path.canonicalize(outputFile)}');

    final bool soundNullSafety = args['sound-null-safety'];
    if (!soundNullSafety) {
      if (!shouldAllowNoSoundNullSafety()) {
        return compileErrorExitCode;
      }
      buildArgs.add('--no-sound-null-safety');
    }

    final String? packages = args[packagesOption.flag];
    if (packages != null) {
      buildArgs.add('--packages=$packages');
    }

    final String? verbosity = args[verbosityOption.flag];
    buildArgs.add('--verbosity=$verbosity');

    if (enabledExperiments.isNotEmpty) {
      buildArgs.add("--enable-experiment=${enabledExperiments.join(',')}");
    }
    if (verbose) {
      buildArgs.add('-v');
    }
    if (environmentVars.isNotEmpty) {
      buildArgs.addAll(environmentVars.map<String>((e) => '--define=$e'));
    }
    buildArgs.add(path.canonicalize(sourcePath));

    // Add the training arguments.
    if (args.rest.length > 1) {
      buildArgs.addAll(args.rest.sublist(1));
    }

    log.stdout('Compiling $sourcePath to $commandName file $outputFile.');
    // TODO(bkonyi): perform compilation in same process.
    final process = await startDartProcess(sdk, buildArgs);
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
    required this.commandName,
    required this.format,
    required this.help,
    bool verbose = false,
  }) : super(commandName, 'Compile Dart $help', verbose) {
    argParser
      ..addOption(
        outputFileOption.flag,
        help: outputFileOption.help,
        abbr: outputFileOption.abbr,
      )
      ..addOption(
        verbosityOption.flag,
        help: verbosityOption.help,
        abbr: verbosityOption.abbr,
        defaultsTo: verbosityOption.defaultsTo,
        allowed: verbosityOption.allowed,
        allowedHelp: verbosityOption.allowedHelp,
      )
      ..addMultiOption(
        defineOption.flag,
        help: defineOption.help,
        abbr: defineOption.abbr,
        valueHelp: defineOption.valueHelp,
      );
    if (commandName != exeCmdName) {
      // dart compile exe creates a product mode binary, which doesn't support asserts.
      argParser.addFlag('enable-asserts',
          negatable: false, help: 'Enable assert statements.');
    }
    argParser
      ..addOption(
        packagesOption.flag,
        abbr: packagesOption.abbr,
        valueHelp: packagesOption.valueHelp,
        help: packagesOption.help,
      )
      ..addFlag(soundNullSafetyOption.flag,
          help: soundNullSafetyOption.help,
          defaultsTo: soundNullSafetyOption.flagDefaultsTo,
          hide: true)
      ..addOption('save-debugging-info', abbr: 'S', valueHelp: 'path', help: '''
Remove debugging information from the output and save it separately to the specified file.
<path> can be relative or absolute.''')
      ..addMultiOption(
        'extra-gen-snapshot-options',
        help: 'Pass additional options to gen_snapshot.',
        hide: true,
        valueHelp: 'opt1,opt2,...',
      )
      ..addOption('target-os',
          help: 'Compile to a specific target operating system.',
          allowed: TargetOS.names)
      ..addExperimentalFlags(verbose: verbose);
  }

  @override
  String get invocation => '${super.invocation} <dart entry point>';

  @override
  FutureOr<int> run() async {
    if (!Sdk.checkArtifactExists(genKernel) ||
        !Sdk.checkArtifactExists(genSnapshot)) {
      return 255;
    }
    // AOT compilation isn't supported on ia32. Currently, generating an
    // executable only supports AOT runtimes, so these commands are disabled.
    if (Platform.version.contains('ia32')) {
      stderr.write(
          "'dart compile $format' is not supported on x86 architectures");
      return 64;
    }
    final args = argResults!;

    // We expect a single rest argument; the dart entry point.
    if (args.rest.length != 1) {
      // This throws.
      usageException('Missing Dart entry point.');
    }
    final String sourcePath = args.rest[0];
    if (!checkFile(sourcePath)) {
      return -1;
    }

    if (!args['sound-null-safety'] && !shouldAllowNoSoundNullSafety()) {
      return compileErrorExitCode;
    }

    try {
      await generateNative(
        kind: format,
        sourceFile: sourcePath,
        outputFile: args['output'],
        defines: args['define'],
        packages: args['packages'],
        enableAsserts:
            commandName != exeCmdName ? args['enable-asserts'] : false,
        enableExperiment: args.enabledExperiments.join(','),
        soundNullSafety: args['sound-null-safety'],
        debugFile: args['save-debugging-info'],
        verbose: verbose,
        verbosity: args['verbosity'],
        extraOptions: args['extra-gen-snapshot-options'],
        targetOS: args['target-os'],
      );
      return 0;
    } catch (e, st) {
      log.stderr('Error: AOT compilation failed');
      log.stderr(e.toString());
      if (verbose) {
        log.stderr(st.toString());
      }
      return compileErrorExitCode;
    }
  }
}

abstract class CompileSubcommandCommand extends DartdevCommand {
  final outputFileOption = Option(
    flag: 'output',
    abbr: 'o',
    help: '''
Write the output to <file name>.
This can be an absolute or relative path.
''',
  );
  final verbosityOption = Option(
    flag: 'verbosity',
    help: '''
Sets the verbosity level of the compilation.
''',
    defaultsTo: Verbosity.defaultValue,
    allowed: Verbosity.allowedValues,
    allowedHelp: Verbosity.allowedValuesHelp,
  );
  final soundNullSafetyOption = Option(
    flag: 'sound-null-safety',
    help: 'DEPRECATED: Respect the nullability of types at runtime.',
    flagDefaultsTo: true,
  );

  late final Option defineOption;
  late final Option packagesOption;

  CompileSubcommandCommand(String name, String description, bool verbose,
      {bool hidden = false})
      : defineOption = Option(
          flag: 'define',
          abbr: 'D',
          valueHelp: 'key=value',
          help: '''
Define an environment declaration. To specify multiple declarations, use multiple options or use commas to separate key-value pairs.
For example: dart compile $name -Da=1,b=2 main.dart''',
        ),
        packagesOption = Option(
            flag: 'packages',
            abbr: 'p',
            valueHelp: 'path',
            help:
                '''Get package locations from the specified file instead of .dart_tool/package_config.json.
<path> can be relative or absolute.
For example: dart compile $name --packages=/tmp/pkgs.json main.dart'''),
        super(name, description, verbose, hidden: hidden);

  bool shouldAllowNoSoundNullSafety() {
    // We need to maintain support for generating AOT snapshots and kernel
    // files with no-sound-null-safety internal Flutter aplications are
    // fully null-safe.
    //
    // See https://github.com/dart-lang/sdk/issues/51513 for context.
    if (name == CompileNativeCommand.aotSnapshotCmdName ||
        name == CompileSnapshotCommand.kernelCmdName) {
      log.stdout(
          'Warning: the flag --no-sound-null-safety is deprecated and pending removal.');
      return true;
    }
    log.stdout(
        'Error: the flag --no-sound-null-safety is not supported in Dart 3.');
    return false;
  }
}

class CompileCommand extends DartdevCommand {
  static const String cmdName = 'compile';
  CompileCommand({bool verbose = false})
      : super(cmdName, 'Compile Dart to various formats.', verbose) {
    addSubcommand(CompileJSCommand(verbose: verbose));
    addSubcommand(CompileSnapshotCommand(
      commandName: CompileSnapshotCommand.jitSnapshotCmdName,
      help: 'to a JIT snapshot.\n'
          'To run the snapshot use: dart run <JIT file>',
      fileExt: 'jit',
      formatName: 'app-jit',
      verbose: verbose,
    ));
    addSubcommand(CompileSnapshotCommand(
      commandName: CompileSnapshotCommand.kernelCmdName,
      help: 'to a kernel snapshot.\n'
          'To run the snapshot use: dart run <kernel file>',
      fileExt: 'dill',
      formatName: 'kernel',
      verbose: verbose,
    ));
    addSubcommand(CompileNativeCommand(
      commandName: CompileNativeCommand.exeCmdName,
      help: 'to a self-contained executable.',
      format: 'exe',
      verbose: verbose,
    ));
    addSubcommand(CompileNativeCommand(
      commandName: CompileNativeCommand.aotSnapshotCmdName,
      help: 'to an AOT snapshot.\n'
          'To run the snapshot use: dartaotruntime <AOT snapshot file>',
      format: 'aot',
      verbose: verbose,
    ));
  }
}
