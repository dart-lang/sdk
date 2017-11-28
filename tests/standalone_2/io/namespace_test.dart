// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:expect/expect.dart";

const String file1str = "file1";

void doTestSync() {
  // Stuff that should exist.
  Directory dir1 = new Directory("/dir1");
  Directory dir2 = new Directory("/dir1/dir2");
  File file1 = new File("/dir1/dir2/file1");

  Expect.isTrue(dir1.existsSync());
  Expect.isTrue(dir2.existsSync());
  Expect.isTrue(file1.existsSync());
  Expect.equals(file1str, file1.readAsStringSync());

  // Relative paths since cwd of the namespace should be "/".
  Directory dir1rel = new Directory("dir1");
  Directory dir2rel = new Directory("dir1/dir2");
  File file1rel = new File("dir1/dir2/file1");

  Expect.equals("/", Directory.current.path);
  Expect.isTrue(dir1rel.existsSync());
  Expect.isTrue(dir2rel.existsSync());
  Expect.isTrue(file1rel.existsSync());
  Expect.equals(file1str, file1.readAsStringSync());

  // Stuff that should not exist.
  Expect.isFalse(new Directory("/tmp").existsSync());
  Expect.isFalse(new File("/tmp").existsSync());
  Expect.isFalse(new File(Platform.script.path).existsSync());
  Expect.isFalse(new File(Platform.executable).existsSync());
  Expect.isFalse(new File(Platform.resolvedExecutable).existsSync());

  // File operations in the namespace.
  // copy.
  File file2 = file1.copySync("/file2");
  Expect.isTrue(file2.existsSync());
  Expect.equals(file1.readAsStringSync(), file2.readAsStringSync());
  // create.
  File file3 = new File("/file3")..createSync();
  Expect.isTrue(file3.existsSync());
  // last{Accessed,Modified}.
  DateTime time = new DateTime.fromMillisecondsSinceEpoch(0);
  file2.setLastAccessedSync(time);
  file2.setLastModifiedSync(time);
  Expect.equals(time, file2.lastAccessedSync());
  Expect.equals(time, file2.lastModifiedSync());
  Expect.equals(file1str.length, file2.lengthSync());
  // open.
  RandomAccessFile file2raf = file2.openSync();
  Expect.equals(file1str.codeUnitAt(0), file2raf.readByteSync());
  file2raf.closeSync();
  // rename.
  File file4 = new File("file4");
  file3.renameSync(file4.path);
  Expect.isFalse(file3.existsSync());
  Expect.isTrue(file4.existsSync());
  // delete.
  file4.deleteSync();
  Expect.isFalse(file4.existsSync());
  // stat.
  FileStat stat = file2.statSync();
  Expect.equals(time, stat.modified);

  // Directory operaions in the namespace.
  // absolute.
  Expect.equals(dir1.path, dir1rel.absolute.path);
  // create
  Directory dir3 = new Directory("/dir3");
  dir3.createSync();
  Expect.isTrue(dir3.existsSync());
  // createTemp
  Directory dir3temp = dir3.createTempSync();
  Expect.isTrue(dir3temp.existsSync());
  // listSync
  List fses = Directory.current.listSync();
  Expect.isTrue(fses.any((fse) => fse.path == dir3.path));
  // rename.
  Directory dir4 = new Directory("dir4");
  dir3.renameSync(dir4.path);
  Expect.isTrue(dir4.existsSync());
  // delete.
  dir4.deleteSync(recursive: true);
  Expect.isFalse(dir4.existsSync());
  // stat.
  FileStat dirstat = dir2.statSync();
  Expect.equals(FileSystemEntityType.DIRECTORY, dirstat.type);
}

doTestAsync() async {
  // Stuff that should exist.
  Directory dir1 = new Directory("/dir1");
  Directory dir2 = new Directory("/dir1/dir2");
  File file1 = new File("/dir1/dir2/file1");

  Expect.isTrue(await dir1.exists());
  Expect.isTrue(await dir2.exists());
  Expect.isTrue(await file1.exists());
  Expect.equals(file1str, await file1.readAsString());

  // Relative paths since cwd of the namespace should be "/".
  Directory dir1rel = new Directory("dir1");
  Directory dir2rel = new Directory("dir1/dir2");
  File file1rel = new File("dir1/dir2/file1");

  Expect.equals("/", Directory.current.path);
  Expect.isTrue(await dir1rel.exists());
  Expect.isTrue(await dir2rel.exists());
  Expect.isTrue(await file1rel.exists());
  Expect.equals(file1str, await file1.readAsString());

  // Stuff that should not exist.
  Expect.isFalse(await new Directory("/tmp").exists());
  Expect.isFalse(await new File("/tmp").exists());
  Expect.isFalse(await new File(Platform.script.path).exists());
  Expect.isFalse(await new File(Platform.executable).exists());
  Expect.isFalse(await new File(Platform.resolvedExecutable).exists());

  // File operations in the namespace.
  // copy.
  File file2 = await file1.copy("/file2");
  Expect.isTrue(await file2.exists());
  Expect.equals(await file1.readAsString(), await file2.readAsString());
  // create.
  File file3 = new File("/file3");
  await file3.create();
  Expect.isTrue(await file3.exists());
  // last{Accessed,Modified}.
  DateTime time = new DateTime.fromMillisecondsSinceEpoch(0);
  await file2.setLastAccessed(time);
  await file2.setLastModified(time);
  Expect.equals(time, await file2.lastAccessed());
  Expect.equals(time, await file2.lastModified());
  Expect.equals(file1str.length, await file2.length());
  // open.
  RandomAccessFile file2raf = await file2.open();
  Expect.equals(file1str.codeUnitAt(0), await file2raf.readByte());
  await file2raf.close();
  // rename.
  File file4 = new File("file4");
  await file3.rename(file4.path);
  Expect.isFalse(await file3.exists());
  Expect.isTrue(await file4.exists());
  // delete.
  await file4.delete();
  Expect.isFalse(await file4.exists());
  // stat.
  FileStat stat = await file2.stat();
  Expect.equals(time, stat.modified);

  // Directory operaions in the namespace.
  // absolute.
  Expect.equals(dir1.path, dir1rel.absolute.path);
  // create
  Directory dir3 = new Directory("/dir3");
  await dir3.create();
  Expect.isTrue(await dir3.exists());
  // createTemp
  Directory dir3temp = await dir3.createTemp();
  Expect.isTrue(await dir3temp.exists());
  // listSync
  List fses = await Directory.current.list().toList();
  Expect.isTrue(fses.any((fse) => fse.path == dir3.path));
  // rename.
  Directory dir4 = new Directory("dir4");
  dir3.renameSync(dir4.path);
  Expect.isTrue(await dir4.exists());
  // delete.
  dir4.deleteSync(recursive: true);
  Expect.isFalse(await dir4.exists());
  // stat.
  FileStat dirstat = await dir2.stat();
  Expect.equals(FileSystemEntityType.DIRECTORY, dirstat.type);
}

List<String> packageOptions() {
  if (Platform.packageRoot != null) {
    return <String>["--package-root=${Platform.packageRoot}"];
  } else if (Platform.packageConfig != null) {
    return <String>["--packages=${Platform.packageConfig}"];
  } else {
    return <String>[];
  }
}

void setupTest() {
  // Create a namespace in /tmp.
  Directory namespace = Directory.systemTemp.createTempSync("namespace");
  try {
    // Create some stuff that should be visible.
    Directory dir1 = new Directory("${namespace.path}/dir1")..createSync();
    Directory dir2 = new Directory("${dir1.path}/dir2")..createSync();
    File file1 = new File("${dir2.path}/file1")
      ..createSync()
      ..writeAsStringSync(file1str);

    // Run the test and capture stdout.
    var args = packageOptions();
    args.addAll([
      "--namespace=${namespace.path}",
      Platform.script.toFilePath(),
      "--run"
    ]);
    var pr = Process.runSync(Platform.executable, args);
    if (pr.exitCode != 0) {
      print("stdout:\n${pr.stdout}");
      print("stderr:\n${pr.stderr}");
    }
    Expect.equals(0, pr.exitCode);
  } finally {
    namespace.deleteSync(recursive: true);
  }
}

main(List<String> arguments) async {
  if (!Platform.isLinux) {
    return;
  }
  if (arguments.contains("--run")) {
    doTestSync();
    await doTestAsync();
  } else {
    setupTest();
  }
}
