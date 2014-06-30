// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../metatest.dart';
import '../utils.dart';

void main(_, message) {
  initMetatest(message);

  setUpTimeout();

  expectTestsPass('tearDown is run synchronously after each test', () {
    var tearDownRun = false;
    tearDown(() {
      tearDownRun = true;
      schedule(() => tearDownRun = false);
    });

    test('test 1', () {
      expect(tearDownRun, isFalse);
      schedule(() => expect(tearDownRun, isTrue));
    });

    test('test 2', () {
      expect(tearDownRun, isFalse);
      schedule(() => expect(tearDownRun, isTrue));
    });
  });

  expectTestsPass('tearDown can schedule events', () {
    var tearDownRun = false;
    tearDown(() {
      schedule(() => tearDownRun = true);
    });

    test('test 1', () {
      schedule(() => expect(tearDownRun, isFalse));
    });

    test('test 2', () {
      expect(tearDownRun, isTrue);
    });
  });

  expectTestsFail('synchronous errors in tearDown cause tests to fail', () {
    tearDown(() => expect('foo', equals('bar')));
    test('test 1', () => expect('foo', equals('foo')));
    test('test 2', () => expect('foo', equals('foo')));
  });

  expectTestsFail('scheduled errors in tearDown cause tests to fail', () {
    tearDown(() => schedule(() => expect('foo', equals('bar'))));
    test('test 1', () => expect('foo', equals('foo')));
    test('test 2', () => expect('foo', equals('foo')));
  });

  expectTestsPass('synchronous errors in tearDown cause onException to run',
      () {
    var onExceptionRun = false;
    tearDown(() {
      currentSchedule.onException.schedule(() {
        onExceptionRun = true;
      });

      if (!onExceptionRun) expect('foo', equals('bar'));
    });

    test('test 1', () => expect('foo', equals('foo')));
    test('test 2', () => expect(onExceptionRun, isTrue));
  }, passing: ['test 2']);

  expectTestsPass("tearDown applies to child groups", () {
    var tearDownRun = false;
    tearDown(() {
      tearDownRun = true;
      schedule(() => tearDownRun = false);
    });

    test('outer', () {
      expect(tearDownRun, isFalse);
      schedule(() => expect(tearDownRun, isTrue));
    });

    group('group', () {
      test('inner', () {
        expect(tearDownRun, isFalse);
        schedule(() => expect(tearDownRun, isTrue));
      });
    });
  });

  expectTestsPass("tearDown doesn't apply to parent groups", () {
    var tearDownRun = false;
    group('group', () {
      tearDown(() {
        tearDownRun = true;
        schedule(() => tearDownRun = false);
      });

      test('inner', () {
        expect(tearDownRun, isFalse);
        schedule(() => expect(tearDownRun, isTrue));
      });
    });

    test('outer', () {
      expect(tearDownRun, isFalse);
      schedule(() => expect(tearDownRun, isFalse));
    });
  });

  expectTestsPass("tearDown doesn't apply to sibling groups", () {
    var tearDownRun = false;
    group('group 1', () {
      tearDown(() {
        tearDownRun = true;
        schedule(() => tearDownRun = false);
      });

      test('test', () {
        expect(tearDownRun, isFalse);
        schedule(() => expect(tearDownRun, isTrue));
      });
    });

    group('group 2', () {
      test('test', () {
        expect(tearDownRun, isFalse);
        schedule(() => expect(tearDownRun, isFalse));
      });
    });
  });

  expectTestsPass("tearDown calls are chained", () {
    var outerTearDownRun = false;
    var innerTearDownRun = false;
    group('outer group', () {
      tearDown(() {
        expect(innerTearDownRun, isFalse);
        outerTearDownRun = true;
        schedule(() => outerTearDownRun = false);
      });

      group('intermediate group with no tearDown', () {
        group('inner group', () {
          tearDown(() {
            innerTearDownRun = true;
            schedule(() => innerTearDownRun = false);
          });

          test('inner', () {
            expect(outerTearDownRun, isFalse);
            expect(innerTearDownRun, isFalse);
            schedule(() {
              expect(outerTearDownRun, isTrue);
              expect(innerTearDownRun, isTrue);
            });
          });
        });
      });

      test('outer', () {
        expect(outerTearDownRun, isFalse);
        expect(innerTearDownRun, isFalse);
        schedule(() {
          expect(outerTearDownRun, isTrue);
          expect(innerTearDownRun, isFalse);
        });
      });
    });

    test('top', () {
      expect(outerTearDownRun, isFalse);
      expect(innerTearDownRun, isFalse);
      schedule(() {
        expect(outerTearDownRun, isFalse);
        expect(innerTearDownRun, isFalse);
      });
    });
  });

  expectTestsPass("a future returned by tearDown is implicitly wrapped", () {
    var futureComplete = false;
    tearDown(() => pumpEventQueue().then((_) => futureComplete = true));

    test('test', () {
      currentSchedule.onComplete.schedule(() => expect(futureComplete, isTrue));
    });
  });

  expectTestsPass("a future returned by tearDown should not block the schedule",
      () {
    var futureComplete = false;
    tearDown(() => pumpEventQueue().then((_) => futureComplete = true));

    test('test', () {
      schedule(() => expect(futureComplete, isFalse));
    });
  });
}
