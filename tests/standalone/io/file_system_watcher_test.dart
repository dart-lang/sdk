// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";


void testWatchCreateFile() {
  var dir = new Directory('').createTempSync();
  var file = new File(dir.path + '/file');

  var watcher = dir.watch();

  asyncStart();
  var sub;
  sub = watcher.listen((event) {
    if (event is FileSystemCreateEvent &&
        event.path.endsWith('file')) {
      asyncEnd();
      sub.cancel();
      dir.deleteSync(recursive: true);
    }
  }, onError: (e) {
    dir.deleteSync(recursive: true);
    throw e;
  });

  runAsync(file.createSync);
}


void testWatchModifyFile() {
  var dir = new Directory('').createTempSync();
  var file = new File(dir.path + '/file');
  file.createSync();

  var watcher = dir.watch();

  asyncStart();
  var sub;
  sub = watcher.listen((event) {
    if (event is FileSystemModifyEvent) {
      Expect.isTrue(event.path.endsWith('file'));
      sub.cancel();
      asyncEnd();
      dir.deleteSync(recursive: true);
    }
  }, onError: (e) {
    dir.deleteSync(recursive: true);
    throw e;
  });

  runAsync(() => file.writeAsStringSync('a'));
}


void testWatchMoveFile() {
  var dir = new Directory('').createTempSync();
  var file = new File(dir.path + '/file');
  file.createSync();

  var watcher = dir.watch();

  asyncStart();
  var sub;
  sub = watcher.listen((event) {
    if (event is FileSystemMoveEvent) {
      Expect.isTrue(event.path.endsWith('file'));
      if (event.destination != null) {
        Expect.isTrue(event.destination.endsWith('file2'));
      }
      sub.cancel();
      asyncEnd();
      dir.deleteSync(recursive: true);
    }
  }, onError: (e) {
    dir.deleteSync(recursive: true);
    throw e;
  });

  runAsync(() => file.renameSync(dir.path + '/file2'));
}


void testWatchDeleteFile() {
  var dir = new Directory('').createTempSync();
  var file = new File(dir.path + '/file');
  file.createSync();

  var watcher = dir.watch();

  asyncStart();
  var sub;
  sub = watcher.listen((event) {
    if (event is FileSystemDeleteEvent) {
      Expect.isTrue(event.path.endsWith('file'));
      sub.cancel();
      asyncEnd();
      dir.deleteSync(recursive: true);
    }
  }, onError: (e) {
    dir.deleteSync(recursive: true);
    throw e;
  });

  runAsync(file.deleteSync);
}


void testWatchOnlyModifyFile() {
  var dir = new Directory('').createTempSync();
  var file = new File(dir.path + '/file');

  var watcher = dir.watch(events: FileSystemEvent.MODIFY);

  asyncStart();
  var sub;
  sub = watcher.listen((event) {
    Expect.isTrue(event is FileSystemModifyEvent);
    Expect.isTrue(event.path.endsWith('file'));
    sub.cancel();
    asyncEnd();
    dir.deleteSync(recursive: true);
  }, onError: (e) {
    dir.deleteSync(recursive: true);
    throw e;
  });

  runAsync(() {
    file.createSync();
    file.writeAsStringSync('a');
  });
}


void testMultipleEvents() {
  var dir = new Directory('').createTempSync();
  var file = new File(dir.path + '/file');
  var file2 = new File(dir.path + '/file2');

  var watcher = dir.watch();

  asyncStart();
  int state = 0;
  var sub;
  sub = watcher.listen((event) {
    int newState = 0;
    switch (event.type) {
      case FileSystemEvent.CREATE:
        newState = 1;
        break;

      case FileSystemEvent.MODIFY:
        newState = 2;
        break;

      case FileSystemEvent.MOVE:
        newState = 3;
        break;

      case FileSystemEvent.DELETE:
        newState = 4;
        sub.cancel();
        asyncEnd();
        dir.deleteSync();
        break;
    }
    if (!Platform.isMacOS) {
      if (newState < state) throw "Bad state";
    }
    state = newState;
  });

  runAsync(() {
    file.createSync();
    file.writeAsStringSync('a');
    file.renameSync(file2.path);
    file2.deleteSync();
  });
}


void testWatchRecursive() {
  var dir = new Directory('').createTempSync();
  if (Platform.isLinux) {
    Expect.throws(() => dir.watch(recursive: true));
    return;
  }
  var dir2 = new Directory(dir.path + '/dir');
  dir2.createSync();
  var file = new File(dir.path + '/dir/file');

  var watcher = dir.watch(recursive: true);

  asyncStart();
  var sub;
  sub = watcher.listen((event) {
    if (event.path.endsWith('file')) {
      sub.cancel();
      asyncEnd();
      dir.deleteSync(recursive: true);
    }
  }, onError: (e) {
    dir.deleteSync(recursive: true);
    throw e;
  });

  runAsync(file.createSync());
}


void testWatchNonRecursive() {
  var dir = new Directory('').createTempSync();
  var dir2 = new Directory(dir.path + '/dir');
  dir2.createSync();
  var file = new File(dir.path + '/dir/file');

  var watcher = dir.watch(recursive: false);

  asyncStart();
  var sub;
  sub = watcher.listen((event) {
    if (event.path.endsWith('file')) {
      throw "File change event not expected";
    }
  }, onError: (e) {
    dir.deleteSync(recursive: true);
    throw e;
  });

  runAsync(file.createSync);

  new Timer(const Duration(milliseconds: 300), () {
    sub.cancel();
    asyncEnd();
    dir.deleteSync(recursive: true);
  });
}


void main() {
  if (!FileSystemEntity.isWatchSupported) return;
  testWatchCreateFile();
  testWatchModifyFile();
  testWatchMoveFile();
  testWatchDeleteFile();
  testWatchOnlyModifyFile();
  testMultipleEvents();
  testWatchNonRecursive();
}
