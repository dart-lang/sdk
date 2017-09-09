// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the StreamSubscription.cancel return Future.
library stream_subscription_cancel;

import 'dart:async';
import 'package:test/test.dart';

void main() {
  test('subscription.cancel', () {
    var completer = new Completer();
    StreamController controller =
        new StreamController(onCancel: () => completer.future);

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
    StreamController controller = new StreamController(onCancel: () {
      completer.complete();
      return completer.future;
    });

    controller.close();

    var completer2 = new Completer();
    var sub;
    void onDone() {
      sub.cancel().then(completer2.complete);
    }

    sub = controller.stream.listen(null, onDone: onDone);
    expect(completer.future, completes);
    expect(completer2.future, completes);
  });

  test('subscription.cancel after error', () {
    var completer = new Completer();
    StreamController controller =
        new StreamController(onCancel: () => completer.future);

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
    StreamController controller = new StreamController(onCancel: () {
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
    StreamController controller = new StreamController(onCancel: () {
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
    StreamController controller = new StreamController(onCancel: () {
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

    sub = controller.stream.listen(null, onError: onError, cancelOnError: true);
    expect(doneCompleter.future, completion(equals(true)));
  });

  test('subscription.cancel before done', () {
    var doneCompleter = new Completer();
    StreamController controller = new StreamController(onCancel: () {
      doneCompleter.complete(true);
    });

    controller.close();

    void onDone() {
      fail("onDone is unexpected");
    }

    controller.stream.listen(null, onDone: onDone).cancel();
    expect(doneCompleter.future, completion(equals(true)));
  });

  test('subscription.cancel through map', () {
    var completer = new Completer();
    StreamController controller =
        new StreamController(onCancel: () => completer.future);

    bool done = false;
    var future = controller.stream.map((x) => x).listen(null).cancel();

    expect(future.then((_) => done = true), completion(equals(true)));

    Timer.run(() {
      expect(done, isFalse);
      completer.complete();
    });
  });

  test('subscription.cancel through asyncMap', () {
    var completer = new Completer();
    StreamController controller =
        new StreamController(onCancel: () => completer.future);

    bool done = false;
    var future = controller.stream.asyncMap((x) => x).listen(null).cancel();

    expect(future.then((_) => done = true), completion(equals(true)));

    Timer.run(() {
      expect(done, isFalse);
      completer.complete();
    });
  });

  test('subscription.cancel through asyncExpand', () {
    var completer = new Completer();
    StreamController controller =
        new StreamController(onCancel: () => completer.future);

    bool done = false;
    var future = controller.stream.asyncExpand((x) => x).listen(null).cancel();

    expect(future.then((_) => done = true), completion(equals(true)));

    Timer.run(() {
      expect(done, isFalse);
      completer.complete();
    });
  });

  test('subscription.cancel through handleError', () {
    var completer = new Completer();
    StreamController controller =
        new StreamController(onCancel: () => completer.future);

    bool done = false;
    var future = controller.stream.handleError((x) => x).listen(null).cancel();

    expect(future.then((_) => done = true), completion(equals(true)));

    Timer.run(() {
      expect(done, isFalse);
      completer.complete();
    });
  });

  test('subscription.cancel through skip', () {
    var completer = new Completer();
    StreamController controller =
        new StreamController(onCancel: () => completer.future);

    bool done = false;
    var future = controller.stream.skip(1).listen(null).cancel();

    expect(future.then((_) => done = true), completion(equals(true)));

    Timer.run(() {
      expect(done, isFalse);
      completer.complete();
    });
  });

  test('subscription.cancel through take', () {
    var completer = new Completer();
    StreamController controller =
        new StreamController(onCancel: () => completer.future);

    bool done = false;
    var future = controller.stream.take(1).listen(null).cancel();

    expect(future.then((_) => done = true), completion(equals(true)));

    Timer.run(() {
      expect(done, isFalse);
      completer.complete();
    });
  });

  test('subscription.cancel through skipWhile', () {
    var completer = new Completer();
    StreamController controller =
        new StreamController(onCancel: () => completer.future);

    bool done = false;
    var future = controller.stream.skipWhile((x) => true).listen(null).cancel();

    expect(future.then((_) => done = true), completion(equals(true)));

    Timer.run(() {
      expect(done, isFalse);
      completer.complete();
    });
  });

  test('subscription.cancel through takeWhile', () {
    var completer = new Completer();
    StreamController controller =
        new StreamController(onCancel: () => completer.future);

    bool done = false;
    var future = controller.stream.takeWhile((x) => true).listen(null).cancel();

    expect(future.then((_) => done = true), completion(equals(true)));

    Timer.run(() {
      expect(done, isFalse);
      completer.complete();
    });
  });

  test('subscription.cancel through timeOut', () {
    var completer = new Completer();
    StreamController controller =
        new StreamController(onCancel: () => completer.future);

    bool done = false;
    var duration = const Duration(hours: 5);
    var future = controller.stream.timeout(duration).listen(null).cancel();

    expect(future.then((_) => done = true), completion(equals(true)));

    Timer.run(() {
      expect(done, isFalse);
      completer.complete();
    });
  });

  test('subscription.cancel through transform', () {
    var completer = new Completer();
    StreamController controller =
        new StreamController(onCancel: () => completer.future);

    bool done = false;
    var transformer = new StreamTransformer.fromHandlers(handleData: (x, y) {});
    var future = controller.stream.transform(transformer).listen(null).cancel();

    expect(future.then((_) => done = true), completion(equals(true)));

    Timer.run(() {
      expect(done, isFalse);
      completer.complete();
    });
  });

  test('subscription.cancel through where', () {
    var completer = new Completer();
    StreamController controller =
        new StreamController(onCancel: () => completer.future);

    bool done = false;
    var future = controller.stream.where((x) => true).listen(null).cancel();

    expect(future.then((_) => done = true), completion(equals(true)));

    Timer.run(() {
      expect(done, isFalse);
      completer.complete();
    });
  });
}
