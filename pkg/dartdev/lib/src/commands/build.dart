// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dart2native/generate.dart';
import 'package:dartdev/src/commands/compile.dart';
import 'package:dartdev/src/experiments.dart';
import 'package:dartdev/src/native_assets_bundling.dart';
import 'package:dartdev/src/sdk.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show Verbosity;
import 'package:native_assets_cli/code_assets_builder.dart';
import 'package:path/path.dart' as path;
import 'package:vm/target_os.dart'; // For possible --target-os values.

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
    argParser
      ..addOption(
        outputOptionName,
        abbr: 'o',
        help: '''
          Write the output to <folder name>.
          This can be an absolute or relative path.
          ''',
      )
      ..addOption(
        formatOptionName,
        abbr: 'f',
        allowed: ['exe', 'aot'],
        defaultsTo: 'exe',
      )
      ..addOption('target-os',
          help: 'Compile to a specific target operating system.',
          allowed: TargetOS.names)
      ..addOption(
        'verbosity',
        help: 'Sets the verbosity level of the compilation.',
        defaultsTo: Verbosity.defaultValue,
        allowed: Verbosity.allowedValues,
        allowedHelp: Verbosity.allowedValuesHelp,
      )
      ..addExperimentalFlags(verbose: verbose);
  }

  @override
  String get invocation => '${super.invocation} <dart entry point>';

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

    // We expect a single rest argument; the dart entry point.
    if (args.rest.length != 1) {
      // This throws.
      usageException('Missing Dart entry point.');
    }

    // TODO(https://dartbug.com/52458): Support `dart build <pkg>:<bin-script>`.
    // Similar to Dart run. Possibly also in `dart compile`.
    final sourceUri = Uri(path: args.rest[0].normalizeCanonicalizePath());
    if (!checkFile(sourceUri.toFilePath())) {
      return genericErrorExitCode;
    }

    final outputUri = Uri.directory(
      args.option(outputOptionName)?.normalizeCanonicalizePath().makeFolder() ??
          sourceUri.toFilePath().removeDotDart().makeFolder(),
    );
    if (await File.fromUri(outputUri.resolve('pubspec.yaml')).exists()) {
      stderr.writeln("'dart build' refuses to delete your project.");
      stderr.writeln('Requested output directory: ${outputUri.toFilePath()}');
      return 128;
    }

    final format = Kind.values.byName(args.option(formatOptionName)!);
    final outputExeUri = outputUri.resolve(
      format.appendFileExtension(
        sourceUri.pathSegments.last.split('.').first,
      ),
    );
    String? targetOS = args['target-os'];
    if (format != Kind.exe) {
      assert(format == Kind.aot);
      // If we're generating an AOT snapshot and not an executable, then
      // targetOS is allowed to be null for a platform-independent snapshot
      // or a different platform than the host.
    } else if (targetOS == null) {
      targetOS = Platform.operatingSystem;
    } else if (targetOS != Platform.operatingSystem) {
      stderr.writeln(
          "'dart build -f ${format.name}' does not support cross-OS compilation.");
      stderr.writeln('Host OS: ${Platform.operatingSystem}');
      stderr.writeln('Target OS: $targetOS');
      return 128;
    }

    final outputDir = Directory.fromUri(outputUri);
    if (await outputDir.exists()) {
      stdout.writeln('Deleting output directory: ${outputUri.toFilePath()}.');
      await outputDir.delete(recursive: true);
    }
    await outputDir.create(recursive: true);

    stdout.writeln('Building native assets.');
    final packageConfig = await DartNativeAssetsBuilder.ensurePackageConfig(
      sourceUri,
    );
    final runPackageName = await DartNativeAssetsBuilder.findRootPackageName(
      sourceUri,
    );
    final pubspecUri =
        await DartNativeAssetsBuilder.findWorkspacePubspec(packageConfig);
    final builder = DartNativeAssetsBuilder(
      pubspecUri: pubspecUri,
      packageConfigUri: packageConfig!,
      runPackageName: runPackageName!,
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
        kind: format,
        sourceFile: sourceUri.toFilePath(),
        outputFile: outputExeUri.toFilePath(),
        verbose: verbose,
        verbosity: args.option('verbosity')!,
        defines: [],
        packages: packageConfig.toFilePath(),
        targetOS: targetOS == null ? null : OS.fromString(targetOS),
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
          outputUri,
          relocatable: true,
          verbose: true,
        );
        nativeAssetsYamlUri =
            await writeNativeAssetsYaml(kernelAssets, tempDir.uri);
      }

      await snapshotGenerator.generate(
        nativeAssets: nativeAssetsYamlUri?.toFilePath(),
      );

      // End linking here.
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
