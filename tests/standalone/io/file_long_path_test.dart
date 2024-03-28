// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test is Windows-only.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as p;

const maxPath = 260;
const maxDirectoryPath = maxPath - 12;
String longName = '${'x' * 248}';

Directory createLongPathDir(Directory tmp, [String? suffix]) {
  var path = tmp.path;
  path = p.join(path, 't' * 248);
  var dir = Directory(path);
  dir.createSync(recursive: true);
  Expect.isTrue(dir.existsSync());
  // Test the rename() of directory
  dir = dir.renameSync(p.join(tmp.path, '$longName$suffix'));
  Expect.isTrue(dir.existsSync());
  Expect.isFalse(Directory(path).existsSync());
  return dir;
}

void testCreate(String dir) {
  final path = p.join(dir, 'a_long_path_filename');
  Expect.isTrue(path.length > maxPath);
  final file = File(path);
  file.createSync();
  Expect.isTrue(file.existsSync());
  file.deleteSync();
}

void testCopy(String dir) {
  final src = p.join(dir, 'a_long_path_filename_1');
  final dest = p.join(dir, 'a_long_path_filename_2');
  Expect.isTrue(src.length > maxPath);
  final file1 = File(src);
  file1.createSync();

  final file2 = file1.copySync(dest);
  Expect.isTrue(file2.existsSync());
  file1.deleteSync();
  file2.deleteSync();
}

void testRename(String dir) {
  final path = p.join(dir, 'a_long_path_filename');
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
  final path = p.join(dir, 'a_long_path_filename');
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
  final path = p.join(dir, 'a_long_path_filename');
  Expect.isTrue(path.length > maxPath);
  final file = File(path);
  file.createSync();
  final access = file.openSync();
  access.closeSync();
}

void testFileStat(String dir) {
  final path = p.join(dir, 'a_long_path_filename');
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

String _createDirectoryHelper(String currentDir, String targetDir) {
  if (p.isRelative(targetDir)) {
    targetDir = p.normalize(p.absolute(currentDir, targetDir));
  }
  final dir = Directory(targetDir)..createSync();
  Expect.isTrue(dir.existsSync());
  return dir.path;
}

void testCreateLinkToDir(String dir, String dir2) {
  final linkPath = p.join(dir, 'a_long_path_linkname');
  final renamedPath = p.join(dir, 'a_long_renamed_path_linkname');

  Expect.isTrue(linkPath.length > maxPath);
  Expect.isTrue(renamedPath.length > maxPath);

  final targetDirectory1 =
      _createDirectoryHelper(dir, p.join(dir2, 'a_long_directory_target1'));
  final targetDirectory2 =
      _createDirectoryHelper(dir, p.join(dir2, 'a_long_directory_target2'));

  final linkTarget1 = p.isRelative(dir2)
      ? p.relative(targetDirectory1, from: p.dirname(p.absolute(linkPath)))
      : targetDirectory1;

  final linkTarget2 = p.isRelative(dir2)
      ? p.relative(targetDirectory2, from: p.dirname(p.absolute(linkPath)))
      : targetDirectory2;

  // Create link
  final link = Link(linkPath)..createSync(linkTarget1);
  Expect.isTrue(link.existsSync());
  final resolvedCreatePath = link.resolveSymbolicLinksSync();
  Expect.isTrue(
      FileSystemEntity.identicalSync(targetDirectory1, resolvedCreatePath),
      '${link.path} should resolve to $targetDirectory1 but resolved to $resolvedCreatePath');

  // Rename link
  var renamedLink = link.renameSync(renamedPath);
  Expect.isTrue(renamedLink.existsSync());
  Expect.isFalse(link.existsSync());
  final resolvedRenamePath = renamedLink.resolveSymbolicLinksSync();
  Expect.isTrue(
      FileSystemEntity.identicalSync(targetDirectory1, resolvedRenamePath),
      '${link.path} should resolve to $targetDirectory1 but resolved to $resolvedRenamePath');

  // Update link target
  renamedLink.updateSync(linkTarget2);
  final resolvedUpdatedPath = renamedLink.resolveSymbolicLinksSync();
  Expect.isTrue(
      FileSystemEntity.identicalSync(targetDirectory2, resolvedUpdatedPath),
      '${link.path} should resolve to $targetDirectory2 but resolved to $resolvedRenamePath');

  Directory(targetDirectory1).deleteSync();
  Directory(targetDirectory2).deleteSync();
  renamedLink.deleteSync();
}

void testCreateLinkToFile(String dir, String dir2) {
  final path = p.join(dir, 'a_long_path_linkname');
  Expect.isTrue(path.length > maxPath);

  String _pathHelper(String currentDir, String targetPath) {
    if (p.isRelative(targetPath)) {
      return p.normalize(p.absolute(currentDir, targetPath));
    } else {
      return targetPath;
    }
  }

  var target = _pathHelper(dir, p.join(dir2, 'a_long_path_target'));
  var target2 = _pathHelper(dir, p.join(dir2, 'an_updated_target'));

  var linkTarget = p.isRelative(dir2)
      ? p.relative(target, from: p.dirname(p.absolute(path)))
      : target;

  var linkTarget2 = p.isRelative(dir2)
      ? p.relative(target2, from: p.dirname(p.absolute(path)))
      : target2;

  final link = Link(path)..createSync(linkTarget);

  final dest = File(target)..createSync();
  Expect.isTrue(dest.existsSync());

  Expect.isTrue(link.existsSync());
  final resolvedPath = link.resolveSymbolicLinksSync();
  Expect.isTrue(FileSystemEntity.identicalSync(target, resolvedPath),
      '${link.path} should resolve to $target but resolved to $resolvedPath');

  // Rename link
  var renamedLink = link.renameSync(p.join(dir, 'a_renamed_long_path_link'));
  Expect.isTrue(renamedLink.existsSync());
  Expect.isFalse(link.existsSync());
  Expect.isTrue(renamedLink.targetSync().contains('a_long_path_target'));

  // Update link target
  final renamedDest = File(target2)..createSync();
  renamedLink.updateSync(linkTarget2);
  Expect.isTrue(renamedLink.targetSync().contains('an_updated_target'));

  dest.deleteSync();
  renamedDest.deleteSync();
  renamedLink.deleteSync();
}

testNormalLinkToLongPath(String short, String long) {
  var target = File(p.join(long, 'file_target'))..createSync();
  final link = Link(p.join(short, 'link'))..createSync(target.path);
  Expect.isTrue(target.path.length > maxPath);
  Expect.isTrue(link.resolveSymbolicLinksSync().length > maxPath);
  Expect.isTrue(link.path.length < maxPath);
  Expect.isTrue(link.resolveSymbolicLinksSync().contains('file_target'));

  Expect.isTrue(link.existsSync());
  Expect.equals(target.path, link.targetSync());

  var targetDir = Directory(p.join(long, 'dir_target'))..createSync();
  link.updateSync(targetDir.path);
  Expect.equals(targetDir.path, link.targetSync());

  link.deleteSync();
  target.deleteSync();
  targetDir.deleteSync();
}

testLongPathLinkToNormal(String short, String long) {
  var target = File(p.join(short, 'file_target'))..createSync();
  final link = Link(p.join(long, 'link'))..createSync(target.path);

  Expect.isTrue(target.path.length < maxPath);
  Expect.isTrue(link.path.length > maxPath);
  Expect.isTrue(link.resolveSymbolicLinksSync().contains('file_target'));

  Expect.isTrue(link.existsSync());
  Expect.equals(target.path, link.targetSync());

  var targetDir = Directory(p.join(short, 'dir_target'))..createSync();
  link.updateSync(targetDir.path);
  Expect.equals(targetDir.path, link.targetSync());

  link.deleteSync();
  target.deleteSync();
  targetDir.deleteSync();
}

testDirectorySetCurrentFails(String dir) {
  // This tests setting a long path directory to current directory.
  Expect.isTrue(dir.length > maxPath);
  if (Platform.isWindows) {
    // On Windows current directory path is limited to MAX_PATH characters.
    // Windows 10, Version 1607 introduced a way to lift this limitation but
    // it requires opt-in from both application and the OS configuration.
    //
    // See https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=registry#enable-long-paths-in-windows-10-version-1607-and-later
    Expect.throws<FileSystemException>(() {
      Directory.current = dir;
    }, (e) => e.toString().contains('extension is too long'));
  }
}

void main() {
  final tmp = Directory.systemTemp.createTempSync('flpt');
  final oldCurrent = Directory.current;
  Directory.current = tmp;
  try {
    String dir1 = createLongPathDir(tmp, 'dir1').path;
    String dir2 = createLongPathDir(tmp, 'dir2').path;
    testDirectorySetCurrentFails(dir1);
    for (final path in [
      dir1,
      p.join('.', '${longName}dir1'),
      p.join('.', '${longName}dir1', '..', '${longName}dir1'),
    ]) {
      testCreate(path);
      testCopy(path);
      testRename(path);
      testReadWrite(path);
      testOpen(path);
      testFileStat(path);
      for (var relative in [true, false]) {
        final targetDir = relative ? p.relative(dir2, from: dir1) : dir2;
        testCreateLinkToDir(path, targetDir);
        testCreateLinkToFile(path, targetDir);
      }
    }

    testNormalLinkToLongPath(tmp.path, dir1);
    testLongPathLinkToNormal(tmp.path, dir1);
  } finally {
    // Reset the current Directory.
    Directory.current = oldCurrent;
    tmp.deleteSync(recursive: true);
  }
}
