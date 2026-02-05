// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
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
  late final List<File> entryPoints;

  final bool dataAssetsExperimentEnabled;

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
    <executable>
  lib/
    <dynamic libraries>
''',
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
Must be a Dart file in the bin/ directory.
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
        help: 'Path to output Ninja depfile',
      )
      ..addExperimentalFlags(verbose: verbose);
  }

  @override
  Future<int> run() async {
    if (!checkArtifactExists(sdk.genKernelSnapshot) ||
        !checkArtifactExists(sdk.genSnapshot) ||
        !checkArtifactExists(sdk.dartAotRuntime) ||
        !checkArtifactExists(sdk.dart)) {
      return 255;
    }
    // AOT compilation isn't supported on ia32. Currently, generating an
    // executable only supports AOT runtimes, so these commands are disabled.
    if (Platform.version.contains('ia32')) {
      stderr.writeln("'dart build' is not supported on x86 architectures.");
      return 64;
    }
    final args = argResults!;

    var target = args.option('target');
    if (target == null) {
      stderr.writeln(
        'There are multiple possible targets in the `bin/` directory, '
        "and the 'target' argument wasn't specified.",
      );
      return 255;
    }
    final sourceUri = File.fromUri(
      Uri.file(target).normalizePath(),
    ).absolute.uri;
    if (!checkFile(sourceUri.toFilePath())) {
      return genericErrorExitCode;
    }

    final outputUri = Uri.directory(
      args.option('output')?.normalizeCanonicalizePath().makeFolder() ??
          sourceUri.toFilePath().removeDotDart().makeFolder(),
    );
    if (await File.fromUri(outputUri.resolve('pubspec.yaml')).exists()) {
      stderr.writeln("'dart build' refuses to delete your project.");
      stderr.writeln('Requested output directory: ${outputUri.toFilePath()}');
      return 128;
    }
    final verbosity = args.option('verbosity')!;
    final depFile = args.option('depfile');
    final enabledExperiments = args.enabledExperiments;

    final packageConfigUri = await DartNativeAssetsBuilder.ensurePackageConfig(
      sourceUri,
    );
    final pubspecUri = await DartNativeAssetsBuilder.findWorkspacePubspec(
      packageConfigUri,
    );
    final executableName = path.basenameWithoutExtension(sourceUri.path);

    return await doBuild(
      executables: [(name: executableName, sourceEntryPoint: sourceUri)],
      enabledExperiments: enabledExperiments,
      outputUri: outputUri,
      packageConfigUri: packageConfigUri!,
      pubspecUri: pubspecUri,
      recordUseEnabled: recordUseEnabled,
      dataAssetsExperimentEnabled: dataAssetsExperimentEnabled,
      verbose: verbose,
      verbosity: verbosity,
      depFile: depFile,
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
    String? depFile,
  }) async {
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
    await binDirectory.create(recursive: true);

    final packageConfig = await DartNativeAssetsBuilder.loadPackageConfig(
      packageConfigUri,
    );
    if (packageConfig == null) {
      return compileErrorExitCode;
    }
    final runPackageName = await DartNativeAssetsBuilder.findRootPackageName(
      executables.first.sourceEntryPoint,
    );
    pubspecUri ??= await DartNativeAssetsBuilder.findWorkspacePubspec(
      packageConfigUri,
    );
    final builder = DartNativeAssetsBuilder(
      pubspecUri: pubspecUri,
      packageConfigUri: packageConfigUri,
      packageConfig: packageConfig,
      runPackageName: runPackageName!,
      includeDevDependencies: false,
      verbose: verbose,
      dataAssetsExperimentEnabled: dataAssetsExperimentEnabled,
    );
    final showProgress = verbosity != Verbosity.error.name;
    BuildResult? buildResult;
    final hasHooks = await builder.hasHooks();
    if (hasHooks) {
      buildResult = await (showProgress
          ? progress('Running build hooks', builder.buildNativeAssetsAOT)
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
          recordedUsagesPath = path.join(tempDir.path, 'recorded_usages.json');
        }
        final outputExeUri = binDirectory.uri.resolve(
          targetOS.executableFileName(e.name),
        );
        final generator = KernelGenerator(
          genSnapshot: sdk.genSnapshot,
          targetDartAotRuntime: sdk.dartAotRuntime,
          kind: Kind.exe,
          sourceFile: e.sourceEntryPoint.toFilePath(),
          outputFile: outputExeUri.toFilePath(),
          verbose: verbose,
          verbosity: verbosity,
          defines: [],
          packages: packageConfigUri.toFilePath(),
          targetOS: targetOS,
          enableExperiment: enabledExperiments.join(','),
          tempDir: tempDir,
          depFile: depFile,
        );

        final snapshotGenerator = await generator.generate(
          recordedUsagesFile: recordedUsagesPath,
        );

        if (first) {
          // Multiple executables are only supported with recorded uses
          // disabled, so don't re-invoke link hooks.
          if (hasHooks) {
            linkResult = await (showProgress
                ? progress(
                    'Running link hooks',
                    () => builder.linkNativeAssetsAOT(
                      recordedUsagesPath: recordedUsagesPath,
                      buildResult: buildResult!,
                    ),
                  )
                : builder.linkNativeAssetsAOT(
                    recordedUsagesPath: recordedUsagesPath,
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
        );

        if (targetOS == OS.macOS) {
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
  String removeDotDart() => replaceFirst(RegExp(r'\.dart$'), '');
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
