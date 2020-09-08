// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

import "dart:async";
import "dart:io";
import "dart:isolate";

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

void testWatchTruncateFile() {
  var dir = Directory.systemTemp.createTempSync('dart_file_system_watcher');
  var file = new File(join(dir.path, 'file'));
  file.writeAsStringSync('ab');
  var fileHandle = file.openSync(mode: FileMode.append);

  var watcher = dir.watch();

  asyncStart();
  var sub;
  sub = watcher.listen((event) {
    if (event is FileSystemModifyEvent) {
      Expect.isTrue(event.path.endsWith('file'));
      Expect.isTrue(event.contentChanged);
      sub.cancel();
      asyncEnd();
      fileHandle.closeSync();
      dir.deleteSync(recursive: true);
    }
  }, onError: (e) {
    dir.deleteSync(recursive: true);
    throw e;
  });

  fileHandle.truncateSync(1);
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
      final destination = event.destination;
      if (destination != null) {
        Expect.isTrue(destination.endsWith('file2'));
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
  watcher.listen((event) {
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

  var watcher = dir.watch(events: FileSystemEvent.modify);

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
      case FileSystemEvent.create:
        newState = 1;
        break;

      case FileSystemEvent.modify:
        newState = 2;
        break;

      case FileSystemEvent.move:
        newState = 3;
        break;

      case FileSystemEvent.delete:
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
  bool gotDelete = false;
  watcher.listen((event) {
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

testWatchConsistentModifiedFile() async {
  // When file modification starts before the watcher listen() is called and the first event
  // happens in a very short period of time the modifying event will be missed before the
  // stream listen has been set up and the watcher will hang forever.
  // Bug: https://github.com/dart-lang/sdk/issues/37233
  // Bug: https://github.com/dart-lang/sdk/issues/37909
  asyncStart();
  ReceivePort receivePort = ReceivePort();
  Completer<bool> exiting = Completer<bool>();

  late Directory dir;
  Completer<bool> modificationEventReceived = Completer<bool>();

  late StreamSubscription receiverSubscription;
  late SendPort workerSendPort;
  receiverSubscription = receivePort.listen((object) async {
    if (object == 'modification_started') {
      var watcher = dir.watch();
      var subscription;
      // Wait for event and check the type
      subscription = watcher.listen((data) async {
        if (data is FileSystemModifyEvent) {
          Expect.isTrue(data.path.endsWith('file'));
          await subscription.cancel();
          modificationEventReceived.complete(true);
        }
      });
      return;
    }
    if (object == 'end') {
      await receiverSubscription.cancel();
      exiting.complete(true);
      return;
    }
    // init event
    workerSendPort = object[0];
    dir = new Directory(object[1]);
  });

  Completer<bool> workerExitedCompleter = Completer();
  RawReceivePort exitReceivePort = RawReceivePort((object) {
    workerExitedCompleter.complete(true);
  });
  RawReceivePort errorReceivePort = RawReceivePort((object) {
    print('worker errored: $object');
  });
  Isolate isolate = await Isolate.spawn(modifyFiles, receivePort.sendPort,
      onExit: exitReceivePort.sendPort, onError: errorReceivePort.sendPort);

  await modificationEventReceived.future;
  workerSendPort.send('end');

  await exiting.future;
  await workerExitedCompleter.future;
  exitReceivePort.close();
  errorReceivePort.close();
  // Stop modifier isolate
  isolate.kill();
  asyncEnd();
}

void modifyFiles(SendPort sendPort) async {
  // Send sendPort back to listen for modification signal.
  ReceivePort receivePort = ReceivePort();
  var dir = Directory.systemTemp.createTempSync('dart_file_system_watcher');

  // Create file within the directory and keep modifying.
  var file = new File(join(dir.path, 'file'));
  file.createSync();
  bool done = false;
  var subscription;
  subscription = receivePort.listen((object) async {
    if (object == 'end') {
      await subscription.cancel();
      done = true;
    }
  });
  sendPort.send([receivePort.sendPort, dir.path]);
  bool notificationSent = false;
  while (!done) {
    // Start modifying the file continuously before watcher start watching.
    for (int i = 0; i < 100; i++) {
      file.writeAsStringSync('a');
    }
    if (!notificationSent) {
      sendPort.send('modification_started');
      notificationSent = true;
    }
    await Future.delayed(Duration());
  }
  // Clean up the directory and files
  dir.deleteSync(recursive: true);
  sendPort.send('end');
}

testWatchOverflow() async {
  // When underlying buffer for ReadDirectoryChangesW overflows(on Windows),
  // it will send an exception to Stream which has been listened.
  // Bug: https://github.com/dart-lang/sdk/issues/37233
  asyncStart();
  ReceivePort receivePort = ReceivePort();
  Completer<bool> exiting = Completer<bool>();

  Directory dir =
      Directory.systemTemp.createTempSync('dart_file_system_watcher');
  var file = new File(join(dir.path, 'file'));
  file.createSync();

  Isolate isolate =
      await Isolate.spawn(watcher, receivePort.sendPort, paused: true);

  var subscription;
  subscription = receivePort.listen((object) async {
    if (object == 'end') {
      exiting.complete(true);
      subscription.cancel();
      // Clean up the directory and files
      dir.deleteSync(recursive: true);
      asyncEnd();
    } else if (object == 'start') {
      isolate.pause(isolate.pauseCapability);
      // Populate the buffer to overflows and check for exception
      for (int i = 0; i < 2000; i++) {
        file.writeAsStringSync('a');
      }
      isolate.resume(isolate.pauseCapability!);
    }
  });
  // Resume paused isolate to create watcher
  isolate.resume(isolate.pauseCapability!);

  await exiting.future;
  isolate.kill();
}

void watcher(SendPort sendPort) async {
  runZonedGuarded(() {
    var watcher = Directory.systemTemp.watch(recursive: true);
    watcher.listen((data) async {});
    sendPort.send('start');
  }, (error, stack) {
    print(error);
    sendPort.send('end');
  });
}

void main() {
  if (!FileSystemEntity.isWatchSupported) return;
  testWatchCreateFile();
  testWatchCreateDir();
  testWatchModifyFile();
  testWatchMoveFile();
  testWatchTruncateFile();
  testWatchDeleteFile();
  testWatchDeleteDir();
  testWatchOnlyModifyFile();
  testMultipleEvents();
  testWatchNonRecursive();
  testWatchNonExisting();
  testWatchMoveSelf();
  testWatchConsistentModifiedFile();
  if (Platform.isWindows) testWatchOverflow();
}
