// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that file system APIs handle (long) UNC paths correctly on Windows
// and that two phase `File::Copy` implementation (which first creates a
// temporary file and then replaces the destination) uses correct location
// for temporary file.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as p;

// Run a number of tests using the given [filePath]: create the file,
// copy it to [anotherFilePath], rename it to [anotherFilePath] and then
// rename it back to [filePath].
void testFilePath(String filePath, String anotherFilePath) {
  void checkContent(File f) {
    Expect.isTrue(f.existsSync());
    Expect.equals(filePath, f.readAsStringSync());
  }

  final f = File(filePath);
  f.writeAsStringSync(filePath);
  checkContent(f);
  f.copySync(anotherFilePath);
  checkContent(File(anotherFilePath));
  File(anotherFilePath).deleteSync();
  Expect.isFalse(File(anotherFilePath).existsSync());
  f.renameSync(anotherFilePath);
  checkContent(File(anotherFilePath));
  File(anotherFilePath).renameSync(f.path);
  checkContent(f);
  f.deleteSync();
  Expect.isFalse(f.existsSync());
}

// Verify a sequence of events induced by [testFilePath] in the temporary
// directory [subdirPath], which servers as parent folder for `anotherFilePath`.
void verifyEvents(List<FileSystemEvent> events, String anotherFilePath) {
  // We expect `f.copySync(anotherFilePath)` to create a temporary file in
  // [subdirPath] and then overwrite `anotherFilePath` with it.
  Expect.isTrue(events[0] is FileSystemCreateEvent);
  Expect.isTrue(
      events[1] is FileSystemModifyEvent && events[1].path == events[0].path);
  Expect.isTrue(
      events[2] is FileSystemModifyEvent && events[2].path == events[0].path);
  Expect.isTrue(events[3] is FileSystemMoveEvent &&
      events[3].path == events[0].path &&
      (events[3] as FileSystemMoveEvent).destination == anotherFilePath);
  // File(anotherFilePath).deleteSync();
  Expect.isTrue(
      events[4] is FileSystemDeleteEvent && events[4].path == anotherFilePath);
  // f.renameSync(anotherFilePath);
  Expect.isTrue(
      events[5] is FileSystemCreateEvent && events[5].path == anotherFilePath);
  // File(anotherFilePath).deleteSync();
  Expect.isTrue(
      events[6] is FileSystemDeleteEvent && events[6].path == anotherFilePath);
}

// Convert `C:\x\y\z` to `\\localhost\C$\x\y\z`.
String toUnc(String path) =>
    r'\\localhost\' + path[0] + r'$' + path.substring(2);

void main() async {
  // This is Windows only test.
  if (!Platform.isWindows) {
    return;
  }

  final temp = Directory.systemTemp.createTempSync().absolute;
  try {
    print(temp.path);
    print(temp.path.length);

    final subdir1Path = p.join(temp.path, 'x' * (251 - temp.path.length));
    Directory(subdir1Path).createSync();
    Expect.isTrue(Directory(subdir1Path).existsSync());

    final subdir2Path = p.join(temp.path, 'y' * (251 - temp.path.length));
    Directory(subdir2Path).createSync();
    Expect.isTrue(Directory(subdir2Path).existsSync());

    final subdir1Events = Directory(subdir1Path)
        .watch(recursive: true)
        .takeWhile((event) => !event.path.contains('TEST_DONE'))
        .toList();

    final subdir2Events = Directory(subdir2Path)
        .watch(recursive: true)
        .takeWhile((event) => !event.path.contains('TEST_DONE'))
        .toList();

    // Make UNC path by replacing X: with \\localhost\X$\
    final tempPathUnc = toUnc(temp.path);
    print(tempPathUnc);
    Expect.isTrue(Directory(tempPathUnc).existsSync());
    testFilePath(
      p.join(temp.path, 'a' * (250 - temp.path.length)),
      p.join(subdir1Path, 'f'),
    );

    // Note: WinAPI seems to refuse to move file from UNC path into non-UNC
    // path event though they actually point to the same physical drive.
    testFilePath(
      p.join(tempPathUnc, 'a' * (250 - temp.path.length)),
      toUnc(p.join(subdir2Path, 'f')),
    );

    // Signal test completion to file system event watchers.
    File(p.join(subdir1Path, 'TEST_DONE')).writeAsStringSync('TEST_DONE');
    File(p.join(subdir2Path, 'TEST_DONE')).writeAsStringSync('TEST_DONE');

    // Verify collected events.
    verifyEvents(await subdir1Events, p.join(subdir1Path, 'f'));
    verifyEvents(await subdir2Events, p.join(subdir2Path, 'f'));
  } finally {
    temp.deleteSync(recursive: true);
  }
}
