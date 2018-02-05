library fileapi;

import 'dart:async';
import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:async_helper/async_helper.dart';

FileSystem fs;

main() async {
  useHtmlConfiguration();

  getFileSystem() async {
    var fileSystem = await window.requestFileSystem(100);
    fs = fileSystem;
  }

  if (FileSystem.supported) {
    await getFileSystem();

    test('fileDoesntExist', () async {
      try {
        var fileObj = await fs.root.getFile('file2');
        fail("file found");
      } catch (error) {
        expect(true, error is DomException);
        expect(DomException.NOT_FOUND, error.name);
      }
    });

    test('fileCreate', () async {
      var fileObj = await fs.root.createFile('file4');
      expect(fileObj.name, equals('file4'));
      expect(fileObj.isFile, isTrue);

      var metadata = await fileObj.getMetadata();
      var changeTime = metadata.modificationTime;

      // Increased Windows buildbots can sometimes be particularly slow.
      expect(new DateTime.now().difference(changeTime).inMinutes, lessThan(4));
      expect(metadata.size, equals(0));
    });
  }
}

