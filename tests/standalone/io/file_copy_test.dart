// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing File.copy*

import 'dart:io';
import 'dart:ffi' as ffi;

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";
import 'package:ffi/ffi.dart';

const FILE_CONTENT1 = 'some string';
const FILE_CONTENT2 = 'some other string';

@ffi.Native<ffi.Int Function(ffi.Pointer<ffi.Char>, ffi.Int)>()
external int mkfifo(ffi.Pointer<ffi.Char> pathname, int mode);

void testFifo() async {
  var tmp = Directory.systemTemp.createTempSync('copy-fifo');
  if (!Platform.isLinux) {
    return;
  }

  using((arena) {
    // 432 => rw-rw----
    if (mkfifo("${tmp.path}/fifo".toNativeUtf8(allocator: arena).cast(), 432) ==
        -1) {
      throw FileSystemException('error creating FIFO');
    }
  });

  final write = File("${tmp.path}/fifo").writeAsString("Hello World!");
  final copy = File("${tmp.path}/fifo").copy("${tmp.path}/copy");
  await Future.wait([write, copy]);
  Expect.equals("Hello World!", File("${tmp.path}/copy").readAsStringSync());
  tmp.deleteSync(recursive: true);
}

void testCopySync() {
  var tmp = Directory.systemTemp.createTempSync('dart-file-copy');

  var file1 = new File('${tmp.path}/file1');
  file1.writeAsStringSync(FILE_CONTENT1);
  Expect.equals(FILE_CONTENT1, file1.readAsStringSync());

  // Copy to new file works.
  var file2 = file1.copySync('${tmp.path}/file2');
  Expect.equals(FILE_CONTENT1, file1.readAsStringSync());
  Expect.equals(FILE_CONTENT1, file2.readAsStringSync());

  // Override works for files.
  file2.writeAsStringSync(FILE_CONTENT2);
  file2.copySync(file1.path);
  Expect.equals(FILE_CONTENT2, file1.readAsStringSync());
  Expect.equals(FILE_CONTENT2, file2.readAsStringSync());

  // Check there is no temporary files existing.
  var list = tmp.listSync();
  Expect.equals(2, list.length);
  for (var file in list) {
    final fileName = file.path.toString();
    Expect.isTrue(fileName.contains("file1") || fileName.contains("file2"));
  }

  // Fail when coping to directory.
  var dir = new Directory('${tmp.path}/dir')..createSync();
  Expect.throws(() => file1.copySync(dir.path));
  Expect.equals(FILE_CONTENT2, file1.readAsStringSync());

  Directory('${tmp.path}/abc').createSync();
  // Copy to new file works.
  var file3 = file1.copySync('${tmp.path}/abc/../file3');
  Expect.equals(FILE_CONTENT2, file1.readAsStringSync());
  Expect.equals(FILE_CONTENT2, file3.readAsStringSync());

  tmp.deleteSync(recursive: true);
}

void testWithForwardSlashes() {
  if (Platform.isWindows) {
    final tmp = Directory.systemTemp.createTempSync('dart-file-copy');

    final file1 = File('${tmp.path}/file1');
    file1.writeAsStringSync(FILE_CONTENT1);
    Expect.equals(FILE_CONTENT1, file1.readAsStringSync());

    // Test with a path contains only forward slashes.
    final dest = tmp.path.toString().replaceAll("\\", "/");
    final file2 = file1.copySync('${dest}/file2');
    Expect.equals(FILE_CONTENT1, file2.readAsStringSync());

    // Test with a path mixing both forward and backward slashes.
    final file3 = file1.copySync('${dest}\\file3');
    Expect.equals(FILE_CONTENT1, file3.readAsStringSync());

    // Clean up the directory
    tmp.deleteSync(recursive: true);
  }
}

void testCopy() {
  asyncStart();
  var tmp = Directory.systemTemp.createTempSync('dart-file-copy');

  var file1 = new File('${tmp.path}/file1');
  file1.writeAsStringSync(FILE_CONTENT1);
  Expect.equals(FILE_CONTENT1, file1.readAsStringSync());

  // Copy to new file works.
  file1
      .copy('${tmp.path}/file2')
      .then((file2) {
        Expect.equals(FILE_CONTENT1, file1.readAsStringSync());
        Expect.equals(FILE_CONTENT1, file2.readAsStringSync());

        // Override works for files.
        file2.writeAsStringSync(FILE_CONTENT2);
        return file2.copy(file1.path).then((_) {
          Expect.equals(FILE_CONTENT2, file1.readAsStringSync());
          Expect.equals(FILE_CONTENT2, file2.readAsStringSync());

          // Fail when coping to directory.
          var dir = new Directory('${tmp.path}/dir')..createSync();

          return file1
              .copy(dir.path)
              .then((_) => Expect.fail('expected error'), onError: (_) {})
              .then((_) {
                Expect.equals(FILE_CONTENT2, file1.readAsStringSync());
              });
        });
      })
      .whenComplete(() {
        tmp.deleteSync(recursive: true);
        asyncEnd();
      });
}

main() {
  testCopySync();
  testCopy();
  testFifo();
  // This is Windows only test.
  testWithForwardSlashes();
}
