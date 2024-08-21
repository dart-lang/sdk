// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';
import 'package:reload_test/hot_reload_memory_filesystem.dart';

void main() {
  late Directory testDirectory;
  late Uri jsOutputUri;

  setUp(() {
    testDirectory = Directory.systemTemp.createTempSync('test_file_system');
    jsOutputUri = testDirectory.uri.resolve('js/');
    Directory.fromUri(jsOutputUri).createSync();
  });
  tearDown(() {
    testDirectory.deleteSync(recursive: true);
  });
  test("Web filesystem behaves correctly across generations.", () {
    // Initialize the filesystem and register two test files with their
    // corresponding sourcemaps.
    final filesystem = HotReloadMemoryFilesystem(jsOutputUri);

    final source1 = '''
      file1() {
        foo();
      }
      ''';
    final source2 = '''
      file2() {
        bar();
      }
      ''';
    final sources = '$source1$source2'.codeUnits;
    final sourcesFile = File.fromUri(testDirectory.uri.resolve('test.sources'))
      ..writeAsBytesSync(sources);
    final sourcemap1 = '{map1}';
    final sourcemap2 = '{map2}';
    final sourcemap = '$sourcemap1$sourcemap2'.codeUnits;
    final sourcemapFile = File.fromUri(testDirectory.uri.resolve('test.map'))
      ..writeAsBytesSync(sourcemap);

    final manifest = '''
      {
        "/file1.ext": {
          "code": [0, ${source1.codeUnits.length}],
          "sourcemap": [0, ${sourcemap1.codeUnits.length}]
        },
        "/file2.ext": {
          "code": [
            ${source1.codeUnits.length},
            ${source1.codeUnits.length + source2.codeUnits.length}
          ],
          "sourcemap":[
            ${sourcemap1.codeUnits.length},
            ${sourcemap1.codeUnits.length + sourcemap2.codeUnits.length}
          ]
        }
      }
      '''
        .codeUnits;
    final manifestFile = File.fromUri(testDirectory.uri.resolve('test.json'))
      ..writeAsBytesSync(manifest);

    var updatedFiles = filesystem
        .update(sourcesFile, manifestFile, sourcemapFile, generation: "0");

    expect(updatedFiles, equals(['file1.ext', 'file2.ext']),
        reason: 'Updated files are correctly reported.');

    expect(
        filesystem.files,
        equals(
            {'file1.ext': source1.codeUnits, 'file2.ext': source2.codeUnits}),
        reason: 'Filesystem source files are correctly stored.');

    expect(
        filesystem.sourcemaps,
        equals({
          'file1.ext.map': sourcemap1.codeUnits,
          'file2.ext.map': sourcemap2.codeUnits,
        }),
        reason: 'Filesystem sourcemaps are correctly stored.');

    expect(
        filesystem.generationsToModifiedFilePaths,
        equals({
          '0': [
            [
              'file1.ext',
              jsOutputUri.resolve('generation0/file1.ext').toFilePath()
            ],
            [
              'file2.ext',
              jsOutputUri.resolve('generation0/file2.ext').toFilePath()
            ]
          ]
        }),
        reason:
            'Filesystem emits correct generation to modfied files mapping.');

    // Update the filesystem with two more files in the next generation.

    final manifest2 = '''
      {
        "/file3.ext": {
          "code": [0, ${source1.codeUnits.length}],
          "sourcemap": [0, ${sourcemap1.codeUnits.length}]
        },
        "/file4.ext": {
          "code": [
            ${source1.codeUnits.length},
            ${source1.codeUnits.length + source2.codeUnits.length}
          ],
          "sourcemap":[
            ${sourcemap1.codeUnits.length},
            ${sourcemap1.codeUnits.length + sourcemap2.codeUnits.length}
          ]
        }
      }
      '''
        .codeUnits;
    manifestFile.writeAsBytesSync(manifest2);

    updatedFiles = filesystem.update(sourcesFile, manifestFile, sourcemapFile,
        generation: "1");

    expect(updatedFiles, equals(['file3.ext', 'file4.ext']),
        reason: 'Updated files are correctly reported.');

    expect(
        filesystem.files,
        equals({
          'file1.ext': source1.codeUnits,
          'file2.ext': source2.codeUnits,
          'file3.ext': source1.codeUnits,
          'file4.ext': source2.codeUnits,
        }),
        reason: 'Filesystem source files are correctly stored.');

    expect(
        filesystem.sourcemaps,
        equals({
          'file1.ext.map': sourcemap1.codeUnits,
          'file2.ext.map': sourcemap2.codeUnits,
          'file3.ext.map': sourcemap1.codeUnits,
          'file4.ext.map': sourcemap2.codeUnits,
        }),
        reason: 'Filesystem sourcemaps are correctly stored.');

    expect(
        filesystem.generationsToModifiedFilePaths,
        equals({
          '0': [
            [
              'file1.ext',
              jsOutputUri.resolve('generation0/file1.ext').toFilePath()
            ],
            [
              'file2.ext',
              jsOutputUri.resolve('generation0/file2.ext').toFilePath()
            ]
          ],
          '1': [
            [
              'file3.ext',
              jsOutputUri.resolve('generation1/file3.ext').toFilePath()
            ],
            [
              'file4.ext',
              jsOutputUri.resolve('generation1/file4.ext').toFilePath()
            ],
          ],
        }),
        reason:
            'Filesystem emits correct generation to modfied files mapping.');

    expect(
        filesystem.scriptDescriptorForBootstrap,
        equals([
          {
            'id': 'file1.ext',
            'src': jsOutputUri.resolve('generation0/file1.ext').toFilePath(),
          },
          {
            'id': 'file2.ext',
            'src': jsOutputUri.resolve('generation0/file2.ext').toFilePath(),
          },
        ]),
        reason: 'Filesystem emits correct script descriptors.');

    // Write files and check that the filesystem's state is properly cleared.
    expect(
        File(jsOutputUri.resolve('generation3/file1.ext').toFilePath())
            .existsSync(),
        isFalse);
    expect(
        File(jsOutputUri.resolve('generation3/file2.ext').toFilePath())
            .existsSync(),
        isFalse);
    expect(
        File(jsOutputUri.resolve('generation3/file3.ext').toFilePath())
            .existsSync(),
        isFalse);
    expect(
        File(jsOutputUri.resolve('generation3/file4.ext').toFilePath())
            .existsSync(),
        isFalse);
    filesystem.writeToDisk(jsOutputUri, generation: "3");
    expect(
        File(jsOutputUri.resolve('generation3/file1.ext').toFilePath())
            .existsSync(),
        isTrue);
    expect(
        File(jsOutputUri.resolve('generation3/file2.ext').toFilePath())
            .existsSync(),
        isTrue);
    expect(
        File(jsOutputUri.resolve('generation3/file3.ext').toFilePath())
            .existsSync(),
        isTrue);
    expect(
        File(jsOutputUri.resolve('generation3/file4.ext').toFilePath())
            .existsSync(),
        isTrue);
    expect(filesystem.files, isEmpty,
        reason: 'Filesystem clears files after writing to disk.');
    expect(filesystem.sourcemaps, isEmpty,
        reason: 'Filesystem clears sourcemaps after writing to disk.');

    // Check that subsequent writes don't emit already-emitted files.
    File(jsOutputUri.resolve('generation3/file1.ext').toFilePath())
        .deleteSync();
    File(jsOutputUri.resolve('generation3/file2.ext').toFilePath())
        .deleteSync();
    File(jsOutputUri.resolve('generation3/file3.ext').toFilePath())
        .deleteSync();
    File(jsOutputUri.resolve('generation3/file4.ext').toFilePath())
        .deleteSync();
    filesystem.writeToDisk(jsOutputUri, generation: "3");
    expect(
        File(jsOutputUri.resolve('generation3/file1.ext').toFilePath())
            .existsSync(),
        isFalse);
    expect(
        File(jsOutputUri.resolve('generation3/file2.ext').toFilePath())
            .existsSync(),
        isFalse);
    expect(
        File(jsOutputUri.resolve('generation3/file3.ext').toFilePath())
            .existsSync(),
        isFalse);
    expect(
        File(jsOutputUri.resolve('generation3/file4.ext').toFilePath())
            .existsSync(),
        isFalse);
  });
}
