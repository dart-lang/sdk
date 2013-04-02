// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:pathos/path.dart' as path;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

import '../metatest.dart';
import 'utils.dart';

void main() {
  setUpTimeout();

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
}