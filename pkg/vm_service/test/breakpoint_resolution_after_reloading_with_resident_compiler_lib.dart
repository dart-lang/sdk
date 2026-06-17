// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer' show debugger;
import 'dart:io' show Directory, File;
import 'dart:isolate' as i;

import 'package:path/path.dart' show join;

import 'common/test_helper.dart';

const _v0Contents = '''
import 'dart:developer';
import 'dart:isolate';

void f() {
  print('V0.a');
}

Future<void> main([List<String> args = const <String>[]]) {
  print('READY');
  // Keep the isolate alive.
  RawReceivePort();
  debugger();
}
''';

Future<void> testeeMain() async {
  final tempDir = Directory.systemTemp.createTempSync();
  try {
    final rootLib = File(join(tempDir.path, 'main.dart'));
    rootLib.writeAsStringSync(_v0Contents);

    await i.Isolate.spawnUri(rootLib.uri, [], null, debugName: 'Test Main');
    debugger(); // LINE_A
    tempDir.deleteSync(recursive: true);
  } catch (_) {
    tempDir.deleteSync(recursive: true);
    rethrow;
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
