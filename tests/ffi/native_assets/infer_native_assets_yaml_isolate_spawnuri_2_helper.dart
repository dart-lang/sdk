// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

Future<void> main(List<String> args, Object? message) async {
  final list = message as List;
  final sendPort = list[0] as SendPort;
  final tempUri2 = Uri(path: list[1] as String);
  await invokeHelper2(sendPort, tempUri2);
}

const helper2Name = 'infer_native_assets_yaml_isolate_spawnuri_2_helper_2.dart';
final helper2Sourceuri = Platform.script.resolve(helper2Name);

Future<void> invokeHelper2(SendPort sendPort, Uri tempUri2) async {
  print('invoke helper 2 without packageConfig');

  final helper2CopiedUri = tempUri2.resolve(helper2Name);

  final receivePort = ReceivePort();
  await Isolate.spawnUri(helper2CopiedUri, [], receivePort.sendPort);

  final result = (await receivePort.first);
  sendPort.send(result);
  if (result != 49) {
    throw "Unexpected result: $result.";
  }
  print('invoke helper 2 without packageConfig done');
}
