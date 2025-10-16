// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:code_assets/code_assets.dart' show Architecture, OS;
import 'package:dart2native/generate.dart';
import 'package:dartdev/src/unified_analytics.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show Verbosity;
import 'package:hooks_runner/hooks_runner.dart' show Target;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:vm/target_os.dart';

import '../core.dart';
import '../experiments.dart';
import '../native_assets.dart';
import '../sdk.dart';
import '../sdk_cache.dart';
import '../utils.dart';
import '../vm_interop_handler.dart';

const int genericErrorExitCode = 255;
const int compileErrorExitCode = 254;
const int crossCompileErrorExitCode = 128;

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
    if (!checkArtifactExists(sdk.librariesJson, warnIfBuildRoot: true)) {
      return genericErrorExitCode;
    }
    final args = argResults!;
    var snapshot = sdk.dart2jsAotSnapshot;
    if (!checkArtifactExists(snapshot, logError: false)) {
      log.stderr('Error: JS compilation failed');
      log.stderr('Unable to find $snapshot');
      return compileErrorExitCode;
    }
    final dart2jsCommand = [
      '--libraries-spec=${sdk.librariesJson}',
      '--cfe-invocation-modes=compile',
      '--invoker=dart_cli',
      // Add the remaining arguments.
      if (args.rest.isNotEmpty) ...args.rest.sublist(0),
    ];
    try {
      VmInteropHandler.run(
        snapshot,
        dart2jsCommand,
        packageConfigOverride: null,
        useExecProcess: false,
      );
      return 0;
    } catch (e, st) {
      log.stderr('Error: JS compilation failed');
      log.stderr(e.toString());
      if (verbose) {
        log.stderr(st.toString());
      }
      return compileErrorExitCode;
    }
  }
}

class CompileDDCCommand extends CompileSubcommandCommand {
  static const String cmdName = 'js-dev';

  /// Accept all flags so we can delegate arg parsing to ddc internally.
  @override
  final ArgParser argParser = ArgParser.allowAnything();

  // This command is an internal developer command used by tools and is
  // hidden in the help message.
  CompileDDCCommand({bool verbose = false})
      : super(
          cmdName,
          'Compile Dart to JavaScript using ddc.',
          verbose,
          hidden: true,
        );

  @override
  String get invocation => '${super.invocation} <dart entry point>';

  @override
  FutureOr<int> run() async {
    if (!checkArtifactExists(sdk.librariesJson, warnIfBuildRoot: true)) {
      return genericErrorExitCode;
    }
    final args = argResults!;
    var snapshot = sdk.ddcAotSnapshot;
    if (!checkArtifactExists(snapshot, logError: false)) {
      log.stderr('Error: JS compilation failed');
      log.stderr('Unable to find $snapshot');
      return compileErrorExitCode;
    }
    final ddcCommand = <String>[
      // Add the remaining arguments.
      if (args.rest.isNotEmpty) ...args.rest.sublist(0),
    ];
    try {
      VmInteropHandler.run(
        snapshot,
        ddcCommand,
        packageConfigOverride: null,
        useExecProcess: false,
      );
      return 0;
    } catch (e, st) {
      log.stderr('Error: JS compilation failed');
      log.stderr(e.toString());
      if (verbose) {
        log.stderr(st.toString());
      }
      return compileErrorExitCode;
    }
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
      ..addOption(
        'depfile',
        valueHelp: 'path',
        help: 'Path to output Ninja depfile',
      )
      ..addMultiOption(
        'extra-gen-kernel-options',
        help: 'Pass additional options to gen_kernel.',
        hide: true,
        valueHelp: 'opt1,opt2,...',
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
        depFile: args.option('depfile'),
        extraOptions: args.multiOption('extra-gen-kernel-options'),
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
      ..addFlag(
        enableAssertsOption.flag,
        negatable: false,
        help: enableAssertsOption.help,
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
    final enableAsserts = args.flag(enableAssertsOption.flag);

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

    if (enableAsserts) {
      buildArgs.add('--${enableAssertsOption.flag}');
    }

    buildArgs.add(path.canonicalize(sourcePath));

    // Add the training arguments.
    if (args.rest.length > 1) {
      buildArgs.addAll(args.rest.sublist(1));
    }

    log.stdout('Compiling $sourcePath to jit-snapshot file $outputFile.');
    // TODO(bkonyi): perform compilation in same process.
    return await runProcess([sdk.dartvm, ...buildArgs]);
  }
}

class CompileNativeCommand extends CompileSubcommandCommand {
  static const String exeCmdName = 'exe';
  static const String aotSnapshotCmdName = 'aot-snapshot';
  static final supportedTargetPlatforms = <Target>{
    Target.linuxArm,
    Target.linuxArm64,
    Target.linuxRiscv64,
    Target.linuxX64
  };

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
        enableAssertsOption.flag,
        negatable: false,
        help: enableAssertsOption.help,
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
      ..addOption(
        'save-debugging-info',
        abbr: 'S',
        valueHelp: 'path',
        help: '''
Remove debugging information from the output and save it separately to the specified file.
<path> can be relative or absolute.''',
      )
      ..addOption(
        'depfile',
        valueHelp: 'path',
        help: 'Path to output Ninja depfile',
      )
      ..addMultiOption(
        'extra-gen-snapshot-options',
        help: 'Pass additional options to gen_snapshot.',
        hide: true,
        valueHelp: 'opt1,opt2,...',
      )
      ..addMultiOption(
        'extra-gen-kernel-options',
        help: 'Pass additional options to gen_kernel.',
        hide: true,
        valueHelp: 'opt1,opt2,...',
      )
      ..addOption('target-os',
          help: 'Compile to a specific target operating system.',
          allowed: TargetOS.names)
      ..addOption('target-arch',
          help: 'Compile to a specific target architecture.',
          allowed: Architecture.values.map((v) => v.name).toList())
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
    // Kernel is always generated using the host's dartaotruntime and
    // gen_kernel_aot.dart.snapshot, even during cross compilation.
    if (!checkArtifactExists(sdk.genKernelSnapshot) ||
        !checkArtifactExists(sdk.dartAotRuntime)) {
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

    var genSnapshotBinary = sdk.genSnapshot;
    var dartAotRuntimeBinary = sdk.dartAotRuntime;

    final target = crossCompilationTarget(args);

    if (target != null) {
      if (!supportedTargetPlatforms.contains(target)) {
        stderr.writeln('Unsupported target platform $target.');
        stderr.writeln('Supported target platforms: '
            '${supportedTargetPlatforms.join(', ')}');
        return crossCompileErrorExitCode;
      }

      var cacheDir = getDartStorageDirectory();
      if (cacheDir != null) {
        cacheDir = Directory(path.join(cacheDir.path, 'dartdev', 'sdk_cache'));
      } else {
        cacheDir = Directory.systemTemp.createTempSync();
        log.stdout('Cannot get dart storage directory. '
            'Using temp dir ${cacheDir.path}');
      }
      final httpClient = http.Client();
      try {
        final cache = SdkCache(
            directory: cacheDir.path, verbose: verbose, httpClient: httpClient);
        final archiveFolder = await cache.resolveVersion(
            version: Runtime.runtime.version,
            revision: sdk.revision ?? '',
            channelName: Runtime.runtime.channel ?? 'unknown');
        genSnapshotBinary = await cache.ensureGenSnapshot(
            archiveFolder: archiveFolder, target: target);
        dartAotRuntimeBinary = await cache.ensureDartAotRuntime(
            archiveFolder: archiveFolder, target: target);
      } finally {
        httpClient.close();
      }
    }

    final packageConfigUri = await DartNativeAssetsBuilder.ensurePackageConfig(
      Directory.current.uri,
    );
    if (packageConfigUri != null) {
      final packageConfig =
          await DartNativeAssetsBuilder.loadPackageConfig(packageConfigUri);
      if (packageConfig == null) {
        return compileErrorExitCode;
      }
      final runPackageName = await DartNativeAssetsBuilder.findRootPackageName(
        Directory.current.uri,
      );
      if (runPackageName != null) {
        final pubspecUri = await DartNativeAssetsBuilder.findWorkspacePubspec(
            packageConfigUri);
        final builder = DartNativeAssetsBuilder(
            pubspecUri: pubspecUri,
            packageConfigUri: packageConfigUri,
            packageConfig: packageConfig,
            runPackageName: runPackageName,
            includeDevDependencies: false,
            dataAssetsExperimentEnabled: false,
            verbose: verbose,
            target: target);
        if (!nativeAssetsExperimentEnabled) {
          if (await builder.warnOnNativeAssets()) {
            return 255;
          }
        } else if (await builder.hasHooks()) {
          stderr.writeln(
              "'dart compile' does not support build hooks, use 'dart build' instead.");
          return 255;
        }
      }
    }

    final tempDir = Directory.systemTemp.createTempSync();
    try {
      final kernelGenerator = KernelGenerator(
        genSnapshot: genSnapshotBinary,
        targetDartAotRuntime: dartAotRuntimeBinary,
        kind: format,
        sourceFile: sourcePath,
        outputFile: args.option('output'),
        defines: args.multiOption(defineOption.flag),
        packages: args.option('packages'),
        enableExperiment: args.enabledExperiments.join(','),
        enableAsserts: args.flag(enableAssertsOption.flag),
        debugFile: args.option('save-debugging-info'),
        verbose: verbose,
        verbosity: args.option('verbosity')!,
        targetOS: target?.os ?? OS.current,
        tempDir: tempDir,
        depFile: args.option('depfile'),
      );
      final snapshotGenerator = await kernelGenerator.generate(
        extraOptions: args.multiOption('extra-gen-kernel-options'),
      );
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

  /// Returns target platform for cross compilation.
  ///
  /// If cross compilation is not needed, returns null.
  Target? crossCompilationTarget(ArgResults args) {
    final String? targetOS = args.option('target-os');
    final String? targetArch = args.option('target-arch');

    if (targetOS == null && targetArch == null) {
      return null;
    }

    // If one of the target options is explicitly specified,
    // resolving full host and target platforms to check for
    // cross compilation.
    final host = Target.current;
    final target = Target.fromArchitectureAndOS(
      targetArch == null
          ? host.architecture
          : Architecture.fromString(targetArch),
      targetOS == null ? host.os : OS.fromString(targetOS),
    );

    // Platforms match, no need to cross compile.
    if (host == target) {
      return null;
    }
    return target;
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
      --enable-gc
      --enable-reference-types
      --enable-multivalue
      --enable-exception-handling
      --enable-nontrapping-float-to-int
      --enable-sign-ext
      --enable-bulk-memory
      --enable-threads

      --no-inline=*<noInline>*

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
      --minimize-rec-groups
    '''); // end of binaryenFlags

  final List<String> binaryenFlagsDeferredLoading = _flagList('''
      --enable-gc
      --enable-reference-types
      --enable-multivalue
      --enable-exception-handling
      --enable-nontrapping-float-to-int
      --enable-sign-ext
      --enable-bulk-memory
      --enable-threads

      --no-inline=*<noInline>*

      -Os
    '''); // end of binaryenFlagsDeferredLoading

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
      --omit-bounds-checks
    '''); // end of optimizationLevel4Flags

  static List<String> _flagList(String lines) => lines
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  CompileWasmCommand({bool verbose = false})
      : super(commandName, help, verbose) {
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
        'strip-wasm',
        defaultsTo: true,
        negatable: true,
        help:
            'Whether to strip the resulting wasm file of static symbol names.',
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
        enableAssertsOption.flag,
        negatable: false,
        help: enableAssertsOption.help,
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
        splitCommas: false,
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
      ..addFlag(
        'source-maps',
        help: 'Generate a source map file.',
        defaultsTo: true,
      )
      ..addFlag('enable-deferred-loading',
          help: 'Emit multiple modules based on the Dart program\'s deferred '
              'import graph.',
          hide: !verbose,
          defaultsTo: false)
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
        splitCommas: false,
      )
      ..addExperimentalFlags(verbose: verbose);
  }

  @override
  String get invocation => '${super.invocation} <dart entry point>';

  @override
  FutureOr<int> run() async {
    final args = argResults!;
    final verbose = this.verbose || args.flag('verbose');

    if (!checkArtifactExists(sdk.wasmPlatformDill, warnIfBuildRoot: true) ||
        !checkArtifactExists(sdk.dartAotRuntime) ||
        !checkArtifactExists(sdk.dart2wasmSnapshot)) {
      return 255;
    }

    // We expect a single rest argument; the dart entry point.
    if (args.rest.length != 1) {
      // This throws.
      usageException('Missing Dart entry point.');
    }
    final String sourcePath = args.rest[0];
    final extraCompilerOptions = args.multiOption('extra-compiler-option');
    final isMultiRoot =
        extraCompilerOptions.any((e) => e.contains('multi-root'));

    // If we know the source file doesn't exist, we want to abort early with an
    // obvious error message. We can't resolve the actual path here if the input
    // is an URI, so we skip that check in that case.
    final sourceIsPath =
        !isMultiRoot || Uri.tryParse(sourcePath)?.hasScheme == false;
    if (sourceIsPath && !checkFile(sourcePath)) {
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

    final packages = args.option(packagesOption.flag);
    final defines = args.multiOption(defineOption.flag);

    int? maxPages;
    if (args.option('shared-memory') != null) {
      maxPages = int.tryParse(args.option('shared-memory')!);
      if (maxPages == null) {
        usageException(
            'Error: The --shared-memory flag must specify a number!');
      }
    }

    final isMultiModule = args.flag('enable-deferred-loading') ||
        // Used in testing to force multiple modules.
        extraCompilerOptions
            .any((e) => e.contains('enable-multi-module-stress-test'));
    final optimizationLevel = int.parse(args.option('optimization-level')!);
    final runWasmOpt = optimizationLevel >= 1;

    if (runWasmOpt && !checkArtifactExists(sdk.wasmOpt)) {
      return 255;
    }

    void handleOverride(List<String> flags, String name, bool? value) {
      // If no override provided, default to what -O implies.
      if (value == null) return;

      flags.removeWhere((option) => option == '--no-$name');
      flags.removeWhere((option) => option == '--$name');

      // Explicitly use the flag value, irrespective of -O settings.
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
        args.wasParsed('minify') ? args.flag('minify') : null);

    final generateSourceMap = args.flag('source-maps');
    final enabledExperiments = args.enabledExperiments;
    final dart2wasmCommand = [
      sdk.dartAotRuntime,
      sdk.dart2wasmSnapshot,
      '--platform=${sdk.wasmPlatformDill}',
      if (verbose) '--verbose',
      if (packages != null) '--packages=$packages',
      if (args.flag('print-wasm')) '--print-wasm',
      if (args.flag('print-kernel')) '--print-kernel',
      if (args.flag(enableAssertsOption.flag)) '--${enableAssertsOption.flag}',
      if (!generateSourceMap) '--no-source-maps',
      if (isMultiModule) '--enable-deferred-loading',
      for (final define in defines) '-D$define',
      if (maxPages != null) ...[
        '--import-shared-memory',
        '--shared-memory-max-pages=$maxPages',
      ],
      ...enabledExperiments.map((e) => '--enable-experiment=$e'),

      // First we pass flags based on the optimization level.
      ...optimizationFlags,

      // Then we pass any extra compiler flags through.
      ...extraCompilerOptions,

      sourcePath,
      outputFile,
    ];
    try {
      final exitCode = await runProcess(dart2wasmCommand);
      if (exitCode != 0) return exitCode;
    } catch (e, st) {
      log.stderr('Error: Wasm compilation failed');
      log.stderr(e.toString());
      if (verbose) {
        log.stderr(st.toString());
      }
      return compileErrorExitCode;
    }

    final bool strip = args.flag('strip-wasm');

    // When running in dry run mode there will not be any file emitted.
    final isDryRun = extraCompilerOptions.any((e) => e.contains('dry-run'));

    if (isDryRun) return 0;

    if (runWasmOpt) {
      if (isMultiModule) {
        // Iterate over all matching wasm files and optimize them concurrently
        // in different processes.
        final outputFiles = await _listMultiWasmModules(
            path.dirname(outputFile), outputFileBasename);
        final futures = <Future<int>>[];
        for (final f in outputFiles) {
          final baseFileName = path.setExtension(f.path, '');
          futures.add(optimize(baseFileName, f.path,
              deferredLoadingEnabled: true,
              generateSourceMap: generateSourceMap,
              strip: strip));
        }
        final exitCode = (await Future.wait(futures))
            .firstWhere((r) => r != 0, orElse: () => 0);
        if (exitCode != 0) return exitCode;
      } else {
        final exitCode = await optimize(outputFileBasename, outputFile,
            deferredLoadingEnabled: false,
            generateSourceMap: generateSourceMap,
            strip: strip);
        if (exitCode != 0) return exitCode;
      }
    }

    final mjsFile = '$outputFileBasename.mjs';
    log.stdout(
        "Generated wasm module '$outputFile', and JS init file '$mjsFile'.");
    return 0;
  }

  Future<List<File>> _listMultiWasmModules(
      String outputDir, String outputFileBasename) async {
    final files = <File>[];
    final outputFiles = await Directory(outputDir).list().toList();
    // When multiple modules are produced from wasm (e.g. with deferred
    // loading), the compiler emits files:
    // - basename.wasm (main module)
    // - basename_module{1...N}.wasm (extra modules)
    for (final f in outputFiles) {
      if (f is! File) continue;
      if (!path.split(f.path).last.startsWith(outputFileBasename)) continue;
      if (path.extension(f.path) != '.wasm') continue;

      files.add(f);
    }
    return files;
  }

  Future<int> optimize(String outputFileBasename, String outputFile,
      {required bool deferredLoadingEnabled,
      required bool generateSourceMap,
      required bool strip}) async {
    final unoptFile = '$outputFileBasename.unopt.wasm';
    File(outputFile).renameSync(unoptFile);

    final unoptSourceMapFile = '$outputFileBasename.unopt.wasm.map';
    if (generateSourceMap) {
      File('$outputFile.map').renameSync(unoptSourceMapFile);
    }

    final flags = [
      ...(deferredLoadingEnabled
          ? binaryenFlagsDeferredLoading
          : binaryenFlags),
      if (!strip) '-g',
      if (generateSourceMap) ...[
        '-ism',
        unoptSourceMapFile,
        '-osm',
        '$outputFile.map'
      ]
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

  late final Option defineOption = Option(
    flag: 'define',
    abbr: 'D',
    valueHelp: 'key=value',
    help: '''
Define an environment declaration. To specify multiple declarations, use multiple options or use commas to separate key-value pairs.
For example: dart compile $name -Da=1,b=2 main.dart''',
  );

  late final Option packagesOption = Option(
      flag: 'packages',
      abbr: 'p',
      valueHelp: 'path',
      help:
          '''Get package locations from the specified file instead of .dart_tool/package_config.json.
<path> can be relative or absolute.
For example: dart compile $name --packages=/tmp/pkgs.json main.dart''');

  final Option enableAssertsOption =
      Option(flag: 'enable-asserts', help: 'Enable assert statements.');

  CompileSubcommandCommand(super.name, super.description, super.verbose,
      {super.hidden});
}

class CompileCommand extends DartdevCommand {
  static const String cmdName = 'compile';

  CompileCommand({
    bool verbose = false,
    bool nativeAssetsExperimentEnabled = false,
  }) : super(cmdName, 'Compile Dart to various formats.', verbose) {
    addSubcommand(CompileJSCommand(verbose: verbose));
    addSubcommand(CompileDDCCommand(verbose: verbose));
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

  @override
  CommandCategory get commandCategory => CommandCategory.project;
}
