// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test is Windows-only.

import 'dart:io';

import "package:expect/expect.dart";

const maxPath = 260;
const maxDirectoryPath = maxPath - 12;
String longName = '${'x' * 248}';

Directory createLongPathDir(Directory tmp) {
  if (tmp.path.length <= maxDirectoryPath) {
    var path = tmp.path;
    path += '\\${'t' * 248}';
    var dir = Directory(path);
    dir.createSync(recursive: true);
    // Test the rename() of directory
    dir = dir.renameSync(tmp.path + '\\$longName');
    Expect.isTrue(dir.existsSync());
    Expect.isFalse(Directory(path).existsSync());
    return dir;
  } else {
    return tmp;
  }
}

void testCreate(String dir) {
  final path = '${dir}\\a_long_path_filename';
  Expect.isTrue(path.length > maxPath);
  final file = File(path);
  file.createSync();
  Expect.isTrue(file.existsSync());
  file.deleteSync();
}

void testCopy(String dir) {
  final src = '${dir}\\a_long_path_filename_1';
  final dest = '${dir}\\a_long_path_filename_2';
  Expect.isTrue(src.length > maxPath);
  final file1 = File(src);
  file1.createSync();

  final file2 = file1.copySync(dest);
  Expect.isTrue(file2.existsSync());
  file1.deleteSync();
  file2.deleteSync();
}

void testRename(String dir) {
  final path = '${dir}\\a_long_path_filename';
  Expect.isTrue(path.length > maxPath);
  final file = File(path);
  file.createSync();
  Expect.isTrue(file.existsSync());

  final renamedFile = file.renameSync('${path}_copy');

  Expect.isFalse(file.existsSync());
  Expect.isTrue(renamedFile.existsSync());
  renamedFile.deleteSync();
}

void testReadWrite(String dir) {
  final path = '${dir}\\a_long_path_filename';
  Expect.isTrue(path.length > maxPath);
  final file = File(path);

  final content = "testReadWrite";
  file.writeAsStringSync(content);
  Expect.isTrue(file.existsSync());

  int length = file.lengthSync();
  Expect.equals(content.length, length);

  final string = file.readAsStringSync();
  Expect.equals(content, string);
  file.deleteSync();
}

void testOpen(String dir) {
  final path = '${dir}\\a_long_path_filename';
  Expect.isTrue(path.length > maxPath);
  final file = File(path);
  file.createSync();
  final access = file.openSync();
  access.closeSync();
}

void testFileStat(String dir) {
  final path = '${dir}\\a_long_path_filename';
  Expect.isTrue(path.length > maxPath);
  final file = File(path);
  file.createSync();
  final stat = FileStat.statSync(file.path);

  final dateTime = DateTime.utc(2020);

  file.setLastModifiedSync(dateTime);
  Expect.notEquals(
      stat.modified.toString(), file.lastModifiedSync().toString());

  file.setLastAccessedSync(dateTime);
  Expect.notEquals(
      stat.accessed.toString(), file.lastAccessedSync().toString());
}

void testCreateLinkToDir(String dir) {
  final path = '${dir}\\a_long_path_linkname';
  Expect.isTrue(path.length > maxPath);
  var target = '$dir\\a_long_path_target';
  final link = Link(path)..createSync(target);

  final dest = Directory(target)..createSync();
  Expect.isTrue(dest.existsSync());

  Expect.isTrue(link.existsSync());
  Expect.isTrue(link.targetSync().contains('a_long_path_target'));

  // Rename link
  var renamedLink = link.renameSync('${dir}\\a_renamed_long_path_link');
  Expect.isTrue(renamedLink.existsSync());
  Expect.isFalse(link.existsSync());
  Expect.isTrue(renamedLink.targetSync().contains('a_long_path_target'));

  // Update link target
  target = '$dir\\an_updated_target';
  final renamedDest = Directory(target)..createSync();
  renamedLink.updateSync(target);
  Expect.isTrue(renamedLink.targetSync().contains('an_updated_target'));

  dest.deleteSync();
  renamedDest.deleteSync();
  renamedLink.deleteSync();
}

void testCreateLinkToFile(String dir) {
  final path = '${dir}\\a_long_path_linkname';
  Expect.isTrue(path.length > maxPath);
  var target = '$dir\\a_long_path_target';
  final link = Link(path)..createSync(target);

  final dest = File(target)..createSync();
  Expect.isTrue(dest.existsSync());

  Expect.isTrue(link.existsSync());
  Expect.isTrue(link.targetSync().contains('a_long_path_target'));
  Expect.isTrue(link.resolveSymbolicLinksSync().contains('a_long_path_target'));

  // Rename link
  var renamedLink = link.renameSync('${dir}\\a_renamed_long_path_link');
  Expect.isTrue(renamedLink.existsSync());
  Expect.isFalse(link.existsSync());
  Expect.isTrue(renamedLink.targetSync().contains('a_long_path_target'));

  // Update link target
  target = '$dir\\an_updated_target';
  final renamedDest = File(target)..createSync();
  renamedLink.updateSync(target);
  Expect.isTrue(renamedLink.targetSync().contains('an_updated_target'));

  dest.deleteSync();
  renamedDest.deleteSync();
  renamedLink.deleteSync();
}

testNormalLinkToLongPath(String short, String long) {
  var target = File('$long\\file_target')..createSync();
  final link = Link('$short\\link')..createSync(target.path);
  Expect.isTrue(target.path.length > maxPath);
  Expect.isTrue(link.resolveSymbolicLinksSync().length > maxPath);
  Expect.isTrue(link.path.length < maxPath);
  Expect.isTrue(link.resolveSymbolicLinksSync().contains('file_target'));

  Expect.isTrue(link.existsSync());
  Expect.equals(target.path, link.targetSync());

  var targetDir = Directory('$long\\dir_target')..createSync();
  link.updateSync(targetDir.path);
  Expect.equals(targetDir.path, link.targetSync());

  link.deleteSync();
  target.deleteSync();
  targetDir.deleteSync();
}

testLongPathLinkToNormal(String short, String long) {
  var target = File('$short\\file_target')..createSync();
  final link = Link('$long\\link')..createSync(target.path);

  Expect.isTrue(target.path.length < maxPath);
  Expect.isTrue(link.path.length > maxPath);
  Expect.isTrue(link.resolveSymbolicLinksSync().contains('file_target'));

  Expect.isTrue(link.existsSync());
  Expect.equals(target.path, link.targetSync());

  var targetDir = Directory('$short\\dir_target')..createSync();
  link.updateSync(targetDir.path);
  Expect.equals(targetDir.path, link.targetSync());

  link.deleteSync();
  target.deleteSync();
  targetDir.deleteSync();
}

testDirectorySetCurrent(String dir) {
  // This tests setting a long path directory to current directory.
  // This will fail.
  Expect.isTrue(dir.length > maxPath);
  Expect.throws<FileSystemException>(() {
    Directory.current = dir;
  }, (e) => e.toString().contains('extension is too long'));
}

void main() {
  if (!Platform.isWindows) {
    return;
  }
  final tmp = Directory.systemTemp.createTempSync('dart-file-long-path');
  final oldCurrent = Directory.current;
  Directory.current = tmp;
  try {
    String dir = createLongPathDir(tmp).path;
    testDirectorySetCurrent(dir);
    for (final path in [dir, ".\\$longName", ".\\$longName\\..\\$longName"]) {
      testCreate(path);
      testCopy(path);
      testRename(path);
      testReadWrite(path);
      testOpen(path);
      testFileStat(path);
      testCreateLinkToDir(path);
      testCreateLinkToFile(path);
    }

    testNormalLinkToLongPath(tmp.path, dir);
    testLongPathLinkToNormal(tmp.path, dir);
  } finally {
    // Reset the current Directory.
    Directory.current = oldCurrent;
    tmp.deleteSync(recursive: true);
  }
}
