// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Directory listing test.

import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

testChangeDirectory() {
  asyncStart();
  Directory.systemTemp.createTemp('dart_directory_chdir').then((temp) {
    var initialCurrent = Directory.current;
    Directory.current = temp;
    var newCurrent = Directory.current;
    new File("111").createSync();
    var dir = new Directory(newCurrent.path + Platform.pathSeparator + "222");
    dir.createSync();
    Directory.current = dir;
    new File("333").createSync();
    Expect.isTrue(new File("333").existsSync());
    Expect.isTrue(new File("../111").existsSync());
    Directory.current = "..";
    Expect.isTrue(new File("111").existsSync());
    Expect.isTrue(new File("222/333").existsSync());
    // Deleting the current working directory causes an error.
    // On Windows, the deletion fails, and on non-Windows, the getter fails.
    Expect.throws(() {
      temp.deleteSync(recursive: true);
      Directory.current;
    }, (e) => e is FileSystemException);
    Directory.current = initialCurrent;
    Directory.current;
    if (temp.existsSync()) temp.deleteSync(recursive: true);
    asyncEnd();
  });
}

testChangeDirectoryIllegalArguments() {
  Expect.throwsArgumentError(() => Directory.current = 1);
  Expect.throwsArgumentError(
      () => Directory.current = 111111111111111111111111111111111111);
  Expect.throwsArgumentError(() => Directory.current = true);
  Expect.throwsArgumentError(() => Directory.current = []);
  Expect.throwsArgumentError(() => Directory.current = new File("xxx"));
}

main() {
  testChangeDirectory();
  testChangeDirectoryIllegalArguments();
}
