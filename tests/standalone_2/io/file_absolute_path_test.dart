// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing FileSystemEntity.absolute

import "package:expect/expect.dart";
import 'dart:io';

main() {
  if (Platform.isWindows) {
    testWindows();
    try {
      Directory.current = 'C:\\';
    } catch (e) {
      return;
    }
    testWindows();
  } else {
    testPosix();
    Directory.current = '.';
    testPosix();
    Directory.current = '/';
    testPosix();
  }
}

testWindows() {
  String current = Directory.current.path;
  for (String relative in ['abd', '..', '.', 'efg/hij', 'abc/']) {
    if (current.endsWith('\\')) {
      Expect.equals(new File(relative).absolute.path, '$current$relative');
    } else {
      Expect.equals(new File(relative).absolute.path, '$current\\$relative');
    }
    Expect.isTrue(new File(relative).absolute.isAbsolute);
  }
  for (String absolute in [
    'c:/abd',
    'D:\\rf',
    '\\\\a_share\\folder',
    '\\\\?\\c:\\prefixed\path\\'
  ]) {
    Expect.isTrue(new File(absolute).absolute.path == absolute);
    Expect.isTrue(new File(absolute).absolute.isAbsolute);
  }
}

testPosix() {
  String current = Directory.current.path;
  for (String relative in ['abd', '..', '.', 'efg/hij', 'abc/']) {
    if (current.endsWith('/')) {
      Expect.equals(new File(relative).absolute.path, '$current$relative');
    } else {
      Expect.equals(new File(relative).absolute.path, '$current/$relative');
    }
    Expect.isTrue(new File(relative).absolute.isAbsolute);
    Expect.equals(new Directory(relative).absolute.path,
        new Link(relative).absolute.path);
    Expect.isTrue(new File(relative).absolute is File);
    Expect.isTrue(new Directory(relative).absolute is Directory);
    Expect.isTrue(new Link(relative).absolute is Link);
  }
  for (String absolute in ['/abd', '/', '/./..\\', '/efg/hij', '/abc/']) {
    Expect.equals(new File(absolute).absolute.path, absolute);
    Expect.isTrue(new File(absolute).absolute.isAbsolute);
  }
}
