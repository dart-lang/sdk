// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--delayed-filewatch-callback

// Verifies that cancelling subscription from inside of the event handler
// works as expected, does not result in crash or hang.

import "dart:async";
import "dart:io";

import "package:path/path.dart";

final completer = Completer<void>();
var subscription;

void handleWatchEvent(event) {
  if (event is FileSystemCreateEvent && event.path.endsWith('txt')) {
    subscription.cancel();
    completer.complete();
  }
}

void main() async {
  if (!FileSystemEntity.isWatchSupported) return;
  final dir = Directory.systemTemp.createTempSync('dart_file_system_watcher');
  final watcher = dir.watch();
  subscription = watcher.listen(handleWatchEvent);

  print('watching ${dir.path}');
  for (int i = 0; i < 1000; i++) {
    File(join(dir.path, 'file_$i.txt')).createSync();
  }
  await completer.future;
  try {
    dir.deleteSync(recursive: true);
  } catch (_) {}
}
