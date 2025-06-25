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
import 'package:dartdev/src/sdk.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show Verbosity;
import 'package:path/path.dart' as path;

import '../core.dart';
import '../native_assets.dart';

class BuildCommand extends DartdevCommand {
  static const String cmdName = 'build';
  static const String outputOptionName = 'output';
  static const String formatOptionName = 'format';
  static const int genericErrorExitCode = 255;
  final bool recordUseEnabled;

  BuildCommand({bool verbose = false, required this.recordUseEnabled})
      : super(cmdName, 'Build a Dart application including native assets.',
            verbose) {
    addSubcommand(BuildCliSubcommand(
      verbose: verbose,
      recordUseEnabled: recordUseEnabled,
    ));
  }

  @override
  String get category => 'Project';
}

/// Subcommand for `dart build cli`.
///
/// Expects [Directory.current] to contain a Dart project with a bin/ directory.
class BuildCliSubcommand extends CompileSubcommandCommand {
  final bool recordUseEnabled;

  static const String cmdName = 'cli';

  static final OS targetOS = OS.current;
  late final List<File> entryPoints;

  BuildCliSubcommand({bool verbose = false, required this.recordUseEnabled})
      : super(
            cmdName,
            '''Build a Dart application with a command line interface (CLI).

The resulting CLI app bundle is structured in the following manner:

bundle/
  bin/
    <executable>
  lib/
    <dynamic libraries>
''',
            verbose) {
    final binDirectory =
        Directory.fromUri(Directory.current.uri.resolve('bin/'));

    final outputDirectoryDefault = Directory.fromUri(Directory.current.uri
        .resolve('build/cli/${OS.current}_${Architecture.current}/'));
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
            ? path.relative(entryPoints.single.path,
                from: Directory.current.path)
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
      ..addExperimentalFlags(verbose: verbose);
  }

  @override
  Future<int> run() async {
    if (!Sdk.checkArtifactExists(genKernel) ||
        !Sdk.checkArtifactExists(genSnapshotHost) ||
        !Sdk.checkArtifactExists(sdk.dart)) {
      return 255;
    }
    // AOT compilation isn't supported on ia32. Currently, generating an
    // executable only supports AOT runtimes, so these commands are disabled.
    if (Platform.version.contains('ia32')) {
      stderr.write("'dart build' is not supported on x86 architectures");
      return 64;
    }
    final args = argResults!;

    final sourceUri =
        File.fromUri(Uri.file(args.option('target')!).normalizePath())
            .absolute
            .uri;
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
    final outputDir = Directory.fromUri(outputUri);
    if (await outputDir.exists()) {
      stdout.writeln('Deleting output directory: ${outputUri.toFilePath()}.');
      await outputDir.delete(recursive: true);
    }
    final bundleDirectory = Directory.fromUri(outputUri.resolve('bundle/'));
    final binDirectory = Directory.fromUri(bundleDirectory.uri.resolve('bin/'));
    await binDirectory.create(recursive: true);

    final outputExeUri = binDirectory.uri.resolve(
      targetOS.executableFileName(
        path.basenameWithoutExtension(sourceUri.path),
      ),
    );

    stdout.writeln('''The `dart build cli` command is in preview at the moment.
See documentation on https://dart.dev/interop/c-interop#native-assets.
''');

    stdout.writeln('Building native assets.');
    final packageConfigUri = await DartNativeAssetsBuilder.ensurePackageConfig(
      sourceUri,
    );
    final packageConfig =
        await DartNativeAssetsBuilder.loadPackageConfig(packageConfigUri!);
    if (packageConfig == null) {
      return compileErrorExitCode;
    }
    final runPackageName = await DartNativeAssetsBuilder.findRootPackageName(
      sourceUri,
    );
    final pubspecUri =
        await DartNativeAssetsBuilder.findWorkspacePubspec(packageConfigUri);
    final builder = DartNativeAssetsBuilder(
      pubspecUri: pubspecUri,
      packageConfigUri: packageConfigUri,
      packageConfig: packageConfig,
      runPackageName: runPackageName!,
      includeDevDependencies: false,
      verbose: verbose,
    );
    final buildResult = await builder.buildNativeAssetsAOT();
    if (buildResult == null) {
      stderr.writeln('Native assets build failed.');
      return 255;
    }

    final tempDir = Directory.systemTemp.createTempSync();
    try {
      String? recordedUsagesPath;
      if (recordUseEnabled) {
        recordedUsagesPath = path.join(tempDir.path, 'recorded_usages.json');
      }
      final generator = KernelGenerator(
        genSnapshot: genSnapshotHost,
        targetDartAotRuntime: hostDartAotRuntime,
        kind: Kind.exe,
        sourceFile: sourceUri.toFilePath(),
        outputFile: outputExeUri.toFilePath(),
        verbose: verbose,
        verbosity: args.option('verbosity')!,
        defines: [],
        packages: packageConfigUri.toFilePath(),
        targetOS: targetOS,
        enableExperiment: args.enabledExperiments.join(','),
        tempDir: tempDir,
      );

      final snapshotGenerator = await generator.generate(
        recordedUsagesFile: recordedUsagesPath,
      );

      final linkResult = await builder.linkNativeAssetsAOT(
        recordedUsagesPath: recordedUsagesPath,
        buildResult: buildResult,
      );
      if (linkResult == null) {
        stderr.writeln('Native assets link failed.');
        return 255;
      }

      final allAssets = [
        ...buildResult.encodedAssets,
        ...linkResult.encodedAssets
      ];

      final staticAssets = allAssets
          .where((e) => e.isCodeAsset)
          .map(CodeAsset.fromEncoded)
          .where((e) => e.linkMode == StaticLinking());
      if (staticAssets.isNotEmpty) {
        stderr.write(
            """'dart build' does not yet support CodeAssets with static linking.
Use linkMode as dynamic library instead.""");
        return 255;
      }

      Uri? nativeAssetsYamlUri;
      if (allAssets.isNotEmpty) {
        final kernelAssets = await bundleNativeAssets(
          allAssets,
          builder.target,
          binDirectory.uri,
          relocatable: true,
          verbose: true,
        );
        nativeAssetsYamlUri =
            await writeNativeAssetsYaml(kernelAssets, tempDir.uri);
      }

      await snapshotGenerator.generate(
        nativeAssets: nativeAssetsYamlUri?.toFilePath(),
      );

      if (targetOS == OS.macOS) {
        // The dylibs are opened with a relative path to the executable.
        // MacOS prevents opening dylibs that are not on the include path.
        await rewriteInstallPath(outputExeUri);
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
