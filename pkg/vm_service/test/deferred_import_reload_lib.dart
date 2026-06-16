// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io';
// ignore: library_prefixes
import 'dart:isolate' as I;

import 'package:path/path.dart' as path;

import 'common/test_helper.dart';

// Chop off the file name.
String baseDirectory = '${path.dirname(Platform.script.path)}/';

Uri baseUri = Platform.script.replace(path: baseDirectory);
Uri spawnUri =
    baseUri.resolveUri(Uri.parse('deferred_import_reload/v1/main.dart'));

Future<void> testMain() async {
  debugger(); // LINE_A

  final receivePort = I.ReceivePort();
  final completer = Completer<void>();
  late final StreamSubscription sub;
  sub = receivePort.listen((_) {
    completer.complete();
    sub.cancel();
    receivePort.close();
  });

  // Spawn the child isolate and wait for it to finish loading the deferred
  // library.
  await I.Isolate.spawnUri(spawnUri, [], receivePort.sendPort);
  await completer.future;
  debugger(); // LINE_B
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
