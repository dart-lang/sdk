// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import 'package:metatest/metatest.dart';
import '../utils.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

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

  expectTestsPass("setUp applies to child groups", () {
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
        expect(setUpRun, isTrue);
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

  expectTestsPass("setUp calls are chained", () {
    var setUpOuterRun = false;
    var setUpInnerRun = false;
    group('outer group', () {
      setUp(() {
        setUpOuterRun = true;
        currentSchedule.onComplete.schedule(() {
          setUpOuterRun = false;
        });
      });
      group('intermediate group with no setUp', () {
        group('inner group', () {
          setUp(() {
            setUpInnerRun = true;
            currentSchedule.onComplete.schedule(() {
              setUpInnerRun = false;
            });
          });
          test('inner', () {
            expect(setUpOuterRun, isTrue);
            expect(setUpInnerRun, isTrue);
          });
        });
      });
      test('outer', () {
        expect(setUpOuterRun, isTrue);
        expect(setUpInnerRun, isFalse);
      });
    });

    test('top', () {
      expect(setUpOuterRun, isFalse);
      expect(setUpInnerRun, isFalse);
    });
  });

  expectTestsPass("a future returned by setUp is implicitly wrapped", () {
    var futureComplete = false;
    setUp(() => pumpEventQueue().then((_) => futureComplete = true));

    test('test', () {
      currentSchedule.onComplete.schedule(() => expect(futureComplete, isTrue));
    });
  });

  expectTestsPass("a future returned by setUp should not block test()", () {
    var futureComplete = false;
    setUp(() => pumpEventQueue().then((_) => futureComplete = true));

    test('test', () {
      expect(futureComplete, isFalse);
    });
  });

  expectTestsPass("a future returned by setUp should not block the schedule",
      () {
    var futureComplete = false;
    setUp(() => pumpEventQueue().then((_) => futureComplete = true));

    test('test', () {
      schedule(() => expect(futureComplete, isFalse));
    });
  });
}
