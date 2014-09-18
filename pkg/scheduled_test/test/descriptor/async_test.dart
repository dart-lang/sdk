// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:metatest/metatest.dart';
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

import 'utils.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  setUpTimeout();

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
      expect(errors.single, new isInstanceOf<ScheduleError>());
      expect(errors.single.error.toString(),
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
      expect(errors.single, new isInstanceOf<ScheduleError>());
      expect(errors.single.error.toString(),
          matches(r"^Directory not found: '[^']+[\\/]dir'\.$"));
    });
  }, passing: ['test 2']);
}
