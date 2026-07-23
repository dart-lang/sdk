// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:code_assets/code_assets.dart' hide Sanitizer;
import 'package:dart2native/dart2native.dart' show markExecutable;
import 'package:dart2native/generate.dart';
import 'package:dartdev/src/commands/compile.dart';
import 'package:dartdev/src/experiments.dart';
import 'package:dartdev/src/native_assets_bundling.dart';
import 'package:dartdev/src/native_assets_macos.dart';
import 'package:dartdev/src/progress.dart';
import 'package:dartdev/src/sdk.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show Verbosity;
import 'package:hooks_runner/hooks_runner.dart';
import 'package:path/path.dart' as path;
import 'package:vm/target_os.dart';

import '../core.dart';
import '../native_assets.dart';

class BuildCommand extends DartdevCommand {
  static const String cmdName = 'build';
  static const String outputOptionName = 'output';
  static const String formatOptionName = 'format';
  static const int genericErrorExitCode = 255;
  final bool recordUseEnabled;
  final bool dataAssetsExperimentEnabled;

  BuildCommand({
    bool verbose = false,
    required this.recordUseEnabled,
    required this.dataAssetsExperimentEnabled,
  }) : super(
         cmdName,
         'Build a Dart application including code assets.',
         verbose,
       ) {
    addSubcommand(
      BuildCliSubcommand(
        verbose: verbose,
        recordUseEnabled: recordUseEnabled,
        dataAssetsExperimentEnabled: dataAssetsExperimentEnabled,
      ),
    );
  }

  @override
  CommandCategory get commandCategory => CommandCategory.project;
}

/// Subcommand for `dart build cli`.
///
/// Expects [Directory.current] to contain a Dart project with a bin/ directory.
class BuildCliSubcommand extends CompileSubcommandCommand {
  final bool recordUseEnabled;

  static const String cmdName = 'cli';

  static final OS targetOS = OS.current;
  static final bool busyBoxStyle = targetOS == OS.linux;
  late final List<File> entryPoints;

  final bool dataAssetsExperimentEnabled;

  @override
  String get invocation {
    // We don't take rest/positional arguments, so remove '<dart entry point>'
    // (inherited from CompileSubcommandCommand) and '[arguments]' from the help.
    return super.invocation
        .replaceAll(' <dart entry point>', '')
        .replaceAll(' [arguments]', '');
  }

  BuildCliSubcommand({
    bool verbose = false,
    required this.recordUseEnabled,
    required this.dataAssetsExperimentEnabled,
  }) : super(
         cmdName,
         '''Build a Dart application with a command line interface (CLI).

The resulting CLI app bundle is structured in the following manner:

bundle/
  bin/
    <executables>
  lib/
    <dynamic libraries>''',
         verbose,
       ) {
    final binDirectory = Directory.fromUri(
      Directory.current.uri.resolve('bin/'),
    );

    final outputDirectoryDefault = Directory.fromUri(
      Directory.current.uri.resolve(
        'build/cli/${OS.current}_${Architecture.current}/',
      ),
    );
    entryPoints = binDirectory.existsSync()
        ? binDirectory
              .listSync()
              .whereType<File>()
              .where((e) => e.path.endsWith('dart'))
              .toList()
        : [];
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        help: '''
          Write the output to <output>/bundle/.
          This can be an absolute or relative path.
          ''',
        valueHelp: 'path',
        defaultsTo: path
            .relative(outputDirectoryDefault.path, from: Directory.current.path)
            .makeFolder(),
      )
      ..addOption(
        'target',
        abbr: 't',
        help: '''The main entry-point file of the command-line application.
Must be a Dart file.
If the "--target" option is omitted, and there is a single Dart file in bin/,
then that is used instead.''',
        valueHelp: 'path',
        defaultsTo: entryPoints.length == 1
            ? path.relative(
                entryPoints.single.path,
                from: Directory.current.path,
              )
            : null,
      )
      ..addOption(
        packagesOption.flag,
        abbr: packagesOption.abbr,
        valueHelp: packagesOption.valueHelp,
        help: packagesOption.help,
      )
      ..addOption(
        'verbosity',
        help: 'Sets the verbosity level of the compilation.',
        valueHelp: 'level',
        defaultsTo: Verbosity.defaultValue,
        allowed: Verbosity.allowedValues,
        allowedHelp: Verbosity.allowedValuesHelp,
      )
      ..addOption(
        'depfile',
        valueHelp: 'path',
        help:
            'Path to an output file in Ninja depfile format containing a list of compilation dependencies. This is passed to the compiler to support dependency tracking in build systems.',
      )
      ..addOption(
        'target-sanitizer',
        help: 'Build with a specific target sanitizer.',
        allowed: Sanitizer.available().map((s) => s.name).toList(),
        defaultsTo: 'none',
      )
      ..addOption(
        'target-os',
        help: 'Compile to a specific target operating system.',
        allowed: TargetOS.names,
      )
      ..addOption(
        'target-arch',
        help: 'Compile to a specific target architecture.',
        allowed: Architecture.values.map((v) => v.name).toList(),
      )
      ..addOption(
        'root-package',
        help:
            'The package for which hooks are run (including its transitive '
            'dependencies). Must be provided if the entry point(s) are outside '
            'the packages in the packages argument.',
        valueHelp: 'name',
      )
      ..addExperimentalFlags(verbose: verbose);
  }

  @override
  Future<int> run() async {
    final args = argResults!;
    final sanitizer = Sanitizer.fromString(args.option('target-sanitizer'))!;
    final targetRuntime = busyBoxStyle
        ? sdk.dartCliRuntimeFor(sanitizer: sanitizer.name)
        : sdk.dartAotRuntimeFor(sanitizer: sanitizer.name);
    if (!checkArtifactExists(sdk.genKernelSnapshot) ||
        !checkArtifactExists(sdk.genSnapshot) ||
        !checkArtifactExists(targetRuntime) ||
        !checkArtifactExists(sdk.dart)) {
      return 255;
    }

    var genSnapshotBinary = sdk.genSnapshot;
    var dartAotRuntimeBinary = targetRuntime;

    final crossTarget = crossCompilationTarget(args);
    if (crossTarget != null) {
      if (!CompileSubcommandCommand.supportedTargetPlatforms.contains(
        crossTarget,
      )) {
        stderr.writeln('Unsupported target platform $crossTarget.');
        stderr.writeln(
          'Supported target platforms: '
          '${CompileSubcommandCommand.supportedTargetPlatforms.join(', ')}',
        );
        return crossCompileErrorExitCode;
      }
      if (sanitizer != Sanitizer.none) {
        stderr.writeln('Sanitizers are not supported when cross-compiling.');
        return 255;
      }

      final targetBinaries = await resolveTargetBinaries(crossTarget);
      genSnapshotBinary = targetBinaries.genSnapshot;
      dartAotRuntimeBinary = targetBinaries.dartAotRuntime;
    }
    // AOT compilation isn't supported on ia32. Currently, generating an
    // executable only supports AOT runtimes, so these commands are disabled.
    if (Platform.version.contains('ia32')) {
      stderr.writeln("'dart build' is not supported on x86 architectures.");
      return 64;
    }

    if (args.rest.isNotEmpty) {
      usageException('Unexpected arguments: ${args.rest.join(' ')}');
    }
    final target = args.option('target');

    if (target == null) {
      if (entryPoints.isEmpty) {
        stderr.writeln(
          "No entry point was specified. Use '--target <path>'.",
        );
      } else {
        stderr.writeln(
          'There are multiple possible targets in the `bin/` directory, '
          "and the target wasn't specified.",
        );
      }
      return 255;
    }
    final sourceUri = File.fromUri(
      Uri.file(target).normalizePath(),
    ).absolute.uri;
    if (!checkFile(sourceUri.toFilePath())) {
      return genericErrorExitCode;
    }

    final targetOS = crossTarget?.os ?? OS.current;
    final targetArch = crossTarget?.architecture ?? Architecture.current;
    final String outputDirString;
    if (args.wasParsed('output')) {
      outputDirString = args.option('output')!;
    } else {
      outputDirString = path.join('build', 'cli', '${targetOS}_$targetArch');
    }
    final outputUri = Uri.directory(
      outputDirString.normalizeCanonicalizePath().makeFolder(),
    );
    if (await File.fromUri(outputUri.resolve('pubspec.yaml')).exists()) {
      stderr.writeln("'dart build' refuses to delete your project.");
      stderr.writeln('Requested output directory: ${outputUri.toFilePath()}');
      return 128;
    }
    final verbosity = args.option('verbosity')!;
    final depFile = args.option('depfile');
    final enabledExperiments = args.enabledExperiments;

    Uri? packageConfigUri;
    final packages = args.option(packagesOption.flag);
    if (packages != null) {
      packageConfigUri = File(packages).absolute.uri;
    } else {
      packageConfigUri = await DartNativeAssetsBuilder.ensurePackageConfig(
        sourceUri,
      );
    }
    if (packageConfigUri == null) {
      stderr.writeln(
        'Error: Could not find or generate a package config mapping.',
      );
      return 255;
    }
    final pubspecUri =
        await DartNativeAssetsBuilder.findWorkspacePubspec(
          packageConfigUri,
        ) ??
        await DartNativeAssetsBuilder.findPubspec(sourceUri);
    final executableName = path.basenameWithoutExtension(sourceUri.path);

    return await doBuild(
      executables: [(name: executableName, sourceEntryPoint: sourceUri)],
      enabledExperiments: enabledExperiments,
      outputUri: outputUri,
      packageConfigUri: packageConfigUri,
      pubspecUri: pubspecUri,
      recordUseEnabled: recordUseEnabled,
      dataAssetsExperimentEnabled: dataAssetsExperimentEnabled,
      verbose: verbose,
      verbosity: verbosity,
      depFile: depFile,
      sanitizer: sanitizer,
      runPackageName: args.option('root-package'),
      target: crossTarget,
      genSnapshotPath: genSnapshotBinary,
      dartAotRuntimePath: dartAotRuntimeBinary,
    );
  }

  static Future<int> doBuild({
    required DartBuildExecutables executables,
    required Uri outputUri,
    required Uri packageConfigUri,
    required Uri? pubspecUri,
    required bool recordUseEnabled,
    required bool dataAssetsExperimentEnabled,
    required List<String> enabledExperiments,
    required bool verbose,
    required String verbosity,
    Sanitizer sanitizer = Sanitizer.none,
    bool progressUpdatesOnStderr = false,
    String? depFile,
    String? runPackageName,
    Target? target,
    String? genSnapshotPath,
    String? dartAotRuntimePath,
  }) async {
    final resolvedTarget = target ?? Target.current;
    final targetOS = resolvedTarget.os;
    if (executables.length >= 2) {
      if (recordUseEnabled) {
        // Multiple entry points can lead to multiple different tree-shakings.
        // We either need to generate a new entry point that combines all entry
        // points and combine that into a single executable and have wrappers
        // around that executable. Or, we need to merge the recorded uses for
        // the various entrypoints. The former will lead to smaller bundle-size
        // overall.
        stderr.writeln(
          'Multiple executables together with record use is not yet supported.',
        );
        return 255;
      }
      if (depFile != null) {
        stderr.writeln(
          'The --depfile option is not supported with multiple targets.',
        );
        return 255;
      }
    }
    final outputDir = Directory.fromUri(outputUri);
    if (await outputDir.exists()) {
      stdout.writeln('Deleting output directory: ${outputUri.toFilePath()}.');
      try {
        await outputDir.delete(recursive: true);
      } on PathAccessException {
        stderr.writeln(
          'Failed to delete: ${outputUri.toFilePath()}. '
          'The application might be in use.',
        );
        return 255;
      }
    }

    // Place the bundle in a subdir so that we can potentially put debug symbols
    // next to it.
    final bundleDirectory = Directory.fromUri(outputUri.resolve('bundle/'));
    final binDirectory = Directory.fromUri(bundleDirectory.uri.resolve('bin/'));
    final libDirectory = Directory.fromUri(bundleDirectory.uri.resolve('lib/'));
    await binDirectory.create(recursive: true);
    await libDirectory.create(recursive: true);

    final packageConfig = await DartNativeAssetsBuilder.loadPackageConfig(
      packageConfigUri,
    );
    if (packageConfig == null) {
      return compileErrorExitCode;
    }
    String? resolvedRunPackageName = runPackageName;
    if (resolvedRunPackageName == null) {
      final entrypointPackage = packageConfig.packageOf(
        executables.first.sourceEntryPoint,
      );
      if (entrypointPackage == null) {
        stderr.writeln(
          "Error: The entrypoint '${executables.first.sourceEntryPoint.toFilePath()}' "
          "does not reside in any package defined in the package config at '${packageConfigUri.toFilePath()}'.",
        );
        return 255;
      }
      resolvedRunPackageName = entrypointPackage.name;

      for (final executable in executables.skip(1)) {
        final exePackage = packageConfig.packageOf(executable.sourceEntryPoint);
        if (exePackage == null || exePackage.name != resolvedRunPackageName) {
          stderr.writeln(
            'Error: All entrypoints must reside in the same package. '
            "'${executable.sourceEntryPoint.toFilePath()}' does not belong to package '$resolvedRunPackageName'.",
          );
          return 255;
        }
      }
    }
    pubspecUri ??=
        await DartNativeAssetsBuilder.findWorkspacePubspec(
          packageConfigUri,
        ) ??
        await DartNativeAssetsBuilder.findPubspec(
          executables.first.sourceEntryPoint,
        );
    final builder = DartNativeAssetsBuilder(
      pubspecUri: pubspecUri,
      packageConfigUri: packageConfigUri,
      packageConfig: packageConfig,
      runPackageName: resolvedRunPackageName,
      includeDevDependencies: false,
      verbose: verbose,
      dataAssetsExperimentEnabled: dataAssetsExperimentEnabled,
      progressUpdatesOnStderr: progressUpdatesOnStderr,
      sanitizer: sanitizer,
      target: target,
    );
    final showProgress = verbosity != Verbosity.error.name;
    BuildResult? buildResult;
    final hasHooks = await builder.hasHooks();
    if (hasHooks) {
      buildResult = await (showProgress
          ? progress(
              'Running build hooks',
              builder.buildNativeAssetsAOT,
              progressUpdatesOnStderr: progressUpdatesOnStderr,
            )
          : builder.buildNativeAssetsAOT());
      if (buildResult == null) {
        stderr.writeln('Running build hooks failed.');
        return 255;
      }
    }

    final tempDir = Directory.systemTemp.createTempSync();
    try {
      var first = true;
      Uri? nativeAssetsYamlUri;
      LinkResult? linkResult;
      for (final e in executables) {
        String? recordedUsagesPath;
        if (recordUseEnabled) {
          // Enable concurrently running `dart build cli`. Don't store file in
          // .dart_tool/.
          recordedUsagesPath = path.join(tempDir.path, 'recorded_usages.json');
        }
        final outputExeUri = binDirectory.uri.resolve(
          targetOS.executableFileName(e.name),
        );
        final outputSnapshotUri = busyBoxStyle
            ? libDirectory.uri.resolve(_linuxAotSnapshotFileName(e.name))
            : null;
        final generator = KernelGenerator(
          genSnapshot: genSnapshotPath ?? sdk.genSnapshot,
          targetDartAotRuntime:
              dartAotRuntimePath ??
              sdk.dartAotRuntimeFor(
                sanitizer: sanitizer.name,
              ),
          kind: busyBoxStyle ? Kind.aot : Kind.exe,
          sourceFile: e.sourceEntryPoint.toFilePath(),
          outputFile: (outputSnapshotUri ?? outputExeUri).toFilePath(),
          verbose: verbose,
          verbosity: verbosity,
          defines: [...sanitizer.defines],
          packages: packageConfigUri.toFilePath(),
          targetOS: targetOS,
          enableExperiment: enabledExperiments.join(','),
          tempDir: tempDir,
          depFile: depFile,
          progressUpdatesOnStderr: progressUpdatesOnStderr,
        );

        final snapshotGenerator = await generator.generate(
          recordedUsagesFile: recordedUsagesPath,
        );

        if (first) {
          // Multiple executables are only supported with recorded uses
          // disabled, so don't re-invoke link hooks.
          if (hasHooks) {
            final entryPoints = executables
                .map((e) => e.sourceEntryPoint)
                .toList();
            linkResult = await (showProgress
                ? progress(
                    'Running link hooks',
                    () => builder.linkNativeAssetsAOT(
                      recordedUsagesPath: recordedUsagesPath,
                      entryPoints: entryPoints,
                      buildResult: buildResult!,
                    ),
                    progressUpdatesOnStderr: progressUpdatesOnStderr,
                  )
                : builder.linkNativeAssetsAOT(
                    recordedUsagesPath: recordedUsagesPath,
                    entryPoints: entryPoints,
                    buildResult: buildResult!,
                  ));
            if (linkResult == null) {
              stderr.writeln('Running link hooks failed.');
              return 255;
            }
          }
        }

        final allAssets = [
          if (hasHooks) ...[
            ...buildResult!.encodedAssets,
            ...linkResult!.encodedAssets,
          ],
        ];

        final staticAssets = allAssets
            .where((e) => e.isCodeAsset)
            .map(CodeAsset.fromEncoded)
            .where((e) => e.linkMode == StaticLinking());
        if (staticAssets.isNotEmpty) {
          stderr.write(
            """'dart build' does not yet support CodeAssets with static linking.
Use linkMode as dynamic library instead.""",
          );
          return 255;
        }

        if (allAssets.isNotEmpty && first) {
          // Without tree-shaking, the assets after linking must be identical
          // for all entry points.
          final kernelAssets = await bundleNativeAssets(
            allAssets,
            builder.target,
            binDirectory.uri,
            relocatable: true,
            verbose: true,
          );
          nativeAssetsYamlUri = await writeNativeAssetsYaml(
            kernelAssets,
            tempDir.uri,
          );
        }

        await snapshotGenerator.generate(
          nativeAssets: nativeAssetsYamlUri?.toFilePath(),
          extraOptions: [
            ...sanitizer.genSnapshotFlags,
          ],
        );

        if (busyBoxStyle) {
          if (first) {
            await File(
              sdk.dartCliRuntimeFor(sanitizer: sanitizer.name),
            ).copy(outputExeUri.toFilePath());
            await markExecutable(outputExeUri.toFilePath());
          } else {
            await Link.fromUri(
              outputExeUri,
            ).create(targetOS.executableFileName(executables.first.name));
          }
        } else if (targetOS == OS.macOS) {
          // The dylibs are opened with a relative path to the executable.
          // MacOS prevents opening dylibs that are not on the include path.
          await rewriteInstallPath(outputExeUri);
        }
        first = false;
      }
    } finally {
      await tempDir.delete(recursive: true);
    }
    return 0;
  }
}

extension on String {
  String normalizeCanonicalizePath() => path.canonicalize(path.normalize(this));
  String makeFolder() => endsWith('\\') || endsWith('/') ? this : '$this/';
}

/// The executables to build in a `dart build cli` app bundle.
///
/// All entry points must be in the same package.
///
/// The names are typically taken from the `executables` section of the
/// `pubspec.yaml` file.
///
/// Recorded usages and multiple executables are not supported yet.
typedef DartBuildExecutables = List<({String name, Uri sourceEntryPoint})>;

String _linuxAotSnapshotFileName(String executableName) =>
    'libdartaot$executableName.so';
