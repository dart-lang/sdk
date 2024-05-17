// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:dart2native/generate.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show Verbosity;
import 'package:path/path.dart' as path;
import 'package:vm/target_os.dart'; // For possible --target-os values.

import '../core.dart';
import '../experiments.dart';
import '../native_assets.dart';
import '../sdk.dart';
import '../utils.dart';

const int genericErrorExitCode = 255;
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

/// Checks to see if [destPath] is a file path that can be written to.
bool checkFileWriteable(String destPath) {
  final file = File(destPath);
  final exists = file.existsSync();
  try {
    file.writeAsStringSync(
      '',
      mode: FileMode.append,
      flush: true,
    );
    // Don't leave empty files around.
    if (!exists) {
      file.deleteSync();
    }
    return true;
  } on FileSystemException {
    return false;
  }
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
    if (!Sdk.checkArtifactExists(sdk.dart2jsSnapshot) ||
        !Sdk.checkArtifactExists(sdk.librariesJson)) {
      return 255;
    }

    final args = argResults!;

    // Build arguments.
    final buildArgs = <String>[
      '--libraries-spec=${sdk.librariesJson}',
      '--cfe-invocation-modes=compile',
      '--invoker=dart_cli',
      // Add the remaining arguments.
      if (args.rest.isNotEmpty) ...args.rest.sublist(0),
    ];

    var retval = 0;
    final result = Completer<int>();
    final exitPort = ReceivePort()
      ..listen((msg) {
        result.complete(0);
      });
    final errorPort = ReceivePort()
      ..listen((error) {
        log.stderr(error.toString());
        result.complete(255);
      });
    try {
      await Isolate.spawnUri(Uri.file(sdk.dart2jsSnapshot), buildArgs, null,
          onExit: exitPort.sendPort, onError: errorPort.sendPort);
      retval = await result.future;
    } catch (e, st) {
      log.stderr('Error: JS compilation failed');
      log.stderr(e.toString());
      if (verbose) {
        log.stderr(st.toString());
      }
      retval = compileErrorExitCode;
    }
    errorPort.close();
    exitPort.close();
    return retval;
  }
}

class CompileKernelSnapshotCommand extends CompileSubcommandCommand {
  static const commandName = 'kernel';
  static const help = 'Compile Dart to a kernel snapshot.\n'
      'To run the snapshot use: dart run <kernel file>';

  CompileKernelSnapshotCommand({
    bool verbose = false,
  }) : super(commandName, help, verbose) {
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
      ..addFlag(
        'link-platform',
        help: 'Includes the platform kernel in the resulting kernel file. '
            "Required for use with 'dart compile exe' or 'dart compile aot-snapshot'.",
        defaultsTo: true,
      )
      ..addFlag(
        'embed-sources',
        help: 'Embed source files in the generated kernel component.',
        defaultsTo: true,
      )
      ..addMultiOption(
        defineOption.flag,
        help: defineOption.help,
        abbr: defineOption.abbr,
        valueHelp: defineOption.valueHelp,
      )
      ..addFlag(
        soundNullSafetyOption.flag,
        help: soundNullSafetyOption.help,
        defaultsTo: soundNullSafetyOption.flagDefaultsTo,
        hide: true,
      )
      ..addExperimentalFlags(verbose: verbose);
  }

  @override
  FutureOr<int> run() async {
    final args = argResults!;
    if (args.rest.isEmpty) {
      // This throws.
      usageException('Missing Dart entry point.');
    } else if (args.rest.length > 1) {
      usageException('Unexpected arguments after Dart entry point.');
    }

    final String sourcePath = args.rest[0];
    if (!checkFile(sourcePath)) {
      return genericErrorExitCode;
    }

    // Determine output file name.
    String? outputFile = args.option(outputFileOption.flag);
    if (outputFile == null) {
      final inputWithoutDart = sourcePath.endsWith('.dart')
          ? sourcePath.substring(0, sourcePath.length - 5)
          : sourcePath;
      outputFile = '$inputWithoutDart.dill';
    }

    log.stdout('Compiling $sourcePath to kernel file $outputFile.');

    if (!checkFileWriteable(outputFile)) {
      log.stderr('Unable to open file $outputFile for writing snapshot.');
      return genericErrorExitCode;
    }

    final bool soundNullSafety = args.flag('sound-null-safety');
    if (!soundNullSafety) {
      log.stdout(
          'Error: the flag --no-sound-null-safety is not supported in Dart 3.');
      return compileErrorExitCode;
    }

    try {
      await generateKernel(
        sourceFile: sourcePath,
        outputFile: outputFile,
        defines: args.multiOption('define'),
        packages: args.option('packages'),
        enableExperiment: args.enabledExperiments.join(','),
        linkPlatform: args.flag('link-platform'),
        embedSources: args.flag('embed-sources'),
        verbose: verbose,
        verbosity: args.option('verbosity')!,
      );
      return 0;
    } catch (e, st) {
      log.stderr(e.toString());
      if (verbose) {
        log.stderr(st.toString());
      }
      return compileErrorExitCode;
    }
  }
}

class CompileJitSnapshotCommand extends CompileSubcommandCommand {
  static const help = 'Compile Dart to a JIT snapshot.\n'
      'The executable will be run once to snapshot a warm JIT.\n'
      'To run the snapshot use: dart run <JIT file>';

  CompileJitSnapshotCommand({
    bool verbose = false,
  }) : super('jit-snapshot', help, verbose) {
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
  String get invocation =>
      '${super.invocation} <dart entry point> [<training arguments>]';

  @override
  ArgParser createArgParser() {
    return ArgParser(
      // Don't parse the training arguments for JIT snapshots.
      allowTrailingOptions: false,
      usageLineLength: dartdevUsageLineLength,
    );
  }

  @override
  FutureOr<int> run() async {
    final args = argResults!;
    if (args.rest.isEmpty) {
      // This throws.
      usageException('Missing Dart entry point.');
    }

    final String sourcePath = args.rest[0];
    if (!checkFile(sourcePath)) {
      return genericErrorExitCode;
    }

    // Determine output file name.
    String? outputFile = args.option(outputFileOption.flag);
    if (outputFile == null) {
      final inputWithoutDart = sourcePath.endsWith('.dart')
          ? sourcePath.substring(0, sourcePath.length - 5)
          : sourcePath;
      outputFile = '$inputWithoutDart.jit';
    }

    if (!checkFileWriteable(outputFile)) {
      log.stderr('Unable to open file $outputFile for writing snapshot.');
      return genericErrorExitCode;
    }

    final enabledExperiments = args.enabledExperiments;
    final defines = args.multiOption(defineOption.flag);

    // Build arguments.
    final buildArgs = <String>[];
    buildArgs.add('--snapshot-kind=app-jit');
    buildArgs.add('--snapshot=${path.canonicalize(outputFile)}');

    final bool soundNullSafety = args.flag('sound-null-safety');
    if (!soundNullSafety) {
      log.stdout(
          'Error: the flag --no-sound-null-safety is not supported in Dart 3.');
      return compileErrorExitCode;
    }

    final String? packages = args.option(packagesOption.flag);
    if (packages != null) {
      buildArgs.add('--packages=$packages');
    }

    final String verbosity = args.option(verbosityOption.flag)!;
    buildArgs.add('--verbosity=$verbosity');

    if (enabledExperiments.isNotEmpty) {
      buildArgs.add("--enable-experiment=${enabledExperiments.join(',')}");
    }
    if (verbose) {
      buildArgs.add('-v');
    }
    for (final define in defines) {
      buildArgs.add('-D$define');
    }
    buildArgs.add(path.canonicalize(sourcePath));

    // Add the training arguments.
    if (args.rest.length > 1) {
      buildArgs.addAll(args.rest.sublist(1));
    }

    log.stdout('Compiling $sourcePath to jit-snapshot file $outputFile.');
    // TODO(bkonyi): perform compilation in same process.
    return await runProcess([sdk.dart, ...buildArgs]);
  }
}

class CompileNativeCommand extends CompileSubcommandCommand {
  static const String exeCmdName = 'exe';
  static const String aotSnapshotCmdName = 'aot-snapshot';

  final String commandName;
  final Kind format;
  final String help;
  final bool nativeAssetsExperimentEnabled;

  CompileNativeCommand({
    required this.commandName,
    required this.format,
    required this.help,
    bool verbose = false,
    this.nativeAssetsExperimentEnabled = false,
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
      )
      ..addFlag(
        'enable-asserts',
        negatable: false,
        help: 'Enable assert statements.',
      )
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
    // AOT compilation isn't supported on ia32. Currently, generating an
    // executable only supports AOT runtimes, so these commands are disabled.
    if (Platform.version.contains('ia32')) {
      stderr.write(
          "'dart compile $commandName' is not supported on x86 architectures.\n");
      return 64;
    }
    if (!Sdk.checkArtifactExists(genKernel) ||
        !Sdk.checkArtifactExists(genSnapshot)) {
      return 255;
    }
    final args = argResults!;

    // We expect a single rest argument; the dart entry point.
    if (args.rest.length != 1) {
      // This throws.
      usageException('Missing Dart entry point.');
    }
    final String sourcePath = args.rest[0];
    if (!checkFile(sourcePath)) {
      return genericErrorExitCode;
    }

    if (!args.flag('sound-null-safety')) {
      log.stdout(
          'Error: the flag --no-sound-null-safety is not supported in Dart 3.');
      return compileErrorExitCode;
    }

    if (!nativeAssetsExperimentEnabled) {
      if (await warnOnNativeAssets()) {
        return 255;
      }
    } else {
      final (success, assets) = await compileNativeAssetsJit(verbose: verbose);
      if (!success) {
        stderr.writeln('Native assets build failed.');
        return 255;
      }
      if (assets.isNotEmpty) {
        stderr.writeln(
            "'dart compile' does currently not support native assets.");
        return 255;
      }
    }

    String? targetOS = args.option('target-os');
    if (format != Kind.exe) {
      assert(format == Kind.aot);
      // If we're generating an AOT snapshot and not an executable, then
      // targetOS is allowed to be null for a platform-independent snapshot
      // or a different platform than the host.
    } else if (targetOS == null) {
      targetOS = Platform.operatingSystem;
    } else if (targetOS != Platform.operatingSystem) {
      stderr.writeln(
          "'dart compile $commandName' does not support cross-OS compilation.");
      stderr.writeln('Host OS: ${Platform.operatingSystem}');
      stderr.writeln('Target OS: $targetOS');
      return 128;
    }
    final tempDir = Directory.systemTemp.createTempSync();
    try {
      final kernelGenerator = KernelGenerator(
        kind: format,
        sourceFile: sourcePath,
        outputFile: args.option('output'),
        defines: args.multiOption(defineOption.flag),
        packages: args.option('packages'),
        enableExperiment: args.enabledExperiments.join(','),
        enableAsserts: args.flag('enable-asserts'),
        debugFile: args.option('save-debugging-info'),
        verbose: verbose,
        verbosity: args.option('verbosity')!,
        targetOS: targetOS,
        tempDir: tempDir,
      );
      final snapshotGenerator = await kernelGenerator.generate();
      await snapshotGenerator.generate(
        extraOptions: args.multiOption('extra-gen-snapshot-options'),
      );
      return 0;
    } catch (e, st) {
      log.stderr('Error: AOT compilation failed');
      log.stderr(e.toString());
      if (verbose) {
        log.stderr(st.toString());
      }
      return compileErrorExitCode;
    } finally {
      await tempDir.delete(recursive: true);
    }
  }
}

class CompileWasmCommand extends CompileSubcommandCommand {
  static const String commandName = 'wasm';
  static const String help = 'Compile Dart to a WebAssembly/WasmGC module.';

  // The unique place where we store various flags for dart2wasm & binaryen.
  //
  // Other uses (e.g. pkg/dart2wasm/tool/compile_benchmark) will grep in this
  // file for the flags. So please keep the formatting.

  final List<String> binaryenFlags = _flagList('''
      --all-features
      --closed-world
      --traps-never-happen
      --type-unfinalizing
      -Os
      --type-ssa
      --gufa
      -Os
      --type-merging
      -Os
      --type-finalizing
    '''); // end of binaryenFlags

  final List<String> optimizationLevel0Flags = _flagList('''
      --no-inlining
      --no-minify
    '''); // end of optimizationLevel0Flags

  final List<String> optimizationLevel1Flags = _flagList('''
      --inlining
      --no-minify
    '''); // end of optimizationLevel1Flags

  final List<String> optimizationLevel2Flags = _flagList('''
      --inlining
      --minify
    '''); // end of optimizationLevel2Flags

  final List<String> optimizationLevel3Flags = _flagList('''
      --inlining
      --minify
      --omit-implicit-checks
    '''); // end of optimizationLevel3Flags

  final List<String> optimizationLevel4Flags = _flagList('''
      --inlining
      --minify
      --omit-implicit-checks
      --omit-explicit-checks
      --omit-bounds-checks
    '''); // end of optimizationLevel4Flags

  static List<String> _flagList(String lines) => lines
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  CompileWasmCommand({bool verbose = false})
      : super(commandName, help, verbose, hidden: !verbose) {
    argParser
      ..addOption(
        outputFileOption.flag,
        help: outputFileOption.help,
        abbr: outputFileOption.abbr,
      )
      ..addFlag(
        'minify',
        negatable: true,
        help: 'Minify names that are needed at runtime (such as class names). '
            'Affects e.g. `<obj>.runtimeType.toString()`). If passed, this '
            'takes precedence over the optimization-level option.',
        hide: !verbose,
      )
      ..addFlag(
        'name-section',
        defaultsTo: true,
        negatable: true,
        help: 'Include a name section with printable function names.',
        hide: !verbose,
      )
      ..addFlag(
        'print-wasm',
        help: 'Print human-readable wasm debug output',
        hide: !verbose,
        negatable: false,
      )
      ..addFlag(
        'print-kernel',
        help: 'Print human-readable Dart kernel debug output',
        hide: !verbose,
        negatable: false,
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Print debug output during compilation',
        negatable: false,
      )
      ..addFlag(
        'enable-asserts',
        help: 'Enable assert statements.',
        negatable: false,
      )
      ..addOption(
        'shared-memory',
        help: 'Import a shared memory buffer.'
            ' The max number of pages must be passed.',
        valueHelp: 'page count',
        hide: !verbose,
      )
      ..addMultiOption(
        'extra-compiler-option',
        abbr: 'E',
        help: 'An extra option to pass to the dart2wasm compiler.',
        hide: !verbose,
      )
      ..addOption(
        'optimization-level',
        abbr: 'O',
        help: 'Controls optimizations that can help reduce code-size and '
            'improve performance of the generated code.',
        allowed: ['0', '1', '2', '3', '4'],
        defaultsTo: '1',
        valueHelp: 'level',
        allowedHelp: {
          '0': optimizationLevel0Flags.join(' '),
          '1': optimizationLevel1Flags.join(' '),
          '2': optimizationLevel2Flags.join(' '),
          '3': optimizationLevel3Flags.join(' '),
          '4': optimizationLevel4Flags.join(' '),
        },
        hide: !verbose,
      )
      ..addOption(
        packagesOption.flag,
        abbr: packagesOption.abbr,
        valueHelp: packagesOption.valueHelp,
        help: packagesOption.help,
        hide: !verbose,
      )
      ..addMultiOption(
        defineOption.flag,
        help: defineOption.help,
        abbr: defineOption.abbr,
        valueHelp: defineOption.valueHelp,
      );
  }

  @override
  String get invocation => '${super.invocation} <dart entry point>';

  @override
  FutureOr<int> run() async {
    final args = argResults!;
    final verbose = this.verbose || args.flag('verbose');

    if (!Sdk.checkArtifactExists(sdk.wasmPlatformDill) ||
        !Sdk.checkArtifactExists(sdk.dartAotRuntime) ||
        !Sdk.checkArtifactExists(sdk.dart2wasmSnapshot) ||
        !Sdk.checkArtifactExists(sdk.wasmOpt)) {
      return 255;
    }

    // We expect a single rest argument; the dart entry point.
    if (args.rest.length != 1) {
      // This throws.
      usageException('Missing Dart entry point.');
    }
    final String sourcePath = args.rest[0];
    if (!checkFile(sourcePath)) {
      return genericErrorExitCode;
    }

    // Determine output file name.
    String? outputFile = args.option(outputFileOption.flag);
    if (outputFile == null) {
      final inputWithoutDart = sourcePath.endsWith('.dart')
          ? sourcePath.substring(0, sourcePath.length - 5)
          : sourcePath;
      outputFile = '$inputWithoutDart.wasm';
    }

    if (!outputFile.endsWith('.wasm')) {
      log.stderr(
          'Error: The output file "$outputFile" does not end with ".wasm"');
      return 255;
    }
    final outputFileBasename =
        outputFile.substring(0, outputFile.length - '.wasm'.length);

    final sdkPath = path.absolute(sdk.sdkPath);
    final packages = args.option(packagesOption.flag);
    final defines = args.multiOption(defineOption.flag);
    final extraCompilerOptions = args.multiOption('extra-compiler-option');

    int? maxPages;
    if (args.option('shared-memory') != null) {
      maxPages = int.tryParse(args.option('shared-memory')!);
      if (maxPages == null) {
        usageException(
            'Error: The --shared-memory flag must specify a number!');
      }
    }

    final optimizationLevel = int.parse(args.option('optimization-level')!);
    final runWasmOpt = optimizationLevel >= 1;

    void handleOverride(List<String> flags, String name, bool? value) {
      // If no override provided, default to what -O implies.
      if (value == null) return;

      flags.removeWhere((option) => option == '--no-$name');
      flags.removeWhere((option) => option == '--$name');

      // Explicitly use the the flag value, irrespective of -O settings.
      value ? flags.add('--$name') : flags.add('--no-$name');
    }

    final optimizationFlags = (switch (optimizationLevel) {
      0 => optimizationLevel0Flags,
      1 => optimizationLevel1Flags,
      2 => optimizationLevel2Flags,
      3 => optimizationLevel3Flags,
      4 => optimizationLevel4Flags,
      _ => throw 'unreachable',
    })
        .toList();
    handleOverride(optimizationFlags, 'minify',
        args.wasParsed('minify') ? null : args.flag('minify'));

    final dart2wasmCommand = [
      sdk.dartAotRuntime,
      sdk.dart2wasmSnapshot,
      '--platform=${sdk.wasmPlatformDill}',
      '--dart-sdk=$sdkPath',
      if (verbose) '--verbose',
      if (packages != null) '--packages=$packages',
      if (args.flag('print-wasm')) '--print-wasm',
      if (args.flag('print-kernel')) '--print-kernel',
      if (args.flag('enable-asserts')) '--enable-asserts',
      for (final define in defines) '-D$define',
      if (maxPages != null) ...[
        '--import-shared-memory',
        '--shared-memory-max-pages=$maxPages',
      ],

      // First we pass flags based on the optimization level.
      ...optimizationFlags,

      // Then we pass any extra compiler flags through.
      ...extraCompilerOptions,

      path.absolute(sourcePath),
      outputFile,
    ];
    try {
      final exitCode = await runProcess(dart2wasmCommand);
      if (exitCode != 0) return compileErrorExitCode;
    } catch (e, st) {
      log.stderr('Error: Wasm compilation failed');
      log.stderr(e.toString());
      if (verbose) {
        log.stderr(st.toString());
      }
      return compileErrorExitCode;
    }

    if (runWasmOpt) {
      final unoptFile = '$outputFileBasename.unopt.wasm';
      File(outputFile).renameSync(unoptFile);

      final flags = [
        ...binaryenFlags,
        if (args.flag('name-section')) '-g',
      ];

      if (verbose) {
        log.stdout('Optimizing output with: ${sdk.wasmOpt} $flags');
      }
      final processResult = Process.runSync(
        sdk.wasmOpt,
        [...flags, '-o', outputFile, unoptFile],
      );
      if (processResult.exitCode != 0) {
        log.stderr('Error: Wasm compilation failed while optimizing output');
        log.stderr(processResult.stderr);
        return compileErrorExitCode;
      }
    }

    final mjsFile = '$outputFileBasename.mjs';
    log.stdout(
        "Generated wasm module '$outputFile', and JS init file '$mjsFile'.");
    return 0;
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

  CompileSubcommandCommand(super.name, super.description, super.verbose,
      {super.hidden})
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
For example: dart compile $name --packages=/tmp/pkgs.json main.dart''');
}

class CompileCommand extends DartdevCommand {
  static const String cmdName = 'compile';

  CompileCommand({
    bool verbose = false,
    bool nativeAssetsExperimentEnabled = false,
  }) : super(cmdName, 'Compile Dart to various formats.', verbose) {
    addSubcommand(CompileJSCommand(verbose: verbose));
    addSubcommand(CompileJitSnapshotCommand(verbose: verbose));
    addSubcommand(CompileKernelSnapshotCommand(verbose: verbose));
    addSubcommand(CompileNativeCommand(
      commandName: CompileNativeCommand.exeCmdName,
      help: 'to a self-contained executable.',
      format: Kind.exe,
      verbose: verbose,
      nativeAssetsExperimentEnabled: nativeAssetsExperimentEnabled,
    ));
    addSubcommand(CompileNativeCommand(
      commandName: CompileNativeCommand.aotSnapshotCmdName,
      help: 'to an AOT snapshot.\n'
          'To run the snapshot use: dartaotruntime <AOT snapshot file>',
      format: Kind.aot,
      verbose: verbose,
      nativeAssetsExperimentEnabled: nativeAssetsExperimentEnabled,
    ));
    addSubcommand(CompileWasmCommand(verbose: verbose));
  }
}
