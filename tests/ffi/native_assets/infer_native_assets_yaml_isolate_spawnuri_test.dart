// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Invokes infer_native_assets_yaml_isolate_spawnuri_helper.dart with
// `Isolate.spawn`.
//
// 1. With an explicitly passed package_config.json path.
// 2. With automatic package resolution and no explicit path.
//
// No test without an explicitly passed package_config.json path without
// automatic package resolution, because it will inherit the Dart SDK
// package_config.json which has no corresponding native_assets.yaml.

import 'dart:io';
import 'dart:isolate';

import 'helpers.dart';

Future<void> main(List<String> args, Object? message) async {
  await invokeHelper(withPackageConfig: true);
  await invokeHelper(withPackageConfig: false);
}

const helperName = 'infer_native_assets_yaml_isolate_spawnuri_helper.dart';

final helperSourceuri = Platform.script.resolve(helperName);

final packageMetaUri = Platform.script.resolve('../../../pkg/meta');

/// Add an unused import to see that we're using actually the package config.
final emptyPackageConfig = '''{
  "configVersion": 2,
  "packages": [
    {
      "name": "meta",
      "rootUri": "$packageMetaUri",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    }
  ],
  "generated": "${DateTime.now()}",
  "generator": "test"
}
''';

Future<void> invokeHelper({bool withPackageConfig = true}) async {
  final test =
      withPackageConfig
          ? 'with packageConfig'
          : 'with automaticPackageResolution';
  print('invoke helper $test');
  await withTempDir((tempUri) async {
    await createTestFiles(tempUri);

    final helperCopiedUri = tempUri.resolve(helperName);
    final dartToolsUri = tempUri.resolve('.dart_tool/');
    final packageConfigUri = dartToolsUri.resolve('package_config.json');
    final receivePort = ReceivePort();
    await Isolate.spawnUri(
      helperCopiedUri,
      [],
      receivePort.sendPort,
      packageConfig: withPackageConfig ? packageConfigUri : null,
      automaticPackageResolution: !withPackageConfig,
    );

    final result = (await receivePort.first);
    if (result != 49) {
      throw "Unexpected result: $result.";
    }
  });
  print('invoke helper $test done');
}

Future<void> createTestFiles(Uri tempUri) async {
  final helperCopiedUri = tempUri.resolve(helperName);
  await File.fromUri(helperSourceuri).copy(helperCopiedUri.toFilePath());
  print('File copied to $helperCopiedUri.');

  final dartToolsUri = tempUri.resolve('.dart_tool/');
  await Directory.fromUri(dartToolsUri).create();

  final packageConfigUri = dartToolsUri.resolve('package_config.json');
  await File.fromUri(packageConfigUri).writeAsString(emptyPackageConfig);

  final nativeAssetsYaml = createNativeAssetYaml(
    asset: helperCopiedUri.toString(),
    assetMapping: ['absolute', ffiTestFunctionsUriAbsolute.toFilePath()],
  );
  final nativeAssetsUri = dartToolsUri.resolve('native_assets.yaml');
  await File.fromUri(nativeAssetsUri).writeAsString(nativeAssetsYaml);
  print('File native_assets.yaml written to $nativeAssetsUri.');
}
