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
import 'utils.dart';

String sandbox;

void main() {
  metaSetUp(() {
    // The windows bots are very slow, so we increase the default timeout.
    if (Platform.operatingSystem != "windows") return;
    currentSchedule.timeout = new Duration(seconds: 10);
  });

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
          matches(r"^File not found: '[^']+[\\/]name\.txt'\.$"));
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
      expect(errors.first.error.toString(),
          matches(r"^Directory not found: '[^']+[\\/]dir[\\/]subdir'\.$"));
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
      expect(errors.first.error.toString(),
          matches(r"^File not found: '[^']+[\\/]dir[\\/]file2\.txt'\.$"));
    });
  }, passing: ['test 2']);

  expectTestsPass("directory().validate() fails if multiple children aren't "
      "found or have the wrong contents", () {
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
            new File(path.join(subdirPath, 'subfile2.txt'))
                .writeAsString('subwrongtents2')
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
      expect(errors.first.error.toString(), matches(
          r"^\* File not found: '[^']+[\\/]dir[\\/]subdir[\\/]subfile1\.txt'\."
              r"\n"
          r"\* File 'subfile2\.txt' should contain:\n"
          r"  \| subcontents2\n"
          r"  but actually contained:\n"
          r"  X subwrongtents2\n"
          r"\* File not found: '[^']+[\\/]dir[\\/]file2\.txt'\.$"));
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
      expect(errors.map((e) => e.error.toString()), equals([
        "File 'subfile1.txt' should contain:\n"
        "| subcontents1\n"
        "but actually contained:\n"
        "X wrongtents1"
      ]));
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

      expect(byteStreamToString(dir.load('subdir/name.txt')),
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
          throwsA(equals("Can't read the contents of 'subdir': is a "
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
        d.file('file2.txt', 'contents2')
      ]);

      expect(dir.describe(), equals(
          "dir\n"
          "|-- file1.txt\n"
          "'-- file2.txt"));
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

  expectTestsPass("directory().describe() with no contents returns the "
      "directory name", () {
    test('test', () {
      expect(d.dir('dir').describe(), equals('dir'));
    });
  });

  expectTestsPass("async().create() forwards to file().create", () {
    test('test', () {
      scheduleSandbox();

      d.async(pumpEventQueue().then((_) {
        return d.file('name.txt', 'contents');
      })).create();

      d.file('name.txt', 'contents').validate();
    });
  });

  expectTestsPass("async().create() forwards to directory().create", () {
    test('test', () {
      scheduleSandbox();

      d.async(pumpEventQueue().then((_) {
        return d.dir('dir', [
          d.file('file1.txt', 'contents1'),
          d.file('file2.txt', 'contents2')
        ]);
      })).create();

      d.dir('dir', [
        d.file('file1.txt', 'contents1'),
        d.file('file2.txt', 'contents2')
      ]).validate();
    });
  });

  expectTestsPass("async().validate() forwards to file().validate", () {
    test('test', () {
      scheduleSandbox();

      d.file('name.txt', 'contents').create();

      d.async(pumpEventQueue().then((_) {
        return d.file('name.txt', 'contents');
      })).validate();
    });
  });

  expectTestsPass("async().validate() fails if file().validate fails", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      d.async(pumpEventQueue().then((_) {
        return d.file('name.txt', 'contents');
      })).validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error,
          matches(r"^File not found: '[^']+[\\/]name\.txt'\.$"));
    });
  }, passing: ['test 2']);

  expectTestsPass("async().validate() forwards to directory().validate", () {
    test('test', () {
      scheduleSandbox();

      d.dir('dir', [
        d.file('file1.txt', 'contents1'),
        d.file('file2.txt', 'contents2')
      ]).create();

      d.async(pumpEventQueue().then((_) {
        return d.dir('dir', [
          d.file('file1.txt', 'contents1'),
          d.file('file2.txt', 'contents2')
        ]);
      })).validate();
    });
  });

  expectTestsPass("async().create() fails if directory().create fails", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      d.async(pumpEventQueue().then((_) {
        return d.dir('dir', [
          d.file('file1.txt', 'contents1'),
          d.file('file2.txt', 'contents2')
        ]);
      })).validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error,
          matches(r"^Directory not found: '[^']+[\\/]dir'\.$"));
    });
  }, passing: ['test 2']);

  expectTestsPass("async().load() fails", () {
    test('test', () {
      scheduleSandbox();

      expect(d.async(new Future.immediate(d.file('name.txt')))
              .load('path').toList(),
          throwsA(equals("AsyncDescriptors don't support load().")));
    });
  });

  expectTestsPass("async().read() fails", () {
    test('test', () {
      scheduleSandbox();

      expect(d.async(new Future.immediate(d.file('name.txt'))).read().toList(),
          throwsA(equals("AsyncDescriptors don't support read().")));
    });
  });

  expectTestsPass("nothing().create() does nothing", () {
    test('test', () {
      scheduleSandbox();

      d.nothing('foo').create();

      schedule(() {
        expect(new File(path.join(sandbox, 'foo')).exists(),
            completion(isFalse));
      });

      schedule(() {
        expect(new Directory(path.join(sandbox, 'foo')).exists(),
            completion(isFalse));
      });
    });
  });

  expectTestsPass("nothing().validate() succeeds if nothing's there", () {
    test('test', () {
      scheduleSandbox();

      d.nothing('foo').validate();
    });
  });

  expectTestsPass("nothing().validate() fails if there's a file", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      d.file('name.txt', 'contents').create();
      d.nothing('name.txt').validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error,
          matches(r"^Expected nothing to exist at '[^']+[\\/]name.txt', but "
              r"found a file\.$"));
    });
  }, passing: ['test 2']);

  expectTestsPass("nothing().validate() fails if there's a directory", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      d.dir('dir').create();
      d.nothing('dir').validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error,
          matches(r"^Expected nothing to exist at '[^']+[\\/]dir', but found a "
              r"directory\.$"));
    });
  }, passing: ['test 2']);

  expectTestsPass("nothing().load() fails", () {
    test('test', () {
      scheduleSandbox();

      expect(d.nothing('name.txt').load('path').toList(),
          throwsA(equals("Nothing descriptors don't support load().")));
    });
  });

  expectTestsPass("nothing().read() fails", () {
    test('test', () {
      scheduleSandbox();

      expect(d.nothing('name.txt').read().toList(),
          throwsA(equals("Nothing descriptors don't support read().")));
    });
  });

  expectTestsPass("pattern().validate() succeeds if there's a file matching "
      "the pattern and the child entry", () {
    test('test', () {
      scheduleSandbox();

      d.file('foo', 'blap').create();

      d.filePattern(new RegExp(r'f..'), 'blap').validate();
    });
  });

  expectTestsPass("pattern().validate() succeeds if there's a dir matching "
      "the pattern and the child entry", () {
    test('test', () {
      scheduleSandbox();

      d.dir('foo', [
        d.file('bar', 'baz')
      ]).create();

      d.dirPattern(new RegExp(r'f..'), [
        d.file('bar', 'baz')
      ]).validate();
    });
  });

  expectTestsPass("pattern().validate() succeeds if there's multiple files "
      "matching the pattern but only one matching the child entry", () {
    test('test', () {
      scheduleSandbox();

      d.file('foo', 'blap').create();
      d.file('fee', 'blak').create();
      d.file('faa', 'blut').create();

      d.filePattern(new RegExp(r'f..'), 'blap').validate();
    });
  });

  expectTestsPass("pattern().validate() fails if there's no file matching the "
      "pattern", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      d.filePattern(new RegExp(r'f..'), 'bar').validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error,
          matches(r"^No entry found in '[^']+' matching /f\.\./\.$"));
    });
  }, passing: ['test 2']);

  expectTestsPass("pattern().validate() fails if there's a file matching the "
      "pattern but not the entry", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      d.file('foo', 'bap').create();
      d.filePattern(new RegExp(r'f..'), 'bar').validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error,
          matches(r"^Caught error\n"
              r"| File 'foo' should contain:\n"
              r"| | bar\n"
              r"| but actually contained:\n"
              r"| X bap\n"
              r"while validating\n"
              r"| foo$"));
    });
  }, passing: ['test 2']);

  expectTestsPass("pattern().validate() fails if there's a dir matching the "
      "pattern but not the entry", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      d.dir('foo', [
        d.file('bar', 'bap')
      ]).create();

      d.dirPattern(new RegExp(r'f..'), [
        d.file('bar', 'baz')
      ]).validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error,
          matches(r"^Caught error\n"
              r"| File 'bar' should contain:\n"
              r"| | baz\n"
              r"| but actually contained:\n"
              r"| X bap"
              r"while validating\n"
              r"| foo\n"
              r"| '-- bar$"));
    });
  }, passing: ['test 2']);

  expectTestsPass("pattern().validate() fails if there's multiple files "
      "matching the pattern and the child entry", () {
    var errors;
    test('test 1', () {
      scheduleSandbox();

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      d.file('foo', 'bar').create();
      d.file('fee', 'bar').create();
      d.file('faa', 'bar').create();
      d.filePattern(new RegExp(r'f..'), 'bar').validate();
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error, matches(
              r"^Multiple valid entries found in '[^']+' matching "
                  r"\/f\.\./:\n"
              r"\* faa\n"
              r"\* fee\n"
              r"\* foo$"));
    });
  }, passing: ['test 2']);
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
