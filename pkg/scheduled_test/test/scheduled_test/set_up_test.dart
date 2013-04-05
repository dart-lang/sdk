// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:scheduled_test/scheduled_test.dart';

import '../metatest.dart';
import '../utils.dart';

void main() {
  setUpTimeout();

  expectTestsPass('setUp is run before each test', () {
    var setUpRun = false;
    setUp(() {
      setUpRun = true;
    });

    test('test 1', () {
      expect(setUpRun, isTrue);
      setUpRun = false;
    });

    test('test 2', () {
      expect(setUpRun, isTrue);
      setUpRun = false;
    });
  });

  expectTestsPass('setUp can schedule events', () {
    var setUpRun = false;
    setUp(() {
      schedule(() {
        setUpRun = true;
      });
      currentSchedule.onComplete.schedule(() {
        setUpRun = false;
      });
    });

    test('test 1', () {
      expect(setUpRun, isFalse);
      schedule(() => expect(setUpRun, isTrue));
    });

    test('test 2', () {
      expect(setUpRun, isFalse);
      schedule(() => expect(setUpRun, isTrue));
    });
  });

  expectTestsFail('synchronous errors in setUp will cause tests to fail', () {
    setUp(() => expect('foo', equals('bar')));
    test('test 1', () => expect('foo', equals('foo')));
    test('test 2', () => expect('foo', equals('foo')));
  });

  expectTestsFail('scheduled errors in setUp will cause tests to fail', () {
    setUp(() => schedule(() => expect('foo', equals('bar'))));
    test('test 1', () => expect('foo', equals('foo')));
    test('test 2', () => expect('foo', equals('foo')));
  });

  expectTestsPass('synchronous errors in setUp will cause onException to run',
      () {
    var onExceptionRun = false;
    setUp(() {
      currentSchedule.onException.schedule(() {
        onExceptionRun = true;
      });

      if (!onExceptionRun) expect('foo', equals('bar'));
    });

    test('test 1', () => expect('foo', equals('foo')));
    test('test 2', () => expect(onExceptionRun, isTrue));
  }, passing: ['test 2']);

  expectTestsPass("setUp doesn't apply to child groups", () {
    var setUpRun = false;
    setUp(() {
      setUpRun = true;
      currentSchedule.onComplete.schedule(() {
        setUpRun = false;
      });
    });

    test('outer', () {
      expect(setUpRun, isTrue);
    });

    group('group', () {
      test('inner', () {
        expect(setUpRun, isFalse);
      });
    });
  });

  expectTestsPass("setUp doesn't apply to parent groups", () {
    var setUpRun = false;
    group('group', () {
      setUp(() {
        setUpRun = true;
        currentSchedule.onComplete.schedule(() {
          setUpRun = false;
        });
      });

      test('inner', () {
        expect(setUpRun, isTrue);
      });
    });

    test('outer', () {
      expect(setUpRun, isFalse);
    });
  });

  expectTestsPass("setUp doesn't apply to sibling groups", () {
    var setUpRun = false;
    group('group 1', () {
      setUp(() {
        setUpRun = true;
        currentSchedule.onComplete.schedule(() {
          setUpRun = false;
        });
      });

      test('test 1', () {
        expect(setUpRun, isTrue);
      });
    });

    group('group 2', () {
      test('test 2', () {
        expect(setUpRun, isFalse);
      });
    });
  });
}