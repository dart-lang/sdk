// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Reports the sizes of binary artifacts shipped with the SDK.

import 'dart:io';

const executables = <String>[
  'dart',
  'dartaotruntime',
];

const libs = <String>[
  'vm_platform_strong.dill',
  'vm_platform_strong_product.dill',
];

const snapshots = <String>[
  'analysis_server',
  'dart2js',
  'dart2native',
  'dartanalyzer',
  'dartdev',
  'dartdevc',
  'dartdoc',
  'dartfmt',
  'dds',
  'frontend_server',
  'gen_kernel',
  'kernel-service',
  'kernel_worker',
  'pub',
];

Future<void> reportArtifactSize(String path, String name) async {
  try {
    final size = await File(path).length();
    print('SDKArtifactSizes.$name(CodeSize): $size');
  } on FileSystemException {
    // Report dummy data for artifacts that don't exist for specific platforms.
    print('SDKArtifactSizes.$name(CodeSize): 0');
  }
}

Future<void> main() async {
  final topDirIndex =
      Platform.resolvedExecutable.lastIndexOf(Platform.pathSeparator);
  final rootDir = Platform.resolvedExecutable.substring(0, topDirIndex);

  for (final executable in executables) {
    final executablePath = '$rootDir/dart-sdk/bin/$executable';
    await reportArtifactSize(executablePath, executable);
  }

  for (final lib in libs) {
    final libPath = '$rootDir/dart-sdk/lib/_internal/$lib';
    await reportArtifactSize(libPath, lib);
  }

  for (final snapshot in snapshots) {
    final snapshotPath =
        '$rootDir/dart-sdk/bin/snapshots/$snapshot.dart.snapshot';
    await reportArtifactSize(snapshotPath, snapshot);
  }
}
