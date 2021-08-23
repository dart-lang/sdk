// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing file I/O.

// @dart = 2.9

// OtherResources=fixed_length_file
// OtherResources=read_as_text.dat

import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";

class FileTest {
  static Directory tempDirectory;
  static int numLiveAsyncTests = 0;

  static void asyncTestStarted() {
    asyncStart();
    ++numLiveAsyncTests;
  }

  static void asyncTestDone(String name) {
    asyncEnd();
    --numLiveAsyncTests;
    if (numLiveAsyncTests == 0) {
      deleteTempDirectory();
    }
  }

  static void createTempDirectory(Function doNext) {
    Directory.systemTemp.createTemp('dart_file').then((temp) {
      tempDirectory = temp;
      doNext();
    });
  }

  static void deleteTempDirectory() {
    tempDirectory.deleteSync(recursive: true);
  }

  static testReadInto() async {
    asyncTestStarted();
    File file = new File(tempDirectory.path + "/out_read_into");

    var openedFile = await file.open(mode: FileMode.write);
    await openedFile.writeFrom(const [1, 2, 3]);

    await openedFile.setPosition(0);
    var list = [null, null, null];
    Expect.equals(3, await openedFile.readInto(list));
    Expect.listEquals([1, 2, 3], list);

    read(start, end, length, expected) async {
      var list = [null, null, null];
      await openedFile.setPosition(0);
      Expect.equals(length, await openedFile.readInto(list, start, end));
      Expect.listEquals(expected, list);
      return list;
    }

    await read(0, 3, 3, [1, 2, 3]);
    await read(0, 2, 2, [1, 2, null]);
    await read(1, 2, 1, [null, 1, null]);
    await read(1, 3, 2, [null, 1, 2]);
    await read(2, 3, 1, [null, null, 1]);
    await read(0, 0, 0, [null, null, null]);

    await openedFile.close();

    asyncTestDone("testReadInto");
  }

  static void testReadAsText() {
    asyncTestStarted();
    var name = getFilename("fixed_length_file");
    var f = new File(name);
    f.readAsString(encoding: utf8).then((text) {
      Expect.isTrue(text.endsWith("42 bytes."));
      Expect.equals(42, text.length);
      var name = getFilename("read_as_text.dat");
      var f = new File(name);
      f.readAsString(encoding: utf8).then((text) {
        Expect.equals(6, text.length);
        var expected = [955, 120, 46, 32, 120, 10];
        Expect.listEquals(expected, text.codeUnits);
        f.readAsString(encoding: latin1).then((text) {
          Expect.equals(7, text.length);
          var expected = [206, 187, 120, 46, 32, 120, 10];
          Expect.listEquals(expected, text.codeUnits);
          var readAsStringFuture = f.readAsString(encoding: ascii);
          readAsStringFuture.then((text) {
            Expect.fail("Non-ascii char should cause error");
          }).catchError((e) {
            asyncTestDone("testReadAsText");
          });
        });
      });
    });
  }

  static String getFilename(String path) {
    return Platform.script.resolve(path).toFilePath();
  }

  // Main test entrypoint.
  // This test results in an unhandled exception in the isolate while
  // some async file IO operations are still pending. The unhandled
  // exception results in the 'File' object being leaked, the error
  // only shows up in the ASAN bots which detect the leak.
  static testMain() {
    asyncStart();
    var outerZone = Zone.current;
    var firstZone = Zone.current.fork(specification: ZoneSpecification(
        handleUncaughtError: (self, parent, zone, error, stacktrace) {
      asyncEnd();
      print("unittest-suite-success"); // For the test harness.
      exit(0);
    }));
    firstZone.run(() async {
      Expect.identical(firstZone, Zone.current);
      createTempDirectory(() {
        testReadAsText();
        testReadInto();
        Expect.equals(1, 0); // Should not execute this.
        asyncEnd();
      });
    });
  }
}

main() {
  FileTest.testMain();
}
