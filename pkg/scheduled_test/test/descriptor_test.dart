// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library descriptor_test;

import 'dart:async';
import 'dart:io';

import 'package:pathos/path.dart' as path;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

import 'metatest.dart';

String sandbox;

void main() {
  expectTestsPass('file().create() creates a file', () {
    test('test', () {
      scheduleSandbox();

      d.file('name.txt', 'contents').create();

      schedule(() {
        expect(new File(path.join(sandbox, 'name.txt')).readAsString(),
            completion(equals('contents')));
      });
    });
  });

  expectTestsPass('file().create() overwrites an existing file', () {
    test('test', () {
      scheduleSandbox();

      d.file('name.txt', 'contents1').create();

      d.file('name.txt', 'contents2').create();

      schedule(() {
        expect(new File(path.join(sandbox, 'name.txt')).readAsString(),
            completion(equals('contents2')));
      });
    });
  });

  expectTestsPass('file().create() with a RegExp name fails', () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      d.file(new RegExp(r'name\.txt'), 'contents').create();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals([
        r"Pattern /name\.txt/ must be a string."
      ]), verbose: true);
    });
  }, passing: ['test 2']);

  expectTestsPass('file().validate() completes successfully if the filesystem '
      'matches the descriptor', () {
    test('test', () {
      scheduleSandbox();

      schedule(() {
        return new File(path.join(sandbox, 'name.txt'))
            .writeAsString('contents');
      });

      d.file('name.txt', 'contents').validate();
    });
  });

  expectTestsPass("file().validate() fails if there's a file with the wrong "
      "contents", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      schedule(() {
        return new File(path.join(sandbox, 'name.txt'))
            .writeAsString('wrongtents');
      });

      d.file('name.txt', 'contents').validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals([
        "File 'name.txt' should contain:\n"
        "| contents\n"
        "but actually contained:\n"
        "X wrongtents"
      ]), verbose: true);
    });
  }, passing: ['test 2']);

  expectTestsPass("file().validate() fails if there's no file", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      d.file('name.txt', 'contents').validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error,
          matches(r"^File not found: '[^']+/name\.txt'\.$"));
    });
  }, passing: ['test 2']);

  expectTestsPass('file().validate() with a RegExp completes successfully if '
      'the filesystem matches the descriptor', () {
    test('test', () {
      scheduleSandbox();

      schedule(() {
        return new File(path.join(sandbox, 'name.txt'))
            .writeAsString('contents');
      });

      d.file(new RegExp(r'na..\.txt'), 'contents').validate();
    });
  });

  expectTestsPass("file().validate() with a RegExp fails if there's a file "
      "with the wrong contents", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      schedule(() {
        return new File(path.join(sandbox, 'name.txt'))
            .writeAsString('some\nwrongtents');
      });

      d.file(new RegExp(r'na..\.txt'), 'some\ncontents\nand stuff').validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals([
        "File 'name.txt' (matching /na..\\.txt/) should contain:\n"
        "| some\n"
        "| contents\n"
        "| and stuff\n"
        "but actually contained:\n"
        "| some\n"
        "X wrongtents\n"
        "? and stuff"
      ]), verbose: true);
    });
  }, passing: ['test 2']);

  expectTestsPass("file().validate() with a RegExp fails if there's no "
      "file", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      d.file(new RegExp(r'na..\.txt'), 'contents').validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error,
          matches(r"^No entry found in '[^']+' matching /na\.\.\\\.txt/\.$"));
    });
  }, passing: ['test 2']);

  expectTestsPass("file().validate() with a RegExp fails if there are multiple "
      "matching files", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      schedule(() {
        return Future.wait([
          new File(path.join(sandbox, 'name.txt')).writeAsString('contents'),
          new File(path.join(sandbox, 'nape.txt')).writeAsString('contents'),
          new File(path.join(sandbox, 'nail.txt')).writeAsString('contents')
        ]);
      });

      d.file(new RegExp(r'na..\.txt'), 'contents').validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error,
          matches(
              r"^Multiple entries found in '[^']+' matching /na\.\.\\\.txt/:\n"
              r"\* .*/nail\.txt\n"
              r"\* .*/name\.txt\n"
              r"\* .*/nape\.txt"));
    });
  }, passing: ['test 2']);

  expectTestsPass("file().read() returns the contents of the file as a stream",
      () {
    test('test', () {
      expect(byteStreamToString(d.file('name.txt', 'contents').read()),
          completion(equals('contents')));
    });
  });

  expectTestsPass("file().load() throws an error", () {
    test('test', () {
      expect(d.file('name.txt', 'contents').load('path').toList(),
          throwsA(equals("Can't load 'path' from within 'name.txt': not a "
                         "directory.")));
    });
  });

  expectTestsPass("file().describe() returns the filename", () {
    test('test', () {
      expect(d.file('name.txt', 'contents').describe(), equals('name.txt'));
    });
  });

  expectTestsPass("file().describe() with a RegExp describes the file", () {
    test('test', () {
      expect(d.file(new RegExp(r'na..\.txt'), 'contents').describe(),
          equals(r'file matching /na..\.txt/'));
    });
  });

  expectTestsPass('binaryFile().create() creates a file', () {
    test('test', () {
      scheduleSandbox();

      d.binaryFile('name.bin', [1, 2, 3, 4, 5]).create();

      schedule(() {
        expect(new File(path.join(sandbox, 'name.bin')).readAsBytes(),
            completion(equals([1, 2, 3, 4, 5])));
      });
    });
  });

  expectTestsPass('binaryFile().validate() completes successfully if the '
      'filesystem matches the descriptor', () {
    test('test', () {
      scheduleSandbox();

      schedule(() {
        return new File(path.join(sandbox, 'name.bin'))
            .writeAsBytes([1, 2, 3, 4, 5]);
      });

      d.binaryFile('name.bin', [1, 2, 3, 4, 5]).validate();
    });
  });

  expectTestsPass("binaryFile().validate() fails if there's a file with the "
      "wrong contents", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      schedule(() {
        return new File(path.join(sandbox, 'name.bin'))
            .writeAsBytes([2, 4, 6, 8, 10]);
      });

      d.binaryFile('name.bin', [1, 2, 3, 4, 5]).validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals([
        "File 'name.bin' didn't contain the expected binary data."
      ]), verbose: true);
    });
  }, passing: ['test 2']);

  expectTestsPass("directory().create() creates a directory and its contents",
      () {
    test('test', () {
      scheduleSandbox();

      d.dir('dir', [
        d.dir('subdir', [
          d.file('subfile1.txt', 'subcontents1'),
          d.file('subfile2.txt', 'subcontents2')
        ]),
        d.file('file1.txt', 'contents1'),
        d.file('file2.txt', 'contents2')
      ]).create();

      schedule(() {
        expect(new File(path.join(sandbox, 'dir', 'file1.txt')).readAsString(),
            completion(equals('contents1')));
        expect(new File(path.join(sandbox, 'dir', 'file2.txt')).readAsString(),
            completion(equals('contents2')));
        expect(new File(path.join(sandbox, 'dir', 'subdir', 'subfile1.txt'))
                .readAsString(),
            completion(equals('subcontents1')));
        expect(new File(path.join(sandbox, 'dir', 'subdir', 'subfile2.txt'))
                .readAsString(),
            completion(equals('subcontents2')));
      });
    });
  });

  expectTestsPass("directory().create() works if the directory already exists",
      () {
    test('test', () {
      scheduleSandbox();

      d.dir('dir').create();
      d.dir('dir', [d.file('name.txt', 'contents')]).create();

      schedule(() {
        expect(new File(path.join(sandbox, 'dir', 'name.txt')).readAsString(),
            completion(equals('contents')));
      });
    });
  });

  expectTestsPass("directory().create() with a RegExp name fails", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      d.dir(new RegExp('dir')).create();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals([
        "Pattern /dir/ must be a string."
      ]), verbose: true);
    });
  }, passing: ['test 2']);

  expectTestsPass("directory().validate() completes successfully if the "
      "filesystem matches the descriptor", () {
    test('test', () {
      scheduleSandbox();

      schedule(() {
        var dirPath = path.join(sandbox, 'dir');
        var subdirPath = path.join(dirPath, 'subdir');
        return new Directory(subdirPath).create(recursive: true).then((_) {
          return Future.wait([
            new File(path.join(dirPath, 'file1.txt'))
                .writeAsString('contents1'),
            new File(path.join(dirPath, 'file2.txt'))
                .writeAsString('contents2'),
            new File(path.join(subdirPath, 'subfile1.txt'))
                .writeAsString('subcontents1'),
            new File(path.join(subdirPath, 'subfile2.txt'))
                .writeAsString('subcontents2')
          ]);
        });
      });

      d.dir('dir', [
        d.dir('subdir', [
          d.file('subfile1.txt', 'subcontents1'),
          d.file('subfile2.txt', 'subcontents2')
        ]),
        d.file('file1.txt', 'contents1'),
        d.file('file2.txt', 'contents2')
      ]).validate();
    });
  });

  expectTestsPass("directory().validate() fails if a directory isn't found"
      , () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      schedule(() {
        var dirPath = path.join(sandbox, 'dir');
        return new Directory(dirPath).create().then((_) {
          return Future.wait([
            new File(path.join(dirPath, 'file1.txt'))
                .writeAsString('contents1'),
            new File(path.join(dirPath, 'file2.txt'))
                .writeAsString('contents2')
          ]);
        });
      });

      d.dir('dir', [
        d.dir('subdir', [
          d.file('subfile1.txt', 'subcontents1'),
          d.file('subfile2.txt', 'subcontents2')
        ]),
        d.file('file1.txt', 'contents1'),
        d.file('file2.txt', 'contents2')
      ]).validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error,
          matches(r"^Directory not found: '[^']+/dir/subdir'\.$"));
    });
  }, passing: ['test 2']);

  expectTestsPass("directory().validate() fails if a file isn't found", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      schedule(() {
        var dirPath = path.join(sandbox, 'dir');
        var subdirPath = path.join(dirPath, 'subdir');
        return new Directory(subdirPath).create(recursive: true).then((_) {
          return Future.wait([
            new File(path.join(dirPath, 'file1.txt'))
                .writeAsString('contents1'),
            new File(path.join(subdirPath, 'subfile1.txt'))
                .writeAsString('subcontents1'),
            new File(path.join(subdirPath, 'subfile2.txt'))
                .writeAsString('subcontents2')
          ]);
        });
      });

      d.dir('dir', [
        d.dir('subdir', [
          d.file('subfile1.txt', 'subcontents1'),
          d.file('subfile2.txt', 'subcontents2')
        ]),
        d.file('file1.txt', 'contents1'),
        d.file('file2.txt', 'contents2')
      ]).validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error,
          matches(r"^File not found: '[^']+/dir/file2\.txt'\.$"));
    });
  }, passing: ['test 2']);

  expectTestsPass("directory().validate() fails if a file has the wrong "
      "contents", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      schedule(() {
        var dirPath = path.join(sandbox, 'dir');
        var subdirPath = path.join(dirPath, 'subdir');
        return new Directory(subdirPath).create(recursive: true).then((_) {
          return Future.wait([
            new File(path.join(dirPath, 'file1.txt'))
                .writeAsString('contents1'),
            new File(path.join(dirPath, 'file2.txt'))
                .writeAsString('contents2'),
            new File(path.join(subdirPath, 'subfile1.txt'))
                .writeAsString('wrongtents1'),
            new File(path.join(subdirPath, 'subfile2.txt'))
                .writeAsString('subcontents2')
          ]);
        });
      });

      d.dir('dir', [
        d.dir('subdir', [
          d.file('subfile1.txt', 'subcontents1'),
          d.file('subfile2.txt', 'subcontents2')
        ]),
        d.file('file1.txt', 'contents1'),
        d.file('file2.txt', 'contents2')
      ]).validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals([
        "File 'subfile1.txt' should contain:\n"
        "| subcontents1\n"
        "but actually contained:\n"
        "X wrongtents1"
      ]));
    });
  }, passing: ['test 2']);

  expectTestsPass("directory().validate() with a RegExp completes successfully "
      "if the filesystem matches the descriptor", () {
    test('test', () {
      scheduleSandbox();

      schedule(() {
        var dirPath = path.join(sandbox, 'dir');
        var subdirPath = path.join(dirPath, 'subdir');
        return new Directory(subdirPath).create(recursive: true).then((_) {
          return Future.wait([
            new File(path.join(dirPath, 'file1.txt'))
                .writeAsString('contents1'),
            new File(path.join(dirPath, 'file2.txt'))
                .writeAsString('contents2'),
            new File(path.join(subdirPath, 'subfile1.txt'))
                .writeAsString('subcontents1'),
            new File(path.join(subdirPath, 'subfile2.txt'))
                .writeAsString('subcontents2')
          ]);
        });
      });

      d.dir(new RegExp('d.r'), [
        d.dir('subdir', [
          d.file('subfile1.txt', 'subcontents1'),
          d.file('subfile2.txt', 'subcontents2')
        ]),
        d.file('file1.txt', 'contents1'),
        d.file('file2.txt', 'contents2')
      ]).validate();
    });
  });

  expectTestsPass("directory().validate() with a RegExp fails if there's a dir "
      "with the wrong contents", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      schedule(() {
        var dirPath = path.join(sandbox, 'dir');
        var subdirPath = path.join(dirPath, 'subdir');
        return new Directory(subdirPath).create(recursive: true).then((_) {
          return Future.wait([
            new File(path.join(dirPath, 'file1.txt'))
                .writeAsString('contents1'),
            new File(path.join(subdirPath, 'subfile1.txt'))
                .writeAsString('subcontents1'),
            new File(path.join(subdirPath, 'subfile2.txt'))
                .writeAsString('subcontents2')
          ]);
        });
      });

      d.dir(new RegExp('d.r'), [
        d.dir('subdir', [
          d.file('subfile1.txt', 'subcontents1'),
          d.file('subfile2.txt', 'subcontents2')
        ]),
        d.file('file1.txt', 'contents1'),
        d.file('file2.txt', 'contents2')
      ]).validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error,
          matches(r"^File not found: '[^']+/dir/file2\.txt'\.$"));
    });
  }, passing: ['test 2']);

  expectTestsPass("directory().validate() with a RegExp fails if there's no "
      "dir", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      d.dir(new RegExp('d.r'), [
        d.dir('subdir', [
          d.file('subfile1.txt', 'subcontents1'),
          d.file('subfile2.txt', 'subcontents2')
        ]),
        d.file('file1.txt', 'contents1'),
        d.file('file2.txt', 'contents2')
      ]).validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error,
          matches(r"^No entry found in '[^']+' matching /d\.r/\.$"));
    });
  }, passing: ['test 2']);

  expectTestsPass("directory().validate() with a RegExp fails if there are "
      "multiple matching dirs", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      schedule(() {
        return Future.wait(['dir', 'dar', 'dor'].map((dir) {
          var dirPath = path.join(sandbox, dir);
          var subdirPath = path.join(dirPath, 'subdir');
          return new Directory(subdirPath).create(recursive: true).then((_) {
            return Future.wait([
              new File(path.join(dirPath, 'file1.txt'))
                  .writeAsString('contents1'),
              new File(path.join(dirPath, 'file2.txt'))
                  .writeAsString('contents2'),
              new File(path.join(subdirPath, 'subfile1.txt'))
                  .writeAsString('subcontents1'),
              new File(path.join(subdirPath, 'subfile2.txt'))
                  .writeAsString('subcontents2')
            ]);
          });
        }));
      });

      d.dir(new RegExp('d.r'), [
        d.dir('subdir', [
          d.file('subfile1.txt', 'subcontents1'),
          d.file('subfile2.txt', 'subcontents2')
        ]),
        d.file('file1.txt', 'contents1'),
        d.file('file2.txt', 'contents2')
      ]).validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error,
          matches(
              r"^Multiple entries found in '[^']+' matching /d\.r/:\n"
              r"\* .*/dar\n"
              r"\* .*/dir\n"
              r"\* .*/dor"));
    });
  }, passing: ['test 2']);

  expectTestsPass("directory().load() loads a file", () {
    test('test', () {
      var dir = d.dir('dir', [d.file('name.txt', 'contents')]);
      expect(byteStreamToString(dir.load('name.txt')),
          completion(equals('contents')));
    });
  });

  expectTestsPass("directory().load() loads a deeply-nested file", () {
    test('test', () {
      var dir = d.dir('dir', [
        d.dir('subdir', [
          d.file('name.txt', 'subcontents')
        ]),
        d.file('name.txt', 'contents')
      ]);

      expect(byteStreamToString(dir.load(path.join('subdir', 'name.txt'))),
          completion(equals('subcontents')));
    });
  });

  expectTestsPass("directory().read() fails", () {
    test('test', () {
      var dir = d.dir('dir', [d.file('name.txt', 'contents')]);
      expect(dir.read().toList(),
          throwsA(equals("Can't read the contents of 'dir': is a directory.")));
    });
  });

  expectTestsPass("directory().load() fails to load a nested directory", () {
    test('test', () {
      var dir = d.dir('dir', [
        d.dir('subdir', [
          d.file('name.txt', 'subcontents')
        ]),
        d.file('name.txt', 'contents')
      ]);

      expect(dir.load('subdir').toList(),
          throwsA(equals("Can't load the contents of 'subdir': is a "
              "directory.")));
    });
  });

  expectTestsPass("directory().load() fails to load an absolute path", () {
    test('test', () {
      var dir = d.dir('dir', [d.file('name.txt', 'contents')]);

      expect(dir.load('/name.txt').toList(),
          throwsA(equals("Can't load absolute path '/name.txt'.")));
    });
  });

  expectTestsPass("directory().load() fails to load '.', '..', or ''", () {
    test('test', () {
      var dir = d.dir('dir', [d.file('name.txt', 'contents')]);

      expect(dir.load('.').toList(),
          throwsA(equals("Can't load '.' from within 'dir'.")));

      expect(dir.load('..').toList(),
          throwsA(equals("Can't load '..' from within 'dir'.")));

      expect(dir.load('').toList(),
          throwsA(equals("Can't load '' from within 'dir'.")));
    });
  });

  expectTestsPass("directory().load() fails to load a file with a RegExp name",
      () {
    test('test', () {
      var dir = d.dir('dir', [d.file(new RegExp(r'name\.txt'), 'contents')]);

      expect(dir.load('name.txt').toList(),
          throwsA(equals(r"Pattern /name\.txt/ must be a string.")));
    });
  });

  expectTestsPass("directory().load() fails to load a file that doesn't exist",
      () {
    test('test', () {
      var dir = d.dir('dir', [d.file('name.txt', 'contents')]);

      expect(dir.load('not-name.txt').toList(),
          throwsA(equals("Couldn't find an entry named 'not-name.txt' within "
              "'dir'.")));
    });
  });

  expectTestsPass("directory().load() fails to load a file that exists "
      "multiple times", () {
    test('test', () {
      var dir = d.dir('dir', [
        d.file('name.txt', 'contents'),
        d.file('name.txt', 'contents')
      ]);

      expect(dir.load('name.txt').toList(),
          throwsA(equals("Found multiple entries named 'name.txt' within "
              "'dir'.")));
    });
  });

  expectTestsPass("directory().describe() lists the contents of the directory",
      () {
    test('test', () {
      var dir = d.dir('dir', [
        d.file('file1.txt', 'contents1'),
        d.file('file2.txt', 'contents2'),
        d.file(new RegExp(r're\.txt'), 're-contents')
      ]);

      expect(dir.describe(), equals(
          "dir\n"
          "|-- file1.txt\n"
          "|-- file2.txt\n"
          "'-- file matching /re\\.txt/"));
    });
  });

  expectTestsPass("directory().describe() lists the contents of nested "
      "directories", () {
    test('test', () {
      var dir = d.dir('dir', [
        d.file('file1.txt', 'contents1'),
        d.dir('subdir', [
          d.file('subfile1.txt', 'subcontents1'),
          d.file('subfile2.txt', 'subcontents2'),
          d.dir('subsubdir', [
            d.file('subsubfile.txt', 'subsubcontents')
          ])
        ]),
        d.file('file2.txt', 'contents2')
      ]);

      expect(dir.describe(), equals(
          "dir\n"
          "|-- file1.txt\n"
          "|-- subdir\n"
          "|   |-- subfile1.txt\n"
          "|   |-- subfile2.txt\n"
          "|   '-- subsubdir\n"
          "|       '-- subsubfile.txt\n"
          "'-- file2.txt"));
    });
  });

  expectTestsPass("directory().describe() with a RegExp describes the "
      "directory", () {
    test('test', () {
      var dir = d.dir(new RegExp(r'd.r'), [
        d.file('file1.txt', 'contents1'),
        d.file('file2.txt', 'contents2')
      ]);

      expect(dir.describe(), equals(
          "directory matching /d.r/\n"
          "|-- file1.txt\n"
          "'-- file2.txt"));
    });
  });

  expectTestsPass("directory().describe() with no contents returns the "
      "directory name", () {
    test('test', () {
      expect(d.dir('dir').describe(), equals('dir'));
    });
  });
}

void scheduleSandbox() {
  schedule(() {
    return new Directory('').createTemp().then((dir) {
      sandbox = dir.path;
      d.defaultRoot = sandbox;
    });
  });

  currentSchedule.onComplete.schedule(() {
    d.defaultRoot = null;
    if (sandbox == null) return;
    var oldSandbox = sandbox;
    sandbox = null;
    return new Directory(oldSandbox).delete(recursive: true);
  });
}

Future<List<int>> byteStreamToList(Stream<List<int>> stream) {
  return stream.reduce(<int>[], (buffer, chunk) {
    buffer.addAll(chunk);
    return buffer;
  });
}

Future<String> byteStreamToString(Stream<List<int>> stream) =>
  byteStreamToList(stream).then((bytes) => new String.fromCharCodes(bytes));
