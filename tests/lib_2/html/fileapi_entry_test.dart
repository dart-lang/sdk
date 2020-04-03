library fileapi;

import 'dart:async';
import 'dart:html';

import 'package:async_helper/async_helper.dart';
import 'package:async_helper/async_minitest.dart';

class FileAndDir {
  FileEntry file;
  DirectoryEntry dir;
  FileAndDir(this.file, this.dir);
}

FileSystem fs;

main() async {
  getFileSystem() async {
    return await window.requestFileSystem(100).then((FileSystem fileSystem) {
      fs = fileSystem;
    });
  }

  // Do the boilerplate to get several files and directories created to then
  // test the functions that use those items.
  Future doDirSetup(String testName) async {
    await getFileSystem();

    var file = await fs.root.createFile('file_$testName');
    var dir = await fs.root.createDirectory('dir_$testName');
    return new Future.value(new FileAndDir(file, dir));
  }

  if (FileSystem.supported) {
    test('copy_move', () async {
      var fileAndDir = await doDirSetup('copyTo');
      var entry = await fileAndDir.file.copyTo(fileAndDir.dir, name: 'copiedFile');
      expect(entry.isFile, true, reason: "Expected File");
      expect(entry.name, 'copiedFile');

      // getParent
      fileAndDir = await doDirSetup('getParent');
      entry = await fileAndDir.file.getParent();
      expect(entry.name, '');
      expect(entry.isDirectory, true, reason: "Expected Directory");

      // moveTo
      fileAndDir = await doDirSetup('moveTo');
      entry = await fileAndDir.file.moveTo(fileAndDir.dir, name: 'movedFile');
      expect(entry.name, 'movedFile');
      expect(entry.fullPath, '/dir_moveTo/movedFile');

      try {
        entry = await fs.root.getFile('file4');
        fail("File file4 should not exist.");
      } catch (error) {
        expect(error is DomException, true, reason: "Not DomException - not exist");
        expect(DomException.NOT_FOUND, error.name);
      }

      // remove
      fileAndDir = await doDirSetup('remove');
      expect('file_remove', fileAndDir.file.name);
      await fileAndDir.file.remove();
      try {
        var entry = await fileAndDir.dir.getFile(fileAndDir.file.name);
        fail("file not removed");
      } catch (error) {
        expect(error is DomException, true, reason: "Not DomException - removed");
        expect(DomException.NOT_FOUND, error.name);
      }
    });
  }
}
