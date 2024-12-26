// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Invokes infer_native_assets_yaml_isolate_spawnuri_helper.dart with
// `Isolate.spawn` with an explicitly passed package_config.json path and
// passing the helper as data uri rather than a path to the source file.

import 'dart:io';
import 'dart:isolate';

import 'helpers.dart';

Future<void> main(List<String> args, Object? message) async {
  await invokeHelper();
}

const helperName = 'infer_native_assets_yaml_isolate_spawnuri_3_helper.dart';

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

Future<void> invokeHelper() async {
  print('invoke helper');
  await withTempDir((tempUri) async {
    final helperContents = await File.fromUri(helperSourceuri).readAsString();
    final helperContentsDataUri = Uri.dataFromString(helperContents);
    await createTestFiles(tempUri, helperContentsDataUri);

    final dartToolsUri = tempUri.resolve('.dart_tool/');
    final packageConfigUri = dartToolsUri.resolve('package_config.json');
    final receivePort = ReceivePort();
    await Isolate.spawnUri(
      helperContentsDataUri,
      [],
      receivePort.sendPort,
      packageConfig: packageConfigUri,
    );

    final result = (await receivePort.first);
    if (result != 49) {
      throw "Unexpected result: $result.";
    }
  });
  print('invoke helper done');
}

Future<void> createTestFiles(Uri tempUri, Uri helperContentsDataUri) async {
  final dartToolsUri = tempUri.resolve('.dart_tool/');
  await Directory.fromUri(dartToolsUri).create();

  final packageConfigUri = dartToolsUri.resolve('package_config.json');
  await File.fromUri(packageConfigUri).writeAsString(emptyPackageConfig);

  final nativeAssetsYaml = createNativeAssetYaml(
    asset: helperContentsDataUri.toString(),
    assetMapping: ['absolute', ffiTestFunctionsUriAbsolute.toFilePath()],
  );
  final nativeAssetsUri = dartToolsUri.resolve('native_assets.yaml');
  await File.fromUri(nativeAssetsUri).writeAsString(nativeAssetsYaml);
  print('File native_assets.yaml written to $nativeAssetsUri.');
}
