// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Invokes infer_native_assets_yaml_isolate_spawnuri_2_helper.dart with
// `Isolate.spawn` and an explicitly passed package_config.json path.
//
// That subsequently invokes
// infer_native_assets_yaml_isolate_spawnuri_2_helper_2.dart with
// `Isolate.spawn` without a package_config.json path and without automatic
// package resolution, such that it will inherit the native assets yaml.

import 'dart:io';
import 'dart:isolate';

import 'helpers.dart';

Future<void> main(List<String> args, Object? message) async {
  await invokeHelper();
}

const helperName = 'infer_native_assets_yaml_isolate_spawnuri_2_helper.dart';
const helper2Name = 'infer_native_assets_yaml_isolate_spawnuri_2_helper_2.dart';

final helperSourceuri = Platform.script.resolve(helperName);
final helper2Sourceuri = Platform.script.resolve(helper2Name);

final emptyPackageConfig = '''{
  "configVersion": 2,
  "packages": [],
  "generated": "${DateTime.now()}",
  "generator": "test"
}
''';

Future<void> invokeHelper() async {
  print('invoke helper with packageConfig');
  await withTempDir((tempUri) async {
    await withTempDir((tempUri2) async {
      await createTestFiles(tempUri, tempUri2);

      final helperCopiedUri = tempUri.resolve(helperName);
      final dartToolsUri = tempUri.resolve('.dart_tool/');
      final packageConfigUri = dartToolsUri.resolve('package_config.json');
      final receivePort = ReceivePort();
      await Isolate.spawnUri(helperCopiedUri, [], [
        receivePort.sendPort,
        tempUri2.path,
      ], packageConfig: packageConfigUri);

      final result = (await receivePort.first);
      if (result != 49) {
        throw "Unexpected result: $result.";
      }
    });
  });
  print('invoke helper with packageConfig done');
}

Future<void> createTestFiles(Uri tempUri, Uri tempUri2) async {
  final helperCopiedUri = tempUri.resolve(helperName);
  await File.fromUri(helperSourceuri).copy(helperCopiedUri.toFilePath());
  print('File copied to $helperCopiedUri.');

  final helper2CopiedUri = tempUri2.resolve(helper2Name);
  await File.fromUri(helper2Sourceuri).copy(helper2CopiedUri.toFilePath());
  print('File copied to $helper2CopiedUri.');

  final dartToolsUri = tempUri.resolve('.dart_tool/');
  await Directory.fromUri(dartToolsUri).create();

  final packageConfigUri = dartToolsUri.resolve('package_config.json');
  await File.fromUri(packageConfigUri).writeAsString(emptyPackageConfig);

  final nativeAssetsYaml = createNativeAssetYaml(
    asset: helper2CopiedUri.toString(),
    assetMapping: ['absolute', ffiTestFunctionsUriAbsolute.toFilePath()],
  );
  final nativeAssetsUri = dartToolsUri.resolve('native_assets.yaml');
  await File.fromUri(nativeAssetsUri).writeAsString(nativeAssetsYaml);
  print('File native_assets.yaml written to $nativeAssetsUri.');
}
