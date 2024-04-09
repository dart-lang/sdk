// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library callback_list_test;

import 'dart:html';
import 'dart:async';

import 'package:expect/minitest.dart';

var callbackDone = false;
bool isCallbackDone() => callbackDone;

Future waitUntilCallbackDone(bool test()) async {
  var completer = new Completer();
  check() {
    if (test()) {
      completer.complete();
    } else {
      new Timer(Duration.zero, check);
    }
  }

  check();
  return completer.future;
}

void main() async {
  window.navigator.persistentStorage!.requestQuota(1024 * 1024, _quotaHandler);

  await waitUntilCallbackDone(isCallbackDone);
  expect(true, isCallbackDone());
}

Future _quotaHandler(int byteCount) async {
  FileSystem filesystem =
      await window.requestFileSystem(1024 * 1024, persistent: true);
  DirectoryEntry dir = await filesystem.root!;
  DirectoryReader dirReader = dir.createReader();
  await dirReader.readEntries();
  List<Entry> secondEntries = await dirReader.readEntries();
  callbackDone = true;
}
