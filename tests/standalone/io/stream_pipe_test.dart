// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherResources=readline_test1.dat
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

// Helper method to be able to run the test from the runtime
// directory, or the top directory.
String getDataFilename(String path) =>
    Platform.script.resolve(path).toFilePath();

bool compareFileContent(String fileName1, String fileName2,
    {int file1Offset: 0, int file2Offset: 0, int count}) {
  var file1 = new File(fileName1).openSync();
  var file2 = new File(fileName2).openSync();
  var length1 = file1.lengthSync();
  var length2 = file2.lengthSync();
  if (file1Offset == 0 && file2Offset == 0 && count == null) {
    if (length1 != length2) {
      file1.closeSync();
      file2.closeSync();
      return false;
    }
  }
  if (count == null) count = length1;
  var data1 = new List<int>(count);
  var data2 = new List<int>(count);
  if (file1Offset != 0) file1.setPositionSync(file1Offset);
  if (file2Offset != 0) file2.setPositionSync(file2Offset);
  var read1 = file1.readIntoSync(data1, 0, count);
  Expect.equals(count, read1);
  var read2 = file2.readIntoSync(data2, 0, count);
  Expect.equals(count, read2);
  for (var i = 0; i < count; i++) {
    if (data1[i] != data2[i]) {
      file1.closeSync();
      file2.closeSync();
      return false;
    }
  }
  file1.closeSync();
  file2.closeSync();
  return true;
}

// Test piping from one file to another and closing both streams
// after wards.
testFileToFilePipe1() {
  // Force test to timeout if one of the handlers is
  // not called.
  asyncStart();

  String srcFileName = getDataFilename("readline_test1.dat");
  var srcStream = new File(srcFileName).openRead();

  var tempDir = Directory.systemTemp.createTempSync('dart_stream_pipe');
  String dstFileName = tempDir.path + "/readline_test1.dat";
  new File(dstFileName).createSync();
  var output = new File(dstFileName).openWrite();
  srcStream.pipe(output).then((_) {
    bool result = compareFileContent(srcFileName, dstFileName);
    new File(dstFileName).deleteSync();
    tempDir.deleteSync();
    Expect.isTrue(result);
    asyncEnd();
  });
}

// Test piping from one file to another and write additional data to
// the output stream after piping finished.
testFileToFilePipe2() {
  // Force test to timeout if one of the handlers is
  // not called.
  asyncStart();

  String srcFileName = getDataFilename("readline_test1.dat");
  var srcFile = new File(srcFileName);
  var srcStream = srcFile.openRead();

  var tempDir = Directory.systemTemp.createTempSync('dart_stream_pipe');
  var dstFileName = tempDir.path + "/readline_test1.dat";
  var dstFile = new File(dstFileName);
  dstFile.createSync();
  var output = dstFile.openWrite();
  output.addStream(srcStream).then((_) {
    output.add([32]);
    output.close();
    output.done.then((_) {
      var src = srcFile.openSync();
      var dst = dstFile.openSync();
      var srcLength = src.lengthSync();
      var dstLength = dst.lengthSync();
      Expect.equals(srcLength + 1, dstLength);
      Expect.isTrue(
          compareFileContent(srcFileName, dstFileName, count: srcLength));
      dst.setPositionSync(srcLength);
      var data = new List<int>(1);
      var read2 = dst.readIntoSync(data, 0, 1);
      Expect.equals(32, data[0]);
      src.closeSync();
      dst.closeSync();
      dstFile.deleteSync();
      tempDir.deleteSync();
      asyncEnd();
    });
  });
}

// Test piping two copies of one file to another.
testFileToFilePipe3() {
  // Force test to timeout if one of the handlers is
  // not called.
  asyncStart();

  String srcFileName = getDataFilename("readline_test1.dat");
  var srcFile = new File(srcFileName);
  var srcStream = srcFile.openRead();

  var tempDir = Directory.systemTemp.createTempSync('dart_stream_pipe');
  var dstFileName = tempDir.path + "/readline_test1.dat";
  var dstFile = new File(dstFileName);
  dstFile.createSync();
  var output = dstFile.openWrite();
  output.addStream(srcStream).then((_) {
    var srcStream2 = srcFile.openRead();
    output.addStream(srcStream2).then((_) {
      output.close();
      output.done.then((_) {
        var src = srcFile.openSync();
        var dst = dstFile.openSync();
        var srcLength = src.lengthSync();
        var dstLength = dst.lengthSync();
        Expect.equals(srcLength * 2, dstLength);
        Expect.isTrue(
            compareFileContent(srcFileName, dstFileName, count: srcLength));
        Expect.isTrue(compareFileContent(srcFileName, dstFileName,
            file2Offset: srcLength, count: srcLength));
        src.closeSync();
        dst.closeSync();
        dstFile.deleteSync();
        tempDir.deleteSync();
        asyncEnd();
      });
    });
  });
}

main() {
  testFileToFilePipe1();
  testFileToFilePipe2();
  testFileToFilePipe3();
}
