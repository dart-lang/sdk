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
}