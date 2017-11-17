// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=file_lock_script.dart

import 'dart:async';
import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";

// Check whether the file is locked or not.
check(String path, int start, int end, FileLock mode, {bool locked}) {
  // Client process returns either 'LOCK FAILED' or 'LOCK SUCCEEDED'.
  var expected = locked ? 'LOCK FAILED' : 'LOCK SUCCEEDED';
  var arguments = <String>[]
    ..addAll(Platform.executableArguments)
    ..add(Platform.script.resolve('file_lock_script.dart').toFilePath())
    ..add(path)
    ..add(mode == FileLock.EXCLUSIVE ? 'EXCLUSIVE' : 'SHARED')
    ..add('$start')
    ..add('$end');
  return Process
      .run(Platform.executable, arguments)
      .then((ProcessResult result) {
    if (result.exitCode != 0 || !result.stdout.contains(expected)) {
      print("Client failed, exit code ${result.exitCode}");
      print("  stdout:");
      print(result.stdout);
      print("  stderr:");
      print(result.stderr);
      print("  arguments:");
      print(arguments);
      Expect.fail('Client subprocess exit code: ${result.exitCode}');
    }
  });
}

checkLocked(String path,
        [int start = 0, int end = -1, FileLock mode = FileLock.EXCLUSIVE]) =>
    check(path, start, end, mode, locked: true);

checkNotLocked(String path,
        [int start = 0, int end = -1, FileLock mode = FileLock.EXCLUSIVE]) =>
    check(path, start, end, mode, locked: false);

void testLockWholeFile() {
  Directory directory = Directory.systemTemp.createTempSync('dart_file_lock');
  File file = new File(join(directory.path, "file"));
  file.writeAsBytesSync(new List.filled(10, 0));
  var raf = file.openSync(mode: WRITE);
  raf.lockSync();
  asyncStart();
  checkLocked(file.path).then((_) {
    return checkLocked(file.path, 0, 2).then((_) {
      raf.unlockSync();
      return checkNotLocked(file.path).then((_) {});
    });
  }).whenComplete(() {
    raf.closeSync();
    directory.deleteSync(recursive: true);
    asyncEnd();
  });
}

void testLockWholeFileAsync() {
  Directory directory = Directory.systemTemp.createTempSync('dart_file_lock');
  File file = new File(join(directory.path, "file"));
  file.writeAsBytesSync(new List.filled(10, 0));
  var raf = file.openSync(mode: WRITE);
  asyncStart();
  Future.forEach([
    () => raf.lock(),
    () => checkLocked(file.path, 0, 2),
    () => checkLocked(file.path),
    () => raf.unlock(),
    () => checkNotLocked(file.path),
  ], (f) => f()).whenComplete(() {
    raf.closeSync();
    directory.deleteSync(recursive: true);
    asyncEnd();
  });
}

void testLockRange() {
  Directory directory = Directory.systemTemp.createTempSync('dart_file_lock');
  File file = new File(join(directory.path, "file"));
  file.writeAsBytesSync(new List.filled(10, 0));
  var raf1 = file.openSync(mode: WRITE);
  var raf2 = file.openSync(mode: WRITE);
  asyncStart();
  var tests = [
    () => raf1.lockSync(FileLock.EXCLUSIVE, 2, 3),
    () => raf2.lockSync(FileLock.EXCLUSIVE, 5, 7),
    () => checkNotLocked(file.path, 0, 2),
    () => checkLocked(file.path, 0, 3),
    () => checkNotLocked(file.path, 4, 5),
    () => checkLocked(file.path, 4, 6),
    () => checkLocked(file.path, 6),
    () => checkNotLocked(file.path, 7),
    () => raf1.unlockSync(2, 3),
    () => checkNotLocked(file.path, 0, 5),
    () => checkLocked(file.path, 4, 6),
    () => checkLocked(file.path, 6),
    () => checkNotLocked(file.path, 7),
  ];
  // On Windows regions unlocked must match regions locked.
  if (!Platform.isWindows) {
    tests.addAll([
      () => raf1.unlockSync(5, 6),
      () => checkNotLocked(file.path, 0, 6),
      () => checkLocked(file.path, 6),
      () => checkNotLocked(file.path, 7),
      () => raf2.unlockSync(6, 7),
      () => checkNotLocked(file.path)
    ]);
  } else {
    tests
        .addAll([() => raf2.unlockSync(5, 7), () => checkNotLocked(file.path)]);
  }
  Future.forEach(tests, (f) => f()).whenComplete(() {
    raf1.closeSync();
    raf2.closeSync();
    directory.deleteSync(recursive: true);
    asyncEnd();
  });
}

void testLockRangeAsync() {
  Directory directory = Directory.systemTemp.createTempSync('dart_file_lock');
  File file = new File(join(directory.path, "file"));
  file.writeAsBytesSync(new List.filled(10, 0));
  var raf1 = file.openSync(mode: WRITE);
  var raf2 = file.openSync(mode: WRITE);
  asyncStart();
  var tests = [
    () => raf1.lock(FileLock.EXCLUSIVE, 2, 3),
    () => raf2.lock(FileLock.EXCLUSIVE, 5, 7),
    () => checkNotLocked(file.path, 0, 2),
    () => checkLocked(file.path, 0, 3),
    () => checkNotLocked(file.path, 4, 5),
    () => checkLocked(file.path, 4, 6),
    () => checkLocked(file.path, 6),
    () => checkNotLocked(file.path, 7),
    () => raf1.unlock(2, 3),
    () => checkNotLocked(file.path, 0, 5),
    () => checkLocked(file.path, 4, 6),
    () => checkLocked(file.path, 6),
    () => checkNotLocked(file.path, 7),
  ];
  // On Windows regions unlocked must match regions locked.
  if (!Platform.isWindows) {
    tests.addAll([
      () => raf1.unlock(5, 6),
      () => checkNotLocked(file.path, 0, 6),
      () => checkLocked(file.path, 6),
      () => checkNotLocked(file.path, 7),
      () => raf2.unlock(6, 7),
      () => checkNotLocked(file.path)
    ]);
  } else {
    tests.addAll([() => raf2.unlock(5, 7), () => checkNotLocked(file.path)]);
  }
  Future.forEach(tests, (f) => f()).whenComplete(() {
    raf1.closeSync();
    raf2.closeSync();
    directory.deleteSync(recursive: true);
    asyncEnd();
  });
}

void testLockEnd() {
  Directory directory = Directory.systemTemp.createTempSync('dart_file_lock');
  File file = new File(join(directory.path, "file"));
  file.writeAsBytesSync(new List.filled(10, 0));
  var raf = file.openSync(mode: APPEND);
  asyncStart();
  Future.forEach([
    () => raf.lockSync(FileLock.EXCLUSIVE, 2),
    () => checkNotLocked(file.path, 0, 2),
    () => checkLocked(file.path, 0, 3),
    () => checkLocked(file.path, 9),
    () => raf.writeFromSync(new List.filled(10, 0)),
    () => checkLocked(file.path, 10),
    () => checkLocked(file.path, 19),
    () => raf.unlockSync(2),
    () => checkNotLocked(file.path)
  ], (f) => f()).whenComplete(() {
    raf.closeSync();
    directory.deleteSync(recursive: true);
    asyncEnd();
  });
}

void testLockEndAsync() {
  Directory directory = Directory.systemTemp.createTempSync('dart_file_lock');
  File file = new File(join(directory.path, "file"));
  file.writeAsBytesSync(new List.filled(10, 0));
  var raf = file.openSync(mode: APPEND);
  asyncStart();
  Future.forEach([
    () => raf.lock(FileLock.EXCLUSIVE, 2),
    () => checkNotLocked(file.path, 0, 2),
    () => checkLocked(file.path, 0, 3),
    () => checkLocked(file.path, 9),
    () => raf.writeFromSync(new List.filled(10, 0)),
    () => checkLocked(file.path, 10),
    () => checkLocked(file.path, 19),
    () => raf.unlock(2),
    () => checkNotLocked(file.path)
  ], (f) => f()).whenComplete(() {
    raf.closeSync();
    directory.deleteSync(recursive: true);
    asyncEnd();
  });
}

void testLockShared() {
  Directory directory = Directory.systemTemp.createTempSync('dart_file_lock');
  File file = new File(join(directory.path, "file"));
  file.writeAsBytesSync(new List.filled(10, 0));
  var raf = file.openSync();
  asyncStart();
  Future.forEach([
    () => raf.lock(FileLock.SHARED),
    () => checkLocked(file.path),
    () => checkLocked(file.path, 0, 2),
    () => checkNotLocked(file.path, 0, 2, FileLock.SHARED)
  ], (f) => f()).then((_) {
    raf.closeSync();
    directory.deleteSync(recursive: true);
    asyncEnd();
  });
}

void testLockSharedAsync() {
  Directory directory = Directory.systemTemp.createTempSync('dart_file_lock');
  File file = new File(join(directory.path, "file"));
  file.writeAsBytesSync(new List.filled(10, 0));
  var raf = file.openSync();
  asyncStart();
  Future.forEach([
    () => raf.lock(FileLock.SHARED),
    () => checkLocked(file.path),
    () => checkLocked(file.path, 0, 2),
    () => checkNotLocked(file.path, 0, 2, FileLock.SHARED)
  ], (f) => f()).whenComplete(() {
    raf.closeSync();
    directory.deleteSync(recursive: true);
    asyncEnd();
  });
}

void testLockAfterLength() {
  Directory directory = Directory.systemTemp.createTempSync('dart_file_lock');
  File file = new File(join(directory.path, "file"));
  file.writeAsBytesSync(new List.filled(10, 0));
  var raf = file.openSync(mode: APPEND);
  asyncStart();
  Future.forEach([
    () => raf.lockSync(FileLock.EXCLUSIVE, 2, 15),
    () => checkNotLocked(file.path, 0, 2),
    () => checkLocked(file.path, 0, 3),
    () => checkLocked(file.path, 9),
    () => checkLocked(file.path, 14),
    () => raf.writeFromSync(new List.filled(10, 0)),
    () => checkLocked(file.path, 10),
    () => checkNotLocked(file.path, 15),
    () => raf.unlockSync(2, 15),
    () => checkNotLocked(file.path)
  ], (f) => f()).whenComplete(() {
    raf.closeSync();
    directory.deleteSync(recursive: true);
    asyncEnd();
  });
}

void testLockAfterLengthAsync() {
  Directory directory = Directory.systemTemp.createTempSync('dart_file_lock');
  File file = new File(join(directory.path, "file"));
  file.writeAsBytesSync(new List.filled(10, 0));
  var raf = file.openSync(mode: APPEND);
  asyncStart();
  Future.forEach([
    () => raf.lock(FileLock.EXCLUSIVE, 2, 15),
    () => checkNotLocked(file.path, 0, 2),
    () => checkLocked(file.path, 0, 3),
    () => checkLocked(file.path, 9),
    () => checkLocked(file.path, 14),
    () => raf.writeFromSync(new List.filled(10, 0)),
    () => checkLocked(file.path, 10),
    () => checkNotLocked(file.path, 15),
    () => raf.unlock(2, 15),
    () => checkNotLocked(file.path)
  ], (f) => f()).whenComplete(() {
    raf.closeSync();
    directory.deleteSync(recursive: true);
    asyncEnd();
  });
}

void main() {
  testLockWholeFile();
  testLockWholeFileAsync();
  testLockRange();
  testLockRangeAsync();
  testLockEnd();
  testLockEndAsync();
  testLockShared();
  testLockSharedAsync();
  testLockAfterLength();
  testLockAfterLengthAsync();
}
