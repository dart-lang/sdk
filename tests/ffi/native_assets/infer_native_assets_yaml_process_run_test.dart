// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Invokes infer_native_assets_yaml_process_run_helper.dart with `Process.run`.
// 1. With an explicitly passed package_config.json path.
// 2. Without an explicitly passed package_config.json, walking up the file
//    tree.

import 'dart:io';

import 'helpers.dart';

Future<void> main(List<String> args, Object? message) async {
  await invokeHelperWithPackagesFlag();
  await invokeHelperWorkingDir();
}

const helperName = 'infer_native_assets_yaml_process_run_helper.dart';

final helperSourceuri = Platform.script.resolve(helperName);

final packageMetaUri = Platform.script.resolve('../../../pkg/meta');

/// Add an unused import to see that we're using actually the package config.
final testPackageConfig = '''{
  "configVersion": 2,
  "packages": [
    {
      "name": "meta",
      "rootUri": "${packageMetaUri.toFilePath()}",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    }
  ],
  "generated": "${DateTime.now()}",
  "generator": "test"
}
''';

Future<void> invokeHelperWithPackagesFlag() async {
  print('invoke helper with --package=...');
  await withTempDir((tempUri) async {
    await createTestFiles(tempUri);

    final helperCopiedUri = tempUri.resolve(helperName);
    final dartToolsUri = tempUri.resolve('.dart_tool/');
    final packageConfigUri = dartToolsUri.resolve('package_config.json');

    await runDart(
      scriptUri: helperCopiedUri,
      packageConfigUri: packageConfigUri,
    );
  });
  print('invoke helper with --package=... done');
}

Future<void> invokeHelperWorkingDir() async {
  print('invoke helper in working dir');
  await withTempDir((tempUri) async {
    await createTestFiles(tempUri);
    await runDart(
      workingDirectory: tempUri,
      scriptUri: Uri(path: helperName),
    );
  });
  print('invoke helper in working dir done');
}

Future<void> createTestFiles(Uri tempUri) async {
  final helperCopiedUri = tempUri.resolve(helperName);
  await File.fromUri(helperSourceuri).copy(helperCopiedUri.toFilePath());
  print('File copied to $helperCopiedUri.');

  final dartToolsUri = tempUri.resolve('.dart_tool/');
  await Directory.fromUri(dartToolsUri).create();

  final packageConfigUri = dartToolsUri.resolve('package_config.json');
  await File.fromUri(packageConfigUri).writeAsString(testPackageConfig);

  final nativeAssetsYaml = createNativeAssetYaml(
    asset: 'file://${helperCopiedUri.toFilePath()}',
    assetMapping: [
      'absolute',
      ffiTestFunctionsUriAbsolute.toFilePath(),
    ],
  );
  final nativeAssetsUri = dartToolsUri.resolve('native_assets.yaml');
  await File.fromUri(nativeAssetsUri).writeAsString(nativeAssetsYaml);
  print('File native_assets.yaml written to $nativeAssetsUri.');
}
