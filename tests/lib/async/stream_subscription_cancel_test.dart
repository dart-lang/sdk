// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the StreamSubscription.cancel return Future.
library stream_subscription_cancel;

import 'dart:async';
import 'package:unittest/unittest.dart';

void main() {
  test('subscription.cancel', () {
    var completer = new Completer();
    StreamController controller = new StreamController(
        onCancel: () => completer.future);

    bool done = false;
    expect(controller.stream.listen(null).cancel().then((_) => done),
           completion(equals(true)));

    Timer.run(() {
      done = true;
      completer.complete();
    });
  });

  test('subscription.cancel after close', () {
    var completer = new Completer();
    StreamController controller = new StreamController(
        onCancel: completer.complete);

    controller.close();

    var sub;
    void onDone() {
      expect(sub.cancel(), isNull);
    }

    sub = controller.stream.listen(null, onDone: onDone);
    expect(completer.future, completes);
  });

  test('subscription.cancel after error', () {
    var completer = new Completer();
    StreamController controller = new StreamController(
        onCancel: () => completer.future);

    controller.addError("error");

    bool done = false;

    var subscription;
    var doneCompleter = new Completer();
    void onError(e) {
      subscription.cancel().then((_) => doneCompleter.complete(done));
      done = true;
      completer.complete();
    }
    subscription = controller.stream.listen(null, onError: onError);
    expect(doneCompleter.future, completion(equals(true)));
  });

  test('subscription.cancel after error (cancelOnError)', () {
    bool called = false;
    StreamController controller = new StreamController(
        onCancel: () {
          called = true;
        });

    controller.addError("error");

    var doneCompleter = new Completer();
    void onError(e) {
      expect(called, equals(true));
      doneCompleter.complete(true);
    }
    controller.stream.listen(null, onError: onError, cancelOnError: true);
    expect(doneCompleter.future, completion(equals(true)));
  });

  test('subscription.cancel before error (cancelOnError)', () {
    var doneCompleter = new Completer();
    StreamController controller = new StreamController(
        onCancel: () {
          doneCompleter.complete(true);
        });

    controller.addError("error");

    void onError(e) {
      fail("onError is unexpected");
    }
    controller.stream
      .listen(null, onError: onError, cancelOnError: true)
      .cancel();
    expect(doneCompleter.future, completion(equals(true)));
  });

  test('subscription.cancel on error (cancelOnError)', () {
    bool called = false;
    StreamController controller = new StreamController(
        onCancel: () {
          expect(called, isFalse);
          called = true;
        });

    controller.addError("error");

    var doneCompleter = new Completer();
    var sub;
    void onError(e) {
      expect(called, equals(true));
      sub.cancel();
      doneCompleter.complete(true);
    }
    sub = controller.stream
      .listen(null, onError: onError, cancelOnError: true);
    expect(doneCompleter.future, completion(equals(true)));
  });

  test('subscription.cancel before done', () {
    var doneCompleter = new Completer();
    StreamController controller = new StreamController(
        onCancel: () {
          doneCompleter.complete(true);
        });

    controller.close();

    void onDone() {
      fail("onDone is unexpected");
    }
    controller.stream
      .listen(null, onDone: onDone)
      .cancel();
    expect(doneCompleter.future, completion(equals(true)));
  });
}
