// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Directory rename test.

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

testRenamePath() async {
  // Verifies that the returned directory has the correct path.
  await withTempDir('testRenameToNewPath', (Directory tempDir) async {
    final oldDir = Directory("${tempDir.path}/dir1");
    oldDir.createSync();

    final newDir = oldDir.renameSync("${tempDir.path}/dir2");

    Expect.isTrue(
        oldDir.path == "${tempDir.path}/dir1",
        "${oldDir.path} != '${tempDir.path}/dir1'"
        "- path should not be updated");
    Expect.isTrue(
        newDir.path == "${tempDir.path}/dir2",
        "${newDir.path} != '${tempDir.path}/dir2'"
        "- path should be updated");
  });
}

testRenameToSamePath() async {
  await withTempDir('testRenameToSamePath', (Directory tempDir) async {
    final dir = Directory("${tempDir.path}/dir");
    dir.createSync();
    final file = File("${dir.path}/file");
    file.createSync();

    dir.renameSync(dir.path);
    Expect.isTrue(file.existsSync());
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
      if (Platform.isWindows) {
        Expect.isTrue(e.osError!.message.contains('file already exists'),
            'Unexpected error: $e');
      } else if (Platform.isLinux || Platform.isMacOS) {
        Expect.isTrue(e.osError!.message.contains('Not a directory'),
            'Unexpected error: $e');
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

    try {
      dir1.renameSync(dir2.path);
      // Verify that the file contained in dir1 has been moved.
      if (Platform.isWindows) {
        Expect.fail(
            'Directory.rename should fail to rename over an existing directory '
            'on Windows');
      } else {
        Expect.isTrue(File("${dir2.path}/file").existsSync());
      }
    } on FileSystemException catch (e) {
      if (Platform.isWindows) {
        Expect.isTrue(e.osError!.message.contains('file already exists'));
      } else {
        Expect.fail('Directory.rename should allow moves to empty directories');
      }
    }
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
      Expect.fail(
          'Directory.rename should fail to rename a non-empty directory');
    } on FileSystemException catch (e) {
      if (Platform.isWindows) {
        Expect.isTrue(e.osError!.message.contains('file already exists'),
            'Unexpected error: $e');
      } else if (Platform.isLinux || Platform.isMacOS) {
        Expect.isTrue(e.osError!.message.contains('Directory not empty'),
            'Unexpected error: $e');
      }
    }
  });
}

testRenameButActuallyFile() async {
  await withTempDir('testRenameButActuallyFile', (Directory tempDir) async {
    final file = File("${tempDir.path}/file");
    file.createSync();
    final dir = Directory(file.path);
    try {
      dir.renameSync("${tempDir.path}/dir");
      Expect.fail("Expected a failure to rename the file.");
    } on FileSystemException catch (e) {
      Expect.isTrue(
          e.message.contains('Rename failed'), 'Unexpected error: $e');
      if (Platform.isWindows) {
        Expect.isTrue(e.osError!.message.contains('cannot find the file'),
            'Unexpected error: $e');
      } else if (Platform.isLinux || Platform.isMacOS) {
        Expect.isTrue(e.osError!.message.contains('Not a directory'),
            'Unexpected error: $e');
      }
    }
  });
}

main() async {
  await testRenameToNewPath();
  await testRenamePath();
  await testRenameToSamePath();
  await testRenameToExistingFile();
  await testRenameToExistingEmptyDirectory();
  await testRenameToExistingNonEmptyDirectory();
  await testRenameButActuallyFile();
}
