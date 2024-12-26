// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartdev/src/native_assets_macos.dart';
import 'package:native_assets_builder/native_assets_builder.dart';
import 'package:native_assets_cli/code_assets_builder.dart';
import 'package:native_assets_cli/data_assets_builder.dart';

final libOutputDirectoryUri = Uri.file('lib/');
final dataOutputDirectoryUri = Uri.file('assets/');

Future<KernelAssets> bundleNativeAssets(
  Iterable<EncodedAsset> assets,
  Target target,
  Uri outputUri, {
  required bool relocatable,
  bool verbose = false,
}) async {
  final targetMapping = _targetMapping(assets, target, outputUri, relocatable);
  await _copyAssets(targetMapping, target, outputUri, relocatable, verbose);
  return KernelAssets(targetMapping.map((asset) => asset.target).toList());
}

Future<Uri> writeNativeAssetsYaml(
  KernelAssets assets,
  Uri outputUri, {
  String? header,
}) async {
  final nativeAssetsYamlUri = outputUri.resolve('native_assets.yaml');
  final nativeAssetsYamlFile = File(nativeAssetsYamlUri.toFilePath());
  await nativeAssetsYamlFile.create(recursive: true);

  var contents = assets.toNativeAssetsFile();
  if (header != null) {
    contents = '$header\n$contents';
  }

  await nativeAssetsYamlFile.writeAsString(contents);
  return nativeAssetsYamlUri;
}

Future<void> _copyAssets(
  List<({Object asset, KernelAsset target})> targetMapping,
  Target target,
  Uri outputUri,
  bool relocatable,
  bool verbose,
) async {
  final filesToCopy = <({String id, Uri src, Uri dest})>[];
  final codeAssetUris = <Uri>[];

  for (final (:asset, :target) in targetMapping) {
    final targetPath = target.path;
    if (targetPath
        case KernelAssetRelativePath(:final uri) ||
            KernelAssetAbsolutePath(:final uri)) {
      final targetUri = outputUri.resolveUri(uri);

      switch (asset) {
        case CodeAsset(:final file!):
          filesToCopy.add((
            id: asset.id,
            src: file,
            dest: targetUri,
          ));
          codeAssetUris.add(targetUri);
        case DataAsset(:final file):
          filesToCopy.add((
            id: asset.id,
            src: file,
            dest: targetUri,
          ));
        default:
          throw UnimplementedError();
      }
    }
  }

  if (filesToCopy.isNotEmpty) {
    if (verbose) {
      stdout.writeln(
        'Copying ${filesToCopy.length} build assets:\n'
        '${filesToCopy.map((e) => e.id).join('\n')}',
      );
    }

    // TODO(https://dartbug.com/59668): Cache copying and rewriting of install names
    await Future.wait(filesToCopy.map((file) => file.src.copyTo(file.dest)));

    if (target.os == OS.macOS) {
      await rewriteInstallNames(codeAssetUris, relocatable: relocatable);
    }
  }
}

List<({Object asset, KernelAsset target})> _targetMapping(
  Iterable<EncodedAsset> assets,
  Target target,
  Uri outputUri,
  bool relocatable,
) {
  final codeAssets = assets
      .where((asset) => asset.type == CodeAsset.type)
      .map(CodeAsset.fromEncoded);
  final dataAssets = assets
      .where((asset) => asset.type == DataAsset.type)
      .map(DataAsset.fromEncoded);

  return [
    for (final asset in codeAssets)
      (
        asset: asset,
        target: asset.targetLocation(target, outputUri, relocatable)
      ),
    for (final asset in dataAssets)
      (
        asset: asset,
        target: asset.targetLocation(target, outputUri, relocatable)
      ),
  ];
}

extension on CodeAsset {
  KernelAsset targetLocation(Target target, Uri outputUri, bool relocatable) {
    final kernelAssetPath = switch (linkMode) {
      DynamicLoadingSystem(:final uri) => KernelAssetSystemPath(uri),
      LookupInExecutable() => KernelAssetInExecutable(),
      LookupInProcess() => KernelAssetInProcess(),
      DynamicLoadingBundled() => () {
          final relativeUri =
              libOutputDirectoryUri.resolve(file!.pathSegments.last);
          return relocatable
              ? KernelAssetRelativePath(relativeUri)
              : KernelAssetAbsolutePath(outputUri.resolveUri(relativeUri));
        }(),
      _ => throw UnsupportedError(
          'Unsupported NativeCodeAsset linkMode ${linkMode.runtimeType} in asset $this',
        ),
    };
    return KernelAsset(
      id: id,
      target: target,
      path: kernelAssetPath,
    );
  }
}

extension on DataAsset {
  KernelAsset targetLocation(Target target, Uri outputUri, bool relocatable) {
    final relativeUri = dataOutputDirectoryUri.resolve(file.pathSegments.last);
    return KernelAsset(
      id: id,
      target: target,
      path: relocatable
          ? KernelAssetRelativePath(relativeUri)
          : KernelAssetAbsolutePath(outputUri.resolveUri(relativeUri)),
    );
  }
}

extension on Uri {
  Future<void> copyTo(Uri targetUri) async {
    await File.fromUri(targetUri).create(recursive: true);
    await File.fromUri(this).copy(targetUri.toFilePath());
  }
}
