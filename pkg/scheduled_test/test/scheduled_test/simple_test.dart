// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:scheduled_test/scheduled_test.dart';

import 'package:metatest/metatest.dart';
import '../utils.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  setUpTimeout();

  expectTestsPass('a scheduled test with a correct synchronous expectation '
      'should pass', () {
    test('test', () {
      expect('foo', equals('foo'));
    });
  });

  expectTestsFail('a scheduled test with an incorrect synchronous expectation '
      'should fail', () {
    test('test', () {
      expect('foo', equals('bar'));
    });
  });

  expectTestsPass('a scheduled test with a correct asynchronous expectation '
      'should pass', () {
    test('test', () {
      expect(new Future.value('foo'), completion(equals('foo')));
    });
  });

  expectTestsFail('a scheduled test with an incorrect asynchronous expectation '
      'should fail', () {
    test('test', () {
      expect(new Future.value('foo'), completion(equals('bar')));
    });
  });

  expectTestsPass('a passing scheduled synchronous expect should register', () {
    test('test', () {
      schedule(() => expect('foo', equals('foo')));
    });
  });

  expectTestsFail('a failing scheduled synchronous expect should register', () {
    test('test', () {
      schedule(() => expect('foo', equals('bar')));
    });
  });

  expectTestsPass('a passing scheduled asynchronous expect should '
      'register', () {
    test('test', () {
      schedule(() =>
          expect(new Future.value('foo'), completion(equals('foo'))));
    });
  });

  expectTestsFail('a failing scheduled synchronous expect should '
      'register', () {
    test('test', () {
      schedule(() =>
          expect(new Future.value('foo'), completion(equals('bar'))));
    });
  });

  expectTestsPass('scheduled blocks should be run in order after the '
      'synchronous setup', () {
    test('test', () {
      var list = [1];
      schedule(() => list.add(2));
      list.add(3);
      schedule(() => expect(list, equals([1, 3, 4, 2])));
      list.add(4);
    });
  });

  expectTestsPass('scheduled blocks should forward their return values as '
      'Futures', () {
    test('synchronous value', () {
      var future = schedule(() => 'value');
      expect(future, completion(equals('value')));
    });

    test('asynchronous value', () {
      var future = schedule(() => new Future.value('value'));
      expect(future, completion(equals('value')));
    });
  });

  expectTestsPass('scheduled blocks should wait for their Future return values '
      'to complete before proceeding', () {
    test('test', () {
      var value = 'unset';
      schedule(() => pumpEventQueue().then((_) {
        value = 'set';
      }));
      schedule(() => expect(value, equals('set')));
    });
  });

  expectTestsFail('a test failure in a chained future in a scheduled block '
      'should be registered', () {
    test('test', () {
      schedule(() => new Future.value('foo')
          .then((v) => expect(v, equals('bar'))));
    });
  });

  expectTestsFail('an error in a chained future in a scheduled block should be '
      'registered', () {
    test('test', () {
      schedule(() => new Future.value().then((_) {
        throw 'error';
      }));
    });
  });
}
