// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

void testDeleteRecursiveRace() async {
  asyncStart();
  var temp = Directory.systemTemp.createTempSync('dart_directory_delete_race');

  // Create a bunch of files
  int numFiles = 2000;
  List<File> files = [];
  for (int i = 0; i < numFiles; i++) {
    var file = File('${temp.path}/file_$i.txt');
    file.createSync();
    files.add(file);
  }

  // Start deleting files individually in the background
  bool deleting = true;
  Future deleteFilesIndividually() async {
    for (var file in files) {
      if (!deleting) break;
      try {
        await file.delete();
      } catch (e) {
        // Ignore errors if the file is already deleted by recursive delete
      }
      // Yield to allow delete(recursive: true) to run
      await Future.delayed(Duration.zero);
    }
  }

  var individualDeleteFuture = deleteFilesIndividually();

  // Start recursive delete
  try {
    await temp.delete(recursive: true);
  } catch (e) {
    Expect.fail("Recursive delete failed: $e");
  } finally {
    deleting = false;
    await individualDeleteFuture;
  }

  Expect.isFalse(temp.existsSync());
  asyncEnd();
}

void testDeleteNonExistent() {
  asyncStart();
  var temp = Directory.systemTemp.createTempSync(
    'dart_directory_delete_non_existent',
  );
  var nonExistent = Directory('${temp.path}/non_existent');

  // Verify sync delete throws
  Expect.throws(
    () => nonExistent.deleteSync(recursive: true),
    (e) => e is PathNotFoundException,
  );

  // Verify async delete throws
  nonExistent
      .delete(recursive: true)
      .then(
        (_) {
          Expect.fail("Deletion of non-existing directory should fail");
        },
        onError: (error) {
          Expect.isTrue(error is PathNotFoundException);
          temp.deleteSync(recursive: true);
          asyncEnd();
        },
      );
}

void testFileDelete() {
  asyncStart();
  var temp = Directory.systemTemp.createTempSync('dart_file_delete_test');

  // Case 1: Non-existent file (Sync)
  var file1 = File('${temp.path}/file1.txt');
  Expect.throws(() => file1.deleteSync(), (e) => e is PathNotFoundException);

  // Case 2: Existing file (Sync)
  var file2 = File('${temp.path}/file2.txt');
  file2.createSync();
  Expect.isTrue(file2.existsSync());
  file2.deleteSync();
  Expect.isFalse(file2.existsSync());

  // Case 3: Non-existent file (Async)
  var file3 = File('${temp.path}/file3.txt');
  var p1 = file3.delete().then(
    (_) {
      Expect.fail("Deletion of non-existing file should fail");
    },
    onError: (error) {
      Expect.isTrue(error is PathNotFoundException);
    },
  );

  // Case 4: Existing file (Async)
  var file4 = File('${temp.path}/file4.txt');
  file4.createSync();
  Expect.isTrue(file4.existsSync());
  var p2 = file4.delete().then((_) {
    Expect.isFalse(file4.existsSync());
  });

  Future.wait([p1, p2]).then((_) {
    temp.deleteSync(recursive: true);
    asyncEnd();
  });
}

void main() {
  testDeleteNonExistent();
  testFileDelete();
  for (int i = 0; i < 5; i++) {
    testDeleteRecursiveRace();
  }
}
