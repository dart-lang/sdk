// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Directory rename test.

// @dart = 2.9

import "dart:io";

import "package:expect/expect.dart";
import 'test_utils.dart' show withTempDir;

testRenameToNewPath() async {
  await withTempDir('testRenameToNewPath', (Directory tempDir) async {
    final dir1 = Directory("${tempDir.path}/dir1");
    dir1.createSync();

    dir1.renameSync("${tempDir.path}/dir2");
    Expect.isTrue(Directory("${tempDir.path}/dir2").existsSync());
  });
}

testRenameDoesNotAdjustPath() async {
  await withTempDir('testRenameToNewPath', (Directory tempDir) async {
    final dir1 = Directory("${tempDir.path}/dir1");
    dir1.createSync();
    final originalPath = dir1.path;

    dir1.renameSync("${tempDir.path}/dir2");
    final finalPath = dir1.path;
    Expect.isTrue(originalPath == finalPath,
        "$originalPath != $finalPath - path should not be updated");
  });
}

testRenameToSamePath() async {
  await withTempDir('testRenameToSamePath', (Directory tempDir) async {
    final dir = Directory("${tempDir.path}/dir");
    dir.createSync();
    final file = File("${dir.path}/file");
    file.createSync();

    try {
      dir.renameSync(dir.path);
      if (Platform.isWindows) {
        Expect.fail('Directory.rename to same path should fail on Windows');
      } else {
        Expect.isTrue(file.existsSync());
      }
    } on FileSystemException catch (e) {
      if (Platform.isWindows) {
        // On Windows, the directory will be *deleted*.
        Expect.isFalse(dir.existsSync());
        Expect.isTrue(
            e.osError.message.contains('cannot find the file specified'));
      } else {
        Expect.fail('Directory.rename to same path should not fail on '
            '${Platform.operatingSystem} (${Platform.operatingSystemVersion}): '
            '$e');
      }
    }
  });
}

testRenameToExistingFile() async {
  await withTempDir('testRenameToExistingFile', (Directory tempDir) async {
    final dir = Directory("${tempDir.path}/dir");
    dir.createSync();
    final file = File("${tempDir.path}/file");
    file.createSync();

    // Overwriting an exsting file is not allowed.
    try {
      dir.renameSync(file.path);
      Expect.fail('Directory.rename should fail to rename a non-directory');
    } on FileSystemException catch (e) {
      if (Platform.isLinux || Platform.isMacOS) {
        Expect.isTrue(e.osError.message.contains('Not a directory'));
      } else if (Platform.isWindows) {
        Expect.isTrue(e.osError.message.contains('file already exists'));
      }
    }
  });
}

testRenameToExistingEmptyDirectory() async {
  await withTempDir('testRenameToExistingEmptyDirectory',
      (Directory tempDir) async {
    final dir1 = Directory("${tempDir.path}/dir1");
    dir1.createSync();
    File("${dir1.path}/file").createSync();

    final dir2 = Directory("${tempDir.path}/dir2");
    dir2.createSync();

    dir1.renameSync(dir2.path);
    // Verify that the file contained in dir1 has been moved.
    Expect.isTrue(File("${dir2.path}/file").existsSync());
  });
}

testRenameToExistingNonEmptyDirectory() async {
  await withTempDir('testRenameToExistingNonEmptyDirectory',
      (Directory tempDir) async {
    final dir1 = Directory("${tempDir.path}/dir1");
    dir1.createSync();
    File("${dir1.path}/file1").createSync();

    final dir2 = Directory("${tempDir.path}/dir2");
    dir2.createSync();
    File("${dir2.path}/file2").createSync();

    try {
      dir1.renameSync(dir2.path);
      if (Platform.isWindows) {
        // Verify that the old directory is deleted.
        Expect.isTrue(File("${dir2.path}/file1").existsSync());
        Expect.isFalse(File("${dir2.path}/file2").existsSync());
      } else {
        Expect.fail(
            'Directory.rename should fail to rename a non-empty directory '
            'except on Windows');
      }
    } on FileSystemException catch (e) {
      if (Platform.isLinux || Platform.isMacOS) {
        Expect.isTrue(e.osError.message.contains('Directory not empty'));
      }
    }
  });
}

main() async {
  await testRenameToNewPath();
  await testRenameDoesNotAdjustPath();
  await testRenameToSamePath();
  await testRenameToExistingFile();
  await testRenameToExistingEmptyDirectory();
  await testRenameToExistingNonEmptyDirectory();
}
