// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library substitute_future_test;

import 'dart:async';

import 'package:scheduled_test/src/substitute_future.dart';
import 'package:unittest/unittest.dart';

void main() {
  group('with no substitution, works like a normal Future for', () {
    var completer;
    var future;

    setUp(() {
      completer = new Completer();
      future = new SubstituteFuture(completer.future);
    });

    test('.asStream on success', () {
      expect(future.asStream().toList(), completion(equals(['success'])));
      completer.complete('success');
    });

    test('.asStream on error', () {
      expect(future.asStream().toList(), throwsA(equals('error')));
      completer.completeError('error');
    });

    test('.then and .catchError on success', () {
      expect(future.then((v) => "transformed $v")
              .catchError((error) => "caught ${error}"),
          completion(equals('transformed success')));
      completer.complete('success');
    });

    test('.then and .catchError on error', () {
      expect(future.then((v) => "transformed $v")
              .catchError((error) => "caught ${error}"),
          completion(equals('caught error')));
      completer.completeError('error');
    });

    test('.then with onError on success', () {
      expect(future.then((v) => "transformed $v",
              onError: (error) => "caught ${error}"),
          completion(equals('transformed success')));
      completer.complete('success');
    });

    test('.then with onError on error', () {
      expect(future.then((v) => "transformed $v",
              onError: (error) => "caught ${error}"),
          completion(equals('caught error')));
      completer.completeError('error');
    });

    test('.whenComplete on success', () {
      expect(future.whenComplete(() {
        throw 'whenComplete';
      }), throwsA(equals('whenComplete')));
      completer.complete('success');
    });

    test('.whenComplete on error', () {
      expect(future.whenComplete(() {
        throw 'whenComplete';
      }), throwsA(equals('whenComplete')));
      completer.completeError('error');
    });
  });

  group('with a single substitution', () {
    var oldCompleter;
    var oldFuture;
    var newCompleter;
    var future;

    setUp(() {
      oldCompleter = new Completer();
      future = new SubstituteFuture(oldCompleter.future);
      newCompleter = new Completer();
      oldFuture = future.substitute(newCompleter.future);
    });

    test('pipes a success from the new future to the substitute future, and '
        'from the old future to the return value of .substitute', () {
      expect(oldFuture, completion(equals('old')));
      expect(future, completion(equals('new')));

      oldCompleter.complete('old');
      newCompleter.complete('new');
    });

    test('pipes an error from the new future to the substitute future, and '
        'from the old future to the return value of .substitute', () {
      expect(oldFuture, throwsA(equals('old')));
      expect(future, throwsA(equals('new')));

      oldCompleter.completeError('old');
      newCompleter.completeError('new');
    });
  });

  group('with multiple substitutions', () {
    var completer1;
    var completer2;
    var completer3;
    var future1;
    var future2;
    var future;

    setUp(() {
      completer1 = new Completer();
      completer2 = new Completer();
      completer3 = new Completer();
      future = new SubstituteFuture(completer1.future);
      future1 = future.substitute(completer2.future);
      future2 = future.substitute(completer3.future);
    });

    test('pipes a success from the newest future to the substitute future, and '
        'from the old futures to the return values of .substitute', () {
      expect(future1, completion(equals(1)));
      expect(future2, completion(equals(2)));
      expect(future, completion(equals(3)));

      completer1.complete(1);
      completer2.complete(2);
      completer3.complete(3);
    });

    test('pipes an error from the newest future to the substitute future, and '
        'from the old futures to the return values of .substitute', () {
      expect(future1, throwsA(equals(1)));
      expect(future2, throwsA(equals(2)));
      expect(future, throwsA(equals(3)));

      completer1.completeError(1);
      completer2.completeError(2);
      completer3.completeError(3);
    });
  });

  test('substituting after a future has completed is an error', () {
    var completer = new Completer();
    var future = new SubstituteFuture(completer.future);
    completer.complete('success');
    expect(() => future.substitute(new Future.value()),
        throwsStateError);
  });
}
