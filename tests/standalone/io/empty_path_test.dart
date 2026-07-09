// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing empty file pathname parameter.

import 'dart:io';

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

Future<void> testOpen() async {
  try {
    await File('').open();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
}

Future<void> testExists() async {
  try {
    var retval = await File('').exists();
    Expect.equals(retval, false);
  } catch (e) {
    Expect.equals(1, 0);
  }
  try {
    var retval = File('').existsSync();
    Expect.equals(retval, false);
  } catch (e) {
    Expect.equals(1, 0);
  }
}

Future<void> testCreate() async {
  try {
    await File('').create();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    File('').createSync();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
}

Future<void> testCreateLink() async {
  try {
    await Link('').create('test');
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    await Link('test').create('');
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    Link('').createSync('test');
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    Link('test').createSync('');
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
}

Future<void> testDelete() async {
  try {
    await File('').delete();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    File('').deleteSync();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
}

Future<void> testDeleteLink() async {
  try {
    await Link('').delete();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    Link('').deleteSync();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
}

Future<void> testRename() async {
  try {
    await File('').rename('test');
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  late File file;
  Directory directory = Directory.systemTemp.createTempSync(
    'dart_test_directory',
  );
  try {
    file = File('${directory.path}/test');
    file.createSync();
    await file.rename('');
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  } finally {
    file.deleteSync();
  }
  try {
    File('').renameSync('test');
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    file = File('${directory.path}/test');
    file.createSync();
    file.renameSync('');
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  } finally {
    file.deleteSync();
  }
  directory.deleteSync(recursive: true);
}

Future<void> testCopy() async {
  try {
    await File('').copy('test');
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    await File('test').copy('');
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    File('').copySync('test');
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    File('test').copySync('');
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
}

Future<void> testLength() async {
  try {
    var len = await File('').length();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    var len = File('').lengthSync();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
}

Future<void> testStat() async {
  final now = DateTime.now();
  try {
    var len = await File('').stat();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    var len = File('').statSync();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    var len = await File('').lastAccessed();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    var len = File('').lastAccessedSync();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    var len = await File('').setLastAccessed(now);
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    var len = File('').setLastAccessedSync(now);
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    var len = await File('').lastModified();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    var len = File('').lastModifiedSync();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    var len = await File('').setLastModified(now);
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    var len = File('').setLastModifiedSync(now);
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
}

Future<void> testResolveSymbolicLinks() async {
  try {
    var str = await File('').resolveSymbolicLinks();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    var str = File('').resolveSymbolicLinksSync();
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
}

Future<void> testType() async {
  try {
    var val = await FileSystemEntity.isDirectory('');
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    var val = FileSystemEntity.isDirectorySync('');
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
}

Future<void> testIdentical() async {
  try {
    var val = await FileSystemEntity.identical('', 'test');
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
  try {
    var val = FileSystemEntity.identicalSync('test', '');
    Expect.equals(1, 0);
  } catch (e) {
    Expect.equals(1, 1);
  }
}

main() async {
  await testOpen();
  await testExists();
  await testCreate();
  await testCreateLink();
  await testDelete();
  await testDeleteLink();
  await testRename();
  await testCopy();
  await testLength();
  await testStat();
  await testResolveSymbolicLinks();
  await testType();
  await testIdentical();
}
