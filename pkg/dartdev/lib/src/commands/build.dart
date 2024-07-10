// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dart2native/generate.dart';
import 'package:dartdev/src/commands/compile.dart';
import 'package:dartdev/src/experiments.dart';
import 'package:dartdev/src/sdk.dart';
import 'package:dartdev/src/utils.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show Verbosity;
import 'package:native_assets_builder/native_assets_builder.dart';
import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:native_assets_cli/native_assets_cli_internal.dart';
import 'package:path/path.dart' as path;
import 'package:vm/target_os.dart'; // For possible --target-os values.

import '../core.dart';
import '../native_assets.dart';

const _libOutputDirectory = 'lib';
const _dataOutputDirectory = 'assets';

class BuildCommand extends DartdevCommand {
  static const String cmdName = 'build';
  static const String outputOptionName = 'output';
  static const String formatOptionName = 'format';
  static const int genericErrorExitCode = 255;

  BuildCommand({bool verbose = false})
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
        !Sdk.checkArtifactExists(genSnapshot) ||
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

    // Start native asset generation here.
    stdout.writeln('Building native assets.');
    final workingDirectory = Directory.current.uri;
    final target = Target.current;
    final targetMacOSVersion =
        target.os == OS.macOS ? minimumSupportedMacOSVersion : null;
    final nativeAssetsBuildRunner = NativeAssetsBuildRunner(
      dartExecutable: Uri.file(sdk.dart),
      logger: logger(verbose),
    );
    final buildResult = await nativeAssetsBuildRunner.build(
      workingDirectory: workingDirectory,
      target: target,
      linkModePreference: LinkModePreferenceImpl.dynamic,
      buildMode: BuildModeImpl.release,
      includeParentEnvironment: true,
      supportedAssetTypes: [
        NativeCodeAsset.type,
      ],
      targetMacOSVersion: targetMacOSVersion,
      linkingEnabled: true,
    );
    if (!buildResult.success) {
      stderr.writeln('Native assets build failed.');
      return 255;
    }
    // End native asset generation here.

    final tempDir = Directory.systemTemp.createTempSync();
    try {
      final packageConfig = await packageConfigUri(sourceUri);
      final resources = path.join(tempDir.path, 'resources.json');
      final generator = KernelGenerator(
        kind: format,
        sourceFile: sourceUri.toFilePath(),
        outputFile: outputExeUri.toFilePath(),
        verbose: verbose,
        verbosity: args.option('verbosity')!,
        defines: [],
        packages: packageConfig?.toFilePath(),
        targetOS: targetOS,
        enableExperiment: args.enabledExperiments.join(','),
        tempDir: tempDir,
      );

      final snapshotGenerator = await generator.generate(
        resourcesFile: resources,
      );

      // Start linking here.
      final linkResult = await nativeAssetsBuildRunner.link(
        resourceIdentifiers: Uri.file(resources),
        workingDirectory: workingDirectory,
        target: target,
        linkModePreference: LinkModePreferenceImpl.dynamic,
        buildMode: BuildModeImpl.release,
        includeParentEnvironment: true,
        buildResult: buildResult,
        targetMacOSVersion: targetMacOSVersion,
        supportedAssetTypes: [
          NativeCodeAsset.type,
        ],
      );

      if (!linkResult.success) {
        stderr.writeln('Native assets link failed.');
        return 255;
      }

      final tempUri = tempDir.uri;
      Uri? assetsDartUri;
      final allAssets = [...buildResult.assets, ...linkResult.assets];
      final staticAssets = allAssets
          .whereType<NativeCodeAssetImpl>()
          .where((e) => e.linkMode == StaticLinkingImpl());
      if (staticAssets.isNotEmpty) {
        stderr.write(
            """'dart build' does not yet support NativeCodeAssets with static linking.
Use linkMode as dynamic library instead.""");
        return 255;
      }
      if (allAssets.isNotEmpty) {
        final targetMapping = _targetMapping(allAssets, target);
        assetsDartUri = await _writeAssetsYaml(
          targetMapping.map((e) => e.target).toList(),
          assetsDartUri,
          tempUri,
        );
        if (allAssets.isNotEmpty) {
          stdout.writeln(
              'Copying ${allAssets.length} build assets: ${allAssets.map((e) => e.id)}');
          _copyAssets(targetMapping, outputUri);
        }
      }

      await snapshotGenerator.generate(
        nativeAssets: assetsDartUri?.toFilePath(),
      );

      // End linking here.
    } finally {
      await tempDir.delete(recursive: true);
    }
    return 0;
  }

  List<({AssetImpl asset, KernelAsset target})> _targetMapping(
    Iterable<AssetImpl> assets,
    Target target,
  ) {
    return [
      for (final asset in assets)
        (asset: asset, target: asset.targetLocation(target)),
    ];
  }

  void _copyAssets(
    List<({AssetImpl asset, KernelAsset target})> assetTargetLocations,
    Uri output,
  ) {
    for (final (asset: asset, target: target) in assetTargetLocations) {
      final targetPath = target.path;
      if (targetPath is KernelAssetRelativePath) {
        asset.file!.copyTo(targetPath, output);
      }
    }
  }

  Future<Uri> _writeAssetsYaml(
    List<KernelAsset> assetTargetLocations,
    Uri? nativeAssetsDartUri,
    Uri tempUri,
  ) async {
    stdout.writeln('Writing native_assets.yaml.');
    nativeAssetsDartUri = tempUri.resolve('native_assets.yaml');
    final assetsContent =
        KernelAssets(assetTargetLocations).toNativeAssetsFile();
    await Directory.fromUri(nativeAssetsDartUri.resolve('.')).create();
    await File(nativeAssetsDartUri.toFilePath()).writeAsString(assetsContent);
    return nativeAssetsDartUri;
  }
}

extension on String {
  String normalizeCanonicalizePath() => path.canonicalize(path.normalize(this));
  String makeFolder() => endsWith('\\') || endsWith('/') ? this : '$this/';
  String removeDotDart() => replaceFirst(RegExp(r'\.dart$'), '');
}

extension on Uri {
  void copyTo(KernelAssetRelativePath target, Uri outputUri) {
    if (this != target.uri) {
      final targetUri = outputUri.resolveUri(target.uri);
      File.fromUri(targetUri).createSync(
        recursive: true,
        exclusive: true,
      );
      File.fromUri(this).copySync(targetUri.toFilePath());
    }
  }
}

extension on AssetImpl {
  KernelAsset targetLocation(Target target) {
    return switch (this) {
      NativeCodeAssetImpl nativeAsset => nativeAsset.targetLocation(target),
      DataAssetImpl dataAsset => dataAsset.targetLocation(target),
      AssetImpl() => throw UnimplementedError(),
    };
  }
}

extension on NativeCodeAssetImpl {
  KernelAsset targetLocation(Target target) {
    final KernelAssetPath kernelAssetPath;
    switch (linkMode) {
      case DynamicLoadingSystemImpl dynamicLoading:
        kernelAssetPath = KernelAssetSystemPath(dynamicLoading.uri);
      case LookupInExecutableImpl _:
        kernelAssetPath = KernelAssetInExecutable();
      case LookupInProcessImpl _:
        kernelAssetPath = KernelAssetInProcess();
      case DynamicLoadingBundledImpl _:
        kernelAssetPath = KernelAssetRelativePath(
          Uri(path: path.join(_libOutputDirectory, file!.pathSegments.last)),
        );
      default:
        throw Exception(
          'Unsupported NativeCodeAsset linkMode ${linkMode.runtimeType} in asset $this',
        );
    }
    return KernelAsset(
      id: id,
      target: target,
      path: kernelAssetPath,
    );
  }
}

extension on DataAssetImpl {
  KernelAsset targetLocation(Target target) {
    return KernelAsset(
      id: id,
      target: target,
      path: KernelAssetRelativePath(
          Uri(path: path.join(_dataOutputDirectory, file.pathSegments.last))),
    );
  }
}

// TODO(https://github.com/dart-lang/package_config/issues/126): Expose this
// logic in package:package_config.
Future<Uri?> packageConfigUri(Uri uri) async {
  while (true) {
    final candidate = uri.resolve('.dart_tool/package_config.json');
    if (await File.fromUri(candidate).exists()) {
      return candidate;
    }
    final parent = uri.resolve('..');
    if (parent == uri) {
      return null;
    }
    uri = parent;
  }
}
