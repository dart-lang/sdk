library fileapi;

import 'dart:async';
import 'dart:html';

import 'package:async_helper/async_helper.dart';
import 'package:async_helper/async_minitest.dart';


Future<FileSystem> _fileSystem;

Future<FileSystem> get fileSystem async {
  if (_fileSystem != null) return _fileSystem;

  _fileSystem = window.requestFileSystem(100);

  var fs = await _fileSystem;
  expect(fs != null, true);
  expect(fs.root != null, true);
  expect(fs.runtimeType, FileSystem);
  expect(fs.root.runtimeType, DirectoryEntry);

  return _fileSystem;
}

main() {
  test('supported', () {
    expect(FileSystem.supported, true);
  });

  test('requestFileSystem', () async {
    var expectation = FileSystem.supported ? returnsNormally : throws;
    expect(() async {
      var fs = await fileSystem;
      expect(fs.root != null, true);
    }, expectation);
  });
}

