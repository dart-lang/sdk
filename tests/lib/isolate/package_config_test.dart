// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups
// VMOptions=--trace_shutdown
import 'dart:io';
import 'dart:isolate';

const String packageConfig = "foobar:///no/such/file/";
const String errorString = "IsolateSpawnException: Unable to spawn isolate:";
const String errorString2 = "Error when reading '$packageConfig'";

main([args, msg]) async {
  if (msg != null) {
    throw 'unreachable';
  }
  dynamic error;
  try {
    await Isolate.spawnUri(Platform.script, [], 'msg',
        packageConfig: Uri.parse('foobar:///no/such/file/'));
  } catch (e) {
    error = e;
  }
  if (error == null) throw 'Expected a Spawning error.';
  if (!'$error'.contains(errorString)) {
    throw 'Expected: $error to contain "$errorString"';
  }
  if (!'$error'.contains(errorString2)) {
    throw 'Expected: $error to contain "$errorString2"';
  }
}
