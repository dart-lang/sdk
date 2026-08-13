// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherResources=simple_reload/v1/main.dart simple_reload/v2/main.dart

import 'dart:async';
import 'dart:developer';
import 'dart:io';
// ignore: library_prefixes
import 'dart:isolate' as I;

import 'package:path/path.dart' as path;

import 'common/test_helper.dart';

// Chop off the file name.
final baseDirectory = '${path.dirname(Platform.script.path)}/';

final baseUri = Platform.script.replace(path: baseDirectory);
final spawnUri = baseUri.resolveUri(Uri.parse('simple_reload/v1/main.dart'));
final v2Uri = baseUri.resolveUri(Uri.parse('simple_reload/v2/main.dart'));

Future<void> testMain() async {
  print(baseUri);
  debugger(); // LINE_A
  // Spawn the child isolate.
  final I.Isolate isolate = await I.Isolate.spawnUri(spawnUri, [], null);
  print(isolate);
  debugger(); // LINE_B
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
