// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//
// Packages=.dart_tool/package_config.json
//

library package_isolate_test;

import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as path;

import 'pkgs/shared/shared.dart' as shared;

import '../../../pkg/async_helper/lib/async_helper.dart';
import '../../../pkg/expect/lib/expect.dart';

ReceivePort expectResponse() {
  asyncStart();
  var receivePort = new ReceivePort();
  receivePort.first.then((msg) {
    Expect.equals('isolate', msg);
    Expect.equals('main', shared.output);
    asyncEnd();
  });
  return receivePort;
}

void main() {
  // No support for tests that attempt to Isolate.spawnUri() in AOT of some
  // script other than self.
  if (path.basenameWithoutExtension(Platform.executable) ==
      "dart_precompiled_runtime") {
    return;
  }

  {
    final replyPort = expectResponse().sendPort;
    shared.output = 'main';
    Isolate.spawn(isolate_main, replyPort);
  }

  {
    // Package in spawnUri() of sibling file.
    var replyPort = expectResponse().sendPort;
    shared.output = 'main';
    Isolate.spawnUri(Uri.parse('sibling_isolate.dart'), [], replyPort);
  }

  {
    // Package in spawnUri() of file in folder.
    var replyPort = expectResponse().sendPort;
    shared.output = 'main';
    Isolate.spawnUri(
        Uri.parse('test_folder/folder_isolate.dart'), [], replyPort,
        packageConfig: Uri.parse(
            'tests/standalone/package/test_folder/.dart_tool/package_config.json'));
  }
}

void isolate_main(SendPort replyTo) {
  shared.output = 'isolate';
  (replyTo as SendPort).send(shared.output);
}
