// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

import 'package:metatest/metatest.dart';
import 'utils.dart';

String sandbox;

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  setUpTimeout();

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
      expect(errors.single, new isInstanceOf<ScheduleError>());
      expect(errors.single.error.toString(),
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
      expect(errors.single, new isInstanceOf<ScheduleError>());
      expect(errors.single.error.toString(),
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
      expect(errors.single, new isInstanceOf<ScheduleError>());
      expect(errors.single.error.toString(),
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
      expect(errors.single, new isInstanceOf<ScheduleError>());
      expect(errors.single.error.toString(), matches(
          r"^Multiple valid entries found in '[^']+' matching "
          r"\/f\.\./:\n"
          r"\* faa\n"
          r"\* fee\n"
          r"\* foo$"));
    });
  }, passing: ['test 2']);
}
