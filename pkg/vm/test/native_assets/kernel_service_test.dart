// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import '../../bin/kernel_service.dart';

import 'package:front_end/src/api_prototype/standard_file_system.dart';

void main() async {
  late Directory tempDir;
  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kernel_front_end_test');
  });

  tearDown(() {
    tempDir.delete(recursive: true);
  });

  test('find native_assets.yaml many folders up', () async {
    final dir5 =
        Directory.fromUri(tempDir.uri.resolve('dir1/dir2/dir3/dir4/dir5/'));
    await dir5.create(recursive: true);

    final dartFile = File.fromUri(dir5.uri.resolve('main.dart'));
    await dartFile.writeAsString('''
void main(){
  print('hello world!');
}
''');

    final dartToolDir = Directory.fromUri(tempDir.uri.resolve('.dart_tool/'));
    await dartToolDir.create(recursive: true);

    final packageConfigContents = '''{
  "configVersion": 2,
  "packages": [],
  "generated": "${DateTime.now()}",
  "generator": "test"
}
''';
    final packageConfigFile =
        File.fromUri(dartToolDir.uri.resolve('package_config.json'));
    await packageConfigFile.writeAsString(packageConfigContents);

    final nativeAssetsContents = '''
format-version: [1, 0, 0]
native-assets:
  linux_arm:
    "benchmarks/FfiCall/native-library":
      ["relative", "../native/out/linux/arm/libnative_functions.so"]
''';
    final nativeAssetsFile =
        File.fromUri(dartToolDir.uri.resolve('native_assets.yaml'));
    await nativeAssetsFile.writeAsString(nativeAssetsContents);

    final String? result = await findNativeAssets(
      script: dartFile.uri,
      fileSystem: StandardFileSystem.instance,
    );

    expect(result, nativeAssetsContents);
  });
}
