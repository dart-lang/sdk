// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing file input stream, VM-only, standalone test.

#import("dart:io");
#import("dart:isolate");

void testOpenOutputStreamSync() {
  Directory tempDirectory = new Directory('');

  // Create a port for waiting on the final result of this test.
  ReceivePort done = new ReceivePort();
  done.receive((message, replyTo) {
    tempDirectory.deleteSync();
    done.close();
  });

  tempDirectory.createTempSync();
  String fileName = "${tempDirectory.path}/test";
  File file = new File(fileName);
  file.createSync();
  OutputStream x = file.openOutputStream();
  x.write([65, 66, 67]);
  x.close();
  x.onClosed = () {
    file.deleteSync();
    done.toSendPort().send("done");
  };
}


void testOutputStreamNoPendingWrite() {
  Directory tempDirectory = new Directory('');

  // Create a port for waiting on the final result of this test.
  ReceivePort done = new ReceivePort();
  done.receive((message, replyTo) {
    tempDirectory.deleteRecursively(() {
      done.close();
    });
  });

  tempDirectory.createTemp(() {
    String fileName = "${tempDirectory.path}/test";
    File file = new File(fileName);
    file.create(() {
      OutputStream stream = file.openOutputStream();
      final total = 100;
      var count = 0;
      stream.onNoPendingWrites = () {
        stream.write([count++]);
        if (count == total) {
          stream.close();
        }
        stream.onClosed = () {
          List buffer = new List<int>(total);
          File fileSync = new File(fileName);
          var openedFile = fileSync.openSync();
          openedFile.readListSync(buffer, 0, total);
          for (var i = 0; i < total; i++) {
            Expect.equals(i, buffer[i]);
          }
          openedFile.closeSync();
          fileSync.deleteSync();
          done.toSendPort().send("done");
        };
      };
    });
  });
}


main() {
  testOpenOutputStreamSync();
  testOutputStreamNoPendingWrite();
}
