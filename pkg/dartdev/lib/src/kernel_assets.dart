// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Library defining the `native_assets.yaml` format for embedding in a Dart
/// kernel file.
///
/// The `native_assets.yaml` embedded in a kernel file has a different format
/// from the assets passed in the `build_output.json` from individual native
/// assets builds. This library defines the format of the former.
///
/// The format should be consistent with `pkg/vm/lib/native_assets/`.
library;

import 'dart:convert';

import 'package:code_assets/code_assets.dart';

import 'target.dart';

class KernelAssets {
  final List<KernelAsset> _assets;

  KernelAssets([Iterable<KernelAsset>? assets]) : _assets = [...?assets];

  String toNativeAssetsFile() {
    final assetsPerTarget = <Target, List<KernelAsset>>{};
    for (final asset in _assets) {
      final assets = assetsPerTarget[asset.target] ?? [];
      assets.add(asset);
      assetsPerTarget[asset.target] = assets;
    }

    final jsonContents = {
      'format-version': [1, 0, 0],
      'native-assets': {
        for (final entry in assetsPerTarget.entries)
          entry.key.toString(): {
            for (final e in entry.value)
              e.id: e.path.toJsonForTarget(entry.key),
          },
      },
    };

    return const JsonEncoder.withIndent('  ').convert(jsonContents);
  }
}

class KernelAsset {
  final String id;
  final Target target;
  final KernelAssetPath path;

  KernelAsset({required this.id, required this.target, required this.path});
}

abstract class KernelAssetPath {
  List<String> toJson();
}

extension KernelAssetPathExtension on KernelAssetPath {
  List<String> toJsonForTarget(Target target) => switch (this) {
    final KernelAssetAbsolutePath p => [
      KernelAssetAbsolutePath._pathTypeValue,
      p.uri.toFilePath(windows: target.os == OS.windows),
    ],
    final KernelAssetRelativePath p => [
      KernelAssetRelativePath._pathTypeValue,
      p.uri.toFilePath(windows: target.os == OS.windows),
    ],
    final KernelAssetSystemPath p => [
      KernelAssetSystemPath._pathTypeValue,
      p.uri.toFilePath(windows: target.os == OS.windows),
    ],
    _ => toJson(),
  };
}

/// Asset at absolute path [uri] on the target device where Dart is run.
class KernelAssetAbsolutePath implements KernelAssetPath {
  final Uri uri;

  KernelAssetAbsolutePath(this.uri);

  static const _pathTypeValue = 'absolute';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KernelAssetAbsolutePath && other.uri == uri);

  @override
  int get hashCode => uri.hashCode;

  @override
  List<String> toJson() => [
    _pathTypeValue,
    uri.toFilePath(),
  ];
}

/// Asset at relative path [uri], relative to the 'dart file' executed.
///
/// The 'dart file' executed can be one of the following:
///
/// 1. The `.dart` file when executing `dart path/to/script.dart`.
/// 2. The `.kernel` file when executing from a kernel file.
/// 3. The `.aotsnapshot` file when executing from an AOT snapshot with the Dart
///    AOT runtime.
/// 4. The executable when executing a Dart app compiled with `dart compile exe`
///    to a single file.
///
/// Note when writing your own embedder, make sure the `Dart_CreateIsolateGroup`
/// or similar calls set up the `script_uri` parameter correctly to ensure
/// relative path resolution works.
class KernelAssetRelativePath implements KernelAssetPath {
  final Uri uri;

  KernelAssetRelativePath(this.uri);

  static const _pathTypeValue = 'relative';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KernelAssetRelativePath && other.uri == uri);

  @override
  int get hashCode => uri.hashCode;

  @override
  List<String> toJson() => [
    _pathTypeValue,
    uri.toFilePath(),
  ];
}

/// Asset is available on the system `PATH`.
///
/// [uri] only contains a file name.
class KernelAssetSystemPath implements KernelAssetPath {
  final Uri uri;

  KernelAssetSystemPath(this.uri);

  static const _pathTypeValue = 'system';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KernelAssetSystemPath && other.uri == uri);

  @override
  int get hashCode => uri.hashCode;

  // coverage:ignore-start
  @override
  String toString() => 'KernelAssetAbsolutePath($uri)';
  // coverage:ignore-end

  @override
  List<String> toJson() => [
    _pathTypeValue,
    uri.toFilePath(),
  ];
}

/// Asset is loaded in the process and symbols are available through
/// `DynamicLibrary.process()`.
class KernelAssetInProcess implements KernelAssetPath {
  KernelAssetInProcess._();

  static final KernelAssetInProcess _singleton = KernelAssetInProcess._();

  factory KernelAssetInProcess() => _singleton;

  static const _pathTypeValue = 'process';

  @override
  List<String> toJson() => [_pathTypeValue];
}

/// Asset is embedded in executable and symbols are available through
/// `DynamicLibrary.executable()`.
class KernelAssetInExecutable implements KernelAssetPath {
  KernelAssetInExecutable._();

  static final KernelAssetInExecutable _singleton = KernelAssetInExecutable._();

  factory KernelAssetInExecutable() => _singleton;

  static const _pathTypeValue = 'executable';

  @override
  List<String> toJson() => [_pathTypeValue];
}
