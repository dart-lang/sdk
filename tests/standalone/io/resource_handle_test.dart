// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Most tests for [ResourceHandle] are in unix_socket_test.dart.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:expect/expect.dart';

import 'test_utils.dart' show throws, withTempDir;

Future testToCallsAfterFromFile(String tempDirPath) async {
  final file = File('$tempDirPath/sock1');

  await file.create();
  final openFile = await file.open();

  final handle = ResourceHandle.fromFile(openFile);

  handle.toFile().close();

  throws(handle.toFile, (e) => e is StateError);
  throws(handle.toRawDatagramSocket, (e) => e is StateError);
  throws(handle.toRawSocket, (e) => e is StateError);
  throws(handle.toSocket, (e) => e is StateError);
  throws(handle.toReadPipe, (e) => e is StateError);
  throws(handle.toWritePipe, (e) => e is StateError);
}

void main(List<String> args) async {
  if (!Platform.isMacOS && !Platform.isLinux && !Platform.isAndroid) {
    return;
  }

  await withTempDir('resource_handle_test', (Directory dir) async {
    await testToCallsAfterFromFile('${dir.path}');
  });
}
