// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";

void testWatchCreateFile() {
  var dir = Directory.systemTemp.createTempSync('dart_file_system_watcher');
  var file = new File(join(dir.path, 'file'));

  var watcher = dir.watch();

  asyncStart();
  var sub;
  sub = watcher.listen((event) {
    if (event is FileSystemCreateEvent && event.path.endsWith('file')) {
      Expect.isFalse(event.isDirectory);
      asyncEnd();
      sub.cancel();
      dir.deleteSync(recursive: true);
    }
  }, onError: (e) {
    dir.deleteSync(recursive: true);
    throw e;
  });

  file.createSync();
}

void testWatchCreateDir() {
  var dir = Directory.systemTemp.createTempSync('dart_file_system_watcher');
  var subdir = new Directory(join(dir.path, 'dir'));

  var watcher = dir.watch();

  asyncStart();
  var sub;
  sub = watcher.listen((event) {
    if (event is FileSystemCreateEvent && event.path.endsWith('dir')) {
      Expect.isTrue(event.isDirectory);
      asyncEnd();
      sub.cancel();
      dir.deleteSync(recursive: true);
    }
  }, onError: (e) {
    dir.deleteSync(recursive: true);
    throw e;
  });

  subdir.createSync();
}

void testWatchModifyFile() {
  var dir = Directory.systemTemp.createTempSync('dart_file_system_watcher');
  var file = new File(join(dir.path, 'file'));
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

  file.writeAsStringSync('a');
}

void testWatchMoveFile() {
  // Mac OS doesn't report move events.
  if (Platform.isMacOS) return;
  var dir = Directory.systemTemp.createTempSync('dart_file_system_watcher');
  var file = new File(join(dir.path, 'file'));
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

  file.renameSync(join(dir.path, 'file2'));
}

void testWatchDeleteFile() {
  var dir = Directory.systemTemp.createTempSync('dart_file_system_watcher');
  var file = new File(join(dir.path, 'file'));
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

  file.deleteSync();
}

void testWatchDeleteDir() {
  // Windows keeps the directory handle open, even though it's deleted. It'll
  // be flushed completely, once the watcher is closed as well.
  if (Platform.isWindows) return;
  var dir = Directory.systemTemp.createTempSync('dart_file_system_watcher');
  var watcher = dir.watch(events: 0);

  asyncStart();
  var sub;
  sub = watcher.listen((event) {
    if (event is FileSystemDeleteEvent) {
      Expect.isTrue(event.path == dir.path);
    }
  }, onDone: () {
    asyncEnd();
  });

  dir.deleteSync();
}

void testWatchOnlyModifyFile() {
  var dir = Directory.systemTemp.createTempSync('dart_file_system_watcher');
  var file = new File(join(dir.path, 'file'));

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

  file.createSync();
  file.writeAsStringSync('a');
}

void testMultipleEvents() {
  var dir = Directory.systemTemp.createTempSync('dart_file_system_watcher');
  var file = new File(join(dir.path, 'file'));
  var file2 = new File(join(dir.path, 'file2'));

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

  file.createSync();
  file.writeAsStringSync('a');
  file.renameSync(file2.path);
  file2.deleteSync();
}

void testWatchRecursive() {
  var dir = Directory.systemTemp.createTempSync('dart_file_system_watcher');
  if (Platform.isLinux) {
    Expect.throws(() => dir.watch(recursive: true));
    return;
  }
  var dir2 = new Directory(join(dir.path, 'dir'));
  dir2.createSync();
  var file = new File(join(dir.path, 'dir/file'));

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

  file.createSync();
}

void testWatchNonRecursive() {
  var dir = Directory.systemTemp.createTempSync('dart_file_system_watcher');
  var dir2 = new Directory(join(dir.path, 'dir'));
  dir2.createSync();
  var file = new File(join(dir.path, 'dir/file'));

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

  file.createSync();

  new Timer(const Duration(milliseconds: 300), () {
    sub.cancel();
    asyncEnd();
    dir.deleteSync(recursive: true);
  });
}

void testWatchNonExisting() {
  // MacOS allows listening on non-existing paths.
  if (Platform.isMacOS) return;
  asyncStart();
  new Directory('__some_none_existing_dir__').watch().listen((_) {
    Expect.fail('unexpected error');
  }, onError: (e) {
    asyncEnd();
    Expect.isTrue(e is FileSystemException);
  });
}

void testWatchMoveSelf() {
  // Windows keeps the directory handle open, even though it's deleted. It'll
  // be flushed completely, once the watcher is closed as well.
  if (Platform.isWindows) return;
  var dir = Directory.systemTemp.createTempSync('dart_file_system_watcher');
  var dir2 = new Directory(join(dir.path, 'dir'))..createSync();

  var watcher = dir2.watch();

  asyncStart();
  var sub;
  bool gotDelete = false;
  sub = watcher.listen((event) {
    if (event is FileSystemDeleteEvent) {
      Expect.isTrue(event.path.endsWith('dir'));
      gotDelete = true;
    }
  }, onDone: () {
    Expect.isTrue(gotDelete);
    dir.deleteSync(recursive: true);
    asyncEnd();
  });

  dir2.renameSync(join(dir.path, 'new_dir'));
}

void main() {
  if (!FileSystemEntity.isWatchSupported) return;
  testWatchCreateFile();
  testWatchCreateDir();
  testWatchModifyFile();
  testWatchMoveFile();
  testWatchDeleteFile();
  testWatchDeleteDir();
  testWatchOnlyModifyFile();
  testMultipleEvents();
  testWatchNonRecursive();
  testWatchNonExisting();
  testWatchMoveSelf();
}
