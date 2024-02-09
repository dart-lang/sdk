// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

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
  'dart2wasm',
  'dartdev',
  'dartdevc',
  'dds_aot',
  'frontend_server',
  'gen_kernel',
  'kernel-service',
  'kernel_worker',
];

const resources = <String>[
  'devtools',
];

void reportFileSize(String path, String name) {
  try {
    final size = File(path).lengthSync();
    print('SDKArtifactSizes.$name(CodeSize): $size');
  } on FileSystemException {
    // Report dummy data for artifacts that don't exist for specific platforms.
    print('SDKArtifactSizes.$name(CodeSize): 0');
  }
}

void reportDirectorySize(String path, String name) async {
  final dir = Directory(path);

  try {
    final size = dir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.lengthSync())
        .fold<int>(0, (a, b) => a + b);
    print('SDKArtifactSizes.$name(CodeSize): $size');
  } on FileSystemException {
    // Report dummy data on errors.
    print('SDKArtifactSizes.$name(CodeSize): 0');
  }
}

void main() {
  final topDirIndex =
      Platform.resolvedExecutable.lastIndexOf(Platform.pathSeparator);
  final rootDir = Platform.resolvedExecutable.substring(0, topDirIndex);

  for (final executable in executables) {
    final executablePath = '$rootDir/dart-sdk/bin/$executable';
    reportFileSize(executablePath, executable);
  }

  for (final lib in libs) {
    final libPath = '$rootDir/dart-sdk/lib/_internal/$lib';
    reportFileSize(libPath, lib);
  }

  for (final snapshot in snapshots) {
    final snapshotPath =
        '$rootDir/dart-sdk/bin/snapshots/$snapshot.dart.snapshot';
    reportFileSize(snapshotPath, snapshot);
  }

  for (final resource in resources) {
    final resourcePath = '$rootDir/dart-sdk/bin/resources/$resource';
    reportDirectorySize(resourcePath, resource);
  }

  // Measure the sdk size.
  reportDirectorySize('$rootDir/dart-sdk', 'sdk');
}
